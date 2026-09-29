import '../../data/models/shop_snapshot.dart';

class Bill {
  const Bill(this.play, this.snacks, this.discount);
  final int play, snacks, discount;
  int get subtotal => play + snacks;
  int get appliedDiscount => discount.clamp(0, subtotal);
  int get total => subtotal - appliedDiscount;
  int change(int received) => received - total;
}

int menuPlayAmount(SessionMode mode, int minutes, int players, int hourlyRate, {Map<String,int>? rates}) {
  int price(String key,int fallback) => rates?[key] ?? fallback;
  if (minutes <= 0) return 0;
  final count = players.clamp(1, 4);
  if (mode == SessionMode.gaming) {
    if (minutes == 30 && count == 1) return price('ps5_30m_1p',100);
    if (minutes == 60 || minutes == 120) {
      return price('ps5_1h_${count}p',[150,250,350,450][count-1]) * (minutes ~/ 60);
    }
  }
  if (mode == SessionMode.vr) {
    if (minutes == 15) return price('vr_15m_1p',100);
    if (minutes == 30) return price('vr_30m_1p',200);
  }
  if (mode == SessionMode.racing) {
    if (minutes == 30) return price('racing_30m_1p',150);
    if (minutes == 60) return price('racing_1h_1p',250);
    if (minutes == 120) return price('racing_1h_1p',250)*2;
  }
  if (mode == SessionMode.racingVr) {
    if (minutes == 15) return price('racing_vr_15m_1p',200);
    if (minutes == 30) return price('racing_vr_30m_1p',300);
  }
  return (hourlyRate * minutes / 60).floor();
}
