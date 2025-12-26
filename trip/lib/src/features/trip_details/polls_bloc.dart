import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../services/api_client.dart';

// Events
abstract class PollsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PollsLoadRequested extends PollsEvent {
  final int tripId;
  PollsLoadRequested(this.tripId);
  @override
  List<Object?> get props => [tripId];
}

class PollsVoteRequested extends PollsEvent {
  final int pollId;
  final int optionId;
  PollsVoteRequested(this.pollId, this.optionId);
  @override
  List<Object?> get props => [pollId, optionId];
}

// States
abstract class PollsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PollsLoading extends PollsState {}

class PollsEmpty extends PollsState {}

class PollsLoaded extends PollsState {
  final List<Map<String, dynamic>> polls;

  PollsLoaded(this.polls);

  @override
  List<Object?> get props => [polls];
}

class PollsError extends PollsState {
  final String message;

  PollsError({this.message = 'Failed to load polls'});

  @override
  List<Object?> get props => [message];
}

class PollsBloc extends Bloc<PollsEvent, PollsState> {
  final ApiClient _api;
  int? _currentTripId;

  PollsBloc(this._api) : super(PollsLoading()) {
    on<PollsLoadRequested>(_onLoadRequested);
    on<PollsVoteRequested>(_onVoteRequested);
  }

  Future<void> _onLoadRequested(
    PollsLoadRequested event,
    Emitter<PollsState> emit,
  ) async {
    emit(PollsLoading());
    _currentTripId = event.tripId;
    try {
      final res = await _api.get('polls/', query: {'trip': event.tripId});
      final polls = List<Map<String, dynamic>>.from(res.data as List);

      if (polls.isEmpty) {
        emit(PollsEmpty());
      } else {
        emit(PollsLoaded(polls));
      }
    } catch (e) {
      emit(PollsError(message: _parseError(e)));
    }
  }

  Future<void> _onVoteRequested(
    PollsVoteRequested event,
    Emitter<PollsState> emit,
  ) async {
    try {
      await _api.post(
        'polls/${event.pollId}/vote/',
        data: {'option_id': event.optionId},
      );
      // Reload after voting
      if (_currentTripId != null) {
        add(PollsLoadRequested(_currentTripId!));
      }
    } catch (e) {
      emit(PollsError(message: _parseError(e)));
    }
  }

  String _parseError(Object? error) {
    if (error.toString().contains('401')) {
      return 'Session expired. Please log in again.';
    }
    return 'An error occurred. Please try again.';
  }
}
