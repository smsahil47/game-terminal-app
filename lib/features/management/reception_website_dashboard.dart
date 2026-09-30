import 'package:flutter/material.dart';

import '../../data/models/operations.dart';
import '../../data/models/website_models.dart';
import '../../data/repositories/operations_repository.dart';
import '../../data/repositories/website_repository.dart';
import '../../services/live_shop_data.dart';
import '../operations/operations_pages.dart' show dateOnly;
import '../shop/shop_pages.dart';

class ReceptionWebsiteDashboardPage extends StatefulWidget {
  const ReceptionWebsiteDashboardPage({
    super.key,
    required this.operations,
    required this.website,
  });
  final OperationsRepository operations;
  final WebsiteRepository website;
  @override
  State<ReceptionWebsiteDashboardPage> createState() =>
      _ReceptionWebsiteDashboardPageState();
}

class _ReceptionWebsiteDashboardPageState
    extends State<ReceptionWebsiteDashboardPage>
    with LiveShopData {
  late Future<(List<Booking>, List<TransactionRecord>)> future = _load();
  Future<(List<Booking>, List<TransactionRecord>)> _load() async =>
      (await widget.operations.bookings(), await widget.website.transactions());

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<(List<Booking>, List<TransactionRecord>)>(
        future: future = refreshOnShopChange(future, _load),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return const WebsiteDashboardPage(
                todayBookings: 0,
                todayRevenue: 0,
                upcoming: [],
                summaryError: 'Booking and revenue data unavailable. Pull to retry.',
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          final (bookings, sales) = snapshot.data!;
          final today = dateOnly(DateTime.now());
          final upcoming =
              bookings
                  .where((b) => b.date == today && b.status == 'CONFIRMED')
                  .toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime));
          final revenue = sales
              .where((t) => dateOnly(t.date.toLocal()) == today)
              .fold<int>(0, (sum, t) => sum + t.total);
          return WebsiteDashboardPage(
            todayBookings: upcoming.length,
            todayRevenue: revenue,
            upcoming: [
              for (final b in upcoming)
                (
                  b.startTime,
                  b.customerName,
                  '${b.stationName} · ${b.mode.label}',
                ),
            ],
          );
        },
      );
}
