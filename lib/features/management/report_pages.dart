import 'package:flutter/material.dart';

import '../../app/staff_shell.dart';
import '../../core/theme/website_widgets.dart';
import '../../data/models/operations.dart';
import '../../data/models/shop_snapshot.dart';
import '../../data/models/website_models.dart';
import '../../data/repositories/operations_repository.dart';
import '../../data/repositories/website_repository.dart';
import '../../services/document_export.dart';
import '../../services/live_shop_data.dart';
import '../operations/operations_pages.dart' show dateOnly,money;
import '../shop/shop_pages.dart';

class DailyReportPage extends StatefulWidget {
  const DailyReportPage({super.key,required this.operations});
  final OperationsRepository operations;
  @override State<DailyReportPage> createState()=>_DailyReportPageState();
}
class _DailyReportPageState extends State<DailyReportPage> with LiveShopData {
  DateTime date=DateTime.now();
  late Future<ReportData> future=widget.operations.report(date,date);
  void reload()=>setState(()=>future=widget.operations.report(date,date));
  @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:()async=>reload(),child:ListView(padding:const EdgeInsets.all(16),children:[
    Text('Daily Report',style:Theme.of(context).textTheme.headlineSmall),
    TextButton(onPressed:()async{final d=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2020),lastDate:DateTime(2100));
      if(d!=null){date=d;reload();}},child:Text(dateOnly(date))),
    FutureBuilder<ReportData>(future:future=refreshOnShopChange(future,()=>widget.operations.report(date,date)),builder:(context,snapshot){
      if(snapshot.hasError)return const WebsiteStatusPanel('Daily report unavailable',message:'Pull to retry.',icon:Icons.cloud_off_outlined);
      if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
      final data=snapshot.data!;
      final gaming=data.sales.where((s)=>s.mode==SessionMode.gaming).fold<int>(0,(sum,s)=>sum+s.total);
      final rows=<List<Object?>>[
        ['Metric','Value'],['Total Sales',data.salesTotal],['Gaming Revenue',gaming],
        ['Other Income',data.salesTotal-gaming],['Booking Revenue',data.advanceTotal],
        ['Total Expenses',data.expenseTotal],['Net Amount',data.net],['Transactions',data.sales.length]];
      return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        WebsiteRows(children:[for(final row in rows.skip(1))ListTile(title:Text(row[0].toString()),trailing:Text(
          row[0]=='Transactions'?row[1].toString():money(row[1] as int)))]),
        Row(children:[
          TextButton(onPressed:()=>shareCsv(context,'daily-report-${dateOnly(date)}.csv',rows),child:const Text('Export CSV')),
          TextButton(onPressed:()=>sharePdf('daily-report-${dateOnly(date)}.pdf','Daily Report ${dateOnly(date)}',rows),child:const Text('Export PDF')),
        ])
      ]);
    })
  ]));
}

class OwnerBusinessPage extends StatefulWidget {
  const OwnerBusinessPage({super.key,required this.operations, this.reportsOnly=false});
  final OperationsRepository operations;
  final bool reportsOnly;
  @override State<OwnerBusinessPage> createState()=>_OwnerBusinessPageState();
}
class _OwnerBusinessPageState extends State<OwnerBusinessPage> with LiveShopData {
  late DateTime start=DateTime.now().subtract(Duration(days:widget.reportsOnly?29:0));
  DateTime end=DateTime.now();
  late Future<ReportData> future=widget.operations.report(start,end);
  void reload()=>setState(()=>future=widget.operations.report(start,end));
  @override Widget build(BuildContext context)=>RefreshIndicator(onRefresh:()async=>reload(),child:ListView(padding:const EdgeInsets.all(16),children:[
    Text(widget.reportsOnly?'Reports':'Business Overview',style:Theme.of(context).textTheme.headlineSmall),
    if(!widget.reportsOnly && ShopScope.of(context).snapshot!=null)Text(ShopScope.of(context).snapshot!.cafeName),
    Wrap(spacing:6,children:[
      for(final option in [('Today',0),('7 days',6),('30 days',29)])
        ChoiceChip(label:Text(option.$1),selected:DateTime.now().difference(start).inDays==option.$2,
          onSelected:(_){start=DateTime.now().subtract(Duration(days:option.$2));end=DateTime.now();reload();}),
      ActionChip(label:Text('${dateOnly(start)} to ${dateOnly(end)}'),onPressed:()async{
        final range=await showDateRangePicker(context:context,firstDate:DateTime(2020),lastDate:DateTime(2100),
          initialDateRange:DateTimeRange(start:start,end:end));
        if(range!=null){start=range.start;end=range.end;reload();}
      }),
    ]),
    FutureBuilder<ReportData>(future:future=refreshOnShopChange(future,()=>widget.operations.report(start,end)),builder:(context,snapshot){
      if(snapshot.hasError)return const WebsiteStatusPanel('Business data unavailable',message:'Pull to retry.',icon:Icons.cloud_off_outlined);
      if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
      final data=snapshot.data!;
      final gaming=data.sales.where((s)=>s.mode==SessionMode.gaming).fold<int>(0,(sum,s)=>sum+s.total);
      final expenses=<String,int>{};
      for(final e in data.expenses){expenses[e.category]=(expenses[e.category]??0)+e.amount;}
      final dates=<String,int>{};
      for(final sale in data.sales){final day=dateOnly(sale.date.toLocal());dates[day]=(dates[day]??0)+sale.total;}
      final sortedDates=dates.keys.toList()..sort();
      final rows=<List<Object?>>[
        ['Metric','Value'],['Total sales',data.salesTotal],['Gaming revenue',gaming],
        ['Other income',data.salesTotal-gaming],['Booking revenue',data.advanceTotal],
        ['Total expenses',data.expenseTotal],['Net revenue',data.net],['Transactions',data.sales.length],
        ['Revenue by period',''],for(final day in sortedDates)[day,dates[day]],
        ['Expenses by category',''],for(final e in expenses.entries)[e.key,e.value]];
      return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        if(!widget.reportsOnly)...[
          Wrap(spacing:8,runSpacing:8,children:[
            WebsiteMetricCard(label:'Total Sales',value:money(data.salesTotal),icon:Icons.trending_up),
            WebsiteMetricCard(label:'Net Revenue',value:money(data.net),icon:Icons.account_balance_wallet_outlined),
            WebsiteMetricCard(label:'Total Expenses',value:money(data.expenseTotal),icon:Icons.trending_down),
            WebsiteMetricCard(label:'Transactions',value:'${data.sales.length}',icon:Icons.receipt_long_outlined),
          ]),
          const SizedBox(height:12),
          Wrap(spacing:8,runSpacing:8,children:[
            WebsiteMetricCard(label:'Gaming Revenue',value:money(gaming),icon:Icons.sports_esports_outlined),
            WebsiteMetricCard(label:'Other Revenue',value:money(data.salesTotal-gaming),icon:Icons.wallet_outlined),
            WebsiteMetricCard(label:'Booking Revenue',value:money(data.advanceTotal),icon:Icons.calendar_month_outlined),
          ]),
        ] else WebsiteRows(children:[for(final e in rows.skip(1).take(7))
          ListTile(title:Text(e[0].toString()),trailing:Text(
            e[0]=='Transactions'?e[1].toString():money(e[1] as int)))]),
        const SizedBox(height:12),
        const WebsiteSectionTitle('Revenue trend'),
        if(sortedDates.isEmpty)const WebsiteStatusPanel('No sales recorded in this period.'),
        if(sortedDates.isNotEmpty)WebsiteRevenueChart(values:[for(final day in sortedDates)(day,dates[day]!)]),
        const SizedBox(height:16),
        const WebsiteSectionTitle('Expenses by category'),
        if(expenses.isEmpty)const WebsiteStatusPanel('No expenses recorded in this period.'),
        if(expenses.isNotEmpty)WebsiteExpenseChart(values:[for(final e in expenses.entries)(e.key,e.value)]),
        const SizedBox(height:16),
        const WebsiteSectionTitle('Recent transactions'),
        for(final sale in data.sales.take(widget.reportsOnly?data.sales.length:8))
          ListTile(title:Text('${sale.receipt} · ${money(sale.total)}'),
            subtitle:Text('${sale.customer} · ${sale.station} · ${sale.method}')),
        if(widget.reportsOnly)Row(children:[
          TextButton(onPressed:()=>shareCsv(context,'game-terminal-report.csv',rows),child:const Text('Export CSV')),
          TextButton(onPressed:()=>sharePdf('game-terminal-report.pdf','Game Terminal Report',rows),child:const Text('Export PDF')),
        ]),
      ]);
    })
  ]));
}
class OwnerOperationsPage extends StatefulWidget {
  const OwnerOperationsPage({super.key,required this.operations});
  final OperationsRepository operations;
  @override State<OwnerOperationsPage> createState()=>_OwnerOperationsPageState();
}
class _OwnerOperationsPageState extends State<OwnerOperationsPage> with LiveShopData {
  late Future<List<Booking>> future=widget.operations.bookings();
  @override Widget build(BuildContext context) {
    final snapshot=ShopScope.of(context).snapshot;
    return RefreshIndicator(onRefresh:()async{setState(()=>future=widget.operations.bookings());await ShopScope.of(context).refresh();},
      child:ListView(padding:const EdgeInsets.all(16),children:[
        Text('Shop Operations',style:Theme.of(context).textTheme.headlineSmall),
        if(snapshot!=null)...[
          Wrap(spacing:8,children:[
            Chip(label:Text('Consoles free ${snapshot.available}/${snapshot.stations.length}')),
            Chip(label:Text('Controllers free ${snapshot.controllersFree}/${snapshot.totalControllers}')),
            Chip(label:Text('Live sessions ${snapshot.sessions.length}')),
          ]),
          Text('Stations',style:Theme.of(context).textTheme.titleMedium),
          for(final s in snapshot.stations)ListTile(title:Text(s.name),subtitle:Text(s.status.label),
            trailing:Text(snapshot.sessions.where((v)=>v.stationId==s.id).map((v)=>v.customerName).join(', '))),
        ],
        Text('Upcoming bookings today',style:Theme.of(context).textTheme.titleMedium),
        FutureBuilder<List<Booking>>(future:future=refreshOnShopChange(future,widget.operations.bookings),builder:(context,result){
          if(result.hasError)return const Text('Bookings unavailable.');
          if(!result.hasData)return const Center(child:CircularProgressIndicator());
          final today=result.data!.where((b)=>b.date==dateOnly(DateTime.now())&&b.status=='CONFIRMED').toList()
            ..sort((a,b)=>a.startTime.compareTo(b.startTime));
          return Column(children:[for(final b in today)ListTile(title:Text('${b.startTime} · ${b.customerName}'),
            subtitle:Text('${b.stationName} · ${b.mode.label} · ${b.durationMinutes} min'))]);
        }),
      ]));
  }
}

class StationInsightsPage extends StatefulWidget {
  const StationInsightsPage({super.key,required this.website});
  final WebsiteRepository website;
  @override State<StationInsightsPage> createState()=>_StationInsightsPageState();
}
class _StationInsightsPageState extends State<StationInsightsPage> with LiveShopData {
  late Future<(ShopConfiguration,List<TransactionRecord>)> future=_load();
  Future<(ShopConfiguration,List<TransactionRecord>)> _load() async => (
    await widget.website.configuration(),await widget.website.transactions());
  @override Widget build(BuildContext context){
    final shop=ShopScope.of(context).snapshot;
    return RefreshIndicator(onRefresh:()async=>setState(()=>future=_load()),child:ListView(padding:const EdgeInsets.all(16),children:[
      Text('Station details',style:Theme.of(context).textTheme.headlineSmall),
      FutureBuilder<(ShopConfiguration,List<TransactionRecord>)>(future:future=refreshOnShopChange(future,_load),builder:(context,snapshot){
        if(snapshot.hasError)return const Text('Station details unavailable. Pull to retry.');
        if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
        final (config,sales)=snapshot.data!;
        final today=dateOnly(DateTime.now());
        return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          for(final station in shop?.stations??<Station>[])Card(child:ListTile(
            title:Text('${station.name} · ${station.status.label}'),
            subtitle:Text('Today: ${money(sales.where((t)=>t.stationId==station.id&&dateOnly(t.date.toLocal())==today).fold<int>(0,(sum,t)=>sum+t.total))} revenue · ${sales.where((t)=>t.stationId==station.id&&dateOnly(t.date.toLocal())==today).fold<int>(0,(sum,t)=>sum+t.durationMinutes)} min played'))),
          const SizedBox(height:16),Text('Rate card',style:Theme.of(context).textTheme.titleLarge),
          for(final e in menuRateLabels.entries)ListTile(title:Text(e.value),trailing:Text(money(config.menuRates[e.key]??0))),
        ]);
      })
    ]));
  }
}


class ReceptionDashboardPage extends StatefulWidget {
  const ReceptionDashboardPage({super.key,required this.operations,required this.website});
  final OperationsRepository operations;
  final WebsiteRepository website;
  @override State<ReceptionDashboardPage> createState()=>_ReceptionDashboardPageState();
}
class _ReceptionDashboardPageState extends State<ReceptionDashboardPage> with LiveShopData {
  late Future<(List<Booking>,List<TransactionRecord>)> future=_load();
  Future<(List<Booking>,List<TransactionRecord>)> _load() async => (
    await widget.operations.bookings(),await widget.website.transactions());
  @override Widget build(BuildContext context) {
    final shop=ShopScope.of(context).snapshot;
    return Column(children:[
      if(shop!=null)FutureBuilder<(List<Booking>,List<TransactionRecord>)>(future:future=refreshOnShopChange(future,_load),builder:(context,snapshot){
        if(!snapshot.hasData)return const SizedBox.shrink();
        final (bookings,sales)=snapshot.data!;
        final today=dateOnly(DateTime.now());
        final upcoming=bookings.where((b)=>b.date==today&&b.status=='CONFIRMED').toList()
          ..sort((a,b)=>a.startTime.compareTo(b.startTime));
        final revenue=sales.where((t)=>dateOnly(t.date.toLocal())==today).fold<int>(0,(sum,t)=>sum+t.total);
        return Padding(padding:const EdgeInsets.all(12),child:Column(children:[
          Wrap(spacing:8,children:[
            Chip(label:Text("Today's bookings: ${upcoming.length}")),
            Chip(label:Text("Today's revenue: ${money(revenue)}")),
          ]),
          for(final booking in upcoming)ListTile(dense:true,
            title:Text('${booking.startTime} · ${booking.customerName}'),
            subtitle:Text('${booking.stationName} · ${booking.mode.label}')),
        ]));
      }),
      const Expanded(child:ShopOverviewPage()),
    ]);
  }
}
