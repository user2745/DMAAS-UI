import 'package:equatable/equatable.dart';

enum AgentStatus { idle, streaming, toolExecuting, done, error }

class AgentMessage extends Equatable {
  const AgentMessage({
    required this.role,
    required this.content,
    this.toolName,
    this.isToolResult = false,
  });

  final String role; // 'user', 'assistant', 'tool'
  final String content;
  final String? toolName;
  final bool isToolResult;

  @override
  List<Object?> get props => [role, content, toolName, isToolResult];
}

class AgentState extends Equatable {
  const AgentState({
    this.status = AgentStatus.idle,
    this.messages = const [],
    this.streamingText = '',
    this.currentTool,
    this.errorMessage,
    this.totalInputTokens = 0,
    this.totalOutputTokens = 0,
  });

  final AgentStatus status;
  final List<AgentMessage> messages;
  final String streamingText;
  final String? currentTool;
  final String? errorMessage;
  final int totalInputTokens;
  final int totalOutputTokens;

  bool get isStreaming => status == AgentStatus.streaming;
  bool get isToolExecuting => status == AgentStatus.toolExecuting;
  bool get isIdle => status == AgentStatus.idle || status == AgentStatus.done;
  bool get isBusy => status == AgentStatus.streaming || status == AgentStatus.toolExecuting;

  AgentState copyWith({
    AgentStatus? status,
    List<AgentMessage>? messages,
    String? streamingText,
    String? currentTool,
    String? errorMessage,
    int? totalInputTokens,
    int? totalOutputTokens,
  }) {
    return AgentState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      streamingText: streamingText ?? this.streamingText,
      currentTool: currentTool,
      errorMessage: errorMessage ?? this.errorMessage,
      totalInputTokens: totalInputTokens ?? this.totalInputTokens,
      totalOutputTokens: totalOutputTokens ?? this.totalOutputTokens,
    );
  }

  AgentState reset() => const AgentState();

  @override
  List<Object?> get props => [
        status,
        messages,
        streamingText,
        currentTool,
        errorMessage,
        totalInputTokens,
        totalOutputTokens,
      ];
}
