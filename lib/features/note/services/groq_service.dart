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
  Output ONLY a valid JSON object: { "instructions": [{"target": "phrase", "key": "attr", "value": val, "occurrence": "all"|"first"|"last"|"second"}] }

  CRITICAL TARGET RULES:
  1. DEFINITIONS: 
     - "sentence" and "line" are equivalent. They end at a full-stop (.) or a newline (\n). Use "line:" prefix (e.g., "line:first", "line:1st").
     - "paragraph" refers to contiguous blocks of text separated by blank lines (empty space). Use "paragraph:" prefix (e.g., "paragraph:2nd", "paragraph:last").
  2. SELECTION: If the user says "this", "that", "it", or "selected text", set target: "selection".
  3. POSITION TARGETING: Use ordinal keys like "1st", "2nd", "3rd", "last", "bottom".
  4. TARGET ISOLATION: Otherwise, use the literal phrase from the text (e.g., "Menu items", "Dog").
  5. NO DUPLICATE LISTS: If the user asks for a specific list type (numbered, checkbox, bullets), ONLY send that ONE instruction. NEVER stack list types.
  6. NO VERBS: Strip command verbs ("make", "set", "change") but keep the core target text.
  7. CLEARING (TOP PRIORITY): If the user says "clear formatting", "remove styles", or "clear all", ALWAYS output EXACTLY: { "instructions": [{"target": "all", "key": "unformat_all", "value": true, "occurrence": "all"}] }

  FEATURE RULES:
  1. Styles: "bold", "italic", "underline", "strike" -> boolean true.
  2. Colors: Key "color", value is a hex code (e.g., "#FF0000"). Use this for ANY color command.
  3. Size: "big" -> size_change: 5, "small" -> size_change: -5. Exact sizes (e.g., "20 pixel") -> key: "size", value: 20.
  4. Alignments: "align" -> "left", "right", or "center".
  5. Lists: "list" -> "bullet", "ordered", or "unchecked".
  6. Links: "link" -> value is the URL string (e.g., "google.com").
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
