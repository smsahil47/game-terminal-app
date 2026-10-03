import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_terminal_app/app/game_terminal_app.dart';
import 'package:game_terminal_app/data/models/app_role.dart';
import 'package:game_terminal_app/data/models/website_models.dart';
import 'package:game_terminal_app/data/repositories/auth_repository.dart';
import 'package:game_terminal_app/data/repositories/operations_repository.dart';
import 'package:game_terminal_app/data/repositories/website_repository.dart';
import 'package:game_terminal_app/features/auth/auth_controller.dart';

import 'support/fakes.dart';

class _Operations implements OperationsRepository {
  @override
  Future<List<String>> games() async => ['GTA 5'];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Website implements WebsiteRepository {
  @override
  Future<ShopConfiguration> configuration() async => ShopConfiguration(
    cafeName: 'Test shop',
    totalControllers: 6,
    gamingRate: 150,
    vrRate: 200,
    racingRate: 250,
    menuRates: const {},
    games: const ['GTA 5'],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('station Start Session opens a sheet without leaving stations',
      (tester) async {
    await tester.pumpWidget(GameTerminalApp(
      auth: AuthController(FakeAuthRepository(
        user: const StaffUser('staff-1', 'staff@test.invalid'),
        role: AppRole.receptionist,
      )),
      shop: FakeShopRepository(),
      operations: _Operations(),
      website: _Website(),
      connected: true,
      initialLocation: '/stations',
    ));
    await tester.pumpAndSettle();
    final start = find.widgetWithText(FilledButton, 'Start Session');
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Station 1'), findsOneWidget);
    expect(find.text('Session Duration'), findsOneWidget);
    expect(find.text('Players / Controllers'), findsOneWidget);
    expect(find.text('Sessions'), findsNothing);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Station 1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
