import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

String csvCell(Object? value) => '"${(value ?? '').toString().replaceAll('"','""')}"';
String csvRows(List<List<Object?>> rows) => rows.map((row)=>row.map(csvCell).join(',')).join('\n');

Future<void> shareCsv(BuildContext context,String filename,List<List<Object?>> rows) async {
  final box=context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(ShareParams(
    files:[XFile.fromData(utf8.encode(csvRows(rows)),mimeType:'text/csv')],
    fileNameOverrides:[filename],
    sharePositionOrigin:box==null?null:box.localToGlobal(Offset.zero)&box.size,
  ));
}
Future<void> sharePdf(String filename,String title,List<List<Object?>> rows) async {
  final doc=pw.Document();
  doc.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,build:(_)=>[
    pw.Text(title,style:pw.TextStyle(fontSize:18,fontWeight:pw.FontWeight.bold)),
    pw.SizedBox(height:12),
    pw.TableHelper.fromTextArray(data:rows.map((row)=>row.map((v)=>(v??'').toString()).toList()).toList()),
  ]));
  await Printing.sharePdf(bytes:await doc.save(),filename:filename);
}
Future<void> printReceipt(String title,List<List<Object?>> rows) async {
  final doc=pw.Document();
  doc.addPage(pw.Page(pageFormat:PdfPageFormat.roll80,build:(_)=>pw.Column(
    crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
      pw.Text(title,style:pw.TextStyle(fontWeight:pw.FontWeight.bold,fontSize:14)),
      pw.SizedBox(height:8),
      for(final row in rows) pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,
        children:[pw.Text(row.first.toString()),pw.Text(row.length>1?row[1].toString():'')]),
    ])));
  await Printing.layoutPdf(onLayout:(_)=>doc.save());
}
