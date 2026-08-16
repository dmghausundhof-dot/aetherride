import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/saved_route_note.dart';
import '../../l10n/app_localizations.dart';

/// Lokale Notizen an einer eigenen Strecke (kein Feed, keine Stimme).
class SavedRouteNotesSection extends StatefulWidget {
  const SavedRouteNotesSection({
    super.key,
    required this.notes,
    required this.onAdd,
    required this.onRemove,
    this.authorLabel = 'Du',
  });

  final List<SavedRouteNote> notes;
  final Future<void> Function(String text) onAdd;
  final Future<void> Function(String noteId) onRemove;
  final String authorLabel;

  @override
  State<SavedRouteNotesSection> createState() => _SavedRouteNotesSectionState();
}

class _SavedRouteNotesSectionState extends State<SavedRouteNotesSection> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onAdd(text);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.myRouteNotesTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.myRouteNotesHint,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.s),
        if (widget.notes.isEmpty)
          Text(
            l10n.myRouteNotesEmpty,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          )
        else
          for (final n in widget.notes.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${n.authorLabel} · ${_fmt(n.createdAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(n.text, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => widget.onRemove(n.id),
                  ),
                ],
              ),
            ),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.myRouteNotesPlaceholder,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                scrollPadding: const EdgeInsets.only(bottom: 120),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(l10n),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _saving ? null : () => _submit(l10n),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.myRouteNotesAdd),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}.'
        '${l.month.toString().padLeft(2, '0')}.'
        '${l.year}';
  }
}
