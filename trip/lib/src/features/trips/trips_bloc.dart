import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../services/api_client.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TripSummary extends Equatable {
  final int id;
  final String name;
  final String? description;
  const TripSummary({required this.id, required this.name, this.description});
  @override
  List<Object?> get props => [id, name, description];
}

abstract class TripsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TripsRequested extends TripsEvent {}

class TripCreated extends TripsEvent {
  final String name;
  final String description;
  TripCreated({required this.name, required this.description});
  @override
  List<Object?> get props => [name, description];
}

abstract class TripsState extends Equatable {
  const TripsState();
  @override
  List<Object?> get props => [];
}

class TripsInitial extends TripsState {
  const TripsInitial();
}

class TripsLoading extends TripsState {
  const TripsLoading();
}

class TripsLoaded extends TripsState {
  final List<TripSummary> trips;
  const TripsLoaded(this.trips);
  @override
  List<Object?> get props => [trips];
}

class TripsFailure extends TripsState {
  final String message;
  const TripsFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class TripsBloc extends Bloc<TripsEvent, TripsState> {
  final ApiClient _api;
  TripsBloc(this._api) : super(TripsInitial()) {
    on<TripsRequested>((event, emit) async {
      // Only show loading if we're not already in a loaded state
      if (state is! TripsLoaded) {
        emit(TripsLoading());
      }
      try {
        final res = await _api.get('trips/');
        final list = (res.data as List)
            .map(
              (e) => TripSummary(
                id: e['id'] as int,
                name: e['name'] as String,
                description: e['description'] as String?,
              ),
            )
            .toList();
        final box = await Hive.openBox('cache');
        await box.put('trips', res.data);
        emit(TripsLoaded(list));
      } catch (e) {
        // Fallback to cached
        try {
          final box = await Hive.openBox('cache');
          final cached = box.get('trips') as List?;
          if (cached != null) {
            final list = cached
                .map(
                  (e) => TripSummary(
                    id: e['id'] as int,
                    name: e['name'] as String,
                    description: e['description'] as String?,
                  ),
                )
                .toList();
            emit(TripsLoaded(list));
            return;
          }
        } catch (_) {}
        emit(const TripsFailure('Failed to load trips'));
      }
    });
    on<TripCreated>((event, emit) async {
      try {
        final res = await _api.post(
          'trips/',
          data: {'name': event.name, 'description': event.description},
        );
        // Optimistically add the new trip to the current list
        if (state is TripsLoaded) {
          final currentTrips = (state as TripsLoaded).trips;
          final newTrip = TripSummary(
            id: res.data['id'] as int,
            name: res.data['name'] as String,
            description: res.data['description'] as String?,
          );
          final updatedTrips = [...currentTrips, newTrip];
          emit(TripsLoaded(updatedTrips));
        } else {
          // If not loaded, trigger a full reload
          add(TripsRequested());
        }
      } catch (e) {
        emit(const TripsFailure('Failed to create trip'));
      }
    });
  }
}
