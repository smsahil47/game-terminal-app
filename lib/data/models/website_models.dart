class CustomerRecord {
  const CustomerRecord({required this.id, required this.name, this.phone});
  final String id, name;
  final String? phone;
  factory CustomerRecord.fromJson(Map<String,dynamic> row) => CustomerRecord(
    id: row['id'] as String, name: row['name'] as String, phone: row['phone'] as String?);
}

class ExpenseRecord {
  const ExpenseRecord({required this.id, required this.amount, required this.category, required this.date, this.notes});
  final String id, category, date;
  final int amount;
  final String? notes;
  factory ExpenseRecord.fromJson(Map<String,dynamic> row) => ExpenseRecord(
    id: row['id'] as String, amount: (row['amount'] as num).round(),
    category: row['category'] as String, date: row['expense_date'] as String,
    notes: row['notes'] as String?);
}

const expenseCategories = ['Electricity','Internet','Maintenance','Staff','Supplies','Food/Snacks','Other'];
const menuRateLabels = <String,String>{
  'racing_1h_1p':'Racing · 1 hour', 'racing_30m_1p':'Racing · 30 min',
  'racing_vr_15m_1p':'Racing + VR · 15 min', 'racing_vr_30m_1p':'Racing + VR · 30 min',
  'ps5_30m_1p':'PS5 · 30 min · 1 player',
  'ps5_1h_1p':'PS5 · 1 hour · 1 player', 'ps5_1h_2p':'PS5 · 1 hour · 2 players',
  'ps5_1h_3p':'PS5 · 1 hour · 3 players', 'ps5_1h_4p':'PS5 · 1 hour · 4 players',
  'vr_15m_1p':'VR · 15 min', 'vr_30m_1p':'VR · 30 min',
};
const defaultMenuRates = <String,int>{
  'racing_1h_1p':250,'racing_30m_1p':150,'racing_vr_15m_1p':200,
  'racing_vr_30m_1p':300,'ps5_30m_1p':100,'ps5_1h_1p':150,
  'ps5_1h_2p':250,'ps5_1h_3p':350,'ps5_1h_4p':450,
  'vr_15m_1p':100,'vr_30m_1p':200,
};
class ShopConfiguration {
  ShopConfiguration({required this.cafeName, required this.totalControllers,
    required this.gamingRate, required this.vrRate, required this.racingRate,
    required this.menuRates, required this.games});
  final String cafeName;
  final int totalControllers, gamingRate, vrRate, racingRate;
  final Map<String,int> menuRates;
  final List<String> games;
  int fallbackRate(String mode, int players) => switch(mode) {
    'GAMING' => menuRates['ps5_1h_${players.clamp(1,4)}p'] ?? gamingRate,
    'VR' => (menuRates['vr_30m_1p'] ?? (vrRate ~/ 2)) * 2,
    'RACING' => menuRates['racing_1h_1p'] ?? racingRate,
    'RACING_VR' => (menuRates['racing_vr_30m_1p'] ?? 300) * 2,
    _ => gamingRate,
  };
}
class TransactionRecord {
  const TransactionRecord({required this.id, required this.receipt, required this.customer,
    required this.stationId, required this.station, required this.mode, required this.date,
    required this.total, required this.paymentMethod, required this.playCharges,
    required this.snacksTotal, required this.discount, required this.amountReceived,
    required this.changeReturned, required this.durationMinutes, this.phone, this.game,
    this.players, this.snacks = const []});
  final String id, receipt, customer, stationId, station, mode, paymentMethod;
  final String? phone, game;
  final int total, playCharges, snacksTotal, discount, amountReceived, changeReturned, durationMinutes;
  final int? players;
  final DateTime date;
  final List<Map<String,dynamic>> snacks;
  factory TransactionRecord.fromJson(Map<String,dynamic> row) => TransactionRecord(
    id:row['id'] as String, receipt:row['receipt_number'] as String,
    customer:row['customer_name'] as String, phone:row['customer_phone'] as String?,
    stationId:row['station_id'] as String, station:row['station_name'] as String,
    mode:row['mode'] as String, date:DateTime.parse(row['transaction_date'] as String),
    game:row['game'] as String?, players:(row['player_count'] as num?)?.toInt(),
    total:(row['total'] as num).round(), playCharges:(row['play_charges'] as num).round(),
    snacksTotal:(row['snacks_total'] as num?)?.round() ?? 0,
    discount:(row['discount'] as num).round(),
    amountReceived:(row['amount_received'] as num).round(),
    changeReturned:(row['change_returned'] as num?)?.round() ?? 0,
    durationMinutes:(row['duration_minutes'] as num).toInt(),
    paymentMethod:row['payment_method'] as String,
    snacks:((row['snacks'] as List?)??[]).map((s)=>Map<String,dynamic>.from(s as Map)).toList(),
  );
}
