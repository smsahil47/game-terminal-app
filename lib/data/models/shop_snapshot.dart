enum StationStatus {
  available('AVAILABLE', 'Available'),
  inUse('IN_USE', 'In use'),
  maintenance('MAINTENANCE', 'Maintenance');

  const StationStatus(this.value, this.label);
  final String value;
  final String label;
  static StationStatus parse(Object? value) => values.firstWhere(
    (status) => status.value == value,
    orElse: () => throw const FormatException('Unknown station status'),
  );
}

enum SessionMode {
  gaming('GAMING', 'Gaming'),
  vr('VR', 'VR'),
  racing('RACING', 'Racing'),
  racingVr('RACING_VR', 'Racing + VR');

  const SessionMode(this.value, this.label);
  final String value;
  final String label;
  static SessionMode parse(Object? value) => values.firstWhere(
    (mode) => mode.value == value,
    orElse: () => throw const FormatException('Unknown session mode'),
  );
}

class Station {
  const Station({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.order,
  });
  factory Station.fromJson(Map<String, dynamic> row) => Station(
    id: row['id'] as String,
    name: row['name'] as String,
    type: row['type'] as String,
    status: StationStatus.parse(row['status']),
    order: (row['display_order'] as num).toInt(),
  );
  final String id, name, type;
  final StationStatus status;
  final int order;
}

class ActiveSession {
  const ActiveSession({
    required this.id,
    required this.stationId,
    required this.customerName,
    required this.mode,
    required this.startedAt,
    required this.status,
    this.players,
    this.game,
    this.targetMinutes,
  });
  factory ActiveSession.fromJson(Map<String, dynamic> row) => ActiveSession(
    id: row['id'] as String,
    stationId: row['station_id'] as String,
    customerName: row['customer_name'] as String,
    mode: SessionMode.parse(row['mode']),
    startedAt: DateTime.parse(row['start_time'] as String),
    status: row['status'] as String,
    players: (row['player_count'] as num?)?.toInt(),
    game: row['game'] as String?,
    targetMinutes: (row['target_duration_minutes'] as num?)?.toInt(),
  );
  final String id, stationId, customerName, status;
  final SessionMode mode;
  final DateTime startedAt;
  final int? players, targetMinutes;
  final String? game;
  bool get isActive => status == 'RUNNING' || status == 'EXTENDED';
  int get controllersUsed =>
      isActive && mode == SessionMode.gaming ? (players ?? 1) : 0;
  Duration elapsed(DateTime now) =>
      now.isBefore(startedAt) ? Duration.zero : now.difference(startedAt);
  bool isDue(DateTime now) =>
      isActive &&
      targetMinutes != null &&
      targetMinutes! > 0 &&
      elapsed(now).inSeconds >= targetMinutes! * 60;
}

class ShopSnapshot {
  ShopSnapshot({
    required List<Station> stations,
    required List<ActiveSession> sessions,
    required this.cafeName,
    required this.totalControllers,
  }) : stations = List.unmodifiable(
         [...stations]..sort((a, b) {
           // The physical consoles have stable IDs even when staff rename them.
           // Keep PS5 #1, #2, #3 in that order on every screen.
           final aNumber = int.tryParse(a.id.split('-').last);
           final bNumber = int.tryParse(b.id.split('-').last);
           if (aNumber != null && bNumber != null) {
             final byNumber = aNumber.compareTo(bNumber);
             if (byNumber != 0) return byNumber;
           }
           return a.order.compareTo(b.order);
         }),
       ),
       sessions = List.unmodifiable(sessions.where((s) => s.isActive));
  final List<Station> stations;
  final List<ActiveSession> sessions;
  final String cafeName;
  final int totalControllers;
  int get available =>
      stations.where((s) => s.status == StationStatus.available).length;
  int get controllersUsed =>
      sessions.fold(0, (count, session) => count + session.controllersUsed);
  int get controllersFree => totalControllers - controllersUsed;
}
