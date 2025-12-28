import 'package:flutter/material.dart';

class LayoutMetrics {
  final Size size;
  final EdgeInsets padding;
  final bool isLandscape;
  final bool isCompactWidth;
  final bool isRegularWidth;
  final bool isLargeWidth;
  final bool isShortHeight;

  const LayoutMetrics._({
    required this.size,
    required this.padding,
    required this.isLandscape,
    required this.isCompactWidth,
    required this.isRegularWidth,
    required this.isLargeWidth,
    required this.isShortHeight,
  });

  factory LayoutMetrics.fromConstraints(
    BoxConstraints constraints,
    BuildContext context,
  ) {
    final size = Size(constraints.maxWidth, constraints.maxHeight);
    return LayoutMetrics._(
      size: size,
      padding: MediaQuery.of(context).padding,
      isLandscape: size.width > size.height,
      isCompactWidth: size.width <= 360,
      isRegularWidth: size.width > 360 && size.width <= 430,
      isLargeWidth: size.width > 430,
      isShortHeight: size.height <= 360,
    );
  }

  factory LayoutMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return LayoutMetrics._(
      size: size,
      padding: MediaQuery.of(context).padding,
      isLandscape: size.width > size.height,
      isCompactWidth: size.width <= 360,
      isRegularWidth: size.width > 360 && size.width <= 430,
      isLargeWidth: size.width > 430,
      isShortHeight: size.height <= 360,
    );
  }

  bool get showSidebar => false;

  bool get showInlineActions => false;

  double get sidebarWidth {
    if (!showSidebar) {
      return 0;
    }
    if (size.width >= 900) {
      return 200;
    }
    if (size.width <= 650) {
      return 150;
    }
    return 180;
  }

  double get rowSpacing => 2.0;

  double get labelGap => 4.0;

  double get trackLabelWidth => isCompactWidth ? 44 : 50;

  double get patternButtonWidth => showInlineActions ? 40 : 0;

  double get deleteButtonWidth => showInlineActions ? 36 : 0;

  double get stepMinSize => isCompactWidth ? 24 : 22;

  double get stepMaxSize => isCompactWidth ? 28 : 32;

  double get beatIndicatorLeadingInset => trackLabelWidth + labelGap;

  double get beatIndicatorTrailingInset {
    if (!showInlineActions) {
      return 0;
    }
    return patternButtonWidth + deleteButtonWidth + (labelGap * 2);
  }

  double get contentBottomPadding => isCompactWidth ? 96 : 72;

  int get minBeatsPerPage => 8;

  int get maxBeatsPerPage => isCompactWidth ? 12 : 16;

  int calculateBeatsPerPage({required double availableWidth}) {
    const double horizontalPadding = 16;
    const double minBeatGap = 2;
    final double reserved = trackLabelWidth +
        patternButtonWidth +
        deleteButtonWidth +
        (rowSpacing * 6) +
        horizontalPadding;
    final double usableWidth =
        (availableWidth - reserved).clamp(0, availableWidth);
    final double beatStride = stepMaxSize + minBeatGap;
    final int beats = (usableWidth / beatStride).floor();
    return beats.clamp(minBeatsPerPage, maxBeatsPerPage);
  }

  double gridWidth({required int beatsPerPage}) {
    final double reserved =
        trackLabelWidth + labelGap + beatIndicatorTrailingInset + 16;
    final double stepStride = stepMaxSize + rowSpacing;
    final double stepsWidth = (beatsPerPage * stepStride) - rowSpacing;
    return reserved + stepsWidth;
  }
}
