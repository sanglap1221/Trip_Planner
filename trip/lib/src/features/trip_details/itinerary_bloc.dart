import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../services/api_client.dart';

// Events
abstract class ItineraryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ItineraryLoadRequested extends ItineraryEvent {
  final int tripId;
  ItineraryLoadRequested(this.tripId);
  @override
  List<Object?> get props => [tripId];
}

class ItineraryReorderRequested extends ItineraryEvent {
  final int tripId;
  final int oldIndex;
  final int newIndex;

  ItineraryReorderRequested(this.tripId, this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [tripId, oldIndex, newIndex];
}

// States
abstract class ItineraryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ItineraryLoading extends ItineraryState {}

class ItineraryEmpty extends ItineraryState {}

class ItineraryLoaded extends ItineraryState {
  final List<Map<String, dynamic>> items;

  ItineraryLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

class ItineraryError extends ItineraryState {
  final String message;

  ItineraryError({this.message = 'Failed to load itinerary'});

  @override
  List<Object?> get props => [message];
}

class ItineraryBloc extends Bloc<ItineraryEvent, ItineraryState> {
  final ApiClient _api;

  ItineraryBloc(this._api) : super(ItineraryLoading()) {
    on<ItineraryLoadRequested>(_onLoadRequested);
    on<ItineraryReorderRequested>(_onReorderRequested);
  }

  Future<void> _onLoadRequested(
    ItineraryLoadRequested event,
    Emitter<ItineraryState> emit,
  ) async {
    emit(ItineraryLoading());
    try {
      final res = await _api.get(
        'itinerary-items/',
        query: {'trip': event.tripId},
      );
      final items = List<Map<String, dynamic>>.from(res.data as List);
      items.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

      if (items.isEmpty) {
        emit(ItineraryEmpty());
      } else {
        emit(ItineraryLoaded(items));
      }
    } catch (e) {
      emit(ItineraryError(message: _parseError(e)));
    }
  }

  Future<void> _onReorderRequested(
    ItineraryReorderRequested event,
    Emitter<ItineraryState> emit,
  ) async {
    // Optimistically update UI
    if (state is ItineraryLoaded) {
      final current = (state as ItineraryLoaded).items;
      final list = List<Map<String, dynamic>>.from(current);
      int newIndex = event.newIndex;
      if (newIndex > event.oldIndex) newIndex -= 1;
      final item = list.removeAt(event.oldIndex);
      list.insert(newIndex, item);
      emit(ItineraryLoaded(list));
    }

    try {
      final current = (state as ItineraryLoaded).items;
      final orderIds = current.map((e) => e['id']).toList();
      await _api.post(
        'trips/${event.tripId}/reorder-itinerary/',
        data: {'order': orderIds},
      );
    } catch (e) {
      emit(ItineraryError(message: _parseError(e)));
      // Reload to sync
      add(ItineraryLoadRequested(event.tripId));
    }
  }

  String _parseError(Object? error) {
    if (error.toString().contains('401')) {
      return 'Session expired. Please log in again.';
    }
    return 'An error occurred. Please try again.';
  }
}
