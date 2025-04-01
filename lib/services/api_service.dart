import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://transapi-2sgz.onrender.com/translate_and_analyze'; // Ganti sama public_url kamu

  static Future<Map<String, dynamic>> translateAndAnalyze(String text, String src, String dest) async {
    final url = Uri.parse('$baseUrl/translate_and_analyze');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'src': src,
        'dest': dest,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal komunikasi ke server');
    }
  }
}
