import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_terminal_app/data/models/shop_snapshot.dart';
import 'package:game_terminal_app/features/shop/shop_controller.dart';

import 'support/fakes.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);
void main() {
  test(
    'loads shop and refreshes on realtime updates and reconnection',
    () async {
      final repo = FakeShopRepository();
      final controller = ShopController(repo);
      await flush();
      expect(controller.snapshot?.controllersFree, 4);
      repo.events.add(true);
      await flush();
      expect(repo.loads, 2);
      expect(controller.realtimeConnected, isTrue);
      repo.events.add(false);
      expect(controller.realtimeConnected, isFalse);
      repo.events.add(true);
      await flush();
      expect(repo.loads, 3);
      controller.dispose();
    },
  );
  test('refresh failure keeps snapshot and exposes stale-data error', () async {
    final repo = FakeShopRepository();
    final controller = ShopController(repo);
    await flush();
    repo.error = StateError('offline');
    await controller.refresh();
    expect(controller.snapshot, isNotNull);
    expect(controller.error, isNotNull);
    repo.error = null;
    await controller.refresh();
    expect(controller.error, isNull);
    controller.dispose();
  });
  test('event during initial fetch is not lost', () async {
    final pending = Completer<ShopSnapshot>();
    final repo = FakeShopRepository()..loadOverride = () => pending.future;
    final controller = ShopController(repo);
    repo.events.add(true);
    repo.loadOverride = null;
    pending.complete(sampleShop());
    await flush();
    expect(repo.loads, 2);
    controller.dispose();
  });
  test('late requests are ignored after disposal', () async {
    final pending = Completer<ShopSnapshot>();
    final repo = FakeShopRepository()..loadOverride = () => pending.future;
    final controller = ShopController(repo);
    controller.dispose();
    pending.complete(sampleShop());
    await flush();
    expect(controller.snapshot, isNull);
  });
}
