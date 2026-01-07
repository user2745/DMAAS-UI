import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Field extends Equatable {
  const Field({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final Color color;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'] as String,
      name: json['name'] as String,
      color: _colorFromHex(json['color'] as String? ?? '#6366F1'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': _colorToHex(color),
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  Field copyWith({
    String? id,
    String? name,
    Color? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Field(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [id, name, color, createdAt, updatedAt];
}

Color _colorFromHex(String hexColor) {
  final hexString = hexColor.replaceFirst('#', '');
  return Color(int.parse('FF$hexString', radix: 16));
}

String _colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
}

// Predefined color palette for fields
const List<Color> fieldColors = [
  Color(0xFF6366F1), // Indigo
  Color(0xFFEC4899), // Pink
  Color(0xFFF59E0B), // Amber
  Color(0xFF10B981), // Emerald
  Color(0xFF3B82F6), // Blue
  Color(0xFF8B5CF6), // Violet
  Color(0xFFEF4444), // Red
  Color(0xFF06B6D4), // Cyan
];

// Keep for backwards compatibility
const List<Color> categoryColors = fieldColors;
