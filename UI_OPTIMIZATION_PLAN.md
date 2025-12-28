# UI Optimization Plan (Phone-First, No Cutoff)

## Goals
- Ensure all UI fits within any phone screen shape (notches, rounded corners, home indicators).
- Keep core actions visible and reachable without hunting.
- Preserve rhythm-editing speed while scaling across compact and large devices.

## Current Risks to Fix (by file)
- `lib/pages/mobile_layout.dart`: fixed sidebar widths in `_calculateSidebarWidth`, beat sizing assumptions in `_calculateBeatsPerPage`, and FAB/padding overlap in `_buildTrackGridContent`.
- `lib/widgets/mobile_track_row.dart`: hard-coded label/pattern/delete widths (50/40/36), fixed `buttonSize`/`beatSize` assumptions, and always-visible row actions.
- Layout structure is a `Row` with a fixed-width panel + grid, so small phones clip the grid or compress the sidebar.

## Responsive Layout Strategy (concrete targets)
1) **Define breakpoints**
   - Use `LayoutBuilder` + `MediaQuery.size` to detect:
     - Compact width (<= 360dp)
     - Regular phone (361-430dp)
     - Large phone (431-520dp)
     - Landscape short-height (<= 360dp height)
   - Adjust spacing, density, and panels per breakpoint.

2) **Safe area + insets**
   - Wrap the top-level layout in `SafeArea`.
   - Apply `MediaQuery.padding` + `viewInsets` to containers and scroll views.
   - Add bottom padding for FAB + home indicator so the last row is never blocked.

3) **Replace fixed sizes with flexible constraints**
   - In `build` (top-level Row), replace fixed `Container(width: sidebarWidth)` with a responsive panel that can collapse:
     - Docked (`width: min(maxWidth * 0.28, 200)`) for regular/large phones.
     - Collapsible bottom sheet or overlay for compact widths.
   - Swap hard-coded sizes inside `_buildControlPanel` for spacing tokens driven by a new `LayoutMetrics`.

4) **Grid scaling and paging**
   - Calculate `beatsPerPage` based on available width.
   - Allow horizontal scroll for the grid on compact devices.
   - Keep beat indicator row locked to grid width to avoid misalignment.
   - Add swipe + page dots for multi-page steps.

5) **Panel behavior**
   - Docked panel on wider phones.
   - Collapsible panel (bottom sheet or slide-over) on compact widths.
   - Preserve "Play", "BPM", and "Tempo" as always-visible controls.

## UX Improvements for Phone Usability (mapped to widgets)
1) **Primary controls always visible**
   - Add a compact transport strip above `_buildBeatIndicator` in `lib/pages/mobile_layout.dart` so play/stop and tempo are never hidden by scroll.
   - Ensure current beat highlight remains visible even when the list is scrolled.

2) **Reduce row clutter**
   - Replace always-visible row action buttons in `MobileTrackRow` with:
     - `Dismissible`/`Slidable` actions, or
     - a long-press action sheet, or
     - a selection state that reveals actions for the active row only.

3) **Focused edit mode**
   - On compact widths, tapping a row opens a focused editor screen:
     - Larger step pads (48dp+).
     - Pattern selection and delete consolidated into one menu.
     - Clear "Back to grid" navigation.

4) **Touch target sizing**
   - Ensure 44x44dp minimum for tap targets.
   - In `MobileTrackRow`, compute `beatSize` from available width and clamp to a 44dp minimum on compact phones by reducing `beatsPerPage`.

5) **Clear hierarchy**
   - Visual separation between transport, track list, and grid.
   - Keep active/playing states prominent and consistent.

## Implementation Steps (directly tied to code)
1) **Audit**
   - `lib/pages/mobile_layout.dart`: `_calculateSidebarWidth`, `_calculateBeatsPerPage`, `_buildTrackGridContent` padding.
   - `lib/widgets/mobile_track_row.dart`: label/pattern/delete widths and `buttonSize`.

2) **Core layout refactor**
   - Add `LayoutMetrics` helper (e.g., `lib/services/layout_metrics.dart`) to centralize sizes for compact/regular/large.
   - Replace fixed widths with `LayoutMetrics` in `_buildControlPanel` and `MobileTrackRow`.

3) **Grid + indicators**
   - Move `_calculateBeatsPerPage` to `LayoutMetrics` so `_buildBeatIndicator` and `MobileTrackRow` use the same sizing rules.
   - Add horizontal scroll for the grid on compact widths (e.g., `SingleChildScrollView` wrapping the row of steps).

4) **Panel behavior**
   - For compact widths, move `_buildControlPanel` into a modal bottom sheet (invoked from a settings/controls button).
   - Keep a slim transport bar always visible (play/stop, BPM).

5) **Interaction changes**
   - Implement swipe/long-press for row actions.
   - Add focused edit mode if needed for small phones.

6) **Polish and theming**
   - Use app spacing/radius/typography tokens.
   - Keep dark theme intact with subtle depth and consistent motion.

## Validation Checklist
- iPhone SE (small width), iPhone 14/15 Pro, Pixel 5, Pixel 7 Pro.
- Portrait + landscape.
- Notches, rounded corners, and home indicator.
- Keyboard overlays and accessibility text scaling.

## Deliverables
- Updated responsive layout in `lib/pages/mobile_layout.dart`.
- Updated responsive row sizing in `lib/widgets/mobile_track_row.dart`.
- Any new helper for layout metrics (e.g., `lib/services/layout_metrics.dart`).
