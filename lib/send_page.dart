import 'package:flutter/material.dart';
import 'package:lnbits/lnbits.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'invoice_page.dart';
import 'package:flutter/services.dart';

class SendPage extends StatefulWidget {
  final LNBitsAPI api;
  final SharedPreferences prefs;

  SendPage({required this.api, required this.prefs});

  @override
  _SendPageState createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Color(0x00ffffff),
      //   shadowColor: Color(0x00ffffff),
      //   title: Text(
      //     'Send Payment',
      //     style: TextStyle(color: Colors.white),
      //   ),
      // ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Scan a QR Code',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              ClipboardData? clipboardData =
                  await Clipboard.getData('text/plain');
              String? invoice = clipboardData?.text;
              if (invoice != null && invoice.isNotEmpty) {
                _handleInvoice(invoice);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No invoice found on the clipboard!')),
                );
              }
            },
            child: Text('Paste Invoice'),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        this.result = scanData;
        if (result != null && result!.code != null) {
          _handleInvoice(result!.code!);
        }
      });
    });
  }

  void _handleInvoice(String invoice) async {
    try {
      // Pause scanning
      controller?.pauseCamera();

      // Decode the invoice
      final decodedInvoice = await widget.api.decodeInvoice(invoice: invoice);

      // Show decoded invoice details and the 'Swipe to send' button
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoicePage(
              api: widget.api,
              invoice: invoice,
              decodedInvoice: decodedInvoice,
              prefs: widget.prefs),
        ),
      ).then((value) {
        // Continue scanning after returning from the InvoicePage
        controller?.resumeCamera();
      });
    } catch (e) {
      // Handle invalid invoices: show an error dialog or Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid invoice!')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
