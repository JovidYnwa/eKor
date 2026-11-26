import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../data/task.dart';

/// Status colors, matching the web badges.
(Color fg, Color bg) taskStatusColors(String status) => switch (status) {
      'open' => (AppColors.success700, AppColors.success100),
      'review' || 'draft' => (AppColors.warn800, AppColors.warn100),
      'chosen' => (AppColors.brand700, AppColors.brand100),
      'rejected' => (AppColors.danger700, AppColors.danger100),
      _ => (AppColors.ink500, AppColors.surface50),
    };

/// Task card used in the feed and in "My tasks".
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.t,
    required this.s,
    required this.onTap,
    this.showStatus = false,
  });

  final Task t;
  final S s;
  final VoidCallback onTap;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final place = [
      if (t.city != null) s.pick(t.city!.nameRu, t.city!.nameTj),
      if (t.district != null) s.pick(t.district!.nameRu, t.district!.nameTj),
    ].join(', ');
    final (fg, bg) = taskStatusColors(t.status);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 72,
              height: 72,
              child: t.coverUrl != null
                  ? NetImage(t.coverUrl!)
                  : ColoredBox(
                      color: AppColors.brand50,
                      child: Center(
                        child: Text(
                          s.noPhoto,
                          textAlign: TextAlign.center,
                          style: AppText.style(11, color: AppColors.ink400),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showStatus) ...[
                  Pill(label: s.taskStatus(t.status), color: fg, background: bg),
                  const SizedBox(height: 6),
                ],
                Text(
                  t.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.style(16, weight: FontWeight.w600, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  s.budget(t.budgetMode, t.budgetMin, t.budgetMax),
                  style: AppText.style(15, weight: FontWeight.w600, color: AppColors.ink900),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    s.pick(t.category.nameRu, t.category.nameTj),
                    s.when(t.when, t.date),
                    if (place.isNotEmpty) place,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(color: AppColors.ink500),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(LucideIcons.messageSquare, size: 14, color: AppColors.ink400),
                    const SizedBox(width: 4),
                    Text(s.responsesCount(t.responsesCount),
                        style: AppText.caption.copyWith(color: AppColors.ink500)),
                    if (t.publishedAt != null) ...[
                      const Spacer(),
                      Text(s.ago(t.publishedAt!),
                          style: AppText.caption.copyWith(color: AppColors.ink400)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
