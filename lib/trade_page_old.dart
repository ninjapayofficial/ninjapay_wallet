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
