import 'dart:math';

//Every note will have its unique ID
String generateNoteId() {
  final timestamp = DateTime.now()
      .microsecondsSinceEpoch; //gives the current time as a huge integer measured in microseconds
  final random = Random().nextInt(
    1 << 32,
  ); //generates a random number from 0 up to 2^32 - 1
  return 'note_${timestamp}_$random';
}

///NotesSection creates notes
class NotesSection {
  NotesSection({
    String? id,
    required this.title,
    this.content = '',
    this.richContent = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.isSelected = false,
    this.isPinned = false,
  }) : id = id ?? generateNoteId(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final String id;
  String title;
  String content;
  String richContent;
  DateTime createdAt;
  DateTime updatedAt;
  bool isDeleted;
  bool isSelected;
  bool isPinned;

  //Stores notes in Storage in JSON format
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'richContent': richContent,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isDeleted': isDeleted,
    'isPinned': isPinned,
  };

  //Retrieve notes from Storage in JSON -> Processes it -> returns a NoteSection
  factory NotesSection.fromJson(Map<String, dynamic> json) => NotesSection(
    id: json['id'] as String?,
    title: (json['title'] ?? '') as String,
    content: (json['content'] ?? '') as String,
    richContent: (json['richContent'] ?? '') as String,
    createdAt: _parseDateTime(json['createdAt']),
    updatedAt:
        _parseDateTime(json['updatedAt']) ?? _parseDateTime(json['createdAt']),
    isDeleted: json['isDeleted'] ?? false,
    isPinned: json['isPinned'] ?? false,
  );
}

// Parsing unknown JSON data safely.
DateTime? _parseDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}

class AppSettings {
  final bool isDarkMode;
  const AppSettings({this.isDarkMode = false});

  Map<String, dynamic> toJson() => {'isDarkMode': isDarkMode};

  //Retrieves Appsettings from memory - builds a new instance of AppSettings
  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      AppSettings(isDarkMode: json['isDarkMode'] ?? false);
      
  // Another new version of AppSettings that only updates the fields - preserves anything unchanged
  AppSettings copyWith({bool? isDarkMode}) {
    return AppSettings(isDarkMode: isDarkMode ?? this.isDarkMode);
  }
}
