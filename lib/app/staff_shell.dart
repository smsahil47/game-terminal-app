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
import '../services/session_alarm.dart';

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
  Timer? alertClock;
  DateTime now = DateTime.now();
  final alertedSessions = <String>{};
  final openAlerts = <String>{};
  bool alarmPlaying = false;
  @override
  void initState() {
    super.initState();
    clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
    controller.addListener(_checkDurationAlerts);
    alertClock = Timer.periodic(const Duration(seconds: 1), (_) => _checkDurationAlerts());
  }

  void _checkDurationAlerts() {
    if (!mounted || widget.auth.role != AppRole.receptionist) return;
    final snapshot = controller.snapshot;
    if (snapshot == null) return;
    final checkedAt = DateTime.now();
    for (final session in snapshot.sessions) {
      if (!session.isDue(checkedAt)) continue;
      final key = '${session.id}:${session.targetMinutes}';
      if (!alertedSessions.add(key)) continue;
      openAlerts.add(key);
      final station = snapshot.stations
          .where((item) => item.id == session.stationId)
          .firstOrNull;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !openAlerts.contains(key)) return;
        final target = session.targetMinutes!;
        final label = target == 60
            ? '1 Hour'
            : target % 60 == 0
                ? '${target ~/ 60} Hours'
                : '$target Minutes';
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            leading: const Icon(Icons.alarm, color: AppTheme.warning),
            content: Text(
              '${station?.name ?? 'Station'} has reached $label\n'
              '${session.customerName} · started ${TimeOfDay.fromDateTime(session.startedAt.toLocal()).format(context)}',
            ),
            actions: [
              TextButton(
                onPressed: () => _dismissDurationAlert(key),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        );
        if (!alarmPlaying) {
          alarmPlaying = true;
          unawaited(SessionAlarm.start());
        }
      });
    }
  }

  void _dismissDurationAlert(String key) {
    openAlerts.remove(key);
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    if (openAlerts.isEmpty) {
      alarmPlaying = false;
      unawaited(SessionAlarm.stop());
    }
  }

  @override
  void dispose() {
    clock?.cancel();
    alertClock?.cancel();
    controller.removeListener(_checkDurationAlerts);
    unawaited(SessionAlarm.stop());
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
                  height: 116,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/brand/logo.webp',
                    width: 88,
                    height: 88,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: .9,
                          child: Image.asset(
                            'assets/brand/spidey.webp',
                            fit: BoxFit.cover,
                            alignment: Alignment.bottomLeft,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.surface,
                                AppTheme.surface,
                                AppTheme.surface.withValues(alpha: .55),
                                AppTheme.background.withValues(alpha: .15),
                              ],
                              stops: const [0, .3, .7, 1],
                            ),
                          ),
                        ),
                      ),
                      ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
                            child: Text(
                              'MENU',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
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
        body: Stack(
          children: [
            if (widget.path != '/dashboard')
              Positioned.fill(
                child: Image.asset(
                  'assets/brand/background.webp',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            SafeArea(child: widget.child),
          ],
        ),
      ),
    );
  }
}
