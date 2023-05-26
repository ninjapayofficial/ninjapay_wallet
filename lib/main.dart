import 'package:flutter/material.dart';
import 'package:ninjapay/home_page.dart';
import 'package:ninjapay/initial_setup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NinjaPay',
      theme: ThemeData(
        fontFamily: 'Montserrat',
        primarySwatch: Colors.cyan,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder:
            (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          final SharedPreferences? prefs = snapshot.data;
          final String? url = prefs?.getString('lnbits_url');
          final String? adminKey = prefs?.getString('lnbits_admin_key');
          final String? invoiceKey = prefs?.getString('lnbits_invoice_key');
          if (url == null ||
              adminKey == null ||
              invoiceKey == null ||
              prefs == null) {
            return FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (BuildContext context,
                  AsyncSnapshot<SharedPreferences> snapshot) {
                if (!snapshot.hasData) {
                  return CircularProgressIndicator();
                }
                return InitialSetupPage(prefs: snapshot.data!);
              },
            );
          }
          return HomePage(prefs: prefs!);
        },
      ),
    );
  }
}
