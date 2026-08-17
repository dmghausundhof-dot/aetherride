import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/community/stimme_tags.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';

class StimmeTagChips extends StatelessWidget {
  const StimmeTagChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.stimmeTagsHint,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final wire in kStimmeTagWires)
              FilterChip(
                label: Text(l10n.stimmeTagLabel(wire)),
                selected: selected.contains(wire),
                onSelected: (_) => onChanged(toggleStimmeTag(selected, wire)),
              ),
          ],
        ),
      ],
    );
  }
}

class StimmeDifficultyChips extends StatelessWidget {
  const StimmeDifficultyChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// −1 leichter, 0 wie markiert, +1 härter. Null = keine Angabe.
  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          l10n.stimmeDifficultyHint,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final e in [
              (-1, l10n.stimmeDifficultyEasier),
              (0, l10n.stimmeDifficultyAsMarked),
              (1, l10n.stimmeDifficultyHarder),
            ])
              ChoiceChip(
                label: Text(e.$2),
                selected: selected == e.$1,
                onSelected: (_) =>
                    onChanged(selected == e.$1 ? null : e.$1),
              ),
          ],
        ),
      ],
    );
  }
}
