import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
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

  void _sendMessage(String text) {
    setState(() {
      _messages.insert(0, "You: $text");
    });
    _processMessage(text);
  }

  Future<void> _processMessage(String message) async {
    print("Sending message to GPT: $message");

    var chatCompletionUrl = Uri.parse('$apiUrlBase/chat/completions');
    var chatResponse = await http.post(
      chatCompletionUrl,
      headers: {
        'Authorization': 'Bearer $openaiApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo-1106',
        'messages': [
          {'role': 'user', 'content': message}
        ],
        'tools': [
          // Add the tools array here
          {
            'type': 'function',
            'function': {
              'name': 'createInvoice',
              'description':
                  'Create an invoice with specified amount and memo, always ask for user for amount input if not given',
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
          }
        ],
        'tool_choice': 'auto'
      }),
    );

    print("Chat completion response: ${chatResponse.statusCode}");
    if (chatResponse.statusCode == 200) {
      var chatData = jsonDecode(chatResponse.body);
      print("Chat data: $chatData");

      var choices = chatData['choices'];
      if (choices.isNotEmpty) {
        var assistantMessage = choices[0]['message'];
        print("Assistant's response: $assistantMessage");

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
          }
        } else if (assistantMessage['content'] != null) {
          // Handling regular text responses
          setState(() {
            _messages.insert(0, "Bot: ${assistantMessage['content']}");
          });
        }
      }
    } else {
      print("Error in chat completion: ${chatResponse.body}");
    }
  }

  Future<void> _createInvoice(int amount, String memo) async {
    var url = Uri.parse('https://legend.lnbits.com/api/v1/payments');
    var headers = {
      "X-Api-Key": "c6bda6e5c9374c21a5cdee58572f08e1",
      "Content-type": "application/json"
    };
    var body = jsonEncode({
      "out": false,
      "amount": amount,
      "memo": memo
      // Add other fields if necessary, such as "expiry", "unit", "webhook", "internal"
    });

    try {
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        var paymentRequest = responseData['payment_request'];
        print(
            "Invoice created successfully: Payment Request - $paymentRequest");
        setState(() {
          _messages.insert(
              0, "Bot: Invoice created. Payment Request: $paymentRequest");
        });
      } else {
        print("Failed to create invoice. Response: ${response.body}");
        setState(() {
          _messages.insert(0,
              "Bot: Failed to create invoice. Status code: ${response.statusCode}");
        });
      }
    } catch (e) {
      print("Error occurred while creating invoice: $e");
      setState(() {
        _messages.insert(
            0, "Bot: Error occurred while creating invoice. Error: $e");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invoice Chatbot')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  ListTile(title: Text(_messages[index])),
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
