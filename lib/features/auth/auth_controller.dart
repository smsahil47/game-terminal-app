import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/app_role.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthPhase { loading, signedOut, ready, denied, failed }

class AuthController extends ChangeNotifier {
  AuthController(this.repository) {
    _subscription = repository.changes.listen(
      _accept,
      onError: (Object error) {
        _generation++;
        role = null;
        phase = AuthPhase.failed;
        message = 'Your session could not be verified. Retry or sign out.';
        _notify();
      },
    );
    _accept(repository.currentUser);
  }
  final AuthRepository repository;
  late final StreamSubscription<StaffUser?> _subscription;
  AuthPhase phase = AuthPhase.loading;
  StaffUser? user;
  AppRole? role;
  String? message;
  bool busy = false;
  bool _disposed = false;
  int _generation = 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _accept(StaffUser? next) {
    final generation = ++_generation;
    user = next;
    role = null;
    message = null;
    phase = next == null ? AuthPhase.signedOut : AuthPhase.loading;
    _notify();
    if (next != null) unawaited(_resolve(next, generation));
  }

  Future<void> _resolve(StaffUser next, int generation) async {
    try {
      final resolved = await repository.fetchRole(next.id);
      if (_disposed || generation != _generation) return;
      role = resolved;
      phase = resolved == null ? AuthPhase.denied : AuthPhase.ready;
      message = resolved == null
          ? 'This account has no staff access assigned. Contact your administrator.'
          : null;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      phase = AuthPhase.failed;
      message = 'Could not verify your staff access. Check your connection and retry.';
    }
    _notify();
  }

  void retry() => _accept(repository.currentUser);
  Future<void> signIn(String email, String password) async {
    if (busy) return;
    busy = true;
    message = null;
    _notify();
    try {
      await repository.signIn(email.trim(), password);
      _accept(repository.currentUser);
    } on SignInFailure catch (error) {
      message = error.message;
    } catch (_) {
      message = 'Could not sign in. Please try again.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> signOut() async {
    if (busy) return;
    busy = true;
    _generation++;
    role = null;
    phase = AuthPhase.loading;
    _notify();
    try {
      await repository.signOut();
      _accept(null);
    } catch (_) {
      phase = AuthPhase.failed;
      message = 'Could not complete sign out. Please try again.';
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
