import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/staff_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/website_widgets.dart';
import '../../data/models/shop_snapshot.dart';
import 'shop_controller.dart';
import 'ps5_model_stage.dart';
import '../operations/start_session_sheet.dart';

class ShopOverviewPage extends StatelessWidget {
  const ShopOverviewPage({super.key});
  @override
  Widget build(BuildContext context) => _ShopBody(
    builder: (data) => [
      Text(data.cafeName, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      const Text('Shop overview'),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: () async {
            final controller = ShopScope.of(context);
            final dependencies = ShopScope.dependenciesOf(context);
            final started = await showStartSessionSheet(
              context,
              data,
              dependencies.operations,
              dependencies.website,
            );
            if (started) await controller.refresh();
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start session'),
        ),
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _Metric(
            label: 'Stations free',
            value: '${data.available} / ${data.stations.length}',
            icon: Icons.desktop_windows,
          ),
          _Metric(
            label: 'Active sessions',
            value: '${data.sessions.length}',
            icon: Icons.timer_outlined,
          ),
          _Metric(
            label: 'Controllers free',
            value: '${data.controllersFree} / ${data.totalControllers}',
            icon: Icons.sports_esports,
          ),
          _Metric(
            label: 'Maintenance',
            value:
                '${data.stations.where((s) => s.status == StationStatus.maintenance).length}',
            icon: Icons.build_outlined,
          ),
        ],
      ),
      const SizedBox(height: 28),
      Text('Live sessions', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      if (data.sessions.isEmpty)
        const _Empty('No active sessions', 'Running sessions will appear here.')
      else
        for (final session in data.sessions)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _SessionDetails(
                session: session,
                stationName:
                    data.stations
                        .where((s) => s.id == session.stationId)
                        .firstOrNull
                        ?.name ??
                    'Station',
              ),
            ),
          ),
    ],
  );
}

class WebsiteDashboardPage extends StatelessWidget {
  const WebsiteDashboardPage({
    super.key,
    required this.todayBookings,
    required this.todayRevenue,
    required this.upcoming,
    this.summaryError,
  });
  final int todayBookings;
  final int todayRevenue;
  final List<(String, String, String)> upcoming;
  final String? summaryError;

  @override
  Widget build(BuildContext context) => _ShopBody(
    builder: (data) {
      final hour = DateTime.now().hour;
      final greeting = hour < 12
          ? 'Good morning'
          : hour < 17
          ? 'Good afternoon'
          : 'Good evening';
      final live = data.sessions.length;
      return [
        Container(
          height: 132,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: const DecorationImage(
              image: AssetImage('assets/brand/ps5.webp'),
              alignment: Alignment.centerRight,
              fit: BoxFit.cover,
              opacity: .36,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppTheme.background,
                  Color(0x9905070E),
                  Color(0x1105070E),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  live == 0
                      ? "No sessions running. Here's today's overview."
                      : '$live session${live == 1 ? '' : 's'} running right now.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (summaryError != null) ...[
          WebsiteStatusPanel(summaryError!, icon: Icons.cloud_off_outlined),
          const SizedBox(height: 14),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Metric(
              label: 'Consoles free',
              value: '${data.available} / ${data.stations.length}',
              icon: Icons.desktop_windows_outlined,
            ),
            _Metric(
              label: 'Controllers free',
              value: '${data.controllersFree} / ${data.totalControllers}',
              icon: Icons.sports_esports_outlined,
            ),
            _Metric(
              label: 'Live sessions',
              value: '$live',
              icon: Icons.play_circle_outline,
            ),
            _Metric(
              label: "Today's bookings",
              value: summaryError == null ? '$todayBookings' : '—',
              icon: Icons.calendar_month_outlined,
            ),
            _Metric(
              label: "Today's revenue",
              value: summaryError == null ? '₹$todayRevenue' : '—',
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            const Expanded(
              child: Text(
                'STATIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            Text(
              '${data.available} available · $live live',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (data.stations.isEmpty)
          const _Empty(
            'No stations',
            'Stations will appear here when available.',
          ),
        for (final station in data.stations)
          _StationCard(
            station: station,
            sessions: data.sessions
                .where((s) => s.stationId == station.id)
                .toList(),
          ),
        const SizedBox(height: 20),
        const Text(
          'UPCOMING TODAY',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        if (upcoming.isEmpty)
          const _Empty(
            'No upcoming bookings',
            'Confirmed bookings for today will appear here.',
          ),
        for (final item in upcoming)
          Card(
            child: ListTile(
              leading: Text(
                item.$1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              title: Text(item.$2),
              subtitle: Text(item.$3),
            ),
          ),
      ];
    },
  );
}

class StationsPage extends StatefulWidget {
  const StationsPage({super.key});
  @override
  State<StationsPage> createState() => _StationsPageState();
}

class _StationsPageState extends State<StationsPage> {
  StationStatus? filter;
  @override
  Widget build(BuildContext context) => _ShopBody(
    builder: (data) {
      final stations = data.stations
          .where((s) => filter == null || s.status == filter)
          .toList();
      return [
        Row(
          children: [
            Expanded(
              child: Text(
                'Stations',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/station-details'),
              child: const Text('Rates & usage'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('Availability and current sessions across the shop.'),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: filter == null,
              onSelected: (_) => setState(() => filter = null),
            ),
            for (final status in StationStatus.values)
              ChoiceChip(
                label: Text(status.label),
                selected: filter == status,
                onSelected: (_) => setState(() => filter = status),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (stations.isEmpty)
          const _Empty(
            'No stations found',
            'Try another status or refresh the shop.',
          )
        else
          for (final station in stations)
            _StationCard(
              station: station,
              sessions: data.sessions
                  .where((s) => s.stationId == station.id)
                  .toList(),
            ),
      ];
    },
  );
}

class _ShopBody extends StatelessWidget {
  const _ShopBody({required this.builder});
  final List<Widget> Function(ShopSnapshot) builder;
  @override
  Widget build(BuildContext context) {
    final controller = ShopScope.of(context);
    final data = controller.snapshot;
    if (data == null && controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _SyncStatus(controller: controller),
          const SizedBox(height: 16),
          if (data != null)
            ...builder(data)
          else
            const _Empty(
              'Shop data unavailable',
              'Refresh to try loading the shop again.',
            ),
        ],
      ),
    );
  }
}

class _SyncStatus extends StatelessWidget {
  const _SyncStatus({required this.controller});
  final ShopController controller;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        controller.error != null ? Icons.cloud_off : Icons.sync,
        size: 18,
        color: controller.error != null ? AppTheme.warning : AppTheme.accent,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          controller.error != null
              ? '${controller.error!}${controller.snapshot != null ? ' Showing last loaded data.' : ''}'
              : controller.loading
              ? 'Refreshing shop…'
              : controller.realtimeConnected
              ? 'Connected · updates automatically'
              : 'Live updates disconnected · pull to refresh',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      IconButton(
        tooltip: 'Refresh shop',
        onPressed: controller.loading ? null : controller.refresh,
        icon: const Icon(Icons.refresh),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: (MediaQuery.sizeOf(context).width - 50).clamp(0, 360) / 2,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Icon(icon, color: AppTheme.textMuted, size: 15),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                height: 1.0,
                fontWeight: FontWeight.w600,
                color: AppTheme.text,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StationCard extends StatelessWidget {
  const _StationCard({required this.station, required this.sessions});
  final Station station;
  final List<ActiveSession> sessions;
  Future<void> _startSession(BuildContext context, {SessionMode? mode}) async {
    final controller = ShopScope.of(context);
    final shop = controller.snapshot;
    if (shop == null) return;
    final dependencies = ShopScope.dependenciesOf(context);
    final started = await showStartSessionSheet(
      context,
      shop,
      dependencies.operations,
      dependencies.website,
      stationId: station.id,
      initialMode: mode,
    );
    if (started) await controller.refresh();
  }

  Future<void> _setMaintenance(BuildContext context, bool unavailable) async {
    final controller = ShopScope.of(context);
    try {
      await controller.repository.setMaintenance(station.id, unavailable: unavailable);
      await controller.refresh();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final color = switch (station.status) {
      StationStatus.available => AppTheme.success,
      StationStatus.inUse => AppTheme.accent,
      StationStatus.maintenance => AppTheme.warning,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    station.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  station.status == StationStatus.inUse
                      ? 'Live'
                      : station.status.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (station.status == StationStatus.available)
                  PopupMenuButton<String>(
                    tooltip: 'More options for ${station.name}',
                    icon: const Icon(Icons.more_horiz, size: 18),
                    onSelected: (_) => _setMaintenance(context, true),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'unavailable',
                        child: Text('Mark unavailable'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Ps5ModelStage(),
            const SizedBox(height: 12),
            Text(
              station.type == 'PS5_MULTI'
                  ? 'Gaming · VR · Racing · Racing + VR'
                  : 'PlayStation 5',
            ),
            for (final session in sessions) ...[
              const Divider(height: 28),
              _SessionDetails(session: session),
            ],
            if (station.status == StationStatus.inUse && sessions.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push(
                    '/sessions?checkoutStation=${Uri.encodeComponent(station.id)}',
                  ),
                  icon: const Icon(Icons.stop, size: 17),
                  label: const Text('End Session'),
                ),
              ),
            ],
            if (station.status == StationStatus.available) ...[
              const SizedBox(height: 14),
              if (station.type == 'PS5_MULTI')
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final mode in SessionMode.values)
                      OutlinedButton(
                        onPressed: () => _startSession(context, mode: mode),
                        child: Text(mode.label),
                      ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _startSession(context),
                    icon: const Icon(Icons.play_arrow, size: 17),
                    label: const Text('Start Session'),
                  ),
                ),
            ],
            if (station.status == StationStatus.maintenance) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                  'Station unavailable',
                  style: TextStyle(fontSize: 12, color: AppTheme.warning),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _setMaintenance(context, false),
                  child: const Text('Mark as available'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionDetails extends StatefulWidget {
  const _SessionDetails({required this.session, this.stationName});
  final ActiveSession session;
  final String? stationName;
  @override
  State<_SessionDetails> createState() => _SessionDetailsState();
}

class _SessionDetailsState extends State<_SessionDetails> {
  late final Timer timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final now = DateTime.now();
    final elapsed = session.elapsed(now);
    final duration =
        '${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.stationName != null)
          Text(
            widget.stationName!,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        Text(
          session.customerName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          '${session.mode.label}${session.mode == SessionMode.gaming ? ' · ${session.players ?? 1} player(s)' : ''}',
        ),
        if (session.game?.isNotEmpty == true) Text(session.game!),
        const SizedBox(height: 10),
        Text(
          duration,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontFeatures: [const FontFeature.tabularFigures()]),
        ),
        if (session.status == 'EXTENDED') const Text('Extended session'),
        if (session.targetMinutes != null)
          Text(
            session.isDue(now)
                ? 'Selected duration reached · ${session.targetMinutes} min'
                : 'Reminder at ${session.targetMinutes} min',
            style: TextStyle(
              color: session.isDue(now) ? AppTheme.warning : null,
            ),
          ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.title, this.message);
  final String title, message;
  @override
  Widget build(BuildContext context) => WebsiteStatusPanel(
    title,
    message: message,
    icon: Icons.sports_esports_outlined,
  );
}
