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
  final VoidCallback? onDelete;

  const MobileTrackRow({
    Key? key,
    required this.track,
    required this.currentBeat,
    required this.startBeat,
    required this.endBeat,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const buttonSize = 32.0; // Smaller for landscape
    const spacing = 2.0;

    return Row(
      children: [
        // Track label (only show on first segment)
        if (startBeat == 0) ...[
          SizedBox(
            width: 50,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                track.sound.play();
              },
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    track.sound.name,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: spacing + 2),
        ] else ...[
          SizedBox(width: 52 + spacing),
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
          SizedBox(width: spacing + 2),
          SizedBox(
            width: 40,
            height: buttonSize,
            child: ElevatedButton(
              onPressed: () => _showPatternMenu(context, track),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.grey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Icon(Icons.more_horiz, size: 20, color: Colors.white),
            ),
          ),
        ],

        // Delete button (only show on first segment if deletable)
        if (startBeat == 0 && onDelete != null) ...[
          SizedBox(width: spacing + 2),
          SizedBox(
            width: 36,
            height: buttonSize,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                onDelete!();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.red[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Icon(Icons.delete_outline, size: 18, color: Colors.white),
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
      backgroundColor: Colors.grey[850],
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
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Select Pattern for ${track.sound.name}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            ...allPatterns().map((pattern) => ListTile(
              title: Text(pattern.name, style: TextStyle(color: Colors.white)),
              leading: Icon(Icons.graphic_eq, color: Colors.cyan),
              onTap: () {
                HapticFeedback.selectionClick();
                track.setPattern(pattern);
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
              ? Colors.cyan
              : (active ? Colors.blue.withOpacity(0.3) : Colors.grey[800]),
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(
            color: active ? Colors.white : Colors.transparent,
            width: active ? 2 : 0,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.cyan.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}
