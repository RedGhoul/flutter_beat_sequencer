# Flutter Beat Sequencer - Mobile App Guide

## Overview

The Flutter Beat Sequencer is a **mobile-first drum machine** application that allows users to create rhythmic patterns using 8 different drum sounds across a 32-beat sequence. The app is optimized for portrait-mode phones (375px+ width) with touch-friendly controls and native audio playback.

---

## Table of Contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [How It Works](#how-it-works)
4. [User Interface](#user-interface)
5. [Audio System](#audio-system)
6. [Code Structure](#code-structure)
7. [Building & Running](#building--running)
8. [Technical Details](#technical-details)

---

## Features

### Core Functionality
- **8 Drum Tracks**: 808 Bass, Clap, Hat, Open Hat, Kick 1, Kick 2, Snare 1, Snare 2
- **32-Beat Sequencer**: Full 2-bar loop at 4/4 time signature
- **Paginated View**: 4 swipeable pages (8 beats per page)
- **Pattern Presets**: Quick patterns (Reset, All, Every 2/4/8/16 beats, Fast/Slow Clap)
- **BPM Control**: Adjustable tempo from 60-200 BPM with interactive slider
- **Metronome**: Audio and visual beat indicators
- **Haptic Feedback**: Tactile response on all button presses

### User Experience
- **Touch-Optimized**: 48px minimum touch targets (Apple/Google guidelines)
- **Responsive Design**: Card-based layout with modern aesthetics
- **Portrait Lock**: Prevents awkward landscape orientation
- **Loading Screen**: Shows progress while audio initializes
- **Error Handling**: Graceful failure with retry options

---

## Architecture

### Technology Stack
- **Framework**: Flutter (Dart)
- **Audio**: `just_audio` package (native Android/iOS)
- **State Management**: `bird` & `bird_flutter` (reactive streams)
- **UI Pattern**: Stateful widgets with reactive subscriptions
- **Platform**: Android & iOS (mobile-only)

### Design Pattern
```
┌─────────────────┐
│   LoadingApp    │  ← Initializes audio on startup
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     MyApp       │  ← Main app container
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  MyHomePage     │  ← Creates PlaybackBloc with AudioService
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ MobileSequencer │  ← Renders UI, handles interactions
│     Layout      │
└─────────────────┘
```

---

## How It Works

### 1. Startup Sequence

When the app launches:

1. **Orientation Lock**: Portrait-only mode is enforced
2. **Audio Initialization**: All 8 drum sounds are pre-loaded into memory
3. **Loading Screen**: Displays while sounds load (typically <2 seconds)
4. **Main UI**: Appears when ready, showing beat sequencer

### 2. Creating a Beat

**Step-by-step:**

1. **Select a Track**: Each row represents one drum sound
2. **Tap Beat Circles**: Toggle beats on/off (amber = enabled)
3. **Preview Sound**: Tap track name to hear the drum sample
4. **Set Pattern**: Tap `⋯` button for quick pattern presets
5. **Adjust Tempo**: Use slider to change BPM (60-200)
6. **Press Play**: Start playback, beats light up as they play
7. **Toggle Metronome**: Enable/disable audio/visual click track

### 3. Beat Playback

**Playback Logic:**
```
Timeline advances → Check each track at current beat → Play enabled sounds
         ↓
     Beat 0, 1, 2... 31 → Loop back to 0
         ↓
Every 4 beats: Metronome beep (if enabled)
Every 16 beats: Metronome high beep (bar marker)
```

**Visual Feedback:**
- White border around current beat position
- Amber glow on enabled beats
- Visual metronome pulses (red on bars, amber on downbeats)
- Beat number indicator shows 1-4 within current measure

### 4. Navigation

**Page Swiping:**
- Swipe left/right to navigate between 4 pages
- Each page shows 8 beats (beats 0-7, 8-15, 16-23, 24-31)
- Page indicator shows current position
- Beat numbers update to show position in loop

**Seek Control:**
- Tap any beat in the indicator strip to jump to that position
- Useful for precise editing and navigation

---

## User Interface

### Control Panel

```
┌──────────────────────────────────┐
│         BPM: 160                 │  ← Tempo Display
│    ═══════●═══════               │  ← BPM Slider (60-200)
│                                  │
│  ┌──────────┐  ┌──────────┐     │
│  │ ▶ Play   │  │ 🔊 Metro │     │  ← Control Buttons
│  └──────────┘  └──────────┘     │
│                                  │
│         ● 1                      │  ← Visual Metronome
└──────────────────────────────────┘
```

**Components:**
- **BPM Display**: Large, readable tempo (calculated from internal BPM / 4)
- **BPM Slider**: Drag to adjust tempo in real-time
- **Play/Stop Button**: Green when stopped, red when playing
- **Metronome Button**: Amber when on, brown when off
- **Visual Metronome**: Pulsing circle shows beat count (1-4)

### Page Indicator

```
Page 1/4  ●━━━ ○ ○ ○
          │
          └─ Current page (amber)
```

### Beat Position Indicator

```
┌─┬─┬─┬─┬─┬─┬─┬─┐
│1│2│3│4│5│6│7│8│  ← Beat numbers (1-8 for current page)
└─┴─┴─┴─┴─┴─┴─┴─┘
 ↑
Current beat (amber background)
```

### Track Row

```
┌──────┬──────────────────────────────────┬────┐
│ 808  │ ○ ○ ● ○ ● ○ ○ ●                 │ ⋯  │
└──────┴──────────────────────────────────┴────┘
   │            │                             │
   │            └─ Beat toggles (○=off, ●=on) │
   │                                          │
   └─ Tap to preview                 Pattern menu
```

**Elements:**
- **Track Name**: Tap to hear drum sample
- **Beat Circles**: 48px diameter, tap to toggle
- **Pattern Button**: Opens bottom sheet with presets

### Pattern Selection

```
┌─────────────────────────────┐
│  Select Pattern for 808     │
├─────────────────────────────┤
│  ♪  Reset                   │
│  ♪  All                     │
│  ♪  Every 2 beat            │
│  ♪  Every 4 beat            │
│  ♪  Every 8 beat            │
│  ♪  Every 16 beat           │
│  ♪  Fast Clap               │
│  ♪  Slow Clap               │
└─────────────────────────────┘
```

**Pattern Definitions:**
- **Reset**: All beats off
- **All**: All beats on
- **Every 2 beat**: Beats 0, 2, 4, 6, 8... (eighth notes)
- **Every 4 beat**: Beats 0, 4, 8, 12... (quarter notes)
- **Every 8 beat**: Beats 0, 8, 16, 24 (half notes)
- **Every 16 beat**: Beats 0, 16 (whole notes)
- **Fast Clap**: Beats that are multiples of 4 but not 8
- **Slow Clap**: Beats that are multiples of 8 but not 16

---

## Audio System

### AudioService Architecture

```
AudioService
    │
    ├─ _players: Map<String, AudioPlayer>
    │     ├─ bass → AudioPlayer (pre-loaded)
    │     ├─ clap → AudioPlayer (pre-loaded)
    │     ├─ hat → AudioPlayer (pre-loaded)
    │     ├─ open_hat → AudioPlayer (pre-loaded)
    │     ├─ kick_1 → AudioPlayer (pre-loaded)
    │     ├─ kick_2 → AudioPlayer (pre-loaded)
    │     ├─ snare_1 → AudioPlayer (pre-loaded)
    │     ├─ snare_2 → AudioPlayer (pre-loaded)
    │     ├─ metronome_high → AudioPlayer (optional)
    │     └─ metronome_low → AudioPlayer (optional)
    │
    └─ Methods:
          ├─ initialize() → Load all sounds
          ├─ playSound(name) → Play specific sound
          ├─ playSynth(note, duration) → Play metronome
          └─ dispose() → Clean up resources
```

### Sound File Mapping

| Track Name | Sound Key  | File Path                     |
|------------|------------|-------------------------------|
| 808        | bass       | assets/sounds/bass.wav        |
| Clap       | clap       | assets/sounds/clap_2.wav      |
| Hat        | hat        | assets/sounds/hat_3.wav       |
| Open Hat   | open_hat   | assets/sounds/open_hat.wav    |
| Kick 1     | kick_1     | assets/sounds/kick_1.wav      |
| Kick 2     | kick_2     | assets/sounds/kick_2.wav      |
| Snare 1    | snare_1    | assets/sounds/snare_1.wav     |
| Snare 2    | snare_2    | assets/sounds/snare_2.wav     |
| Metro High | metronome_high | assets/sounds/metronome_high.wav (optional) |
| Metro Low  | metronome_low  | assets/sounds/metronome_low.wav (optional)  |

### Playback Strategy

**Pre-loading Benefits:**
- **Low Latency**: Sounds start instantly (< 10ms)
- **Beat Accuracy**: No delay between beats
- **Memory Trade-off**: ~3MB RAM for all sounds loaded

**Sound Playback:**
```dart
playSound('kick_1'):
  1. Get pre-loaded AudioPlayer from map
  2. Seek to start (Duration.zero)
  3. Play immediately
  4. Return (non-blocking)
```

### Metronome System

**Beat Types:**
- **Bar (every 16 beats)**: High beep (C6 note)
- **Downbeat (every 4 beats)**: Low beep (C5 note)
- **Other beats**: Silent

**Visual + Audio:**
- Audio metronome: Toggle on/off with button
- Visual metronome: Always visible, shows beat count

---

## Code Structure

### File Organization

```
lib/
├── main.dart                    # Entry point, loading screen
├── services/
│   └── audio_service.dart       # Audio abstraction layer
├── pages/
│   ├── main_bloc.dart           # State management (PlaybackBloc, TimelineBloc, TrackBloc)
│   ├── mobile_layout.dart       # Main UI layout
│   ├── pattern.dart             # Pattern definitions
│   └── main.dart               # (Legacy desktop layout - not used)
└── widgets/
    ├── mobile_track_row.dart    # Track row component
    └── title.dart              # (Legacy - not used)

assets/
└── sounds/
    ├── bass.wav
    ├── clap_2.wav
    ├── hat_3.wav
    ├── open_hat.wav
    ├── kick_1.wav
    ├── kick_2.wav
    ├── snare_1.wav
    └── snare_2.wav

android/
└── app/src/main/
    └── AndroidManifest.xml      # Permissions, app name

ios/
└── Runner/
    └── Info.plist              # Audio session, app name
```

### Key Classes

#### PlaybackBloc
**Purpose**: Top-level controller for the entire sequencer

**Properties:**
- `tracks: List<TrackBloc>` - 8 drum tracks
- `timeline: TimelineBloc` - Playback timeline
- `metronomeStatus: Wave<bool>` - Metronome on/off state
- `audioService: AudioService` - Audio playback

**Methods:**
- `playAtBeat(bloc, beat)` - Called on each beat, plays enabled sounds
- `toggleMetronome()` - Turn metronome on/off

#### TimelineBloc
**Purpose**: Manages playback timing and beat position

**Properties:**
- `isPlaying: Wave<bool>` - Playback state
- `bpm: Wave<double>` - Tempo (internal BPM × 4)
- `atBeat: Wave<int>` - Current beat position (0-31, or -1 if stopped)

**Methods:**
- `play()` - Start playback
- `stop()` - Stop and reset to -1
- `setBpm(newBpm)` - Change tempo
- `setBeat(i)` - Jump to specific beat
- `togglePlayback()` - Toggle play/pause

**Timing Logic:**
```dart
// Metronome interval calculation
Duration(microseconds: (double bpm) {
  final beatsPerMicrosecond = bpm / Duration.microsecondsPerMinute;
  return 1 ~/ beatsPerMicrosecond;
}(bpm))
```

#### TrackBloc
**Purpose**: Manages a single drum track's pattern

**Properties:**
- `isEnabled: Wave<List<bool>>` - 32 booleans (one per beat)
- `sound: SoundSelector` - Name and play function

**Methods:**
- `toggle(index)` - Toggle beat on/off
- `playAtBeat(bloc, beat)` - Check if beat is enabled, play if so
- `setPattern(pattern)` - Apply preset pattern

#### MobileSequencerLayout
**Purpose**: Main UI component

**State:**
- `_currentPage: int` - Current page (0-3)
- `_beatsPerPage: int` - Beats per page (8)
- `_pageController: PageController` - Swipe navigation

**Methods:**
- `_buildControlPanel()` - BPM, play/stop, metronome controls
- `_buildPageIndicator()` - Page dots
- `_buildBeatIndicator()` - Beat position strip
- `_buildTrackGrid(pageIndex)` - Track rows for current page

#### MobileTrackRow
**Purpose**: Single track row component

**Props:**
- `track: TrackBloc` - Track data
- `currentBeat: int` - Current playback position
- `startBeat: int` - First beat to show
- `endBeat: int` - Last beat to show

**Renders:**
- Track label (if first page)
- 8 beat toggle circles
- Pattern menu button (if first page)

---

## Building & Running

### Prerequisites

```bash
# Install Flutter SDK
flutter --version

# Should be ≥ 2.4.0
```

### Installation

```bash
# Clone repository
git clone <repo-url>
cd flutter_beat_sequencer

# Checkout mobile branch
git checkout claude/mobile-adaptation-phase-1-011CV5J7vguWgqttvSg95tBs

# Install dependencies
flutter pub get
```

### Running on Device

**Android:**
```bash
# Connect Android device or start emulator
flutter devices

# Run debug build
flutter run -d <device-id>

# Build release APK
flutter build apk --release
```

**iOS:**
```bash
# Connect iOS device or start simulator
flutter devices

# Run debug build
flutter run -d <device-id>

# Build release IPA
flutter build ios --release
```

### Testing

**Quick Test Checklist:**
- [ ] App loads with loading screen
- [ ] All 8 drum sounds play on track name tap
- [ ] Beats toggle on/off when tapped
- [ ] Play/Stop button works
- [ ] BPM slider adjusts tempo smoothly
- [ ] Metronome button toggles audio clicks
- [ ] Visual metronome pulses with beat
- [ ] Page swiping works (4 pages)
- [ ] Beat indicator shows correct position
- [ ] Pattern presets apply correctly
- [ ] Haptic feedback on button presses
- [ ] Orientation stays portrait

---

## Technical Details

### Performance Optimization

**Audio Pre-loading:**
- All sounds loaded on startup (one-time cost)
- Instant playback during performance
- No disk I/O during playback

**UI Optimization:**
- Reactive updates only for changed values
- `$$` operator from bird_flutter rebuilds minimal widgets
- PageView lazy-loads pages (not all rendered at once)

### State Management

**Reactive Streams (bird package):**
```dart
Signal<bool> _isPlaying = Signal(false);  // Mutable state
Wave<bool> isPlaying = _isPlaying.wave;   // Immutable stream

// Update
_isPlaying.add(true);

// Subscribe in UI
$$ >> (context) {
  final playing = isPlaying.value;  // Auto-rebuilds on change
  return Text(playing ? 'Playing' : 'Stopped');
}
```

**Benefits:**
- Automatic UI updates when state changes
- No manual setState() calls
- Memory-efficient subscriptions

### Platform-Specific Configuration

**Android (AndroidManifest.xml):**
- `INTERNET` permission: Audio file loading
- `WAKE_LOCK` permission: Prevent sleep during playback
- App label: "Beat Sequencer"

**iOS (Info.plist):**
- `UIBackgroundModes`: Enable background audio
- `AVAudioSessionCategory`: Optimize for playback
- Portrait orientation preferences
- App name: "Beat Sequencer"

### BPM Calculation

**Internal BPM vs Display BPM:**
```
Internal BPM = 640  (4x display)
Display BPM = 160   (quarter note = 1 beat)

Why 4x?
- Timeline advances in 16th note subdivisions
- Allows precise timing for complex patterns
- Display shows quarter note tempo (standard)
```

**Formula:**
```dart
displayBPM = internalBPM / 4.0
internalBPM = displayBPM * 4.0
```

### Error Handling

**Audio Loading Failures:**
```dart
try {
  await player.setAsset(soundPath);
  await player.load();
} catch (e) {
  // Metronome sounds are optional
  if (soundName.contains('metronome')) {
    print('Metronome not available');
    return;  // Graceful skip
  }

  // Critical sounds must load
  rethrow;  // Show error screen
}
```

**Network Issues:**
- All sounds are bundled assets (no network required)
- INTERNET permission only for just_audio internal use
- Offline-first design

### Memory Footprint

**Approximate Memory Usage:**
- App code: ~15 MB
- Audio files: ~3 MB (loaded in memory)
- UI framework: ~20 MB
- **Total**: ~40-50 MB runtime

**Suitable for:**
- Low-end Android devices (2GB+ RAM)
- All iOS devices (iPhone 6+)

---

## Future Enhancements

### Potential Features
- [ ] Save/Load patterns to disk
- [ ] Multiple pattern banks (A, B, C, D)
- [ ] Export to MIDI or audio file
- [ ] Additional drum kits (electronic, acoustic, percussion)
- [ ] Swing/shuffle timing
- [ ] Individual track volume controls
- [ ] Mute/solo per track
- [ ] Copy/paste patterns between tracks
- [ ] Undo/redo functionality
- [ ] Recording input via microphone
- [ ] Song mode (chain multiple patterns)

### Performance Improvements
- [ ] Add metronome sound files for better click track
- [ ] Optimize beat rendering for 60fps on all devices
- [ ] Add settings screen for audio buffer size
- [ ] Implement audio latency compensation

---

## Troubleshooting

### Common Issues

**Issue: "No audio playing"**
- Check device volume
- Verify sound files exist in `assets/sounds/`
- Check Android permissions granted
- Test on physical device (emulators may have issues)

**Issue: "Audio latency/drift"**
- Use physical device (emulators have high latency)
- Lower BPM temporarily to test
- Check for background processes using CPU
- Consider using `audioplayers` package instead

**Issue: "App crashes on startup"**
- Run `flutter clean && flutter pub get`
- Check all sound files are in assets folder
- Verify `pubspec.yaml` includes `assets/sounds/`
- Check logs: `flutter logs`

**Issue: "Buttons too small to tap"**
- Verify screen DPI is standard
- Increase `buttonSize` in `mobile_track_row.dart`
- Reduce `_beatsPerPage` from 8 to 6

**Issue: "Pattern menu doesn't open"**
- Check `pattern.dart` is imported
- Verify `allPatterns()` returns list
- Check for JavaScript errors (should be none now)

---

## Contributing

### Development Workflow

1. **Setup**: `flutter pub get`
2. **Branch**: Create feature branch
3. **Develop**: Make changes
4. **Test**: Run on device
5. **Commit**: Clear, descriptive messages
6. **Push**: To feature branch
7. **PR**: Create pull request

### Code Style

- Follow Dart conventions
- Use `const` constructors where possible
- Keep methods under 50 lines
- Add comments for complex logic
- Use meaningful variable names

---

## License

See repository LICENSE file.

---

## Credits

**Original Desktop Version:**
- Author: Modestas Valauskas
- Repository: https://github.com/modulovalue/flutter_beat_sequencer

**Mobile Adaptation:**
- Implemented: Phase 1-4 mobile transformation
- Platform: Android & iOS native audio
- UI: Portrait-optimized touch interface

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0.0 | 2025-01 | Complete mobile redesign |
| | | - Native audio system (just_audio) |
| | | - Paginated mobile layout |
| | | - Touch-optimized controls |
| | | - BPM slider & visual metronome |
| | | - Portrait orientation lock |
| 0.1.0 | 2019 | Initial web version |

---

**End of Guide**
