import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../data/ride/ride_media_io.dart';
import '../../domain/privacy/consents.dart';
import '../../domain/ride_journal.dart';
import '../../domain/saved_route_note.dart';
import '../../l10n/app_localizations.dart';
import '../shared/chrome_glyph.dart';
import 'post_ride_video_page.dart';

const _thumb = 112.0;

/// Eine Karte: Filmstrip + Caption. Kein zweites Formular auf dem Recap.
class PostRideJournalSection extends StatefulWidget {
  const PostRideJournalSection({
    super.key,
    required this.journal,
    required this.onChanged,
    this.track = const [],
    this.privacyZones = const [],
  });

  final RideJournal journal;
  final ValueChanged<RideJournal> onChanged;
  final List<Map<String, dynamic>> track;
  final List<PrivacyZone> privacyZones;

  @override
  State<PostRideJournalSection> createState() => _PostRideJournalSectionState();
}

class _PostRideJournalSectionState extends State<PostRideJournalSection> {
  final _noteCtrl = TextEditingController();
  bool _picking = false;
  bool _savingNote = false;

  RideJournal get _journal => widget.journal;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    if (!_journal.canAddPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postRidePhotosMax(RideJournal.maxPhotos))),
      );
      return;
    }
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final media = await pickRidePhoto(
        source: source,
        journal: _journal,
        track: widget.track,
        zones: widget.privacyZones,
      );
      if (media == null || !mounted) return;
      widget.onChanged(_journal.copyWith(photos: [..._journal.photos, media]));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    if (!_journal.canAddVideo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postRideVideosMax(RideJournal.maxVideos))),
      );
      return;
    }
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final media = await pickRideVideo(
        source: source,
        journal: _journal,
        track: widget.track,
        zones: widget.privacyZones,
      );
      if (media == null || !mounted) return;
      widget.onChanged(_journal.copyWith(videos: [..._journal.videos, media]));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _share() async {
    final l10n = AppLocalizations.of(context);
    final files = <XFile>[
      for (final path in _journal.photoPaths)
        if (File(path).existsSync())
          XFile(path, mimeType: rideMediaMime(path)),
      for (final path in _journal.videoPaths)
        if (File(path).existsSync())
          XFile(path, mimeType: rideMediaMime(path)),
    ];
    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postRidePhotosEmpty)),
      );
      return;
    }
    await SharePlus.instance.share(
      ShareParams(files: files, text: l10n.postRidePhotosShareText),
    );
  }

  void _removePhoto(int i) {
    final next = [..._journal.photos]..removeAt(i);
    widget.onChanged(_journal.copyWith(photos: next));
  }

  void _removeVideo(int i) {
    final next = [..._journal.videos]..removeAt(i);
    widget.onChanged(_journal.copyWith(videos: next));
  }

  Future<void> _addNote() async {
    final text = sanitizeNoteText(_noteCtrl.text);
    if (text.isEmpty || _savingNote) return;
    if (!_journal.canAddNote) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postRideNotesMax(RideJournal.maxNotes))),
      );
      return;
    }
    setState(() => _savingNote = true);
    try {
      final note = SavedRouteNote.create(text: text);
      _noteCtrl.clear();
      widget.onChanged(_journal.copyWith(notes: [..._journal.notes, note]));
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  void _removeNote(String id) {
    widget.onChanged(
      _journal.copyWith(
        notes: [for (final n in _journal.notes) if (n.id != id) n],
      ),
    );
  }

  Future<void> _openVideo(String path) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PostRideVideoPage(path: path)),
    );
  }

  Future<void> _openPhoto(String path) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PostRidePhotoPage(path: path),
      ),
    );
  }

  Future<void> _openAddSheet() async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.elevated,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const ChromeGlyph('photo', size: 22),
                title: Text(l10n.postRidePhotoCamera),
                enabled: _journal.canAddPhoto && !_picking,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const ChromeGlyph('photo', size: 22),
                title: Text(l10n.postRidePhotoGallery),
                enabled: _journal.canAddPhoto && !_picking,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const ChromeGlyph('play', size: 22),
                title: Text(l10n.postRideVideoCamera),
                enabled: _journal.canAddVideo && !_picking,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const ChromeGlyph('play', size: 22),
                title: Text(l10n.postRideVideoGallery),
                enabled: _journal.canAddVideo && !_picking,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVideo(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.postRideMediaTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (_journal.hasMedia)
                  IconButton(
                    tooltip: l10n.postRidePhotosShare,
                    visualDensity: VisualDensity.compact,
                    onPressed: _share,
                    icon: const ChromeGlyph('share', size: 20),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          if (_journal.hasMedia)
            _filledStrip(context)
          else
            _emptyDrop(context, l10n),
          const SizedBox(height: AppSpacing.m),
          if (_journal.notes.isNotEmpty) ...[
            for (final n in _journal.notes.reversed) _noteChip(n),
            const SizedBox(height: AppSpacing.s),
          ],
          _noteField(l10n),
        ],
      ),
    );
  }

  Widget _emptyDrop(BuildContext context, AppLocalizations l10n) {
    return Material(
      color: AppColors.elevated,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        onTap: _picking ? null : _openAddSheet,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: CustomPaint(
          painter: const _DashPainter(color: AppColors.border),
          child: SizedBox(
            width: double.infinity,
            height: 96,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChromeGlyph(
                      'photo',
                      color: AppColors.accent.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    ChromeGlyph(
                      'play',
                      color: AppColors.accent.withValues(alpha: 0.9),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  l10n.postRideAddMedia,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.postRideMediaHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filledStrip(BuildContext context) {
    final photos = _journal.photos;
    final videos = _journal.videos;
    return SizedBox(
      height: _thumb,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _addTile(),
          const SizedBox(width: AppSpacing.s),
          for (var i = 0; i < photos.length; i++) ...[
            _thumbFrame(
              pinned: photos[i].hasPin,
              privacyStripped: photos[i].privacyStripped,
              onTap: () => _openPhoto(photos[i].path),
              onRemove: () => _removePhoto(i),
              child: Image.file(
                File(photos[i].path),
                width: i == 0 ? _thumb * 1.35 : _thumb,
                height: _thumb,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _broken(
                  width: i == 0 ? _thumb * 1.35 : _thumb,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
          ],
          for (var i = 0; i < videos.length; i++) ...[
            _thumbFrame(
              pinned: videos[i].hasPin,
              privacyStripped: videos[i].privacyStripped,
              onTap: () => _openVideo(videos[i].path),
              onRemove: () => _removeVideo(i),
              child: SizedBox(
                width: _thumb,
                height: _thumb,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: AppColors.overlay),
                    const Center(
                      child: ChromeGlyph(
                        'play',
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          AppLocalizations.of(context).postRideVideoCamera,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
          ],
        ],
      ),
    );
  }

  Widget _addTile() {
    final canAdd = _journal.canAddPhoto || _journal.canAddVideo;
    return Material(
      color: AppColors.elevated,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        onTap: (_picking || !canAdd) ? null : _openAddSheet,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: SizedBox(
          width: 72,
          height: _thumb,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChromeGlyph(
                'add',
                color: canAdd ? AppColors.accent : AppColors.muted,
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).add,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: canAdd ? AppColors.chipIdleText : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noteChip(SavedRouteNote n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s, right: AppSpacing.xs),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: ChromeGlyph('stimmen', size: 16, color: AppColors.muted),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(n.text, style: const TextStyle(fontSize: 14)),
            ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => _removeNote(n.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteField(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: TextField(
        controller: _noteCtrl,
        minLines: 1,
        maxLines: 3,
        maxLength: RideJournal.maxNoteChars,
        decoration: InputDecoration(
          hintText: l10n.postRideNotesPlaceholder,
          isDense: true,
          counterText: '',
          prefixIcon: const ChromeGlyph('file', size: 20, color: AppColors.muted),
          suffixIcon: IconButton(
            tooltip: l10n.postRideNotesAdd,
            onPressed: _savingNote ? null : _addNote,
            icon: _savingNote
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const ChromeGlyph('send', size: 22),
          ),
        ),
        scrollPadding: const EdgeInsets.only(bottom: 120),
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _addNote(),
      ),
    );
  }

  Widget _broken({double width = _thumb}) => SizedBox(
        width: width,
        height: _thumb,
        child: const ColoredBox(
          color: AppColors.elevated,
          child: ChromeGlyph('photo', size: 24, color: AppColors.muted),
        ),
      );

  Widget _thumbFrame({
    required Widget child,
    required VoidCallback onRemove,
    required VoidCallback onTap,
    bool pinned = false,
    bool privacyStripped = false,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: Material(
            color: Colors.transparent,
            child: InkWell(onTap: onTap, child: child),
          ),
        ),
        if (pinned || privacyStripped)
          Positioned(
            left: 6,
            top: 6,
            child: ChromeGlyph(
              pinned ? 'flag' : 'locate',
              size: 16,
              color: Colors.white,
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.chip),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dash = 6.0;
    const gap = 4.0;
    final path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => old.color != color;
}

class _PostRidePhotoPage extends StatelessWidget {
  const _PostRidePhotoPage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const ChromeGlyph(
              'photo',
              size: 48,
              color: Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}
