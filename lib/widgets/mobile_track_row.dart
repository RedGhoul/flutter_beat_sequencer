import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/main_bloc.dart';
import '../pages/pattern.dart';
import '../services/layout_metrics.dart';

class MobileTrackRow extends StatelessWidget {
  final TrackBloc track;
  final int currentBeat;
  final int startBeat;
  final int endBeat;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenEditor;

  const MobileTrackRow({
    Key? key,
    required this.track,
    required this.currentBeat,
    required this.startBeat,
    required this.endBeat,
    this.onDelete,
    this.onOpenEditor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final metrics = LayoutMetrics.fromContext(context);
    final buttonSize = metrics.stepMaxSize;
    final spacing = metrics.rowSpacing;
    final showInlineActions = metrics.showInlineActions;
    final previewSound = () {
      HapticFeedback.lightImpact();
      track.sound.play();
    };

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress:
          showInlineActions ? null : () => _showRowActions(context, track),
      child: Row(
        children: [
          // Track label (only show on first segment)
          if (startBeat == 0) ...[
            SizedBox(
              width: metrics.trackLabelWidth,
              child: AnimatedButton(
                onPressed: metrics.isCompactWidth && onOpenEditor != null
                    ? onOpenEditor!
                    : previewSound,
                onLongPress: metrics.isCompactWidth && onOpenEditor != null
                    ? previewSound
                    : null,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      track.sound.name,
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: spacing + metrics.labelGap),
          ] else ...[
            SizedBox(width: metrics.trackLabelWidth + metrics.labelGap),
          ],

          // Beat steps for this segment
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final beatsCount = endBeat - startBeat;
                final availableWidth = constraints.maxWidth;
                final totalSpacing = spacing * (beatsCount - 1);
                final rawBeatSize =
                    (availableWidth - totalSpacing) / beatsCount;
                final beatSize =
                    rawBeatSize.clamp(metrics.stepMinSize, buttonSize);

                return Row(
                  children: List.generate(
                    beatsCount * 2 - 1,
                    (index) {
                      if (index.isOdd) {
                        return SizedBox(width: spacing);
                      }
                      final beatIndex = startBeat + (index ~/ 2);
                      return SizedBox(
                        width: beatSize,
                        height: beatSize,
                        child: ValueListenableBuilder<List<bool>>(
                          valueListenable: track.isEnabled,
                          builder: (context, enabledList, _) {
                            return TrackStep(
                              size: beatSize,
                              enabled: enabledList[beatIndex],
                              active: currentBeat == beatIndex,
                              onPressed: () => track.toggle(beatIndex),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Pattern button (only show on first segment)
          if (startBeat == 0 && showInlineActions) ...[
            SizedBox(width: spacing + metrics.labelGap),
            SizedBox(
              width: metrics.patternButtonWidth,
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
          if (startBeat == 0 && onDelete != null && showInlineActions) ...[
            SizedBox(width: spacing + metrics.labelGap),
            SizedBox(
              width: metrics.deleteButtonWidth,
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
                child:
                    Icon(Icons.delete_outline, size: 18, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRowActions(BuildContext context, TrackBloc track) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[850],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 12,
            children: [
              ListTile(
                leading: const Icon(Icons.graphic_eq, color: Colors.cyan),
                title: const Text('Change pattern',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showPatternMenu(context, track);
                },
              ),
              if (onDelete != null)
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Delete track',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete!();
                  },
                ),
            ],
          ),
        ),
      ),
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
                  title:
                      Text(pattern.name, style: TextStyle(color: Colors.white)),
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

class _TrackStepState extends State<TrackStep>
    with SingleTickerProviderStateMixin {
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
                    : (widget.active
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.grey[800]),
                borderRadius: BorderRadius.circular(widget.size / 2),
                border: Border.all(
                  color: widget.active ? Colors.white : Colors.transparent,
                  width: widget.active ? 2 : 0,
                ),
                boxShadow: widget.enabled
                    ? [
                        BoxShadow(
                          color: Colors.cyan
                              .withOpacity(0.5 * _pulseAnimation.value),
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
  final VoidCallback? onLongPress;
  final Widget child;

  const AnimatedButton({
    Key? key,
    required this.onPressed,
    this.onLongPress,
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
      onLongPress: widget.onLongPress,
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
