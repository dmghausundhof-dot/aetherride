import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/community/tour_community_store.dart';

/// Komoot/AllTrails-Scan: ★ Schnitt + Anzahl — nur echte lokale Reviews,
/// keine erfundenen Community-Zahlen.
class TourSocialProof extends StatefulWidget {
  const TourSocialProof({
    super.key,
    required this.tourId,
    this.compact = true,
  });

  final String tourId;
  final bool compact;

  @override
  State<TourSocialProof> createState() => _TourSocialProofState();
}

class _TourSocialProofState extends State<TourSocialProof> {
  final _store = TourCommunityStore();
  double? _avg;
  int _n = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant TourSocialProof oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tourId != widget.tourId) unawaited(_load());
  }

  Future<void> _load() async {
    final list = await _store.reviewsForTour(widget.tourId);
    final avg = await _store.averageRating(widget.tourId);
    if (!mounted) return;
    setState(() {
      _n = list.length;
      _avg = avg;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_n == 0 || _avg == null) return const SizedBox.shrink();
    final style = TextStyle(
      fontSize: widget.compact ? 13 : 14,
      fontWeight: FontWeight.w700,
      color: AppColors.chipIdleText,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: widget.compact ? 16 : 18,
          color: AppColors.accent,
        ),
        const SizedBox(width: 3),
        Text(_avg!.toStringAsFixed(1), style: style),
        Text(
          '  ($_n)',
          style: style.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
