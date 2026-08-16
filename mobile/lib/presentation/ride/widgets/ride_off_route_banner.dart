import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Calm off-route / rejoin status banner (N-02 Trust Theater).
class RideOffRouteBanner extends StatelessWidget {
  const RideOffRouteBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.background,
    this.foreground,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? AppColors.mapWarnFill;
    final fg = foreground ?? AppColors.mapWarnInk;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Material(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        color: bg,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: compact ? AppSpacing.xs : AppSpacing.s,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: compact ? FontWeight.w600 : FontWeight.w800,
                        color: fg,
                        fontSize: compact ? 13 : 15,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: fg.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
