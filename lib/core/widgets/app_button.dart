import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';

/// Primary action button (`Button_primary` + `Button_lg` on the web).
/// Shows a spinner and a lighter background while [busy].
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.busyLabel,
  });

  final String label;
  final String? busyLabel;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final style = busy
        ? FilledButton.styleFrom(
            disabledBackgroundColor: AppColors.brand600Busy,
            disabledForegroundColor: AppColors.white,
          )
        : null;
    return FilledButton(
      style: style,
      onPressed: busy || onPressed == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed!();
            },
      child: busy
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.white,
                  ),
                ),
                if (busyLabel != null) ...[
                  const SizedBox(width: 10),
                  Text(busyLabel!),
                ],
              ],
            )
          : Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}
