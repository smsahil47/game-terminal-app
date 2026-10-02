import '../models/shop_snapshot.dart';

abstract interface class ShopRepository {
  Future<ShopSnapshot> load();
  Future<void> setMaintenance(String stationId, {required bool unavailable});

  /// True requests a fresh snapshot; false means realtime is disconnected.
  Stream<bool> watchChanges();
}

class DisconnectedShopRepository implements ShopRepository {
  const DisconnectedShopRepository();
  @override
  Future<ShopSnapshot> load() async => throw StateError('Backend is disabled.');
  @override
  Future<void> setMaintenance(String stationId, {required bool unavailable}) async =>
      throw StateError('Backend is disabled.');
  @override
  Stream<bool> watchChanges() => const Stream.empty();
}
