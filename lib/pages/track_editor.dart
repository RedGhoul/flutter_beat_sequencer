import 'package:flutter/material.dart';
import '../services/layout_metrics.dart';
import 'main_bloc.dart';
import '../widgets/mobile_track_row.dart';
import 'pattern.dart';

class TrackEditorPage extends StatelessWidget {
  final PlaybackBloc bloc;
  final TrackBloc track;
  final VoidCallback? onDelete;

  const TrackEditorPage({
    Key? key,
    required this.bloc,
    required this.track,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final metrics = LayoutMetrics.fromContext(context);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        title: Text(track.sound.name),
        actions: [
          IconButton(
            onPressed: () => _showPatternMenu(context, track),
            icon: const Icon(Icons.graphic_eq),
            tooltip: 'Change pattern',
          ),
          if (onDelete != null)
            IconButton(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete track',
            ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: bloc.totalBeats,
          builder: (context, totalBeats, _) {
            return ValueListenableBuilder<int>(
              valueListenable: bloc.timeline.atBeat,
              builder: (context, currentBeat, _) {
                return ValueListenableBuilder<List<bool>>(
                  valueListenable: track.isEnabled,
                  builder: (context, enabledList, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 8.0;
                        final targetSize = metrics.isCompactWidth ? 54.0 : 48.0;
                        final columns =
                            (constraints.maxWidth / (targetSize + spacing))
                                .floor()
                                .clamp(6, 12);
                        final stepSize = ((constraints.maxWidth -
                                    (spacing * (columns - 1))) /
                                columns)
                            .clamp(44.0, 64.0);

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[850],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Tap to toggle steps. Long-press label to preview sound.',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: List.generate(totalBeats, (index) {
                                  final isEnabled = enabledList[index];
                                  final isActive = currentBeat == index;
                                  return SizedBox(
                                    width: stepSize,
                                    height: stepSize,
                                    child: TrackStep(
                                      size: stepSize,
                                      enabled: isEnabled,
                                      active: isActive,
                                      onPressed: () => track.toggle(index),
                                    ),
                                  );
                                }),
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
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Delete Track',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete "${track.sound.name}" from the pattern?',
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

    if (confirmed == true && onDelete != null) {
      onDelete!();
      Navigator.pop(context);
    }
  }

  void _showPatternMenu(BuildContext context, TrackBloc track) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[850],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(
              'Select Pattern for ${track.sound.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...allPatterns().map(
              (pattern) => ListTile(
                title: Text(pattern.name,
                    style: const TextStyle(color: Colors.white)),
                leading: const Icon(Icons.graphic_eq, color: Colors.cyan),
                onTap: () {
                  track.setPattern(pattern);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
