import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  static Future<List<Map<String, dynamic>>?> parseVoiceCommand(
    String voiceText,
  ) async {
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) throw Exception('API Key missing.');

      const systemPrompt = """
  You are a JSON formatting engine for a Flutter app using flutter_quill.
  Output ONLY a valid JSON object: { "instructions": [{"target": "exact_word", "key": "attr_key", "value": val, "occurrence": "all"|"first"|"last"|"second"}] }

  CRITICAL TARGET RULES:
  1. EXTRACT THE NOUN: The "target" MUST ONLY be the specific text from the document. STRIP ALL command verbs/adjectives (e.g., "make", "change", "look", "big", "move", "color").
     - "make sayan look big" -> target: "sayan"
     - "change apple color to red" -> target: "apple"
     - "move last line to right" -> target: "line:last"
     - "make the first line bold" -> target: "line:0"
  2. IMPLICIT ALL: If the user says a general command without a specific target word (e.g., "change color", "make everything big", "align right"), set target: "all".
 3. NO CLEARING: NEVER output "unformat_all" unless the user explicitly says "clear formatting". If they do, ALWAYS output EXACTLY: { "instructions": [{"target": "all", "key": "unformat_all", "value": true, "occurrence": "all"}] }

  FEATURE RULES:
  1. Styles: "bold", "italic", "underline", "strike" -> value MUST be boolean true. Size -> key: "size", value: number. Increase -> key: "size_change", value: 10.
  2. Colors: key "color", value is a hex code (e.g. "#FF0000").
  3. Alignments: "align" key with values "right", "left", or "center".
  4. Lists: "list" key with values "bullet", "ordered", or "unchecked".
""";

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': voiceText},
          ],
          'temperature': 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final content = jsonDecode(
          response.body,
        )['choices'][0]['message']['content'];
        final decoded = jsonDecode(content);
        return decoded['instructions'] != null
            ? List<Map<String, dynamic>>.from(decoded['instructions'])
            : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
