import 'package:flutter_test/flutter_test.dart';
import 'package:notepad/features/search/services/semantic_taxonomy.dart';

void main() {
  group('SemanticTaxonomy', () {
    test('defaultTopics contains clean, distinct topic categories', () {
      final topics = SemanticTaxonomy.defaultTopics;

      expect(topics, isNotEmpty);
      expect(topics.length, greaterThanOrEqualTo(10));

      // Verify no duplicates
      final unique = topics.toSet();
      expect(unique.length, equals(topics.length));

      // Verify key domain categories are included
      expect(topics, contains('Software & Programming'));
      expect(topics, contains('Fitness & Workout'));
      expect(topics, contains('Personal Finance & Bills'));
      expect(topics, contains('Food & Recipes'));
    });
  });
}
