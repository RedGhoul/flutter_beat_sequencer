# CLAUDE.md - AI Assistant Guide for Flutter Beat Sequencer

> **Purpose**: This document provides comprehensive guidance for AI assistants (like Claude) working on the Flutter Beat Sequencer codebase. It covers architecture, conventions, workflows, and best practices.

**Last Updated**: 2025-01-13
**Project Version**: 2.0.0 (Mobile-First)
**Flutter SDK**: >=2.4.0 <3.0.0

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Overview](#architecture-overview)
3. [Codebase Structure](#codebase-structure)
4. [State Management (bird/bird_flutter)](#state-management-birdbird_flutter)
5. [Audio System](#audio-system)
6. [Development Workflows](#development-workflows)
7. [Code Conventions](#code-conventions)
8. [Common Tasks](#common-tasks)
9. [Testing Guidelines](#testing-guidelines)
10. [Troubleshooting](#troubleshooting)
11. [Git Workflow](#git-workflow)
12. [Mobile-Specific Considerations](#mobile-specific-considerations)

---

## Project Overview

### What is Flutter Beat Sequencer?

Flutter Beat Sequencer is a **mobile-first drum machine application** built with Flutter for Android and iOS. It allows users to create rhythmic patterns using 8 drum sounds across a 32-beat sequence with an intuitive touch interface.

### Key Features

- **8 Drum Tracks**: 808 Bass, Clap, Hat, Open Hat, Kick 1, Kick 2, Snare 1, Snare 2
- **32-Beat Sequencer**: Two-bar loop at 4/4 time signature
- **Paginated Mobile UI**: 4 swipeable pages (8 beats per page)
- **Pattern Presets**: Quick patterns (Reset, All, Every 2/4/8/16 beats, Fast/Slow Clap)
- **BPM Control**: Adjustable tempo from 60-200 BPM with interactive slider
- **Metronome**: Audio and visual beat indicators
- **Haptic Feedback**: Tactile response on all button presses
- **Portrait-Optimized**: Locked to portrait mode for best UX

### Project History

- **Original Version (0.1.0)**: Web-first application using Howler.js/Tone.js
- **Mobile Transformation (2.0.0)**: Complete rewrite for mobile platforms with native audio
- **Current State**: Mobile-only, touch-optimized, native Flutter audio

### Related Documentation

- `README.md` - Basic project information and badges
- `APP_GUIDE.md` - Comprehensive user and developer guide
- `MOBILE_ADAPTATION_PLAN.md` - Detailed implementation plan for mobile transformation
- `IMPLEMENTATION_VERIFICATION.md` - Verification of implementation phases
- `VERIFICATION_SUMMARY.md` - Summary of verification results

---

## Architecture Overview

### Technology Stack

```
┌─────────────────────────────────────────┐
│          Presentation Layer             │
│  - MobileSequencerLayout (main UI)      │
│  - MobileTrackRow (track widgets)       │
│  - Material Design components           │
└──────────────┬──────────────────────────┘
               │ bird_flutter reactive binding
┌──────────────▼──────────────────────────┐
│         State Management Layer          │
│  - PlaybackBloc (orchestration)         │
│  - TimelineBloc (timing & playback)     │
│  - TrackBloc (per-track state)          │
│  - bird (Signal/Wave pattern)           │
└──────────────┬──────────────────────────┘
               │ service calls
┌──────────────▼──────────────────────────┐
│           Service Layer                 │
│  - AudioService (audio playback)        │
│  - just_audio (native platform audio)   │
└─────────────────────────────────────────┘
```

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | UI framework |
| `bird` | ^0.0.2 | Reactive state management (Signal/Wave) |
| `bird_flutter` | ^0.0.2+1 | Flutter integration for bird ($$, $() operators) |
| `just_audio` | ^0.9.36 | Native audio playback (Android/iOS) |
| `quiver` | (implicit) | Metronome.periodic() for beat timing |
| `extra_pedantic` | ^1.1.1+3 | Strict linting rules (dev dependency) |

### Design Patterns

1. **Reactive BLoC Pattern**: Uses `HookBloc` from bird for automatic resource management
2. **Signal/Wave Duality**: Internal mutable `Signal<T>`, external immutable `Wave<T>`
3. **Service Layer**: AudioService abstracts platform-specific audio implementation
4. **Composition over Inheritance**: TrackBloc and PlaybackBloc both implement `Playable`
5. **Dependency Injection**: AudioService passed down from main.dart through widget tree

---

## Codebase Structure

### Directory Layout

```
flutter_beat_sequencer/
├── lib/                          # Dart source code (999 lines)
│   ├── main.dart                 # Entry point, audio initialization, loading screen
│   ├── pages/
│   │   ├── main_bloc.dart        # State management (BloCs)
│   │   ├── mobile_layout.dart    # Mobile-optimized layout
│   │   ├── pattern.dart          # Pattern definitions
│   │   └── main.dart            # [LEGACY] Original desktop UI (not used)
│   ├── services/
│   │   └── audio_service.dart    # Audio playback abstraction
│   └── widgets/
│       ├── mobile_track_row.dart # Mobile track row component
│       └── title.dart           # [LEGACY] Web title widget (not used)
│
├── assets/
│   └── sounds/                   # Audio files (8 drum samples + 2 metronome)
│       ├── bass.wav              # 808 bass drum
│       ├── clap_2.wav            # Clap sound
│       ├── hat_3.wav             # Closed hi-hat
│       ├── kick_1.wav            # Kick drum variant 1
│       ├── kick_2.wav            # Kick drum variant 2
│       ├── open_hat.wav          # Open hi-hat
│       ├── snare_1.wav           # Snare variant 1
│       ├── snare_2.wav           # Snare variant 2
│       ├── metronome_high.wav    # High beep (C6) for bar markers
│       └── metronome_low.wav     # Low beep (C5) for downbeats
│
├── android/                      # Android platform code
│   └── app/src/main/
│       ├── AndroidManifest.xml   # Permissions: INTERNET, WAKE_LOCK
│       └── kotlin/               # MainActivity.kt
│
├── ios/                          # iOS platform code
│   └── Runner/
│       └── Info.plist           # Audio session configuration
│
├── web/                          # [LEGACY] Web platform (not actively maintained)
│   └── index.html               # Howler.js/Tone.js references
│
├── test/
│   └── widget_test.dart         # Placeholder (no tests implemented yet)
│
└── Configuration Files
    ├── pubspec.yaml             # Dependencies and assets
    ├── analysis_options.yaml     # Linting rules (extra_pedantic)
    └── .gitignore               # Git ignore patterns
```

### Key Files and Their Roles

#### `lib/main.dart` (Entry Point)
- **Purpose**: App initialization and loading screen
- **Key Components**:
  - `LoadingApp`: Shows loading screen while audio initializes
  - `MyApp`: Main app container with dark theme
  - `MyHomePage`: Creates PlaybackBloc with AudioService
- **Important**: Locks orientation to portrait mode
- **Responsibilities**:
  - Initialize AudioService before showing UI
  - Handle audio loading errors gracefully
  - Show CircularProgressIndicator during initialization
  - Pass AudioService to PlaybackBloc

#### `lib/pages/main_bloc.dart` (State Management)
- **Purpose**: Core state management using bird BLoC pattern
- **Key Classes**:
  - `PlaybackBloc`: Orchestrates all tracks and timeline
  - `TimelineBloc`: Manages playback timing and beat position
  - `TrackBloc`: Manages individual track patterns
  - `SoundSelector`: Wrapper for sound name + play function
  - `Playable`: Interface for beat playback callback
- **Important Patterns**:
  - All BLoCs extend `HookBloc` for automatic cleanup
  - Uses `Signal<T>` for internal state, `Wave<T>` for external API
  - Metronome timing uses `quiver.Metronome.periodic()`
  - BPM is stored as 4x display value (640 = 160 BPM)

#### `lib/services/audio_service.dart` (Audio Layer)
- **Purpose**: Abstract audio playback from UI/state management
- **Key Features**:
  - Pre-loads all sounds in `initialize()` for low-latency playback
  - Maps sound names to asset paths
  - Graceful handling of missing metronome sounds
  - `just_audio` AudioPlayer pool (one per sound)
- **Important**: All sounds are pre-loaded in memory (~3MB)

#### `lib/pages/mobile_layout.dart` (Main UI)
- **Purpose**: Mobile-optimized paginated layout
- **Key Components**:
  - `_buildControlPanel()`: BPM display, play/stop, metronome toggle, BPM slider, visual metronome
  - `_buildPageIndicator()`: Dots showing current page (1-4)
  - `_buildBeatIndicator()`: Beat position strip with tap-to-seek
  - `_buildTrackGrid()`: Track rows for current page
- **State**: PageController for swipe navigation, currentPage tracking
- **Pagination**: 32 beats divided into 4 pages × 8 beats

#### `lib/widgets/mobile_track_row.dart` (Track Component)
- **Purpose**: Individual track row with touch-optimized controls
- **Components**:
  - Track label button (tap to preview sound)
  - Beat toggle circles (48px diameter)
  - Pattern menu button (shows bottom sheet)
  - `TrackStep`: Individual beat circle widget
- **Features**:
  - Haptic feedback on all interactions
  - Amber glow on enabled beats
  - White border on currently playing beat
  - Bottom sheet for pattern selection

#### `lib/pages/pattern.dart` (Pattern Definitions)
- **Purpose**: Defines preset patterns for tracks
- **Structure**:
  ```dart
  class TrackPattern {
    final String name;
    final bool Function(int) builder;
  }
  ```
- **Available Patterns**:
  - Reset: All beats off
  - All: All beats on
  - Every 2/4/8/16 beats: Regular intervals
  - Fast Clap: Beats divisible by 4 but not 8
  - Slow Clap: Beats divisible by 8 but not 16

---

## State Management (bird/bird_flutter)

### Overview of bird Package

The bird package provides a lightweight reactive programming framework for Flutter. It's based on the Signal/Wave pattern.

### Core Concepts

#### 1. Signal (Mutable State Container)

```dart
// Create a signal
final Signal<bool> _isPlaying = HookBloc.disposeSink(Signal(false));

// Update the signal
_isPlaying.add(true);

// Read current value
final currentValue = _isPlaying.value;
```

**Important**: Signals are INTERNAL only. Never expose Signal<T> in public APIs.

#### 2. Wave (Immutable Observable Stream)

```dart
// Expose Wave from Signal
Wave<bool> isPlaying = _isPlaying.wave;

// Read value
final value = isPlaying.value;

// Subscribe to changes
final subscription = isPlaying.subscribe((newValue) {
  print('Playing: $newValue');
});
```

**Important**: Waves are EXTERNAL API. Always expose Wave<T> from BLoCs.

#### 3. HookBloc (Resource Management)

```dart
class MyBloc extends HookBloc {
  final Signal<int> _counter = HookBloc.disposeSink(Signal(0));
  Wave<int> counter;

  MyBloc() {
    counter = _counter.wave;
  }

  void increment() {
    _counter.add(_counter.value + 1);
  }
}

// Usage in widget
final bloc = HookBloc.useMemo(() => MyBloc(), []);
HookBloc.useDispose(bloc);
```

**Important**: `HookBloc.disposeSink()` ensures automatic cleanup.

#### 4. bird_flutter UI Binding

```dart
// Reactive widget builder
$$ >> (context) {
  final value = $(() => bloc.counter);
  return Text('Count: $value');
}

// Alternative subscription syntax
$$ >> (context) {
  final value = bloc.counter.value;  // Auto-subscribes
  return Text('Count: $value');
}
```

**Important**: `$$` creates a reactive scope that rebuilds on state changes.

### State Flow in This Project

```
User Action (e.g., tap Play button)
         ↓
   Timeline.play()
         ↓
   _isPlaying.add(true)  [Signal updated]
         ↓
   isPlaying.wave notifies subscribers
         ↓
   $$ reactive scope rebuilds UI
         ↓
   Button shows "Stop" instead of "Play"
```

### Example: Adding a New Reactive State

```dart
class PlaybackBloc extends HookBloc {
  // 1. Create private Signal
  final Signal<int> _volume = HookBloc.disposeSink(Signal(100));

  // 2. Expose public Wave
  late Wave<int> volume;

  PlaybackBloc() {
    // 3. Initialize Wave from Signal
    volume = _volume.wave;
  }

  // 4. Methods to update state
  void setVolume(int newVolume) {
    _volume.add(newVolume.clamp(0, 100));
  }
}

// 5. Use in UI
$$ >> (context) {
  final vol = bloc.volume.value;
  return Slider(
    value: vol.toDouble(),
    onChanged: (v) => bloc.setVolume(v.toInt()),
  );
}
```

---

## Audio System

### AudioService Architecture

```
AudioService
    │
    ├─ _players: Map<String, AudioPlayer>
    │     ├─ bass → AudioPlayer (pre-loaded)
    │     ├─ clap → AudioPlayer (pre-loaded)
    │     ├─ ... (8 drum sounds total)
    │     ├─ metronome_high → AudioPlayer (optional)
    │     └─ metronome_low → AudioPlayer (optional)
    │
    ├─ _soundPaths: Map<String, String>
    │     └─ Maps sound names to asset paths
    │
    └─ Methods:
          ├─ initialize() → Pre-load all sounds
          ├─ playSound(name) → Play specific sound
          ├─ playSynth(note, duration) → Play metronome beep
          └─ dispose() → Clean up resources
```

### Sound File Mapping

| Track Name | Sound Key | Asset Path | Description |
|------------|-----------|------------|-------------|
| 808 | `bass` | `assets/sounds/bass.wav` | 808 bass drum |
| Clap | `clap` | `assets/sounds/clap_2.wav` | Clap sound |
| Hat | `hat` | `assets/sounds/hat_3.wav` | Closed hi-hat |
| Open Hat | `open_hat` | `assets/sounds/open_hat.wav` | Open hi-hat |
| Kick 1 | `kick_1` | `assets/sounds/kick_1.wav` | Kick drum variant 1 |
| Kick 2 | `kick_2` | `assets/sounds/kick_2.wav` | Kick drum variant 2 |
| Snare 1 | `snare_1` | `assets/sounds/snare_1.wav` | Snare variant 1 |
| Snare 2 | `snare_2` | `assets/sounds/snare_2.wav` | Snare variant 2 |
| (Metronome) | `metronome_high` | `assets/sounds/metronome_high.wav` | High beep (C6) |
| (Metronome) | `metronome_low` | `assets/sounds/metronome_low.wav` | Low beep (C5) |

### Pre-loading Strategy

**Why Pre-load?**
- **Low Latency**: Sounds start instantly (<10ms)
- **Beat Accuracy**: No delay between beats
- **Predictable Performance**: No disk I/O during playback

**Trade-off**: ~3MB of RAM for all sounds loaded

### Adding a New Sound

1. **Add sound file** to `assets/sounds/your_sound.wav`

2. **Update pubspec.yaml** (if not already including all of `assets/sounds/`)
   ```yaml
   flutter:
     assets:
       - assets/sounds/
   ```

3. **Add to AudioService._soundPaths**:
   ```dart
   final Map<String, String> _soundPaths = {
     // ... existing sounds ...
     'your_sound': 'assets/sounds/your_sound.wav',
   };
   ```

4. **Add track to PlaybackBloc**:
   ```dart
   TrackBloc(32, SoundSelector("Your Sound", () {
     audioService.playSound('your_sound');
   })),
   ```

5. **Test**: Run app and verify sound loads and plays correctly

### Timing and Synchronization

#### BPM Calculation

```dart
// Display BPM = Internal BPM / 4.0
// Internal BPM = Display BPM * 4.0

// Example:
Display: 160 BPM (quarter notes)
Internal: 640 BPM (16th note subdivisions)
```

**Why 4x?**
- Timeline advances in 16th note subdivisions
- Allows precise timing for complex patterns
- Display shows standard quarter note tempo

#### Metronome Timing

```dart
Duration(microseconds: (double bpm) {
  final beatsPerMicrosecond = bpm / Duration.microsecondsPerMinute;
  return 1 ~/ beatsPerMicrosecond;
}(_bpm.value))
```

This calculates the interval between beats based on BPM.

#### Beat Playback

```dart
void playAtBeat(TimelineBloc bloc, int beat) {
  // Metronome logic
  if (_metronomeStatus.value && beat % 4 == 0) {
    if (beat % 16 == 0) {
      audioService.playSynth("C6", "32n");  // Bar marker
    } else {
      audioService.playSynth("C5", "32n");  // Downbeat
    }
  }

  // Play all enabled tracks
  tracks.forEach((track) => track.playAtBeat(bloc, beat));
}
```

**Beat numbering**: 0-31 (0-indexed, 32 total beats)

---

## Development Workflows

### Setting Up Development Environment

```bash
# 1. Clone repository
git clone <repo-url>
cd flutter_beat_sequencer

# 2. Checkout appropriate branch
git checkout main  # or feature branch

# 3. Install dependencies
flutter pub get

# 4. Verify Flutter installation
flutter doctor

# 5. Run on device/emulator
flutter run

# 6. Build for release (Android)
flutter build apk --release

# 7. Build for release (iOS)
flutter build ios --release
```

### Running the App

**Debug Mode (Hot Reload Enabled)**:
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Specific device
flutter devices  # List devices
flutter run -d <device-id>
```

**Release Mode**:
```bash
# Android APK
flutter build apk --release
# Install: adb install build/app/outputs/flutter-apk/app-release.apk

# iOS IPA
flutter build ios --release
# Deploy via Xcode or TestFlight
```

### Development Best Practices

1. **Always test on physical devices** - Emulators have high audio latency
2. **Use hot reload** - Makes UI iteration fast (`r` in terminal, or IDE button)
3. **Run `flutter analyze`** - Catch linting issues before commit
4. **Check for memory leaks** - Run app for 5+ minutes, monitor memory usage
5. **Test all patterns** - Verify pattern presets work for all tracks
6. **Test pagination** - Swipe through all 4 pages
7. **Test BPM range** - Verify 60-200 BPM works correctly

### Code Analysis

```bash
# Run static analysis
flutter analyze

# Format code (uses Dart formatter)
flutter format lib/

# Check for outdated dependencies
flutter pub outdated
```

### Cleaning Build Cache

```bash
# Clean build cache (fixes many build issues)
flutter clean

# Re-fetch dependencies
flutter pub get

# Rebuild app
flutter run
```

---

## Code Conventions

### Dart Style Guide

This project follows the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) with `extra_pedantic` linting rules.

#### Naming Conventions

```dart
// Classes: PascalCase
class AudioService { }
class PlaybackBloc { }

// Variables/Functions: camelCase
final myVariable = 10;
void playSound() { }

// Constants: camelCase (not SCREAMING_CAPS)
const maxBeats = 32;
const defaultBpm = 160.0;

// Private members: _leadingUnderscore
final Signal<bool> _isPlaying = Signal(false);
```

#### File Naming

```dart
// Files: snake_case
audio_service.dart
mobile_layout.dart
main_bloc.dart
```

### Code Organization

#### File Structure

```dart
// 1. Imports (organized)
import 'dart:async';  // Dart core libraries

import 'package:flutter/material.dart';  // Flutter framework
import 'package:bird/bird.dart';  // Third-party packages

import '../services/audio_service.dart';  // Relative imports
import '../pages/pattern.dart';

// 2. Class definition
class MyWidget extends StatelessWidget {
  // 3. Public fields (if any)
  final String title;

  // 4. Private fields
  final int _counter = 0;

  // 5. Constructor
  const MyWidget({Key? key, required this.title}) : super(key: key);

  // 6. Public methods
  @override
  Widget build(BuildContext context) { }

  // 7. Private methods
  void _incrementCounter() { }
}
```

#### Widget Organization

Prefer composition over large monolithic widgets:

```dart
// GOOD: Broken into smaller widgets
Widget build(BuildContext context) {
  return Column(
    children: [
      _buildHeader(),
      _buildBody(),
      _buildFooter(),
    ],
  );
}

Widget _buildHeader() => Text('Header');
Widget _buildBody() => Text('Body');
Widget _buildFooter() => Text('Footer');

// AVOID: Everything in one giant build method
Widget build(BuildContext context) {
  return Column(
    children: [
      Container(
        child: Row(
          children: [
            Text('...'),
            // ... 100 more lines ...
          ],
        ),
      ),
    ],
  );
}
```

### BLoC Conventions

#### Signal/Wave Pattern

```dart
class MyBloc extends HookBloc {
  // ALWAYS: Private Signal, Public Wave
  final Signal<int> _counter = HookBloc.disposeSink(Signal(0));
  late Wave<int> counter;

  MyBloc() {
    counter = _counter.wave;
  }

  // NEVER: Expose Signal directly
  // Signal<int> counter;  // WRONG!
}
```

#### Disposal Pattern

```dart
class PlaybackBloc extends HookBloc {
  PlaybackBloc() {
    // Dispose Signals
    HookBloc.disposeSink(_isPlaying);
    HookBloc.disposeSink(_bpm);

    // Dispose other BLoCs
    tracks.map((a) => a.dispose).forEach(disposeLater);

    // Dispose subscriptions
    disposeLater(timeline.dispose);
  }
}
```

### UI Conventions

#### Reactive UI Binding

```dart
// GOOD: Use $$ for reactive widgets
$$ >> (context) {
  final isPlaying = bloc.timeline.isPlaying.value;
  return Text(isPlaying ? 'Playing' : 'Stopped');
}

// AVOID: Manual setState() when using bird
// StatefulWidget with setState()  // Not needed with bird
```

#### Touch Targets

```dart
// ALWAYS: Minimum 48px touch targets for mobile
const buttonSize = 48.0;  // Apple/Google guidelines

// AVOID: Small touch targets
const tooSmall = 32.0;  // Hard to tap on mobile
```

#### Haptic Feedback

```dart
// ALWAYS: Add haptic feedback to interactive elements
import 'package:flutter/services.dart';

GestureDetector(
  onTap: () {
    HapticFeedback.selectionClick();  // Light feedback
    // or
    HapticFeedback.lightImpact();     // Medium feedback
    // or
    HapticFeedback.mediumImpact();    // Strong feedback

    onPressed();
  },
  child: YourWidget(),
)
```

### Comments

```dart
// GOOD: Explain WHY, not WHAT
// Pre-load all sounds for low-latency playback during performance
await player.setAsset(entry.value);

// AVOID: Stating the obvious
// Set the asset to entry value
await player.setAsset(entry.value);

// GOOD: Document complex algorithms
// BPM is stored as 4x display value (640 = 160 BPM) to allow
// 16th note subdivisions for precise timing
final internalBpm = displayBpm * 4.0;
```

---

## Common Tasks

### Task 1: Add a New Drum Sound

**Steps**:

1. **Add sound file** to `assets/sounds/new_drum.wav`

2. **Update AudioService** (`lib/services/audio_service.dart`):
   ```dart
   final Map<String, String> _soundPaths = {
     // ... existing sounds ...
     'new_drum': 'assets/sounds/new_drum.wav',
   };
   ```

3. **Add track to PlaybackBloc** (`lib/pages/main_bloc.dart`):
   ```dart
   tracks = [
     // ... existing tracks ...
     TrackBloc(32, SoundSelector("New Drum", () {
       audioService.playSound('new_drum');
     })),
   ];
   ```

4. **Test**: Run `flutter run` and verify the new track appears and plays

**Note**: This adds a 9th track. UI will automatically scroll to accommodate it.

### Task 2: Change BPM Range

**Steps**:

1. **Update slider in mobile_layout.dart**:
   ```dart
   Slider(
     value: bpm.toDouble(),
     min: 40.0,  // Changed from 60.0
     max: 240.0,  // Changed from 200.0
     divisions: 200,  // Update divisions
     // ...
   )
   ```

2. **Test**: Verify slider works at extreme ranges without audio drift

### Task 3: Add a New Pattern Preset

**Steps**:

1. **Update pattern.dart** (`lib/pages/pattern.dart`):
   ```dart
   static final patterns = [
     // ... existing patterns ...
     TrackPattern(
       "My Pattern",
       (i) => i % 3 == 0,  // Every 3rd beat
     ),
   ];
   ```

2. **Test**: Tap pattern menu (⋯ button) and verify new pattern appears

### Task 4: Modify UI Colors

**Steps**:

1. **Update color scheme** in `lib/pages/mobile_layout.dart`:
   ```dart
   // Change brown theme to blue
   Scaffold(
     backgroundColor: Colors.blue[900],  // Was Colors.brown[900]
     // ...
   )
   ```

2. **Update button colors**:
   ```dart
   backgroundColor: isPlaying ? Colors.red : Colors.blue,  // Was green
   ```

3. **Hot reload**: Press `r` in terminal to see changes immediately

### Task 5: Change Beats Per Page

**Steps**:

1. **Update mobile_layout.dart**:
   ```dart
   final int _beatsPerPage = 6;  // Changed from 8
   ```

2. **Test**: Swipe through pages and verify beat indicators update correctly

**Note**: This changes total pages from 4 to 6 (32 ÷ 6 = 5.33, rounds to 6).

### Task 6: Add a New Control Button

**Steps**:

1. **Add state to PlaybackBloc** (`lib/pages/main_bloc.dart`):
   ```dart
   final Signal<bool> _myFeature = HookBloc.disposeSink(Signal(false));
   late Wave<bool> myFeature;

   PlaybackBloc(this.audioService) {
     myFeature = _myFeature.wave;
   }

   void toggleMyFeature() {
     _myFeature.add(!_myFeature.value);
   }
   ```

2. **Add button to UI** (`lib/pages/mobile_layout.dart` in `_buildControlPanel`):
   ```dart
   ElevatedButton.icon(
     onPressed: widget.bloc.toggleMyFeature,
     icon: Icon(Icons.star),
     label: Text('My Feature'),
     style: ElevatedButton.styleFrom(
       backgroundColor: Colors.blue,
     ),
   )
   ```

3. **Test**: Tap button and verify state changes

---

## Testing Guidelines

### Current Testing Status

**WARNING**: This project currently has **minimal test coverage**. The `test/widget_test.dart` file is a placeholder.

### Recommended Testing Approach

When adding tests, follow this structure:

```dart
// test/blocs/playback_bloc_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_beat_sequencer/pages/main_bloc.dart';
import 'package:flutter_beat_sequencer/services/audio_service.dart';

void main() {
  group('PlaybackBloc', () {
    late PlaybackBloc bloc;
    late AudioService mockAudioService;

    setUp(() {
      mockAudioService = MockAudioService();
      bloc = PlaybackBloc(mockAudioService);
    });

    tearDown(() {
      bloc.dispose();
    });

    test('should initialize with 8 tracks', () {
      expect(bloc.tracks.length, 8);
    });

    test('should toggle metronome status', () {
      final initialStatus = bloc.metronomeStatus.value;
      bloc.toggleMetronome();
      expect(bloc.metronomeStatus.value, !initialStatus);
    });
  });
}
```

### Manual Testing Checklist

Before committing changes, verify:

- [ ] **Audio Loading**: App shows loading screen, then main UI
- [ ] **All Sounds Play**: Tap each track name (8 sounds)
- [ ] **Beat Toggling**: Tap beat circles on/off
- [ ] **Playback**: Press Play, verify beats play in sequence
- [ ] **Visual Sync**: White border moves with beat position
- [ ] **BPM Slider**: Drag slider, verify tempo changes immediately
- [ ] **Metronome**: Toggle metronome, verify audio clicks
- [ ] **Visual Metronome**: Verify circle pulses with beat count
- [ ] **Page Swiping**: Swipe left/right through 4 pages
- [ ] **Beat Indicator**: Tap beat positions to seek
- [ ] **Pattern Presets**: Open pattern menu, apply each pattern
- [ ] **Haptic Feedback**: Verify vibration on taps
- [ ] **Orientation**: Verify portrait lock (no landscape)
- [ ] **Memory**: Run for 5+ minutes, check for leaks
- [ ] **Performance**: Verify smooth 60fps animation

### Testing on Devices

**Android**:
```bash
# List connected devices
adb devices

# Install and run
flutter run -d <device-id>

# Check logs
adb logcat | grep flutter
```

**iOS**:
```bash
# List simulators/devices
flutter devices

# Run on iOS
flutter run -d <device-id>

# Check logs in Xcode
open ios/Runner.xcworkspace
```

**Important**: Always test on **physical devices**, not just emulators. Audio latency on emulators is unreliable.

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: Audio Not Playing

**Symptoms**: Sounds don't play when tapping track names or during playback

**Solutions**:
1. Check device volume is not muted
2. Verify sound files exist in `assets/sounds/`
3. Run `flutter clean && flutter pub get`
4. Check logs for loading errors: `flutter logs`
5. Test on physical device (emulators may have issues)
6. Verify `pubspec.yaml` includes:
   ```yaml
   flutter:
     assets:
       - assets/sounds/
   ```

#### Issue: Audio Latency/Drift

**Symptoms**: Beats don't sync with visual indicators, timing drifts

**Solutions**:
1. **Use physical device** - Emulators have high latency
2. Lower BPM temporarily to test
3. Close background apps
4. Check for CPU throttling
5. Consider alternative audio plugin (audioplayers instead of just_audio)

#### Issue: Build Fails with "dart:js" Error

**Symptoms**: Build fails with error about `dart:js` not available on mobile

**Solutions**:
1. Verify `import 'dart:js'` is removed from `main_bloc.dart`
2. Ensure all `js.context` calls are replaced with `audioService` calls
3. Run `flutter clean && flutter pub get`

#### Issue: Buttons Too Small to Tap

**Symptoms**: Difficulty tapping beat circles on small screens

**Solutions**:
1. Increase `buttonSize` in `mobile_track_row.dart`:
   ```dart
   const buttonSize = 52.0;  // Increased from 48.0
   ```
2. Reduce beats per page in `mobile_layout.dart`:
   ```dart
   final int _beatsPerPage = 6;  // Reduced from 8
   ```

#### Issue: App Crashes on Startup

**Symptoms**: White screen, immediate crash, or error screen

**Solutions**:
1. Check logs: `flutter logs` or `adb logcat | grep flutter`
2. Verify all sound files are present
3. Run `flutter clean && flutter pub get`
4. Check for missing dependencies: `flutter pub outdated`
5. Verify Android/iOS permissions are correct

#### Issue: Pattern Menu Doesn't Open

**Symptoms**: Tapping ⋯ button does nothing

**Solutions**:
1. Check `pattern.dart` is imported in `mobile_track_row.dart`
2. Verify `Pattern.patterns` returns a list
3. Check for console errors: `flutter logs`
4. Ensure `showModalBottomSheet` is not blocked by other UI

#### Issue: Hot Reload Not Working

**Symptoms**: Changes don't appear after saving

**Solutions**:
1. Try hot restart instead: `R` (capital R) in terminal
2. Stop and restart: `flutter run`
3. Check for compilation errors in terminal
4. Some changes require full restart (e.g., main.dart changes)

#### Issue: Memory Leak / App Slows Down

**Symptoms**: App gets slower after prolonged use

**Solutions**:
1. Verify all BLoCs are disposed properly
2. Check for subscription leaks (use `disposeLater`)
3. Monitor memory in Flutter DevTools
4. Ensure AudioService.dispose() is called on app exit

---

## Git Workflow

### Branch Naming

This project uses Claude Code's branch naming convention:

```
claude/<description>-<session-id>

Examples:
claude/mobile-adaptation-plan-011CV5FiK6e7Do3upKTdfkCn
claude/create-codebase-documentation-01WqQbpLFyfYVkKGK2G6DQEr
```

**Important**:
- All branches MUST start with `claude/`
- Session ID MUST match the current Claude session
- Pushing to incorrectly named branches will fail with 403 error

### Commit Message Convention

This project follows conventional commits style:

```
<type>: <description>

Examples:
feat: Add new drum sound slot for cowbell
fix: Resolve audio latency on Android devices
docs: Update CLAUDE.md with new patterns
refactor: Extract BPM calculation into separate method
test: Add unit tests for TimelineBloc
chore: Update dependencies to latest versions
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring (no behavior change)
- `test`: Adding or updating tests
- `chore`: Maintenance tasks (dependencies, build config)

### Commit Workflow

When asked to commit changes:

1. **Review changes**:
   ```bash
   git status
   git diff
   ```

2. **Stage files**:
   ```bash
   git add <files>
   ```

3. **Commit with message**:
   ```bash
   git commit -m "$(cat <<'EOF'
   feat: Add comprehensive CLAUDE.md documentation

   - Document architecture and state management patterns
   - Add troubleshooting guide
   - Include common tasks and workflows
   - Provide git and development conventions
   EOF
   )"
   ```

4. **Push to remote**:
   ```bash
   git push -u origin <branch-name>
   ```

**Important**:
- Always use `-u` flag when pushing new branches
- If push fails with network error, retry up to 4 times with exponential backoff (2s, 4s, 8s, 16s)

### Pull Request Workflow

When creating a pull request:

1. **Ensure branch is up to date**:
   ```bash
   git fetch origin
   git status
   ```

2. **Push all commits**:
   ```bash
   git push -u origin <branch-name>
   ```

3. **Create PR using gh CLI** (if available):
   ```bash
   gh pr create --title "Add codebase documentation" --body "$(cat <<'EOF'
   ## Summary
   - Created comprehensive CLAUDE.md for AI assistant guidance
   - Documented architecture, workflows, and conventions

   ## Test plan
   - [x] Verified markdown formatting
   - [x] Checked all code examples
   - [x] Validated file paths and references
   EOF
   )"
   ```

**Note**: If `gh` CLI is not available, ask user to create PR manually.

### Merging Strategy

This project uses **squash merging** for feature branches:

- Feature branches are squashed into a single commit on merge
- Commit history is kept clean and linear
- Each PR = one commit in main branch

---

## Mobile-Specific Considerations

### Portrait Orientation Lock

The app is locked to portrait mode in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(LoadingApp());
}
```

**Why?** The paginated layout is optimized for portrait. Landscape would require different UI.

### Touch Target Sizing

All interactive elements follow Apple and Google guidelines:

- **Minimum**: 48×48 dp (density-independent pixels)
- **Recommended**: 48-56 dp for primary actions
- **Spacing**: 8dp between elements

```dart
// In mobile_track_row.dart
const buttonSize = 48.0;  // Minimum touch target

// In mobile_layout.dart
SizedBox(height: 8),  // Spacing between elements
```

### Haptic Feedback

The app provides tactile feedback for better UX:

```dart
import 'package:flutter/services.dart';

// Light feedback (beat toggles, selections)
HapticFeedback.selectionClick();

// Medium feedback (button presses)
HapticFeedback.lightImpact();

// Strong feedback (important actions)
HapticFeedback.mediumImpact();
```

**When to use**:
- Beat circle taps: `selectionClick()`
- Track name taps: `lightImpact()`
- Pattern menu button: `mediumImpact()`
- Play/Stop button: `lightImpact()`

### Android-Specific

**Permissions** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

**Why?**
- `INTERNET`: Required by just_audio for audio playback
- `WAKE_LOCK`: Prevents device sleep during playback

### iOS-Specific

**Audio Configuration** (`ios/Runner/Info.plist`):
```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>

<key>AVAudioSessionCategory</key>
<string>AVAudioSessionCategoryPlayback</string>
```

**Why?**
- Enables proper audio session management
- Allows background audio (optional feature)

### Performance Considerations

**Audio Latency**:
- Pre-loading all sounds reduces latency to <10ms
- Physical devices have ~20-50ms latency
- Emulators can have 100-500ms latency (unreliable)

**Memory Usage**:
- App code: ~15 MB
- Pre-loaded audio: ~3 MB
- UI framework: ~20 MB
- **Total**: ~40-50 MB runtime

**Frame Rate**:
- Target: 60 fps
- Critical for smooth beat indicator animation
- Use Flutter DevTools Performance tab to monitor

### Screen Size Support

**Minimum supported**: 375px width (iPhone SE, small Android phones)

**Tested on**:
- iPhone SE: 375×667 (smallest supported)
- iPhone 12: 390×844
- Pixel 5: 393×851
- Large phones: 414×896+

**Responsive Design**:
- Beats per page: 8 (fits all supported screens)
- Button sizes: Scale with screen size via MediaQuery (if needed)
- Spacing: Proportional using SizedBox

---

## Best Practices for AI Assistants

### When Working on This Codebase

1. **Always read existing documentation first** - Check README, APP_GUIDE, and this CLAUDE.md
2. **Follow the reactive pattern** - Use Signal/Wave, never mix with setState
3. **Test on physical devices** - Audio latency on emulators is unreliable
4. **Use flutter analyze** - Catch linting issues before committing
5. **Maintain haptic feedback** - Add to all new interactive elements
6. **Keep touch targets ≥48dp** - Essential for mobile usability
7. **Document complex logic** - Especially timing, BPM calculations, beat logic
8. **Use existing patterns** - Don't introduce new state management approaches
9. **Clean up resources** - Always use HookBloc.disposeSink and disposeLater
10. **Test all patterns** - Verify pattern presets work after UI changes

### Understanding the Codebase

**Key mental models**:

1. **Beat numbering is 0-indexed**: Beats 0-31, not 1-32
2. **BPM is 4x internally**: Display = Internal ÷ 4
3. **Pages are 0-indexed**: Pages 0-3, displayed as 1-4
4. **Signals are private**: Only expose Waves publicly
5. **Audio is pre-loaded**: All sounds in memory at startup

### Making Changes

**Before modifying**:
1. Understand the reactive flow
2. Check if change affects beat timing
3. Consider impact on audio latency
4. Test on both Android and iOS
5. Verify portrait orientation still works

**When adding features**:
1. Add state to appropriate BLoC
2. Update UI with reactive binding ($$)
3. Add haptic feedback to interactions
4. Ensure ≥48dp touch targets
5. Test with hot reload
6. Update this CLAUDE.md if architecture changes

### Common Pitfalls to Avoid

1. **Don't mix setState with bird** - Use Signal/Wave only
2. **Don't expose Signals** - Always use Waves for public API
3. **Don't forget disposal** - Memory leaks are common without proper cleanup
4. **Don't test only on emulators** - Audio timing is unreliable
5. **Don't use small touch targets** - <48dp is hard to tap
6. **Don't modify BPM calculation** - Internal 4x multiplier is intentional
7. **Don't add synchronous audio calls** - Keep playSound() async
8. **Don't skip haptic feedback** - Users expect it on mobile

---

## Changelog

### Version 2.0.0 (Current - Mobile-First)
- Complete mobile transformation from web-first application
- Native audio system with just_audio (Android/iOS)
- Paginated mobile layout (4 pages × 8 beats)
- Touch-optimized controls (48px minimum buttons)
- Haptic feedback on all interactions
- BPM slider and visual metronome
- Portrait orientation lock
- Loading screen with error handling

### Version 0.1.0 (Original - Web-First)
- Web application using Howler.js/Tone.js
- Desktop-optimized horizontal layout
- Mouse-optimized controls
- 1500px+ width requirement

---

## Additional Resources

### Official Documentation

- **Flutter**: https://flutter.dev/docs
- **Dart**: https://dart.dev/guides
- **bird package**: https://pub.dev/packages/bird
- **just_audio**: https://pub.dev/packages/just_audio

### Project-Specific Docs

- `README.md` - Project overview
- `APP_GUIDE.md` - Comprehensive user and developer guide
- `MOBILE_ADAPTATION_PLAN.md` - Implementation plan for mobile transformation
- `IMPLEMENTATION_VERIFICATION.md` - Verification of implementation phases

### Getting Help

For issues or questions:
1. Check this CLAUDE.md first
2. Review APP_GUIDE.md for detailed technical info
3. Check Flutter documentation for framework questions
4. Review bird package docs for reactive patterns
5. Search GitHub issues for known problems

---

## Contact

**Original Author**: Modestas Valauskas (@modulovalue)
**Repository**: https://github.com/modulovalue/flutter_beat_sequencer
**Mobile Adaptation**: Claude AI (2025-01)

---

**End of CLAUDE.md**

*This document should be kept up to date as the codebase evolves. When making significant architectural changes, update this file accordingly.*
