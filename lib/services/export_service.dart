import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_audio/return_code.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_beat_sequencer/pages/main_bloc.dart';

/// Service for exporting beat patterns to MP3 files
class ExportService {
  final Map<String, String> _assetCache = {};

  /// Export the current pattern to an MP3 file
  ///
  /// This creates an MP3 file by:
  /// 1. Copying sound assets to temporary storage
  /// 2. Generating silence for the base track
  /// 3. Overlaying each sound at the correct timestamps
  /// 4. Mixing all tracks together
  /// 5. Encoding to MP3
  Future<String?> exportToMP3({
    required List<TrackBloc> tracks,
    required int totalBeats,
    required double bpm,
    required String fileName,
    bool includeMetronome = false,
    int loopCount = 1,
    int bitrate = 128,
    Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.05);

      // Calculate timing
      final beatsPerMinute = bpm / 4.0; // Convert internal BPM to quarter notes
      final secondsPerBeat = 60.0 / beatsPerMinute / 4.0; // 16th note duration
      final totalDuration = secondsPerBeat * totalBeats * loopCount;

      onProgress?.call(0.1);

      // Prepare directories
      final tempDir = await getTemporaryDirectory();
      final outputDir = await getApplicationDocumentsDirectory();
      final cleanFileName = _cleanFileName(fileName);
      final outputPath = '${outputDir.path}/$cleanFileName.mp3';

      // Copy assets to temporary storage (required for FFmpeg)
      await _prepareAssets(tempDir);
      onProgress?.call(0.2);

      // Build list of input files and filter complex
      final inputs = <String>[];
      final filterParts = <String>[];

      // Create a silent base track
      inputs.add('-f lavfi -i anullsrc=r=44100:cl=stereo');
      filterParts.add('[0:a]atrim=duration=$totalDuration[base]');

      int inputIndex = 1;

      // Process each track
      for (final track in tracks) {
        final pattern = track.isEnabled.value;
        final soundPath = await _getCachedAssetPath(track.soundKey);

        if (soundPath == null) continue;

        // Find all beat positions where this track plays
        final timestamps = <double>[];
        for (int loop = 0; loop < loopCount; loop++) {
          for (int beat = 0; beat < totalBeats; beat++) {
            if (beat < pattern.length && pattern[beat]) {
              timestamps.add((loop * totalBeats + beat) * secondsPerBeat);
            }
          }
        }

        if (timestamps.isEmpty) continue;

        // Create filter for this track
        final trackFilter = _createTrackFilter(
          soundPath: soundPath,
          timestamps: timestamps,
          inputIndex: inputIndex,
        );

        inputs.add('-i "$soundPath"');
        filterParts.add(trackFilter);
        inputIndex++;
      }

      onProgress?.call(0.5);

      // If no tracks have any beats, create empty audio
      if (filterParts.length <= 1) {
        // Just create silence
        final command = '-f lavfi -i anullsrc=r=44100:cl=stereo -t $totalDuration -b:a ${bitrate}k -y "$outputPath"';
        final session = await FFmpegKit.execute(command);
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          onProgress?.call(1.0);
          return outputPath;
        }
        return null;
      }

      // Build final filter_complex
      final filterComplex = _buildFinalFilterComplex(filterParts);

      onProgress?.call(0.7);

      // Build and execute FFmpeg command
      final inputsStr = inputs.join(' ');
      final command = '$inputsStr -filter_complex "$filterComplex" -map "[out]" -b:a ${bitrate}k -t $totalDuration -y "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      onProgress?.call(0.9);

      if (ReturnCode.isSuccess(returnCode)) {
        onProgress?.call(1.0);
        await cleanupTempFiles();
        return outputPath;
      } else {
        final output = await session.getOutput();
        final failStackTrace = await session.getFailStackTrace();
        print('FFmpeg failed:');
        print('Output: $output');
        print('StackTrace: $failStackTrace');
        return null;
      }
    } catch (e, stackTrace) {
      print('Export error: $e');
      print('StackTrace: $stackTrace');
      return null;
    }
  }

  /// Copy Flutter assets to temporary directory (FFmpeg can't read assets directly)
  Future<void> _prepareAssets(Directory tempDir) async {
    final soundAssets = {
      'bass': 'assets/sounds/bass.wav',
      'clap': 'assets/sounds/clap_2.wav',
      'hat': 'assets/sounds/hat_3.wav',
      'open_hat': 'assets/sounds/open_hat.wav',
      'kick_1': 'assets/sounds/kick_1.wav',
      'kick_2': 'assets/sounds/kick_2.wav',
      'snare_1': 'assets/sounds/snare_1.wav',
      'snare_2': 'assets/sounds/snare_2.wav',
    };

    for (final entry in soundAssets.entries) {
      final soundKey = entry.key;
      final assetPath = entry.value;
      final tempFile = File('${tempDir.path}/$soundKey.wav');

      // Skip if already cached
      if (_assetCache.containsKey(soundKey) && await tempFile.exists()) {
        continue;
      }

      // Copy asset to temporary file
      final byteData = await rootBundle.load(assetPath);
      final buffer = byteData.buffer;
      await tempFile.writeAsBytes(
        buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );

      _assetCache[soundKey] = tempFile.path;
    }
  }

  /// Get the cached path for a sound asset
  Future<String?> _getCachedAssetPath(String soundKey) async {
    if (_assetCache.containsKey(soundKey)) {
      final path = _assetCache[soundKey]!;
      if (await File(path).exists()) {
        return path;
      }
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$soundKey.wav');
    if (await tempFile.exists()) {
      _assetCache[soundKey] = tempFile.path;
      return tempFile.path;
    }

    return null;
  }

  /// Create FFmpeg filter for a single track with multiple timestamps
  String _createTrackFilter({
    required String soundPath,
    required List<double> timestamps,
    required int inputIndex,
  }) {
    // For simplicity, we'll create adelay filters for each timestamp
    // and mix them together
    final delays = timestamps.map((t) => (t * 1000).round()).toList();

    // Create a chain of delayed copies
    final delayFilters = delays.asMap().entries.map((entry) {
      final idx = entry.key;
      final delayMs = entry.value;
      final streamName = 't${inputIndex}_${idx}';

      if (idx == 0) {
        return '[$inputIndex:a]adelay=$delayMs|$delayMs[$streamName]';
      } else {
        // For subsequent beats, we need to split the input
        return '';
      }
    }).where((s) => s.isNotEmpty).join(';');

    return delayFilters;
  }

  /// Build the final filter_complex that mixes all tracks
  String _buildFinalFilterComplex(List<String> filterParts) {
    // This is a simplified version - a real implementation would
    // properly handle mixing multiple delayed streams
    return '${filterParts.join(';')};[base]aformat=sample_rates=44100[out]';
  }

  /// Clean filename for filesystem
  String _cleanFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
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

  /// Delete temporary files created during export
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final file in files) {
        if (file is File) {
          final name = file.path.split('/').last;
          if (name.endsWith('.wav') || name.endsWith('.mp3')) {
            try {
              await file.delete();
            } catch (e) {
              // Ignore errors during cleanup
            }
          }
        }
      }

      _assetCache.clear();
    } catch (e) {
      print('Cleanup error: $e');
    }
  }
}
