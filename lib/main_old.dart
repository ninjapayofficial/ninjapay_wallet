// import 'dart:io';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:ninjapay/services/speect_to_text_api_client.dart';
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/services.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:http_parser/http_parser.dart';

// void main() => runApp(MaterialApp(
//       home: MyApp(),
//     ));

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   var text = "123";

//   Future<String> convertSpeechToText(String filePath) async {
//     const apiKey = '';
//     var url = Uri.https("api.openai.com", "v1/audio/translations");
//     var request = http.MultipartRequest('POST', url);
//     request.headers.addAll(({"Authorization": "Bearer $apiKey"}));
//     request.fields["model"] = 'whisper-1';
//     request.fields["language"] = "en";
//     request.files.add(await http.MultipartFile.fromPath('file', filePath,
//         contentType: MediaType('audio', 'm4a')));
//     var response = await request.send();
//     var newresponse = await http.Response.fromStream(response);
//     final responseData = json.decode(newresponse.body);

//     return responseData['text'];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("ChatGPT Flutter"),
//       ),
//       body: content(),
//     );
//   }

//   Widget content() {
//     return Container(
//       width: double.infinity,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//               child: ElevatedButton(
//             onPressed: () async {
//               FilePickerResult? result = await FilePicker.platform.pickFiles();
//               if (result != null) {
//                 //call openai's transcription api
//                 convertSpeechToText(result.files.single.path!).then((value) {
//                   print(value);
//                   setState(() {
//                     text = value;
//                   });
//                 });
//               }
//             },
//             child: Text(" Pick File "),
//           )),
//           SizedBox(
//             height: 20,
//           ),
//           Text(
//             "Speech to Text : " + text,
//             style: TextStyle(fontSize: 20),
//           )
//         ],
//       ),
//     );
//   }
// }
