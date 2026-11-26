import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/session.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';

/// Compact RU | TJ toggle, same as in the website header.
class LangSwitch extends ConsumerWidget {
  const LangSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(langProvider);
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final lang in AppLang.values)
            _LangButton(
              label: lang.code.toUpperCase(),
              selected: lang == current,
              onTap: () => setAppLang(ref, lang),
            ),
        ],
      ),
    );
  }
}

/// Switches the app language and, when signed in, saves it on the server
/// so SMS and notifications arrive in the same language.
void setAppLang(WidgetRef ref, AppLang lang) {
  if (ref.read(langProvider) == lang) return;
  HapticFeedback.selectionClick();
  ref.read(langProvider.notifier).set(lang);
  if (ref.read(sessionProvider).value != null) {
    ref.read(authRepositoryProvider).updateMe(lang: lang).ignore();
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x1A0F1B2A), blurRadius: 2)]
                : null,
          ),
          child: Text(
            label,
            style: AppText.style(
              13,
              weight: FontWeight.w600,
              height: 1,
              color: selected ? AppColors.ink900 : AppColors.ink500,
            ),
          ),
        ),
      ),
    );
  }
}
