import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lnbits/lnbits.dart';
import 'package:ninjapay/qr_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceivePage extends StatefulWidget {
  final LNBitsAPI api;
  final SharedPreferences prefs;

  ReceivePage({required this.api, required this.prefs});
  @override
  _ReceivePageState createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  final TextEditingController _satsController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  bool _isLoading = false;

  // Future<void> _generateInvoice() async {
  //   var navigator = Navigator.of(context);

  //   // Generate invoice logic here
  //   final invoiceData = await widget.api.createInvoice(
  //       amount: int.parse(_satsController.text), memo: _memoController.text);

  //   // Once the invoice data is received, parse it to a Map<String, dynamic>
  //   Map<String, dynamic> invoiceMap = jsonDecode(invoiceData);

  //   // Map the parsed data to a PaymentRequest object
  //   final paymentRequest = PaymentRequest.fromJson(invoiceMap);

  //   // Once the PaymentRequest is generated, navigate to the QrPage:
  //   navigator.push(
  //     MaterialPageRoute(
  //         builder: (context) => QrPage(paymentRequest: paymentRequest)),
  //   );
  // }
  Future<void> _generateInvoice() async {
    setState(() {
      _isLoading = true;
    });
    var navigator = Navigator.of(context);

    // Generate invoice logic here
    final invoiceData = await widget.api.createInvoice(
        amount: int.parse(_satsController.text), memo: _memoController.text);

    // If createInvoice only returns the invoice string, pass it directly to QrPage:
    navigator.push(
      MaterialPageRoute(
          builder: (context) => QrPage(
              api: widget.api,
              prefs: widget.prefs,
              invoice: invoiceData,
              amount: int.parse(_satsController.text),
              memo: _memoController.text)),
    );
    // End loading state
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? SpinKitWave(
            color: Color(0xFF21728D),
            size: 50.0,
          )
        : Scaffold(
            appBar: AppBar(
              title: Text('Receive'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Enter amount',
                    style: TextStyle(fontSize: 24),
                  ),
                  TextField(
                    controller: _satsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter sats',
                    ),
                  ),
                  TextField(
                    controller: _memoController,
                    decoration: InputDecoration(
                      labelText: 'Enter memo',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _generateInvoice,
                    child: Text('Generate Invoice'),
                  ),
                ],
              ),
            ),
          );
  }
}

class PaymentRequest {
  final String paymentRequest;
  final String paymentHash;
  final int amount;
  final String memo;

  PaymentRequest({
    required this.paymentRequest,
    required this.paymentHash,
    required this.amount,
    required this.memo,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      paymentRequest: json['payment_request'],
      paymentHash: json['payment_hash'],
      amount: json['amount'],
      memo: json['memo'],
    );
  }
}
////
///
///
///
///
// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:lnbits/lnbits.dart';
// import 'package:ninjapay/qr_page.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class ReceivePage extends StatefulWidget {
//   final LNBitsAPI api;
//   final SharedPreferences prefs;

//   ReceivePage({required this.api, required this.prefs});
//   @override
//   _ReceivePageState createState() => _ReceivePageState();
// }

// class _ReceivePageState extends State<ReceivePage> {
//   final TextEditingController _satsController = TextEditingController();
//   final TextEditingController _memoController = TextEditingController();

//   // Future<void> _generateInvoice() async {
//   //   var navigator = Navigator.of(context);

//   //   // Generate invoice logic here
//   //   final invoiceData = await widget.api.createInvoice(
//   //       amount: int.parse(_satsController.text), memo: _memoController.text);

//   //   // Once the invoice data is received, parse it to a Map<String, dynamic>
//   //   Map<String, dynamic> invoiceMap = jsonDecode(invoiceData);

//   //   // Map the parsed data to a PaymentRequest object
//   //   final paymentRequest = PaymentRequest.fromJson(invoiceMap);

//   //   // Once the PaymentRequest is generated, navigate to the QrPage:
//   //   navigator.push(
//   //     MaterialPageRoute(
//   //         builder: (context) => QrPage(paymentRequest: paymentRequest)),
//   //   );
//   // }

//   // Future<void> _generateInvoice() async {
//   //   var navigator = Navigator.of(context);

//   //   // Generate invoice logic here
//   //   final invoiceData = await widget.api.createInvoice(
//   //       amount: int.parse(_satsController.text), memo: _memoController.text);

//   //   // If createInvoice only returns the invoice string, pass it directly to QrPage:
//   //   navigator.push(
//   //     MaterialPageRoute(builder: (context) => QrPage(invoice: invoiceData)),
//   //   );
//   // }

//   Future<void> _generateInvoice() async {
//     var navigator = Navigator.of(context);

//     // Generate invoice logic here
//     final invoiceData = await widget.api.createInvoice(
//         amount: int.parse(_satsController.text), memo: _memoController.text);

//     // Once the Invoice is generated, navigate to the QrPage:
//     navigator.push(
//       MaterialPageRoute(
//           builder: (context) => QrPage(
//               invoice: invoiceData,
//               amount: int.parse(_satsController.text),
//               memo: _memoController.text)),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Receive'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Text(
//               '0 sats',
//               style: TextStyle(fontSize: 24),
//             ),
//             TextField(
//               controller: _satsController,
//               keyboardType: TextInputType.number,
//               decoration: InputDecoration(
//                 labelText: 'Enter sats',
//               ),
//             ),
//             TextField(
//               controller: _memoController,
//               decoration: InputDecoration(
//                 labelText: 'Enter memo',
//               ),
//             ),
//             ElevatedButton(
//               onPressed: _generateInvoice,
//               child: Text('Generate Invoice'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }