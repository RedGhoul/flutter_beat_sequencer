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

  const MobileTrackRow({
    Key? key,
    required this.track,
    required this.currentBeat,
    required this.startBeat,
    required this.endBeat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const buttonSize = 48.0; // Recommended minimum touch target
    const spacing = 4.0;

    return Row(
      children: [
        // Track label (only show on first segment)
        if (startBeat == 0) ...[
          SizedBox(
            width: 60,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                track.sound.play();
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.brown[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    track.sound.name,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: spacing),
        ] else ...[
          SizedBox(width: 60 + spacing),
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
          SizedBox(width: spacing),
          SizedBox(
            width: 50,
            height: buttonSize,
            child: ElevatedButton(
              onPressed: () => _showPatternMenu(context, track),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.brown[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Icon(Icons.more_horiz, size: 24, color: Colors.white),
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
      backgroundColor: Colors.brown[800],
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
                color: Colors.brown[600],
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
              leading: Icon(Icons.graphic_eq, color: Colors.amber),
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
              ? Colors.amber
              : (active ? Colors.blue.withOpacity(0.5) : Colors.brown[800]),
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(
            color: active ? Colors.white : Colors.transparent,
            width: active ? 3 : 0,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}
