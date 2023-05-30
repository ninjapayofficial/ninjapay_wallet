// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:secp256k1/secp256k1.dart' as crypto;
// import 'package:flutter/material.dart';
// import 'package:lnbits/lnbits.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:http/http.dart' as http;

// class TradePage extends StatefulWidget {
//   final SharedPreferences prefs;
//   final LNBitsAPI api;

//   TradePage({required this.prefs, required this.api});

//   @override
//   _TradePageState createState() => _TradePageState();
// }

// class _TradePageState extends State<TradePage> {
//   late WebViewController _controller;

//   Future<String> _getPublicKey() async {
//     String privateKeyHex = widget.prefs.getString('lnbits_invoice_key') ?? '';
//     var privateKey = crypto.PrivateKey.fromHex(privateKeyHex);
//     var publicKey = privateKey.publicKey;
//     return publicKey.toHex();
//     // Assuming you need a compressed public key.
//   }

//   Future<String> _getLNURLFromLNMarkets(String publicKey) async {
//     var response = await http.post(
//       Uri.parse('https://api.lnmarkets.com/v1/lnurl/auth'),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//       },
//       body: jsonEncode(<String, String>{
//         'publicKey': publicKey,
//       }),
//     );

//     if (response.statusCode == 200) {
//       Map<String, dynamic> responseJson = json.decode(response.body);
//       return responseJson['lnurl'] as String;
//     } else {
//       throw Exception('Failed to load LNURL');
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _getPublicKey().then((publicKey) {
//       _getLNURLFromLNMarkets(publicKey).then((lnurl) {
//         print('Received LNURL: $lnurl');
//         // Use your LNBitsAPI instance to login with the lnurl.
//         // The API method depends on the specific implementation of LNBitsAPI.
//       }).catchError((error) {
//         print('Error getting LNURL: $error');
//       });
//     }).catchError((error) {
//       print('Error deriving public key: $error');
//     });
//   }

//   void _injectWebLNProvider() async {
//     await _controller.runJavascript("""
//     window.webln = {
//       enable: function() {
//         return window.flutter_inappwebview.callHandler('enable');
//       },
//       sendPayment: function(paymentRequest) {
//         return window.flutter_inappwebview.callHandler('sendPayment', paymentRequest);
//       },
//       makeInvoice: function(invoiceRequest) {
//         return window.flutter_inappwebview.callHandler('makeInvoice', invoiceRequest);
//       },
//       signMessage: function(message) {
//         return window.flutter_inappwebview.callHandler('signMessage', message);
//       },
//     }
//   """);

//     // Reload the webpage after injecting WebLN JavaScript code
//     if (_controller != null) {
//       _controller.reload();
//     }
//   }

//   void _checkWebLNEnabled() async {
//     var result = await _controller.evaluateJavascript("window.webln");
//     print(result);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: WebView(
//         javascriptMode: JavascriptMode.unrestricted,
//         initialUrl: 'https://lnmarkets.com',
//         debuggingEnabled: true,
//         onWebViewCreated: (WebViewController webViewController) {
//           _controller = webViewController;
//         },
//         onPageFinished: (String url) {
//           _injectWebLNProvider();
//           _checkWebLNEnabled();
//         },
//         javascriptChannels: {
//           JavascriptChannel(
//             name: 'signMessage',
//             onMessageReceived: (JavascriptMessage message) {
//               print('Sign message channel message: ${message.message}');
//               _signMessage(message.message);
//             },
//           ),
//           // other channels here
//         }.toSet(),
//       ),
//     );
//   }

//   void _signMessage(String message) {
//     // Use the package to sign the message
//     String privateKey = widget.prefs.getString('lnbits_invoice_key') ?? '';
//     var pk = crypto.PrivateKey.fromHex(privateKey);
//     var sig = pk.signature(message);
//     print('lnbits_invoice_key');

//     // The sig object now holds the signature
//     print('Signature: ${sig.toHexes()}');
//   }
// }
