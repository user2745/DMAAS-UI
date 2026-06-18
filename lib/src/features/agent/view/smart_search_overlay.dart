import 'package:flutter/material.dart';

import '../data/smart_search_service.dart';
import 'package:DMAAS/src/theme/app_theme.dart';

/// Inline AI search results overlay — shows below the search bar.
/// Displays: AI summary → ranked task cards with relevance scores.
class SmartSearchOverlay extends StatelessWidget {
  const SmartSearchOverlay({
    super.key,
    required this.result,
    required this.isLoading,
    this.onTaskTap,
    this.onDismiss,
  });

  final SmartSearchResult? result;
  final bool isLoading;
  final void Function(SmartSearchTask task)? onTaskTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildContainer(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accentPurple,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Searching with AI...',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (result == null) return const SizedBox.shrink();

    return _buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI Summary
          if (result!.summary.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.darkBackground,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✦ ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      result!.summary,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Matched tasks
          if (result!.tasks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                '${result!.total} matching task${result!.total == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...result!.tasks.take(6).map(_buildTaskRow),
            const SizedBox(height: 8),
          ],

          // No results
          if (result!.tasks.isEmpty && result!.summary.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No matching tasks found.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(child: child),
      ),
    );
  }

  Widget _buildTaskRow(SmartSearchTask task) {
    final statusColor = _statusColor(task.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTaskTap?.call(task),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Status dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              // Title + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Due date chip
              if (task.dueDate != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceBackground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDate(task.dueDate!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
              // Relevance score
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(task.score * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'done':
      case 'completed':
        return AppTheme.accentGreen;
      case 'in progress':
      case 'in_progress':
        return AppTheme.accentBlue;
      case 'blocked':
        return AppTheme.accentRed;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[d.month - 1]} ${d.day}';
    } catch (_) {
      return iso;
    }
  }
}
