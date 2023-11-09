import 'package:flutter/material.dart';
import 'package:omc_sis_calendar/database/mongo_connect.dart';
import 'package:omc_sis_calendar/screens/main/main_screen.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:omc_sis_calendar/controllers/MenuAppController.dart';
import 'package:omc_sis_calendar/responsive.dart';
import 'package:omc_sis_calendar/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController usernameController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width / 2,
            color: Colors.blue[900],
            child: const Center(
              child: Text(
                'OMC Group',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width / 2,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: usernameController,
                    style: TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Login',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    String login = usernameController.text;
                    String password = passwordController.text;

                    var db = await mongo.Db.create(
                        'mongodb+srv://josewlds:omcapps@cluster0.bnxdvmv.mongodb.net/omcapps?retryWrites=true&w=majority');
                    await db.open();

                    var user = await db.collection('users').findOne(
                        mongo.where.eq('login', login).eq('password', password));

                    if (user != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider<MenuAppController>(
                            create: (context) => MenuAppController(),
                            child: MainScreen(
                              title: 'OMC Group',
                              userId: user['_id'].$oid.toString(),
                              isAdmin: user['admin'] ?? false,
                            ),
                          ),
                        ),
                      );

                    } else {
                      print('Login failed. Please check your credentials.');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue[900],
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text('Entrar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}