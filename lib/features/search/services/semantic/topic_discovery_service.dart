import 'package:flutter/foundation.dart';
import 'package:notepad/core/database/vector_storage.dart';
import '../semantic_taxonomy.dart';
import 'onnx_embedding_engine.dart';
import 'vector_math.dart';

/// Discovers candidate taxonomy topics and matches notes against topic vector embeddings.
class TopicDiscoveryService {
  static List<MapEntry<String, int>>? _cachedTopics;
  static final Map<String, List<String>> _topicNoteIdsCache = {};

  // Runtime vector cache for candidate taxonomy strings to avoid redundant neural passes.
  static final Map<String, Float32List> _topicVectorCache = {};
  static final List<String> _candidateTaxonomy = SemanticTaxonomy.defaultTopics;

  /// Clears in-memory topic suggestion and note ID caches.
  static void invalidateCache() {
    _cachedTopics = null;
    _topicNoteIdsCache.clear();
  }

  /// Computes or retrieves cached 384-d vector embedding for a taxonomy topic string.
  static Future<Float32List?> _getOrComputeTopicVector(String topic) async {
    Float32List? topicVector = _topicVectorCache[topic];
    if (topicVector == null) {
      final vecs = await OnnxEmbeddingEngine.generateDocumentEmbeddings(topic);
      if (vecs.isNotEmpty) {
        topicVector = vecs.first;
        _topicVectorCache[topic] = topicVector;
      }
    }
    return topicVector;
  }

  /// Evaluates candidate topics against active note vector embeddings and returns top qualified topic matches.
  static Future<List<MapEntry<String, int>>> discoverSuggestedTopics({
    required Set<String> activeNoteIds,
    int maxTopics = 6,
    double minSimilarity = 0.32,
  }) async {
    if (_cachedTopics != null && _cachedTopics!.isNotEmpty) {
      return _cachedTopics!;
    }
    if (!await OnnxEmbeddingEngine.isModelAvailable()) return [];
    await OnnxEmbeddingEngine.init();

    try {
      // Fetch all stored vector blobs from SQLite and parse Uint8List buffers into Float32List vectors.
      final allEmbeddings = await VectorStorageService.to.fetchAllEmbeddings();
      final activeEmbeddings = allEmbeddings
          .where((e) => activeNoteIds.contains(e['note_id'] as String))
          .toList();
      if (activeEmbeddings.isEmpty) return [];

      final List<Map<String, dynamic>> parsedEntries = activeEmbeddings.map((
        e,
      ) {
        final blob = e['embedding'] as Uint8List;
        return {
          'note_id': e['note_id'] as String,
          'vector': Uint8List.fromList(blob).buffer.asFloat32List(),
        };
      }).toList();

      final List<MapEntry<String, int>> qualifiedTopics = [];
      _topicNoteIdsCache.clear();

      // Cross-reference candidate taxonomy topic vectors against note chunk vectors using cosine similarity.
      for (final topic in _candidateTaxonomy) {
        final topicVector = await _getOrComputeTopicVector(topic);
        if (topicVector == null) continue;

        final Map<String, double> noteScores = {};

        for (final entry in parsedEntries) {
          final noteId = entry['note_id'] as String;
          final chunkVector = entry['vector'] as Float32List;

          final chunkScore = VectorMath.cosineSimilarity(
            topicVector,
            chunkVector,
          );
          if (chunkScore >= minSimilarity) {
            final currentBestScore = noteScores[noteId] ?? 0.0;
            if (chunkScore > currentBestScore) {
              noteScores[noteId] = chunkScore;
            }
          }
        }

        if (noteScores.isNotEmpty) {
          qualifiedTopics.add(MapEntry(topic, noteScores.length));
          final sortedNoteIds = noteScores.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          _topicNoteIdsCache[topic] = sortedNoteIds.map((e) => e.key).toList();
        }
      }

      // Cache top qualified topic matches and their corresponding note IDs sorted by similarity score.
      qualifiedTopics.sort((a, b) => b.value.compareTo(a.value));
      _cachedTopics = qualifiedTopics.take(maxTopics).toList();
      return _cachedTopics!;
    } catch (e) {
      debugPrint('TopicDiscoveryService: Discovery error: $e');
      return [];
    }
  }

  /// Retrieves note IDs matching a specific topic string, filtered by optional date boundaries.
  static Future<List<String>> getNoteIdsForTopic(
    String topic, {
    DateTime? start,
    DateTime? end,
    double minSimilarity = 0.32,
  }) async {
    if (start == null && end == null) {
      final cachedIds = _topicNoteIdsCache[topic];
      if (cachedIds != null && cachedIds.isNotEmpty) return cachedIds;
    }

    if (!await OnnxEmbeddingEngine.isModelAvailable()) return [];
    await OnnxEmbeddingEngine.init();

    try {
      final topicVector = await _getOrComputeTopicVector(topic);
      if (topicVector == null) return [];

      final candidates = await VectorStorageService.to.fetchAllEmbeddings(
        start: start,
        end: end,
      );

      final Map<String, double> noteBestScores = {};

      for (final entry in candidates) {
        final noteId = entry['note_id'] as String;
        final blob = entry['embedding'] as Uint8List;
        final chunkVector = Uint8List.fromList(blob).buffer.asFloat32List();

        final chunkScore = VectorMath.cosineSimilarity(
          topicVector,
          chunkVector,
        );
        if (chunkScore >= minSimilarity) {
          final currentBestScore = noteBestScores[noteId] ?? 0.0;
          if (chunkScore > currentBestScore) {
            noteBestScores[noteId] = chunkScore;
          }
        }
      }

      final sorted = noteBestScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final resultIds = sorted.map((e) => e.key).toList();

      if (start == null && end == null && resultIds.isNotEmpty) {
        _topicNoteIdsCache[topic] = resultIds;
      }
      return resultIds;
    } catch (e) {
      debugPrint('TopicDiscoveryService: getNoteIdsForTopic error: $e');
      return [];
    }
  }
}
