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
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Container(
              padding: EdgeInsets.only(left: 4, right: 4, bottom: 2, top: 2),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                border: Border.all(color: Color(0xFF21728D), width: 4),
              ),
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'Scan Qr or Paste invoice',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF88a1ac),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            // padding: EdgeInsets.only(left: 20, right: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(100)),
              border: Border.all(color: Color(0xFF21728D), width: 2),
              // your border color and width
              color: Colors.transparent,
            ),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.only(left: 50, right: 50),
                backgroundColor:
                    Color.fromRGBO(136, 161, 172, 0.0), // #88a1ac with 0% alpha
                side: BorderSide(color: Color(0x0088a1ac)), // border color
              ),
              onPressed: () async {
                ClipboardData? clipboardData =
                    await Clipboard.getData('text/plain');
                String? invoice = clipboardData?.text;
                if (invoice != null && invoice.isNotEmpty) {
                  _handleInvoice(invoice);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('No invoice found on the clipboard!')),
                  );
                }
              },
              child: Text(
                'Paste',
                style: TextStyle(
                    color: Color(0xFF21728D), fontWeight: FontWeight.w800),
              ),
            ),
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
