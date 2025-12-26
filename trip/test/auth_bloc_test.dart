import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:trip/src/features/auth/auth_bloc.dart';
import 'package:trip/src/features/auth/auth_repository.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  test('AuthBloc emits Authenticated on successful login', () async {
    final repo = _MockAuthRepo();
    when(
      () => repo.login('u', 'p'),
    ).thenAnswer((_) async => {'access': 'token', 'refresh': 'r'});

    final bloc = AuthBloc(repo);

    expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoading>(), isA<Authenticated>()]),
    );

    bloc.add(AuthLoginRequested('u', 'p'));
  });
}
