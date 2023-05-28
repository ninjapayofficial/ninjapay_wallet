import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lnbits/lnbits.dart';
import 'package:ninjapay/qr_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceivePage extends StatefulWidget {
  final LNBitsAPI api;
  final SharedPreferences prefs;

  ReceivePage({required this.api, required this.prefs});

  @override
  _ReceivePageState createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  final TextEditingController _satsController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  bool _isLoading = false;
  String amount = "0";

  Future<void> _generateInvoice() async {
    setState(() {
      _isLoading = true;
    });
    var navigator = Navigator.of(context);

    final invoiceData = await widget.api
        .createInvoice(amount: int.parse(amount), memo: _memoController.text);

    navigator.push(
      MaterialPageRoute(
          builder: (context) => QrPage(
              api: widget.api,
              prefs: widget.prefs,
              invoice: invoiceData,
              amount: int.parse(amount),
              memo: _memoController.text)),
    );
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? SpinKitWave(
            color: Color(0xFF21728D),
            size: 50.0,
          )
        : Scaffold(
            // appBar: AppBar(
            //   backgroundColor: Theme.of(context).brightness == Brightness.dark
            //       ? Color(0xFF000000)
            //       : Color(0xff88a1ac),
            //   title: Text('Receive'),
            // ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$amount',
                    style: TextStyle(fontSize: 47, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'sats',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
                  ),
                  SizedBox(height: 100),
                  Container(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    width: double.infinity,
                    child: TextField(
                      controller: _memoController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter note',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF88a1ac),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        for (var i = 1; i <= 3; i++) _buildButton(i.toString()),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 4; i <= 6; i++) _buildButton(i.toString()),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 7; i <= 9; i++) _buildButton(i.toString()),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildButton("Clr"),
                        _buildButton("0"),
                        _buildButton("Del"),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.only(left: 6, right: 6),
                    width: double
                        .infinity, // This will make the button span the full width of the screen
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.only(top: 20, bottom: 20),
                        backgroundColor:
                            Color(0xFF21728D), // #88a1ac with 100% alpha
                        side: BorderSide(
                            color: Color(0x1A88a1ac)), // border color
                      ),
                      onPressed: _generateInvoice,
                      child: Text(
                        'Generate Invoice',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildButton(String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0x00ffffff),
        shadowColor: Color(0x0088a1ac), // #88a1ac with 100% alpha
        side: BorderSide(color: Color(0x1A88a1ac)), // border color
      ),
      onPressed: () => _onPressed(label),
      child: Text(
        label,
        style: TextStyle(color: Color(0xFF88a1ac), fontSize: 16),
      ),
    );
  }

  _onPressed(String label) {
    setState(() {
      if (label == "Clr") {
        amount = "0";
      } else if (label == "Del") {
        if (amount.length > 1) {
          amount = amount.substring(0, amount.length - 1);
        } else {
          amount = "0";
        }
      } else {
        if (amount == "0") {
          amount = label;
        } else {
          amount += label;
        }
      }
    });
  }
}
