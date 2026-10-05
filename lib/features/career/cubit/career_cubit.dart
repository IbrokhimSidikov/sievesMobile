import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api/api_service.dart';
import '../models/career_timeline_model.dart';

enum CareerStatus { loading, success, failure }

class CareerState extends Equatable {
  final CareerStatus status;
  final CareerTimeline? timeline;

  const CareerState({this.status = CareerStatus.loading, this.timeline});

  @override
  List<Object?> get props => [status, timeline];
}

class CareerCubit extends Cubit<CareerState> {
  final ApiService _api;

  CareerCubit(this._api) : super(const CareerState());

  /// Keeps the current timeline visible while refreshing.
  Future<void> load() async {
    if (state.timeline == null) {
      emit(const CareerState(status: CareerStatus.loading));
    }
    final timeline = await _api.getMyCareerTimeline();
    if (isClosed) return;
    if (timeline != null) {
      emit(CareerState(status: CareerStatus.success, timeline: timeline));
    } else if (state.timeline == null) {
      emit(const CareerState(status: CareerStatus.failure));
    }
  }
}
