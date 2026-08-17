import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/community/tour_community_store.dart';
import '../../domain/community/stimme_pin.dart';
import '../../l10n/app_localizations.dart';
import '../discover/widgets/stimme_tag_chips.dart';

/// Nach Feel/Setup — nur wenn die Fahrt an einer öffentlichen Tour hing.
class PostRideStimmeCard extends StatefulWidget {
  const PostRideStimmeCard({
    super.key,
    required this.tourId,
    this.track = const [],
  });

  final String tourId;
  final List<Map<String, dynamic>> track;

  @override
  State<PostRideStimmeCard> createState() => _PostRideStimmeCardState();
}

class _PostRideStimmeCardState extends State<PostRideStimmeCard> {
  final _store = TourCommunityStore();
  final _bodyCtrl = TextEditingController();
  int _rating = 4;
  List<String> _tags = const [];
  int? _difficultyDelta;
  bool _busy = false;
  bool _done = false;
  bool _skipped = false;

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final body = _bodyCtrl.text.trim();
      final coords = [
        for (final p in widget.track)
          if (p['lat'] is num && p['lng'] is num)
            [
              (p['lng'] as num).toDouble(),
              (p['lat'] as num).toDouble(),
            ],
      ];
      final last = coords.isEmpty ? null : coords.last;
      final pin = last == null
          ? null
          : snapStimmePin(
              coordinates: coords,
              lat: last[1],
              lng: last[0],
            );
      final review = await _store.addReview(
        tourId: widget.tourId,
        rating: _rating,
        body: body.isEmpty ? '—' : body,
        authorLabel: '',
        tags: _tags,
        alongM: pin?.alongM,
        pinLat: pin?.lat,
        pinLng: pin?.lng,
        difficultyDelta: _difficultyDelta,
      );
      final cloud = await _store.submitToCloud(review);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final msg = switch (cloud) {
        CloudSubmitResult.approved => l10n.stimmenCloudApproved,
        CloudSubmitResult.rejected => l10n.stimmenCloudRejected,
        CloudSubmitResult.pending => l10n.stimmenCloudPending,
        CloudSubmitResult.localOnly => l10n.stimmenCloudLocal,
        CloudSubmitResult.failed => l10n.stimmenCloudFailed,
      };
      setState(() {
        _busy = false;
        _done = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_skipped) return const SizedBox.shrink();
    if (_done) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          l10n.postRideStimmeDone,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.postRideStimmeTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.postRideStimmeHint,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating ? Icons.star : Icons.star_border,
                    color: AppColors.accent,
                  ),
                ),
            ],
          ),
          StimmeTagChips(
            selected: _tags,
            onChanged: (next) => setState(() => _tags = next),
          ),
          StimmeDifficultyChips(
            selected: _difficultyDelta,
            onChanged: (next) => setState(() => _difficultyDelta = next),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyCtrl,
            maxLines: 2,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: l10n.stimmenHowWas,
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton(
                onPressed: _busy ? null : () => unawaited(_save()),
                child: Text(_busy ? l10n.stimmenSaving : l10n.stimmenSubmit),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _skipped = true),
                child: Text(l10n.postRideStimmeSkip),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
