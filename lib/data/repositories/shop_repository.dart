import '../models/shop_snapshot.dart';

abstract interface class ShopRepository {
  Future<ShopSnapshot> load();

  /// True requests a fresh snapshot; false means realtime is disconnected.
  Stream<bool> watchChanges();
}

class DisconnectedShopRepository implements ShopRepository {
  const DisconnectedShopRepository();
  @override
  Future<ShopSnapshot> load() async => throw StateError('Backend is disabled.');
  @override
  Stream<bool> watchChanges() => const Stream.empty();
}
