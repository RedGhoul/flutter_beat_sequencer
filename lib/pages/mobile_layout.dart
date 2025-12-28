import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_bloc.dart';
import 'track_editor.dart';
import '../widgets/mobile_track_row.dart';
import '../models/sound_library.dart';
import '../services/pattern_storage.dart';
import '../services/layout_metrics.dart';
import 'package:permission_handler/permission_handler.dart';

class MobileSequencerLayout extends StatefulWidget {
  final PlaybackBloc bloc;

  const MobileSequencerLayout({Key? key, required this.bloc}) : super(key: key);

  @override
  State<MobileSequencerLayout> createState() => _MobileSequencerLayoutState();
}

class _MobileSequencerLayoutState extends State<MobileSequencerLayout> {
  int _currentPage = 0;
  int _beatsPerPage = 16; // Updated dynamically based on available width.
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.bloc.totalBeats,
      builder: (context, totalBeats, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final metrics = LayoutMetrics.fromConstraints(constraints, context);
            final beatsPerPage = metrics.calculateBeatsPerPage(
              availableWidth: constraints.maxWidth,
            );
            if (beatsPerPage != _beatsPerPage) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _beatsPerPage = beatsPerPage;
                  });
                }
              });
            }
            final totalPages = (totalBeats / _beatsPerPage).ceil();
            if (_currentPage >= totalPages && totalPages > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                final newPage = totalPages - 1;
                setState(() {
                  _currentPage = newPage;
                });
                _pageController.jumpToPage(newPage);
              });
            }

            final content = Column(
              children: [
                // Top bar with transport, page indicator, and beat indicator
                Container(
                  color: Colors.grey[850],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    children: [
                      _buildCompactTransportBar(),
                      const SizedBox(height: 6),
                      _buildPageIndicator(totalPages),
                      const SizedBox(height: 6),
                      _buildBeatIndicator(),
                    ],
                  ),
                ),

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
            );

            return Scaffold(
              backgroundColor: Colors.grey[900],
              floatingActionButton: Semantics(
                label: 'Add new track',
                button: true,
                child: FloatingActionButton(
                  onPressed: () => _showAddTrackDialog(context),
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black,
                  child: const Icon(Icons.add),
                  tooltip: 'Add Track',
                ),
              ),
              body: SafeArea(
                child: metrics.isCompactWidth
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: metrics.gridWidth(beatsPerPage: _beatsPerPage),
                          child: content,
                        ),
                      )
                    : content,
              ),
            );
          },
        );
      },
    );
  }

  void _showControlPanelSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[850],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.85;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: _buildControlPanel(),
          ),
        );
      },
    );
  }

  Widget _buildCompactTransportBar() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.bloc.timeline.isPlaying,
      builder: (context, isPlaying, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: widget.bloc.metronomeStatus,
          builder: (context, metronomeOn, _) {
            return ValueListenableBuilder<double>(
              valueListenable: widget.bloc.timeline.bpm,
              builder: (context, bpmValue, _) {
                final bpm = (bpmValue / 4.0).round();

                return Row(
                  children: [
                    IconButton(
                      onPressed: () => _showControlPanelSheet(context),
                      icon: const Icon(Icons.tune, color: Colors.white),
                      tooltip: 'Controls',
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showControlPanelSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'BPM $bpm',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (isPlaying) {
                          widget.bloc.timeline.stop();
                        } else {
                          widget.bloc.timeline.play();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        backgroundColor:
                            isPlaying ? Colors.red[700] : Colors.green[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Icon(
                        isPlaying ? Icons.stop : Icons.play_arrow,
                        size: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: widget.bloc.toggleMetronome,
                      icon: Icon(
                        metronomeOn ? Icons.volume_up : Icons.volume_off,
                        color: metronomeOn ? Colors.cyan : Colors.white,
                      ),
                      tooltip: 'Metronome',
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildControlPanel() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.bloc.timeline.isPlaying,
      builder: (context, isPlaying, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: widget.bloc.metronomeStatus,
          builder: (context, metronomeOn, _) {
            return ValueListenableBuilder<double>(
              valueListenable: widget.bloc.timeline.bpm,
              builder: (context, bpmValue, _) {
                final bpm = (bpmValue / 4.0).round();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App title
                      const Text(
                        'Beat\nSequencer',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      // BPM display
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'BPM',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$bpm',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyan,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // BPM slider (vertical orientation)
                      Text(
                        'Tempo',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Semantics(
                        label: 'Tempo slider, current BPM: $bpm',
                        value: '$bpm beats per minute',
                        slider: true,
                        child: Slider(
                          value: bpm.toDouble(),
                          min: 60.0,
                          max: 200.0,
                          divisions: 140,
                          label: '$bpm',
                          onChanged: (value) {
                            widget.bloc.timeline.setBpm(value * 4.0);
                          },
                          activeColor: Colors.cyan,
                          inactiveColor: Colors.grey[700],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Play/Stop button
                      Semantics(
                        label: isPlaying ? 'Stop playback' : 'Start playback',
                        button: true,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isPlaying) {
                              widget.bloc.timeline.stop();
                            } else {
                              widget.bloc.timeline.play();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor:
                                isPlaying ? Colors.red[700] : Colors.green[600],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPlaying ? Icons.stop : Icons.play_arrow,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isPlaying ? 'Stop' : 'Play',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Metronome toggle
                      Semantics(
                        label: metronomeOn
                            ? 'Turn metronome off'
                            : 'Turn metronome on',
                        button: true,
                        child: ElevatedButton(
                          onPressed: widget.bloc.toggleMetronome,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor:
                                metronomeOn ? Colors.cyan : Colors.grey[800],
                            foregroundColor:
                                metronomeOn ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                metronomeOn
                                    ? Icons.volume_up
                                    : Icons.volume_off,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Metro',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Save/Load/Export buttons
                      Row(
                        children: [
                          Expanded(
                            child: Tooltip(
                              message: 'Save current pattern',
                              child: ElevatedButton(
                                onPressed: () =>
                                    _showSavePatternDialog(context),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.save, size: 18),
                                    SizedBox(height: 2),
                                    Text('Save',
                                        style: TextStyle(fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Tooltip(
                              message: 'Load saved pattern',
                              child: ElevatedButton(
                                onPressed: () =>
                                    _showLoadPatternDialog(context),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: Colors.purple[700],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.folder_open, size: 18),
                                    SizedBox(height: 2),
                                    Text('Load',
                                        style: TextStyle(fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Export button
                      Tooltip(
                        message: widget.bloc.isExportAvailable
                            ? 'Export pattern to MP3 file'
                            : 'Export disabled in this build',
                        child: ElevatedButton(
                          onPressed: widget.bloc.isExportAvailable
                              ? () => _showExportDialog(context)
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download, size: 18),
                              SizedBox(width: 6),
                              Text('Export MP3',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Measures control
                      Builder(
                        builder: (context) {
                          final measures = widget.bloc.measures;

                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Measures',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$measures',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.cyan,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Tooltip(
                                        message: 'Remove a measure (16 beats)',
                                        child: ElevatedButton(
                                          onPressed: widget.bloc.removeMeasure,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            backgroundColor: Colors.grey[700],
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: const Icon(Icons.remove,
                                              size: 18),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Tooltip(
                                        message: 'Add a measure (16 beats)',
                                        child: ElevatedButton(
                                          onPressed: widget.bloc.addMeasure,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            backgroundColor: Colors.cyan,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          child:
                                              const Icon(Icons.add, size: 18),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Visual metronome
                      Center(
                        child: ValueListenableBuilder<int>(
                          valueListenable: widget.bloc.timeline.atBeat,
                          builder: (context, currentBeat, _) {
                            final isDownbeat = currentBeat % 4 == 0;
                            final isBar = currentBeat % 16 == 0;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isBar
                                    ? Colors.red[600]
                                    : (isDownbeat
                                        ? Colors.cyan
                                        : Colors.grey[800]),
                                boxShadow: (isBar || isDownbeat)
                                    ? [
                                        BoxShadow(
                                          color:
                                              (isBar ? Colors.red : Colors.cyan)
                                                  .withOpacity(0.6),
                                          blurRadius: 15,
                                          spreadRadius: 3,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${(currentBeat % 4) + 1}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPageIndicator(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Page ${_currentPage + 1}/$totalPages',
          style: TextStyle(color: Colors.grey[400], fontSize: 11),
        ),
        const SizedBox(width: 10),
        ...List.generate(totalPages, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: _currentPage == index ? 24 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: _currentPage == index ? Colors.cyan : Colors.grey[700],
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBeatIndicator() {
    return ValueListenableBuilder<int>(
      valueListenable: widget.bloc.timeline.atBeat,
      builder: (context, currentBeat, _) {
        final metrics = LayoutMetrics.fromContext(context);
        final startBeat = _currentPage * _beatsPerPage;

        return SizedBox(
          height: 20,
          child: Row(
            children: [
              SizedBox(width: metrics.beatIndicatorLeadingInset),
              Expanded(
                child: Row(
                  children: List.generate(_beatsPerPage, (index) {
                    final beatIndex = startBeat + index;
                    final isActive = currentBeat == beatIndex;
                    final isFourBeat = beatIndex % 4 == 0;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.bloc.timeline.setBeat(beatIndex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.cyan
                                : (isFourBeat
                                    ? Colors.grey[700]
                                    : Colors.grey[800]),
                            borderRadius: BorderRadius.circular(3),
                            border: isFourBeat
                                ? Border.all(color: Colors.grey[600]!, width: 1)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${beatIndex % 16 + 1}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ).copyWith(
                                color:
                                    isActive ? Colors.black : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(width: metrics.beatIndicatorTrailingInset),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackGrid(int pageIndex) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.bloc.totalBeats,
      builder: (context, totalBeats, _) {
        final startBeat = pageIndex * _beatsPerPage;
        final endBeat = (startBeat + _beatsPerPage).clamp(0, totalBeats);

        return _buildTrackGridContent(startBeat, endBeat);
      },
    );
  }

  Widget _buildTrackGridContent(int startBeat, int endBeat) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.bloc.timeline.atBeat,
      builder: (context, currentBeat, _) {
        return ValueListenableBuilder<List<TrackBloc>>(
          valueListenable: widget.bloc.tracks,
          builder: (context, tracksList, _) {
            final metrics = LayoutMetrics.fromContext(context);
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                8,
                8,
                8 + MediaQuery.of(context).padding.right,
                8 +
                    MediaQuery.of(context).padding.bottom +
                    metrics.contentBottomPadding,
              ),
              itemCount: tracksList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, trackIndex) {
                final track = tracksList[trackIndex];
                final isDeletable = tracksList.length > 1;
                final onDelete = isDeletable
                    ? () => widget.bloc.removeTrack(trackIndex)
                    : null;

                Widget row = TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.grey[850],
                    elevation: 1,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: MobileTrackRow(
                        track: track,
                        currentBeat: currentBeat,
                        startBeat: startBeat,
                        endBeat: endBeat,
                        onDelete: onDelete,
                        onOpenEditor: metrics.isCompactWidth
                            ? () => _openTrackEditor(context, track, onDelete)
                            : null,
                      ),
                    ),
                  ),
                );
                if (onDelete == null) {
                  return row;
                }

                return Dismissible(
                  key: ValueKey('track-$trackIndex-${track.sound.name}'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) =>
                      _confirmDeleteTrack(context, track.sound.name),
                  onDismissed: (_) => onDelete(),
                  background: Container(
                    color: Colors.red[800],
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child:
                        const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  child: row,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmDeleteTrack(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Delete Track',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete "$name" from the pattern?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openTrackEditor(
    BuildContext context,
    TrackBloc track,
    VoidCallback? onDelete,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackEditorPage(
          bloc: widget.bloc,
          track: track,
          onDelete: onDelete,
        ),
      ),
    );
  }

  void _showAddTrackDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    final soundsByCategory = SoundLibrary.getSoundsByCategory();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[850],
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Add Track',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: soundsByCategory.entries.map((entry) {
                      final category = entry.key;
                      final sounds = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyan,
                              ),
                            ),
                          ),
                          ...sounds.map((sound) => ListTile(
                                leading: const Icon(Icons.music_note,
                                    color: Colors.cyan),
                                title: Text(
                                  sound.displayName,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  widget.bloc
                                      .addTrack(sound.key, sound.displayName);
                                  Navigator.pop(context);
                                },
                              )),
                          Divider(color: Colors.grey[800]),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSavePatternDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Save Pattern',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Pattern name',
            hintStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyan),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyan, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                return;
              }

              Navigator.pop(context);

              try {
                await widget.bloc.savePattern(name);
                HapticFeedback.lightImpact();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pattern "$name" saved!'),
                      backgroundColor: Colors.green[700],
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error saving pattern: $e'),
                      backgroundColor: Colors.red[700],
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLoadPatternDialog(BuildContext context) async {
    HapticFeedback.mediumImpact();

    // Load the list of saved patterns
    final patterns = await widget.bloc.getSavedPatterns();

    if (!context.mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[850],
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Load Pattern',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: patterns.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.music_note_outlined,
                                size: 64,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Saved Patterns',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a pattern and save it\nto see it here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: patterns.length,
                          separatorBuilder: (context, index) =>
                              Divider(color: Colors.grey[800]),
                          itemBuilder: (context, index) {
                            final pattern = patterns[index];
                            final formattedDate =
                                _formatDateTime(pattern.savedAt);

                            return ListTile(
                              leading:
                                  Icon(Icons.music_note, color: Colors.purple),
                              title: Text(
                                pattern.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Saved: $formattedDate',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.delete,
                                        color: Colors.red[400]),
                                    onPressed: () async {
                                      HapticFeedback.mediumImpact();

                                      // Confirm deletion
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: Colors.grey[850],
                                          title: Text(
                                            'Delete Pattern?',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          content: Text(
                                            'Are you sure you want to delete "${pattern.name}"?',
                                            style: TextStyle(
                                                color: Colors.white70),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text('Cancel',
                                                  style: TextStyle(
                                                      color: Colors.grey[400])),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.red[700],
                                              ),
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        await widget.bloc
                                            .deletePattern(pattern.id);
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text('Pattern deleted'),
                                              backgroundColor: Colors.red[700],
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () async {
                                HapticFeedback.selectionClick();
                                Navigator.pop(context);

                                try {
                                  await widget.bloc.loadPattern(pattern.id);
                                  HapticFeedback.lightImpact();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Pattern "${pattern.name}" loaded!'),
                                        backgroundColor: Colors.purple[700],
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error loading pattern: $e'),
                                        backgroundColor: Colors.red[700],
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    final TextEditingController nameController =
        TextEditingController(text: 'my_beat');
    int loopCount = 1;
    int bitrate = 128;
    bool includeMetronome = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[850],
            title: Text(
              'Export to MP3',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filename input
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'File name',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      suffixText: '.mp3',
                      suffixStyle: TextStyle(color: Colors.cyan),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyan),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyan, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Loop count
                  Text('Loop Count',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  Slider(
                    value: loopCount.toDouble(),
                    min: 1,
                    max: 8,
                    divisions: 7,
                    label: '${loopCount}x',
                    activeColor: Colors.orange,
                    onChanged: (value) {
                      setState(() {
                        loopCount = value.toInt();
                      });
                    },
                  ),
                  Text('${loopCount}x',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  SizedBox(height: 10),

                  // Bitrate
                  Text('Bitrate (kbps)',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  Slider(
                    value: bitrate.toDouble(),
                    min: 96,
                    max: 320,
                    divisions: 7,
                    label: '$bitrate kbps',
                    activeColor: Colors.orange,
                    onChanged: (value) {
                      setState(() {
                        bitrate =
                            (value / 32).round() * 32; // Round to nearest 32
                      });
                    },
                  ),
                  Text('$bitrate kbps',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  SizedBox(height: 10),

                  // Metronome checkbox
                  CheckboxListTile(
                    title: Text('Include Metronome',
                        style: TextStyle(color: Colors.white)),
                    value: includeMetronome,
                    activeColor: Colors.orange,
                    onChanged: (value) {
                      setState(() {
                        includeMetronome = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    Text('Cancel', style: TextStyle(color: Colors.grey[400])),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    return;
                  }

                  Navigator.pop(context);

                  // Show progress dialog
                  _showExportProgressDialog(
                    context,
                    name,
                    loopCount,
                    bitrate,
                    includeMetronome,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
                child: Text('Export'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportProgressDialog(
    BuildContext context,
    String fileName,
    int loopCount,
    int bitrate,
    bool includeMetronome,
  ) async {
    double progress = 0.0;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[850],
            title: Text('Exporting...', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[700],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                SizedBox(height: 16),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      // Check and request storage permission
      if (!await _requestStoragePermission()) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Storage permission required for export'),
              backgroundColor: Colors.red[700],
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Perform export
      final filePath = await widget.bloc.exportPattern(
        fileName: fileName,
        loopCount: loopCount,
        bitrate: bitrate,
        includeMetronome: includeMetronome,
        onProgress: (p) {
          if (context.mounted) {
            setState(() {
              progress = p;
            });
          }
        },
      );

      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog

        if (filePath != null) {
          // Show success dialog
          _showExportSuccessDialog(context, filePath);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed. Please try again.'),
              backgroundColor: Colors.red[700],
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: Colors.red[700],
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showExportSuccessDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Export Successful!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your beat has been exported to:',
              style: TextStyle(color: Colors.grey[400]),
            ),
            SizedBox(height: 8),
            SelectableText(
              filePath,
              style: TextStyle(color: Colors.cyan, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await widget.bloc.shareExport(filePath);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Share error: $e'),
                      backgroundColor: Colors.red[700],
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            icon: Icon(Icons.share),
            label: Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _requestStoragePermission() async {
    // On Android, check storage permission
    if (await Permission.storage.isGranted) {
      return true;
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}
