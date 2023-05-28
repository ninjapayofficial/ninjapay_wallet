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
      theme: ThemeData.light().copyWith(
        // For light theme
        scaffoldBackgroundColor: Colors.white, // Your light theme color
        textTheme: ThemeData.light().textTheme.apply(fontFamily: 'Montserrat'),
        colorScheme: ThemeData.light().colorScheme.copyWith(
              primary: Color(0xFF88a1ac),
            ), // The color of CircularProgressIndicator in light theme
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
              color: Color(0xFF000000),
              fontSize: 22,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w800), // Change color as needed
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor:
              Colors.white, // Your dark theme BottomNavigationBar color
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        // For dark theme
        scaffoldBackgroundColor: Colors.black, // Your dark theme color
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Montserrat'),
        colorScheme: ThemeData.dark().colorScheme.copyWith(
              primary: Color(
                  0xFF88a1ac), // The color of CircularProgressIndicator in dark theme
            ),
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
              color: Color(0xFFffffff),
              fontSize: 22,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w800), // Change color as needed
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor:
              Colors.black, // Your dark theme BottomNavigationBar color
        ),
      ),
      themeMode: ThemeMode
          .system, // Automatically picks between light and dark theme depending on system settings.

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
