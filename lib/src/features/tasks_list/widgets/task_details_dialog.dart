import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../board/models/task.dart';
import '../../board/models/task_comment.dart';

// Design Language: Motion-first, polished dialog with smooth animations
// See DESIGN_LANGUAGE.md for complete spec

class TaskDetailsDialog extends StatefulWidget {
  const TaskDetailsDialog({
    super.key,
    required this.task,
    this.onEdit,
    this.onDelete,
    this.onAddComment,
    this.onDeleteComment,
  });

  final Task task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Future<void> Function(String text)? onAddComment;
  final Future<void> Function(String commentId)? onDeleteComment;

  @override
  State<TaskDetailsDialog> createState() => _TaskDetailsDialogState();
}

class _TaskDetailsDialogState extends State<TaskDetailsDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  bool _isAddingComment = false;
  bool _showMetadata = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 600;
    // Design Language: Mobile responsiveness (full-screen-like under 600px)
    final maxWidth = isCompact ? media.size.width - 16 : 640;
    final maxHeight = isCompact ? media.size.height - 16 : 700;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          insetPadding: EdgeInsets.all(isCompact ? 8 : 16),
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            // Responsive sizing (full-screen-like on compact screens)
            constraints: BoxConstraints(
              maxWidth: maxWidth.toDouble(),
              maxHeight: maxHeight.toDouble(),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(120),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header (compact, 16px padding)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Status badge (small pill)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.task.status.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.task.status.color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.task.status.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: widget.task.status.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title (reduced from 28px to 18-20px)
                      Expanded(
                        child: Text(
                          widget.task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Close',
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
                // Main content (scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description section
                        if (widget.task.description != null &&
                            widget.task.description!.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.task.description!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Divider(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.08),
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                          ),
                        ],
                        // Metadata (collapsible)
                        _buildMetadataSection(context),
                        Padding(
                          padding: EdgeInsets.zero,
                          child: Divider(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.08),
                            height: 1,
                          ),
                        ),
                        // Discussion section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Discussion',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${widget.task.comments.length}',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Comments list
                              _buildCommentsList(context),
                              if (widget.onAddComment != null) ...[
                                const SizedBox(height: 16),
                                _buildCommentInput(context),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer (actions)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.onDelete != null)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onDelete?.call();
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (widget.onEdit != null)
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onEdit?.call();
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsible header with smooth animation
          GestureDetector(
            onTap: () {
              setState(() {
                _showMetadata = !_showMetadata;
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Animated chevron (rotates 180° smoothly)
                    AnimatedRotation(
                      turns: _showMetadata ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        size: 20,
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Details',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Smooth expand/collapse with ClipRect
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              duration: const Duration(milliseconds: 200),
              heightFactor: _showMetadata ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetadataRow(
                      context,
                      icon: Icons.calendar_today,
                      label: 'Created',
                      value: _formatDateTime(widget.task.createdAt),
                    ),
                    const SizedBox(height: 10),
                    if (widget.task.dueDate != null) ...[
                      _buildMetadataRow(
                        context,
                        icon: Icons.event,
                        label: 'Due Date',
                        value: _formatDateTime(widget.task.dueDate!),
                        color: _getDueDateColor(widget.task.dueDate!),
                      ),
                      const SizedBox(height: 10),
                    ],
                    _buildMetadataRow(
                      context,
                      icon: Icons.fingerprint,
                      label: 'Task ID',
                      value: widget.task.id.substring(0, 12) + '...',
                      isCode: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? color,
    bool isCode = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color ?? theme.colorScheme.onSurface,
              fontWeight: color != null ? FontWeight.w600 : null,
              fontFamily: isCode ? 'monospace' : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsList(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.task.comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No comments yet. Start the discussion!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.task.comments.length,
      itemBuilder: (context, index) {
        final comment = widget.task.comments[index];
        return _buildCommentCard(context, comment);
      },
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
        borderRadius: BorderRadius.circular(10),
        color: theme.colorScheme.onSurface.withOpacity(0.02),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              hintStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            maxLines: null,
            minLines: 2,
            enabled: !_isAddingComment,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.bodySmall,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed:
                      _isAddingComment ? null : _handleAddComment,
                  icon: _isAddingComment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, size: 16),
                  label: const Text('Comment'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(BuildContext context, TaskComment comment) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with avatar, name, time, delete
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.person,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatCommentTime(comment.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
              if (widget.onDeleteComment != null)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    onPressed: () => _handleDeleteComment(comment.id),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Comment text
          Text(
            comment.text,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isAddingComment = true;
    });

    try {
      await widget.onAddComment?.call(text);
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingComment = false;
        });
      }
    }
  }

  Future<void> _handleDeleteComment(String commentId) async {
    try {
      await widget.onDeleteComment?.call(commentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatCommentTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  Color? _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    if (dueDate.isBefore(now)) {
      return const Color(0xFFEF4444); // Red for overdue
    } else if (dueDate.difference(now).inDays <= 1) {
      return const Color(0xFFFF9800); // Orange for due soon
    }
    return null;
  }
}
