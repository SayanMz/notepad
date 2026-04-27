import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  // Groq's OpenAI-compatible endpoint
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Sends the voice string to Groq and asks for a strict JSON formatting map.
  static Future<List<Map<String, dynamic>>?> parseVoiceCommand(
    String voiceText,
  ) async {
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API Key is missing from .env file.');
      }

      const systemPrompt = """
  You are a text formatting engine for a Flutter app.
  Extract the target word/phrase and the desired formatting action.
  
  Respond ONLY with a valid JSON array of objects. 
  Allowed actions: "bold", "italic", "underline", "list_bullet", "color".
  
  COLOR RULES:
  If the user asks for a color, use action: "color" and add a "value" field 
  containing the appropriate Hex code (e.g., "#FF5733"). 
  You can interpret any color name (e.g., "Ocean Blue", "Forest Green", "Sunset Orange").
  
  Example Output: [{"target": "dogs", "action": "color", "value": "#F44336"}]
""";

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': voiceText},
          ],
          'temperature': 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawJsonText = data['choices'][0]['message']['content'];

        // THE FIX: Strip out the markdown backticks that crash jsonDecode
        rawJsonText = rawJsonText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        // 1. Decode to dynamic first so we can 'inspect' it
        final decoded = jsonDecode(rawJsonText);

        // 2. The Check: Is it a List [] or just a Map {}?
        if (decoded is List) {
          // Case A: AI gave us a List. We just cast it and return.
          return decoded.cast<Map<String, dynamic>>();
        } else if (decoded is Map) {
          // Case B: AI gave us a single Map.
          // We wrap it in [ ] to manually turn it into a List!
          return [decoded.cast<String, dynamic>()];
        }

        // Case C: Fallback if AI gave us a string or something else
        return null;
      } else {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('GroqService Crash: $e');
      rethrow; // Pass the error back to the UI!
    }
  }
}

/*
INTERVIEW NOTE:
"I used a hybrid architecture. Standard local logic wasn't semantically flexible enough to handle variations in human speech, 
and training an offline TFLite model would take weeks. So, I integrated the Groq API. I pass the raw speech to an LPU-accelerated LLaMA 3 model 
with a rigid system prompt, which instantly returns the semantic intent as a structured JSON array. My local Dart code then parses that JSON 
and interacts with the editor's block architecture."
*/
