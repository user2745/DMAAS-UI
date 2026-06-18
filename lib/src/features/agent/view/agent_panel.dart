import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/agent_cubit.dart';
import '../cubit/agent_state.dart';

/// Conversational agent panel — slide-up bottom sheet.
class AgentPanel extends StatelessWidget {
  const AgentPanel._({this.initialQuery});

  final String? initialQuery;

  static Future<void> show(BuildContext context, {String? initialQuery}) {
    context.read<AgentCubit>().reset();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AgentCubit>(),
        child: AgentPanel._(initialQuery: initialQuery),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgentCubit, AgentState>(
      builder: (context, state) {
        return _AgentPanelBody(
          state: state,
          initialQuery: initialQuery,
        );
      },
    );
  }
}

class _AgentPanelBody extends StatefulWidget {
  const _AgentPanelBody({required this.state, this.initialQuery});

  final AgentState state;
  final String? initialQuery;

  @override
  State<_AgentPanelBody> createState() => _AgentPanelBodyState();
}

class _AgentPanelBodyState extends State<_AgentPanelBody> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();
  bool _initialQuerySent = false;

  @override
  void initState() {
    super.initState();
    // Auto-send initial query if provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_initialQuerySent) {
          _initialQuerySent = true;
          context.read<AgentCubit>().sendMessage(widget.initialQuery!);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.state.isBusy) return;
    _controller.clear();
    context.read<AgentCubit>().sendMessage(text);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(covariant _AgentPanelBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll when new content arrives
    if (widget.state.messages.length != oldWidget.state.messages.length ||
        widget.state.streamingText != oldWidget.state.streamingText) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, sheetScrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF30363D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    const Text('✦', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Activities Agent',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE6EDF3),
                        ),
                      ),
                    ),
                    if (widget.state.isBusy)
                      IconButton(
                        onPressed: () => context.read<AgentCubit>().cancel(),
                        icon: const Icon(Icons.stop_circle_outlined,
                            color: Color(0xFFFF6B6B)),
                        tooltip: 'Stop',
                        iconSize: 22,
                      ),
                    IconButton(
                      onPressed: () => context.read<AgentCubit>().reset(),
                      icon: const Icon(Icons.refresh,
                          color: Color(0xFF8B949E)),
                      tooltip: 'New conversation',
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 16, color: Color(0xFF21262D)),
              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  itemCount: widget.state.messages.length +
                      (widget.state.streamingText.isNotEmpty ? 1 : 0) +
                      (widget.state.isToolExecuting ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Existing messages
                    if (index < widget.state.messages.length) {
                      return _MessageBubble(
                          message: widget.state.messages[index]);
                    }

                    // Tool executing indicator
                    if (widget.state.isToolExecuting &&
                        index == widget.state.messages.length) {
                      return _ToolIndicator(
                          toolName: widget.state.currentTool ?? 'Working');
                    }

                    // Streaming text
                    return _StreamingBubble(
                        text: widget.state.streamingText);
                  },
                ),
              ),
              // Tool indicator bar
              if (widget.state.isToolExecuting)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: const Color(0xFF21262D),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFBB86FC),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _toolDisplayName(widget.state.currentTool),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B949E),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              // Input
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1117),
                  border: Border(
                    top: BorderSide(color: Color(0xFF21262D)),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _inputFocus,
                          onSubmitted: (_) => _sendMessage(),
                          style: const TextStyle(
                            color: Color(0xFFE6EDF3),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.state.messages.isEmpty
                                ? 'Ask anything about your tasks...'
                                : 'Follow up...',
                            hintStyle: const TextStyle(
                              color: Color(0xFF484F58),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF161B22),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF30363D)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF30363D)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFBB86FC)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: IconButton(
                          onPressed: widget.state.isBusy ? null : _sendMessage,
                          icon: Icon(
                            Icons.send_rounded,
                            color: widget.state.isBusy
                                ? const Color(0xFF484F58)
                                : const Color(0xFFBB86FC),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF21262D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _toolDisplayName(String? name) {
    switch (name) {
      case 'search_tasks':
        return 'Searching tasks...';
      case 'task_crud':
        return 'Managing tasks...';
      case 'summarize_tasks':
        return 'Generating report...';
      case 'search_web':
        return 'Searching the web...';
      case 'browser_action':
        return 'Browsing...';
      case 'create_artifact':
        return 'Creating document...';
      default:
        return 'Working...';
    }
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AgentMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFFBB86FC).withAlpha(30) : const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUser
                  ? const Color(0xFFBB86FC).withAlpha(60)
                  : const Color(0xFF30363D),
            ),
          ),
          child: SelectableText(
            message.content,
            style: TextStyle(
              fontSize: 14,
              color: isUser ? const Color(0xFFE6EDF3) : const Color(0xFFC9D1D9),
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Streaming bubble ──────────────────────────────────────────────────────────

class _StreamingBubble extends StatelessWidget {
  const _StreamingBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: SelectableText(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFC9D1D9),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const _CursorBlink(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Blinking cursor ───────────────────────────────────────────────────────────

class _CursorBlink extends StatefulWidget {
  const _CursorBlink();

  @override
  State<_CursorBlink> createState() => _CursorBlinkState();
}

class _CursorBlinkState extends State<_CursorBlink>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 16,
        color: const Color(0xFFBB86FC),
      ),
    );
  }
}

// ── Tool indicator ────────────────────────────────────────────────────────────

class _ToolIndicator extends StatelessWidget {
  const _ToolIndicator({required this.toolName});

  final String toolName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF21262D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFBB86FC).withAlpha(40),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFBB86FC),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              toolName,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF8B949E),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
