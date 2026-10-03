import 'package:flutter/material.dart';

import '../../data/models/operations.dart';
import '../../data/models/shop_snapshot.dart';
import '../../data/repositories/operations_repository.dart';
import '../../data/repositories/website_repository.dart';
import 'start_session_sheet.dart';

Future<bool> startBookedSession(
  BuildContext context,
  Booking booking,
  ShopSnapshot shop,
  OperationsRepository operations,
  WebsiteRepository website,
) =>
    showStartSessionSheet(context, shop, operations, website, booking: booking);
