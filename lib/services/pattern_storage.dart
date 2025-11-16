import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Model for a saved pattern
class SavedPattern {
  final String id;
  final String name;
  final double bpm;
  final bool metronomeOn;
  final int totalBeats;
  final List<SavedTrack> tracks;
  final DateTime savedAt;

  SavedPattern({
    required this.id,
    required this.name,
    required this.bpm,
    required this.metronomeOn,
    required this.totalBeats,
    required this.tracks,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bpm': bpm,
      'metronomeOn': metronomeOn,
      'totalBeats': totalBeats,
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory SavedPattern.fromJson(Map<String, dynamic> json) {
    return SavedPattern(
      id: json['id'] as String,
      name: json['name'] as String,
      bpm: (json['bpm'] as num).toDouble(),
      metronomeOn: json['metronomeOn'] as bool,
      totalBeats: json['totalBeats'] as int,
      tracks: (json['tracks'] as List)
          .map((t) => SavedTrack.fromJson(t as Map<String, dynamic>))
          .toList(),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}

/// Model for a saved track
class SavedTrack {
  final String soundKey;
  final String displayName;
  final List<bool> pattern;

  SavedTrack({
    required this.soundKey,
    required this.displayName,
    required this.pattern,
  });

  Map<String, dynamic> toJson() {
    return {
      'soundKey': soundKey,
      'displayName': displayName,
      'pattern': pattern,
    };
  }

  factory SavedTrack.fromJson(Map<String, dynamic> json) {
    return SavedTrack(
      soundKey: json['soundKey'] as String,
      displayName: json['displayName'] as String,
      pattern: (json['pattern'] as List).cast<bool>(),
    );
  }
}

/// Metadata for a saved pattern (for quick listing)
class PatternMetadata {
  final String id;
  final String name;
  final DateTime savedAt;

  PatternMetadata({
    required this.id,
    required this.name,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory PatternMetadata.fromJson(Map<String, dynamic> json) {
    return PatternMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}

/// Service for saving and loading patterns to/from local storage
class PatternStorage {
  static const String _metadataKey = 'pattern_metadata_list';
  static const String _patternPrefix = 'pattern_';

  /// Save a pattern to local storage
  Future<void> savePattern(SavedPattern pattern) async {
    final prefs = await SharedPreferences.getInstance();

    // Save the pattern data
    final patternKey = '$_patternPrefix${pattern.id}';
    final patternJson = jsonEncode(pattern.toJson());
    await prefs.setString(patternKey, patternJson);

    // Update metadata list
    final metadata = PatternMetadata(
      id: pattern.id,
      name: pattern.name,
      savedAt: pattern.savedAt,
    );
    await _addToMetadataList(prefs, metadata);
  }

  /// Load a pattern from local storage by ID
  Future<SavedPattern?> loadPattern(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final patternKey = '$_patternPrefix$id';
    final patternJson = prefs.getString(patternKey);

    if (patternJson == null) {
      return null;
    }

    final Map<String, dynamic> json = jsonDecode(patternJson);
    return SavedPattern.fromJson(json);
  }

  /// Delete a pattern from local storage
  Future<void> deletePattern(String id) async {
    final prefs = await SharedPreferences.getInstance();

    // Delete the pattern data
    final patternKey = '$_patternPrefix$id';
    await prefs.remove(patternKey);

    // Update metadata list
    await _removeFromMetadataList(prefs, id);
  }

  /// Get list of all saved pattern metadata (for UI listing)
  Future<List<PatternMetadata>> getPatternMetadataList() async {
    final prefs = await SharedPreferences.getInstance();
    final metadataJson = prefs.getString(_metadataKey);

    if (metadataJson == null) {
      return [];
    }

    final List<dynamic> jsonList = jsonDecode(metadataJson);
    return jsonList
        .map((json) => PatternMetadata.fromJson(json as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt)); // Most recent first
  }

  /// Add a pattern to the metadata list
  Future<void> _addToMetadataList(
      SharedPreferences prefs, PatternMetadata metadata) async {
    final metadataJson = prefs.getString(_metadataKey);
    List<PatternMetadata> metadataList = [];

    if (metadataJson != null) {
      final List<dynamic> jsonList = jsonDecode(metadataJson);
      metadataList = jsonList
          .map((json) => PatternMetadata.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    // Remove existing entry with same ID (in case of overwrite)
    metadataList.removeWhere((m) => m.id == metadata.id);

    // Add new entry
    metadataList.add(metadata);

    // Save updated list
    final updatedJson =
        jsonEncode(metadataList.map((m) => m.toJson()).toList());
    await prefs.setString(_metadataKey, updatedJson);
  }

  /// Remove a pattern from the metadata list
  Future<void> _removeFromMetadataList(
      SharedPreferences prefs, String id) async {
    final metadataJson = prefs.getString(_metadataKey);

    if (metadataJson == null) {
      return;
    }

    final List<dynamic> jsonList = jsonDecode(metadataJson);
    final metadataList = jsonList
        .map((json) => PatternMetadata.fromJson(json as Map<String, dynamic>))
        .toList();

    // Remove entry with matching ID
    metadataList.removeWhere((m) => m.id == id);

    // Save updated list
    final updatedJson =
        jsonEncode(metadataList.map((m) => m.toJson()).toList());
    await prefs.setString(_metadataKey, updatedJson);
  }

  /// Generate a unique ID for a new pattern
  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
