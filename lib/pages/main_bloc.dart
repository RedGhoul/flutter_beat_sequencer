import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_beat_sequencer/services/audio_service.dart';
import 'package:flutter_beat_sequencer/pages/pattern.dart';

abstract class Playable {
  void playAtBeat(TimelineBloc bloc, int beat);
}

class PlaybackBloc extends ChangeNotifier implements Playable {
  final ValueNotifier<bool> _metronomeStatus = ValueNotifier<bool>(false);
  final ValueNotifier<int> _totalBeats = ValueNotifier<int>(32);
  final ValueNotifier<List<TrackBloc>> _tracks = ValueNotifier<List<TrackBloc>>([]);
  final AudioService audioService;

  ValueListenable<List<TrackBloc>> get tracks => _tracks;
  ValueListenable<bool> get metronomeStatus => _metronomeStatus;
  ValueListenable<int> get totalBeats => _totalBeats;
  late TimelineBloc timeline;

  PlaybackBloc(this.audioService) {
    final initialBeats = _totalBeats.value;

    final initialTracks = [
      TrackBloc(initialBeats, SoundSelector("808", () {
        audioService.playSound('bass');
      })),
      TrackBloc(initialBeats, SoundSelector("Clap", () {
        audioService.playSound('clap');
      })),
      TrackBloc(initialBeats, SoundSelector("Hat", () {
        audioService.playSound('hat');
      })),
      TrackBloc(initialBeats, SoundSelector("Open Hat", () {
        audioService.playSound('open_hat');
      })),
      TrackBloc(initialBeats, SoundSelector("Kick 1", () {
        audioService.playSound('kick_1');
      })),
      TrackBloc(initialBeats, SoundSelector("Kick 2", () {
        audioService.playSound('kick_2');
      })),
      TrackBloc(initialBeats, SoundSelector("Snare 1", () {
        audioService.playSound('snare_1');
      })),
      TrackBloc(initialBeats, SoundSelector("Snare 2", () {
        audioService.playSound('snare_2');
      })),
    ];

    _tracks.value = initialTracks;

    // Initialize timeline with dynamic beat count
    timeline = TimelineBloc(playAtBeat, _totalBeats);
  }

  @override
  void dispose() {
    _metronomeStatus.dispose();
    _totalBeats.dispose();
    for (final track in _tracks.value) {
      track.dispose();
    }
    _tracks.dispose();
    timeline.dispose();
    super.dispose();
  }

  @override
  void playAtBeat(TimelineBloc bloc, int beat) {
    if (_metronomeStatus.value && beat % 4 == 0) {
      if (beat % 16 == 0) {
        audioService.playSynth("C6", "32n");
      } else {
        audioService.playSynth("C5", "32n");
      }
    }
    _tracks.value.forEach((track) => track.playAtBeat(bloc, beat));
  }

  void toggleMetronome() {
    _metronomeStatus.value = !_metronomeStatus.value;
  }

  void addMeasure() {
    final newTotal = _totalBeats.value + 16; // Add 1 measure (16 beats)
    _totalBeats.value = newTotal;

    // Extend all tracks
    for (final track in _tracks.value) {
      track.extendPattern(newTotal);
    }
  }

  void removeMeasure() {
    if (_totalBeats.value > 16) { // Minimum 1 measure
      final newTotal = _totalBeats.value - 16;
      _totalBeats.value = newTotal;

      // Truncate all tracks
      for (final track in _tracks.value) {
        track.truncatePattern(newTotal);
      }

      // Reset beat position if needed
      if (timeline.atBeat.value >= newTotal) {
        timeline.setBeat(0);
      }
    }
  }

  void addTrack(String soundKey, String displayName) {
    final newTrack = TrackBloc(
      _totalBeats.value,
      SoundSelector(displayName, () {
        audioService.playSound(soundKey);
      }),
    );

    final updatedTracks = List<TrackBloc>.from(_tracks.value)..add(newTrack);
    _tracks.value = updatedTracks;
  }

  void removeTrack(int index) {
    if (_tracks.value.length > 1 && index >= 0 && index < _tracks.value.length) {
      final trackToRemove = _tracks.value[index];
      final updatedTracks = List<TrackBloc>.from(_tracks.value)..removeAt(index);
      _tracks.value = updatedTracks;

      // Dispose the removed track
      trackToRemove.dispose();
    }
  }

  int get measures => (_totalBeats.value / 16).ceil();
}

class TimelineBloc extends ChangeNotifier {
  final ValueNotifier<bool> _isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<double> _bpm = ValueNotifier<double>(160.0 * 4.0);
  final ValueNotifier<int> _atBeat = ValueNotifier<int>(-1);
  final ValueNotifier<int> _totalBeats;

  ValueListenable<bool> get isPlaying => _isPlaying;
  ValueListenable<double> get bpm => _bpm;
  ValueListenable<int> get atBeat => _atBeat;

  StreamSubscription<DateTime>? _metronome;
  final void Function(TimelineBloc, int) _playAtBeat;

  TimelineBloc(void Function(TimelineBloc, int) playAtBeat, this._totalBeats) : _playAtBeat = playAtBeat {
    _isPlaying.addListener(_onIsPlayingChanged);
    _bpm.addListener(_onBpmChanged);
  }

  void _onIsPlayingChanged() {
    _metronome?.cancel();
    _metronome = null;
    
    if (_isPlaying.value) {
      _startMetronome();
    }
  }

  void _onBpmChanged() {
    if (_isPlaying.value) {
      _metronome?.cancel();
      _metronome = null;
      _startMetronome();
    }
  }

  void _startMetronome() {
    _increaseAtBeat();
    _playAtBeat(this, _atBeat.value);
    final period = Duration(microseconds: (double bpm) {
      final beatsPerMicrosecond = bpm / Duration.microsecondsPerMinute;
      return 1 ~/ beatsPerMicrosecond;
    }(_bpm.value));
    _metronome = Stream.periodic(period, (count) => DateTime.now()).listen((data) {
      _increaseAtBeat();
      _playAtBeat(this, _atBeat.value);
    });
  }

  @override
  void dispose() {
    _isPlaying.removeListener(_onIsPlayingChanged);
    _bpm.removeListener(_onBpmChanged);
    _metronome?.cancel();
    _isPlaying.dispose();
    _bpm.dispose();
    _atBeat.dispose();
    super.dispose();
  }

  void togglePlayback() {
    _isPlaying.value = !_isPlaying.value;
  }

  void play() {
    _isPlaying.value = true;
  }

  void stop() {
    _isPlaying.value = false;
    _atBeat.value = -1;
  }

  void setBpm(double newBpm) {
    _bpm.value = newBpm;
  }

  void _increaseAtBeat() {
    _atBeat.value = _atBeat.value + 1;
    if (_atBeat.value >= _totalBeats.value) {
      _atBeat.value = 0;
    }
  }

  void setBeat(int i) {
    _atBeat.value = i;
  }
}

class TrackBloc extends ChangeNotifier implements Playable {
  final ValueNotifier<List<bool>> _isEnabled;
  ValueListenable<List<bool>> get isEnabled => _isEnabled;

  final SoundSelector sound;

  TrackBloc(int initWith, this.sound) : _isEnabled = ValueNotifier<List<bool>>(List.generate(initWith, (a) => false));

  @override
  void dispose() {
    _isEnabled.dispose();
    super.dispose();
  }

  void toggle(int index) {
    final cur = List<bool>.from(_isEnabled.value);
    if (cur.length > index) {
      cur[index] = !cur[index];
      _isEnabled.value = cur;
    }
  }

  @override
  void playAtBeat(TimelineBloc bloc, int beat) {
    if (_isEnabled.value.length > beat) {
      final play = _isEnabled.value[beat];
      if (play) {
        sound.play();
      }
    }
  }

  void playPreview() {
    sound.play();
  }

  void setPattern(TrackPattern pattern) {
    _isEnabled.value = _isEnabled.value
        .asMap()
        .keys
        .map(pattern.builder)
        .toList();
  }

  void extendPattern(int newLength) {
    final current = _isEnabled.value;
    final extended = List<bool>.generate(
      newLength,
      (i) => i < current.length ? current[i] : false,
    );
    _isEnabled.value = extended;
  }

  void truncatePattern(int newLength) {
    final current = _isEnabled.value;
    final truncated = current.sublist(0, newLength);
    _isEnabled.value = truncated;
  }
}

class SoundSelector {
  final String name;
  final void Function() play;

  const SoundSelector(this.name, this.play);
}
