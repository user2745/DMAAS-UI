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
    this.order = 0,
    this.description,
    this.dueDate,
    this.fieldValues,
    this.categoryId,
  });

  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final DateTime createdAt;
  final int order;
  final DateTime? dueDate;
  final Map<String, dynamic>? fieldValues;
  final String? categoryId;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      status: TaskStatusX.fromString(json['status'] ?? 'todo'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      order: (json['order'] as num?)?.toInt() ?? 0,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      fieldValues: json['fieldValues'] is Map<String, dynamic>
          ? json['fieldValues'] as Map<String, dynamic>
          : (json['fieldValues'] is Map
                ? Map<String, dynamic>.from(json['fieldValues'] as Map)
                : null),
      categoryId: json['categoryId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status.value,
      'order': order,
      if (dueDate != null) 'dueDate': dueDate?.toIso8601String(),
      if (fieldValues != null) 'fieldValues': fieldValues,
      if (categoryId != null) 'categoryId': categoryId,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? createdAt,
    int? order,
    DateTime? dueDate,
    Map<String, dynamic>? fieldValues,
    String? categoryId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      order: order ?? this.order,
      dueDate: dueDate ?? this.dueDate,
      fieldValues: fieldValues ?? this.fieldValues,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    status,
    createdAt,
    order,
    dueDate,
    fieldValues,
    categoryId,
  ];
}
