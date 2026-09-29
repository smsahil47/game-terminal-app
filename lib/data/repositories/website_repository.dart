import '../models/website_models.dart';

abstract interface class WebsiteRepository {
  Future<ShopConfiguration> configuration();
  Future<void> syncGames(List<String> next, List<String> previous);
  Future<void> saveMenuRates(Map<String,int> rates);
  Future<void> saveCoreSettings({String? cafeName,int? totalControllers,int? gamingRate,int? vrRate,int? racingRate});
  Future<void> renameStation(String id,String name);
  Future<List<CustomerRecord>> customers();
  Future<void> saveCustomer(CustomerRecord customer);
  Future<List<ExpenseRecord>> expenses();
  Future<void> saveExpense(ExpenseRecord expense);
  Future<void> deleteExpense(String id);
  Future<List<TransactionRecord>> transactions();
}

class DisconnectedWebsiteRepository implements WebsiteRepository {
  const DisconnectedWebsiteRepository();
  Never get unavailable => throw StateError('Backend is disabled.');
  @override Future<ShopConfiguration> configuration() async => unavailable;
  @override Future<void> syncGames(List<String> next,List<String> previous) async => unavailable;
  @override Future<void> saveMenuRates(Map<String,int> rates) async => unavailable;
  @override Future<void> saveCoreSettings({String? cafeName,int? totalControllers,int? gamingRate,int? vrRate,int? racingRate}) async => unavailable;
  @override Future<void> renameStation(String id,String name) async => unavailable;
  @override Future<List<CustomerRecord>> customers() async => unavailable;
  @override Future<void> saveCustomer(CustomerRecord customer) async => unavailable;
  @override Future<List<ExpenseRecord>> expenses() async => unavailable;
  @override Future<void> saveExpense(ExpenseRecord expense) async => unavailable;
  @override Future<void> deleteExpense(String id) async => unavailable;
  @override Future<List<TransactionRecord>> transactions() async => unavailable;
}
