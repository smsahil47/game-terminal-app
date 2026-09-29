import 'package:flutter/material.dart';

import '../../core/billing/billing.dart';
import '../../data/models/operations.dart';
import '../../data/models/shop_snapshot.dart';
import '../../data/repositories/operations_repository.dart';
import '../../data/repositories/website_repository.dart';
import '../operations/operations_pages.dart' show field,parsed,notice,runAction,money;

Future<bool> startBookedSession(BuildContext context, Booking booking, ShopSnapshot shop,
    OperationsRepository operations, WebsiteRepository website) async {
  final station=shop.stations.where((s)=>s.id==booking.stationId).firstOrNull;
  if(station==null || station.status!=StationStatus.available){
    notice(context,'The booked station is not available.');return false;
  }
  if(station.type!='PS5_MULTI' && booking.mode!=SessionMode.gaming){
    notice(context,'This station supports Gaming only.');return false;
  }
  final config=await website.configuration();
  final games=await operations.games();
  if(!context.mounted)return false;
  final name=TextEditingController(text:booking.customerName);
  final phone=TextEditingController(text:booking.customerPhone);
  final duration=TextEditingController(text:'${booking.durationMinutes}');
  final game=TextEditingController(),snackName=TextEditingController(),snackPrice=TextEditingController();
  final snacks=<Snack>[];
  var players=booking.players??1;
  final started=await showDialog<bool>(context:context,builder:(dialog)=>StatefulBuilder(builder:(context,setDialog)=>AlertDialog(
    title:Text('Start booking · ${station.name}'),content:SizedBox(width:400,child:SingleChildScrollView(child:Column(
      mainAxisSize:MainAxisSize.min,children:[
        field(name,'Customer'),field(phone,'Phone'),
        if(booking.mode==SessionMode.gaming)DropdownButton<int>(value:players,items:[
          for(var n=1;n<=4;n++)DropdownMenuItem(value:n,child:Text('$n players'))],
          onChanged:(v)=>setDialog(()=>players=v!)),
        if(games.isNotEmpty)DropdownButton<String?>(value:game.text.isEmpty?null:game.text,
          hint:const Text('Select game'),items:[for(final g in games)DropdownMenuItem(value:g,child:Text(g))],
          onChanged:(v)=>setDialog(()=>game.text=v??'')),
        field(game,'Game title'),
        field(duration,'Duration minutes',keyboard:TextInputType.number),
        for(final snack in snacks)ListTile(title:Text(snack.name),trailing:Text(money(snack.price))),
        field(snackName,'Snack (optional)'),field(snackPrice,'Snack price',keyboard:TextInputType.number),
        TextButton(onPressed:(){if(snackName.text.trim().isEmpty||parsed(snackPrice)<=0)return;
          setDialog((){snacks.add(Snack(snackName.text.trim(),parsed(snackPrice)));snackName.clear();snackPrice.clear();});
        },child:const Text('Add snack')),
        Text('Advance already recorded: ${money(booking.advanceAmount)}'),
      ]))),actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('Cancel')),
      FilledButton(onPressed:()async{
        final minutes=parsed(duration);
        if(minutes<=0 || name.text.trim().isEmpty){notice(dialog,'Enter customer and duration.');return;}
        final rate=config.fallbackRate(booking.mode.value,players);
        final amount=menuPlayAmount(booking.mode,minutes,players,rate,rates:config.menuRates);
        await runAction(dialog,()async{
          await operations.start(SessionDraft(station:station,customerName:name.text,phone:phone.text,
            mode:booking.mode,minutes:minutes,players:players,game:game.text,playAmount:amount,ratePerHour:rate,snacks:snacks),shop.controllersFree);
          try {await operations.completeBooking(booking.id);}
          catch (_) {if(dialog.mounted)notice(dialog,'Session started. Booking status needs manual review.');}
          if(dialog.mounted)Navigator.pop(dialog,true);
        });
      },child:const Text('Start session'))])));
  return started??false;
}
