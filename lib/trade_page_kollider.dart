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
//   String? jwt;
//   late String lnbitsApiKey;

//   Future<String> _getPublicKey() async {
//     String privateKeyHex = widget.prefs.getString('lnbits_invoice_key') ?? '';
//     var privateKey = crypto.PrivateKey.fromHex(privateKeyHex);
//     var publicKey = privateKey.publicKey;
//     return publicKey.toHex();
//     // Assuming you need a compressed public key.
//   }

//   Future<void> _handleLNUrlAuth() async {
//     String publicKey = await _getPublicKey();

//     // Step 1: Get LNURL from Kollider
//     var kolliderResponse = await http.get(
//       Uri.parse('https://api.kollider.xyz/v1/auth/external/lnurl_auth'),
//       headers: {
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Authorization': 'Bearer ${lnbitsApiKey}',
//       },
//     );

//     if (kolliderResponse.statusCode != 200) {
//       throw Exception('Failed to fetch LNURL from Kollider');
//     }

//     String lnUrl = json.decode(kolliderResponse.body)['lnurl'];

//     // Step 2: Pass LNURL to LNBits to get callback URL and k1 parameter
//     var lnbitsResponse = await http.get(
//       Uri.parse(
//           'https://legend.lnbits.com/api/v1/lnurlscan/$lnUrl?api-key=${lnbitsApiKey}'),
//     );

//     if (lnbitsResponse.statusCode != 200) {
//       throw Exception('Failed to fetch LNURL details from LNBits');
//     }

//     Map<String, dynamic> decoded = json.decode(lnbitsResponse.body);
//     String callback = decoded['callback'];
//     String k1 = decoded['k1'];

//     // Step 3: Sign the k1 using the wallet's private key
//     var privateKey = crypto.PrivateKey.fromHex(
//         widget.prefs.getString('lnbits_invoice_key') ?? '');
//     Uint8List k1Bytes = hexStringToBytes(k1);
//     var signedK1 = privateKey.signature(k1Bytes as String).toHexes();

//     // Step 4: Make a POST request to the callback URL with the signed k1
//     var authCallbackResponse = await http.post(
//       Uri.parse(callback),
//       headers: {'Content-Type': 'application/x-www-form-urlencoded'},
//       body: {
//         'sig': signedK1,
//         'key': publicKey,
//       },
//     );

//     if (authCallbackResponse.statusCode != 200) {
//       throw Exception('Failed to authenticate with LN service');
//     }

//     jwt = json.decode(authCallbackResponse.body)['jwt'];
//   }

//   @override
//   void initState() {
//     super.initState();
//     lnbitsApiKey = widget.prefs.getString('lnbits_api_key') ?? '';
//     _handleLNUrlAuth().then((_) {
//       print('Received JWT: $jwt');
//       if (jwt != null) {
//         _controller.loadUrl('https://pro.kollider.xyz/?token=$jwt');
//       }
//     }).catchError((error) {
//       print('Error getting JWT: $error');
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
//         initialUrl: 'https://pro.kollider.xyz/',
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

//   Uint8List hexStringToBytes(String hex) {
//     return Uint8List.fromList(
//       Iterable<int>.generate(
//         hex.length ~/ 2,
//         (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
//       ).toList(),
//     );
//   }
// }
////////////////////
///
///
///
///
///
///
///
///
///
///
///
///
///
///
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
//   late String lnbitsInvoiceKey;

//   @override
//   void initState() {
//     super.initState();
//     lnbitsInvoiceKey = widget.prefs.getString('lnbits_invoice_key') ?? '';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: WebView(
//         javascriptMode: JavascriptMode.unrestricted,
//         initialUrl: 'https://pro.kollider.xyz/',
//         debuggingEnabled: true,
//         onWebViewCreated: (WebViewController webViewController) {
//           _controller = webViewController;
//         },
//         onPageFinished: (String url) {
//           _injectWebLNProvider();
//         },
//         javascriptChannels: {
//           JavascriptChannel(
//             name: 'weblnSignMessage',
//             onMessageReceived: (JavascriptMessage message) {
//               _signMessage(message.message);
//             },
//           ),
//           // Add other channels as needed
//         }.toSet(),
//       ),
//     );
//   }

//   void _injectWebLNProvider() async {
//     await _controller.evaluateJavascript("""
//       window.webln = {
//         enable: function() {
//           return Promise.resolve();
//         },
//         sendPayment: function(paymentRequest) {
//           // Implement sendPayment functionality as needed
//         },
//         makeInvoice: function(invoiceRequest) {
//           // Implement makeInvoice functionality as needed
//         },
//         signMessage: function(message) {
//           return window.weblnSignMessage.postMessage(message);
//         },
//       };
//     """);
//   }

//   void _signMessage(String message) {
//     // Use the package to sign the message
//     var privateKey = crypto.PrivateKey.fromHex(lnbitsInvoiceKey);
//     var sig = privateKey
//         .signature(Uint8List.fromList(utf8.encode(message)) as String);
//     print('Signature: ${sig.toHexes()}');

//     // TODO: Send the signature back to the webpage
//     // You will need to implement this part based on how your webpage expects to receive the signature
//   }
// }
