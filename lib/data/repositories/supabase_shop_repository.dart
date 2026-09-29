import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/shop_snapshot.dart';
import 'shop_repository.dart';

class SupabaseShopRepository implements ShopRepository {
  SupabaseShopRepository(this.client);
  final SupabaseClient client;
  @override
  Future<ShopSnapshot> load() async {
    final results = await Future.wait<dynamic>([
      client
          .from('stations')
          .select('id,name,type,status,display_order')
          .order('display_order'),
      client
          .from('sessions')
          .select(
            'id,station_id,customer_name,mode,start_time,status,player_count,game,target_duration_minutes',
          )
          .inFilter('status', ['RUNNING', 'EXTENDED'])
          .order('start_time', ascending: false),
      client
          .from('app_settings')
          .select('cafe_name,total_controllers')
          .eq('id', 1)
          .single(),
    ]);
    final settings = results[2] as Map<String, dynamic>;
    return ShopSnapshot(
      stations: (results[0] as List)
          .map((row) => Station.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(),
      sessions: (results[1] as List)
          .map(
            (row) =>
                ActiveSession.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList(),
      cafeName: settings['cafe_name'] as String,
      totalControllers: (settings['total_controllers'] as num).toInt(),
    );
  }

  @override
  Stream<bool> watchChanges() {
    late StreamController<bool> events;
    RealtimeChannel? channel;
    void emit(bool connected) {
      if (!events.isClosed) events.add(connected);
    }

    events = StreamController<bool>(
      onListen: () {
        channel = client
            .channel('mobile-shop-${DateTime.now().microsecondsSinceEpoch}')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'stations',
              callback: (_) => emit(true),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'sessions',
              callback: (_) => emit(true),
            )
            .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'bookings',callback:(_)=>emit(true))
            .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'transactions',callback:(_)=>emit(true))
            .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'customers',callback:(_)=>emit(true))
            .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'expenses',callback:(_)=>emit(true))
            .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'games',callback:(_)=>emit(true))
            .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'pricing_rates',callback:(_)=>emit(true))
            .onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'app_settings',callback:(_)=>emit(true))
            .subscribe(
              (status, error) =>
                  emit(status == RealtimeSubscribeStatus.subscribed),
            );
      },
      onCancel: () async {
        final active = channel;
        if (active != null) await client.removeChannel(active);
      },
    );
    return events.stream;
  }
}
