import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/agent_service.dart';
import 'agent_state.dart';

class AgentCubit extends Cubit<AgentState> {
  AgentCubit({required AgentService agentService})
      : _service = agentService,
        super(const AgentState());

  final AgentService _service;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  /// Send a message to the agent and stream the response.
  Future<void> sendMessage(String message) async {
    if (state.isBusy) return;

    // Add user message
    final userMsg = AgentMessage(role: 'user', content: message);
    final updatedMessages = [...state.messages, userMsg];

    emit(state.copyWith(
      status: AgentStatus.streaming,
      messages: updatedMessages,
      streamingText: '',
      currentTool: null,
      errorMessage: null,
    ));

    // Build history for the API (exclude current user message)
    final history = state.messages
        .where((m) => !m.isToolResult)
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    String accumulatedText = '';

    _subscription = _service
        .sendMessage(message: message, history: history)
        .listen(
      (event) {
        final type = event['type'] as String?;
        final data = event['data'];

        switch (type) {
          case 'text':
            accumulatedText += (data as String? ?? '');
            emit(state.copyWith(
              status: AgentStatus.streaming,
              streamingText: accumulatedText,
            ));
            break;

          case 'tool_start':
            final toolName = (data as Map<String, dynamic>?)?['name'] as String? ?? 'tool';
            emit(state.copyWith(
              status: AgentStatus.toolExecuting,
              currentTool: toolName,
            ));
            break;

          case 'tool_result':
            // Tool finished, back to streaming
            emit(state.copyWith(
              status: AgentStatus.streaming,
              currentTool: null,
            ));
            break;

          case 'turn_start':
            // New iteration — commit previous text as a message
            if (accumulatedText.isNotEmpty) {
              final assistantMsg =
                  AgentMessage(role: 'assistant', content: accumulatedText);
              final msgs = [...state.messages, assistantMsg];
              accumulatedText = '';
              emit(state.copyWith(
                messages: msgs,
                streamingText: '',
              ));
            }
            break;

          case 'usage':
            final inputTokens =
                (data as Map<String, dynamic>?)?['input_tokens'] as int? ?? 0;
            final outputTokens = data?['output_tokens'] as int? ?? 0;
            emit(state.copyWith(
              totalInputTokens: state.totalInputTokens + inputTokens,
              totalOutputTokens: state.totalOutputTokens + outputTokens,
            ));
            break;

          case 'done':
            // Commit final text
            if (accumulatedText.isNotEmpty) {
              final assistantMsg =
                  AgentMessage(role: 'assistant', content: accumulatedText);
              final msgs = [...state.messages, assistantMsg];
              emit(state.copyWith(
                status: AgentStatus.done,
                messages: msgs,
                streamingText: '',
                currentTool: null,
              ));
            } else {
              emit(state.copyWith(
                status: AgentStatus.done,
                currentTool: null,
              ));
            }
            break;

          case 'error':
            emit(state.copyWith(
              status: AgentStatus.error,
              errorMessage: data?.toString() ?? 'Unknown error',
              currentTool: null,
            ));
            break;
        }
      },
      onError: (error) {
        emit(state.copyWith(
          status: AgentStatus.error,
          errorMessage: error.toString(),
        ));
      },
      onDone: () {
        // If stream closes without a done event, commit whatever we have
        if (state.isStreaming && accumulatedText.isNotEmpty) {
          final assistantMsg =
              AgentMessage(role: 'assistant', content: accumulatedText);
          final msgs = [...state.messages, assistantMsg];
          emit(state.copyWith(
            status: AgentStatus.done,
            messages: msgs,
            streamingText: '',
          ));
        }
      },
    );
  }

  /// Cancel the current agent run.
  void cancel() {
    _subscription?.cancel();
    _subscription = null;
    if (state.isBusy) {
      emit(state.copyWith(status: AgentStatus.done));
    }
  }

  /// Reset conversation.
  void reset() {
    _subscription?.cancel();
    _subscription = null;
    emit(state.reset());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
