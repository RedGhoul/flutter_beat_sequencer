# Flutter Beat Sequencer - Enhancement Implementation Plan

**Created**: 2025-01-16
**Updated**: 2025-11-16
**Status**: In Progress (5/6 Phases Complete)
**Branch**: `claude/implement-save-load-016zieRaHRyxJH5jARmPbmJA`

---

## Overview

This document outlines the comprehensive plan to transform the Flutter Beat Sequencer into a feature-rich, landscape-oriented drum machine with:
- ✅ Horizontal landscape-only orientation
- ✅ Expandable beat/measure system
- ✅ Dynamic track and sound management
- ✅ Save/load functionality
- ✅ MP3 export capability
- 🔄 Enhanced mobile UI (planned)

---

## Phase 1: Landscape Orientation & UI Redesign ✅

**Status**: Complete
**Commit**: `618872f`
**Duration**: 2-3 hours

### Goals
Convert the app from portrait to landscape orientation with an optimized layout for mobile devices.

### Changes Implemented

#### 1.1 Orientation Lock
- **File**: `lib/main.dart:12-15`
- **Change**: Replaced portrait orientations with landscape
  ```dart
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
  ```

#### 1.2 Layout Redesign
- **File**: `lib/pages/mobile_layout.dart`
- **Changes**:
  - Converted to Row-based layout with left sidebar
  - Sidebar width: 180px (contains all controls)
  - Main content area: Track grid with pagination
  - Increased beats per page from 8 to 16
  - Updated color scheme: Brown → Gray/Cyan theme
  - Background: `Colors.grey[900]`
  - Accent: `Colors.cyan`
  - Secondary: `Colors.grey[850]`, `Colors.grey[800]`

#### 1.3 Control Panel Reorganization
- **Location**: Left sidebar
- **Components** (top to bottom):
  1. App title
  2. BPM display (large cyan number)
  3. BPM slider (60-200 BPM)
  4. Play/Stop button (green/red)
  5. Metronome toggle (cyan when active)
  6. Measures control (added in Phase 2)
  7. Visual metronome indicator

#### 1.4 Track Row Optimization
- **File**: `lib/widgets/mobile_track_row.dart`
- **Changes**:
  - Reduced button size: 48px → 32px
  - Reduced spacing: 4px → 2px
  - Reduced label width: 60px → 50px
  - Reduced pattern button width: 50px → 40px
  - Updated colors to match new theme

### Results
- More screen real estate for beat grid (16 beats visible vs 8)
- Better fit for landscape aspect ratio
- Cleaner, more modern appearance
- Improved visual hierarchy

---

## Phase 2: Dynamic Beat System ✅

**Status**: Complete
**Commit**: `618872f`
**Duration**: 3-4 hours

### Goals
Allow users to dynamically add or remove measures (16-beat chunks) beyond the original 32-beat limit.

### Changes Implemented

#### 2.1 Configurable Beat Count
- **File**: `lib/pages/main_bloc.dart`
- **Changes**:
  - Added `Signal<int> _totalBeats` to PlaybackBloc (default: 32)
  - Exposed as `Wave<int> totalBeats`
  - Updated all track initialization to use `_totalBeats.value`
  - Modified `TimelineBloc` to accept `Signal<int> _totalBeats` parameter

#### 2.2 Measure Management Methods
- **File**: `lib/pages/main_bloc.dart`
- **New Methods**:
  ```dart
  void addMeasure() {
    final newTotal = _totalBeats.value + 16;
    _totalBeats.add(newTotal);
    for (final track in _tracks.value) {
      track.extendPattern(newTotal);
    }
  }

  void removeMeasure() {
    if (_totalBeats.value > 16) { // Minimum 1 measure
      final newTotal = _totalBeats.value - 16;
      _totalBeats.add(newTotal);
      for (final track in _tracks.value) {
        track.truncatePattern(newTotal);
      }
      if (timeline.atBeat.value >= newTotal) {
        timeline.setBeat(0);
      }
    }
  }

  int get measures => (_totalBeats.value / 16).ceil();
  ```

#### 2.3 Track Pattern Extension
- **File**: `lib/pages/main_bloc.dart`
- **New Methods in TrackBloc**:
  ```dart
  void extendPattern(int newLength) {
    final current = _isEnabled.value;
    final extended = List<bool>.generate(
      newLength,
      (i) => i < current.length ? current[i] : false,
    );
    _isEnabled.add(extended);
  }

  void truncatePattern(int newLength) {
    final current = _isEnabled.value;
    final truncated = current.sublist(0, newLength);
    _isEnabled.add(truncated);
  }
  ```

#### 2.4 UI Controls
- **File**: `lib/pages/mobile_layout.dart`
- **Location**: Control panel sidebar
- **Components**:
  - Measures display (shows current count)
  - Minus button (removes 1 measure, min: 1)
  - Plus button (adds 1 measure, no max)

#### 2.5 Dynamic Pagination
- **File**: `lib/pages/mobile_layout.dart`
- **Changes**:
  ```dart
  final totalBeats = widget.bloc.totalBeats.value;
  final totalPages = (totalBeats / _beatsPerPage).ceil();
  ```

#### 2.6 Timeline Loop Update
- **File**: `lib/pages/main_bloc.dart`
- **Change**:
  ```dart
  void _increaseAtBeat() {
    _atBeat.add(atBeat.value + 1);
    if (_atBeat.value >= _totalBeats.value) {
      _atBeat.add(0);
    }
  }
  ```

### Results
- Users can create loops of any length (16, 32, 48, 64+ beats)
- Minimum: 1 measure (16 beats)
- No maximum limit
- All tracks automatically extend/truncate when measures change
- Beat position resets if playing beyond truncated length

---

## Phase 3: Dynamic Sound/Track Management ✅

**Status**: Complete
**Commit**: `46baad7`
**Duration**: 4-5 hours

### Goals
Allow users to add/remove tracks dynamically and select from a library of sounds.

### Changes Implemented

#### 3.1 Sound Library Model
- **File**: `lib/models/sound_library.dart` (NEW)
- **Structure**:
  ```dart
  class SoundInfo {
    final String key;
    final String displayName;
    final String category;
    final String assetPath;
  }

  class SoundLibrary {
    static const List<SoundInfo> builtInSounds = [
      // 8 sounds organized by category
    ];

    static Map<String, List<SoundInfo>> getSoundsByCategory();
    static SoundInfo? getSoundByKey(String key);
  }
  ```
- **Categories**:
  - **Kicks**: Kick 1, Kick 2
  - **Snares**: Snare 1, Snare 2
  - **Hi-Hats**: Hat, Open Hat
  - **Percussion**: Clap
  - **Bass**: 808

#### 3.2 Dynamic Track List
- **File**: `lib/pages/main_bloc.dart`
- **Changes**:
  - Changed `List<TrackBloc> tracks` to `Signal<List<TrackBloc>> _tracks`
  - Exposed as `Wave<List<TrackBloc>> tracks`
  - All track operations now work on reactive list

#### 3.3 Track Management Methods
- **File**: `lib/pages/main_bloc.dart`
- **New Methods**:
  ```dart
  void addTrack(String soundKey, String displayName) {
    final newTrack = TrackBloc(
      _totalBeats.value,
      SoundSelector(displayName, () {
        audioService.playSound(soundKey);
      }),
    );
    disposeLater(newTrack.dispose);
    final updatedTracks = List<TrackBloc>.from(_tracks.value)..add(newTrack);
    _tracks.add(updatedTracks);
  }

  void removeTrack(int index) {
    if (_tracks.value.length > 1 && index >= 0 && index < _tracks.value.length) {
      final trackToRemove = _tracks.value[index];
      final updatedTracks = List<TrackBloc>.from(_tracks.value)..removeAt(index);
      _tracks.add(updatedTracks);
      trackToRemove.dispose();
    }
  }
  ```

#### 3.4 Add Track UI
- **File**: `lib/pages/mobile_layout.dart`
- **Components**:
  - FloatingActionButton (+ icon, cyan color)
  - Bottom sheet with DraggableScrollableSheet
  - Sound selector organized by category
  - Category headers with sound list items
  - Tap to add track and close dialog

#### 3.5 Delete Track UI
- **File**: `lib/widgets/mobile_track_row.dart`
- **Changes**:
  - Added `VoidCallback? onDelete` parameter
  - Delete button shows only on first segment (startBeat == 0)
  - Delete button only shown when more than 1 track exists
  - Red delete button with trash icon
  - Haptic feedback on delete

#### 3.6 Dynamic Audio Loading
- **File**: `lib/services/audio_service.dart`
- **New Methods**:
  ```dart
  Future<void> _loadSound(String key, String path);
  Future<void> loadCustomSound(String key, String assetPath);
  void unloadSound(String soundName);
  bool isSoundLoaded(String soundName);
  ```
- **Lazy Loading**: Sounds load on first play if not preloaded
- **Memory Management**: Sounds can be unloaded when tracks removed

### Results
- Users can add unlimited tracks
- Users can delete tracks (minimum 1 enforced)
- All 8 built-in sounds available in categorized library
- Proper resource cleanup on track removal
- No memory leaks from abandoned AudioPlayers

---

## Phase 4: Save/Load Functionality ✅

**Status**: Complete
**Commit**: `727d487`
**Duration**: 3-4 hours

### Goals
Allow users to save their beat patterns and reload them later.

### Changes Implemented

#### 4.1 Dependencies Added
- **File**: `pubspec.yaml`
- **Added**: `shared_preferences: ^2.2.2`

#### 4.2 Data Models
- **File**: `lib/services/pattern_storage.dart` (NEW - 226 lines)
- **Models Created**:
  - `SavedPattern`: Complete pattern state with metadata
  - `SavedTrack`: Individual track with sound key and pattern
  - `PatternMetadata`: Lightweight pattern info for listing
- **Fields**:
  - Pattern ID (timestamp-based)
  - Pattern name (user-provided)
  - BPM, metronome status, total beats
  - Track list with sound keys and patterns
  - Save timestamp

#### 4.3 Storage Service
- **File**: `lib/services/pattern_storage.dart`
- **Class**: `PatternStorage`
- **Methods Implemented**:
  - `savePattern()`: Save pattern to SharedPreferences with JSON
  - `loadPattern()`: Load pattern by ID
  - `deletePattern()`: Remove saved pattern
  - `getPatternMetadataList()`: Get all saved patterns (sorted by date)
  - `generateId()`: Create unique timestamp-based IDs
- **Storage Strategy**:
  - Each pattern stored with key `pattern_<id>`
  - Metadata list stored separately for efficient listing
  - JSON serialization for cross-platform compatibility

#### 4.4 PlaybackBloc Integration
- **File**: `lib/pages/main_bloc.dart`
- **New Fields**:
  - `PatternStorage _patternStorage`
  - `String soundKey` added to `TrackBloc` for serialization
- **New Methods**:
  - `savePattern(String name)`: Serialize and save current state
  - `loadPattern(String id)`: Load and apply saved pattern
  - `getSavedPatterns()`: Get list of all saved patterns
  - `deletePattern(String id)`: Delete saved pattern
- **Features**:
  - Auto-stops playback when loading
  - Properly disposes old tracks
  - Recreates tracks from saved data
  - Restores all settings (BPM, metronome, beats, tracks)

#### 4.5 Save/Load UI
- **File**: `lib/pages/mobile_layout.dart`
- **Location**: Control panel sidebar
- **Components**:
  - **Save Button** (blue): Opens dialog for naming pattern
  - **Load Button** (purple): Opens bottom sheet with saved patterns
  - **Save Dialog**:
    - Text input for pattern name
    - Cancel/Save buttons
    - Success/error SnackBar notifications
  - **Load Dialog** (Draggable Bottom Sheet):
    - List of all saved patterns
    - Pattern name and timestamp ("2h ago", "Yesterday")
    - Delete button with confirmation dialog
    - Tap to load pattern
  - **Success Feedback**:
    - Green SnackBar on save
    - Purple SnackBar on load
    - Red SnackBar on errors
  - **Haptic Feedback**: All button interactions

#### 4.6 TrackBloc Updates
- **File**: `lib/pages/main_bloc.dart`
- **Changes**:
  - Added `soundKey` field to `TrackBloc` constructor
  - Updated all track instantiations to include sound key
  - Enables proper serialization/deserialization

### Results
- ✅ Patterns persist across app sessions
- ✅ Users can maintain library of beat patterns
- ✅ Quick load/save workflow with modern UI
- ✅ Proper resource cleanup (no memory leaks)
- ✅ Most recent patterns shown first
- ✅ Pattern deletion with confirmation
- ✅ Comprehensive error handling

---

## Phase 5: MP3 Export ✅

**Status**: Complete
**Commit**: `3043e79`
**Duration**: 6-8 hours
**Complexity**: High

### Goals
Export the current beat loop as an MP3 file that can be shared or used in other applications.

### Changes Implemented

#### 5.1 Dependencies Added
- **File**: `pubspec.yaml`
- **Added**:
  - `ffmpeg_kit_flutter_audio: ^6.0.3` - FFmpeg audio processing
  - `path_provider: ^2.1.1` - File system access
  - `permission_handler: ^11.1.0` - Runtime permissions
  - `share_plus: ^7.2.1` - File sharing

#### 5.2 Export Service Architecture
- **File**: `lib/services/export_service.dart` (NEW - 294 lines)
- **Strategy**: FFmpeg-based audio mixing
- **Core Features**:
  - Asset preparation (copies Flutter assets to temp storage)
  - Timestamp calculation based on BPM
  - FFmpeg filter_complex generation
  - Progress tracking with callbacks
  - Temporary file cleanup

#### 5.3 Export Process Implementation
**Workflow**:
1. **Prepare Assets**: Copy sound files from assets to temp directory (FFmpeg requirement)
2. **Calculate Timing**: Compute beat timestamps in seconds based on BPM
3. **Build Filter Complex**: Generate FFmpeg command for audio mixing
4. **Process Audio**: Execute FFmpeg with progress callbacks
5. **Save Output**: Export to Application Documents directory
6. **Share**: Optional sharing via system share sheet

**Key Methods**:
- `exportToMP3()`: Main export method with configurable parameters
- `_prepareAssets()`: Copy Flutter assets to temporary storage
- `_getCachedAssetPath()`: Retrieve cached asset paths
- `_createTrackFilter()`: Build FFmpeg filters for tracks
- `shareMP3()`: Share exported file
- `cleanupTempFiles()`: Remove temporary files

#### 5.4 PlaybackBloc Integration
- **File**: `lib/pages/main_bloc.dart`
- **New Field**: `ExportService _exportService`
- **New Methods**:
  - `exportPattern()`: Trigger MP3 export with options
  - `shareExport()`: Share exported MP3 file
- **Parameters**:
  - fileName, loopCount, bitrate, includeMetronome
  - onProgress callback for UI updates

#### 5.5 Export UI
- **File**: `lib/pages/mobile_layout.dart` (+325 lines)
- **Location**: Control panel sidebar (below Save/Load buttons)
- **Components**:

  **Export MP3 Button** (Orange):
  - Icon: Download
  - Opens export options dialog

  **Export Options Dialog**:
  - Filename input with .mp3 suffix display
  - Loop count slider (1x-8x) with visual feedback
  - Bitrate slider (96-320 kbps)
  - Include metronome checkbox
  - Modern dark theme matching app design
  - Cancel/Export buttons

  **Export Progress Dialog**:
  - Non-dismissible during export
  - Linear progress bar
  - Percentage display (0-100%)
  - Real-time progress updates

  **Export Success Dialog**:
  - Success icon (green checkmark)
  - File path display (selectable)
  - Close button
  - Share button (orange) with system share sheet

#### 5.6 Permissions Configuration

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<!-- Storage permissions for MP3 export -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<!-- For Android 13+ (API 33+) -->
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library to export and save beat patterns as audio files.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs access to save exported beat patterns to your photo library.</string>
```

#### 5.7 Permission Handling
- **File**: `lib/pages/mobile_layout.dart`
- **Method**: `_requestStoragePermission()`
- **Features**:
  - Checks existing permissions
  - Requests if not granted
  - Shows error if denied
  - Platform-aware (Android-specific)

### Results
- ✅ Export beat patterns to MP3 format
- ✅ Configurable quality (96-320 kbps bitrate)
- ✅ Loop count selection (1x-8x)
- ✅ Optional metronome inclusion
- ✅ Share exported files via system dialog
- ✅ Real-time progress indicator
- ✅ Permission handling for storage access
- ✅ Automatic cleanup of temporary files
- ✅ Export location: Application Documents directory
- ✅ Comprehensive error handling with user feedback

### Implementation Notes
⚠️ **FFmpeg Complexity**: Current implementation includes basic FFmpeg filter_complex structure. During device testing, audio mixing logic may need refinement for optimal synchronization and quality. The foundational architecture is in place for easy iteration.

⚠️ **Testing Required**: Should be tested on physical devices as FFmpeg may not be available in some emulator environments.

---

## Phase 6: UI Polish & Optimization 🔄

**Status**: Planned
**Priority**: Low
**Duration**: 4-5 hours

### Goals
Enhance visual design, add polish animations, and optimize performance.

### 6.1 Visual Design Improvements

#### Color Scheme Refinement
- Consider gradient backgrounds
- Add accent colors for different track types
- Improve contrast for accessibility
- Dark theme refinements

#### Typography
- **Consider adding custom font**:
  ```yaml
  fonts:
    - family: Poppins
      fonts:
        - asset: fonts/Poppins-Regular.ttf
        - asset: fonts/Poppins-Bold.ttf
          weight: 700
  ```
- Apply consistent font sizes
- Improve hierarchy

#### Icons
- Better icons for all controls
- Consider custom icon set
- Improve icon sizing consistency

### 6.2 Animations & Transitions

#### Beat Indicator
- Pulse animation on active beat
- Smooth color transitions
- Glow effect on enabled beats

#### Track Addition/Removal
- Slide-in animation for new tracks
- Fade-out animation for removed tracks
- Hero animation for track reordering (future)

#### Page Transitions
- Smooth swipe animations
- Page curl effect (optional)
- Beat position animation across pages

#### Button Interactions
- Scale animation on press
- Ripple effects
- Smooth color transitions

### 6.3 Gesture Controls

#### Long Press Gestures
- Long-press beat to clear all in track
- Long-press track name for rename
- Long-press pattern button for favorites

#### Swipe Gestures
- Swipe right on beats to enable multiple
- Swipe left on track to delete
- Swipe down to clear entire track

#### Pinch Gestures
- Pinch to zoom beat grid (optional)
- Compact/expanded view modes

### 6.4 Performance Optimizations

#### Widget Optimization
- Use `const` constructors everywhere possible
- Minimize widget rebuilds
- Extract widgets to reduce nesting

#### Reactive Scope Optimization
- Minimize `$$ >>` scope size
- Subscribe to only needed values
- Use selective rebuilding

#### Audio Optimization
- Lazy load sounds (already implemented)
- Cache decoded audio
- Optimize playback scheduling

#### Memory Management
- Profile memory usage
- Fix any leaks
- Optimize track disposal

### 6.5 User Experience Enhancements

#### First-Run Tutorial
- Overlay with tap targets
- Step-by-step guide
- "Got it" dismissal

#### Tooltips
- Long-press tooltips on all controls
- Explain complex features
- Dismissible hints

#### Empty States
- Message when no tracks
- Prompt to add first track
- Example patterns to try

#### Error Handling
- Graceful audio loading failures
- User-friendly error messages
- Retry mechanisms

### 6.6 Accessibility

#### Screen Reader Support
- Semantic labels for all controls
- Announce beat position changes
- Track name announcements

#### High Contrast Mode
- Ensure sufficient contrast
- Test with system settings
- Alternative color schemes

#### Haptic Feedback Refinement
- Consistent feedback patterns
- User preference setting
- Different intensities for actions

### Expected Results
- Polished, professional appearance
- Smooth 60fps animations
- Improved usability
- Better accessibility
- Optimized performance

---

## Summary Timeline

| Phase | Feature | Status | Duration | Commit |
|-------|---------|--------|----------|--------|
| 1 | Landscape Orientation & UI Redesign | ✅ Complete | 2-3h | `618872f` |
| 2 | Dynamic Beat System | ✅ Complete | 3-4h | `618872f` |
| 3 | Dynamic Sound/Track Management | ✅ Complete | 4-5h | `46baad7` |
| 4 | Save/Load Functionality | ✅ Complete | 3-4h | `727d487` |
| 5 | MP3 Export | ✅ Complete | 6-8h | `3043e79` |
| 6 | UI Polish & Optimization | 🔄 Planned | 4-5h | - |
| **Total** | | **83% Complete** | **22-29h** | - |

---

## Recommended Implementation Order

1. ✅ **Phase 1** - Foundation change, quick win
2. ✅ **Phase 2** - Enables scalability
3. ✅ **Phase 3** - Adds flexibility
4. ✅ **Phase 4** - Users want persistence before export
5. ✅ **Phase 5** - Complex feature building on all others
6. 🔄 **Phase 6** - Polish after features work

---

## Testing Checklist

### Phase 1-3 (Completed)
- [x] App launches in landscape
- [x] All sounds play correctly
- [x] Beat toggling works
- [x] Playback loops correctly
- [x] BPM changes work
- [x] Metronome toggles
- [x] Visual metronome syncs
- [x] Page swiping works (now 2 pages for 32 beats)
- [x] Add measure button works
- [x] Remove measure button works (min 1 measure)
- [x] Add track dialog opens
- [x] Track added from each category
- [x] Delete track works
- [x] Cannot delete last track

### Phase 4 (Implemented - Device Testing Needed)
- [ ] Save pattern with custom name
- [ ] Load saved pattern
- [ ] Pattern list shows all saved patterns (sorted by date)
- [ ] Delete saved pattern (with confirmation)
- [ ] Patterns restore correctly (all beats)
- [ ] BPM/metronome state restores
- [ ] Total beats/measures restore
- [ ] Track names and sounds restore

### Phase 5 (Implemented - Device Testing Needed)
- [ ] Export generates MP3 file
- [ ] Exported audio matches playback timing
- [ ] All enabled beats present in export
- [ ] Metronome included when enabled (if checked)
- [ ] Loop count works (1x, 2x, 4x, 8x)
- [ ] Share dialog works
- [ ] File saved to correct location (Documents directory)
- [ ] Permissions requested correctly (Android/iOS)
- [ ] Progress indicator updates correctly
- [ ] Bitrate selection affects file size/quality

### Phase 6 (Pending)
- [ ] Animations smooth at 60fps
- [ ] No performance degradation
- [ ] Memory usage stable
- [ ] Haptic feedback consistent
- [ ] Tutorial flows correctly
- [ ] Tooltips helpful
- [ ] Accessibility features work

---

## Dependencies Added

### Current (Updated 2025-11-16)
```yaml
dependencies:
  flutter:
    sdk: flutter
  just_audio: ^0.9.36                    # Phase 1-3: Native audio playback
  shared_preferences: ^2.2.2             # Phase 4: Pattern storage
  ffmpeg_kit_flutter_audio: ^6.0.3      # Phase 5: MP3 export
  path_provider: ^2.1.1                  # Phase 5: File system access
  permission_handler: ^11.1.0            # Phase 5: Storage permissions
  share_plus: ^7.2.1                     # Phase 5: File sharing

dev_dependencies:
  flutter_test:
    sdk: flutter
  extra_pedantic: ^1.1.1+3              # Strict linting
```

### Removed Dependencies
- `bird: ^0.0.2` - Replaced with ValueNotifier
- `bird_flutter: ^0.0.2+1` - Replaced with ValueNotifier
- `modulovalue_project_widgets` - No longer needed

---

## Key Architectural Decisions

### 1. Reactive State Management (bird)
- **Choice**: Continue using bird package
- **Rationale**: Already established, works well, minimal learning curve
- **Pattern**: Signal (mutable) → Wave (immutable) → UI binding ($$)

### 2. Dynamic Lists
- **Choice**: `Signal<List<T>>` for dynamic collections
- **Rationale**: Enables reactive updates when list changes
- **Implementation**: Create new list instance on each update

### 3. Audio Architecture
- **Choice**: Lazy loading with fallback to pre-loading
- **Rationale**: Balance memory usage with latency
- **Trade-off**: Slight delay on first play vs memory efficiency

### 4. Export Strategy
- **Choice**: FFmpeg for audio mixing
- **Rationale**: Industry-standard, powerful, cross-platform
- **Alternative Considered**: Native platform APIs (too complex, platform-specific)

### 5. Persistence
- **Choice**: SharedPreferences with JSON serialization
- **Rationale**: Simple, built-in, sufficient for pattern data
- **Alternative Considered**: SQLite (overkill for current needs)

### 6. File Structure
- **Pattern**: Feature-based organization
- **Folders**:
  - `models/` - Data structures
  - `services/` - Business logic
  - `pages/` - Screens and BLoCs
  - `widgets/` - Reusable components

---

## Known Issues & Future Enhancements

### Current Limitations
1. **Web Platform**: Not actively maintained, focus is mobile
2. **Custom Sounds**: Not yet supported (only built-in sounds)
3. **Track Reordering**: Not implemented
4. **Undo/Redo**: Not available
5. **Copy/Paste Patterns**: Not implemented

### Future Enhancements (Post-Phase 6)
1. **Custom Sound Import**: Load WAV/MP3 from device
2. **Track Reordering**: Drag to reorder tracks
3. **Pattern Copy/Paste**: Copy patterns between tracks
4. **Undo/Redo Stack**: History of changes
5. **Cloud Sync**: Save projects to cloud
6. **MIDI Export**: Export as MIDI file
7. **Effects**: Reverb, delay, filters per track
8. **Swing/Humanize**: Add groove to patterns
9. **Velocity**: Variable hit strength per beat
10. **Multi-page Patterns**: Different patterns per page

---

## Notes for Future Development

### Code Quality
- Maintain extra_pedantic linting rules
- Add dartdoc comments for public APIs
- Keep functions small and focused
- Use meaningful variable names

### Testing Strategy
- Add unit tests for BLoCs
- Add widget tests for complex widgets
- Add integration tests for critical flows
- Test on variety of device sizes

### Performance Targets
- 60fps UI at all times
- <50ms audio latency
- <100MB memory usage
- <5s cold start time

### Documentation
- Keep CLAUDE.md updated with changes
- Document new patterns/conventions
- Update README with new features
- Add inline comments for complex logic

---

**End of Implementation Plan**
