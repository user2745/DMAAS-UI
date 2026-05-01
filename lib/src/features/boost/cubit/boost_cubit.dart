import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/boost_service.dart';
import 'boost_state.dart';

class BoostCubit extends Cubit<BoostState> {
  BoostCubit({required BoostService boostService})
      : _service = boostService,
        super(const BoostState()) {
    _loadCredits();
  }

  final BoostService _service;

  Future<void> _loadCredits() async {
    try {
      final credits = await _service.fetchCredits();
      emit(state.copyWith(credits: credits, creditsLoaded: true));
    } catch (_) {
      // Silently fail — credits show as 0 until next successful fetch
      emit(state.copyWith(creditsLoaded: true));
    }
  }

  Future<void> refreshCredits() => _loadCredits();

  Future<void> boost({
    required String taskId,
    required String taskTitle,
    String? taskDescription,
    required String intent,
  }) async {
    if (state.isLoading) return;

    emit(state.copyWith(status: BoostStatus.loading, result: null, errorMessage: null));

    try {
      final data = await _service.boost(
        taskId: taskId,
        taskTitle: taskTitle,
        taskDescription: taskDescription,
        intent: intent,
      );

      final result = data['result'] as String? ?? '';
      final creditsRemaining =
          (data['creditsRemaining'] as num?)?.toInt() ?? (state.credits - 1);

      emit(state.copyWith(
        status: BoostStatus.success,
        result: result,
        credits: creditsRemaining,
      ));
    } catch (e) {
      // ignore: avoid_print
      print('[BoostCubit] Error: $e');
      final msg = e.toString().contains('no_credits')
          ? 'You\'ve used all your boost credits.'
          : 'Boost error: $e';
      emit(state.copyWith(
        status: BoostStatus.error,
        errorMessage: msg,
      ));
    }
  }

  void reset() {
    emit(state.clearResult());
  }
}
