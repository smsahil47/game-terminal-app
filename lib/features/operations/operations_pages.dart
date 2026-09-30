import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/staff_shell.dart';
import '../../core/billing/billing.dart';
import '../../core/theme/website_widgets.dart';
import '../../data/models/app_role.dart';
import '../../data/models/operations.dart';
import '../../data/models/shop_snapshot.dart';
import '../../data/repositories/operations_repository.dart';
import '../../data/repositories/website_repository.dart';
import '../../services/document_export.dart';
import '../../services/live_shop_data.dart';
import 'booking_start.dart';

String money(int value) => '₹$value';
String dateOnly(DateTime date) => '${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
void notice(BuildContext context, Object message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message.toString())));
Future<void> runAction(BuildContext context, Future<void> Function() action) async {
  try { await action(); } catch (error) { if (context.mounted) notice(context,error); }
}
Widget field(TextEditingController controller, String label, {TextInputType? keyboard}) => Padding(
  padding: const EdgeInsets.only(bottom: 12), child: TextField(controller:controller,keyboardType:keyboard,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));
int parsed(TextEditingController controller) => int.tryParse(controller.text.trim()) ?? 0;

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key,required this.repository,required this.website,required this.role});
  final OperationsRepository repository;
  final WebsiteRepository website;
  final AppRole role;
  @override State<SessionsPage> createState()=>_SessionsPageState();
}
class _SessionsPageState extends State<SessionsPage> with LiveShopData {
  late Future<List<SessionDetail>> future = widget.repository.sessions();
  void reload() { setState(()=> future=widget.repository.sessions()); ShopScope.of(context).refresh(); }
  @override Widget build(BuildContext context) {
    final shop=ShopScope.of(context).snapshot;
    return RefreshIndicator(onRefresh:() async => reload(),child:ListView(padding:const EdgeInsets.all(16),children:[
      Row(children:[Expanded(child:Text('Sessions',style:Theme.of(context).textTheme.headlineSmall)),
        if(widget.role.canOperate && shop!=null) FilledButton.icon(onPressed:()=>_start(context,shop),icon:const Icon(Icons.add),label:const Text('Start'))]),
      const SizedBox(height:12),
      FutureBuilder<List<SessionDetail>>(future:future=refreshOnShopChange(future,widget.repository.sessions),builder:(context,snapshot){
        if(snapshot.hasError) return const WebsiteStatusPanel('Sessions unavailable',message:'Pull to retry.',icon:Icons.cloud_off_outlined);
        if(!snapshot.hasData) return const Center(child:CircularProgressIndicator());
        if(snapshot.data!.isEmpty) return const WebsiteStatusPanel('No active sessions',message:'Start a session from an available station.',icon:Icons.timer_outlined);
        return Column(children:[for(final s in snapshot.data!) Card(child:ListTile(
          title:Text('${s.stationName} · ${s.customerName}'), subtitle:Text('${s.mode.label} · ${s.status} · ${(s.targetMinutes??s.durationMinutes+s.extraMinutes)} min booked'),
          trailing: const Icon(Icons.chevron_right),onTap:()=>_details(context,s)))]);
      })
    ]));
  }
  Future<void> _start(BuildContext context,ShopSnapshot shop) async {
    final name=TextEditingController(), phone=TextEditingController(), minutes=TextEditingController(text:'60'), game=TextEditingController();
    final snackName=TextEditingController(),snackPrice=TextEditingController();
    final snacks=<Snack>[];
    Station? station=shop.stations.where((s)=>s.status==StationStatus.available).firstOrNull;
    SessionMode mode=SessionMode.gaming; int players=1; List<String> games=[];
    try { games=await widget.repository.games(); } catch (_) {}
    final config=await widget.website.configuration();
    if(!context.mounted) return;
    await showDialog<void>(context:context,builder:(dialog)=>StatefulBuilder(builder:(context,setDialog) => AlertDialog(
      title:const Text('Start session'),content:SizedBox(width:420,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        DropdownButtonFormField<Station>(initialValue:station,decoration:const InputDecoration(labelText:'Station'),items:[
          for(final s in shop.stations.where((s)=>s.status==StationStatus.available)) DropdownMenuItem(value:s,child:Text(s.name))
        ],onChanged:(v)=>setDialog((){station=v;if(v?.type!='PS5_MULTI')mode=SessionMode.gaming;})),
        const SizedBox(height:12),field(name,'Customer name'),field(phone,'Phone'),
        DropdownButtonFormField<SessionMode>(key:ValueKey('${station?.id}:${mode.value}'),initialValue:mode,
          decoration:const InputDecoration(labelText:'Mode'),items:[
          for(final m in station?.type=='PS5_MULTI'?SessionMode.values:[SessionMode.gaming]) DropdownMenuItem(value:m,child:Text(m.label))
        ],onChanged:(v)=>setDialog(()=>mode=v!)),
        if(mode==SessionMode.gaming) DropdownButtonFormField<int>(initialValue:players,decoration:const InputDecoration(labelText:'Players/controllers'),items:[
          for(var n=1;n<=4;n++) DropdownMenuItem(value:n,child:Text('$n'))
        ],onChanged:(v)=>setDialog(()=>players=v!)),
        if(games.isNotEmpty) DropdownButtonFormField<String>(decoration:const InputDecoration(labelText:'Game'),items:[
          for(final g in games) DropdownMenuItem(value:g,child:Text(g))
        ],onChanged:(v)=>game.text=v??''),
        field(game,'Game title'),field(minutes,'Duration minutes',keyboard:TextInputType.number),
        for(final snack in snacks)ListTile(title:Text(snack.name),trailing:Text(money(snack.price))),
        field(snackName,'Snack (optional)'),field(snackPrice,'Snack price',keyboard:TextInputType.number),
        TextButton(onPressed:(){if(snackName.text.trim().isEmpty||parsed(snackPrice)<=0)return;
          setDialog((){snacks.add(Snack(snackName.text.trim(),parsed(snackPrice)));snackName.clear();snackPrice.clear();});
        },child:const Text('Add snack')),
        Text('Menu charge: ${money(menuPlayAmount(mode,parsed(minutes),players,config.fallbackRate(mode.value,players),rates:config.menuRates))} · confirm duration before starting'),
      ]))),actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Cancel')),
        FilledButton(onPressed:() async { final selected=station; final duration=parsed(minutes);
          if(selected==null || name.text.trim().isEmpty || duration<=0){notice(dialog,'Enter a station, customer and valid duration.');return;}
          if(selected.type!='PS5_MULTI' && mode!=SessionMode.gaming){notice(dialog,'This station supports Gaming only.');return;}
          final charge=menuPlayAmount(mode,duration,players,config.fallbackRate(mode.value,players),rates:config.menuRates);
          await runAction(dialog,() async { await widget.repository.start(SessionDraft(station:selected,customerName:name.text,phone:phone.text,mode:mode,minutes:duration,players:players,game:game.text,playAmount:charge,ratePerHour:config.fallbackRate(mode.value,players),snacks:snacks),shop.controllersFree);
            if(dialog.mounted){Navigator.pop(dialog);reload();} });
        },child:const Text('Start'))]
    )));
  }
  Future<void> _details(BuildContext context,SessionDetail s) async {
    await showDialog<void>(context:context,builder:(dialog)=>AlertDialog(
      title:Text('${s.stationName} · ${s.customerName}'),content:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${s.mode.label} · ${(s.targetMinutes??s.durationMinutes+s.extraMinutes)} booked minutes'),
        Text('Started ${s.startedAt.toLocal()}'),Text('Game: ${s.game??'—'}'),
        Text('Snacks: ${money(s.snacksTotal)}'),
        if(s.endedAt!=null) Text('Stopped ${s.endedAt!.toLocal()}'),
      ]),actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Close')),
        if(widget.role.canOperate) ...[
          TextButton(onPressed:(){Navigator.pop(dialog);_extend(context,s);},child:const Text('Extend')),
          TextButton(onPressed:(){Navigator.pop(dialog);_snack(context,s);},child:const Text('Add snack')),
          if(s.endedAt==null) TextButton(onPressed:() async {await runAction(dialog,() async {await widget.repository.stop(s);if(dialog.mounted){Navigator.pop(dialog);reload();}});},child:const Text('Stop timer')),
          FilledButton(onPressed:(){Navigator.pop(dialog);_checkout(context,s);},child:const Text('Checkout')),
        ]
      ]));
  }
  Future<void> _extend(BuildContext context,SessionDetail s) async {
    int minutes=30;
    final config=await widget.website.configuration();
    if(!context.mounted)return;
    await showDialog<void>(context:context,builder:(dialog)=>StatefulBuilder(builder:(context,setDialog)=>AlertDialog(
      title:const Text('Extend session'),content:DropdownButton<int>(value:minutes,items:[15,30,60,120].map((v)=>DropdownMenuItem(value:v,child:Text('$v minutes'))).toList(),onChanged:(v)=>setDialog(()=>minutes=v!)),
      actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Cancel')),
        FilledButton(onPressed:() async {await runAction(dialog,() async {await widget.repository.extend(s,minutes,menuPlayAmount(s.mode,minutes,s.players??1,config.fallbackRate(s.mode.value,s.players??1),rates:config.menuRates));if(dialog.mounted){Navigator.pop(dialog);reload();}});},child:const Text('Extend'))]
    )));
  }
  Future<void> _snack(BuildContext context,SessionDetail s) async {
    final name=TextEditingController(),price=TextEditingController();
    await showDialog<void>(context:context,builder:(dialog)=>AlertDialog(title:const Text('Add snack'),content:Column(mainAxisSize:MainAxisSize.min,children:[field(name,'Snack'),field(price,'Price',keyboard:TextInputType.number)]),actions:[
      TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Cancel')),
      FilledButton(onPressed:() async {await runAction(dialog,() async {await widget.repository.addSnack(s,Snack(name.text,parsed(price)));if(dialog.mounted){Navigator.pop(dialog);reload();}});},child:const Text('Add'))
    ]));
  }
  Future<void> _checkout(BuildContext context,SessionDetail s) async {
    final ended=DateTime.now(); final elapsed=ended.difference(s.startedAt).inMinutes.clamp(0,999999);
    final booked=(s.targetMinutes??s.durationMinutes+s.extraMinutes);
    final play=(s.ratePerHour*ended.difference(s.startedAt).inSeconds.clamp(0,999999999)/3600).floor();
    final discount=TextEditingController(text:'0'),received=TextEditingController(text:'${play+s.snacksTotal}');
    String method='CASH';
    await showDialog<void>(context:context,builder:(dialog)=>StatefulBuilder(builder:(context,setDialog){
      final bill=Bill(play,s.snacksTotal,parsed(discount));
      return AlertDialog(title:const Text('Billing & checkout'),content:SizedBox(width:380,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        Text('Booked: $booked min · Elapsed: $elapsed min'),Text('Play ${money(play)} + Snacks ${money(s.snacksTotal)}'),
        Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:discount,keyboardType:TextInputType.number,onChanged:(_)=>setDialog((){}),decoration:const InputDecoration(labelText:'Discount',border:OutlineInputBorder()))),
        DropdownButtonFormField<String>(initialValue:method,decoration:const InputDecoration(labelText:'Payment method'),items:const [
          DropdownMenuItem(value:'CASH',child:Text('Cash')),DropdownMenuItem(value:'UPI',child:Text('UPI'))],onChanged:(v)=>setDialog(()=>method=v!)),
        Padding(padding:const EdgeInsets.only(bottom:12),child:TextField(controller:received,keyboardType:TextInputType.number,onChanged:(_)=>setDialog((){}),decoration:const InputDecoration(labelText:'Amount received',border:OutlineInputBorder()))),
        Text('Subtotal ${money(bill.subtotal)} · Total ${money(bill.total)}'),
        Text('Change ${money(bill.change(parsed(received)))}'),
      ]))),actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Cancel')),
        FilledButton(onPressed:() async {
          final paidAt=DateTime.now();
          final seconds=paidAt.difference(s.startedAt).inSeconds.clamp(0,999999999);
          final paidMinutes=(seconds/60).round();
          final finalBill=Bill((s.ratePerHour*seconds/3600).floor(),s.snacksTotal,parsed(discount));
          if(parsed(received)<finalBill.total){notice(dialog,'Received amount is below total.');return;}
          await runAction(dialog,() async {final receipt=await widget.repository.checkout(Checkout(
            session:s,bill:finalBill,method:method,received:parsed(received),minutes:paidMinutes,endedAt:paidAt));
            if(dialog.mounted){
              Navigator.pop(dialog);reload();
              final lines=<List<Object?>>[
                ['Receipt',receipt.number],['Customer',s.customerName],['Station',s.stationName],
                ['Mode',s.mode.label],if(s.game!=null && s.game!.isNotEmpty)['Game',s.game],
                ['Started',s.startedAt.toLocal().toString()],['Ended',paidAt.toLocal().toString()],
                ['Duration','$paidMinutes min'],['Play',money(finalBill.play)],
                ['Snacks',money(finalBill.snacks)],['Discount',money(finalBill.appliedDiscount)],
                ['Total',money(receipt.total)],['Payment',method],
                ['Received',money(parsed(received))],['Change',money(receipt.change)],
              ];
              showDialog<void>(context:context,builder:(r)=>AlertDialog(
                title:Text('Receipt ${receipt.number}'),
                content:SizedBox(width:320,child:ListView(shrinkWrap:true,children:[
                  for(final line in lines)ListTile(dense:true,title:Text(line[0].toString()),trailing:Text(line[1].toString())),
                  if(receipt.warning!=null)Text(receipt.warning!),
                ])),
                actions:[
                  TextButton(onPressed:()=>printReceipt('Game Terminal',lines),child:const Text('Print')),
                  TextButton(onPressed:()=>sharePdf('receipt-${receipt.number}.pdf','Game Terminal Receipt',lines),
                    child:const Text('Share PDF')),
                  TextButton(onPressed:()=>Navigator.pop(r),child:const Text('Done')),
                ]));
            }
          });
        },child:const Text('Record payment'))]);
    }));
  }
}

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key,required this.repository,required this.website,required this.role});
  final OperationsRepository repository; final WebsiteRepository website; final AppRole role;
  @override State<BookingsPage> createState()=>_BookingsPageState();
}
class _BookingsPageState extends State<BookingsPage> with LiveShopData {
  String scope='today';
  String query='';
  String? modeFilter,stationFilter;
  DateTime? exactDate;
  late Future<List<Booking>> future=widget.repository.bookings();
  void reload()=>setState(()=>future=widget.repository.bookings());
  @override Widget build(BuildContext context) {
    final shop=ShopScope.of(context).snapshot;
    return RefreshIndicator(onRefresh:() async=>reload(),child:ListView(padding:const EdgeInsets.all(16),children:[
      Row(children:[Expanded(child:Text('Bookings',style:Theme.of(context).textTheme.headlineSmall)),
        if(widget.role.canOperate && shop!=null) FilledButton.icon(onPressed:()=>_edit(context,shop,null),icon:const Icon(Icons.add),label:const Text('New'))]),
      const SizedBox(height:12),
      Wrap(spacing:8,children:[
        for(final value in ['today','upcoming','all']) ChoiceChip(label:Text(value),selected:scope==value,
          onSelected:(_)=>setState(()=>scope=value)),
        DropdownButton<String?>(value:modeFilter,hint:const Text('All modes'),items:[
          const DropdownMenuItem(value:null,child:Text('All modes')),
          for(final m in SessionMode.values)DropdownMenuItem(value:m.value,child:Text(m.label))],
          onChanged:(v)=>setState(()=>modeFilter=v)),
        if(shop!=null)DropdownButton<String?>(value:stationFilter,hint:const Text('All stations'),items:[
          const DropdownMenuItem(value:null,child:Text('All stations')),
          for(final s in shop.stations)DropdownMenuItem(value:s.id,child:Text(s.name))],
          onChanged:(v)=>setState(()=>stationFilter=v)),
        TextButton(onPressed:()async{final day=await showDatePicker(context:context,initialDate:exactDate??DateTime.now(),
          firstDate:DateTime(2020),lastDate:DateTime(2100));if(day!=null)setState(()=>exactDate=day);},
          child:Text(exactDate==null?'Any date':dateOnly(exactDate!))),
        if(exactDate!=null)IconButton(onPressed:()=>setState(()=>exactDate=null),icon:const Icon(Icons.clear)),
      ]),
      TextField(decoration:const InputDecoration(labelText:'Search customer or phone',prefixIcon:Icon(Icons.search)),
        onChanged:(value)=>setState(()=>query=value.trim().toLowerCase())),
      FutureBuilder<List<Booking>>(future:future=refreshOnShopChange(future,widget.repository.bookings),builder:(context,snapshot){
        if(snapshot.hasError) return const WebsiteStatusPanel('Bookings unavailable',message:'Pull to retry.',icon:Icons.cloud_off_outlined);
        if(!snapshot.hasData) return const Center(child:CircularProgressIndicator());
        final today=dateOnly(DateTime.now());
        final visible=snapshot.data!.where((b){
          if(scope=='today'&&b.date!=today)return false;
          if(scope=='upcoming'&&(b.date.compareTo(today)<0||b.status!='CONFIRMED'))return false;
          if(exactDate!=null&&b.date!=dateOnly(exactDate!))return false;
          if(modeFilter!=null&&b.mode.value!=modeFilter)return false;
          if(stationFilter!=null&&b.stationId!=stationFilter)return false;
          return b.customerName.toLowerCase().contains(query)||(b.customerPhone??'').contains(query);
        }).toList();
        final rows=<List<Object?>>[
          ['Date','Start','Customer','Phone','Station','Mode','Duration','Status','Advance','Method','Balance'],
          for(final b in visible)[b.date,b.startTime,b.customerName,b.customerPhone??'',b.stationName,b.mode.value,
            b.durationMinutes,b.status,b.advanceAmount,b.advancePaymentMethod??'',b.balanceAmount??0]];
        if(visible.isEmpty)return const WebsiteStatusPanel('No bookings match these filters',message:'Try another date or status.',icon:Icons.calendar_month_outlined);
        return Column(children:[
          Row(children:[
            TextButton(onPressed:()=>shareCsv(context,'bookings.csv',rows),child:const Text('Export CSV')),
            TextButton(onPressed:()=>sharePdf('bookings.pdf','Bookings',rows),child:const Text('Export PDF')),
          ]),
          for(final b in visible) Card(child:ListTile(
          leading:Column(mainAxisAlignment:MainAxisAlignment.center,mainAxisSize:MainAxisSize.min,children:[
            Text(b.startTime,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600)),
            Text(b.date==dateOnly(DateTime.now())?'Today':b.date,
              style:Theme.of(context).textTheme.bodySmall)]),
          title:Text(b.customerName),
          subtitle:Text('${b.stationName} · ${b.mode.label} · ${b.durationMinutes} min · ${b.status}\nAdvance ${money(b.advanceAmount)}'),
          isThreeLine:true, trailing:widget.role.canOperate&&b.status=='CONFIRMED'?PopupMenuButton<String>(onSelected:(v) {
            if(v=='edit' && shop!=null) _edit(context,shop,b);
            if(v=='cancel') runAction(context,() async {await widget.repository.cancelBooking(b.id);reload();});
            if(v=='start' && shop!=null){runAction(context,()async{
              final started=await startBookedSession(context,b,shop,widget.repository,widget.website);
              if(started&&context.mounted){reload();ShopScope.of(context).refresh();}
            });}
          },itemBuilder:(_)=>const [
            PopupMenuItem(value:'start',child:Text('Start session')),
            PopupMenuItem(value:'edit',child:Text('Edit')),
            PopupMenuItem(value:'cancel',child:Text('Cancel'))]):null))]);
      })
    ]));
  }
  Future<void> _edit(BuildContext context,ShopSnapshot shop,Booking? old) async {
    final name=TextEditingController(text:old?.customerName),phone=TextEditingController(text:old?.customerPhone),
      duration=TextEditingController(text:'${old?.durationMinutes??60}'),advance=TextEditingController(text:'${old?.advanceAmount??0}');
    Station? station=shop.stations.where((s)=>s.id==old?.stationId).firstOrNull??shop.stations.firstOrNull;
    SessionMode mode=old?.mode??SessionMode.gaming; DateTime date=old==null?DateTime.now():DateTime.parse(old.date);
    TimeOfDay time=old==null?TimeOfDay.now():TimeOfDay(hour:int.parse(old.startTime.substring(0,2)),minute:int.parse(old.startTime.substring(3,5)));
    String method=old?.advancePaymentMethod??'CASH';
    await showDialog<void>(context:context,builder:(dialog)=>StatefulBuilder(builder:(context,setDialog)=>AlertDialog(
      title:Text(old==null?'New booking':'Edit booking'),content:SizedBox(width:400,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        field(name,'Customer name'),field(phone,'Phone'),
        DropdownButtonFormField<Station>(initialValue:station,decoration:const InputDecoration(labelText:'Station'),items:[
          for(final s in shop.stations) DropdownMenuItem(value:s,child:Text(s.name))],
          onChanged:(v)=>setDialog((){station=v;if(v?.type!='PS5_MULTI')mode=SessionMode.gaming;})),
        DropdownButtonFormField<SessionMode>(key:ValueKey('${station?.id}:${mode.value}'),initialValue:mode,
          decoration:const InputDecoration(labelText:'Mode'),items:[
          for(final m in station?.type=='PS5_MULTI'?SessionMode.values:[SessionMode.gaming])
            DropdownMenuItem(value:m,child:Text(m.label))],onChanged:(v)=>setDialog(()=>mode=v!)),
        Row(children:[TextButton(onPressed:() async {final picked=await showDatePicker(context:dialog,initialDate:date,firstDate:DateTime(2020),lastDate:DateTime(2100));if(picked!=null)setDialog(()=>date=picked);},child:Text(dateOnly(date))),
          TextButton(onPressed:() async {final picked=await showTimePicker(context:dialog,initialTime:time);if(picked!=null)setDialog(()=>time=picked);},child:Text(time.format(dialog)))]),
        field(duration,'Duration minutes',keyboard:TextInputType.number),field(advance,'Advance',keyboard:TextInputType.number),
        DropdownButtonFormField<String>(initialValue:method,decoration:const InputDecoration(labelText:'Advance method'),items:const [
          DropdownMenuItem(value:'CASH',child:Text('Cash')),DropdownMenuItem(value:'UPI',child:Text('UPI'))],onChanged:(v)=>setDialog(()=>method=v!)),
      ]))),actions:[TextButton(onPressed:()=>Navigator.pop(dialog),child:const Text('Cancel')),
        FilledButton(onPressed:() async {final selected=station; if(selected==null){notice(dialog,'Choose a station.');return;}
          if(selected.type!='PS5_MULTI' && mode!=SessionMode.gaming){notice(dialog,'This station supports Gaming only.');return;}
          final b=Booking(id:old?.id??'',customerName:name.text,customerPhone:phone.text,stationId:selected.id,stationName:selected.name,mode:mode,date:dateOnly(date),
            startTime:'${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}',durationMinutes:parsed(duration),status:'CONFIRMED',advanceAmount:parsed(advance));
          await runAction(dialog,() async {await widget.repository.saveBooking(b,advanceMethod:method);if(dialog.mounted){Navigator.pop(dialog);reload();}});
        },child:const Text('Save'))]
    )));
  }
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key,required this.repository});
  final OperationsRepository repository;
  @override State<ReportsPage> createState()=>_ReportsPageState();
}
class _ReportsPageState extends State<ReportsPage> {
  DateTime start=DateTime.now().subtract(const Duration(days:29)),end=DateTime.now();
  late Future<ReportData> future=widget.repository.report(start,end);
  void reload()=>setState(()=>future=widget.repository.report(start,end));
  @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:() async=>reload(),child:ListView(padding:const EdgeInsets.all(16),children:[
    Text('Reports',style:Theme.of(context).textTheme.headlineSmall),
    Row(children:[TextButton(onPressed:() async {final range=await showDateRangePicker(context:context,firstDate:DateTime(2020),lastDate:DateTime(2100),initialDateRange:DateTimeRange(start:start,end:end));if(range!=null){start=range.start;end=range.end;reload();}},child:Text('${dateOnly(start)} to ${dateOnly(end)}')),
      const Spacer(),IconButton(onPressed:reload,icon:const Icon(Icons.refresh))]),
    FutureBuilder<ReportData>(future:future,builder:(context,snapshot) {
      if(snapshot.hasError) return const WebsiteStatusPanel('Reports unavailable',message:'Pull to retry.',icon:Icons.cloud_off_outlined);
      if(!snapshot.hasData) return const Center(child:CircularProgressIndicator());
      final data=snapshot.data!;
      final modeTotals=<SessionMode,int>{for(final m in SessionMode.values)m:0};
      for(final sale in data.sales){modeTotals[sale.mode]=modeTotals[sale.mode]!+sale.total;}
      final maxValue=modeTotals.values.fold<int>(1,(a,b)=>a>b?a:b);
      return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Wrap(spacing:8,children:[
          Chip(label:Text('Sales ${money(data.salesTotal)}')),Chip(label:Text('Advances ${money(data.advanceTotal)}')),
          Chip(label:Text('Expenses ${money(data.expenseTotal)}')),Chip(label:Text('Net ${money(data.net)}'))]),
        const SizedBox(height:16),Text('Revenue by mode',style:Theme.of(context).textTheme.titleMedium),
        for(final entry in modeTotals.entries) Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Row(children:[
          SizedBox(width:90,child:Text(entry.key.label)),Expanded(child:LinearProgressIndicator(value:entry.value/maxValue,minHeight:12)),
          const SizedBox(width:8),Text(money(entry.value))])),
        const SizedBox(height:20),Text('Transactions (${data.sales.length})',style:Theme.of(context).textTheme.titleMedium),
        for(final sale in data.sales) ListTile(title:Text('${sale.receipt} · ${money(sale.total)}'),subtitle:Text('${sale.customer} · ${sale.station} · ${sale.method}')),
        const SizedBox(height:16),Text('Expenses (${data.expenses.length})',style:Theme.of(context).textTheme.titleMedium),
        for(final expense in data.expenses) ListTile(title:Text('${expense.category} · ${money(expense.amount)}'),subtitle:Text(expense.date)),
        const SizedBox(height:16),Text('Booking overview (${data.bookings.length})',style:Theme.of(context).textTheme.titleMedium),
        for(final booking in data.bookings) ListTile(title:Text(booking.customerName),subtitle:Text('${booking.status} · Advance ${money(booking.advanceAmount)}')),
        const SizedBox(height:16),Builder(builder:(button)=>FilledButton.icon(onPressed:() async {
          await SharePlus.instance.share(ShareParams(files:[XFile.fromData(utf8.encode(data.toCsv()),mimeType:'text/csv')],fileNameOverrides:['game-terminal-report.csv'],sharePositionOrigin:(button.findRenderObject() as RenderBox).localToGlobal(Offset.zero)&(button.findRenderObject() as RenderBox).size));
        },icon:const Icon(Icons.ios_share),label:const Text('Export CSV'))),
      ]);
    })
  ]));
}
