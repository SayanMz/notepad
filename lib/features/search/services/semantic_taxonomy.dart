/// A clean, orthogonal taxonomy of topic categories.
/// Designed to prevent vector cannibalization and duplicate multi-label matches.
class SemanticTaxonomy {
  static const List<String> defaultTopics = [
    // Technology & Engineering
    'Software & Programming',
    'AI & Data Science',
    'Hardware & Electronics',

    // Entertainment & Media
    'Gaming',
    'Movies & Shows',
    'Books & Literature',
    'Music & Audio',

    // Work & Education
    'Academics & Study',
    'Career & Interviews',
    'Meeting Notes',
    'Projects & Ideas',

    // Finance & Home
    'Personal Finance & Bills',
    'Shopping & Wishlist',

    // Health & Living
    'Fitness & Workout',
    'Health & Medicine',
    'Food & Recipes',
    'Personal Journal',

    // Travel & Transit
    'Travel & Places',
    'Vehicles & Commuting',

    // Creative & Social
    'Creative Writing & Art',
    'Events & Social',
  ];
}
