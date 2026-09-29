import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_terminal_app/data/models/app_role.dart';
import 'package:game_terminal_app/data/repositories/auth_repository.dart';
import 'package:game_terminal_app/features/auth/auth_controller.dart';
import 'package:game_terminal_app/app/game_terminal_app.dart';

import 'support/fakes.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);
void main() {
  test('signed-out users cannot open operational routes', () {
    final auth = AuthController(FakeAuthRepository());
    expect(authRedirect(auth, '/owner'), '/login');
    expect(authRedirect(auth, '/stations'), '/login');
    auth.dispose();
  });
  for (final role in AppRole.values) {
    test(
      '${role.label} restores a session and receives only assigned routes',
      () async {
        final auth = AuthController(
          FakeAuthRepository(
            user: const StaffUser('id', 'staff@test.invalid'),
            role: role,
          ),
        );
        expect(auth.phase, AuthPhase.loading);
        expect(authRedirect(auth, role.home), '/loading');
        await flush();
        expect(auth.role, role);
        expect(authRedirect(auth, role.home), isNull);
        final other = role == AppRole.owner ? '/stations' : '/owner/operations';
        expect(authRedirect(auth, other), role.home);
        expect(authRedirect(auth, '/unknown'), role.home);
        auth.dispose();
      },
    );
  }
  test('missing or unknown roles fail closed', () async {
    expect(AppRole.parse('ADMIN'), isNull);
    final auth = AuthController(
      FakeAuthRepository(user: const StaffUser('id', ''), role: null),
    );
    await flush();
    expect(auth.phase, AuthPhase.denied);
    expect(auth.role, isNull);
    expect(authRedirect(auth, '/dashboard'), '/access');
    auth.dispose();
  });
  test('role lookup failure permits retry, never grants access', () async {
    final repo = FakeAuthRepository(user: const StaffUser('id', ''));
    repo.resolve = (_) async => throw StateError('offline');
    final auth = AuthController(repo);
    await flush();
    expect(auth.phase, AuthPhase.failed);
    repo.resolve = (_) async => AppRole.owner;
    auth.retry();
    await flush();
    expect(auth.role, AppRole.owner);
    auth.dispose();
  });
  test('late role response cannot restore access after sign out', () async {
    final response = Completer<AppRole?>();
    final repo = FakeAuthRepository(user: const StaffUser('id', ''))
      ..resolve = (_) => response.future;
    final auth = AuthController(repo);
    await auth.signOut();
    response.complete(AppRole.owner);
    await flush();
    expect(auth.phase, AuthPhase.signedOut);
    expect(auth.role, isNull);
    auth.dispose();
  });
  test('old user role response cannot overwrite a newer account', () async {
    final first = Completer<AppRole?>();
    final repo = FakeAuthRepository(user: const StaffUser('first', ''))
      ..resolve = (id) =>
          id == 'first' ? first.future : Future.value(AppRole.receptionist);
    final auth = AuthController(repo);
    repo.emit(const StaffUser('second', ''));
    await flush();
    first.complete(AppRole.owner);
    await flush();
    expect(auth.user?.id, 'second');
    expect(auth.role, AppRole.receptionist);
    auth.dispose();
  });
  test('auth stream errors revoke route access', () async {
    final repo = FakeAuthRepository(user: const StaffUser('id', ''));
    final auth = AuthController(repo);
    await flush();
    repo.events.addError(StateError('refresh failed'));
    expect(auth.phase, AuthPhase.failed);
    expect(auth.role, isNull);
    auth.dispose();
  });
  test('sign in trims email and presents safe credential errors', () async {
    final repo = FakeAuthRepository()
      ..loginError = const SignInFailure('Email or password is incorrect.');
    final auth = AuthController(repo);
    await auth.signIn(' staff@test.invalid ', 'wrong');
    expect(repo.signedInEmail, 'staff@test.invalid');
    expect(auth.message, 'Email or password is incorrect.');
    expect(auth.busy, isFalse);
    expect(auth.role, isNull);
    auth.dispose();
  });
}
