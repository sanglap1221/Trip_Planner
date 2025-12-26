import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/auth/auth_bloc.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/login_page.dart';
import 'features/trips/trips_bloc.dart';
import 'features/trips/trips_page.dart';
import 'services/api_client.dart';

class TripApp extends StatelessWidget {
  const TripApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient();
    final authRepo = AuthRepository(api);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepo),
        RepositoryProvider.value(value: api),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthBloc(authRepo)..add(AuthStarted())),
          BlocProvider(create: (_) => TripsBloc(api)),
        ],
        child: MaterialApp(
          title: 'Smart Trip Planner',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) return const TripsPage();
              if (state is AuthLoading)
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              return const LoginPage();
            },
          ),
        ),
      ),
    );
  }
}
