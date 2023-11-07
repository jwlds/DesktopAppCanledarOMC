import 'package:flutter/material.dart';
import 'package:omc_sis_calendar/screens/dashboard/components/my_calendar.dart';
import 'package:omc_sis_calendar/screens/dashboard/components/my_fields.dart';
import 'package:omc_sis_calendar/responsive.dart';

import '../../constants.dart';
import 'components/header.dart';
import 'components/recent_files.dart';
import 'components/storage_details.dart';

import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:desktop_window/desktop_window.dart';
import 'dart:async';
import 'package:clean_calendar/clean_calendar.dart';

class DashboardScreen extends StatefulWidget {
  final String title;
  final String userId;
  final bool isAdmin;

  DashboardScreen({required this.title, required this.userId, required this.isAdmin});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Header(),
            SizedBox(height: defaultPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      MyFiles(),
                      SizedBox(height: defaultPadding),
                      MyCalendarWidget(userId: widget.userId),  // Fix here: Use widget.userId
                      if (Responsive.isMobile(context))
                        SizedBox(height: defaultPadding),
                      if (Responsive.isMobile(context)) StorageDetails(),
                    ],
                  ),
                ),
                if (!Responsive.isMobile(context))
                  SizedBox(width: defaultPadding),
                // On Mobile means if the screen is less than 850 we don't want to show it
                if (!Responsive.isMobile(context))
                  Expanded(
                    flex: 2,
                    child: StorageDetails(),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

