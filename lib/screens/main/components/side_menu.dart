import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:omc_sis_calendar/screens/MyResquestsScreen/my_requests_screen.dart';
import 'package:omc_sis_calendar/screens/RequestsScreen/requeste_screen.dart';

class SideMenu extends StatelessWidget {


  final String userId;
  final bool isAdmin;
  SideMenu({required this.userId, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Image.asset(
              "assets/images/logo.png",
            ),
          ),
          DrawerListTile(
            title: "Dashboard",
            svgSrc: "assets/icons/menu_dashboard.svg",
            press: () {},
          ),
          DrawerListTile(
            title: "Minhas Solicitações",
            svgSrc: "assets/icons/menu_tran.svg",
            press: () => _navigateToMyTrips(context,userId),
          ),
          if (isAdmin)
            DrawerListTile(
            title: "Solicitações (admin)",
            svgSrc: "assets/icons/menu_task.svg",
              press: () => _navigateToRequests(context,userId),
            ),
          DrawerListTile(
            title: "Sair",
            svgSrc: "assets/icons/menu_setting.svg",
            press: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}

void _navigateToRequests(BuildContext context, String userId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Requests(userId: userId,),
    ),
  );
}

void _navigateToMyTrips(BuildContext context, String userId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MyRequests(userId: userId,),
    ),
  );
}

class DrawerListTile extends StatelessWidget {
  const DrawerListTile({
    Key? key,
    required this.title,
    required this.svgSrc,
    required this.press,
  }) : super(key: key);

  final String title, svgSrc;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      horizontalTitleGap: 0.0,
      leading: SvgPicture.asset(
        svgSrc,
        colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
        height: 16,
      ),
      title: Text(
        title,
        style: TextStyle(color: Colors.white54),
      ),
    );
  }
}
