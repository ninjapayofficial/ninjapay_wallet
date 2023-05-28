import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:lnbits/lnbits.dart';
import 'package:flutter/services.dart';
import 'package:barcode_widget/barcode_widget.dart';

class HistoryPage extends StatefulWidget {
  final SharedPreferences prefs;

  HistoryPage({required this.prefs});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<dynamic>> _getTransactionHistory;

  @override
  void initState() {
    super.initState();
    _getTransactionHistory = _fetchTransactionHistory();
  }

  Future<List<dynamic>> _fetchTransactionHistory() async {
    final url = widget.prefs.getString('lnbits_url')!;
    final adminKey = widget.prefs.getString('lnbits_admin_key')!;
    final httpClient = HttpClient();

    final request = await httpClient.getUrl(
      Uri.parse('$url/api/v1/payments?limit=100&api-key=$adminKey'),
    );
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == HttpStatus.ok) {
      return jsonDecode(responseBody);
    } else {
      throw Exception('Failed to load transaction history');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _getTransactionHistory,
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final transactions = snapshot.data;
        return ListView.builder(
          itemCount: transactions!.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yy HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(
                        transactions[index]['time'] * 1000,
                      ),
                    ),
                  ),
                  Text(
                    '${(transaction['amount'] / 1000).toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  // added created date
                ],
              ),
              subtitle: Text(
                'Memo: ${transaction['memo']}',
                style: TextStyle(color: Color(0xFF88a1ac)),
              ),
              onTap: () {
                // added onTap callback
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("Transaction Details"),
                      content: Column(
                        children: <Widget>[
                          Text(
                            DateFormat('dd MMM yy HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                transactions[index]['time'] * 1000,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yy HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                transactions[index]['expiry'].toInt() * 1000,
                              ),
                            ),
                          ),
                          Text(
                              'Amount: ${(transaction['amount'] / 1000).toStringAsFixed(0)}'),
                          Text('Fee: ${transaction['fee']}'),
                          Text('Payment Hash: ${transaction['payment_hash']}'),
                          Text('Memo: ${transaction['memo']}'),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                  text: transactions[index]['bolt11']));
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Copied to Clipboard')));
                            },
                            child: Text(
                              'Invoice: ${transaction['bolt11']}',
                              style: TextStyle(color: Color(0xFF88a1ac)),
                            ),
                          ),
                          SizedBox(
                            height: 20, //Some spacing
                          ),
                          //Qr code
                          BarcodeWidget(
                            barcode: Barcode.qrCode(),
                            data: transactions[index]['bolt11'],
                            width: 200,
                            height: 200,
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text(
                            "Close",
                            style: TextStyle(
                                color: Color(0xFF21728D),
                                fontWeight: FontWeight.w800),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
