import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notepad/features/search/services/semantic/onnx_embedding_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('onnx_engine_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          switch (call.method) {
            case 'getApplicationDocumentsDirectory':
            case 'getTemporaryDirectory':
              return tempDir.path;
            default:
              return null;
          }
        });
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  group('OnnxEmbeddingEngine', () {
    test('isModelAvailable returns false when local ONNX model file does not exist', () async {
      final available = await OnnxEmbeddingEngine.isModelAvailable();
      expect(available, isFalse);
    });

    test('getLocalModelFiles returns map with model and vocab File references', () async {
      final files = await OnnxEmbeddingEngine.getLocalModelFiles();
      expect(files.containsKey('model'), isTrue);
      expect(files.containsKey('vocab'), isTrue);
    });
  });
}
