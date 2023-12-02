import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  final SharedPreferences prefs;
  ChatScreen({required this.prefs});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _messages = [];
  static const String openaiApiKey =
      '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';
  static const String assistantId =
      'asst_CSYIJvNEJIBs7l0tJeWyrNR1'; // Replace with your actual Assistant ID
  static const String apiUrlBase = 'https://api.openai.com/v1';

  @override
  void initState() {
    super.initState();
    // Add the initial bot message here
    _addInitialBotMessage();
  }

  void _sendMessage(String text) {
    setState(() {
      _messages.insert(0, "You: $text");
    });
    _processMessage(text);
  }

  void _addInitialBotMessage() {
    setState(() {
      _messages.insert(0,
          "AskAI: How can I help you? I can help you create, pay invoices or contacts, send money to U.S, place limit orders, etc...");
    });
  }

  Future<void> _processMessage(String message) async {
    if (kDebugMode) {
      print("Sending message to GPT: $message");
    }

    // Define system message with instructions
    var systemMessage = {
      'role': 'system',
      'content':
          'You are a helpful assistant. Please create or pay invoices as per user requests. Dont make assumptions about what values to plug into functions. Ask for clarification if a user request is ambiguous.'
    };

    // Define user message
    var userMessage = {'role': 'user', 'content': message};
    // Combine system and user messages
    var messages = [systemMessage, userMessage];

    var chatCompletionUrl = Uri.parse('$apiUrlBase/chat/completions');
    var chatResponse = await http.post(
      chatCompletionUrl,
      headers: {
        'Authorization': 'Bearer $openaiApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo-1106',
        'messages': messages,
        'tools': [
          {
            'type': 'function',
            'function': {
              'name': 'createInvoice',
              'description':
                  'Create an invoice with specified amount and memo, always ask the user for amount input if not given already',
              'parameters': {
                'type': 'object',
                'properties': {
                  'amount': {
                    'type': 'integer',
                    'description':
                        'The amount for the invoice which is required by user as an input always'
                  },
                  'memo': {
                    'type': 'string',
                    'description': 'An memo or description for the invoice'
                  }
                },
                'required': ['amount', 'memo']
              },
            }
          },
          {
            'type': 'function',
            'function': {
              'name': 'payInvoice',
              'description':
                  'Pay an invoice or make payment using the provided Bolt11 string, if user does not give the bolt11 which starts with lnbc...., ask him again until he does.',
              'parameters': {
                'type': 'object',
                'properties': {
                  'bolt11': {
                    'type': 'string',
                    'description':
                        'The Bolt11 string for the invoice to be paid'
                  }
                },
                'required': ['bolt11']
              }
            }
          }
        ],
        'tool_choice': 'auto'
      }),
    );

    if (kDebugMode) {
      print("Chat completion response: ${chatResponse.statusCode}");
    }
    if (chatResponse.statusCode == 200) {
      var chatData = jsonDecode(chatResponse.body);
      if (kDebugMode) {
        print("Chat data: $chatData");
      }

      var choices = chatData['choices'];
      if (choices.isNotEmpty) {
        var assistantMessage = choices[0]['message'];
        if (kDebugMode) {
          print("Assistant's response: $assistantMessage");
        }

        // Check if the assistant's response contains a function call
        if (assistantMessage['tool_calls'] != null &&
            assistantMessage['tool_calls'].isNotEmpty) {
          var toolCall = assistantMessage['tool_calls'][0];
          var functionName = toolCall['function']['name'];

          // Handling the createInvoice function call
          if (functionName == 'createInvoice') {
            var functionArgs = jsonDecode(toolCall['function']['arguments']);
            int amount = functionArgs['amount'];
            String memo = functionArgs['memo'];

            if (amount != null && memo != null) {
              await _createInvoice(amount, memo);
            }
          } else if (functionName == 'payInvoice') {
            var functionArgs = jsonDecode(toolCall['function']['arguments']);
            String bolt11 = functionArgs['bolt11'];

            if (bolt11 != null) {
              await _payInvoice(bolt11);
            }
          }
        } else if (assistantMessage['content'] != null) {
          // Handling regular text responses
          setState(() {
            _messages.insert(0, "AskAI: ${assistantMessage['content']}");
          });
        }
      }
    } else {
      if (kDebugMode) {
        print("Error in chat completion: ${chatResponse.body}");
      }
    }
  }

  // Method to Create invoice
  Future<void> _createInvoice(int amount, String memo) async {
    var url = widget.prefs.getString('lnbits_url')!;
    var headers = {
      "X-Api-Key": widget.prefs.getString('lnbits_admin_key')!,
      "Content-type": "application/json"
    };
    var body = jsonEncode({
      "out": false,
      "amount": amount,
      "memo": memo
      // Add other fields if necessary, such as "expiry", "unit", "webhook", "internal"
    });

    try {
      var response = await http.post(Uri.parse('$url/api/v1/payments'),
          headers: headers, body: body);
      if (response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        var paymentRequest = responseData['payment_request'];
        if (kDebugMode) {
          print(
              "Invoice created successfully: Payment Request - $paymentRequest");
        }
        setState(() {
          _messages.insert(
              0, "AskAI: Invoice created. Payment Request: $paymentRequest");
        });
      } else {
        if (kDebugMode) {
          print("Failed to create invoice. Response: ${response.body}");
        }
        setState(() {
          _messages.insert(0,
              "AskAI: Failed to create invoice. Status code: ${response.statusCode}");
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error occurred while creating invoice: $e");
      }
      setState(() {
        _messages.insert(
            0, "AskAI: Error occurred while creating invoice. Error: $e");
      });
    }
  }

  // Method to Pay an invoice
  Future<void> _payInvoice(String bolt11) async {
    var url = widget.prefs.getString('lnbits_url')!;
    var headers = {
      "X-Api-Key": widget.prefs.getString('lnbits_admin_key')!,
      "Content-type": "application/json"
    };
    var body = jsonEncode({"out": true, "bolt11": bolt11});

    try {
      var response = await http.post(Uri.parse('$url/api/v1/payments'),
          headers: headers, body: body);
      if (response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        var paymentHash = responseData['payment_hash'];
        if (kDebugMode) {
          print("Payment made successfully: Payment Hash - $paymentHash");
        }
        setState(() {
          _messages.insert(0,
              "AskAI: Payment made successfully. Payment Hash: $paymentHash");
        });
      } else {
        if (kDebugMode) {
          print("Failed to make payment. Response: ${response.body}");
        }
        setState(() {
          _messages.insert(0,
              "AskAI: Failed to make payment. Status code: ${response.statusCode}");
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error occurred while making payment: $e");
      }
      setState(() {
        _messages.insert(
            0, "AskAI: Error occurred while making payment. Error: $e");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //     // centerTitle: true,
      //     title: Text(
      //       'AskAI',
      //       // style: TextStyle(color: Colors.blueGrey),
      //     ),
      //     backgroundColor: Color.fromARGB(21, 136, 161, 172)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                var isBotMessage = _messages[index].startsWith("AskAI:");
                return GestureDetector(
                  onTap: () {
                    if (isBotMessage) {
                      int lastColonIndex = _messages[index].lastIndexOf(':');
                      if (lastColonIndex != -1 &&
                          lastColonIndex < _messages[index].length - 1) {
                        String textToCopy = _messages[index]
                            .substring(lastColonIndex + 1)
                            .trim();
                        Clipboard.setData(ClipboardData(text: textToCopy));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Copied to clipboard: $textToCopy')),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isBotMessage)
                          Image.asset('assets/images/ninjapay_logo_circle.png',
                              width: 37),
                        SizedBox(width: isBotMessage ? 8.0 : 0),
                        Expanded(
                          child: Text(_messages[index]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: 'Send a message'),
                    onSubmitted: (text) {
                      // Clear the text field without sending the message again
                      _controller.clear();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage(_controller.text);
                    _controller.clear(); // Clear text after sending
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
