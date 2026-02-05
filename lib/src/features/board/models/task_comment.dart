import 'package:equatable/equatable.dart';

class TaskComment extends Equatable {
  const TaskComment({
    required this.id,
    required this.text,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: json['_id'] ?? json['id'] ?? '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
    };
  }

  TaskComment copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskComment(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, text, createdAt, updatedAt];
}
