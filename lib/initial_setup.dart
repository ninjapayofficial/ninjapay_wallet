import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

class InitialSetupPage extends StatefulWidget {
  final SharedPreferences prefs;

  const InitialSetupPage({super.key, required this.prefs});

  @override
  _InitialSetupPageState createState() => _InitialSetupPageState();
}

class _InitialSetupPageState extends State<InitialSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _adminKeyController = TextEditingController();
  final _invoiceKeyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Initial Setup"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                    labelText: "LNbits URL(https://legend.lnbits.com)"),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the LNbits URL';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _adminKeyController,
                decoration: const InputDecoration(labelText: "Admin Key"),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the Admin Key';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _invoiceKeyController,
                decoration: const InputDecoration(labelText: "Invoice Key"),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the Invoice Key';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                child: const Text("Submit"),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.prefs
                        .setString('lnbits_url', _urlController.text.trim());
                    widget.prefs.setString(
                        'lnbits_admin_key', _adminKeyController.text.trim());
                    widget.prefs.setString('lnbits_invoice_key',
                        _invoiceKeyController.text.trim());
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomePage(prefs: widget.prefs)),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
