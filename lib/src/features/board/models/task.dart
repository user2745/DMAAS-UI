import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TaskStatus { todo, inProgress, done }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  String get value {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
    }
  }

  static TaskStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.todo:
        return const Color(0xFF58A6FF); // Blue
      case TaskStatus.inProgress:
        return const Color(0xFFBB86FC); // Purple
      case TaskStatus.done:
        return const Color(0xFF3FB950); // Green
    }
  }

  TaskStatus? get previous {
    switch (this) {
      case TaskStatus.todo:
        return null;
      case TaskStatus.inProgress:
        return TaskStatus.todo;
      case TaskStatus.done:
        return TaskStatus.inProgress;
    }
  }

  TaskStatus? get next {
    switch (this) {
      case TaskStatus.todo:
        return TaskStatus.inProgress;
      case TaskStatus.inProgress:
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
    required this.status,
    required this.createdAt,
    this.description,
    this.dueDate,
  });

  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? dueDate;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: TaskStatusX.fromString(json['status'] ?? 'todo'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status.value,
      if (dueDate != null) 'dueDate': dueDate?.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? dueDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
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
  ];
}

