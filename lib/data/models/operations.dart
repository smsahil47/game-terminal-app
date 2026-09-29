import 'shop_snapshot.dart';

class Snack {
  const Snack(this.name, this.price);
  final String name;
  final int price;
  factory Snack.fromJson(Map<String, dynamic> row) => Snack(row['name'] as String, (row['price'] as num).round());
  Map<String, dynamic> toJson() => {'name': name, 'price': price};
}

class SessionDetail {
  const SessionDetail({required this.id, required this.stationId, required this.stationName, required this.customerName, required this.mode, required this.startedAt, required this.status, required this.durationMinutes, required this.extraMinutes, required this.ratePerHour, required this.snacks, this.customerPhone, this.players, this.game, this.bookedPlayAmount, this.targetMinutes, this.endedAt, this.notes});
  final String id, stationId, stationName, customerName, status;
  final String? customerPhone, game, notes;
  final SessionMode mode;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMinutes, extraMinutes, ratePerHour;
  final int? players, bookedPlayAmount, targetMinutes;
  final List<Snack> snacks;
  int get snacksTotal => snacks.fold(0, (sum, item) => sum + item.price);
  factory SessionDetail.fromJson(Map<String, dynamic> row) => SessionDetail(
    id: row['id'] as String, stationId: row['station_id'] as String,
    stationName: row['station_name'] as String, customerName: row['customer_name'] as String,
    customerPhone: row['customer_phone'] as String?, mode: SessionMode.parse(row['mode']),
    startedAt: DateTime.parse(row['start_time'] as String), endedAt: DateTime.tryParse(row['end_time'] as String? ?? ''),
    status: row['status'] as String, durationMinutes: (row['duration_minutes'] as num).toInt(),
    extraMinutes: (row['extra_minutes'] as num).toInt(), ratePerHour: (row['rate_per_hour'] as num).round(),
    bookedPlayAmount: (row['booked_play_amount'] as num?)?.round(), targetMinutes: (row['target_duration_minutes'] as num?)?.toInt(),
    players: (row['player_count'] as num?)?.toInt(), game: row['game'] as String?, notes: row['notes'] as String?,
    snacks: ((row['snacks'] as List?) ?? []).map((item) => Snack.fromJson(Map<String, dynamic>.from(item as Map))).toList(),
  );
}

class Booking {
  const Booking({required this.id, required this.customerName, required this.stationId, required this.stationName, required this.mode, required this.date, required this.startTime, required this.durationMinutes, required this.status, required this.advanceAmount, this.customerPhone, this.notes});
  final String id, customerName, stationId, stationName, date, startTime, status;
  final String? customerPhone, notes;
  final SessionMode mode;
  final int durationMinutes, advanceAmount;
  factory Booking.fromJson(Map<String, dynamic> row) => Booking(
    id: row['id'] as String, customerName: row['customer_name'] as String, customerPhone: row['customer_phone'] as String?,
    stationId: row['station_id'] as String, stationName: row['station_name'] as String, mode: SessionMode.parse(row['mode']),
    date: row['booking_date'] as String, startTime: (row['start_time'] as String).substring(0,5),
    durationMinutes: (row['duration_minutes'] as num).toInt(), status: row['status'] as String,
    advanceAmount: (row['advance_amount'] as num?)?.round() ?? 0, notes: row['notes'] as String?,
  );
}

int timeToMinutes(String time) {
  final parts = time.split(':');
  return int.parse(parts[0])*60 + int.parse(parts[1]);
}
bool bookingConflict(Booking candidate, Iterable<Booking> others) => others.any((other) =>
  other.id != candidate.id && other.stationId == candidate.stationId && other.date == candidate.date &&
  other.status == 'CONFIRMED' &&
  timeToMinutes(candidate.startTime) < timeToMinutes(other.startTime) + other.durationMinutes &&
  timeToMinutes(candidate.startTime) + candidate.durationMinutes > timeToMinutes(other.startTime));

class Sale {
  const Sale(this.id, this.receipt, this.customer, this.station, this.mode, this.total, this.date, this.method);
  final String id, receipt, customer, station, method;
  final SessionMode mode;
  final int total;
  final DateTime date;
  factory Sale.fromJson(Map<String, dynamic> row) => Sale(
    row['id'] as String, row['receipt_number'] as String, row['customer_name'] as String,
    row['station_name'] as String, SessionMode.parse(row['mode']), (row['total'] as num).round(),
    DateTime.parse(row['transaction_date'] as String), row['payment_method'] as String);
}
class Expense {
  const Expense(this.category, this.amount, this.date);
  final String category, date;
  final int amount;
  factory Expense.fromJson(Map<String, dynamic> row) => Expense(row['category'] as String, (row['amount'] as num).round(), row['expense_date'] as String);
}
class ReportData {
  const ReportData(this.sales, this.bookings, this.expenses);
  final List<Sale> sales;
  final List<Booking> bookings;
  final List<Expense> expenses;
  int get salesTotal => sales.fold(0, (sum, row) => sum + row.total);
  int get advanceTotal => bookings.where((b) => b.status != 'CANCELLED').fold(0, (sum, b) => sum + b.advanceAmount);
  int get expenseTotal => expenses.fold(0, (sum, row) => sum + row.amount);
  int get net => salesTotal + advanceTotal - expenseTotal;
  String toCsv() {
    String cell(Object? value) => '"${value.toString().replaceAll('"', '""')}"';
    final rows = <List<Object?>>[
      ['kind','date','reference','customer_or_category','station','mode','payment','amount'],
      for (final s in sales) ['sale',s.date.toIso8601String(),s.receipt,s.customer,s.station,s.mode.value,s.method,s.total],
      for (final b in bookings) if (b.status != 'CANCELLED') ['booking_advance',b.date,b.id,b.customerName,b.stationName,b.mode.value,'',b.advanceAmount],
      for (final e in expenses) ['expense',e.date,'',e.category,'','','',e.amount],
    ];
    return rows.map((row) => row.map(cell).join(',')).join('\n');
  }
}
