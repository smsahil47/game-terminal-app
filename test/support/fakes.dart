import 'dart:async';

import 'package:game_terminal_app/data/models/app_role.dart';
import 'package:game_terminal_app/data/models/shop_snapshot.dart';
import 'package:game_terminal_app/data/repositories/auth_repository.dart';
import 'package:game_terminal_app/data/repositories/shop_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user, this.role = AppRole.receptionist});
  StaffUser? user;
  AppRole? role;
  Object? loginError;
  Future<AppRole?> Function(String)? resolve;
  final events = StreamController<StaffUser?>.broadcast(sync: true);
  int loginCalls = 0;
  String? signedInEmail;
  @override
  StaffUser? get currentUser => user;
  @override
  Stream<StaffUser?> get changes => events.stream;
  @override
  Future<AppRole?> fetchRole(String userId) async =>
      resolve != null ? await resolve!(userId) : role;
  void emit(StaffUser? value) {
    user = value;
    events.add(value);
  }

  @override
  Future<void> signIn(String email, String password) async {
    loginCalls++;
    signedInEmail = email;
    if (loginError != null) throw loginError!;
    emit(StaffUser('staff-1', email));
  }

  @override
  Future<void> signOut() async => emit(null);
}

class FakeShopRepository implements ShopRepository {
  FakeShopRepository({ShopSnapshot? data}) : data = data ?? sampleShop();
  ShopSnapshot data;
  int loads = 0;
  Object? error;
  final List<(String, bool)> maintenanceChanges = [];
  Future<ShopSnapshot> Function()? loadOverride;
  final events = StreamController<bool>.broadcast(sync: true);
  @override
  Future<ShopSnapshot> load() async {
    loads++;
    if (loadOverride != null) return loadOverride!();
    if (error != null) throw error!;
    return data;
  }

  @override
  Future<void> setMaintenance(String stationId, {required bool unavailable}) async {
    maintenanceChanges.add((stationId, unavailable));
  }

  @override
  Stream<bool> watchChanges() => events.stream;
}

ShopSnapshot sampleShop() => ShopSnapshot(
  cafeName: 'Test shop',
  totalControllers: 6,
  stations: const [
    Station(
      id: 's1',
      name: 'Station 1',
      type: 'PS5',
      status: StationStatus.available,
      order: 1,
    ),
    Station(
      id: 's2',
      name: 'Station 2',
      type: 'PS5_MULTI',
      status: StationStatus.inUse,
      order: 2,
    ),
  ],
  sessions: [
    ActiveSession(
      id: 'a1',
      stationId: 's2',
      customerName: 'Test customer',
      mode: SessionMode.gaming,
      startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      status: 'RUNNING',
      players: 2,
      game: 'Test game',
      targetMinutes: 30,
    ),
  ],
);
