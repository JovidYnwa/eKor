import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/paged_list.dart';
import '../data/task.dart';
import 'task_tile.dart';

/// "Мои задания" with Active / Archive tabs.
class MyTasksScreen extends ConsumerWidget {
  const MyTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppBar(
          title: Text(s.myTasks),
          bottom: TabBar(
            labelStyle: AppText.label,
            unselectedLabelStyle: AppText.style(15, weight: FontWeight.w500),
            labelColor: AppColors.ink900,
            unselectedLabelColor: AppColors.ink500,
            indicatorColor: AppColors.brand600,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: AppColors.line200,
            tabs: [Tab(text: s.tabActive), Tab(text: s.tabArchive)],
          ),
        ),
        body: const TabBarView(
          children: [_TaskList(tab: 'active'), _TaskList(tab: 'archive')],
        ),
      ),
    );
  }
}

class _TaskList extends ConsumerStatefulWidget {
  const _TaskList({required this.tab});
  final String tab;

  @override
  ConsumerState<_TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<_TaskList>
    with AutomaticKeepAliveClientMixin {
  late final PagedController<Task> _list = PagedController(
    (cursor) => ref.read(tasksRepositoryProvider).mine(tab: widget.tab, cursor: cursor),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _list.loadMore();
  }

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = ref.watch(stringsProvider);
    return ListenableBuilder(
      listenable: _list,
      builder: (context, _) {
        if (_list.isFirstLoad) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_list.items.isEmpty && _list.error != null) {
          return Center(child: ErrorState(error: _list.error!, s: s, onRetry: _list.refresh));
        }
        if (_list.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: _list.refresh,
            child: ListView(
              children: [
                EmptyState(
                  icon: LucideIcons.clipboardList,
                  title: widget.tab == 'active' ? s.noActiveTasks : s.noArchiveTasks,
                  body: widget.tab == 'active' ? s.noTasksBody : null,
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _list.refresh,
          child: LoadMoreListener(
            onEnd: _list.loadMore,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _list.items.length + (_list.loading ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i >= _list.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final t = _list.items[i];
                return TaskTile(
                  t: t,
                  s: s,
                  showStatus: true,
                  onTap: () => context.push('/task/${t.id}'),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
