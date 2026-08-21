import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/chrome_glyph.dart';
import '../../../data/community/tour_community_store.dart';

/// Community-Chip auf Karten/Detail — nur echte Counts, keine Stub-Sterne.
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
  TourCommunityCounts _counts = const TourCommunityCounts();

  @override
  void initState() {
    super.initState();
    TourCommunityStore.revision.addListener(_onRevision);
    unawaited(_load());
  }

  @override
  void dispose() {
    TourCommunityStore.revision.removeListener(_onRevision);
    super.dispose();
  }

  void _onRevision() {
    if (!mounted) return;
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant TourSocialProof oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tourId != widget.tourId) unawaited(_load());
  }

  Future<void> _load() async {
    final cached = TourCommunityStore.countsCache[widget.tourId];
    if (cached != null && mounted) {
      setState(() => _counts = cached);
    }
    final local = await _store.reviewsForTour(widget.tourId);
    final bundle = await _store.mergeCloudBundle(widget.tourId);
    final fromCloud = TourCommunityStore.countsCache[widget.tourId];
    final ratings = bundle.reviews.map((r) => r.rating).toList();
    final avg = ratings.isEmpty
        ? null
        : ratings.fold<int>(0, (a, b) => a + b) / ratings.length;
    final next = TourCommunityCounts(
      reviewCount: mathMax(
        fromCloud?.reviewCount ?? 0,
        bundle.reviews.length,
      ),
      photoCount: mathMax(
        fromCloud?.photoCount ?? 0,
        bundle.photoUrls.length,
      ),
      averageRating: avg,
      difficulty: fromCloud?.difficulty,
    );
    // Local-only reviews still count (honest device data).
    final withLocal = next.reviewCount == 0 && local.isNotEmpty
        ? TourCommunityCounts(
            reviewCount: local.length,
            photoCount: next.photoCount,
            averageRating:
                local.fold<int>(0, (a, r) => a + r.rating) / local.length,
            difficulty: next.difficulty,
          )
        : next;
    TourCommunityStore.countsCache[widget.tourId] = withLocal;
    if (!mounted) return;
    setState(() => _counts = withLocal);
  }

  @override
  Widget build(BuildContext context) {
    if (!_counts.hasCommunity) return const SizedBox.shrink();
    final style = TextStyle(
      fontSize: widget.compact ? 12 : 13,
      fontWeight: FontWeight.w700,
      color: AppColors.chipIdleText,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_counts.reviewCount > 0) ...[
            ChromeGlyph(
              'star',
              size: widget.compact ? 14 : 16,
              color: AppColors.accent,
            ),
            const SizedBox(width: 3),
            Text(
              _counts.averageRating != null
                  ? '${_counts.averageRating!.toStringAsFixed(1)} (${_counts.reviewCount})'
                  : '${_counts.reviewCount}',
              style: style,
            ),
          ],
          if (_counts.photoCount > 0) ...[
            if (_counts.reviewCount > 0)
              Text('  ·  ', style: style.copyWith(color: AppColors.muted)),
            ChromeGlyph(
              'photo',
              size: widget.compact ? 13 : 15,
              color: AppColors.muted,
            ),
            const SizedBox(width: 3),
            Text('${_counts.photoCount}', style: style),
          ],
        ],
      ),
    );
  }
}

int mathMax(int a, int b) => a > b ? a : b;
