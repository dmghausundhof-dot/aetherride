import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/community/ride_group_invite.dart';
import '../../l10n/app_localizations.dart';
import '../auth/auth_screen.dart';
import '../shell/hof_threshold_nav.dart';

/// Eine Fläche Verbinden — ein Feld für Link oder öffentlichen Code.
class PlatzJoinSheet extends StatefulWidget {
  const PlatzJoinSheet({
    super.key,
    required this.signedIn,
    this.onSignIn,
  });

  final bool signedIn;
  final VoidCallback? onSignIn;

  @override
  State<PlatzJoinSheet> createState() => _PlatzJoinSheetState();
}

class _PlatzJoinSheetState extends State<PlatzJoinSheet> {
  late final TextEditingController _ctrl;
  String? _err;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final loc = AppLocalizations.of(context);
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _err = loc.platzJoinEmpty);
      return;
    }
    if (RideGroupInvite.parsePastedJoin(raw) == null) {
      setState(() => _err = loc.platzJoinInvalid);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, raw);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: HofThresholdNav.sheetBottomInset(context) +
              MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.platzJoinWithCode,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.platzJoinLinkHint,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            if (!widget.signedIn) ...[
              const SizedBox(height: 12),
              Text(
                loc.platzJoinSignInFirst,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('platz-join-signin'),
                onPressed: widget.onSignIn ?? () => openAuthScreen(context),
                child: Text(loc.signIn),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              key: const Key('platz-join-field'),
              controller: _ctrl,
              autofocus: widget.signedIn,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: loc.platzConnectField,
                isDense: true,
                errorText: _err,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            if (widget.signedIn)
              FilledButton(
                key: const Key('platz-join-submit'),
                onPressed: _submit,
                child: Text(loc.platzJoin),
              )
            else
              OutlinedButton(
                key: const Key('platz-join-submit'),
                onPressed: _submit,
                child: Text(loc.platzJoinLocalCta),
              ),
          ],
        ),
      ),
    );
  }
}
