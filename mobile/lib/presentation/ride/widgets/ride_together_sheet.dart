import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/nav_hud_tokens.dart';
import '../../../data/community/ride_group_cloud.dart';
import '../../../data/community/ride_group_store.dart';
import '../../../data/community/ride_together_look.dart';
import '../../../domain/community/ride_group_policy.dart';
import '../../../domain/community/ride_together.dart';
import '../../../l10n/app_localizations.dart';
import '../../shell/hof_threshold_nav.dart';
import 'ride_hud_island.dart';

class RideTogetherChip extends StatelessWidget {
  const RideTogetherChip({
    super.key,
    required this.onTap,
    this.line,
    this.compact = false,
  });

  final VoidCallback onTap;
  final String? line;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sunlight = AppColors.isSunlight(context);
    final text = (line ?? '').trim().isEmpty ? l10n.rideTogether : line!.trim();
    final parsed = _splitTogetherChipLine(text);
    final ink = sunlight ? AppColors.sunText : AppColors.chipIdleText;
    return RideHudIsland(
      key: const Key('ride-together-chip'),
      onTap: onTap,
      padding: compact ? RideHudIsland.compactPad : RideHudIsland.pad,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: NavHudTokens.islandHitDp),
        child: Row(
          children: [
            Icon(
              Icons.people_outline,
              size: compact ? 18 : 20,
              color: sunlight ? AppColors.sageOnLight : AppColors.sageOnDark,
            ),
            const SizedBox(width: 10),
            Expanded(child: _chipLabel(parsed, ink)),
            Icon(
              Icons.chevron_right,
              size: compact ? 18 : 20,
              color: AppColors.meta(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipLabel(({String? code, String label}) parsed, Color ink) {
    final code = parsed.code;
    if (code == null) {
      return Text(
        parsed.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: NavHudTokens.layerLabelDp,
          fontWeight: NavHudTokens.layerLabelWeight,
          height: 1.1,
          color: ink,
        ),
      );
    }
    return Row(
      children: [
        Text(
          code,
          maxLines: 1,
          style: TextStyle(
            fontSize: NavHudTokens.islandCodeDp,
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: NavHudTokens.islandCodeTracking,
            fontFeatures: const [FontFeature.tabularFigures()],
            fontFamily: 'monospace',
            color: ink,
          ),
        ),
        if (parsed.label.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              parsed.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: NavHudTokens.layerLabelDp,
                fontWeight: NavHudTokens.layerLabelWeight,
                height: 1.1,
                color: ink.withValues(alpha: 0.78),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

({String? code, String label}) _splitTogetherChipLine(String text) {
  const sep = ' · ';
  final i = text.indexOf(sep);
  if (i == RideGroupPolicy.joinCodeLen) {
    return (code: text.substring(0, i), label: text.substring(i + sep.length));
  }
  if (text.length == RideGroupPolicy.joinCodeLen) {
    return (code: text, label: '');
  }
  return (code: null, label: text);
}

String rideTogetherChipLine(
  AppLocalizations l10n, {
  required TogetherChipKind kind,
  String? joinCode,
  String? inboundName,
}) {
  switch (kind) {
    case TogetherChipKind.code:
      return (joinCode ?? '').trim();
    case TogetherChipKind.soloWait:
      return _chipCodeStatus(joinCode, l10n.rideTogetherSoloWait);
    case TogetherChipKind.wait:
      return _chipCodeStatus(joinCode, l10n.rideTogetherWait);
    case TogetherChipKind.accepted:
      return _chipCodeStatus(joinCode, l10n.rideTogetherAccepted);
    case TogetherChipKind.declined:
      return _chipCodeStatus(joinCode, l10n.rideTogetherDeclined);
    case TogetherChipKind.inbound:
      return _chipCodeStatus(
        joinCode,
        l10n.rideTogetherInbound(
          (inboundName ?? '').trim().isEmpty
              ? l10n.rideTogetherAnon
              : inboundName!.trim(),
        ),
      );
    case TogetherChipKind.idle:
      return l10n.rideTogether;
  }
}

String _chipCodeStatus(String? joinCode, String status) {
  final code = (joinCode ?? '').trim();
  if (code.length == RideGroupPolicy.joinCodeLen) return '$code · $status';
  return status;
}

class RideTogetherSheet extends StatefulWidget {
  const RideTogetherSheet({
    super.key,
    required this.groups,
    required this.look,
    this.lat,
    this.lng,
    this.inPrivacyZone = false,
    this.onPaired,
  });

  final RideGroupStore groups;
  final RideTogetherLook look;
  final double? lat;
  final double? lng;
  final bool inPrivacyZone;
  final VoidCallback? onPaired;

  @override
  State<RideTogetherSheet> createState() => _RideTogetherSheetState();
}

class _RideTogetherSheetState extends State<RideTogetherSheet> {
  String? _note;
  final _code = TextEditingController();

  RideTogetherLook get _look => widget.look;

  @override
  void initState() {
    super.initState();
    _look.attachSheet();
    _look.addListener(_onLook);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_boot());
    });
  }

  @override
  void dispose() {
    _look.removeListener(_onLook);
    _look.detachSheet();
    _code.dispose();
    super.dispose();
  }

  void _onLook() {
    if (mounted) setState(() {});
  }

  Future<void> _boot() async {
    final l10n = AppLocalizations.of(context);
    await _look.ensureStarted(
      lat: widget.lat,
      lng: widget.lng,
      inPrivacyZone: widget.inPrivacyZone,
      needGpsNote: l10n.rideTogetherNeedGps,
      inZoneNote: l10n.rideTogetherInZone,
      needLoginNote: l10n.rideTogetherNeedLogin,
    );
  }

  Future<void> _ask(TogetherNearby n) async {
    final res = await _look.ask(n);
    if (!mounted) return;
    setState(() => _note = _togetherNote(res));
  }

  Future<void> _respond(TogetherInbound inbound, bool accept) async {
    final res = await _look.respond(inbound, accept);
    if (!mounted) return;
    if (accept && res != null && res.ok && res.bundle != null) {
      await widget.groups.adoptCloudBundle(res.bundle!);
      widget.onPaired?.call();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _note = _togetherNote(res));
  }

  Future<void> _joinCode() async {
    final code = RideGroupPolicy.normalizeJoinCode(_code.text);
    if (code.length != RideGroupPolicy.joinCodeLen) {
      setState(() => _note = AppLocalizations.of(context).rideTogetherCodeInvalid);
      return;
    }
    final res = await _look.joinByCode(code);
    if (!mounted) return;
    if (res != null &&
        res.ok &&
        res.bundle != null &&
        res.bundle!.groups.isNotEmpty) {
      await widget.groups.adoptCloudBundle(res.bundle!);
      widget.onPaired?.call();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _note = _togetherNote(res) ?? AppLocalizations.of(context).rideTogetherCodeUnknown);
  }

  Future<void> _stopLook() async {
    await _look.stop();
  }

  String? _togetherNote(RideGroupCloudResult? res) {
    if (res == null) return null;
    final l10n = AppLocalizations.of(context);
    if (res.error == 'full') return l10n.rideTogetherFull;
    if (res.error == 'two_sessions') return l10n.rideTogetherTwoSessions;
    if (res.error == 'not_looking') return l10n.rideTogetherNotLooking;
    if (res.error == 'rate_limited') return l10n.rideTogetherRateLimited;
    if (res.error == 'too_far') return l10n.rideTogetherTooFar;
    return res.note;
  }

  String _name(String label, AppLocalizations l10n) =>
      label.trim().isEmpty ? l10n.rideTogetherAnon : label.trim();

  String _bucket(String bucket, AppLocalizations l10n) =>
      bucket == 'beside' ? l10n.rideTogetherBeside : l10n.rideTogetherNear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snap = _look.snap;
    final busy = _look.busy;
    final pendingTo = _look.pendingTo;
    final shownNote = _note ?? _look.note;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          HofThresholdNav.sheetBottomInset(context),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.rideTogether,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.rideTogetherSearch,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              if (snap != null && snap.members.length >= 2) ...[
                const SizedBox(height: 8),
                Text(
                  snap.members.length >= RideTogetherPolicy.memberCap
                      ? l10n.rideTogetherFull
                      : l10n.rideTogetherClosedHint,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
              if (shownNote != null && shownNote.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(shownNote, style: const TextStyle(fontSize: 13)),
              ],
              if (snap != null && snap.inbound.isNotEmpty) ...[
                const SizedBox(height: 14),
                for (final inbound in snap.inbound)
                  RideTogetherInboundCard(
                    onAccept: busy ? null : () => unawaited(_respond(inbound, true)),
                    onDecline: busy ? null : () => unawaited(_respond(inbound, false)),
                    acceptLabel: l10n.rideTogetherAccept,
                    declineLabel: l10n.rideTogetherDecline,
                    askLabel: l10n.rideTogetherInbound(_name(inbound.label, l10n)),
                  ),
              ],
              if (snap != null) ...[
                const SizedBox(height: 12),
                if (snap.nearby.isEmpty)
                  Text(
                    l10n.rideTogetherEmpty,
                    style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  )
                else
                  for (final n in snap.nearby)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        child: ListTile(
                          key: Key('ride-together-near-${n.userId}'),
                          title: Text(
                            _name(n.label, l10n),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(_bucket(n.bucket, l10n)),
                          trailing: TextButton(
                            onPressed: busy || pendingTo == n.userId
                                ? null
                                : () => unawaited(_ask(n)),
                            child: Text(
                              pendingTo == n.userId
                                  ? l10n.rideTogetherWait
                                  : l10n.rideTogetherAsk,
                            ),
                          ),
                        ),
                      ),
                    ),
                if (snap.joinCode != null && snap.joinCode!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.rideTogetherCodeHint,
                    style: const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: snap.joinCode!));
                    },
                    child: Text(
                      snap.joinCode!,
                      key: const Key('ride-together-code'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 14),
              TextField(
                key: const Key('ride-together-code-field'),
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.visiblePassword,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: const [_JoinCodeFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.rideTogetherJoinCode,
                  counterText: '',
                ),
                onSubmitted: (_) => unawaited(_joinCode()),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('ride-together-join'),
                onPressed: busy ? null : () => unawaited(_joinCode()),
                child: Text(l10n.rideTogetherJoin),
              ),
              if (_look.looking) ...[
                const SizedBox(height: 8),
                TextButton(
                  key: const Key('ride-together-stop-look'),
                  onPressed: busy ? null : () => unawaited(_stopLook()),
                  child: Text(l10n.rideTogetherStopLook),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RideTogetherInboundCard extends StatelessWidget {
  const RideTogetherInboundCard({
    super.key,
    required this.askLabel,
    required this.acceptLabel,
    required this.declineLabel,
    required this.onAccept,
    required this.onDecline,
  });

  final String askLabel;
  final String acceptLabel;
  final String declineLabel;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    return RideHudIsland(
      padding: RideHudIsland.pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            askLabel,
            style: TextStyle(
              fontSize: NavHudTokens.layerLabelDp,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: AppColors.sheetInk(context),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const Key('ride-together-accept'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.chromeFill(context),
                    foregroundColor: AppColors.inkOnChrome(context),
                    minimumSize: const Size.fromHeight(NavHudTokens.islandHitDp),
                  ),
                  onPressed: onAccept,
                  child: Text(
                    acceptLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  key: const Key('ride-together-decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.sheetInk(context),
                    minimumSize: const Size.fromHeight(NavHudTokens.islandHitDp),
                  ),
                  onPressed: onDecline,
                  child: Text(
                    declineLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JoinCodeFormatter extends TextInputFormatter {
  const _JoinCodeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final n = RideGroupPolicy.normalizeJoinCode(newValue.text);
    final clipped = n.length > RideGroupPolicy.joinCodeLen
        ? n.substring(0, RideGroupPolicy.joinCodeLen)
        : n;
    return TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: clipped.length),
    );
  }
}
