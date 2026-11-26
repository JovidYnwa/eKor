import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/paged_list.dart';
import '../../../core/widgets/pickers.dart';
import '../../catalog/data/category.dart';
import '../../catalog/data/city.dart';
import '../data/master.dart';
import '../data/masters_repository.dart';
import 'master_tile.dart';

/// Masters catalog: search, city, category, filters, infinite list.
/// [initialCategoryId] comes from `/masters?cat=ID` (e.g. home category tiles).
class MastersScreen extends ConsumerStatefulWidget {
  const MastersScreen({super.key, this.initialCategoryId});
  final int? initialCategoryId;

  @override
  ConsumerState<MastersScreen> createState() => _MastersScreenState();
}

class _MastersScreenState extends ConsumerState<MastersScreen> {
  late MasterFilters _filters =
      MasterFilters(categoryId: widget.initialCategoryId);
  late final PagedController<MasterCard> _list = PagedController(_loader());
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _list.loadMore();
  }

  @override
  void didUpdateWidget(MastersScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialCategoryId != old.initialCategoryId) {
      _apply(_filters.copyWith(categoryId: () => widget.initialCategoryId));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _list.dispose();
    super.dispose();
  }

  PageLoader<MasterCard> _loader() {
    final repo = ref.read(mastersRepositoryProvider);
    final filters = _filters;
    final cityId = ref.read(selectedCityProvider);
    return (cursor) => repo.catalog(filters: filters, cityId: cityId, cursor: cursor);
  }

  void _apply(MasterFilters f) {
    setState(() => _filters = f);
    _list.reset(_loader());
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400),
        () => _apply(_filters.copyWith(q: q)));
  }

  Future<void> _pickCategory() async {
    final id = await showCategoryPicker(context, selected: _filters.categoryId);
    if (id == null) return;
    _apply(_filters.copyWith(categoryId: () => id == -1 ? null : id));
  }

  Future<void> _pickSort(S s) async {
    const codes = ['rel', 'reviews', 'available'];
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(s.sortLabel, style: AppText.h3),
            ),
            for (var i = 0; i < codes.length; i++)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                title: Text(s.sorts[i], style: AppText.label),
                trailing: _filters.sort == codes[i]
                    ? const Icon(LucideIcons.check, color: AppColors.brand600)
                    : null,
                onTap: () => Navigator.pop(ctx, codes[i]),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) _apply(_filters.copyWith(sort: picked));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final city = ref.watch(selectedCityObjProvider);
    // Reload when the city changes elsewhere (e.g. on Home).
    ref.listen(selectedCityProvider, (_, _) => _list.reset(_loader()));

    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final catName = _filters.categoryId == null
        ? s.category
        : cats
            .where((c) => c.id == _filters.categoryId)
            .map((c) => s.pick(c.nameRu, c.nameTj))
            .firstOrNull ?? s.category;

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(
        title: Text(s.navMasters),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearch,
                  style: AppText.bodyLg,
                  decoration: InputDecoration(
                    hintText: s.mastersSearchPh,
                    prefixIcon: const Icon(LucideIcons.search,
                        size: 20, color: AppColors.ink500),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(LucideIcons.x, size: 18),
                            onPressed: () {
                              _search.clear();
                              _apply(_filters.copyWith(q: ''));
                            },
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  children: [
                    _Chip(
                      icon: LucideIcons.mapPin,
                      label: city == null ? s.allCities : s.pick(city.nameRu, city.nameTj),
                      selected: city != null,
                      onTap: () => showCityPicker(context, ref),
                    ),
                    _Chip(
                      icon: LucideIcons.layoutGrid,
                      label: catName,
                      selected: _filters.categoryId != null,
                      onTap: _pickCategory,
                    ),
                    _Chip(
                      label: s.availableToday,
                      selected: _filters.available,
                      onTap: () => _apply(_filters.copyWith(available: !_filters.available)),
                    ),
                    _Chip(
                      label: s.rating4,
                      selected: _filters.rating4,
                      onTap: () => _apply(_filters.copyWith(rating4: !_filters.rating4)),
                    ),
                    _Chip(
                      icon: LucideIcons.arrowUpDown,
                      label: s.sorts[['rel', 'reviews', 'available'].indexOf(_filters.sort)],
                      selected: _filters.sort != 'rel',
                      onTap: () => _pickSort(s),
                    ),
                  ],
                ),
              ),
              const Divider(),
            ],
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _list,
        builder: (context, _) => _body(s),
      ),
    );
  }

  Widget _body(S s) {
    if (_list.isFirstLoad) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_list.items.isEmpty && _list.error != null) {
      return Center(child: ErrorState(error: _list.error!, s: s, onRetry: _list.refresh));
    }
    if (_list.items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: EmptyState(
            icon: LucideIcons.searchX,
            title: s.emptyMastersTitle,
            body: s.emptyMastersBody,
            action: _filters.isDefault && ref.read(selectedCityProvider) == null
                ? null
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(200, 48)),
                    onPressed: () {
                      _search.clear();
                      ref.read(selectedCityProvider.notifier).set(null);
                      _apply(const MasterFilters());
                    },
                    child: Text(s.resetFilters),
                  ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _list.refresh,
      child: LoadMoreListener(
        onEnd: _list.loadMore,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: _list.items.length + 2,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Text(s.found(_list.total ?? _list.items.length),
                  style: AppText.caption.copyWith(color: AppColors.ink500));
            }
            if (i == _list.items.length + 1) {
              if (_list.loading) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (_list.error != null) {
                return TextButton(onPressed: _list.loadMore, child: Text(s.retry));
              }
              return const SizedBox.shrink();
            }
            final m = _list.items[i - 1];
            return MasterTile(
              m: m,
              s: s,
              onTap: () => context.push('/master/${m.id}'),
            );
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.ink900;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.ink900 : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: BorderSide(color: selected ? AppColors.ink900 : AppColors.line300),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(label,
                    style: AppText.style(14, weight: FontWeight.w600, height: 1, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
