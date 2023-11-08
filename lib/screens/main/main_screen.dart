import 'package:omc_sis_calendar/controllers/MenuAppController.dart';
import 'package:omc_sis_calendar/responsive.dart';
import 'package:omc_sis_calendar/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/side_menu.dart';

class MainScreen extends StatelessWidget {
  final String title;
  final String userId;
  final bool isAdmin;

  MainScreen({required this.title, required this.userId, required this.isAdmin});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: context.read<MenuAppController>().scaffoldKey,
      drawer: SideMenu(userId: userId, isAdmin: isAdmin),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (Responsive.isDesktop(context))
              Expanded(

                child: SideMenu(userId: userId,isAdmin: isAdmin),
              ),
            Expanded(

              flex: 5,
              child:  DashboardScreen(
                title: title,
                userId: userId,
                isAdmin: isAdmin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
