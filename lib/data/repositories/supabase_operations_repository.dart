import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/billing/billing.dart';
import '../models/operations.dart';
import '../models/shop_snapshot.dart';
import 'operations_repository.dart';

class SupabaseOperationsRepository implements OperationsRepository {
  SupabaseOperationsRepository(this.client);
  final SupabaseClient client;
  List<Map<String, dynamic>> rows(dynamic data) => (data as List).map((row) => Map<String, dynamic>.from(row as Map)).toList();
  @override
  Future<List<SessionDetail>> sessions() async => rows(await client.from('sessions').select('*').inFilter('status', ['RUNNING','EXTENDED']).order('start_time', ascending: false)).map(SessionDetail.fromJson).toList();
  @override
  Future<List<Booking>> bookings() async => rows(await client.from('bookings').select('*').order('booking_date').order('start_time')).map(Booking.fromJson).toList();
  @override
  Future<List<String>> games() async => rows(await client.from('games').select('title').eq('is_active', true).order('title')).map((r) => r['title'] as String).toList();

  @override
  Future<SessionDetail> start(SessionDraft draft, int controllersFree) async {
    if (draft.customerName.trim().isEmpty || draft.minutes <= 0) throw StateError('Enter a customer and duration.');
    if (draft.mode == SessionMode.gaming && draft.players > controllersFree) throw StateError('Not enough controllers are free.');
    final station = await client.from('stations').update({'status':'IN_USE','current_mode':draft.mode.value}).eq('id',draft.station.id).eq('status','AVAILABLE').select('id').maybeSingle();
    if (station == null) throw StateError('Station is no longer available.');
    try {
      if (draft.mode == SessionMode.gaming) {
        final active = rows(await client.from('sessions').select('player_count').eq('mode','GAMING').inFilter('status',['RUNNING','EXTENDED']));
        final inUse = active.fold<int>(0, (sum,r) => sum + ((r['player_count'] as num?)?.toInt() ?? 1));
        // The station has already been claimed; use the latest live count and the configured pool.
        final settings = await client.from('app_settings').select('total_controllers').eq('id',1).single();
        if (inUse + draft.players > (settings['total_controllers'] as num).toInt()) throw StateError('Controller pool changed. Refresh and try again.');
      }
      final row = await client.from('sessions').insert({
        'station_id':draft.station.id,'station_name':draft.station.name,'customer_name':draft.customerName.trim(),
        'customer_phone':draft.phone?.trim().isEmpty == true ? null : draft.phone?.trim(),
        'mode':draft.mode.value,'player_count':draft.mode == SessionMode.gaming ? draft.players.clamp(1,4) : null,
        'game':draft.game.trim().isEmpty ? null : draft.game.trim(),'start_time':DateTime.now().toUtc().toIso8601String(),
        'end_time':null,'duration_minutes':draft.minutes,'extra_minutes':0,
        'rate_per_hour':(draft.playAmount*60/draft.minutes).round(),'booked_play_amount':draft.playAmount,
        'target_duration_minutes':draft.minutes,'subtotal':0,'discount':0,'tax':0,'total':0,
        'status':'RUNNING','notes':null,'receipt_number':null,'snacks':<Map<String,dynamic>>[],'snacks_total':0
      }).select('*').single();
      return SessionDetail.fromJson(row);
    } catch (_) {
      await client.from('stations').update({'status':'AVAILABLE','current_mode':null}).eq('id',draft.station.id);
      rethrow;
    }
  }

  @override
  Future<void> extend(SessionDetail session, int minutes, int charge) async {
    if (minutes <= 0) throw StateError('Choose an extension.');
    final current = await client.from('sessions').select('extra_minutes,booked_play_amount,duration_minutes,target_duration_minutes').eq('id',session.id).inFilter('status',['RUNNING','EXTENDED']).maybeSingle();
    if (current == null) throw StateError('Session is no longer active.');
    await client.from('sessions').update({
      'extra_minutes':(current['extra_minutes'] as num).toInt()+minutes,
      'booked_play_amount':((current['booked_play_amount'] as num?)?.round() ?? menuPlayAmount(session.mode, session.durationMinutes, session.players ?? 1, session.ratePerHour))+charge,
      'target_duration_minutes':((current['target_duration_minutes'] as num?)?.toInt() ?? session.durationMinutes)+minutes,
      'status':'EXTENDED'
    }).eq('id',session.id).inFilter('status',['RUNNING','EXTENDED']);
  }
  @override
  Future<void> stop(SessionDetail session) async {
    final row = await client.from('sessions').update({'end_time':DateTime.now().toUtc().toIso8601String()}).eq('id',session.id).inFilter('status',['RUNNING','EXTENDED']).select('id').maybeSingle();
    if (row == null) throw StateError('Session is no longer active.');
  }
  @override
  Future<void> addSnack(SessionDetail session, Snack snack) async {
    if (snack.name.trim().isEmpty || snack.price < 0) throw StateError('Enter a snack and valid price.');
    final row = await client.from('sessions').select('snacks').eq('id',session.id).inFilter('status',['RUNNING','EXTENDED']).maybeSingle();
    if (row == null) throw StateError('Session is no longer active.');
    final snacks = [...((row['snacks'] as List?) ?? []).map((s) => Map<String,dynamic>.from(s as Map)),snack.toJson()];
    await client.from('sessions').update({'snacks':snacks,'snacks_total':snacks.fold<int>(0,(sum,s)=>sum+(s['price'] as num).round())}).eq('id',session.id).inFilter('status',['RUNNING','EXTENDED']);
  }
  @override
  Future<PaymentReceipt> checkout(Checkout input) async {
    if (input.method != 'CASH' && input.method != 'UPI') throw StateError('Choose Cash or UPI.');
    if (input.received < input.bill.total) throw StateError('Received amount is below total.');
    final session = input.session;
    final existing = await client.from('transactions').select('receipt_number,total,change_returned').eq('session_id',session.id).maybeSingle();
    if (existing != null) return PaymentReceipt(existing['receipt_number'] as String,(existing['total'] as num).round(),(existing['change_returned'] as num?)?.round() ?? 0,alreadyPaid:true);
    final receipt = 'GT-${DateTime.now().millisecondsSinceEpoch}-${Random.secure().nextInt(9000)+1000}';
    final claim = await client.from('sessions').update({
      'end_time':input.endedAt.toUtc().toIso8601String(),'duration_minutes':input.minutes,
      'subtotal':input.bill.subtotal,'discount':input.bill.appliedDiscount,'tax':0,'total':input.bill.total,
      'status':'COMPLETED','receipt_number':receipt,'snacks_total':input.bill.snacks
    }).eq('id',session.id).inFilter('status',['RUNNING','EXTENDED']).select('id').maybeSingle();
    if (claim == null) {
      final paid = await client.from('transactions').select('receipt_number,total,change_returned').eq('session_id',session.id).maybeSingle();
      if (paid != null) return PaymentReceipt(paid['receipt_number'] as String,(paid['total'] as num).round(),(paid['change_returned'] as num?)?.round() ?? 0,alreadyPaid:true);
      throw StateError('Session changed. Refresh before checkout.');
    }
    try {
      await client.from('transactions').insert({
        'receipt_number':receipt,'session_id':session.id,'customer_name':session.customerName,'customer_phone':session.customerPhone,
        'station_id':session.stationId,'station_name':session.stationName,'mode':session.mode.value,'game':session.game,
        'player_count':session.mode == SessionMode.gaming ? session.players ?? 1 : null,'rate_per_hour':session.ratePerHour,
        'transaction_date':input.endedAt.toUtc().toIso8601String(),'duration_minutes':input.minutes,
        'play_charges':input.bill.play,'subtotal':input.bill.subtotal,'discount':input.bill.appliedDiscount,'tax':0,
        'total':input.bill.total,'payment_method':input.method,'amount_received':input.received,
        'change_returned':input.bill.change(input.received),'status':'PAID','snacks':session.snacks.map((s)=>s.toJson()).toList(),
        'snacks_total':input.bill.snacks,'notes':session.notes
      });
    } catch (_) {
      await client.from('sessions').update({'status':'RUNNING','end_time':null,'receipt_number':null,'subtotal':0,'discount':0,'tax':0,'total':0}).eq('id',session.id);
      rethrow;
    }
    String? warning;
    try { await client.from('stations').update({'status':'AVAILABLE','current_mode':null}).eq('id',session.stationId); }
    catch (_) { warning = 'Payment saved, but the station could not be released. Check station status.'; }
    return PaymentReceipt(receipt,input.bill.total,input.bill.change(input.received),warning:warning);
  }
  @override
  Future<Booking> saveBooking(Booking booking, {String? advanceMethod}) async {
    if (booking.customerName.trim().isEmpty || booking.durationMinutes <= 0 || timeToMinutes(booking.startTime)+booking.durationMinutes > 1440) throw StateError('Check customer and booking time.');
    if (booking.advanceAmount < 0) throw StateError('Advance cannot be negative.');
    if (booking.advanceAmount > 0 && advanceMethod != 'CASH' && advanceMethod != 'UPI') throw StateError('Choose an advance payment method.');
    final all = await bookings();
    if (bookingConflict(booking, all)) throw StateError('This station has a conflicting booking.');
    final end = timeToMinutes(booking.startTime)+booking.durationMinutes;
    final endTime = '${(end~/60).toString().padLeft(2,'0')}:${(end%60).toString().padLeft(2,'0')}:00';
    final payload = {
      'customer_name':booking.customerName.trim(),'customer_phone':booking.customerPhone,
      'station_id':booking.stationId,'station_name':booking.stationName,'mode':booking.mode.value,
      'player_count':booking.mode == SessionMode.gaming ? 1 : null,'booking_date':booking.date,
      'start_time':'${booking.startTime}:00','end_time':endTime,'duration_minutes':booking.durationMinutes,
      'status':booking.status,'advance_amount':booking.advanceAmount,'advance_payment_method':advanceMethod,
      'balance_amount':0,'notes':booking.notes
    };
    final row = booking.id.isEmpty
      ? await client.from('bookings').insert(payload).select('*').single()
      : await client.from('bookings').update(payload).eq('id',booking.id).select('*').single();
    return Booking.fromJson(row);
  }
  @override
  Future<void> cancelBooking(String id) async {
    final row = await client.from('bookings').update({'status':'CANCELLED'}).eq('id',id).eq('status','CONFIRMED').select('id').maybeSingle();
    if (row == null) throw StateError('Booking is no longer confirmed.');
  }
  @override
  Future<ReportData> report(DateTime start, DateTime end) async {
    final from = DateTime(start.year,start.month,start.day).toUtc().toIso8601String();
    final until = DateTime(end.year,end.month,end.day+1).toUtc().toIso8601String();
    final firstDate = from.substring(0,10), lastDate = DateTime(end.year,end.month,end.day).toIso8601String().substring(0,10);
    final sales = rows(await client.from('transactions').select('id,receipt_number,customer_name,station_name,mode,total,transaction_date,payment_method').gte('transaction_date',from).lt('transaction_date',until).order('transaction_date',ascending:false)).map(Sale.fromJson).toList();
    final advances = rows(await client.from('bookings').select('*').gte('created_at',from).lt('created_at',until)).map(Booking.fromJson).toList();
    final expenses = rows(await client.from('expenses').select('amount,category,expense_date').gte('expense_date',firstDate).lte('expense_date',lastDate)).map(Expense.fromJson).toList();
    return ReportData(sales,advances,expenses);
  }
}
