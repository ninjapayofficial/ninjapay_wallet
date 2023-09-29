import 'dart:convert';
import 'package:secp256k1/secp256k1.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:lnbits/lnbits.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class TradePage extends StatefulWidget {
  final SharedPreferences prefs;
  final LNBitsAPI api;

  const TradePage({super.key, required this.prefs, required this.api});

  @override
  _TradePageState createState() => _TradePageState();
}

class _TradePageState extends State<TradePage> {
  late WebViewController _controller;
  late String lnbitsInvoiceKey;
  late String lnbitsAdminKey;
  late String url;

  @override
  void initState() {
    super.initState();
    url = widget.prefs.getString('lnbits_url') ?? '';
    lnbitsInvoiceKey = widget.prefs.getString('lnbits_invoice_key') ?? '';
    lnbitsAdminKey = widget.prefs.getString('lnbits_admin_key') ?? '';
    // print('Init URL: $url');
    // print('Init Invoice Key: $lnbitsInvoiceKey');
    // print('Init Admin Key: $lnbitsAdminKey');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        javascriptMode: JavascriptMode.unrestricted,
        initialUrl: 'https://pro.kollider.xyz/',
        debuggingEnabled: true,
        onWebViewCreated: (WebViewController webViewController) {
          _controller = webViewController;
        },
        onPageFinished: (String url) {
          _injectWebLNProvider();
          _addListenerForLnurlClicks();
        },
        javascriptChannels: {
          JavascriptChannel(
            name: 'weblnSignMessage',
            onMessageReceived: (JavascriptMessage message) {
              _signMessage(message.message);
            },
          ),
          JavascriptChannel(
            name: 'weblnSendPayment',
            onMessageReceived: (JavascriptMessage message) {
              _sendPayment(message.message);
            },
          ),
          JavascriptChannel(
            name: 'weblnMakeInvoice',
            onMessageReceived: (JavascriptMessage message) {
              _makeInvoice(message.message);
            },
          ),
          JavascriptChannel(
            name: 'lnurlClickHandler',
            onMessageReceived: (JavascriptMessage message) {
              _handleLnurlClick(message.message);
            },
          ),
          JavascriptChannel(
            name: 'consoleLog',
            onMessageReceived: (JavascriptMessage message) {
              print(message.message);
            },
          ),
        }.toSet(),
      ),
    );
  }

  // void _injectWebLNProvider() async {
  //   await _controller.runJavascript("""
  //     window.webln = {
  //       enable: function() {
  //         return Promise.resolve();
  //       },
  //       sendPayment: function(paymentRequest) {
  //         window.weblnSendPayment.postMessage(paymentRequest);
  //       },
  //       makeInvoice: function(invoiceRequest) {
  //         window.weblnMakeInvoice.postMessage(invoiceRequest);
  //       },
  //       signMessage: function(message) {
  //         window.weblnSignMessage.postMessage(message);
  //       },
  //     };
  //   """);
  // }

  void _injectWebLNProvider() async {
    await _controller.runJavascript("""
      window.webln = {
        enable: function() {
          return Promise.resolve();
        },
        sendPayment: function(paymentRequest) {
          return new Promise((resolve, reject) => {
            window.weblnSendPayment.postMessage(paymentRequest);
            window.weblnSendPayment.onmessage = (event) => {
              if (event.data.error) {
                reject(event.data.error);
              } else {
                resolve(event.data.result);
              }
            };
          });
        },
        makeInvoice: function(invoiceRequest) {
          console.log = function(message) {
            consoleLog.postMessage(message);
          };
          console.log('makeInvoice called with request:', invoiceRequest);
          return new Promise((resolve, reject) => {
            console.log('Sending message to weblnMakeInvoice...');
            window.weblnMakeInvoice.postMessage(invoiceRequest);
            window.weblnMakeInvoice.onmessage = (event) => {
              console.log('Received message from weblnMakeInvoice:', event.data);
              if (event.data.error) {
                console.log('Rejecting Promise due to error:', event.data.error);
                reject(event.data.error);
              } else {
                console.log('Resolving Promise with result:', event.data.result);
                resolve(event.data.result);
              }
            };
          });
        },
        signMessage: function(message) {
          return new Promise((resolve, reject) => {
            window.weblnSignMessage.postMessage(message);
            window.weblnSignMessage.onmessage = (event) => {
              if (event.data.error) {
                reject(event.data.error);
              } else {
                resolve(event.data.result);
              }
            };
          });
        },
      };
    """);
  }

  void _addListenerForLnurlClicks() async {
    await _controller.runJavascript("""
      document.addEventListener('click', function(event) {
        var element = event.target;
        while (element && element.tagName !== 'A') {
          element = element.parentElement;
        }
        if (element && element.href.startsWith('lightning:')) {
          window.lnurlClickHandler.postMessage(element.href);
          event.preventDefault();
        }
      });
    """);
  }

  // void _sendPayment(String paymentRequest) async {
  //   // This method sends a payment to the provided invoice
  //   // Use the LNBits API to pay the invoice
  //   var paymentResponse = await widget.api.payInvoice(bolt11: paymentRequest);
  //   // Check the payment status
  //   final isPaid = await widget.api.checkInvoice(paymentHash: paymentResponse);
  //   if (isPaid) {
  //     print('Payment successful');
  //   } else {
  //     print('Payment error');
  //   }
  // }

  void _sendPayment(String paymentRequest) async {
    var paymentResponse = await widget.api.payInvoice(bolt11: paymentRequest);

    // Check the payment status
    final isPaid = await widget.api.checkInvoice(paymentHash: paymentResponse);
    if (isPaid) {
      print('Payment successful');
      // Inform the webpage about the successful payment
      await _controller.runJavascript(
        'window.postMessage(${jsonEncode(paymentResponse)}, "*");',
      );
    } else {
      print('Payment error');
      // Optionally, inform the webpage about the payment error
    }
  }

  void _makeInvoice(String invoiceRequestJson) async {
    var args = jsonDecode(invoiceRequestJson);
    print('Received data: $invoiceRequestJson');
    if (invoiceRequestJson == null || invoiceRequestJson == 'undefined') {
      print('Invalid JSON data');
      return;
    }
    try {
      var args = jsonDecode(invoiceRequestJson);
      print('Debug: _makeInvoice called with: $invoiceRequestJson');

      Map<String, dynamic> invoiceRequest = jsonDecode(invoiceRequestJson);
      var amount = invoiceRequest['amount'] ?? invoiceRequest['defaultAmount'];
      var memo = invoiceRequest['defaultMemo'];

      print('Debug: Parsed amount: $amount');
      print('Debug: Parsed memo: $memo');

      if (amount != null && memo != null) {
        var invoiceResponse =
            await widget.api.createInvoice(amount: amount, memo: memo);

        String resultJson = jsonEncode({
          'paymentRequest': invoiceResponse,
        });

        print('Debug: Created invoice: $resultJson');

        _controller.runJavascript(
          'window.postMessage($resultJson, "*");',
        );

        _controller.runJavascript(
            'window.weblnMakeInvoice.onmessage({ data: \'$resultJson\' })');
      }
    } catch (e) {
      // handle or log error
      print('Error while parsing json: $e');
    }
  }

  // void _makeInvoice(String invoiceRequest) async {
  //   print('Debug: _makeInvoice called with: $invoiceRequest');

  //   var amount = int.tryParse(
  //       invoiceRequest); // Adjust this based on the format of invoiceRequest
  //   print('Debug: Parsed amount: $amount');

  //   if (amount != null) {
  //     var invoiceResponse = await widget.api.createInvoice(
  //         amount: amount ?? 1000,
  //         memo: 'Kollider Withdraw'); // Adjust description as needed

  //     // Then convert the result into a JSON string and pass it back to the webpage
  //     String resultJson = jsonEncode({
  //       'invoice': invoiceResponse,
  //     });

  //     print('Debug: Created invoice: $resultJson');

  //     // Pass the result back to JavaScript
  //     _controller.runJavascript(
  //         'window.weblnMakeInvoice.onmessage({ data: $resultJson })');
  //   }
  // }

  // void _makeInvoice(String invoiceRequest) async {
  //   var amount = int.tryParse(
  //       invoiceRequest); // Adjust this based on the format of invoiceRequest

  //   String resultJson;

  //   if (amount != null) {
  //     var invoiceResponse = await widget.api.createInvoice(
  //         amount: amount,
  //         memo: 'Kollider Withdraw'); // Adjust description as needed

  //     // Then convert the result into a JSON string and pass it back to the webpage
  //     resultJson = jsonEncode({
  //       'invoice': invoiceResponse,
  //     });
  //   } else {
  //     resultJson = jsonEncode({
  //       'error': 'Invalid amount: $invoiceRequest',
  //     });
  //   }

  //   _controller.runJavascript('webln.makeInvoice.resolve($resultJson)');
  // }

  // void _makeInvoice(String invoiceRequest) async {
  //   // This method creates a new invoice with the requested amount
  //   // Parse the requested amount from the invoiceRequest
  //   var amount = int.tryParse(
  //       invoiceRequest); // Adjust this based on the format of invoiceRequest
  //   if (amount != null) {
  //     var invoiceResponse = await widget.api.createInvoice(
  //         amount: amount,
  //         memo: 'Kollider Withdraw'); // Adjust description as needed
  //   }
  // }

  // void _makeInvoice(String invoiceRequest) async {
  //   var args = jsonDecode(invoiceRequest);
  //   var amount = args['amount'] ?? '1000'; // Default amount if not provided

  //   var invoiceResponse = await widget.api
  //       .createInvoice(amount: amount, memo: 'Kollider Withdraw');

  //   // Inform the webpage about the created invoice
  //   await _controller.runJavascript(
  //     'window.postMessage(${jsonEncode(invoiceResponse)}, "*");',
  //   );
  // }

  void _handleLnurlClick(String lnurl) async {
    // Extract the LNURL from the "lightning:" URI
    lnurl = lnurl.substring(10); // remove 'lightning:' prefix

    // Fetch the LNURL-auth callback from LNBits
    http.Response response = await http.get(
      Uri.parse('$url/api/v1/lnurlscan/$lnurl?api-key=$lnbitsAdminKey'),
      headers: <String, String>{
        'accept': 'application/json',
        'X-API-KEY': lnbitsAdminKey,
      },
    );
    // print('LNURL ${lnurl}');
    // print('LNURL-auth callback response: ${response.body}');
    if (response.statusCode == 200) {
      // Parse the callback URL from the response
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      String callback = responseBody['callback'];

      // POST to LNBits to perform the login
      http.Response authResponse = await http.post(
        Uri.parse('$url/api/v1/lnurlauth?api-key=$lnbitsAdminKey'),
        headers: <String, String>{
          'accept': 'application/json',
          'X-API-KEY': lnbitsAdminKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'callback': callback,
        }),
      );

      if (authResponse.statusCode == 200) {
        // Login was successful, refresh the webpage
        _controller.loadUrl('https://pro.kollider.xyz/');
      } else {
        // Handle error
        print('Error logging in: ${authResponse.statusCode}');
      }
    } else {
      // Handle error
      print('Error fetching LNURL-auth callback: ${response.statusCode}');
    }
  }

  void _signMessage(String message) async {
    // Use the package to sign the message
    var privateKey = crypto.PrivateKey.fromHex(lnbitsInvoiceKey);
    var sig = privateKey.signature(message);
    print('Signature: ${sig.toHexes()}');
    // Inform the webpage about the signature
    await _controller.runJavascript(
      'window.postMessage(${jsonEncode(sig)}, "*");',
    );

    ///
//       void _signMessage(String message) async {
//     var signature = await widget.api.signMessage(message: message);

//     // Inform the webpage about the signature
//     await _controller.runJavascript(
//       'window.postMessage(${jsonEncode(signature)}, "*");',
//     );
//   }
// }

    // TODO: Send the signature back to the webpage
    // You will need to implement this part based on how your webpage expects to receive the signature
  }
}
