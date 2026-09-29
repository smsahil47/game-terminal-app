import 'package:flutter/material.dart';

import '../app/staff_shell.dart';

/// Re-fetches page data when the existing shop realtime controller loads a new revision.
mixin LiveShopData<T extends StatefulWidget> on State<T> {
  int? _seenShopVersion;
  Future<R> refreshOnShopChange<R>(Future<R> current, Future<R> Function() load) {
    final next=ShopScope.of(context).dataVersion;
    if(_seenShopVersion==null){_seenShopVersion=next;return current;}
    if(_seenShopVersion==next)return current;
    _seenShopVersion=next;
    return load();
  }
}
