import 'package:equatable/equatable.dart';

enum AppPurchaseStatus { unknown, loading, purchased, notPurchased, error }

class PurchaseState extends Equatable {
  const PurchaseState({
    this.status = AppPurchaseStatus.unknown,
    this.taskCount = 0,
    this.firstTaskDate,
    this.isPurchasing = false,
    this.errorMessage,
  });

  final AppPurchaseStatus status;
  final int taskCount;
  final DateTime? firstTaskDate;
  final bool isPurchasing;
  final String? errorMessage;

  bool get isPurchased => status == AppPurchaseStatus.purchased;

  /// True once they've hit 30 tasks OR 15 days since first task
  bool get hasHitLimit {
    if (isPurchased) return false;
    if (taskCount >= 30) return true;
    if (firstTaskDate != null) {
      final daysElapsed = DateTime.now().difference(firstTaskDate!).inDays;
      if (daysElapsed >= 15) return true;
    }
    return false;
  }

  int get daysRemaining {
    if (firstTaskDate == null) return 15;
    final elapsed = DateTime.now().difference(firstTaskDate!).inDays;
    return (15 - elapsed).clamp(0, 15);
  }

  int get tasksRemaining => (30 - taskCount).clamp(0, 30);

  PurchaseState copyWith({
    AppPurchaseStatus? status,
    int? taskCount,
    DateTime? firstTaskDate,
    bool? isPurchasing,
    String? errorMessage,
  }) {
    return PurchaseState(
      status: status ?? this.status,
      taskCount: taskCount ?? this.taskCount,
      firstTaskDate: firstTaskDate ?? this.firstTaskDate,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        taskCount,
        firstTaskDate,
        isPurchasing,
        errorMessage,
      ];
}
