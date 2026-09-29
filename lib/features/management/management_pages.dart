import 'package:flutter/material.dart';

import '../../app/staff_shell.dart';
import '../../data/models/website_models.dart';
import '../../data/repositories/website_repository.dart';
import '../../services/document_export.dart';
import '../../services/live_shop_data.dart';
import '../operations/operations_pages.dart' show dateOnly, money, notice, runAction, field, parsed;

class GameTerminalPage extends StatefulWidget {
  const GameTerminalPage({super.key,required this.repository});
  final WebsiteRepository repository;
  @override State<GameTerminalPage> createState()=>_GameTerminalPageState();
}
class _GameTerminalPageState extends State<GameTerminalPage> with LiveShopData {
  late Future<ShopConfiguration> future=widget.repository.configuration();
  void reload()=>setState(()=>future=widget.repository.configuration());
  @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:()async=>reload(),child:ListView(padding:const EdgeInsets.all(16),children:[
    Text('Game Terminal',style:Theme.of(context).textTheme.headlineSmall),
    FutureBuilder<ShopConfiguration>(future:future=refreshOnShopChange(future,widget.repository.configuration),builder:(context,snapshot){
      if(snapshot.hasError)return const Text('Game Terminal data unavailable. Pull to retry.');
      if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
      final config=snapshot.data!;
      final shop=ShopScope.of(context).snapshot;
      return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const SizedBox(height:12),
        Text('Games',style:Theme.of(context).textTheme.titleLarge),
        for(final game in config.games) ListTile(title:Text(game),trailing:IconButton(icon:const Icon(Icons.delete_outline),tooltip:'Remove game',
          onPressed:()async{
            final confirmed=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(
              title:const Text('Remove game?'),content:Text(game),actions:[
                TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('Cancel')),
                FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:const Text('Remove'))]));
            if(confirmed==true && mounted){
              await runAction(this.context,()async{
                await widget.repository.syncGames(config.games.where((g)=>g!=game).toList(),config.games);
                reload();
              });
            }
          })),
        FilledButton.icon(onPressed:()=>_addGame(config),icon:const Icon(Icons.add),label:const Text('Add game')),
        const SizedBox(height:24),
        Text('Pricing',style:Theme.of(context).textTheme.titleLarge),
        for(final entry in menuRateLabels.entries) ListTile(title:Text(entry.value),trailing:Text(money(config.menuRates[entry.key]??0))),
        FilledButton.icon(onPressed:()=>_editRates(config),icon:const Icon(Icons.edit),label:const Text('Edit rates')),
        const SizedBox(height:24),
        Text('Shop settings',style:Theme.of(context).textTheme.titleLarge),
        ListTile(title:Text(config.cafeName),subtitle:Text('Controllers: ${config.totalControllers} · Gaming ${money(config.gamingRate)}/hr · VR ${money(config.vrRate)}/hr · Racing ${money(config.racingRate)}/hr')),
        OutlinedButton(onPressed:()=>_editSettings(config),child:const Text('Edit shop settings')),
        const SizedBox(height:24),
        Text('Console names',style:Theme.of(context).textTheme.titleLarge),
        if(shop!=null) for(final station in shop.stations) ListTile(title:Text(station.name),subtitle:Text(station.type),
          trailing:IconButton(icon:const Icon(Icons.edit),tooltip:'Rename',onPressed:()=>_rename(station.id,station.name))),
      ]);
    })
  ]));
  Future<void> _addGame(ShopConfiguration config) async {
    final title=TextEditingController();
    await showDialog<void>(context:context,builder:(dialog)=>AlertDialog(title:const Text('Add game'),
      content:field(title,'Game title'),actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Cancel')),
      FilledButton(onPressed:()async{if(title.text.trim().isEmpty)return;
        await runAction(dialog,()async{await widget.repository.syncGames([...config.games,title.text.trim()],config.games);
          if(dialog.mounted){Navigator.pop(dialog);reload();}});},child:const Text('Add'))]));
  }
  Future<void> _editRates(ShopConfiguration config) async {
    final inputs={for(final key in menuRateLabels.keys)key:TextEditingController(text:'${config.menuRates[key]??0}')};
    await showDialog<void>(context:context,builder:(dialog)=>AlertDialog(title:const Text('Menu rates'),
      content:SizedBox(width:420,height:400,child:ListView(children:[for(final entry in menuRateLabels.entries)
        field(inputs[entry.key]!,entry.value,keyboard:TextInputType.number)])),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Cancel')),
        FilledButton(onPressed:()async{if(inputs.values.any((v)=>int.tryParse(v.text)==null||parsed(v)<0)){notice(dialog,'Enter valid nonnegative rates.');return;}
          await runAction(dialog,()async{await widget.repository.saveMenuRates({for(final entry in inputs.entries)entry.key:parsed(entry.value)});
            if(dialog.mounted){Navigator.pop(dialog);reload();}});},child:const Text('Save rates'))]));
  }
  Future<void> _editSettings(ShopConfiguration config) async {
    final name=TextEditingController(text:config.cafeName),controllers=TextEditingController(text:'${config.totalControllers}'),
      gaming=TextEditingController(text:'${config.gamingRate}'),vr=TextEditingController(text:'${config.vrRate}'),
      racing=TextEditingController(text:'${config.racingRate}');
    await showDialog<void>(context:context,builder:(dialog)=>AlertDialog(title:const Text('Shop settings'),
      content:SizedBox(width:400,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        field(name,'Cafe name'),field(controllers,'Total controllers',keyboard:TextInputType.number),
        field(gaming,'Gaming per hour',keyboard:TextInputType.number),
        field(vr,'VR per hour',keyboard:TextInputType.number),field(racing,'Racing per hour',keyboard:TextInputType.number)]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Cancel')),
        FilledButton(onPressed:()async{if(name.text.trim().isEmpty||parsed(controllers)<1||[gaming,vr,racing].any((v)=>parsed(v)<0)){notice(dialog,'Check settings values.');return;}
          await runAction(dialog,()async{await widget.repository.saveCoreSettings(cafeName:name.text,totalControllers:parsed(controllers),gamingRate:parsed(gaming),vrRate:parsed(vr),racingRate:parsed(racing));
            if(dialog.mounted && mounted){Navigator.pop(dialog);reload();ShopScope.of(context).refresh();}});},child:const Text('Save'))]));
  }
  Future<void> _rename(String id,String current) async {
    final name=TextEditingController(text:current);
    await showDialog<void>(context:context,builder:(dialog)=>AlertDialog(title:const Text('Rename console'),content:field(name,'Name'),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Cancel')),
        FilledButton(onPressed:()async{await runAction(dialog,()async{await widget.repository.renameStation(id,name.text);
          if(dialog.mounted && mounted){Navigator.pop(dialog);ShopScope.of(context).refresh();}});},child:const Text('Save'))]));
  }
}

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key,required this.repository});
  final WebsiteRepository repository;
  @override State<CustomersPage> createState()=>_CustomersPageState();
}
class _CustomersPageState extends State<CustomersPage> with LiveShopData {
  late Future<List<CustomerRecord>> future=widget.repository.customers();
  final search=TextEditingController();
  void reload()=>setState(()=>future=widget.repository.customers());
  @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:()async=>reload(),child:ListView(padding:const EdgeInsets.all(16),children:[
    Row(children:[Expanded(child:Text('Customers',style:Theme.of(context).textTheme.headlineSmall)),
      FilledButton.icon(onPressed:()=>_edit(null),icon:const Icon(Icons.add),label:const Text('Add'))]),
    TextField(controller:search,decoration:const InputDecoration(labelText:'Search name or phone',prefixIcon:Icon(Icons.search)),onChanged:(_)=>setState((){})),
    FutureBuilder<List<CustomerRecord>>(future:future=refreshOnShopChange(future,widget.repository.customers),builder:(context,snapshot){
      if(snapshot.hasError)return const Text('Customers unavailable. Pull to retry.');
      if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
      final query=search.text.trim().toLowerCase();
      final visible=snapshot.data!.where((c)=>c.name.toLowerCase().contains(query)||(c.phone??'').contains(query));
      return Column(children:[for(final c in visible) Card(child:ListTile(title:Text(c.name),subtitle:Text(c.phone??'No phone'),
        trailing:IconButton(icon:const Icon(Icons.edit),onPressed:()=>_edit(c))))]);
    }),
  ]));
  Future<void> _edit(CustomerRecord? old) async {
    final name=TextEditingController(text:old?.name),phone=TextEditingController(text:old?.phone);
    await showDialog<void>(context:context,builder:(dialog)=>AlertDialog(title:Text(old==null?'Add customer':'Edit customer'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[field(name,'Name'),field(phone,'Phone')]),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Cancel')),
        FilledButton(onPressed:()async{await runAction(dialog,()async{await widget.repository.saveCustomer(CustomerRecord(id:old?.id??'',name:name.text,phone:phone.text));
          if(dialog.mounted){Navigator.pop(dialog);reload();}});},child:const Text('Save'))]));
  }
}

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key,required this.repository});
  final WebsiteRepository repository;
  @override State<ExpensesPage> createState()=>_ExpensesPageState();
}
class _ExpensesPageState extends State<ExpensesPage> with LiveShopData {
  late Future<List<ExpenseRecord>> future=widget.repository.expenses();
  final search=TextEditingController();
  String? category;
  DateTime? date;
  int? recentDays;
  void reload()=>setState(()=>future=widget.repository.expenses());
  @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:()async=>reload(),child:ListView(padding:const EdgeInsets.all(16),children:[
    Row(children:[Expanded(child:Text('Expenses',style:Theme.of(context).textTheme.headlineSmall)),
      FilledButton.icon(onPressed:()=>_edit(null),icon:const Icon(Icons.add),label:const Text('Add'))]),
    Wrap(spacing:8,children:[
      for(final option in <(String,int?)>[('All',null),('Today',0),('7 days',6),('30 days',29)])
        ChoiceChip(label:Text(option.$1),selected:recentDays==option.$2,onSelected:(_)=>setState(()=>recentDays=option.$2)),
      DropdownButton<String?>(value:category,hint:const Text('All categories'),items:[
        const DropdownMenuItem(value:null,child:Text('All categories')),
        for(final c in expenseCategories)DropdownMenuItem(value:c,child:Text(c))
      ],onChanged:(v)=>setState(()=>category=v)),
      TextButton(onPressed:()async{final d=await showDatePicker(context:context,initialDate:date??DateTime.now(),firstDate:DateTime(2020),lastDate:DateTime(2100));
        if(d!=null)setState(()=>date=d);},child:Text(date==null?'All dates':dateOnly(date!))),
      if(date!=null)IconButton(onPressed:()=>setState(()=>date=null),icon:const Icon(Icons.clear)),
    ]),
    TextField(controller:search,onChanged:(_)=>setState((){}),
      decoration:const InputDecoration(labelText:'Search category or notes',prefixIcon:Icon(Icons.search))),
    FutureBuilder<List<ExpenseRecord>>(future:future=refreshOnShopChange(future,widget.repository.expenses),builder:(context,snapshot){
      if(snapshot.hasError)return const Text('Expenses unavailable. Pull to retry.');
      if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
      final cutoff=recentDays==null?null:DateTime.now().subtract(Duration(days:recentDays!));
      final query=search.text.trim().toLowerCase();
      final visible=snapshot.data!.where((e)=>(category==null||e.category==category)
        &&(query.isEmpty||e.category.toLowerCase().contains(query)||(e.notes??'').toLowerCase().contains(query))
        &&(date==null||e.date==dateOnly(date!))
        &&(cutoff==null||e.date.compareTo(dateOnly(cutoff))>=0)).toList();
      final total=visible.fold<int>(0,(sum,e)=>sum+e.amount);
      return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Total ${money(total)} · ${visible.length} expenses'),
        for(final e in visible)Card(child:ListTile(title:Text('${e.category} · ${money(e.amount)}'),
          subtitle:Text('${e.date}${e.notes==null?'':' · ${e.notes}'}'),
          trailing:PopupMenuButton<String>(onSelected:(v){
            if(v=='edit')_edit(e);
            if(v=='delete')_delete(e);
          },itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Edit')),
            PopupMenuItem(value:'delete',child:Text('Delete'))])))]);
    })
  ]));
  Future<void> _edit(ExpenseRecord? old) async {
    final amount=TextEditingController(text:old==null?'':'${old.amount}'),notes=TextEditingController(text:old?.notes);
    String category=old?.category??expenseCategories.first;
    DateTime date=old==null?DateTime.now():DateTime.parse(old.date);
    await showDialog<void>(context:context,builder:(dialog)=>StatefulBuilder(builder:(context,setDialog)=>AlertDialog(
      title:Text(old==null?'Add expense':'Edit expense'),content:Column(mainAxisSize:MainAxisSize.min,children:[
        field(amount,'Amount',keyboard:TextInputType.number),
        DropdownButton<String>(value:category,items:[for(final c in expenseCategories)DropdownMenuItem(value:c,child:Text(c))],
          onChanged:(v)=>setDialog(()=>category=v!)),
        TextButton(onPressed:()async{final d=await showDatePicker(context:dialog,initialDate:date,firstDate:DateTime(2020),lastDate:DateTime(2100));
          if(d!=null)setDialog(()=>date=d);},child:Text(dateOnly(date))),
        field(notes,'Notes'),
      ]),actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Cancel')),
        FilledButton(onPressed:()async{await runAction(dialog,()async{await widget.repository.saveExpense(ExpenseRecord(
          id:old?.id??'',amount:parsed(amount),category:category,date:dateOnly(date),notes:notes.text));
          if(dialog.mounted){Navigator.pop(dialog);reload();}});},child:const Text('Save'))])));
  }
  Future<void> _delete(ExpenseRecord e) async {
    final yes=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(title:const Text('Delete expense?'),
      content:Text('${e.category} · ${money(e.amount)}'),actions:[
        TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:const Text('Delete'))]));
    if(yes==true && mounted)await runAction(context,()async{await widget.repository.deleteExpense(e.id);reload();});
  }
}

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key,required this.repository});
  final WebsiteRepository repository;
  @override State<TransactionsPage> createState()=>_TransactionsPageState();
}
class _TransactionsPageState extends State<TransactionsPage> with LiveShopData {
  late Future<List<TransactionRecord>> future=widget.repository.transactions();
  final search=TextEditingController();
  String? mode,station;
  DateTime? date;
  int? recentDays;
  void reload()=>setState(()=>future=widget.repository.transactions());
  @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:()async=>reload(),child:ListView(padding:const EdgeInsets.all(16),children:[
    Text('Transactions',style:Theme.of(context).textTheme.headlineSmall),
    FutureBuilder<List<TransactionRecord>>(future:future=refreshOnShopChange(future,widget.repository.transactions),builder:(context,snapshot){
      if(snapshot.hasError)return const Text('Transactions unavailable. Pull to retry.');
      if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
      final all=snapshot.data!;
      final stations={for(final t in all)t.stationId:t.station};
      final cutoff=recentDays==null?null:DateTime.now().subtract(Duration(days:recentDays!));
      final query=search.text.trim().toLowerCase();
      final today=dateOnly(DateTime.now());
      final todaySales=all.where((t)=>dateOnly(t.date.toLocal())==today).toList();
      final todayTotal=todaySales.fold<int>(0,(sum,t)=>sum+t.total);
      final visible=all.where((t)=>(mode==null||t.mode==mode)&&(station==null||t.stationId==station)
        &&(query.isEmpty||t.customer.toLowerCase().contains(query)||t.receipt.toLowerCase().contains(query)||t.station.toLowerCase().contains(query))
        &&(date==null||dateOnly(t.date.toLocal())==dateOnly(date!))
        &&(cutoff==null||dateOnly(t.date.toLocal()).compareTo(dateOnly(cutoff))>=0)).toList();
      final rows=<List<Object?>>[
        ['Receipt','Date','Customer','Station','Mode','Method','Play','Snacks','Discount','Total'],
        for(final t in visible)[t.receipt,t.date.toLocal(),t.customer,t.station,t.mode,t.paymentMethod,
          t.playCharges,t.snacksTotal,t.discount,t.total]
      ];
      return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text("Today's receipts: ${todaySales.length} · Revenue: ${money(todayTotal)}"),
        TextField(controller:search,onChanged:(_)=>setState((){}),
          decoration:const InputDecoration(labelText:'Search customer, receipt or station',prefixIcon:Icon(Icons.search))),
        Wrap(spacing:8,children:[
          for(final option in <(String,int?)>[('All',null),('Today',0),('7 days',6),('30 days',29)])
            ChoiceChip(label:Text(option.$1),selected:recentDays==option.$2,onSelected:(_)=>setState(()=>recentDays=option.$2)),
          DropdownButton<String?>(value:mode,hint:const Text('All modes'),items:[
            const DropdownMenuItem(value:null,child:Text('All modes')),
            for(final m in ['GAMING','VR','RACING','RACING_VR'])DropdownMenuItem(value:m,child:Text(m))],
            onChanged:(v)=>setState(()=>mode=v)),
          DropdownButton<String?>(value:station,hint:const Text('All stations'),items:[
            const DropdownMenuItem(value:null,child:Text('All stations')),
            for(final e in stations.entries)DropdownMenuItem(value:e.key,child:Text(e.value))],
            onChanged:(v)=>setState(()=>station=v)),
          TextButton(onPressed:()async{final d=await showDatePicker(context:context,initialDate:date??DateTime.now(),
            firstDate:DateTime(2020),lastDate:DateTime(2100));if(d!=null)setState(()=>date=d);},
            child:Text(date==null?'All dates':dateOnly(date!))),
          if(date!=null)IconButton(onPressed:()=>setState(()=>date=null),icon:const Icon(Icons.clear)),
        ]),
        Text('${visible.length} transactions · ${money(visible.fold<int>(0,(sum,t)=>sum+t.total))}'),
        Row(children:[
          TextButton(onPressed:()=>shareCsv(context,'transactions.csv',rows),child:const Text('Export CSV')),
          TextButton(onPressed:()=>sharePdf('transactions.pdf','Transactions',rows),child:const Text('Export PDF')),
        ]),
        for(final t in visible)Card(child:ListTile(title:Text('${t.receipt} · ${money(t.total)}'),
          subtitle:Text('${t.customer} · ${t.station} · ${t.paymentMethod} · ${dateOnly(t.date.toLocal())}'),
          onTap:()=>_receipt(t),trailing:const Icon(Icons.receipt_long))),
      ]);
    })
  ]));
  void _receipt(TransactionRecord t) {
    final rows=<List<Object?>>[
      ['Receipt',t.receipt],['Date',t.date.toLocal().toString()],
      ['Customer',t.customer],['Station',t.station],['Mode',t.mode],
      if(t.game!=null && t.game!.isNotEmpty)['Game',t.game],
      if(t.players!=null)['Players',t.players],
      ['Duration','${t.durationMinutes} min'],['Play',money(t.playCharges)],
      ['Snacks',money(t.snacksTotal)],['Discount',money(t.discount)],
      ['Total',money(t.total)],['Payment',t.paymentMethod],
      ['Received',money(t.amountReceived)],['Change',money(t.changeReturned)],
    ];
    showDialog<void>(context:context,builder:(dialog)=>AlertDialog(title:Text('Receipt ${t.receipt}'),
      content:SizedBox(width:340,child:ListView(shrinkWrap:true,children:[
        for(final row in rows)ListTile(dense:true,title:Text(row[0].toString()),trailing:Text(row[1].toString()))])),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Close')),
        TextButton(onPressed:()=>printReceipt('Game Terminal',rows),child:const Text('Print')),
        TextButton(onPressed:()=>sharePdf('receipt-${t.receipt}.pdf','Receipt ${t.receipt}',rows),
          child:const Text('Share PDF'))]));
  }
}
