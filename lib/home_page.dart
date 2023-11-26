import 'dart:convert';
import 'dart:io';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lnbits/lnbits.dart';
import 'package:ninjapay/screens/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_page.dart';
import 'initial_setup.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import 'plugin_page.dart';
import 'receive_page.dart';
import 'send_page.dart';
import 'trade_page.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  final SharedPreferences prefs;

  HomePage({required this.prefs});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future _getWalletDetails;
  late LNBitsAPI api; // Declare here
  // Add a new key for the RefreshIndicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Future<Null> _handleRefresh() async {
    setState(() {
      _getWalletDetails = _fetchWalletDetails();
    });

    return null;
  }

  // Future<void> _refresh() async {
  //   setState(() {
  //     _getWalletDetails = _fetchWalletDetails();
  //   });
  // }

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
      api = LNBitsAPI(
        // Initialize here
        url: widget.prefs.getString('lnbits_url')!,
        adminKey: widget.prefs.getString('lnbits_admin_key')!,
        invoiceKey: widget.prefs.getString('lnbits_invoice_key')!,
      );
      _getWalletDetails = _fetchWalletDetails();
      // _getTransactionHistory = _fetchTransactionHistory();
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

  Future<double> fetchBtcToUsd() async {
    const url =
        'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['bitcoin']['usd'].toDouble();
    } else {
      throw Exception('Failed to load conversion rate');
    }
  }

  int _currentIndex = 0;

  List<Widget> get tabs => [
        RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          child: FutureBuilder(
            future: Future.wait([
              _getWalletDetails,
              fetchBtcToUsd(),
            ]),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final walletDetails = snapshot.data![0];
              final btcToUsdRate = snapshot.data![1];
              final balanceInBtc = walletDetails['balance'] /
                  100000000000; // convert msats to btc
              final balanceInUsd = balanceInBtc * btcToUsdRate;
              // ...
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    Center(
                      child: Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height *
                            0.2, // adjust the height as needed
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          border: Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Color.fromARGB(89, 33, 114, 141)
                                  : Color.fromARGB(89, 33, 114, 141),
                              width: 2),
                          // your border color and width
                          color: Colors.transparent,
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Image.asset(
                                'assets/images/lwallet.png', // update with the correct path to your image
                                width: 100, // adjust the size as needed
                              ),
                            ),
                            Positioned(
                              right: 10,
                              top: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${(walletDetails['balance'] / 1000).toStringAsFixed(0)}', // convert msats to sats
                                    style: TextStyle(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF21728d),
                                    ),
                                  ),
                                  Text(
                                    'sats',
                                    style: TextStyle(
                                        color: Color(0xFF88a1ac),
                                        fontSize:
                                            16), // adjust the font size as needed
                                  ),
                                  Text(
                                    '(\$${balanceInUsd.toStringAsFixed(2)})', // show USD equivalent
                                    style: TextStyle(
                                        color: Color(0xFF88a1ac),
                                        fontSize:
                                            16), // adjust the font size as needed
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                                right: 10,
                                bottom: 5,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            HistoryPage(prefs: widget.prefs),
                                      ),
                                    );
                                  },
                                  child: Chip(
                                    backgroundColor: Color(
                                        0x1A21728D), // set color to what suits your app
                                    avatar: Icon(
                                      Icons
                                          .history, // set icon to what you prefer
                                      color: Color(0xFF88a1ac),
                                    ),
                                    label: Text(
                                      'History',
                                      style:
                                          TextStyle(color: Color(0xFF88a1ac)),
                                    ),
                                  ),
                                )),
                            Positioned(
                              left: -5,
                              bottom: -5,
                              child: Image.asset(
                                'assets/images/lnbits.png', // update with the correct path to your image
                                width: 100, // adjust the size as needed
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                        height: 10), // space between rectangle box and buttons
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: <Widget>[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(
                                136, 161, 172, 0.2), // #88a1ac with 20% alpha
                            side: BorderSide(
                                color: Color(0x1A88a1ac)), // border color
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SendPage(api: api, prefs: widget.prefs),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/images/send.svg',
                                color: Color(0xFF88a1ac),
                                height: 28,
                              ),
                              Text('Send',
                                  style: TextStyle(
                                      color:
                                          Color(0xFF88a1ac))), // color of text
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(
                                136, 161, 172, 0.2), // #88a1ac with 20% alpha
                            side: BorderSide(
                                color: Color(0x1A88a1ac)), // border color
                          ),
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ReceivePage(
                                        api: api, prefs: widget.prefs)));
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/images/receive.svg',
                                color: Color(0xFF88a1ac),
                                height: 28,
                              ), // color of icon
                              Text('Receive',
                                  style: TextStyle(
                                      color:
                                          Color(0xFF88a1ac))), // color of text
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        ChatScreen(), // new page
        TradePage(api: api, prefs: widget.prefs), // new page
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset(
          Theme.of(context).brightness == Brightness.dark
              ? 'assets/images/logo_light.svg'
              : 'assets/images/logo_dark.svg',
          height: 14,
        ),
        centerTitle: true,
        backgroundColor: Color(0x00ffffff),
        shadowColor: Color(0x00ffffff),
      ),
      body: tabs[_currentIndex], // body changes based on the selected tab
      bottomNavigationBar: BottomNavigationBar(
        // backgroundColor: Color(0xFFffffff),
        currentIndex: _currentIndex,
        selectedItemColor: Color(0xFF21728D), // color when active
        unselectedItemColor: Color(0xFF88a1ac), // color when inactive
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Color(0x1A21728D)
                : null,
            icon: Icon(Icons.electric_bolt_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cable_rounded),
            label: 'Plugins',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.candlestick_chart_rounded),
            label: 'Trade',
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
