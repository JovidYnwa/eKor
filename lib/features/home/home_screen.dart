import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/l10n/strings.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/lang_switch.dart';
import '../../core/widgets/pickers.dart';
import '../catalog/data/category.dart';
import '../catalog/data/city.dart';
import '../masters/data/master.dart';
import '../masters/data/masters_repository.dart';
import '../masters/ui/master_profile_screen.dart' show ReviewCard;
import '../tasks/data/task.dart';
import '../tasks/ui/task_tile.dart';

// ── Home data, all scoped to the selected city ──────────────

final _mastersTotalProvider = FutureProvider.autoDispose<int>((ref) async {
  final page = await ref.watch(mastersRepositoryProvider).catalog(
        filters: const MasterFilters(),
        cityId: ref.watch(selectedCityProvider),
        limit: 1,
      );
  return page.total ?? page.items.length;
});

final _newTasksProvider = FutureProvider.autoDispose<List<Task>>((ref) async {
  final page = await ref
      .watch(tasksRepositoryProvider)
      .feed(cityId: ref.watch(selectedCityProvider), limit: 5);
  return page.items;
});

final _latestReviewsProvider = FutureProvider.autoDispose<List<Review>>((ref) =>
    ref.watch(mastersRepositoryProvider).latestReviews(cityId: ref.watch(selectedCityProvider)));

/// Home — mirrors the mobile layout of ekor.tj: logo + language, search and
/// city, categories, main actions, new tasks and latest reviews.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final categories = ref.watch(categoriesProvider);
    final tasks = ref.watch(_newTasksProvider);
    final reviews = ref.watch(_latestReviewsProvider);

    Future<void> refresh() async {
      ref.invalidate(citiesProvider);
      ref.invalidate(_mastersTotalProvider);
      ref.invalidate(_newTasksProvider);
      ref.invalidate(_latestReviewsProvider);
      ref.invalidate(categoriesProvider);
      await ref.read(categoriesProvider.future);
    }

    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: RefreshIndicator(
        color: AppColors.brand600,
        edgeOffset: MediaQuery.paddingOf(context).top,
        onRefresh: refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Hero(s: s)),
            SliverToBoxAdapter(child: _SectionHead(title: s.categories)),
            categories.when(
              data: (list) => _CategoriesGrid(
                categories: list.where((c) => !c.isOther).take(5).toList(),
                s: s,
              ),
              loading: () => const _CategoriesSkeleton(),
              error: (e, _) => SliverToBoxAdapter(
                child: _InlineError(
                  message: errorText(e, s),
                  retry: s.retry,
                  onRetry: () => ref.invalidate(categoriesProvider),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _Actions(s: s)),

            // ── New tasks ──
            SliverToBoxAdapter(child: _SectionHead(title: s.newTasks, top: 28)),
            ...tasks.when(
              loading: () => [const _ListSkeleton(height: 96)],
              error: (e, _) => [
                SliverToBoxAdapter(
                  child: _InlineError(
                    message: errorText(e, s),
                    retry: s.retry,
                    onRetry: () => ref.invalidate(_newTasksProvider),
                  ),
                ),
              ],
              data: (list) => [
                if (list.isEmpty)
                  SliverToBoxAdapter(child: _Note(text: s.noTasksYet))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => TaskTile(
                        t: list[i],
                        s: s,
                        onTap: () => context.push('/task/${list[i].id}'),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Latest reviews ──
            SliverToBoxAdapter(
              child: _SectionHead(title: s.lastReviews, note: s.reviewsNote, top: 28),
            ),
            ...reviews.when(
              loading: () => [const _ListSkeleton(height: 120)],
              error: (e, _) => [
                SliverToBoxAdapter(
                  child: _InlineError(
                    message: errorText(e, s),
                    retry: s.retry,
                    onRetry: () => ref.invalidate(_latestReviewsProvider),
                  ),
                ),
              ],
              data: (list) => [
                if (list.isEmpty)
                  SliverToBoxAdapter(child: _Note(text: s.noReviews))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) =>
                          ReviewCard(r: list[i], s: s, showMaster: true),
                    ),
                  ),
              ],
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpace.s8)),
          ],
        ),
      ),
    );
  }
}

class _Hero extends ConsumerWidget {
  const _Hero({required this.s});
  final S s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(selectedCityObjProvider);
    final total = ref.watch(_mastersTotalProvider).value;

    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.line200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                Text(
                  'eKor',
                  style: AppText.style(22,
                      weight: FontWeight.w700,
                      color: AppColors.brand600,
                      letterSpacing: -0.2),
                ),
                const Spacer(),
                const LangSwitch(),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s3),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.line200, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _SearchRow(
                  icon: LucideIcons.search,
                  title: s.searchPh,
                  placeholder: true,
                  onTap: () => context.go('/masters'),
                ),
                const Divider(height: 1),
                _SearchRow(
                  icon: LucideIcons.mapPin,
                  title: city == null ? s.allCities : s.pick(city.nameRu, city.nameTj),
                  subtitle: city == null
                      ? s.onlineAll
                      : (total != null ? s.masters(total) : null),
                  trailing: LucideIcons.chevronDown,
                  onTap: () => showCityPicker(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.placeholder = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final IconData? trailing;
  final bool placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: placeholder ? 52 : 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.ink500),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: placeholder
                          ? AppText.style(16, color: AppColors.ink400)
                          : AppText.style(15, weight: FontWeight.w600, height: 1.3),
                    ),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: AppText.caption.copyWith(color: AppColors.ink500)),
                  ],
                ),
              ),
              if (trailing != null) Icon(trailing, size: 20, color: AppColors.ink400),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.title, this.note, this.top = 16});
  final String title;
  final String? note;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.style(19, weight: FontWeight.w600)),
          if (note != null)
            Text(note!, style: AppText.caption.copyWith(color: AppColors.ink500)),
        ],
      ),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({required this.categories, required this.s});
  final List<Category> categories;
  final S s;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      for (final c in categories)
        _CatTile(
          icon: c.iconData,
          name: s.pick(c.nameRu, c.nameTj),
          onTap: () => context.go('/masters?cat=${c.id}'),
        ),
      _CatTile(
        icon: LucideIcons.ellipsis,
        name: s.allCats,
        onTap: () async {
          final id = await showCategoryPicker(context);
          if (id == null || !context.mounted) return;
          context.go(id == -1 ? '/masters' : '/masters?cat=$id');
        },
      ),
    ];
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      sliver: SliverGrid.count(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.98,
        children: tiles,
      ),
    );
  }
}

class _CatTile extends StatelessWidget {
  const _CatTile({required this.icon, required this.name, required this.onTap});
  final IconData icon;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.line200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brand100,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 22, color: AppColors.brand600),
              ),
              const SizedBox(height: AppSpace.s2),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.style(13, weight: FontWeight.w600, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesSkeleton extends StatelessWidget {
  const _CategoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      sliver: SliverGrid.count(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.98,
        children: List.generate(6, (_) => const _SkeletonBox()),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      sliver: SliverList.separated(
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, _) => SizedBox(height: height, child: const _SkeletonBox()),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.skeleton,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.s});
  final S s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(_mastersTotalProvider).value;
    final city = ref.watch(selectedCityObjProvider);
    final where = city == null ? s.allCities : s.pick(city.nameRu, city.nameTj);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionCard(
            title: s.findMaster,
            subtitle: total == null ? null : '${s.masters(total)} — $where',
            icon: LucideIcons.users,
            dark: true,
            onTap: () => context.go('/masters'),
          ),
          const SizedBox(height: AppSpace.s2),
          _ActionCard(
            title: s.postTask,
            subtitle: s.postTaskSub,
            icon: LucideIcons.plus,
            onTap: () => showSnack(context, s.soon),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.dark = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? AppColors.white : AppColors.ink900;
    return Material(
      color: dark ? AppColors.ink900 : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: dark ? BorderSide.none : const BorderSide(color: AppColors.line200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 22, color: dark ? fg : AppColors.brand600),
                const SizedBox(width: AppSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title,
                          style: AppText.style(17,
                              weight: FontWeight.w600, height: 1.3, color: fg)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: AppText.caption.copyWith(
                                color: dark
                                    ? AppColors.white.withValues(alpha: 0.8)
                                    : AppColors.ink500)),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight,
                    size: 20, color: dark ? fg : AppColors.ink400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: AppCard(
        child: Text(text, style: AppText.body.copyWith(color: AppColors.ink500)),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.retry,
    required this.onRetry,
  });

  final String message;
  final String retry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: AppCard(
        child: Row(
          children: [
            Expanded(child: Text(message, style: AppText.body)),
            TextButton(onPressed: onRetry, child: Text(retry)),
          ],
        ),
      ),
    );
  }
}
