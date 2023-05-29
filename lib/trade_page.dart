import 'package:flutter/material.dart';
import 'package:lnbits/lnbits.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TradePage extends StatefulWidget {
  final SharedPreferences prefs;
  final LNBitsAPI api;

  TradePage({required this.prefs, required this.api});

  @override
  _TradePageState createState() => _TradePageState();
}

class _TradePageState extends State<TradePage> {
  WebViewController? _controller;
  String lnurl = "Your lnurl here"; // Place your lnurl here
  String apiKey = "b86dacdf0d8a449193230ff47093d5ad"; // Place your api key here
  String callbackUrl = "";

  @override
  void initState() {
    super.initState();
    _getCallbackUrl();
  }

  _getCallbackUrl() async {
    final response = await http.get(
      Uri.parse(
          'https://legend.lnbits.com/api/v1/lnurlscan/$lnurl?api-key=$apiKey'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'accept': 'application/json',
        'X-API-KEY': apiKey,
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        callbackUrl = data["callback"];
      });
      _login();
    } else {
      throw Exception('Failed to load callback URL');
    }
  }

  _login() async {
    final response = await http.post(
      Uri.parse('https://legend.lnbits.com/api/v1/lnurlauth?api-key=$apiKey'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'accept': 'application/json',
        'X-API-KEY': apiKey,
      },
      body: jsonEncode(<String, String>{
        'callback': callbackUrl,
      }),
    );

    if (response.statusCode == 200) {
      // Successfully logged in
    } else {
      throw Exception('Failed to log in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Trade Page'),
      // ),
      body: WebView(
        initialUrl: 'https://lnmarkets.com', // Replace with your url
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller = webViewController;
        },
      ),
    );
  }
}
