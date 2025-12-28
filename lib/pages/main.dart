import 'package:flutter/material.dart';
import 'package:flutter_beat_sequencer/pages/main_bloc.dart';
import 'package:flutter_beat_sequencer/pages/pattern.dart';
import 'package:flutter_beat_sequencer/widgets/title.dart';
import 'package:flutter_beat_sequencer/services/audio_service.dart';

class MainPage extends StatefulWidget {
  final AudioService audioService;

  const MainPage({Key? key, required this.audioService}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late PlaybackBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = PlaybackBloc(widget.audioService);
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[800],
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ...modulovalueTitle(
                "Flutter Beat Sequencer",
                "flutter_beat_sequencer",
              ).map((widget) => DefaultTextStyle(
                    style: TextStyle(color: Colors.white),
                    child: widget,
                  )),
              SizedBox(height: 12.0),
              ValueListenableBuilder<double>(
                valueListenable: _bloc.timeline.bpm,
                builder: (context, bpmValue, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _bloc.timeline.isPlaying,
                    builder: (context, playing, _) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: _bloc.metronomeStatus,
                        builder: (context, metronomeStatus, _) {
                          final bpm = bpmValue / 4.0;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text("BPM: $bpm",
                                  style: TextStyle(color: Colors.white)),
                              SizedBox(width: 8.0),
                              TextButton(
                                onPressed: _bloc.timeline.togglePlayback,
                                child: Icon(
                                  playing ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                              ),
                              TextButton(
                                onPressed: _bloc.timeline.stop,
                                child: Icon(Icons.stop, color: Colors.white),
                              ),
                              TextButton(
                                onPressed: _bloc.toggleMetronome,
                                child: Text(
                                  metronomeStatus
                                      ? "Metronome On"
                                      : "Metronome Off",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
              _beatIndicator(_bloc.timeline),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
                decoration: BoxDecoration(
                  color: Colors.brown[900],
                ),
                child: ValueListenableBuilder<List<TrackBloc>>(
                  valueListenable: _bloc.tracks,
                  builder: (context, tracks, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: tracks.map((track) => _track(track)).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _beatIndicator(TimelineBloc bloc) {
  return ValueListenableBuilder<int>(
    valueListenable: bloc.atBeat,
    builder: (context, beat, _) {
      return SizedBox(
        height: 14.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 50),
            SizedBox(width: 8.0),
            SizedBox(width: 50),
            SizedBox(width: 8.0),
            ...List.generate(32, (i) {
              return GestureDetector(
                onTap: () => bloc.setBeat(i - 1),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5.0),
                      color: i == beat
                          ? Colors.white
                          : Colors.white.withOpacity(0.05),
                    ),
                    width: 28.0,
                  ),
                ),
              );
            }),
          ],
        ),
      );
    },
  );
}

Widget _track(TrackBloc bloc) {
  return ValueListenableBuilder<List<bool>>(
    valueListenable: bloc.isEnabled,
    builder: (context, enabled, _) {
      return SizedBox(
        height: 42.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: bloc.sound.play,
              child: SizedBox(
                width: 50,
                child: Text(
                  bloc.sound.name,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            SizedBox(width: 8.0),
            SizedBox(
              width: 50.0,
              child: IconButton(
                icon: Icon(Icons.more_horiz, color: Colors.white),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(bloc.sound.name),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: allPatterns().map((pattern) {
                              return ListTile(
                                title: Text(pattern.name),
                                onTap: () {
                                  bloc.setPattern(pattern);
                                  Navigator.of(context).pop();
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(width: 8.0),
            ...enabled.asMap().entries.map((a) {
              return TrackStep(
                beat: a.key,
                selected: a.value,
                onPressed: () => bloc.toggle(a.key),
              );
            })
          ],
        ),
      );
    },
  );
}

class TrackStep extends StatelessWidget {
  final bool selected;
  final int beat;
  final void Function() onPressed;

  const TrackStep({
    required this.beat,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2.0),
        child: Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: selected
                ? Colors.white
                : (beat % 4 == 0
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.07)),
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
      ),
    );
  }
}
