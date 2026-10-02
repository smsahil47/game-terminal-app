import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_terminal_app/app/game_terminal_app.dart';
import 'package:go_router/go_router.dart';
import 'package:game_terminal_app/data/models/app_role.dart';
import 'package:game_terminal_app/data/repositories/auth_repository.dart';
import 'package:game_terminal_app/features/auth/auth_controller.dart';

import 'support/fakes.dart';

void main() {
  testWidgets(
    'unconfigured build shows login without enabling backend or loading data',
    (tester) async {
      final repo = FakeAuthRepository();
      final shop = FakeShopRepository();
      await tester.pumpWidget(
        GameTerminalApp(
          auth: AuthController(repo),
          shop: shop,
          connected: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Staff access only'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Sign in'))
            .onPressed,
        isNull,
      );
      expect(repo.loginCalls, 0);
      expect(shop.loads, 0);
    },
  );
  testWidgets('validates fields before sending credentials', (tester) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(
      GameTerminalApp(
        auth: AuthController(repo),
        shop: FakeShopRepository(),
        connected: true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    expect(repo.loginCalls, 0);
  });
  testWidgets(
    'receptionist signs in, sees station data and filters availability',
    (tester) async {
      final repo = FakeAuthRepository();
      await tester.pumpWidget(
        GameTerminalApp(
          auth: AuthController(repo),
          shop: FakeShopRepository(),
          connected: true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'staff@test.invalid',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Consoles free'), findsOneWidget);
      expect(find.text('4 / 6'), findsOneWidget);
      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      for (final title in [
        'Dashboard',
        'Bookings',
        'Transactions',
        'Customers',
        'Expenses',
        'Daily Report',
        'Game Terminal',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('Stations'), findsNothing);
      expect(find.text('Sessions'), findsNothing);
      Navigator.of(tester.element(find.byType(Drawer))).pop();
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.text('Consoles free'))).go('/stations');
      await tester.pumpAndSettle();
      expect(find.text('Station 1'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Available'));
      await tester.pumpAndSettle();
      expect(find.text('Station 2'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'In use'));
      await tester.pumpAndSettle();
      expect(find.text('Station 2'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'owner cannot deep link into receptionist routes and sees read-only operations',
    (tester) async {
      final repo = FakeAuthRepository(
        user: const StaffUser('owner', 'owner@test.invalid'),
        role: AppRole.owner,
      );
      await tester.pumpWidget(
        GameTerminalApp(
          auth: AuthController(repo),
          shop: FakeShopRepository(),
          connected: true,
          initialLocation: '/stations',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Business Overview'), findsOneWidget);
      await tester.tap(find.byTooltip('Open menu'));
      await tester.pumpAndSettle();
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Shop Operations'), findsOneWidget);
      expect(find.text('Sessions'), findsNothing);
      expect(find.text('Bookings'), findsNothing);
      await tester.tap(find.text('Shop Operations'));
      await tester.pumpAndSettle();
      expect(find.text('Station 1'), findsOneWidget);
      expect(find.text('Start session'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('unassigned account sees access notice and no shop data', (
    tester,
  ) async {
    final shop = FakeShopRepository();
    await tester.pumpWidget(
      GameTerminalApp(
        auth: AuthController(
          FakeAuthRepository(user: const StaffUser('missing', ''), role: null),
        ),
        shop: shop,
        connected: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No access assigned'), findsOneWidget);
    expect(shop.loads, 0);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Staff access only'), findsOneWidget);
  });
}
