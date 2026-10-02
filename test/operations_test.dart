import 'package:flutter_test/flutter_test.dart';
import 'package:game_terminal_app/core/billing/billing.dart';
import 'package:game_terminal_app/data/models/operations.dart';
import 'package:game_terminal_app/data/models/shop_snapshot.dart';
import 'package:game_terminal_app/features/operations/operations_pages.dart';

void main() {
  test('booking date presets match the website filters', () {
    final now = DateTime(2026, 10, 2, 15);
    expect(bookingDateInRange('2026-10-02', 'today', now), isTrue);
    expect(bookingDateInRange('2026-10-01', 'yesterday', now), isTrue);
    expect(bookingDateInRange('2026-09-25', 'week', now), isTrue);
    expect(bookingDateInRange('2026-09-24', 'week', now), isFalse);
    expect(bookingDateInRange('2026-09-02', 'month', now), isTrue);
    expect(bookingDateInRange('2026-09-01', 'month', now), isFalse);
  });
  test('menu tiers and prorated custom duration match website rules', () {
    expect(menuPlayAmount(SessionMode.gaming,30,1,150),100);
    expect(menuPlayAmount(SessionMode.gaming,60,4,450),450);
    expect(menuPlayAmount(SessionMode.gaming,120,2,250),500);
    expect(menuPlayAmount(SessionMode.vr,15,1,400),100);
    expect(menuPlayAmount(SessionMode.racing,30,1,250),150);
    expect(menuPlayAmount(SessionMode.racingVr,30,1,600),300);
    expect(menuPlayAmount(SessionMode.racing,45,1,250),187);
  });
  test('bill caps discounts and calculates change', () {
    const bill=Bill(150,35,500);
    expect(bill.subtotal,185);
    expect(bill.appliedDiscount,185);
    expect(bill.total,0);
    expect(bill.change(200),200);
  });
  test('booking conflict uses exclusive end and skips cancelled rows', () {
    Booking make(String id,String start,int minutes,String status)=>Booking(
      id:id,customerName:'Test',stationId:'s1',stationName:'One',mode:SessionMode.gaming,
      date:'2026-10-01',startTime:start,durationMinutes:minutes,status:status,advanceAmount:0);
    final existing=[make('one','10:00',60,'CONFIRMED')];
    expect(bookingConflict(make('','10:30',60,'CONFIRMED'),existing),isTrue);
    expect(bookingConflict(make('','11:00',60,'CONFIRMED'),existing),isFalse);
    expect(bookingConflict(make('one','10:30',60,'CONFIRMED'),existing),isFalse);
    expect(bookingConflict(make('','10:30',60,'CONFIRMED'),[make('one','10:00',60,'CANCELLED')]),isFalse);
  });
  test('report sums sales, advances, expenses and quotes CSV', () {
    final report=ReportData([
      Sale('1','R1','Alice, Jr','Station 1',SessionMode.gaming,150,DateTime.utc(2026,10,1),'UPI')
    ],[const Booking(id:'b',customerName:'Bob',stationId:'s',stationName:'Station 2',mode:SessionMode.vr,date:'2026-10-01',startTime:'12:00',durationMinutes:30,status:'CONFIRMED',advanceAmount:50)],[const Expense('Internet',25,'2026-10-01')]);
    expect(report.net,175);
    expect(report.toCsv(),contains('"Alice, Jr"'));
  });
}
