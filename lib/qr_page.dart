import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lnbits/lnbits.dart';
import 'package:ninjapay/receive_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QrPage extends StatelessWidget {
  final String invoice;
  final int amount;
  final String memo;
  final LNBitsAPI api;
  final SharedPreferences prefs;

  QrPage(
      {required this.invoice,
      required this.amount,
      required this.memo,
      required this.api,
      required this.prefs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 12, right: 12, top: 40),
            child: Column(
              children: [
                Container(
                  padding:
                      EdgeInsets.only(left: 8, right: 8, top: 100, bottom: 10),
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height *
                      0.6, // adjust the height as needed
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    border: Border.all(color: Color(0x1A88a1ac), width: 2),
                    color: Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      BarcodeWidget(
                        barcode: Barcode.qrCode(),
                        data: invoice,
                        width: 200,
                        height: 200,
                      ),
                      SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: '$invoice'));
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied to Clipboard')));
                        },
                        child: Text(
                          '$invoice',
                          style: TextStyle(color: Color(0xFF88a1ac)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Amount: $amount sats',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
                ),
                Text(
                  'Memo: $memo',
                  style: TextStyle(color: Color(0xFF88a1ac)),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(100)),
                  border: Border.all(color: Color(0xFF21728D), width: 2),
                  color: Colors.transparent,
                ),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.only(left: 50, right: 50),
                    backgroundColor: Color.fromRGBO(
                        136, 161, 172, 0.0), // #88a1ac with 0% alpha
                    side: BorderSide(color: Color(0x0088a1ac)), // border color
                  ),
                  onPressed: () async {
                    Clipboard.setData(ClipboardData(text: '$invoice'));
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied to Clipboard')));
                  },
                  child: Text(
                    'Copy',
                    style: TextStyle(
                        color: Color(0xFF21728D), fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
