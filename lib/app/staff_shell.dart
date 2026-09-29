import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        drawer: Drawer(child:SafeArea(child:ListView(children:[
          const ListTile(title:Text('Game Terminal')),
          for(final item in (role == AppRole.owner
            ? <(String,String,IconData)>[
                ('Overview',role.home,Icons.dashboard),('Shop Operations',role.stationsPath,Icons.store),
                ('Reports',role.reportsPath,Icons.bar_chart),('Account',role.accountPath,Icons.person)]
            : <(String,String,IconData)>[
                ('Dashboard',role.home,Icons.dashboard),('Bookings',role.bookingsPath,Icons.calendar_month),
                ('Sessions',role.sessionsPath,Icons.timer),('Stations',role.stationsPath,Icons.sports_esports),
                ('Station details',role.stationDetailsPath,Icons.display_settings),
                ('Transactions',role.transactionsPath,Icons.receipt_long),('Customers',role.customersPath,Icons.people),
                ('Expenses',role.expensesPath,Icons.account_balance_wallet),('Daily Report',role.dailyReportPath,Icons.summarize),
                ('Game Terminal',role.gameTerminalPath,Icons.settings),('Account',role.accountPath,Icons.person)]))
            ListTile(leading:Icon(item.$3),title:Text(item.$1),selected:widget.path==item.$2,
              onTap:(){Navigator.pop(context);context.go(item.$2);}),
        ]))),
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
