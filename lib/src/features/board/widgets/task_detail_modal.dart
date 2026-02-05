import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../../tasks_list/models/field.dart';
import '../../board/models/task_comment.dart';
import '../cubit/task_board_cubit.dart';
import '../../tasks_list/widgets/field_widgets.dart';
import '../../../widgets/micro_interactions/undo_redo_whisper.dart';
import '../../../widgets/micro_interactions/breathing_border.dart';

// Design Language: Premium modal with header band, chips, and details rail
// See DESIGN_LANGUAGE.md for complete spec

class TaskDetailModal extends StatefulWidget {
  const TaskDetailModal({
    super.key,
    required this.task,
    this.onAddComment,
    this.onDeleteComment,
  });

  final Task task;
  final Future<void> Function(String text)? onAddComment;
  final Future<void> Function(String commentId)? onDeleteComment;

  static Future<void> show(
    BuildContext context, {
    required Task task,
    Future<void> Function(String text)? onAddComment,
    Future<void> Function(String commentId)? onDeleteComment,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return TaskDetailModal(
          task: task,
          onAddComment: onAddComment,
          onDeleteComment: onDeleteComment,
        );
      },
    );
  }

  @override
  State<TaskDetailModal> createState() => _TaskDetailModalState();
}

class _TaskDetailModalState extends State<TaskDetailModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isAddingComment = false;
  final Set<String> _expandedChips = {};
  bool _isEditingTitle = false;
  bool _isEditingDescription = false;
  bool _isTitleHovered = false;
  bool _isDescriptionHovered = false;
  bool _showUndoWhisper = false;
  bool _isCommentSyncing = false;
  String? _commentSyncStatus; // 'loading', 'synced', 'error', null
  bool _isFieldsHovered = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.task.title;
    _descriptionController.text = widget.task.description ?? '';
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _commentController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 600;
    final maxWidth = (isCompact ? media.size.width - 16 : 680.0);
    final maxHeight = (isCompact ? media.size.height - 16 : 800.0);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Dialog(
              insetPadding: EdgeInsets.all(isCompact ? 8 : 16),
              backgroundColor: Colors.transparent,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: widget.task.status.color.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
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
                // Header Band (compact)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Status accent bar
                      Container(
                        width: 4,
                        height: 32,
                        decoration: BoxDecoration(
                          color: widget.task.status.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.task.status.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: widget.task.status.color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.task.status.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: widget.task.status.color,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title
                      Expanded(
                        child: MouseRegion(
                          onEnter: (_) =>
                              setState(() => _isTitleHovered = true),
                          onExit: (_) =>
                              setState(() => _isTitleHovered = false),
                          cursor: SystemMouseCursors.text,
                          child: GestureDetector(
                            onTap: () => setState(() => _isEditingTitle = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: _isTitleHovered || _isEditingTitle
                                    ? theme.colorScheme.onSurface.withOpacity(
                                        0.04,
                                      )
                                    : Colors.transparent,
                                border: _isEditingTitle
                                    ? Border.all(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.3),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: _isEditingTitle
                                  ? TextField(
                                      controller: _titleController,
                                      autofocus: true,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onSubmitted: (_) => _saveTitle(),
                                      onTapOutside: (_) => _saveTitle(),
                                    )
                                  : Text(
                                      _titleController.text.isNotEmpty
                                          ? _titleController.text
                                          : widget.task.title,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Actions
                      Container(
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Close',
                          iconSize: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Chips Section (metadata)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  0,
                                ),
                                child:
                                    BlocBuilder<TaskBoardCubit, TaskBoardState>(
                                      builder: (context, boardState) {
                                        final chips = <Widget>[];

                                        // Created date chip
                                        chips.add(
                                          _buildMetadataChip(
                                            context,
                                            chipId: 'created',
                                            icon: Icons.calendar_today,
                                            label: _formatDate(
                                              widget.task.createdAt,
                                            ),
                                            detailLabel: 'Created',
                                            color: widget.task.status.color,
                                          ),
                                        );

                                        // Due date chip (if set)
                                        if (widget.task.dueDate != null) {
                                          chips.add(
                                            _buildMetadataChip(
                                              context,
                                              chipId: 'due',
                                              icon: Icons.event,
                                              label: _formatDate(
                                                widget.task.dueDate!,
                                              ),
                                              detailLabel: 'Due',
                                              color: const Color(0xFFFF9800),
                                            ),
                                          );
                                        }

                                        // Custom field chips
                                        print('DEBUG: Total fields from backend: ${boardState.fields.length}');
                                        print('DEBUG: Task fieldValues: ${widget.task.fieldValues}');
                                        for (final field in boardState.fields) {
                                          final fieldValue = widget
                                              .task
                                              .fieldValues?[field.id];
                                          print('DEBUG: Field "${field.name}" (${field.id}) = $fieldValue');
                                          if (fieldValue != null &&
                                              fieldValue
                                                  .toString()
                                                  .isNotEmpty) {
                                            final displayValue =
                                                _formatFieldValue(
                                                  field,
                                                  fieldValue,
                                                );
                                            chips.add(
                                              _buildMetadataChip(
                                                context,
                                                chipId: field.id,
                                                icon: _getFieldIcon(field.type),
                                                label: displayValue,
                                                detailLabel: field.name,
                                                color: field.color,
                                              ),
                                            );
                                          }
                                        }

                                        // Add field button (appears on hover)
                                        if (_isFieldsHovered) {
                                          chips.add(
                                            _buildAddFieldButton(context),
                                          );
                                        }

                                        return MouseRegion(
                                          onEnter: (_) => setState(() => _isFieldsHovered = true),
                                          onExit: (_) => setState(() => _isFieldsHovered = false),
                                          child: Wrap(
                                            spacing: 11,
                                            runSpacing: 11,
                                            children: chips,
                                          ),
                                        );
                                      },
                                    ),
                              ),
                              // Description Section
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Description',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    MouseRegion(
                                      onEnter: (_) => setState(
                                        () => _isDescriptionHovered = true,
                                      ),
                                      onExit: (_) => setState(
                                        () => _isDescriptionHovered = false,
                                      ),
                                      cursor: SystemMouseCursors.text,
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => _isEditingDescription = true,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: _isEditingDescription
                                                ? theme.colorScheme.surface
                                                : _isDescriptionHovered
                                                ? theme.colorScheme.onSurface
                                                      .withOpacity(0.02)
                                                : theme.colorScheme.surface,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: _isEditingDescription
                                                  ? theme.colorScheme.primary
                                                        .withOpacity(0.3)
                                                  : _isDescriptionHovered
                                                  ? theme.colorScheme.onSurface
                                                        .withOpacity(0.12)
                                                  : theme.colorScheme.onSurface
                                                        .withOpacity(0.08),
                                            ),
                                          ),
                                          child: _isEditingDescription
                                              ? TextField(
                                                  controller:
                                                      _descriptionController,
                                                  autofocus: true,
                                                  maxLines: null,
                                                  minLines: 3,
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(height: 1.5),
                                                  decoration:
                                                      const InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        hintText:
                                                            'Add a description...',
                                                      ),
                                                  onTapOutside: (_) =>
                                                      _saveDescription(),
                                                )
                                              : Text(
                                                  _descriptionController
                                                              .text.isNotEmpty
                                                      ? _descriptionController
                                                          .text
                                                      : (widget.task.description
                                                              ?.isNotEmpty ??
                                                          false
                                                          ? widget.task
                                                              .description!
                                                          : 'No description'),
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        height: 1.5,
                                                        color:
                                                            widget
                                                                    .task
                                                                    .description
                                                                    ?.isNotEmpty ??
                                                                false
                                                            ? theme
                                                                  .colorScheme
                                                                  .onSurface
                                                            : theme
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                    0.4,
                                                                  ),
                                                      ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Comments Section (bottom-justified)
                      if (widget.task.comments.isNotEmpty ||
                          widget.onAddComment != null)
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Comments (${widget.task.comments.length})',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.4),
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 12),
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
                // Footer
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
                      Material(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.12,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.close,
                                  size: 16,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Close',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
            // Undo/Redo whisper badge
            UndoRedoWhisper(
              isVisible: _showUndoWhisper,
              onUndo: () {
                // Trigger undo via Cubit
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Undo not yet implemented')),
                );
              },
              onRedo: () {
                // Trigger redo via Cubit
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Redo not yet implemented')),
                );
              },
              onDismiss: () {
                setState(() => _showUndoWhisper = false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataChip(
    BuildContext context, {
    required String chipId,
    required IconData icon,
    required String label,
    required String detailLabel,
    required Color color,
  }) {
    final isExpanded = _expandedChips.contains(chipId);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedChips.remove(chipId);
            } else {
              _expandedChips.add(chipId);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 12 : 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isExpanded
                ? color.withOpacity(0.12)
                : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isExpanded
                  ? color.withOpacity(0.3)
                  : color.withOpacity(0.2),
              width: isExpanded ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isExpanded ? 14 : 13,
                color: color.withOpacity(0.9),
              ),
              const SizedBox(width: 6),
              if (isExpanded) ...[
                Text(
                  '$detailLabel: ',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddFieldButton(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          await showDialog(
            context: context,
            builder: (context) => const CreateFieldDialog(),
          );
          // Reload fields after dialog closes to show the newly created field
          if (context.mounted) {
            context.read<TaskBoardCubit>().loadFields();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 13,
                color: theme.colorScheme.primary.withOpacity(0.9),
              ),
              const SizedBox(width: 6),
              Text(
                'Add field',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsList(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.task.comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No comments yet',
            style: theme.textTheme.bodySmall?.copyWith(
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

  Widget _buildCommentCard(BuildContext context, TaskComment comment) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.person,
                  size: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatCommentTime(comment.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
              ),
              if (widget.onDeleteComment != null)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                    onPressed: () => widget.onDeleteComment?.call(comment.id),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.text,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.4,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    final theme = Theme.of(context);
    return BreathingBorder(
      isBreathing: _isCommentSyncing,
      borderColor: theme.colorScheme.primary,
      borderRadius: 8,
      statusIndicator: _commentSyncStatus,
      showGlow: false,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.08),
          ),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(10),
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),
              maxLines: null,
              minLines: 2,
              enabled: !_isAddingComment,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: _isAddingComment ? null : _handleAddComment,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isAddingComment)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(
                              Icons.send,
                              size: 14,
                              color: Colors.white,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            'Add',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _handleAddComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isAddingComment = true;
      _isCommentSyncing = true;
      _commentSyncStatus = 'loading';
    });

    try {
      await widget.onAddComment?.call(text);
      _commentController.clear();
      
      // Show success state briefly
      if (mounted) {
        setState(() => _commentSyncStatus = 'synced');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() {
            _isCommentSyncing = false;
            _commentSyncStatus = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _commentSyncStatus = 'error');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
        
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _isCommentSyncing = false;
            _commentSyncStatus = null;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingComment = false);
      }
    }
  }

  String _formatDate(DateTime date) {
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

  IconData _getFieldIcon(FieldType type) {
    switch (type) {
      case FieldType.text:
        return Icons.text_fields;
      case FieldType.singleSelect:
        return Icons.check_circle_outline;
      case FieldType.date:
        return Icons.calendar_today;
    }
  }

  String _formatFieldValue(Field field, dynamic value) {
    if (value == null) return '';

    switch (field.type) {
      case FieldType.date:
        try {
          final date = value is DateTime
              ? value
              : DateTime.parse(value.toString());
          return DateFormat('MMM d').format(date);
        } catch (e) {
          return value.toString();
        }
      case FieldType.singleSelect:
      case FieldType.text:
        return value.toString();
    }
  }

  void _saveTitle() {
    if (!_isEditingTitle) return;
    setState(() => _isEditingTitle = false);
    final newTitle = _titleController.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.task.title) {
      context.read<TaskBoardCubit>().updateTask(
        widget.task.copyWith(title: newTitle),
      );
      // Show undo whisper
      _showUndoForChange('title');
    } else {
      _titleController.text = widget.task.title;
    }
  }

  void _saveDescription() {
    if (!_isEditingDescription) return;
    setState(() => _isEditingDescription = false);
    final newDescription = _descriptionController.text.trim();
    if (newDescription != widget.task.description) {
      context.read<TaskBoardCubit>().updateTask(
        widget.task.copyWith(
          description: newDescription.isEmpty ? null : newDescription,
        ),
      );
      // Show undo whisper
      _showUndoForChange('description');
    } else {
      _descriptionController.text = widget.task.description ?? '';
    }
  }

  void _showUndoForChange(String changeType) {
    setState(() {
      _showUndoWhisper = true;
    });
  }
}
