import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/game_terminal_app.dart';
import 'core/config/app_config.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/shop_repository.dart';
import 'data/repositories/operations_repository.dart';
import 'data/repositories/supabase_operations_repository.dart';
import 'data/repositories/supabase_auth_repository.dart';
import 'data/repositories/supabase_shop_repository.dart';
import 'data/repositories/website_repository.dart';
import 'data/repositories/supabase_website_repository.dart';
import 'features/auth/auth_controller.dart';
import 'services/secure_session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  AuthRepository auth = const DisconnectedAuthRepository();
  ShopRepository shop = const DisconnectedShopRepository();
  OperationsRepository operations = const DisconnectedOperationsRepository();
  WebsiteRepository website = const DisconnectedWebsiteRepository();
  var connected = false;
  String? startupIssue = config.validationError;
  if (config.enabled && startupIssue == null) {
    try {
      final supabase = await Supabase.initialize(
        url: config.url,
        publishableKey: config.publicKey,
        debug: false,
        authOptions: FlutterAuthClientOptions(
          detectSessionInUri: false,
          localStorage: SecureSessionStorage(Uri.parse(config.url).host),
        ),
      );
      auth = SupabaseAuthRepository(supabase.client);
      shop = SupabaseShopRepository(supabase.client);
      operations = SupabaseOperationsRepository(supabase.client);
      website = SupabaseWebsiteRepository(supabase.client);
      connected = true;
    } catch (_) {
      startupIssue =
          'Staff sign-in could not start. Please reopen the app and try again.';
    }
  }
  runApp(
    GameTerminalApp(
      auth: AuthController(auth),
      shop: shop,
      operations: operations,
      website: website,
      connected: connected,
      startupIssue: startupIssue,
    ),
  );
}
