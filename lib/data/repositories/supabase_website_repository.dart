import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/website_models.dart';
import '../../core/validation/staff_validation.dart';
import 'website_repository.dart';

class SupabaseWebsiteRepository implements WebsiteRepository {
  SupabaseWebsiteRepository(this.client);
  final SupabaseClient client;
  List<Map<String,dynamic>> rows(dynamic data) => (data as List)
    .map((row)=>Map<String,dynamic>.from(row as Map)).toList();

  @override Future<ShopConfiguration> configuration() async {
    final settings=await client.from('app_settings').select('*').eq('id',1).single();
    final pricing=await client.from('pricing_rates').select('*').eq('id',1).single();
    final gameRows=rows(await client.from('games').select('title').eq('is_active',true).order('created_at').order('title'));
    return ShopConfiguration(
      cafeName:settings['cafe_name'] as String,
      totalControllers:(settings['total_controllers'] as num).toInt(),
      gamingRate:(settings['gaming_rate_per_hour'] as num).round(),
      vrRate:(settings['vr_rate_per_hour'] as num).round(),
      racingRate:(settings['racing_rate_per_hour'] as num).round(),
      menuRates:{for(final key in menuRateLabels.keys) key:(pricing[key] as num).round()},
      games:gameRows.map((row)=>row['title'] as String).toList(),
    );
  }
  @override Future<void> syncGames(List<String> next,List<String> previous) async {
    final titles=next.map((t)=>t.trim()).where((t)=>t.isNotEmpty).toSet();
    final added=titles.difference(previous.toSet());
    final removed=previous.toSet().difference(titles);
    if(added.isNotEmpty) {await client.from('games').upsert(
      [for(final title in added){'title':title,'is_active':true}],onConflict:'title');}
    if(removed.isNotEmpty) await client.from('games').update({'is_active':false}).inFilter('title',removed.toList());
  }
  @override Future<void> saveMenuRates(Map<String,int> rates) async {
    if(rates.keys.any((key)=>!menuRateLabels.containsKey(key)) || rates.values.any((v)=>v<0)) throw StateError('Invalid menu rate.');
    final row=await client.from('pricing_rates').update(rates).eq('id',1).select('id').maybeSingle();
    if(row==null) throw StateError('Pricing row is missing.');
  }
  @override Future<void> saveCoreSettings({String? cafeName,int? totalControllers,int? gamingRate,int? vrRate,int? racingRate}) async {
    final patch=<String,dynamic>{};
    if(cafeName!=null) patch['cafe_name']=cafeName.trim();
    if(totalControllers!=null) patch['total_controllers']=totalControllers;
    if(gamingRate!=null) patch['gaming_rate_per_hour']=gamingRate;
    if(vrRate!=null) patch['vr_rate_per_hour']=vrRate;
    if(racingRate!=null) patch['racing_rate_per_hour']=racingRate;
    if(patch.isEmpty)return;
    final row=await client.from('app_settings').update(patch).eq('id',1).select('id').maybeSingle();
    if(row==null) throw StateError('Settings row is missing.');
  }
  @override Future<void> renameStation(String id,String name) async {
    if(name.trim().isEmpty)throw StateError('Station name is required.');
    final row=await client.from('stations').update({'name':name.trim()}).eq('id',id).select('id').maybeSingle();
    if(row==null)throw StateError('Station is missing.');
  }
  @override Future<List<CustomerRecord>> customers() async => rows(
    await client.from('customers').select('*').order('name')).map(CustomerRecord.fromJson).toList();
  @override Future<void> saveCustomer(CustomerRecord customer) async {
    final nameError=customerNameError(customer.name);
    if(nameError!=null)throw StateError(nameError);
    final phoneError=indianPhoneError(customer.phone);
    if(phoneError!=null)throw StateError(phoneError);
    final payload={'name':customer.name.trim(),'phone':customer.phone?.trim().isEmpty==true?null:customer.phone?.trim()};
    if(customer.id.isEmpty){await client.from('customers').insert(payload);}
    else {final row=await client.from('customers').update(payload).eq('id',customer.id).select('id').maybeSingle();if(row==null)throw StateError('Customer is missing.');}
  }
  @override Future<List<ExpenseRecord>> expenses() async => rows(await client.from('expenses').select('*').order('expense_date',ascending:false).order('created_at',ascending:false)).map(ExpenseRecord.fromJson).toList();
  @override Future<void> saveExpense(ExpenseRecord expense) async {
    if(expense.amount<=0 || !expenseCategories.contains(expense.category))throw StateError('Enter a valid expense.');
    final payload={'amount':expense.amount,'category':expense.category,'expense_date':expense.date,'notes':expense.notes?.trim().isEmpty==true?null:expense.notes?.trim()};
    if(expense.id.isEmpty){await client.from('expenses').insert(payload);}
    else {final row=await client.from('expenses').update(payload).eq('id',expense.id).select('id').maybeSingle();if(row==null)throw StateError('Expense is missing.');}
  }
  @override Future<void> deleteExpense(String id) async {await client.from('expenses').delete().eq('id',id);}
  @override Future<List<TransactionRecord>> transactions() async => rows(await client.from('transactions').select('*').order('transaction_date',ascending:false)).map(TransactionRecord.fromJson).toList();
}
