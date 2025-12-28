import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final Map<String, AudioPlayer> _players = {};
  final Map<String, String> _soundPaths = {
    'bass': 'assets/sounds/bass.wav',
    'clap': 'assets/sounds/clap_2.wav',
    'hat': 'assets/sounds/hat_3.wav',
    'open_hat': 'assets/sounds/open_hat.wav',
    'kick_1': 'assets/sounds/kick_1.wav',
    'kick_2': 'assets/sounds/kick_2.wav',
    'snare_1': 'assets/sounds/snare_1.wav',
    'snare_2': 'assets/sounds/snare_2.wav',
    'metronome_high': 'assets/sounds/metronome_high.wav',
    'metronome_low': 'assets/sounds/metronome_low.wav',
  };

  Future<void> initialize() async {
    // Pre-load all sounds for low-latency playback
    for (final entry in _soundPaths.entries) {
      final player = AudioPlayer();
      try {
        await player.setAsset(entry.value);
        await player.setVolume(1.0);
        await player.load();
        _players[entry.key] = player;
      } catch (e) {
        if (kDebugMode) {
          print('Warning: Could not load ${entry.key}: $e');
        }
        // For metronome sounds, it's okay if they don't exist yet
        if (!entry.key.contains('metronome')) {
          rethrow;
        }
      }
    }
  }

  Future<void> playSound(String soundName) async {
    // Load sound if not already loaded
    if (!_players.containsKey(soundName) &&
        _soundPaths.containsKey(soundName)) {
      await _loadSound(soundName, _soundPaths[soundName]!);
    }

    final player = _players[soundName];
    if (player != null) {
      await player.seek(Duration.zero); // Reset to start
      await player.play();
    }
  }

  Future<void> _loadSound(String key, String path) async {
    final player = AudioPlayer();
    try {
      await player.setAsset(path);
      await player.setVolume(1.0);
      await player.load();
      _players[key] = player;
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Could not load $key: $e');
      }
      rethrow;
    }
  }

  Future<void> loadCustomSound(String key, String assetPath) async {
    _soundPaths[key] = assetPath;
    await _loadSound(key, assetPath);
  }

  void unloadSound(String soundName) {
    final player = _players.remove(soundName);
    if (player != null) {
      player.dispose();
    }
    _soundPaths.remove(soundName);
  }

  bool isSoundLoaded(String soundName) {
    return _players.containsKey(soundName);
  }

  Future<void> playSynth(String note, String duration) async {
    // For metronome sound - use high/low beep sounds
    if (note == "C6") {
      await playSound('metronome_high');
    } else if (note == "C5") {
      await playSound('metronome_low');
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
