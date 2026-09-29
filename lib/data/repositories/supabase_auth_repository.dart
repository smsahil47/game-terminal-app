import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_role.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);
  final SupabaseClient client;
  StaffUser? _map(User? user) =>
      user == null ? null : StaffUser(user.id, user.email ?? '');
  @override
  StaffUser? get currentUser => _map(client.auth.currentUser);
  @override
  Stream<StaffUser?> get changes =>
      client.auth.onAuthStateChange.map((event) => _map(event.session?.user));
  @override
  Future<AppRole?> fetchRole(String userId) async {
    final row = await client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    return AppRole.parse(row?['role']);
  }

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (error) {
      throw SignInFailure(switch (error.code) {
        'invalid_credentials' => 'Email or password is incorrect.',
        'email_not_confirmed' =>
          'Your account is not confirmed. Contact your administrator.',
        'over_request_rate_limit' =>
          'Too many attempts. Please try again shortly.',
        _ => 'Could not sign in. Check your details and try again.',
      });
    } catch (_) {
      throw const SignInFailure(
        'Could not connect. Check your connection and try again.',
      );
    }
  }

  @override
  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.local);
}
