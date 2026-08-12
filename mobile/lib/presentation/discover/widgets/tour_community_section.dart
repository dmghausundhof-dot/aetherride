import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/community/tour_community_store.dart';

/// Tour-Detail: lokale Bewertungen / Kommentare (ohne Cloud-Abhängigkeit).
class TourCommunitySection extends StatefulWidget {
  const TourCommunitySection({super.key, required this.tourId});

  final String tourId;

  @override
  State<TourCommunitySection> createState() => _TourCommunitySectionState();
}

class _TourCommunitySectionState extends State<TourCommunitySection> {
  final _store = TourCommunityStore();
  final _bodyCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(text: 'Du');
  List<TourCommunityReview> _reviews = const [];
  double? _avg;
  int _rating = 4;
  bool _loading = true;
  bool _saving = false;
  bool _compose = false;
  final List<String> _draftPhotos = [];

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
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
    final list = await _store.mergeCloud(widget.tourId);
    final avg = list.isEmpty
        ? null
        : list.fold<int>(0, (a, r) => a + r.rating) / list.length;
    if (!mounted) return;
    setState(() {
      _reviews = list;
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
        final msg = switch (cloud) {
          CloudSubmitResult.pending =>
            'Gespeichert — lokal und zur Freigabe gesendet',
          CloudSubmitResult.localOnly =>
            'Gespeichert — lokal (Cloud nach Login)',
          CloudSubmitResult.failed =>
            'Gespeichert lokal — Cloud gerade nicht erreichbar',
        };
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Community',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            if (_avg != null)
              Text(
                '★ ${_avg!.toStringAsFixed(1)} · ${_reviews.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Sterne, Kommentar und Fotos — wie bei Komoot. Andere sehen Cloud-Reviews, sobald sie freigegeben sind.',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.m),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_reviews.isEmpty)
          const Text(
            'Noch keine Bewertungen — sei die/der Erste.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          )
        else
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
          OutlinedButton.icon(
            onPressed: () => setState(() => _compose = true),
            icon: const Icon(Icons.star_outline, size: 18),
            label: const Text('Bewertung schreiben'),
          )
        else ...[
          const Text(
            'Bewertung schreiben',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
            decoration: const InputDecoration(
              labelText: 'Name',
              isDense: true,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          TextField(
            controller: _bodyCtrl,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Kommentar',
              hintText: 'Wie war die Tour?',
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
              label: const Text('Foto hinzufügen'),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _saving ? null : () => unawaited(_submit()),
              child: Text(_saving ? 'Speichern …' : 'Absenden'),
            ),
          ),
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
                tooltip: 'Entfernen',
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
