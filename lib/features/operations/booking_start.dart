import 'package:flutter/material.dart';

import '../../data/models/operations.dart';
import '../../data/models/shop_snapshot.dart';
import '../../data/models/website_models.dart';
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
  final catalog=games.isEmpty?defaultGames:games;
  final name=TextEditingController(text:booking.customerName);
  final phone=TextEditingController(text:booking.customerPhone);
  final game=TextEditingController(),notes=TextEditingController(),snackName=TextEditingController(),snackPrice=TextEditingController();
  final snacks=<Snack>[];
  var players=booking.players??1;
  int? reminderMinutes;
  final started=await showDialog<bool>(context:context,builder:(dialog)=>StatefulBuilder(builder:(context,setDialog)=>AlertDialog(
    title:Text('Start booking · ${station.name}'),content:SizedBox(width:400,child:SingleChildScrollView(child:Column(
      mainAxisSize:MainAxisSize.min,children:[
        field(name,'Customer'),field(phone,'Phone'),
        if(booking.mode==SessionMode.gaming)DropdownButton<int>(value:players,items:[
          for(var n=1;n<=4;n++)DropdownMenuItem(value:n,child:Text('$n players'))],
          onChanged:(v)=>setDialog(()=>players=v!)),
        DropdownButton<String?>(value:game.text.isEmpty?null:game.text,
          hint:const Text('Select game'),items:[for(final g in gamesForSessionMode(booking.mode.value,catalog))DropdownMenuItem(value:g,child:Text(g))],
          onChanged:(v)=>setDialog(()=>game.text=v??'')),
        field(game,'Game title'),
        const Text('Session Duration · reminder only'),
        Wrap(spacing:8,children:[for(final choice in [30,60,120])
          ChoiceChip(label:Text(choice==60?'1 Hour':choice==120?'2 Hours':'30 Minutes'),
            selected:reminderMinutes==choice,
            onSelected:(_)=>setDialog(()=>reminderMinutes=choice))]),
        for(final snack in snacks)ListTile(title:Text(snack.name),subtitle:Text(money(snack.price)),
          trailing:IconButton(tooltip:'Remove snack',icon:const Icon(Icons.close),
            onPressed:()=>setDialog(()=>snacks.remove(snack)))),
        field(snackName,'Snack (optional)'),field(snackPrice,'Snack price',keyboard:TextInputType.number),
        TextButton(onPressed:(){if(snackName.text.trim().isEmpty||parsed(snackPrice)<=0)return;
          setDialog((){snacks.add(Snack(snackName.text.trim(),parsed(snackPrice)));snackName.clear();snackPrice.clear();});
        },child:const Text('Add snack')),
        field(notes,'Notes (optional)'),
        Text('Advance already recorded: ${money(booking.advanceAmount)}'),
      ]))),actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:const Text('Cancel')),
      FilledButton(onPressed:()async{
        final minutes=reminderMinutes;
        if(minutes==null || name.text.trim().isEmpty){notice(dialog,'Enter customer and choose a session duration.');return;}
        final rate=config.fallbackRate(booking.mode.value,players);
        await runAction(dialog,()async{
          await operations.start(SessionDraft(station:station,customerName:name.text,phone:phone.text,
            mode:booking.mode,minutes:minutes,players:players,game:game.text,notes:notes.text,
            playAmount:0,ratePerHour:rate,snacks:snacks),shop.controllersFree);
          try {await operations.completeBooking(booking.id);}
          catch (_) {if(dialog.mounted)notice(dialog,'Session started. Booking status needs manual review.');}
          if(dialog.mounted)Navigator.pop(dialog,true);
        });
      },child:const Text('Start session'))])));
  return started??false;
}
