import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_terminal_app/core/config/app_config.dart';
import 'package:game_terminal_app/data/models/shop_snapshot.dart';

void main() {
  test('backend defaults to disabled with no endpoint', () {
    const config = AppConfig();
    expect(config.enabled, isFalse);
    expect(config.url, isEmpty);
    expect(config.validationError, isNull);
  });
  test('enabled backend requires an explicit environment, HTTPS, and public key', () {
    const key = 'sb_publishable_test_public_key';
    expect(
      const AppConfig(
        enabled: true,
        environment: 'staging',
        url: 'https://test.supabase.co',
        publicKey: key,
      ).validationError,
      isNotNull,
    );
    expect(
      const AppConfig(
        enabled: true,
        environment: 'production',
        url: 'https://test.supabase.co',
        publicKey: key,
      ).validationError,
      isNull,
    );
    expect(
      const AppConfig(
        enabled: true,
        url: 'http://test.supabase.co',
        publicKey: key,
      ).validationError,
      isNotNull,
    );
    expect(
      const AppConfig(
        enabled: true,
        url: 'https://test.supabase.co',
        publicKey: 'sb_secret_never_use',
      ).validationError,
      isNotNull,
    );
    expect(
      const AppConfig(
        enabled: true,
        url: 'https://test.supabase.co',
        publicKey: key,
      ).validationError,
      isNull,
    );
  });
  test('legacy anon key accepted; service role key rejected', () {
    String jwt(String role) =>
        'header.${base64Url.encode(utf8.encode(jsonEncode({'role': role})))}.signature';
    expect(
      AppConfig(
        enabled: true,
        url: 'https://test.supabase.co',
        publicKey: jwt('anon'),
      ).validationError,
      isNull,
    );
    expect(
      AppConfig(
        enabled: true,
        url: 'https://test.supabase.co',
        publicKey: jwt('service_role'),
      ).validationError,
      isNotNull,
    );
  });
  test('maps exact website station and session values', () {
    final station = Station.fromJson({
      'id': 's',
      'name': 'Station',
      'type': 'PS5_MULTI',
      'status': 'MAINTENANCE',
      'display_order': 3,
    });
    expect(station.status, StationStatus.maintenance);
    expect(station.order, 3);
    for (final mode in SessionMode.values) {
      final session = ActiveSession.fromJson({
        'id': 'a',
        'station_id': 's',
        'customer_name': 'Customer',
        'mode': mode.value,
        'start_time': '2026-09-28T10:00:00Z',
        'status': 'EXTENDED',
        'player_count': mode == SessionMode.gaming ? 3 : null,
        'game': null,
        'target_duration_minutes': 30,
      });
      expect(session.mode, mode);
      expect(session.controllersUsed, mode == SessionMode.gaming ? 3 : 0);
      expect(session.isDue(DateTime.utc(2026, 9, 28, 10, 29, 59)), isFalse);
      expect(session.isDue(DateTime.utc(2026, 9, 28, 10, 30)), isTrue);
      expect(session.elapsed(DateTime.utc(2026, 9, 28, 9)), Duration.zero);
    }
  });
  test('completed sessions do not consume controllers or trigger alerts', () {
    final session = ActiveSession(
      id: 'a',
      stationId: 's',
      customerName: 'Customer',
      mode: SessionMode.gaming,
      startedAt: DateTime.utc(2026),
      status: 'COMPLETED',
      players: 4,
      targetMinutes: 30,
    );
    final snapshot = ShopSnapshot(
      stations: [],
      sessions: [session],
      cafeName: 'Shop',
      totalControllers: 6,
    );
    expect(snapshot.sessions, isEmpty);
    expect(snapshot.controllersFree, 6);
    expect(session.isDue(DateTime.utc(2027)), isFalse);
  });
  test('physical consoles show PS5 #1 before #2 and #3', () {
    final snapshot = ShopSnapshot(
      stations: const [
        Station(
          id: 'ps5-03', name: 'PS5 #3', type: 'PS5_MULTI',
          status: StationStatus.available, order: 1,
        ),
        Station(
          id: 'ps5-02', name: 'PS5 #2', type: 'PS5',
          status: StationStatus.available, order: 3,
        ),
        Station(
          id: 'ps5-01', name: 'PS5 #1', type: 'PS5',
          status: StationStatus.available, order: 2,
        ),
      ],
      sessions: [],
      cafeName: 'Shop',
      totalControllers: 6,
    );
    expect(snapshot.stations.map((station) => station.name), [
      'PS5 #1', 'PS5 #2', 'PS5 #3',
    ]);
  });
}
