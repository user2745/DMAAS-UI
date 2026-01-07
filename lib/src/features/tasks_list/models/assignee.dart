import 'package:equatable/equatable.dart';

class Assignee extends Equatable {
  const Assignee({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? avatarUrl;

  Assignee copyWith({String? id, String? name, String? avatarUrl}) => Assignee(
        id: id ?? this.id,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );

  @override
  List<Object?> get props => [id, name, avatarUrl];
}