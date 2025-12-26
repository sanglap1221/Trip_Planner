import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../trip_details/trip_details_page.dart';
import 'trips_bloc.dart';

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Trips')),
      body: BlocBuilder<TripsBloc, TripsState>(
        builder: (context, state) {
          if (state is TripsInitial) {
            context.read<TripsBloc>().add(TripsRequested());
          }
          if (state is TripsLoading || state is TripsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TripsFailure) {
            return Center(child: Text(state.message));
          }
          final trips = (state as TripsLoaded).trips;
          if (trips.isEmpty) {
            return const Center(child: Text('No trips yet'));
          }
          return ListView.separated(
            itemCount: trips.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final t = trips[i];
              return ListTile(
                title: Text(t.name),
                subtitle: t.description == null || t.description!.isEmpty
                    ? null
                    : Text(t.description!),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        TripDetailsPage(tripId: t.id, tripName: t.name),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
