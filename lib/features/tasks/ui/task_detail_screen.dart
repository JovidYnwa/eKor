import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../masters/ui/master_profile_screen.dart' show PhotoViewer;
import '../data/task.dart';
import 'task_tile.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final task = ref.watch(taskDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(title: Text(s.task)),
      body: task.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: ErrorState(
              error: e, s: s, onRetry: () => ref.invalidate(taskDetailProvider(id))),
        ),
        data: (t) => RefreshIndicator(
          onRefresh: () => ref.refresh(taskDetailProvider(id).future),
          child: _Content(t: t, s: s),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.t, required this.s});
  final Task t;
  final S s;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = taskStatusColors(t.status);
    final place = [
      if (t.city != null) s.pick(t.city!.nameRu, t.city!.nameTj),
      if (t.district != null) s.pick(t.district!.nameRu, t.district!.nameTj),
      if (t.address != null && t.address!.isNotEmpty) t.address!,
    ].join(', ');
    final photos = t.photos.map((p) => p.url).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Pill(label: s.taskStatus(t.status), color: fg, background: bg),
                  Pill(label: s.pick(t.category.nameRu, t.category.nameTj)),
                  if (t.subcategory != null)
                    Pill(label: s.pick(t.subcategory!.nameRu, t.subcategory!.nameTj)),
                ],
              ),
              const SizedBox(height: 12),
              Text(t.title, style: AppText.h2),
              const SizedBox(height: 8),
              Text(
                [
                  if (t.publishedAt != null) s.ago(t.publishedAt!),
                  s.responsesCount(t.responsesCount),
                  s.views(t.viewsCount),
                ].join(' · '),
                style: AppText.caption.copyWith(color: AppColors.ink500),
              ),
            ],
          ),
        ),
        if (t.status == 'rejected' && t.rejectComment != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger50,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.danger200),
              ),
              child: Text(t.rejectComment!, style: AppText.body),
            ),
          ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => PhotoViewer(urls: photos, initial: i),
                )),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: SizedBox(width: 160, child: NetImage(photos[i])),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Row(
                  icon: LucideIcons.wallet,
                  label: s.budgetLabel,
                  value: s.budget(t.budgetMode, t.budgetMin, t.budgetMax),
                ),
                _Row(
                  icon: LucideIcons.calendar,
                  label: s.whenLabel,
                  value: s.when(t.when, t.date),
                ),
                if (place.isNotEmpty)
                  _Row(icon: LucideIcons.mapPin, label: s.placeLabel, value: place),
                if (t.clientName != null)
                  _Row(
                    icon: LucideIcons.user,
                    label: s.clientLabel,
                    value: t.clientName!,
                    last: true,
                  ),
              ],
            ),
          ),
        ),
        if (t.description != null && t.description!.trim().isNotEmpty) ...[
          SectionTitle(s.details),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppCard(
              child: SizedBox(
                width: double.infinity,
                child: Text(t.description!, style: AppText.bodyLg),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.line100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.ink500),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label, style: AppText.body.copyWith(color: AppColors.ink500)),
          ),
          Expanded(child: Text(value, style: AppText.label)),
        ],
      ),
    );
  }
}
