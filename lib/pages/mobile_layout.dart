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

              // BPM slider
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
