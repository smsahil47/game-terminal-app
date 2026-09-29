import '../models/operations.dart';
import '../models/shop_snapshot.dart';
import '../../core/billing/billing.dart';

class SessionDraft {
  const SessionDraft({required this.station, required this.customerName, required this.mode, required this.minutes, required this.players, required this.game, required this.playAmount, required this.ratePerHour, this.phone, this.snacks=const []});
  final Station station;
  final String customerName, game;
  final String? phone;
  final List<Snack> snacks;
  final SessionMode mode;
  final int minutes, players, playAmount, ratePerHour;
}
class Checkout {
  const Checkout({required this.session, required this.bill, required this.method, required this.received, required this.minutes, required this.endedAt});
  final SessionDetail session;
  final Bill bill;
  final String method;
  final int received, minutes;
  final DateTime endedAt;
}
class PaymentReceipt {
  const PaymentReceipt(this.number, this.total, this.change, {this.alreadyPaid = false, this.warning});
  final String number;
  final int total, change;
  final bool alreadyPaid;
  final String? warning;
}
abstract interface class OperationsRepository {
  Future<List<SessionDetail>> sessions();
  Future<List<Booking>> bookings();
  Future<List<String>> games();
  Future<SessionDetail> start(SessionDraft draft, int controllersFree);
  Future<void> extend(SessionDetail session, int minutes, int charge);
  Future<void> stop(SessionDetail session);
  Future<void> addSnack(SessionDetail session, Snack snack);
  Future<PaymentReceipt> checkout(Checkout checkout);
  Future<Booking> saveBooking(Booking booking, {String? advanceMethod});
  Future<void> cancelBooking(String id);
  Future<void> completeBooking(String id);
  Future<ReportData> report(DateTime start, DateTime end);
}
class DisconnectedOperationsRepository implements OperationsRepository {
  const DisconnectedOperationsRepository();
  Never get unavailable => throw StateError('Backend is disabled.');
  @override Future<List<SessionDetail>> sessions() async => unavailable;
  @override Future<List<Booking>> bookings() async => unavailable;
  @override Future<List<String>> games() async => unavailable;
  @override Future<SessionDetail> start(SessionDraft draft, int controllersFree) async => unavailable;
  @override Future<void> extend(SessionDetail session, int minutes, int charge) async => unavailable;
  @override Future<void> stop(SessionDetail session) async => unavailable;
  @override Future<void> addSnack(SessionDetail session, Snack snack) async => unavailable;
  @override Future<PaymentReceipt> checkout(Checkout checkout) async => unavailable;
  @override Future<Booking> saveBooking(Booking booking, {String? advanceMethod}) async => unavailable;
  @override Future<void> cancelBooking(String id) async => unavailable;
  @override Future<void> completeBooking(String id) async => unavailable;
  @override Future<ReportData> report(DateTime start, DateTime end) async => unavailable;
}
