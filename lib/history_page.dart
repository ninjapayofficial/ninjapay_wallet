import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:barcode_widget/barcode_widget.dart';

class HistoryPage extends StatefulWidget {
  final SharedPreferences prefs;

  const HistoryPage({super.key, required this.prefs});

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
    final url = widget.prefs.getString('lnbits_url')!.trim();
    final adminKey = widget.prefs.getString('lnbits_admin_key')!.trim();
    final httpClient = HttpClient();

    final requestUrl =
        Uri.parse('$url/api/v1/payments?limit=200&api-key=$adminKey');

    final request = await httpClient.getUrl(requestUrl);
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
    return Scaffold(
      body: FutureBuilder<List<dynamic>>(
        future: _getTransactionHistory,
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                minLeadingWidth: 8,
                leading: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: SvgPicture.asset(
                    transaction['pending'] == true
                        ? 'assets/images/pending.svg'
                        : (transaction['amount'] < 0
                            ? 'assets/images/send.svg'
                            : 'assets/images/receive.svg'),
                    height: 28,
                    color: transaction['pending'] == true
                        ? const Color(0xFFB99866)
                        // Choose an appropriate color for pending
                        : (transaction['amount'] < 0
                            ? const Color(0xFFCF7381)
                            : const Color(0xFF2EB2A1)),
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yy HH:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(
                          transaction['time'] * 1000,
                        ),
                      ),
                    ),
                    Text(
                      '${(transaction['amount'] / 1000).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    // added created date
                  ],
                ),
                subtitle: Text(
                  'Memo: ${transaction['memo']}',
                  style: const TextStyle(color: Color(0xFF88a1ac)),
                ),
                onTap: () {
                  // added onTap callback
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        // backgroundColor: Color(0xFF21728D),
                        title: const Text("Transaction Details"),
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
                            Text(
                                'Payment Hash: ${transaction['payment_hash']}'),
                            Text('Memo: ${transaction['memo']}'),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                    text: transactions[index]['bolt11']));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Copied to Clipboard')));
                              },
                              child: Text(
                                'Invoice: ${transactions[index]['bolt11'].substring(0, 27)}.........................${transactions[index]['bolt11'].substring(transactions[index]['bolt11'].length - 27)}',
                                style: const TextStyle(color: Color(0xFF88a1ac)),
                              ),
                            ),

                            const Text('Tap to copy ☝️'),
                            const SizedBox(
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
                            child: const Text(
                              "Close",
                              style: TextStyle(
                                  color: Color(0xFF21728D), // 0xFF21728D
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
      ),
    );
  }
}
