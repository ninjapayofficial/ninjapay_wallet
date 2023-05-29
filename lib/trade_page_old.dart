// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:lnbits/lnbits.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:pointycastle/export.dart' as pc;
// import 'package:pointycastle/signers/rsa_signer.dart';
// import 'package:asn1lib/asn1lib.dart';

// class TradePage extends StatefulWidget {
//   final SharedPreferences prefs;
//   final LNBitsAPI api;

//   TradePage({required this.prefs, required this.api});

//   @override
//   _TradePageState createState() => _TradePageState();
// }

// class _TradePageState extends State<TradePage> {
//   late Future _lnurlAuth;
//   String? _lnurl;
//   String? invoiceKey;

//   @override
//   void initState() {
//     super.initState();
//     invoiceKey = widget.prefs.getString('lnbits_invoice_key');
//     _lnurlAuth = _fetchLNURL();
//   }

//   Future _fetchLNURL() async {
//     var response =
//         await http.get(Uri.parse('https://api.lnmarkets.com/v1/lnurl/auth'));
//     if (response.statusCode == 200) {
//       var lnurlResponse = jsonDecode(response.body);
//       var k1 = lnurlResponse['k1'];

//       var sigAndKey = _signK1Challenge(k1);
//       return await _authenticateWithLNMarkets(
//           k1, sigAndKey['sig']!, sigAndKey['key']!);
//     } else {
//       throw Exception('Failed to load LNURL');
//     }
//   }

//   Map<String, String> _signK1Challenge(String k1) {
//     // Convert the k1 string and invoiceKey to Uint8List
//     var k1Bytes = utf8.encode(k1) as Uint8List;
//     var invoiceKeyBytes = base64.decode(invoiceKey!);

//     var signer = new pc.Signer("SHA-256/RSA");
//     var privKey =
//         pc.RSAPrivateKey.fromASN1(new ASN1Parser(invoiceKeyBytes).nextObject());
//     var privParams = new pc.RSAKeyParameters(
//         false, privKey.modulus!, privKey.privateExponent!);
//     signer.init(true, privParams);

//     var sig = signer.generateSignature(k1Bytes);
//     var sigBase64 = base64.encode(sig.bytes);

//     return {'sig': sigBase64, 'key': invoiceKey};
//   }

//   Future _authenticateWithLNMarkets(String k1, String sig, String key) async {
//     var response = await http.post(
//       Uri.parse('https://api.lnmarkets.com/v1/lnurl/auth'),
//       body: {'k1': k1, 'sig': sig, 'key': key},
//       headers: {
//         'Content-Type': 'application/json',
//       },
//     );
//     if (response.statusCode == 200) {
//       // Handle successful authentication
//     } else {
//       throw Exception('Failed to authenticate with LNMarkets');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Trade Page'),
//       ),
//       body: WebView(
//         initialUrl: 'https://lnmarkets.com', // Replace with your url
//         javascriptMode: JavascriptMode.unrestricted,
//         onWebViewCreated: (WebViewController webViewController) {
//           _controller = webViewController;
//         },
//       ),
//     );
//   }
// }
//////
//////////////////////////
// import 'package:flutter/material.dart';
// import 'package:lnbits/lnbits.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class TradePage extends StatefulWidget {
//   final SharedPreferences prefs;
//   final LNBitsAPI api;

//   TradePage({required this.prefs, required this.api});

//   @override
//   _TradePageState createState() => _TradePageState();
// }

// class _TradePageState extends State<TradePage> {
//   WebViewController? _controller;
//   String lnurl = "Your lnurl here"; // Place your lnurl here
//   String apiKey = "b86dacdf0d8a449193230ff47093d5ad"; // Place your api key here
//   String callbackUrl = "";

//   @override
//   void initState() {
//     super.initState();
//     _getCallbackUrl();
//   }

//   _getCallbackUrl() async {
//     final response = await http.get(
//       Uri.parse(
//           'https://legend.lnbits.com/api/v1/lnurlscan/$lnurl?api-key=$apiKey'),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'accept': 'application/json',
//         'X-API-KEY': apiKey,
//       },
//     );

//     if (response.statusCode == 200) {
//       var data = jsonDecode(response.body);
//       setState(() {
//         callbackUrl = data["callback"];
//       });
//       _login();
//     } else {
//       throw Exception('Failed to load callback URL');
//     }
//   }

//   _login() async {
//     final response = await http.post(
//       Uri.parse('https://legend.lnbits.com/api/v1/lnurlauth?api-key=$apiKey'),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'accept': 'application/json',
//         'X-API-KEY': apiKey,
//       },
//       body: jsonEncode(<String, String>{
//         'callback': callbackUrl,
//       }),
//     );

//     if (response.statusCode == 200) {
//       // Successfully logged in
//     } else {
//       throw Exception('Failed to log in');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: AppBar(
//       //   title: Text('Trade Page'),
//       // ),
//       body: WebView(
//         initialUrl: 'https://lnmarkets.com', // Replace with your url
//         javascriptMode: JavascriptMode.unrestricted,
//         onWebViewCreated: (WebViewController webViewController) {
//           _controller = webViewController;
//         },
//       ),
//     );
//   }
// }
 ///////////////////////////////
 ///
 ///
 ///
 ///
 ///
 ///
 ///
// import 'package:flutter/material.dart';
// import 'package:lnbits/lnbits.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class TradePage extends StatefulWidget {
//   final SharedPreferences prefs;
//   final LNBitsAPI api;

//   TradePage({required this.prefs, required this.api});

//   @override
//   _TradePageState createState() => _TradePageState();
// }

// class _TradePageState extends State<TradePage> {
//   late WebViewController _controller;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Trade Page'),
//       ),
//       body: WebView(
//         initialUrl: 'https://lnmarkets.com', // Replace with your url
//         javascriptMode: JavascriptMode.unrestricted,
//         onWebViewCreated: (WebViewController webViewController) {
//           _controller = webViewController;
//         },
//         onPageFinished: (String url) {
//           _getLNURL();
//         },
//       ),
//     );
//   }

//   void _getLNURL() async {
//     try {
//       final htmlContent =
//           await _controller.evaluateJavascript('document.body.innerHTML');
//       // Print or log the HTML content if you want to manually inspect it
//       // print(htmlContent);

//       // Try to find the LNURL in the HTML
//       final regex = RegExp(r'lnurl[0-9a-z]+', caseSensitive: false);
//       final lnurl = regex.firstMatch(htmlContent)?.group(0);

//       if (lnurl != null) {
//         print('LNURL found: $lnurl');
//       } else {
//         print('No LNURL found in the HTML');
//       }
//     } catch (e) {
//       print('Failed to get HTML content: $e');
//     }
//   }
// }
