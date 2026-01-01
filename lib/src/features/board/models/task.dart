import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TaskStatus { backlog, inProgress, review, done }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.backlog:
        return 'Backlog';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.review:
        return 'Review';
      case TaskStatus.done:
        return 'Done';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.backlog:
        return const Color(0xFF58A6FF); // Blue
      case TaskStatus.inProgress:
        return const Color(0xFFBB86FC); // Purple
      case TaskStatus.review:
        return const Color(0xFFFF9800); // Orange
      case TaskStatus.done:
        return const Color(0xFF3FB950); // Green
    }
  }

  TaskStatus? get previous {
    switch (this) {
      case TaskStatus.backlog:
        return null;
      case TaskStatus.inProgress:
        return TaskStatus.backlog;
      case TaskStatus.review:
        return TaskStatus.inProgress;
      case TaskStatus.done:
        return TaskStatus.review;
    }
  }

  TaskStatus? get next {
    switch (this) {
      case TaskStatus.backlog:
        return TaskStatus.inProgress;
      case TaskStatus.inProgress:
        return TaskStatus.review;
      case TaskStatus.review:
        return TaskStatus.done;
      case TaskStatus.done:
        return null;
    }
  }
}

class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.dueDate,
    this.assignee,
  });

  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? assignee;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? dueDate,
    String? assignee,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      assignee: assignee ?? this.assignee,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    status,
    createdAt,
    dueDate,
    assignee,
  ];
}
