import 'package:equatable/equatable.dart';

class UserPreferences extends Equatable {
  const UserPreferences({
    this.roadmapScheduleMode = 'gantt',
    this.roadmapGroupByFieldId,
    this.roadmapZoomLevel = 'month',
  });

  final String roadmapScheduleMode;
  final String? roadmapGroupByFieldId;
  final String roadmapZoomLevel;

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      roadmapScheduleMode:
          (json['roadmapScheduleMode'] as String?) ?? 'gantt',
      roadmapGroupByFieldId: json['roadmapGroupByFieldId'] as String?,
      roadmapZoomLevel: (json['roadmapZoomLevel'] as String?) ?? 'month',
    );
  }

  Map<String, dynamic> toJson() => {
        'roadmapScheduleMode': roadmapScheduleMode,
        'roadmapGroupByFieldId': roadmapGroupByFieldId,
        'roadmapZoomLevel': roadmapZoomLevel,
      };

  UserPreferences copyWith({
    String? roadmapScheduleMode,
    Object? roadmapGroupByFieldId = _sentinel,
    String? roadmapZoomLevel,
  }) {
    return UserPreferences(
      roadmapScheduleMode: roadmapScheduleMode ?? this.roadmapScheduleMode,
      roadmapGroupByFieldId: roadmapGroupByFieldId == _sentinel
          ? this.roadmapGroupByFieldId
          : roadmapGroupByFieldId as String?,
      roadmapZoomLevel: roadmapZoomLevel ?? this.roadmapZoomLevel,
    );
  }

  @override
  List<Object?> get props => [
        roadmapScheduleMode,
        roadmapGroupByFieldId,
        roadmapZoomLevel,
      ];
}

const Object _sentinel = Object();
