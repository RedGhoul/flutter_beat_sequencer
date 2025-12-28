import 'dart:io';

import 'package:share_plus/share_plus.dart';

/// Service for exporting beat patterns to MP3 files.
///
/// MP3 export is currently disabled because the ffmpeg-kit iOS artifacts
/// referenced by the Flutter plugin are no longer available.
class ExportService {
  bool get isExportAvailable => false;

  Future<String?> exportToMP3({
    required List<dynamic> tracks,
    required int totalBeats,
    required double bpm,
    required String fileName,
    bool includeMetronome = false,
    int loopCount = 1,
    int bitrate = 128,
    Function(double)? onProgress,
  }) async {
    return null;
  }

  /// Share the exported MP3 file
  Future<void> shareMP3(String filePath) async {
    try {
      final file = XFile(filePath);
      await Share.shareXFiles(
        [file],
        subject: 'Beat Pattern Export',
        text: 'Check out this beat I made!',
      );
    } catch (e) {
      print('Share error: $e');
      rethrow;
    }
  }

  /// Get a user-friendly file size string
  String getFileSize(String filePath) {
    try {
      final file = File(filePath);
      final bytes = file.lengthSync();

      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
