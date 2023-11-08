import 'package:flutter/material.dart';
import 'package:omc_sis_calendar/screens/dashboard/components/my_calendar.dart';
import 'package:omc_sis_calendar/responsive.dart';

import '../../constants.dart';



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
            Header(userId: widget.userId,),
            SizedBox(height: defaultPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [

                      MyCalendarWidget(userId: widget.userId),
                      if (Responsive.isMobile(context))
                        SizedBox(height: defaultPadding),
                    ],
                  ),
                ),
                if (!Responsive.isMobile(context))
                  SizedBox(width: defaultPadding),
              ],
            )
          ],
        ),
      ),
    );
  }
}

