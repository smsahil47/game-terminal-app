import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/shop_snapshot.dart';
import '../../data/repositories/shop_repository.dart';

class ShopController extends ChangeNotifier {
  ShopController(this.repository) {
    _subscription = repository.watchChanges().listen(
      (connected) {
        realtimeConnected = connected;
        _notify();
        if (connected) unawaited(refresh());
      },
      onError: (Object error) {
        realtimeConnected = false;
        _notify();
      },
    );
    unawaited(refresh());
  }
  final ShopRepository repository;
  late final StreamSubscription<bool> _subscription;
  ShopSnapshot? snapshot;
  String? error;
  bool loading = false;
  bool realtimeConnected = false;
  bool _disposed = false, _pending = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh() async {
    if (_disposed) return;
    if (loading) {
      _pending = true;
      return;
    }
    loading = true;
    _notify();
    try {
      final next = await repository.load();
      if (_disposed) return;
      snapshot = next;
      error = null;
    } catch (_) {
      if (_disposed) return;
      error = 'Could not refresh shop data. Check your connection and retry.';
    } finally {
      loading = false;
      _notify();
      if (_pending && !_disposed) {
        _pending = false;
        unawaited(refresh());
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
