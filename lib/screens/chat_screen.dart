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

    // Create a new thread
    var createThreadUrl = Uri.parse('$apiUrlBase/threads');
    var threadResponse = await http.post(
      createThreadUrl,
      headers: {
        'Authorization': 'Bearer $openaiApiKey',
        'Content-Type': 'application/json',
        'OpenAI-Beta': 'assistants=v1'
      },
    );

    print("Thread creation response: ${threadResponse.statusCode}");
    if (threadResponse.statusCode == 200) {
      var threadData = jsonDecode(threadResponse.body);
      var threadId = threadData['id']; // Extract the thread ID
      print("Thread ID: $threadId");

      // Add a message to the thread
      var addMessageUrl = Uri.parse('$apiUrlBase/threads/$threadId/messages');
      var messageResponse = await http.post(
        addMessageUrl,
        headers: {
          'Authorization': 'Bearer $openaiApiKey',
          'Content-Type': 'application/json',
          'OpenAI-Beta': 'assistants=v1'
        },
        body: jsonEncode({
          'role': 'user',
          'content': message,
        }),
      );

      print("Message addition response: ${messageResponse.statusCode}");

      // Run the assistant
      var runUrl = Uri.parse('$apiUrlBase/threads/$threadId/runs');
      var runResponse = await http.post(
        runUrl,
        headers: {
          'Authorization': 'Bearer $openaiApiKey',
          'Content-Type': 'application/json',
          'OpenAI-Beta': 'assistants=v1'
        },
        body: jsonEncode({
          'assistant_id': assistantId,
        }),
      );

      // Check for the assistant's response
      if (runResponse.statusCode == 200) {
        // Wait for the run to complete and then retrieve the assistant's response
        var runData = jsonDecode(runResponse.body);
        var runId = runData['id'];

        bool runCompleted = false;
        while (!runCompleted) {
          await Future.delayed(
              Duration(seconds: 1)); // Delay to prevent rapid polling

          var runStatusUrl =
              Uri.parse('$apiUrlBase/threads/$threadId/runs/$runId');
          var runStatusResponse = await http.get(
            runStatusUrl,
            headers: {
              'Authorization': 'Bearer $openaiApiKey',
              'OpenAI-Beta': 'assistants=v1'
            },
          );

          if (runStatusResponse.statusCode == 200) {
            var runStatusData = jsonDecode(runStatusResponse.body);
            runCompleted = runStatusData['status'] == 'completed';
          } else {
            print("Error fetching run status: ${runStatusResponse.body}");
            break;
          }
        }
        // Retrieve the assistant's response
        var messagesUrl = Uri.parse('$apiUrlBase/threads/$threadId/messages');
        var messagesResponse = await http.get(
          messagesUrl,
          headers: {
            'Authorization': 'Bearer $openaiApiKey',
            'OpenAI-Beta': 'assistants=v1'
          },
        );

        print("Messages retrieval response: ${messagesResponse.statusCode}");
        if (messagesResponse.statusCode == 200) {
          var messagesData = jsonDecode(messagesResponse.body);
          var assistantMessages = messagesData['data']
              .where((msg) => msg['role'] == 'assistant')
              .toList();
          print("Message: $messagesData");
          print("Assistant Message: $assistantMessages");

          // Assuming the last assistant message contains the action response
          if (assistantMessages.isNotEmpty) {
            var lastAssistantMessage = assistantMessages.last;
            print("Last Assistant Message: $lastAssistantMessage");
            print("Content: ${lastAssistantMessage['content']}");
            print("Text: ${lastAssistantMessage['content']['text']}");
            var assistantResponse =
                lastAssistantMessage['content']['text']['value'];

            print("Assistant's response: $assistantResponse");
            setState(() {
              _messages.insert(0, "Bot: $assistantResponse");
            });

            // Check if the assistant's response indicates an action to create an invoice
            if (assistantResponse.contains('action:createInvoice')) {
              // Parse the response to extract the amount and memo
              var amount = lastAssistantMessage['parameters']['amount'];
              var memo = lastAssistantMessage['parameters']['memo'];
              if (amount != null && memo != null) {
                await _createInvoice(amount, memo);
              }
            }
          }
        }
      }
    }
  }

  Future<void> _createInvoice(int amount, String memo) async {
    var url = Uri.parse('https://legend.lnbits.com/api/v1/payments');
    var headers = {
      "X-Api-Key": "c6bda6e5c9374c21a5cdee58572f08e1",
      "Content-type": "application/json"
    };
    var body = jsonEncode({"out": false, "amount": amount, "memo": memo});

    try {
      var response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        // Assuming the response contains some sort of success message or invoice ID
        var invoiceId =
            responseData['id']; // Adjust this based on actual response
        print("Invoice created successfully: $invoiceId");
        setState(() {
          _messages.insert(
              0, "Bot: Invoice created successfully. ID: $invoiceId");
        });
      } else {
        setState(() {
          _messages.insert(0,
              "Bot: Failed to create invoice. Status code: ${response.statusCode}");
        });
      }
    } catch (e) {
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
                    onSubmitted: _sendMessage,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
