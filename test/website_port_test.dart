import 'package:flutter_test/flutter_test.dart';
import 'package:game_terminal_app/core/billing/billing.dart';
import 'package:game_terminal_app/core/validation/staff_validation.dart';
import 'package:game_terminal_app/data/models/app_role.dart';
import 'package:game_terminal_app/data/models/shop_snapshot.dart';
import 'package:game_terminal_app/data/models/website_models.dart';
import 'package:game_terminal_app/services/document_export.dart';

void main() {
  test('configured website tiers and fallback rates drive session pricing',() {
    final rates={...defaultMenuRates,'ps5_1h_2p':280,'vr_30m_1p':230};
    final config=ShopConfiguration(cafeName:'Test',totalControllers:6,gamingRate:150,
      vrRate:400,racingRate:250,menuRates:rates,games:const []);
    expect(config.fallbackRate('GAMING',2),280);
    expect(config.fallbackRate('VR',1),460);
    expect(menuPlayAmount(SessionMode.gaming,60,2,config.fallbackRate('GAMING',2),rates:rates),280);
    expect(menuPlayAmount(SessionMode.vr,45,1,config.fallbackRate('VR',1),rates:rates),345);
  });
  test('website staff validation accepts Indian names and checks mobile numbers',() {
    expect(customerNameError('A'),isNotNull);
    expect(customerNameError('1234'),isNotNull);
    expect(customerNameError('Ravi'),isNull);
    expect(customerNameError('रवि'),isNull);
    expect(indianPhoneError('9123456789'),isNull);
    expect(indianPhoneError('5123456789'),isNotNull);
    expect(indianPhoneError('91234a6789'),isNotNull);
    expect(gameTitleError(''),isNotNull);
  });
  test('new website pages are receptionist-only',() {
    for(final path in ['/game-terminal','/customers','/expenses','/transactions','/daily-report','/station-details']){
      expect(AppRole.receptionist.canAccess(path),isTrue);
      expect(AppRole.owner.canAccess(path),isFalse);
    }
    expect(AppRole.owner.canAccess('/owner/reports'),isTrue);
    expect(AppRole.receptionist.canAccess('/owner/reports'),isFalse);
  });
  test('CSV export quotes commas, quotes, and newlines',() {
    final csv=csvRows([['Name','Notes'],['Alice, Jr','said "hi"\nagain']]);
    expect(csv,contains('"Alice, Jr"'));
    expect(csv,contains('"said ""hi""\nagain"'));
  });
}
