# Mobile Adaptation Implementation Plan
## Flutter Beat Sequencer - Mobile-Only Version

---

## OVERVIEW

This beat sequencer app currently requires 1500px+ width and uses web-only JavaScript audio libraries. This plan transforms it into a **mobile-first, mobile-only** application optimized for phones (375-430px portrait screens).

**Current State:**
- 396 lines of Dart code across 5 files
- Web-first with Howler.js/Tone.js audio
- Fixed horizontal layout (1500px+ width)
- 32×32px buttons (too small for touch)
- Desktop/web optimized

**Target State:**
- **Mobile-only application**
- Native Flutter audio (Android/iOS)
- Portrait-optimized UI (375px+ width)
- 48×48px touch targets
- Vertical scrolling with pagination
- Swipe gestures for navigation

---

## IMPLEMENTATION STEPS

### PHASE 1: AUDIO SYSTEM REPLACEMENT

#### Step 1.1: Add Audio Dependencies
**File:** `pubspec.yaml`

**Action:** Add native audio plugin dependency

```yaml
dependencies:
  flutter:
    sdk: flutter
  bird: ^0.0.2
  bird_flutter: ^0.0.2+1
  modulovalue_project_widgets:
    git: git://github.com/modulovalue/modulovalue_project_widgets.git
  just_audio: ^0.9.36                    # ADD THIS LINE
```

**Why:** `just_audio` is a cross-platform audio plugin that works on Android and iOS. It replaces web-only Howler.js.

**Command to run:**
```bash
flutter pub get
```

---

#### Step 1.2: Create Audio Service Abstraction
**File:** `lib/services/audio_service.dart` (NEW FILE)

**Action:** Create a new audio service that abstracts audio playback

```dart
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
  };

  Future<void> initialize() async {
    // Pre-load all sounds for low-latency playback
    for (final entry in _soundPaths.entries) {
      final player = AudioPlayer();
      await player.setAsset(entry.value);
      await player.setVolume(1.0);
      await player.load();
      _players[entry.key] = player;
    }
  }

  Future<void> playSound(String soundName) async {
    final player = _players[soundName];
    if (player != null) {
      await player.seek(Duration.zero); // Reset to start
      await player.play();
    }
  }

  Future<void> playSynth(String note, String duration) async {
    // For metronome sound - use a simple beep or load a synth sample
    // Option 1: Use a pre-recorded beep sound
    // Option 2: Generate tone programmatically (requires additional package)
    // For simplicity, we'll use a short beep sound
    if (kDebugMode) {
      print('Metronome: $note for $duration');
    }
    // TODO: Add metronome sound file and play it here
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
```

**Why:** This abstraction layer:
- Separates audio logic from UI/state management
- Pre-loads sounds for fast playback (critical for rhythm accuracy)
- Works on mobile platforms
- Easy to test and swap implementations

---

#### Step 1.3: Update Main Bloc to Use Audio Service
**File:** `lib/pages/main_bloc.dart`

**Action:** Replace JavaScript audio calls with AudioService

**Changes needed:**

1. **Remove JS import** (line 1):
```dart
// DELETE THIS LINE:
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
```

2. **Add AudioService import** (add after other imports):
```dart
import '../services/audio_service.dart';
```

3. **Add AudioService to PlaybackBloc** (around line 40-50):
```dart
class PlaybackBloc extends HookBloc implements Playable {
  final AudioService audioService; // ADD THIS FIELD

  PlaybackBloc(this.audioService) { // UPDATE CONSTRUCTOR
    tracks = [
      TrackBloc(
        name: "808",
        sound: Sound(
          name: "bass",
          play: () {
            audioService.playSound('bass'); // REPLACE: js.context["bass"].callMethod("play");
          },
        ),
      ),
      // ... continue for other tracks
    ];
  }
```

4. **Update all 8 TrackBloc sound definitions** (lines 47-114):

Replace each `js.context["xxx"].callMethod("play")` with `audioService.playSound('xxx')`:

```dart
// Track 2 - Clap
TrackBloc(
  name: "Clap",
  sound: Sound(
    name: "clap",
    play: () {
      audioService.playSound('clap'); // CHANGE THIS LINE
    },
  ),
),

// Track 3 - Hat
TrackBloc(
  name: "Hat",
  sound: Sound(
    name: "hat",
    play: () {
      audioService.playSound('hat'); // CHANGE THIS LINE
    },
  ),
),

// Track 4 - Open Hat
TrackBloc(
  name: "Open Hat",
  sound: Sound(
    name: "open_hat",
    play: () {
      audioService.playSound('open_hat'); // CHANGE THIS LINE
    },
  ),
),

// Track 5 - Kick 1
TrackBloc(
  name: "Kick 1",
  sound: Sound(
    name: "kick_1",
    play: () {
      audioService.playSound('kick_1'); // CHANGE THIS LINE
    },
  ),
),

// Track 6 - Kick 2
TrackBloc(
  name: "Kick 2",
  sound: Sound(
    name: "kick_2",
    play: () {
      audioService.playSound('kick_2'); // CHANGE THIS LINE
    },
  ),
),

// Track 7 - Snare 1
TrackBloc(
  name: "Snare 1",
  sound: Sound(
    name: "snare_1",
    play: () {
      audioService.playSound('snare_1'); // CHANGE THIS LINE
    },
  ),
),

// Track 8 - Snare 2
TrackBloc(
  name: "Snare 2",
  sound: Sound(
    name: "snare_2",
    play: () {
      audioService.playSound('snare_2'); // CHANGE THIS LINE
    },
  ),
),
```

5. **Update metronome playback** (around line 122):
```dart
playAtBeat: (i) {
  if (i % 16 == 0) {
    audioService.playSynth("C6", "32n"); // REPLACE js.context call
  }
  if (i % 4 == 0) {
    audioService.playSynth("C5", "32n"); // REPLACE js.context call
  }
},
```

**Why:** This removes the web dependency and uses our cross-platform audio service.

---

#### Step 1.4: Initialize Audio Service in Main
**File:** `lib/main.dart`

**Action:** Initialize audio service before running app and show loading screen

**Complete replacement of main.dart:**

```dart
import 'package:flutter/material.dart';
import 'package:bird_flutter/bird_flutter.dart';
import 'services/audio_service.dart';
import 'pages/mobile_layout.dart';
import 'pages/main_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(LoadingApp());
}

class LoadingApp extends StatefulWidget {
  @override
  State<LoadingApp> createState() => _LoadingAppState();
}

class _LoadingAppState extends State<LoadingApp> {
  AudioService? _audioService;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      final audioService = AudioService();
      await audioService.initialize();
      setState(() {
        _audioService = audioService;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: Colors.brown[900],
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.amber),
                SizedBox(height: 16),
                Text('Loading sounds...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Scaffold(
          backgroundColor: Colors.brown[900],
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('Error: $_error', style: TextStyle(color: Colors.white)),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _initializeAudio();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MyApp(audioService: _audioService!);
  }
}

class MyApp extends StatelessWidget {
  final AudioService audioService;

  const MyApp({Key? key, required this.audioService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: MyHomePage(audioService: audioService),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final AudioService audioService;

  const MyHomePage({Key? key, required this.audioService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return $$ >> (context) {
      final bloc = HookBloc.useMemo(
        () => PlaybackBloc(audioService),
        [],
      );

      HookBloc.useDispose(bloc);

      return MobileSequencerLayout(bloc: bloc);
    };
  }
}
```

**Why:**
- Shows loading screen while audio initializes
- Handles errors gracefully with retry option
- Completely replaces desktop layout with mobile-only version
- Clean separation of concerns

---

#### Step 1.5: Add Metronome Sound Asset
**File:** Create `assets/sounds/metronome_high.wav` and `assets/sounds/metronome_low.wav`

**Action:**
1. Generate or download two short beep sounds (high pitch for bar, low pitch for beat)
2. Place in `assets/sounds/` directory
3. Update `audio_service.dart` to include these sounds

**Update `AudioService._soundPaths`:**
```dart
final Map<String, String> _soundPaths = {
  'bass': 'assets/sounds/bass.wav',
  'clap': 'assets/sounds/clap_2.wav',
  'hat': 'assets/sounds/hat_3.wav',
  'open_hat': 'assets/sounds/open_hat.wav',
  'kick_1': 'assets/sounds/kick_1.wav',
  'kick_2': 'assets/sounds/kick_2.wav',
  'snare_1': 'assets/sounds/snare_1.wav',
  'snare_2': 'assets/sounds/snare_2.wav',
  'metronome_high': 'assets/sounds/metronome_high.wav', // ADD
  'metronome_low': 'assets/sounds/metronome_low.wav',   // ADD
};
```

**Update `playSynth` method:**
```dart
Future<void> playSynth(String note, String duration) async {
  if (note == "C6") {
    await playSound('metronome_high');
  } else if (note == "C5") {
    await playSound('metronome_low');
  }
}
```

**Why:** Replaces Tone.js synthesizer with pre-recorded sounds (simpler and more reliable).

**Alternative:** If you can't find/create these sounds, you can skip metronome temporarily and leave `playSynth` empty.

---

### PHASE 2: MOBILE UI IMPLEMENTATION

#### Step 2.1: Create Mobile Track Widget
**File:** `lib/widgets/mobile_track_row.dart` (NEW FILE)

**Action:** Create mobile-optimized track widget with touch targets

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bird_flutter/bird_flutter.dart';
import '../pages/main_bloc.dart';
import '../pages/pattern.dart';

class MobileTrackRow extends StatelessWidget {
  final TrackBloc track;
  final int currentBeat;
  final int startBeat;
  final int endBeat;

  const MobileTrackRow({
    Key? key,
    required this.track,
    required this.currentBeat,
    required this.startBeat,
    required this.endBeat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const buttonSize = 48.0; // Material Design minimum touch target
    const spacing = 4.0;

    return Row(
      children: [
        // Track label (only show on first segment)
        if (startBeat == 0) ...[
          SizedBox(
            width: 60,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                track.sound.play();
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.brown[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    track.name,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: spacing),
        ] else ...[
          SizedBox(width: 60 + spacing),
        ],

        // Beat steps for this segment
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              endBeat - startBeat,
              (index) {
                final beatIndex = startBeat + index;
                return TrackStep(
                  size: buttonSize,
                  enabled: track.isEnabled.value[beatIndex],
                  active: currentBeat == beatIndex,
                  onPressed: () => track.toggle(beatIndex),
                );
              },
            ),
          ),
        ),

        // Pattern button (only show on first segment)
        if (startBeat == 0) ...[
          SizedBox(width: spacing),
          SizedBox(
            width: 50,
            height: buttonSize,
            child: ElevatedButton(
              onPressed: () => _showPatternMenu(context, track),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.brown[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Icon(Icons.more_horiz, size: 24, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  void _showPatternMenu(BuildContext context, TrackBloc track) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.brown[800],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.brown[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Select Pattern for ${track.name}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            ...Pattern.patterns.map((pattern) => ListTile(
              title: Text(pattern.name, style: TextStyle(color: Colors.white)),
              leading: Icon(Icons.graphic_eq, color: Colors.amber),
              onTap: () {
                HapticFeedback.selectionClick();
                track.setPattern(pattern.pattern);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}

class TrackStep extends StatelessWidget {
  final double size;
  final bool enabled;
  final bool active;
  final VoidCallback onPressed;

  const TrackStep({
    Key? key,
    required this.size,
    required this.enabled,
    required this.active,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPressed();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: enabled
              ? Colors.amber
              : (active ? Colors.blue.withOpacity(0.5) : Colors.brown[800]),
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(
            color: active ? Colors.white : Colors.transparent,
            width: active ? 3 : 0,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}
```

**Why:**
- 48px touch targets (Material Design compliant)
- Haptic feedback on every interaction
- Visual glow on enabled beats
- Mobile-friendly bottom sheet for patterns
- Clean, modern Material Design aesthetics

---

#### Step 2.2: Create Mobile Layout
**File:** `lib/pages/mobile_layout.dart` (NEW FILE)

**Action:** Create mobile-specific layout with pagination

```dart
import 'package:flutter/material.dart';
import 'package:bird_flutter/bird_flutter.dart';
import 'main_bloc.dart';
import '../widgets/mobile_track_row.dart';

class MobileSequencerLayout extends StatefulWidget {
  final PlaybackBloc bloc;

  const MobileSequencerLayout({Key? key, required this.bloc}) : super(key: key);

  @override
  State<MobileSequencerLayout> createState() => _MobileSequencerLayoutState();
}

class _MobileSequencerLayoutState extends State<MobileSequencerLayout> {
  int _currentPage = 0;
  final int _beatsPerPage = 8; // Show 8 beats per page
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (32 / _beatsPerPage).ceil();

    return Scaffold(
      backgroundColor: Colors.brown[900],
      appBar: AppBar(
        title: Text('Beat Sequencer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown[800],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Control panel
          _buildControlPanel(),

          SizedBox(height: 8),

          // Page indicator
          _buildPageIndicator(totalPages),

          SizedBox(height: 8),

          // Beat position indicator
          _buildBeatIndicator(),

          SizedBox(height: 12),

          // Track grid (paginated)
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: totalPages,
              itemBuilder: (context, pageIndex) {
                return _buildTrackGrid(pageIndex);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return $$ >> (context) {
      final isPlaying = widget.bloc.timeline.isPlaying.value;
      final metronomeOn = widget.bloc.metronomeStatus.value;
      final bpm = (widget.bloc.timeline.bpm.value / 4.0).round();

      return Card(
        color: Colors.brown[800],
        margin: EdgeInsets.all(8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // BPM display
              Text(
                'BPM: $bpm',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),

              SizedBox(height: 16),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Play/Stop button
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (isPlaying) {
                            widget.bloc.timeline.stop();
                          } else {
                            widget.bloc.timeline.play();
                          }
                        },
                        icon: Icon(
                          isPlaying ? Icons.stop : Icons.play_arrow,
                          size: 28,
                        ),
                        label: Text(
                          isPlaying ? 'Stop' : 'Play',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: isPlaying ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Metronome toggle
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: widget.bloc.toggleMetronome,
                        icon: Icon(
                          metronomeOn ? Icons.volume_up : Icons.volume_off,
                          size: 28,
                        ),
                        label: Text(
                          'Metro',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: metronomeOn
                              ? Colors.amber
                              : Colors.brown[700],
                          foregroundColor: metronomeOn ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    };
  }

  Widget _buildPageIndicator(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Page ${_currentPage + 1}/$totalPages',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        SizedBox(width: 12),
        ...List.generate(totalPages, (index) {
          return Container(
            width: _currentPage == index ? 32 : 8,
            height: 8,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _currentPage == index ? Colors.amber : Colors.brown[700],
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBeatIndicator() {
    return $$ >> (context) {
      final currentBeat = widget.bloc.timeline.atBeat.value;
      final startBeat = _currentPage * _beatsPerPage;
      final endBeat = startBeat + _beatsPerPage;

      return Container(
        height: 24,
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: List.generate(_beatsPerPage, (index) {
            final beatIndex = startBeat + index;
            final isActive = currentBeat == beatIndex;
            final isFourBeat = beatIndex % 4 == 0;

            return Expanded(
              child: GestureDetector(
                onTap: () => widget.bloc.timeline.setBeat(beatIndex),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.amber
                        : (isFourBeat ? Colors.brown[700] : Colors.brown[800]),
                    borderRadius: BorderRadius.circular(4),
                    border: isFourBeat
                        ? Border.all(color: Colors.brown[600]!, width: 1)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${beatIndex % 16 + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.black : Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    };
  }

  Widget _buildTrackGrid(int pageIndex) {
    final startBeat = pageIndex * _beatsPerPage;
    final endBeat = (startBeat + _beatsPerPage).clamp(0, 32);

    return $$ >> (context) {
      final currentBeat = widget.bloc.timeline.atBeat.value;

      return ListView.separated(
        padding: EdgeInsets.all(8),
        itemCount: widget.bloc.tracks.length,
        separatorBuilder: (context, index) => SizedBox(height: 8),
        itemBuilder: (context, trackIndex) {
          final track = widget.bloc.tracks[trackIndex];

          return Card(
            color: Colors.brown[800],
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: MobileTrackRow(
                track: track,
                currentBeat: currentBeat,
                startBeat: startBeat,
                endBeat: endBeat,
              ),
            ),
          );
        },
      );
    };
  }
}
```

**Why:**
- **Pagination:** Divides 32 beats into 4 pages of 8 beats each
- **PageView:** Natural swipe gestures between pages
- **Page indicators:** Shows current page clearly
- **Beat numbers:** Helps users orient themselves
- **Large buttons:** All controls are 48dp+ for easy tapping
- **Modern design:** Card-based layout with rounded corners and shadows

---

### PHASE 3: TESTING AND PLATFORM CONFIGURATION

#### Step 3.1: Update Android Manifest
**File:** `android/app/src/main/AndroidManifest.xml`

**Action:** Add audio permissions

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- ADD THESE LINES before <application> tag: -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>

    <application
        android:label="Beat Sequencer"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- ... rest of manifest ... -->
    </application>
</manifest>
```

**Why:** Required for audio file access and playback on Android.

---

#### Step 3.2: Update iOS Info.plist
**File:** `ios/Runner/Info.plist`

**Action:** Add audio session configuration

```xml
<dict>
    <!-- ... existing keys ... -->

    <!-- ADD THESE LINES: -->
    <key>UIBackgroundModes</key>
    <array>
        <string>audio</string>
    </array>

    <key>AVAudioSessionCategory</key>
    <string>AVAudioSessionCategoryPlayback</string>
</dict>
```

**Why:** Allows audio to play properly and optionally in background on iOS.

---

#### Step 3.3: Test on Physical Device
**Actions:**

1. **Build for Android:**
```bash
flutter build apk --release
```

2. **Build for iOS:**
```bash
flutter build ios --release
```

3. **Install and test:**
   - Install on physical device (emulators may have audio latency issues)
   - Test all 8 drum sounds
   - Test metronome
   - Test pattern selection
   - Test play/stop
   - Verify beat accuracy (no drift)
   - Test rotation (portrait should be primary)
   - Test swipe between pages

4. **Check for issues:**
   - Audio latency (should be <50ms)
   - UI responsiveness
   - Memory leaks (run for 5+ minutes)
   - Battery drain (audio should be efficient)
   - Touch targets (all buttons easily tappable)

**Why:** Audio performance varies significantly between emulators and real devices.

---

### PHASE 4: OPTIONAL ENHANCEMENTS

#### Step 4.1: Add Tempo Control
**File:** `lib/pages/mobile_layout.dart`

**Action:** Add slider to control BPM in the control panel

**In `_buildControlPanel()`, add after BPM display:**
```dart
// BPM display
Text(
  'BPM: $bpm',
  style: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.amber,
  ),
),

// ADD THIS SLIDER:
Slider(
  value: bpm.toDouble(),
  min: 60.0,
  max: 200.0,
  divisions: 140,
  label: '$bpm BPM',
  onChanged: (value) {
    widget.bloc.timeline.setBpm(value * 4.0); // Internal BPM is 4x
  },
  activeColor: Colors.amber,
  inactiveColor: Colors.brown[700],
),

SizedBox(height: 16),
```

**Why:** Users can adjust tempo to their preference directly from the UI.

---

#### Step 4.2: Add Visual Beat Metronome
**File:** `lib/pages/mobile_layout.dart`

**Action:** Add pulsing circle in the control panel

**In `_buildControlPanel()`, add after control buttons:**
```dart
SizedBox(height: 16),

// Visual metronome
$$ >> (context) {
  final currentBeat = widget.bloc.timeline.atBeat.value;
  final isDownbeat = currentBeat % 4 == 0;
  final isBar = currentBeat % 16 == 0;

  return AnimatedContainer(
    duration: Duration(milliseconds: 100),
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: isBar
          ? Colors.red
          : (isDownbeat ? Colors.amber : Colors.brown[700]),
      boxShadow: (isBar || isDownbeat)
          ? [
              BoxShadow(
                color: (isBar ? Colors.red : Colors.amber).withOpacity(0.6),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ]
          : null,
    ),
    child: Center(
      child: Text(
        '${(currentBeat % 4) + 1}',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );
},
```

**Why:** Provides visual beat reference (helpful when metronome sound is off or in loud environments).

---

#### Step 4.3: Lock Orientation to Portrait
**File:** `lib/main.dart`

**Action:** Force portrait orientation for better UX

**Add import at top:**
```dart
import 'package:flutter/services.dart';
```

**Update main function:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(LoadingApp());
}
```

**Why:** The pagination layout is optimized for portrait mode. Locking orientation prevents awkward landscape layouts.

---

## SUMMARY OF CHANGES

### Files Created (3 new files):
1. `lib/services/audio_service.dart` - Audio abstraction layer
2. `lib/widgets/mobile_track_row.dart` - Mobile track widget with 48px touch targets
3. `lib/pages/mobile_layout.dart` - Mobile-specific paginated layout

### Files Modified (3 files):
1. `pubspec.yaml` - Add just_audio dependency
2. `lib/main.dart` - Complete rewrite with loading screen and mobile-only layout
3. `lib/pages/main_bloc.dart` - Replace JS audio with AudioService

### Files to Add (2 audio files - optional):
1. `assets/sounds/metronome_high.wav` - High beep for bars
2. `assets/sounds/metronome_low.wav` - Low beep for beats

### Platform Files Modified (2 files):
1. `android/app/src/main/AndroidManifest.xml` - Audio permissions
2. `ios/Runner/Info.plist` - Audio session config

### Files No Longer Used:
1. `lib/pages/main.dart` - Can be deleted (replaced by mobile_layout.dart)
2. `lib/widgets/title.dart` - Can be deleted (using AppBar instead)

---

## IMPLEMENTATION ORDER

**Critical path (must be done in order):**
1. Phase 1: Steps 1.1 → 1.2 → 1.3 → 1.4 → 1.5 (Audio system)
2. Phase 2: Steps 2.1 → 2.2 (Mobile UI)
3. Phase 3: Steps 3.1 → 3.2 → 3.3 (Platform & Testing)

**Optional enhancements (can be done in any order after Phase 3):**
- Step 4.1 (Tempo control slider)
- Step 4.2 (Visual metronome)
- Step 4.3 (Portrait lock)

---

## TESTING CHECKLIST

**Phase 1 (Audio):**
- [ ] App builds without errors
- [ ] All 8 drum sounds play on tap
- [ ] Sounds play during playback
- [ ] Metronome works (if sounds added)
- [ ] No audio latency (beats sync with visual indicator)
- [ ] Loading screen appears on app start

**Phase 2 (UI):**
- [ ] Mobile layout appears
- [ ] Page swipe works smoothly (4 pages total)
- [ ] All buttons are easily tappable (48px minimum)
- [ ] Track names visible and tappable (plays sound preview)
- [ ] Pattern selection bottom sheet works
- [ ] Beat indicator shows current position
- [ ] Page indicator shows current page

**Phase 3 (Platform):**
- [ ] Android app builds and runs
- [ ] iOS app builds and runs
- [ ] Permissions granted without crashes
- [ ] Audio works on both platforms
- [ ] Haptic feedback works
- [ ] No lag or stuttering

**Phase 4 (Optional Polish):**
- [ ] Tempo slider adjusts playback speed (if implemented)
- [ ] Visual metronome pulses with beat (if implemented)
- [ ] App stays in portrait mode (if implemented)

---

## TROUBLESHOOTING

### Issue: Audio not playing on mobile
**Solution:**
- Check that `just_audio` is installed: `flutter pub get`
- Verify audio files are in `assets/sounds/` directory
- Check `pubspec.yaml` has `assets/sounds/` listed under assets
- Run `flutter clean` and rebuild

### Issue: Build fails with "dart:js" error
**Solution:**
- Ensure all `import 'dart:js'` lines are removed from `main_bloc.dart`
- Replace all `js.context` calls with `audioService` calls
- Run `flutter clean` and rebuild

### Issue: Audio latency/drift
**Solution:**
- Use physical device (not emulator)
- Consider using `audioplayers` package instead of `just_audio`
- Pre-load all sounds before playback starts (already done in AudioService)

### Issue: Buttons too small on some devices
**Solution:**
- Increase `buttonSize` in `mobile_track_row.dart` from 48 to 52 or 56
- Reduce `_beatsPerPage` in `mobile_layout.dart` from 8 to 6

### Issue: Pattern bottom sheet doesn't appear
**Solution:**
- Check that `Pattern.patterns` is imported and accessible
- Verify `import '../pages/pattern.dart'` is in `mobile_track_row.dart`

---

## ESTIMATED EFFORT

- **Phase 1 (Audio):** 2-3 hours
- **Phase 2 (UI):** 2-3 hours
- **Phase 3 (Platform):** 1 hour
- **Phase 4 (Optional):** 30 minutes - 1 hour each

**Total:** 5-7 hours for core mobile adaptation, +1.5-3 hours for optional features.

---

## FINAL RESULT

**Before:**
- Web-only, desktop-first
- 1500px+ width required
- Horizontal scrolling
- Mouse-optimized (32px buttons)
- JavaScript audio (Howler.js/Tone.js)

**After:**
- **Mobile-only application**
- Works perfectly on 375px+ phones
- Vertical scrolling with swipe pagination (4 pages × 8 beats)
- Touch-optimized (48px buttons)
- Native audio playback (just_audio)
- Haptic feedback on all interactions
- Modern Material Design aesthetics
- Portrait-optimized layout

**Key Features:**
- ✅ 8 drum tracks (808, Clap, Hat, Open Hat, Kick 1, Kick 2, Snare 1, Snare 2)
- ✅ 32-beat sequencer split into 4 swipeable pages
- ✅ Play/Stop controls
- ✅ Metronome toggle
- ✅ BPM display (optional: adjustable slider)
- ✅ Pattern presets (Reset, All, Every 2/4/8/16, etc.)
- ✅ Beat position indicator
- ✅ Sound preview on track name tap
- ✅ Haptic feedback
- ✅ Loading screen

The app is now a fully native mobile experience optimized for phones!
