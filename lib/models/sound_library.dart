class SoundInfo {
  final String key;
  final String displayName;
  final String category;
  final String assetPath;

  const SoundInfo({
    required this.key,
    required this.displayName,
    required this.category,
    required this.assetPath,
  });
}

class SoundLibrary {
  static const List<SoundInfo> builtInSounds = [
    // Kicks
    SoundInfo(
      key: 'kick_1',
      displayName: 'Kick 1',
      category: 'Kicks',
      assetPath: 'assets/sounds/kick_1.wav',
    ),
    SoundInfo(
      key: 'kick_2',
      displayName: 'Kick 2',
      category: 'Kicks',
      assetPath: 'assets/sounds/kick_2.wav',
    ),

    // Snares
    SoundInfo(
      key: 'snare_1',
      displayName: 'Snare 1',
      category: 'Snares',
      assetPath: 'assets/sounds/snare_1.wav',
    ),
    SoundInfo(
      key: 'snare_2',
      displayName: 'Snare 2',
      category: 'Snares',
      assetPath: 'assets/sounds/snare_2.wav',
    ),

    // Hi-Hats
    SoundInfo(
      key: 'hat',
      displayName: 'Hat',
      category: 'Hi-Hats',
      assetPath: 'assets/sounds/hat_3.wav',
    ),
    SoundInfo(
      key: 'open_hat',
      displayName: 'Open Hat',
      category: 'Hi-Hats',
      assetPath: 'assets/sounds/open_hat.wav',
    ),

    // Percussion
    SoundInfo(
      key: 'clap',
      displayName: 'Clap',
      category: 'Percussion',
      assetPath: 'assets/sounds/clap_2.wav',
    ),

    // Bass
    SoundInfo(
      key: 'bass',
      displayName: '808',
      category: 'Bass',
      assetPath: 'assets/sounds/bass.wav',
    ),
  ];

  static Map<String, List<SoundInfo>> getSoundsByCategory() {
    final Map<String, List<SoundInfo>> categorized = {};

    for (final sound in builtInSounds) {
      if (!categorized.containsKey(sound.category)) {
        categorized[sound.category] = [];
      }
      categorized[sound.category]!.add(sound);
    }

    return categorized;
  }

  static SoundInfo? getSoundByKey(String key) {
    try {
      return builtInSounds.firstWhere((sound) => sound.key == key);
    } catch (e) {
      return null;
    }
  }
}
