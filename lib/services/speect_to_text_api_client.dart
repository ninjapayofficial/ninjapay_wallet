import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class SpeechToTextApiClient {
  static const String baseUrl = 'https://api.openai.com';
  final String openaiApiKey;

  SpeechToTextApiClient(filepath, {required this.openaiApiKey});

  Future<String> convertSpeechToText(
      {required String filePath, String model = 'whisper-1'}) async {
    final uri = Uri.parse('$baseUrl/v1/audio/translations');

    var request = http.MultipartRequest('POST', uri);
    request.headers[HttpHeaders.authorizationHeader] = 'Bearer $openaiApiKey';

    var multipartFile = await http.MultipartFile.fromPath('file', filePath,
        contentType: MediaType('audio', 'mpeg'));

    request.fields['model'] = model;
    request.files.add(multipartFile);

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print(data);
        // Extract and return the transcription from the response
        // Adjust this logic based on the actual structure of the response
        return data['translation'] ?? 'Translation not available';
      } else {
        throw Exception(
            'Failed to transcribe audio. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error during transcription: $e');
    }
  }
}
//////
///
///
  // Future<String> _convertSpeechToText(
  //     {required String filePath, String model = 'whisper-1'}) async {
  //   final uri = Uri.parse('https://api.openai.com/v1/audio/translations');

  //   var request = http.MultipartRequest('POST', uri);
  //   request.headers[HttpHeaders.authorizationHeader] = 'Bearer $openaiApiKey';

  //   var multipartFile = await http.MultipartFile.fromPath('file', filePath,
  //       contentType: MediaType('audio', 'mpeg'));

  //   request.fields['model'] = model;
  //   request.files.add(multipartFile);

  //   try {
  //     var streamedResponse = await request.send();
  //     var response = await http.Response.fromStream(streamedResponse);

  //     if (response.statusCode == 200) {
  //       var data = jsonDecode(response.body);
  //       print(data);
  //       // Extract and return the transcription from the response
  //       // Adjust this logic based on the actual structure of the response
  //       return data['translation'] ?? 'Translation not available';
  //     } else {
  //       throw Exception(
  //           'Failed to transcribe audio. Status code: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     throw Exception('Error during transcription: $e');
  //   }
  // }