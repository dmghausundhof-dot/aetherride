import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/community/labeled_via.dart';
import '../../../l10n/app_localizations.dart';
import '../../map/map_pin_image.dart';
import '../../shared/chrome_glyph.dart';

/// Komoot-style stacked A → vias → B. Start/end and vias are searchable.
class PlanWaypointStack extends StatefulWidget {
  const PlanWaypointStack({
    super.key,
    required this.startController,
    required this.endController,
    required this.startFocus,
    required this.endFocus,
    required this.vias,
    required this.hasStart,
    required this.hasEnd,
    required this.onMyLocation,
    required this.onSwap,
    required this.onAddVia,
    this.pickingVia = false,
    this.viaHint,
    required this.onCloseLoop,
    required this.onViaReorder,
    required this.onViaRemove,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onStartSubmitted,
    required this.onEndSubmitted,
    required this.onViaChanged,
    required this.onViaSubmitted,
    this.loopClosed = false,
    this.lineHint,
    this.onUndo,
    this.onRedo,
    this.startOutside = false,
    this.endOutside = false,
    this.viaOutside = const [],
  });

  final TextEditingController startController;
  final TextEditingController endController;
  final FocusNode startFocus;
  final FocusNode endFocus;
  final List<LabeledVia> vias;
  final bool hasStart;
  final bool hasEnd;
  final VoidCallback onMyLocation;
  final VoidCallback onSwap;
  final VoidCallback onAddVia;
  final bool pickingVia;
  final String? viaHint;
  final VoidCallback onCloseLoop;
  final void Function(int from, int to) onViaReorder;
  final void Function(int index) onViaRemove;
  final ValueChanged<String> onStartChanged;
  final ValueChanged<String> onEndChanged;
  final VoidCallback onStartSubmitted;
  final VoidCallback onEndSubmitted;
  final void Function(int index, String query) onViaChanged;
  final void Function(int index, String query) onViaSubmitted;
  final bool loopClosed;
  final String? lineHint;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool startOutside;
  final bool endOutside;
  final List<bool> viaOutside;

  @override
  State<PlanWaypointStack> createState() => _PlanWaypointStackState();
}

class _PlanWaypointStackState extends State<PlanWaypointStack> {
  final _viaCtrls = <TextEditingController>[];
  final _viaFocus = <FocusNode>[];

  @override
  void initState() {
    super.initState();
    _syncViaFields();
  }

  @override
  void didUpdateWidget(covariant PlanWaypointStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncViaFields();
  }

  @override
  void dispose() {
    for (final c in _viaCtrls) {
      c.dispose();
    }
    for (final f in _viaFocus) {
      f.dispose();
    }
    super.dispose();
  }

  void _syncViaFields() {
    while (_viaCtrls.length < widget.vias.length) {
      final i = _viaCtrls.length;
      _viaCtrls.add(
        TextEditingController(text: widget.vias[i].trimmedLabel ?? ''),
      );
      _viaFocus.add(FocusNode());
    }
    while (_viaCtrls.length > widget.vias.length) {
      _viaCtrls.removeLast().dispose();
      _viaFocus.removeLast().dispose();
    }
    for (var i = 0; i < widget.vias.length; i++) {
      if (_viaFocus[i].hasFocus) continue;
      final next = widget.vias[i].trimmedLabel ?? '';
      if (_viaCtrls[i].text != next) _viaCtrls[i].text = next;
    }
  }

  void _scrollFieldIntoView(BuildContext ctx) {
    Future.delayed(const Duration(milliseconds: 280), () {
      if (!ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.12,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showEnd = widget.hasStart || widget.hasEnd;
    final showSwap = widget.hasStart && widget.hasEnd;
    final showStops = widget.hasStart && widget.hasEnd;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: AppColors.charcoal.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Stack(
            children: [
              if (showEnd)
                Positioned(
                  left: 13,
                  top: 28,
                  bottom: 28,
                  child: Container(width: 1, color: AppColors.border),
                ),
              Column(
                children: [
                  _field(
                    controller: widget.startController,
                    focus: widget.startFocus,
                    kind: MapPinKind.start,
                    outside: widget.startOutside,
                    hint: widget.hasStart
                        ? l10n.navigateStartHint
                        : l10n.discoverTapStart,
                    semantics: l10n.navigateStartLabel,
                    onChanged: widget.onStartChanged,
                    onSubmitted: (_) => widget.onStartSubmitted(),
                    trailing: IconButton(
                      tooltip: l10n.navigateMyLocation,
                      onPressed: widget.onMyLocation,
                      icon: const ChromeGlyph('locate', size: 18),
                    ),
                  ),
                  if (showSwap)
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: l10n.navigateSwap,
                        onPressed: widget.onSwap,
                        icon: const Icon(Icons.swap_vert, size: 18),
                      ),
                    ),
                  if (showStops && widget.vias.isNotEmpty)
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: widget.vias.length,
                      onReorder: (from, to) {
                        var dest = to;
                        if (dest > from) dest -= 1;
                        widget.onViaReorder(from, dest);
                      },
                      itemBuilder: (ctx, i) => KeyedSubtree(
                        key: ValueKey('via-$i-${widget.vias[i].lat}'),
                        child: _viaField(l10n, i),
                      ),
                    ),
                  if (showEnd)
                    _field(
                      controller: widget.endController,
                      focus: widget.endFocus,
                      kind: MapPinKind.finish,
                      outside: widget.endOutside,
                      hint: l10n.navigateEndHint,
                      semantics: l10n.navigateEndLabel,
                      onChanged: widget.onEndChanged,
                      onSubmitted: (_) => widget.onEndSubmitted(),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (widget.viaHint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.viaHint!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE65100),
              ),
            ),
          ),
        if (showStops)
          Wrap(
            spacing: 4,
            children: [
              TextButton.icon(
                onPressed: widget.onAddVia,
                style: widget.pickingVia
                    ? TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE65100),
                        backgroundColor: const Color(0x22E65100),
                      )
                    : null,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.navigateAddVia),
              ),
              TextButton.icon(
                onPressed: widget.onCloseLoop,
                icon: Icon(
                  widget.loopClosed ? Icons.loop : Icons.replay,
                  size: 18,
                ),
                label: Text(l10n.navigateCloseLoop),
              ),
              if (widget.onUndo != null)
                TextButton.icon(
                  key: const Key('plan-undo'),
                  onPressed: widget.onUndo,
                  icon: const Icon(Icons.undo, size: 18),
                  label: Text(l10n.planUndo),
                ),
              if (widget.onRedo != null)
                TextButton.icon(
                  key: const Key('plan-redo'),
                  onPressed: widget.onRedo,
                  icon: const Icon(Icons.redo, size: 18),
                  label: Text(l10n.planRedo),
                ),
            ],
          ),
        if (showStops && widget.lineHint != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              widget.lineHint!,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
        if (showStops && widget.loopClosed)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l10n.navigateCloseLoopHint,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ),
      ],
    );
  }

  Widget _viaField(AppLocalizations l10n, int index) {
    return _field(
      controller: _viaCtrls[index],
      focus: _viaFocus[index],
      kind: MapPinKind.via,
      outside: index < widget.viaOutside.length && widget.viaOutside[index],
      viaLabel: '${index + 1}',
      hint: l10n.discoverViaN(index + 1),
      semantics: l10n.discoverViaN(index + 1),
      onChanged: (q) => widget.onViaChanged(index, q),
      onSubmitted: (q) => widget.onViaSubmitted(index, q),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.drag_handle, size: 18, color: AppColors.muted),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => widget.onViaRemove(index),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required FocusNode focus,
    required MapPinKind kind,
    required String hint,
    required String semantics,
    required ValueChanged<String> onChanged,
    required ValueChanged<String> onSubmitted,
    Widget? trailing,
    String? viaLabel,
    bool outside = false,
  }) {
    return Builder(
      builder: (ctx) {
        return Focus(
          onFocusChange: (has) {
            if (has) _scrollFieldIntoView(ctx);
          },
          child: Semantics(
            label: semantics,
            textField: true,
            child: Row(
              children: [
                MapPinBadge(
                  kind: kind,
                  size: 28,
                  label: viaLabel,
                  fill: outside ? AppColors.sage : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focus,
                    autofillHints: const [AutofillHints.addressCity],
                    decoration: InputDecoration(
                      hintText: hint,
                      filled: true,
                      fillColor: AppColors.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        );
      },
    );
  }
}
