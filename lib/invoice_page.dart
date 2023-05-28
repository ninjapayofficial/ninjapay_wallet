import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:lnbits/lnbits.dart';
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

class _InvoicePageState extends State<InvoicePage> {
  bool _isLoading = false;
  String _paymentHash = '';
  var balance = "Updating balance...";

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
          title: Text('Invoice Details'),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Amount: $amountSat sat'),
                    Text(
                        'Description: ${widget.decodedInvoice['description']}'),
                    Text('Date: $formattedDate'),
                    Text('Expires at: $formattedExpiryDate'),
                    // Add more fields as needed

                    Flexible(
                      child: ListView(
                        shrinkWrap:
                            true, // Ensures that the list only occupies the necessary space
                        children: <Widget>[
                          // Swipe to send button
                          SliderButton(
                            action: () {
                              _payInvoice();
                            },
                            label: Text(
                              "Slide to Pay",
                              style: TextStyle(
                                  color: Color(0xff4a4a4a),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17),
                            ),
                            icon: Icon(
                              Icons.payment,
                              color: Colors.white,
                              size: 40.0,
                            ),
                            width: 400,
                            radius: 10,
                            buttonColor: Color(0xFF21728D),
                            backgroundColor: Colors.white,
                            highlightedColor: Colors.white,
                            baseColor: Color(0xFF21728D),
                          ),
                        ],
                      ),
                    ),
                  ],
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
          title: Text('Payment Successful!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SpinKitWave(
                color: Colors.green,
                size: 50.0,
              ),
            ],
          ),
        );
      },
    );
  }
}
