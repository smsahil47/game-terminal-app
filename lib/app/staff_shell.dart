import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../data/models/app_role.dart';
import '../data/repositories/shop_repository.dart';
import '../data/repositories/operations_repository.dart';
import '../data/repositories/website_repository.dart';
import '../features/auth/auth_controller.dart';
import '../features/shop/shop_controller.dart';

class ShopScope extends InheritedNotifier<ShopController> {
  const ShopScope({
    super.key,
    required ShopController controller,
    required super.child,
  }) : super(notifier: controller);
  static ShopController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShopScope>()!.notifier!;
}

class StaffShell extends StatefulWidget {
  const StaffShell({
    super.key,
    required this.auth,
    required this.repository,
    required this.operations,
    required this.website,
    required this.path,
    required this.child,
  });
  final AuthController auth;
  final ShopRepository repository;
  final OperationsRepository operations;
  final WebsiteRepository website;
  final String path;
  final Widget child;
  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  late final controller = ShopController(widget.repository);
  Timer? clock;
  DateTime now = DateTime.now();
  @override
  void initState() {
    super.initState();
    clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    clock?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.auth.role;
    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isOwner = role == AppRole.owner;
    final items = isOwner
        ? <(String, String, IconData)>[
            ('Overview', role.home, Icons.space_dashboard_outlined),
            ('Reports', role.reportsPath, Icons.bar_chart_outlined),
            ('Shop Operations', role.stationsPath, Icons.storefront_outlined),
            ('Sessions', role.sessionsPath, Icons.timer_outlined),
            ('Bookings', role.bookingsPath, Icons.calendar_month_outlined),
            ('Account', role.accountPath, Icons.person_outline),
          ]
        : <(String, String, IconData)>[
            ('Dashboard', role.home, Icons.space_dashboard_outlined),
            ('Bookings', role.bookingsPath, Icons.calendar_month_outlined),
            (
              'Transactions',
              role.transactionsPath,
              Icons.receipt_long_outlined,
            ),
            ('Customers', role.customersPath, Icons.people_outline),
            (
              'Expenses',
              role.expensesPath,
              Icons.account_balance_wallet_outlined,
            ),
            ('Daily Report', role.dailyReportPath, Icons.summarize_outlined),
            (
              'Game Terminal',
              role.gameTerminalPath,
              Icons.sports_esports_outlined,
            ),
            ('Stations', role.stationsPath, Icons.desktop_windows_outlined),
            ('Sessions', role.sessionsPath, Icons.timer_outlined),
            (
              'Station details',
              role.stationDetailsPath,
              Icons.display_settings_outlined,
            ),
            ('Account', role.accountPath, Icons.person_outline),
          ];
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final time =
        '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour < 12 ? 'AM' : 'PM'}';
    return ShopScope(
      controller: controller,
      child: Scaffold(
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  height: 152,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/brand/spidey.webp'),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      opacity: .32,
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x990A0E1A), AppTheme.surface],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/brand/logo.webp',
                          width: 68,
                          height: 68,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'GAME TERMINAL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            color: AppTheme.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: ListTile(
                            dense: true,
                            minTileHeight: 40,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            tileColor: widget.path == item.$2
                                ? AppTheme.accent.withValues(alpha: .18)
                                : null,
                            leading: Icon(
                              item.$3,
                              size: 18,
                              color: widget.path == item.$2
                                  ? AppTheme.accent
                                  : AppTheme.textMuted,
                            ),
                            title: Text(
                              item.$1,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: widget.path == item.$2
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: widget.path == item.$2
                                    ? AppTheme.text
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              context.go(item.$2);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_circle_outlined,
                        size: 26,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role.label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              widget.auth.user?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              tooltip: 'Open menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu, size: 20),
            ),
          ),
          titleSpacing: 0,
          title: Image.asset('assets/brand/logo.webp', width: 36, height: 36),
          actions: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '${now.day}/${now.month}/${now.year}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Account',
              onPressed: () => context.go(role.accountPath),
              icon: const Icon(Icons.account_circle_outlined, size: 25),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(child: widget.child),
      ),
    );
  }
}
