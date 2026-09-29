import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/app_role.dart';
import '../data/repositories/shop_repository.dart';
import '../data/repositories/operations_repository.dart';
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
    required this.path,
    required this.child,
  });
  final AuthController auth;
  final ShopRepository repository;
  final OperationsRepository operations;
  final String path;
  final Widget child;
  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  late final controller = ShopController(widget.repository);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.auth.role;
    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final paths = [role.home, role.stationsPath, role.sessionsPath, role.bookingsPath, if (role == AppRole.owner) role.reportsPath, role.accountPath];
    final index = paths.indexOf(widget.path);
    return ShopScope(
      controller: controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Game Terminal'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(label: Text(role.label)),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (role == AppRole.owner)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  child: const Text(
                    'Owner access · Shop operations are read-only',
                  ),
                ),
              Expanded(child: widget.child),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index < 0 ? 0 : index,
          onDestinationSelected: (selected) => context.go(paths[selected]),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: const Icon(Icons.sports_esports_outlined),
              label: role == AppRole.owner ? 'Operations' : 'Stations',
            ),
            const NavigationDestination(icon: Icon(Icons.timer_outlined), label: 'Sessions'),
            const NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Bookings'),
            if (role == AppRole.owner) const NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
