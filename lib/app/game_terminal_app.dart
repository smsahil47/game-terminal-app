import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../data/repositories/shop_repository.dart';
import '../data/repositories/operations_repository.dart';
import '../data/repositories/website_repository.dart';
import '../features/management/management_pages.dart';
import '../features/management/report_pages.dart';
import '../features/operations/operations_pages.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_pages.dart';
import '../features/shop/shop_pages.dart';
import 'staff_shell.dart';

String? authRedirect(AuthController auth, String path) {
  if (auth.phase == AuthPhase.loading) {
    return path == '/loading' ? null : '/loading';
  }
  if (auth.phase == AuthPhase.signedOut) {
    return path == '/login' ? null : '/login';
  }
  if (auth.phase == AuthPhase.denied || auth.phase == AuthPhase.failed) {
    return path == '/access' ? null : '/access';
  }
  final role = auth.role;
  if (role == null) return '/access';
  return role.canAccess(path) ? null : role.home;
}

class GameTerminalApp extends StatefulWidget {
  const GameTerminalApp({
    super.key,
    required this.auth,
    required this.shop,
    this.operations = const DisconnectedOperationsRepository(),
    this.website = const DisconnectedWebsiteRepository(),
    required this.connected,
    this.startupIssue,
    this.initialLocation = '/login',
  });
  final AuthController auth;
  final ShopRepository shop;
  final OperationsRepository operations;
  final WebsiteRepository website;
  final bool connected;
  final String? startupIssue;
  final String initialLocation;
  @override
  State<GameTerminalApp> createState() => _GameTerminalAppState();
}

class _GameTerminalAppState extends State<GameTerminalApp>
    with WidgetsBindingObserver {
  late final GoRouter router = GoRouter(
    initialLocation: widget.initialLocation,
    refreshListenable: widget.auth,
    redirect: (context, state) => authRedirect(widget.auth, state.uri.path),
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => LoginPage(
          auth: widget.auth,
          connected: widget.connected,
          startupIssue: widget.startupIssue,
        ),
      ),
      GoRoute(
        path: '/loading',
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/access',
        builder: (_, _) => AccessPage(auth: widget.auth),
      ),
      ShellRoute(
        builder: (context, state, child) => StaffShell(
          key: ValueKey('${widget.auth.user?.id}:${widget.auth.role}'),
          auth: widget.auth,
          repository: widget.shop,
          operations: widget.operations,
          website: widget.website,
          path: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, _) => ReceptionDashboardPage(operations: widget.operations,website:widget.website)),
          GoRoute(path: '/owner', builder: (_, _) => OwnerBusinessPage(operations:widget.operations)),
          GoRoute(path: '/stations', builder: (_, _) => const StationsPage()),
          GoRoute(path: '/owner/operations', builder: (_, _) => OwnerOperationsPage(operations:widget.operations)),
          GoRoute(path: '/station-details',builder: (_, _) => StationInsightsPage(website:widget.website)),
          GoRoute(path: '/game-terminal',builder: (_, _) => GameTerminalPage(repository:widget.website)),
          GoRoute(path: '/customers',builder: (_, _) => CustomersPage(repository:widget.website)),
          GoRoute(path: '/expenses',builder: (_, _) => ExpensesPage(repository:widget.website)),
          GoRoute(path: '/transactions',builder: (_, _) => TransactionsPage(repository:widget.website)),
          GoRoute(path: '/daily-report',builder: (_, _) => DailyReportPage(operations:widget.operations)),
          for (final path in ['/sessions', '/owner/sessions'])
            GoRoute(path: path, builder: (_, _) => SessionsPage(repository: widget.operations, website:widget.website, role: widget.auth.role!)),
          for (final path in ['/bookings', '/owner/bookings'])
            GoRoute(path: path, builder: (_, _) => BookingsPage(repository: widget.operations, website:widget.website, role: widget.auth.role!)),
          GoRoute(path: '/owner/reports', builder: (_, _) => OwnerBusinessPage(operations:widget.operations,reportsOnly:true)),
          for (final path in ['/account', '/owner/account'])
            GoRoute(
              path: path,
              builder: (_, _) => AccountPage(auth: widget.auth),
            ),
        ],
      ),
    ],
  );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.auth.user != null) {
      widget.auth.retry();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    router.dispose();
    widget.auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Game Terminal',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    routerConfig: router,
  );
}
