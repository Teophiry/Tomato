import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

class ApiService {
  final String baseUrl = "https://api.openai.com/v1";
  final String apiKey = "YOUR_API_KEY"; // Replace with your actual API key

  Future<String> sendImageToGPT4Vision(File image) async {
    final String base64Image = await encodeImage(image);
    try {
      final response = await Dio().post(
        "$baseUrl/chat/completions",
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode({
          'model': 'gpt-4-vision-preview',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                },
              ],
            },
          ],
        }),
      );
      return response.data["choices"][0]["message"]["content"];
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<String> encodeImage(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }
}
