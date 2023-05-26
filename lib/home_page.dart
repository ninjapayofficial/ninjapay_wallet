import 'dart:convert';
import 'dart:io';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:lnbits/lnbits.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'initial_setup.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  final SharedPreferences prefs;

  HomePage({required this.prefs});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future _getWalletDetails;
  late Future _getTransactionHistory;

  @override
  void initState() {
    super.initState();

    if (widget.prefs.getString('lnbits_url') == null ||
        widget.prefs.getString('lnbits_admin_key') == null ||
        widget.prefs.getString('lnbits_invoice_key') == null) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Missing information"),
                content: Text("Please enter LNBits URL and keys"),
                actions: <Widget>[
                  TextButton(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  InitialSetupPage(prefs: widget.prefs)));
                    },
                  )
                ],
              );
            });
      });
    } else {
      _getWalletDetails = _fetchWalletDetails();
      _getTransactionHistory = _fetchTransactionHistory();
    }
  }

  Future _fetchWalletDetails() async {
    final api = LNBitsAPI(
      url: widget.prefs.getString('lnbits_url')!,
      adminKey: widget.prefs.getString('lnbits_admin_key')!,
      invoiceKey: widget.prefs.getString('lnbits_invoice_key')!,
    );
    return await api.getWalletDetails();
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

  int _currentIndex = 0;

  List<Widget> get tabs => [
        FutureBuilder(
          future: _getWalletDetails,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            final walletDetails = snapshot.data;
            return Column(
              children: <Widget>[
                Text('Welcome ${walletDetails['name']}'),
                Text('Balance: ${walletDetails['balance']}'),
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: _fetchTransactionHistory(),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<dynamic>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
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
                                Text('Amount: ${transaction['amount']}'),
                                Text(
                                  DateFormat('dd MMM yy HH:mm').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      transactions[index]['time'] * 1000,
                                    ),
                                  ),
                                ), // added created date
                              ],
                            ),
                            subtitle: Text('Memo: ${transaction['memo']}'),
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
                                              transactions[index]['time'] *
                                                  1000,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          DateFormat('dd MMM yy HH:mm').format(
                                            DateTime.fromMillisecondsSinceEpoch(
                                              transactions[index]['expiry']
                                                      .toInt() *
                                                  1000,
                                            ),
                                          ),
                                        ),
                                        Text(
                                            'Amount: ${transaction['amount']}'),
                                        Text('Fee: ${transaction['fee']}'),
                                        Text(
                                            'Payment Hash: ${transaction['payment_hash']}'),
                                        Text('Memo: ${transaction['memo']}'),
                                        GestureDetector(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(
                                                text: transactions[index]
                                                    ['bolt11']));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        'Copied to Clipboard')));
                                          },
                                          child: Text(
                                              'Invoice: ${transaction['bolt11']}'),
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
                                        child: Text("Close"),
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
                ),
              ],
            );
          },
        ),
        Center(child: Text('Plugins')),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ninjapay"),
      ),
      body: tabs[_currentIndex], // body changes based on the selected tab
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.extension),
            label: 'Plugins',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
