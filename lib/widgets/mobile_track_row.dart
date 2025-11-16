import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            child: AnimatedButton(
              onPressed: () {
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
                return ValueListenableBuilder<List<bool>>(
                  valueListenable: track.isEnabled,
                  builder: (context, enabledList, _) {
                    return TrackStep(
                      size: buttonSize,
                      enabled: enabledList[beatIndex],
                      active: currentBeat == beatIndex,
                      onPressed: () => track.toggle(beatIndex),
                    );
                  },
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
    showModalBottomSheet<void>(
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

class TrackStep extends StatefulWidget {
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
  State<TrackStep> createState() => _TrackStepState();
}

class _TrackStepState extends State<TrackStep> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.selectionClick();
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.85 : 1.0,
        duration: Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.enabled
                    ? Colors.cyan
                    : (widget.active ? Colors.blue.withOpacity(0.3) : Colors.grey[800]),
                borderRadius: BorderRadius.circular(widget.size / 2),
                border: Border.all(
                  color: widget.active ? Colors.white : Colors.transparent,
                  width: widget.active ? 2 : 0,
                ),
                boxShadow: widget.enabled
                    ? [
                        BoxShadow(
                          color: Colors.cyan.withOpacity(0.5 * _pulseAnimation.value),
                          blurRadius: 6 * _pulseAnimation.value,
                          spreadRadius: 1 * _pulseAnimation.value,
                        )
                      ]
                    : (widget.active
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ]
                        : null),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Animated button widget for better UX with scale animation on press
class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const AnimatedButton({
    Key? key,
    required this.onPressed,
    required this.child,
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
