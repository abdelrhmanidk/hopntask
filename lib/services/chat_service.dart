import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String _baseUrl = 'http://192.168.1.77:8007';  // Updated base URL

  Future<String> getResponse(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'];
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
} 