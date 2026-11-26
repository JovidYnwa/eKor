import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/tokens.dart';

/// Bottom tab bar (`Layout_tabbar` on the web): Главная / Мастера / Задания / Профиль.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final tabs = [
      (LucideIcons.house, s.navHome),
      (LucideIcons.users, s.navMasters),
      (LucideIcons.clipboardList, s.navTasks),
      (LucideIcons.user, s.navProfile),
    ];

    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.line200)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppSizes.tabBarH,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _Tab(
                      icon: tabs[i].$1,
                      label: tabs[i].$2,
                      selected: shell.currentIndex == i,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        // Tapping the active tab returns to its first screen.
                        shell.goBranch(i,
                            initialLocation: i == shell.currentIndex);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brand600 : AppColors.ink500;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.style(
                11,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
                height: 1.2,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
