import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/catalog/data/category.dart';
import '../../features/catalog/data/city.dart';
import '../format.dart';
import '../l10n/strings.dart';
import '../theme/tokens.dart';
import 'common.dart';

/// Bottom sheet to pick the city. Returns true if the selection changed.
Future<void> showCityPicker(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _CitySheet(),
  );
}

class _CitySheet extends ConsumerWidget {
  const _CitySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final cities = ref.watch(citiesProvider);
    final selected = ref.watch(selectedCityProvider);

    void choose(int? id) {
      HapticFeedback.selectionClick();
      ref.read(selectedCityProvider.notifier).set(id);
      Navigator.pop(context);
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(s.regionTitle, style: AppText.h3),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(s.regionSub,
                style: AppText.body.copyWith(color: AppColors.ink500)),
          ),
          const Divider(),
          Expanded(
            child: cities.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                  error: e, s: s, onRetry: () => ref.invalidate(citiesProvider)),
              data: (list) => ListView(
                controller: controller,
                children: [
                  _OptionTile(
                    icon: LucideIcons.globe,
                    title: s.allCities,
                    subtitle: s.onlineAll,
                    selected: selected == null,
                    onTap: () => choose(null),
                  ),
                  for (final c in list)
                    _OptionTile(
                      icon: LucideIcons.mapPin,
                      title: s.pick(c.nameRu, c.nameTj),
                      subtitle: [
                        if (c.regionRu.isNotEmpty && c.regionRu != c.nameRu)
                          s.pick(c.regionRu, c.regionTj),
                        s.masters(c.mastersCount),
                      ].join(' · '),
                      selected: selected == c.id,
                      onTap: () => choose(c.id),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to pick a category. Resolves to the chosen id;
/// `-1` means "all categories"; `null` means dismissed.
Future<int?> showCategoryPicker(BuildContext context, {int? selected}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CategorySheet(selected: selected),
  );
}

class _CategorySheet extends ConsumerWidget {
  const _CategorySheet({this.selected});
  final int? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final cats = ref.watch(categoriesProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(s.categories, style: AppText.h3),
          ),
          const Divider(),
          Expanded(
            child: cats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                  error: e, s: s, onRetry: () => ref.invalidate(categoriesProvider)),
              data: (list) => ListView(
                controller: controller,
                children: [
                  _OptionTile(
                    icon: LucideIcons.layoutGrid,
                    title: s.allCats,
                    selected: selected == null,
                    onTap: () => Navigator.pop(context, -1),
                  ),
                  for (final c in list)
                    _OptionTile(
                      icon: c.iconData,
                      title: s.pick(c.nameRu, c.nameTj),
                      subtitle: s.masters(c.mastersCount),
                      selected: selected == c.id,
                      onTap: () => Navigator.pop(context, c.id),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.brand100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: AppColors.brand600),
      ),
      title: Text(title, style: AppText.label),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: AppText.caption.copyWith(color: AppColors.ink500)),
      trailing: selected
          ? const Icon(LucideIcons.check, color: AppColors.brand600)
          : null,
    );
  }
}
