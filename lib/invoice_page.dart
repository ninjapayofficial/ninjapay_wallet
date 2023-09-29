import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:lnbits/lnbits.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slider_button/slider_button.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'home_page.dart';

class InvoicePage extends StatefulWidget {
  final LNBitsAPI api;
  final String invoice;
  final Map<String, dynamic> decodedInvoice;
  final SharedPreferences prefs;

  InvoicePage(
      {required this.api,
      required this.invoice,
      required this.decodedInvoice,
      required this.prefs});

  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String _paymentHash = '';
  var balance = "Updating balance...";
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // Convert amount to satoshis
    int amountSat = widget.decodedInvoice['amount_msat'] ~/ 1000;

    // Convert date to desired format
    DateTime date = DateTime.fromMillisecondsSinceEpoch(
        widget.decodedInvoice['date'] *
            1000); // Convert seconds to milliseconds
    String formattedDate = DateFormat('d MMM yy HH:mm').format(date);

    // Calculate expiry date
    Duration expiryDuration =
        Duration(seconds: widget.decodedInvoice['expiry']);
    DateTime expiryDate = date.add(expiryDuration);
    String formattedExpiryDate =
        DateFormat('d MMM yy HH:mm').format(expiryDate);

    return WillPopScope(
      onWillPop: () async => !_isLoading, // Prevent navigation when loading
      child: Scaffold(
        appBar: AppBar(
          // title: Text('Invoice details',
          //     style: TextStyle(color: Color(0xFF88a1ac))),
          backgroundColor: Color(0x00ffffff),
          shadowColor: Color(0x00ffffff),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/btc_wall.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text('$amountSat sat',
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800)),
                              SizedBox(height: 20),
                              Text(
                                  'Description: ${widget.decodedInvoice['description']}',
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center),
                              Text('Date: $formattedDate',
                                  style: TextStyle(fontSize: 16)),
                              Text('Expires at: $formattedExpiryDate',
                                  style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                      // Swipe to send button
                      SliderButton(
                        action: () {
                          _payInvoice();
                        },
                        label: Text(
                          "Slide to Pay    >>>>>>>>>>           ",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              color: Color(0xff4a4a4a),
                              fontWeight: FontWeight.w500,
                              fontSize: 17),
                        ),
                        icon: Icon(
                          Icons.currency_bitcoin_rounded,
                          color: Colors.white,
                          size: 40.0,
                        ),
                        width: 400,
                        radius: 10,
                        buttonColor: Color(0xFF21728D),
                        backgroundColor: Color.fromARGB(76, 33, 114, 141),
                        highlightedColor: Colors.white,
                        baseColor: Color(0xFF21728D),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void _payInvoice() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _paymentHash = await widget.api.payInvoice(bolt11: widget.invoice);

      // Check the payment status
      final isPaid = await widget.api.checkInvoice(paymentHash: _paymentHash);

      // Handle the payment result accordingly
      if (isPaid) {
        // Payment successful
        _showSuccessDialog();
        await Future.delayed(Duration(seconds: 2)); // Wait for 2 seconds
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => HomePage(prefs: widget.prefs)),
          (Route<dynamic> route) => false,
        );
        // Navigate back to home
      } else {
        // Payment failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed!')),
        );
      }
    } catch (e) {
      // Handle the error accordingly
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0x0088a1ac),
          title: Text('Payment Successful!', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
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
              )
              // SpinKitWave(
              //   color: Color(0xFF21728D),
              //   size: 50.0,
              // ),
            ],
          ),
        );
      },
    );
  }
}
