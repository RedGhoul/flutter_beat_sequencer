import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_bloc.dart';
import '../widgets/mobile_track_row.dart';
import '../models/sound_library.dart';
import '../services/pattern_storage.dart';

class MobileSequencerLayout extends StatefulWidget {
  final PlaybackBloc bloc;

  const MobileSequencerLayout({Key? key, required this.bloc}) : super(key: key);

  @override
  State<MobileSequencerLayout> createState() => _MobileSequencerLayoutState();
}

class _MobileSequencerLayoutState extends State<MobileSequencerLayout> {
  int _currentPage = 0;
  final int _beatsPerPage = 16; // Show 16 beats per page in landscape
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
        final totalPages = (totalBeats / _beatsPerPage).ceil();

        return Scaffold(
      backgroundColor: Colors.grey[900],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTrackDialog(context),
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.black,
        child: Icon(Icons.add),
        tooltip: 'Add Track',
      ),
      body: Row(
        children: [
          // Left sidebar - Control panel
          Container(
            width: 180,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(2, 0),
                ),
              ],
            ),
            child: _buildControlPanel(),
          ),

          // Main content - Track grid
          Expanded(
            child: Column(
              children: [
                // Top bar with page indicator and beat indicator
                Container(
                  color: Colors.grey[850],
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      _buildPageIndicator(totalPages),
                      SizedBox(height: 6),
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
            ),
          ),
        ],
      ),
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
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App title
            Text(
              'Beat\nSequencer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20),

            // BPM display
            Container(
              padding: EdgeInsets.symmetric(vertical: 12),
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
                  SizedBox(height: 4),
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

            SizedBox(height: 12),

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
            Slider(
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

            SizedBox(height: 16),

            // Play/Stop button
            ElevatedButton(
              onPressed: () {
                if (isPlaying) {
                  widget.bloc.timeline.stop();
                } else {
                  widget.bloc.timeline.play();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isPlaying ? Colors.red[700] : Colors.green[600],
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
                  SizedBox(width: 8),
                  Text(
                    isPlaying ? 'Stop' : 'Play',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10),

            // Metronome toggle
            ElevatedButton(
              onPressed: widget.bloc.toggleMetronome,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                backgroundColor: metronomeOn ? Colors.cyan : Colors.grey[800],
                foregroundColor: metronomeOn ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    metronomeOn ? Icons.volume_up : Icons.volume_off,
                    size: 20,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Metro',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Save/Load buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showSavePatternDialog(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save, size: 18),
                        SizedBox(height: 2),
                        Text('Save', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showLoadPatternDialog(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.purple[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open, size: 18),
                        SizedBox(height: 2),
                        Text('Load', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Measures control
            Builder(
              builder: (context) {
                final measures = widget.bloc.measures;

                return Container(
                padding: EdgeInsets.all(10),
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
                    SizedBox(height: 6),
                    Text(
                      '$measures',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.bloc.removeMeasure,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: Colors.grey[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Icon(Icons.remove, size: 18),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.bloc.addMeasure,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: Colors.cyan,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Icon(Icons.add, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
              },
            ),

            SizedBox(height: 20),

            // Visual metronome
            Center(
              child: ValueListenableBuilder<int>(
                valueListenable: widget.bloc.timeline.atBeat,
                builder: (context, currentBeat, _) {
                final isDownbeat = currentBeat % 4 == 0;
                final isBar = currentBeat % 16 == 0;

                return AnimatedContainer(
                  duration: Duration(milliseconds: 100),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isBar
                        ? Colors.red[600]
                        : (isDownbeat ? Colors.cyan : Colors.grey[800]),
                    boxShadow: (isBar || isDownbeat)
                        ? [
                            BoxShadow(
                              color: (isBar ? Colors.red : Colors.cyan)
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
                      style: TextStyle(
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
        SizedBox(width: 10),
        ...List.generate(totalPages, (index) {
          return Container(
            width: _currentPage == index ? 24 : 6,
            height: 6,
            margin: EdgeInsets.symmetric(horizontal: 3),
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
        final startBeat = _currentPage * _beatsPerPage;

        return Container(
        height: 20,
        child: Row(
          children: List.generate(_beatsPerPage, (index) {
            final beatIndex = startBeat + index;
            final isActive = currentBeat == beatIndex;
            final isFourBeat = beatIndex % 4 == 0;

            return Expanded(
              child: GestureDetector(
                onTap: () => widget.bloc.timeline.setBeat(beatIndex),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.cyan
                        : (isFourBeat ? Colors.grey[700] : Colors.grey[800]),
                    borderRadius: BorderRadius.circular(3),
                    border: isFourBeat
                        ? Border.all(color: Colors.grey[600]!, width: 1)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${beatIndex % 16 + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.black : Colors.grey[500],
                        fontSize: 9,
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
            return ListView.separated(
              padding: EdgeInsets.all(8),
              itemCount: tracksList.length,
              separatorBuilder: (context, index) => SizedBox(height: 4),
              itemBuilder: (context, trackIndex) {
                final track = tracksList[trackIndex];

                return Card(
                  color: Colors.grey[850],
                  elevation: 1,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: MobileTrackRow(
                      track: track,
                      currentBeat: currentBeat,
                      startBeat: startBeat,
                      endBeat: endBeat,
                      onDelete: tracksList.length > 1
                          ? () => widget.bloc.removeTrack(trackIndex)
                          : null,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
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
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Add Track',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
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
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            child: Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyan,
                              ),
                            ),
                          ),
                          ...sounds.map((sound) => ListTile(
                            leading: Icon(Icons.music_note, color: Colors.cyan),
                            title: Text(
                              sound.displayName,
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.bloc.addTrack(sound.key, sound.displayName);
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
        title: Text(
          'Save Pattern',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Pattern name',
            hintStyle: TextStyle(color: Colors.grey[500]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyan),
            ),
            focusedBorder: UnderlineInputBorder(
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
            child: Text('Save'),
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

    if (patterns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No saved patterns found'),
          backgroundColor: Colors.orange[700],
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

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
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Load Pattern',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: patterns.length,
                    separatorBuilder: (context, index) => Divider(color: Colors.grey[800]),
                    itemBuilder: (context, index) {
                      final pattern = patterns[index];
                      final formattedDate = _formatDateTime(pattern.savedAt);

                      return ListTile(
                        leading: Icon(Icons.music_note, color: Colors.purple),
                        title: Text(
                          pattern.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Saved: $formattedDate',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red[400]),
                              onPressed: () async {
                                HapticFeedback.mediumImpact();

                                // Confirm deletion
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.grey[850],
                                    title: Text(
                                      'Delete Pattern?',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: Text(
                                      'Are you sure you want to delete "${pattern.name}"?',
                                      style: TextStyle(color: Colors.white70),
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
                                        ),
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  await widget.bloc.deletePattern(pattern.id);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                                  content: Text('Pattern "${pattern.name}" loaded!'),
                                  backgroundColor: Colors.purple[700],
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error loading pattern: $e'),
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
