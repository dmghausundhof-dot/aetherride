import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/community/public_profile_store.dart';
import '../../../data/community/tour_community_store.dart';
import '../../../data/community/tour_share.dart';
import '../../../data/local/user_profile_store.dart';
import '../../../l10n/app_localizations.dart';

/// Tour-Detail: Stimmen an der Tour (ohne Cloud-Abhängigkeit).
class TourCommunitySection extends StatefulWidget {
  const TourCommunitySection({
    super.key,
    required this.tourId,
    this.showHeading = true,
  });

  final String tourId;
  final bool showHeading;

  @override
  State<TourCommunitySection> createState() => _TourCommunitySectionState();
}

class _TourCommunitySectionState extends State<TourCommunitySection> {
  final _store = TourCommunityStore();
  final _bodyCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  List<TourCommunityReview> _reviews = const [];
  List<String> _cloudPhotos = const [];
  double? _avg;
  int _rating = 4;
  bool _loading = true;
  bool _saving = false;
  bool _compose = false;
  final List<String> _draftPhotos = [];
  final _composeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
    unawaited(_prefillAuthor());
  }

  Future<void> _prefillAuthor() async {
    try {
      final pub = await PublicProfileStore().load();
      var name = pub.displayName.trim();
      if (name.isEmpty) {
        final user = UserProfileStore();
        await user.load();
        name = user.displayName?.trim() ?? '';
      }
      if (!mounted || name.isEmpty || _nameCtrl.text.isNotEmpty) return;
      _nameCtrl.text = name;
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant TourCommunitySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tourId != widget.tourId) {
      unawaited(_reload());
    }
  }

  @override
  void dispose() {
    _bodyCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final bundle = await _store.mergeCloudBundle(widget.tourId);
    final list = bundle.reviews;
    final avg = list.isEmpty
        ? null
        : list.fold<int>(0, (a, r) => a + r.rating) / list.length;
    if (!mounted) return;
    setState(() {
      _reviews = list;
      _cloudPhotos = bundle.photoUrls;
      _avg = avg;
      _loading = false;
    });
  }

  Future<void> _pickPhoto() async {
    if (_draftPhotos.length >= 4) return;
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (x == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final destDir = Directory(p.join(dir.path, 'tour_review_photos'));
    await destDir.create(recursive: true);
    final dest = File(p.join(destDir.path, '${const Uuid().v4()}.jpg'));
    await File(x.path).copy(dest.path);
    if (!mounted) return;
    setState(() => _draftPhotos.add(dest.path));
  }

  Future<void> _submit() async {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final review = await _store.addReview(
        tourId: widget.tourId,
        rating: _rating,
        body: body,
        authorLabel: _nameCtrl.text,
        photoUris: List<String>.from(_draftPhotos),
      );
      final cloud = await _store.submitToCloud(review);
      _bodyCtrl.clear();
      _draftPhotos.clear();
      _compose = false;
      await _reload();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final msg = switch (cloud) {
          CloudSubmitResult.approved => l10n.stimmenCloudApproved,
          CloudSubmitResult.rejected => l10n.stimmenCloudRejected,
          CloudSubmitResult.pending => l10n.stimmenCloudPending,
          CloudSubmitResult.localOnly => l10n.stimmenCloudLocal,
          CloudSubmitResult.failed => l10n.stimmenCloudFailed,
        };
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _scrollComposeIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _composeKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.15,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? metaLine;
    if (_avg != null) {
      metaLine = '★ ${_avg!.toStringAsFixed(1)} · ${_reviews.length}';
      if (_cloudPhotos.isNotEmpty) {
        metaLine = '$metaLine · ${_cloudPhotos.length} ${l10n.myRouteDetailPhotos}';
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeading)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.stimmenTitle,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              if (metaLine != null)
                Text(
                  metaLine,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
            ],
          )
        else if (metaLine != null)
          Text(
            metaLine,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        if (!_compose) ...[
          const SizedBox(height: 4),
          Text(
            l10n.stimmenHint,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                unawaited(
                  SharePlus.instance.share(
                    ShareParams(
                      text: TourShare.text(widget.tourId),
                      subject: l10n.stimmenShareSubject,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.muted,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.share, style: const TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
        ],
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_reviews.isEmpty && _cloudPhotos.isEmpty && !_compose)
          Text(
            l10n.stimmenEmpty,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          )
        else if (!_compose)
          for (final r in _reviews) ...[
            _ReviewTile(
              review: r,
              onDelete: () async {
                await _store.removeReview(r.id);
                await _reload();
              },
            ),
            const SizedBox(height: AppSpacing.s),
          ],
        const SizedBox(height: AppSpacing.m),
        if (!_compose)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _compose = true);
                    _scrollComposeIntoView();
                  },
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: Text(l10n.stimmenWrite),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _compose = true);
                  _scrollComposeIntoView();
                  unawaited(_pickPhoto());
                },
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: Text(l10n.garagePhoto),
              ),
            ],
          )
        else ...[
          KeyedSubtree(
            key: _composeKey,
            child: Text(
              l10n.stimmenWrite,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
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
          TextField(
            controller: _nameCtrl,
            scrollPadding: const EdgeInsets.only(bottom: 120),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.profileDisplayName,
              hintText: l10n.stimmenEmptyName,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          TextField(
            controller: _bodyCtrl,
            maxLines: 3,
            maxLength: 500,
            scrollPadding: const EdgeInsets.only(bottom: 140),
            decoration: InputDecoration(
              labelText: l10n.stimmenLabel,
              hintText: l10n.stimmenHowWas,
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          if (_draftPhotos.isNotEmpty)
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < _draftPhotos.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_draftPhotos[i]),
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              iconSize: 16,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              onPressed: () =>
                                  setState(() => _draftPhotos.removeAt(i)),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _draftPhotos.length >= 4
                  ? null
                  : () => unawaited(_pickPhoto()),
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: Text(l10n.stimmenAddPhoto),
            ),
          ),
          Row(
            children: [
              FilledButton(
                onPressed: _saving ? null : () => unawaited(_submit()),
                child: Text(_saving ? l10n.stimmenSaving : l10n.stimmenSubmit),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() => _compose = false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.muted,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(l10n.cancel),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.onDelete});

  final TourCommunityReview review;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.authorLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '★' * review.rating,
                style: const TextStyle(color: AppColors.accent, fontSize: 12),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context).remove,
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
          Text(
            review.body,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          if (review.photoUris.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 88,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final uri in review.photoUris)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: uri.startsWith('http')
                            ? Image.network(
                                uri,
                                width: 120,
                                height: 88,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(uri),
                                width: 120,
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
