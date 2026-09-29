import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/staff_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/shop_snapshot.dart';
import 'shop_controller.dart';

class ShopOverviewPage extends StatelessWidget {
  const ShopOverviewPage({super.key});
  @override
  Widget build(BuildContext context) => _ShopBody(
    builder: (data) => [
      Text(data.cafeName, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      const Text('Shop overview'),
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
        Text('Stations', style: Theme.of(context).textTheme.headlineSmall),
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
    width: 160,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.accent, size: 22),
            const SizedBox(height: 16),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label),
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
                const Icon(Icons.sports_esports_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    station.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Flexible(
                  child: Text(
                    station.status.label,
                    style: TextStyle(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              station.type == 'PS5_MULTI'
                  ? 'Gaming · VR · Racing · Racing + VR'
                  : 'PlayStation 5',
            ),
            for (final session in sessions) ...[
              const Divider(height: 28),
              _SessionDetails(session: session),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        const Icon(Icons.sports_esports_outlined, size: 40),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}
