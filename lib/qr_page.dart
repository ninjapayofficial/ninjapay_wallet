import 'dart:async';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lnbits/lnbits.dart';
import 'package:lottie/lottie.dart';
import 'package:ninjapay/home_page.dart';
import 'package:ninjapay/receive_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QrPage extends StatefulWidget {
  final String invoice;
  final int amount;
  final String memo;
  final LNBitsAPI api;
  final SharedPreferences prefs;
  var paid = false;

  QrPage(
      {required this.invoice,
      required this.amount,
      required this.memo,
      required this.api,
      required this.prefs});

  @override
  _QrPageState createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> with TickerProviderStateMixin {
  bool isPaid = false;
  Timer? _timer;
  String? paymentHash;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    getPaymentHash();
    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) => checkPayment());
    _controller = AnimationController(vsync: this);
  }

  Future<void> getPaymentHash() async {
    final decodedInvoice =
        await widget.api.decodeInvoice(invoice: widget.invoice);
    paymentHash = decodedInvoice['payment_hash'];
  }

  void checkPayment() async {
    if (paymentHash != null) {
      final bool isInvoicePaid =
          await widget.api.checkInvoice(paymentHash: paymentHash!);
      if (isInvoicePaid) {
        if (_timer != null) {
          _timer!.cancel();
          _timer = null;
        }
        setState(() {
          isPaid = true;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 12, right: 12, top: 40),
            child: Column(
              children: [
                if (isPaid)
                  Lottie.asset(
                    'assets/success.json',
                    controller: _controller,
                    onLoaded: (composition) {
                      // Configure the AnimationController with the duration of the
                      // Lottie file and start the animation.
                      _controller
                        ..duration = composition.duration
                        ..forward();
                    },
                  ) // display gif when payment is done
                else
                  Container(
                    padding:
                        EdgeInsets.only(left: 8, right: 8, top: 70, bottom: 10),
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height *
                        0.6, // adjust the height as needed
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      border: Border.all(color: Color(0x1A88a1ac), width: 2),
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        BarcodeWidget(
                          barcode: Barcode.qrCode(),
                          data: widget.invoice,
                          width: 200,
                          height: 200,
                        ),
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: '${widget.invoice}'));
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Copied to Clipboard')));
                          },
                          child: Text(
                            '${widget.invoice}',
                            style: TextStyle(color: Color(0xFF88a1ac)),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 10),
                Text(
                  'Amount: ${widget.amount} sats',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26),
                ),
                Text(
                  'Memo: ${widget.memo}',
                  style: TextStyle(color: Color(0xFF88a1ac)),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: isPaid
                ? // If the invoice has been paid, show a "Payment Received" message or any other widget you want to show
                IconButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                HomePage(prefs: widget.prefs)),
                        (Route<dynamic> route) =>
                            false, //this makes the HomePage the root
                      );
                    },
                    icon: Icon(Icons.close))
                : Padding(
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
                          side: BorderSide(
                              color: Color(0x0088a1ac)), // border color
                        ),
                        onPressed: () async {
                          Clipboard.setData(
                              ClipboardData(text: '${widget.invoice}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied to Clipboard')));
                        },
                        child: Text(
                          'Copy',
                          style: TextStyle(
                              color: Color(0xFF21728D),
                              fontWeight: FontWeight.w800),
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
