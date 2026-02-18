import 'package:equatable/equatable.dart';

enum BoostStatus { idle, loading, success, error }

class BoostState extends Equatable {
  const BoostState({
    this.status = BoostStatus.idle,
    this.credits = 0,
    this.result,
    this.errorMessage,
    this.creditsLoaded = false,
  });

  final BoostStatus status;
  final int credits;
  final String? result;
  final String? errorMessage;
  final bool creditsLoaded;

  bool get isLoading => status == BoostStatus.loading;
  bool get hasResult => status == BoostStatus.success && result != null;
  bool get hasError => status == BoostStatus.error;
  bool get noCredits => creditsLoaded && credits <= 0;

  BoostState copyWith({
    BoostStatus? status,
    int? credits,
    String? result,
    String? errorMessage,
    bool? creditsLoaded,
  }) {
    return BoostState(
      status: status ?? this.status,
      credits: credits ?? this.credits,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      creditsLoaded: creditsLoaded ?? this.creditsLoaded,
    );
  }

  BoostState clearResult() {
    return BoostState(
      status: BoostStatus.idle,
      credits: credits,
      creditsLoaded: creditsLoaded,
    );
  }

  @override
  List<Object?> get props =>
      [status, credits, result, errorMessage, creditsLoaded];
}
