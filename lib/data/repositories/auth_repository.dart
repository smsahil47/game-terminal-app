import '../models/app_role.dart';

class StaffUser {
  const StaffUser(this.id, this.email);
  final String id;
  final String email;
}

class SignInFailure implements Exception {
  const SignInFailure(this.message);
  final String message;
}

abstract interface class AuthRepository {
  StaffUser? get currentUser;
  Stream<StaffUser?> get changes;
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<AppRole?> fetchRole(String userId);
}

class DisconnectedAuthRepository implements AuthRepository {
  const DisconnectedAuthRepository();
  @override
  StaffUser? get currentUser => null;
  @override
  Stream<StaffUser?> get changes => const Stream.empty();
  @override
  Future<AppRole?> fetchRole(String userId) async => null;
  @override
  Future<void> signIn(String email, String password) async =>
      throw const SignInFailure('Staff sign-in is not connected yet.');
  @override
  Future<void> signOut() async {}
}
