import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/preferences_api_service.dart';
import '../models/user_preferences.dart';

class PreferencesCubit extends Cubit<UserPreferences> {
  PreferencesCubit({required PreferencesApiService apiService})
      : _apiService = apiService,
        super(const UserPreferences());

  final PreferencesApiService _apiService;

  Future<void> load() async {
    try {
      final prefs = await _apiService.getPreferences();
      emit(prefs);
    } catch (_) {
      // Keep defaults if load fails — non-critical
    }
  }

  Future<void> setRoadmapScheduleMode(String mode) async {
    emit(state.copyWith(roadmapScheduleMode: mode));
    _persist({'roadmapScheduleMode': mode});
  }

  Future<void> setRoadmapGroupBy(String? fieldId) async {
    emit(state.copyWith(roadmapGroupByFieldId: fieldId));
    _persist({'roadmapGroupByFieldId': fieldId});
  }

  Future<void> setRoadmapZoomLevel(String level) async {
    emit(state.copyWith(roadmapZoomLevel: level));
    _persist({'roadmapZoomLevel': level});
  }

  Future<void> _persist(Map<String, dynamic> patch) async {
    try {
      await _apiService.patchPreferences(patch);
    } catch (_) {
      // Best-effort — local state already updated
    }
  }
}
