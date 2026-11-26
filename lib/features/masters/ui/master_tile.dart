import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/format.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/common.dart';
import '../data/master.dart';

/// Master card in the catalog list.
class MasterTile extends StatelessWidget {
  const MasterTile({super.key, required this.m, required this.s, required this.onTap});
  final MasterCard m;
  final S s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final place = [
      if (m.city != null) s.pick(m.city!.nameRu, m.city!.nameTj),
      if (m.district != null) s.pick(m.district!.nameRu, m.district!.nameTj),
    ].join(', ');

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(url: m.avatarUrl, name: m.name, size: 56),
          const SizedBox(width: AppSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        m.name ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.style(17, weight: FontWeight.w600, height: 1.25),
                      ),
                    ),
                    if (m.verified) ...[
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.badgeCheck,
                          size: 18, color: AppColors.brand600),
                    ],
                  ],
                ),
                if (m.headline != null)
                  Text(
                    s.pick(m.headline!.nameRu, m.headline!.nameTj),
                    style: AppText.body.copyWith(color: AppColors.ink700),
                  ),
                const SizedBox(height: 6),
                RatingLine(
                  rating: m.ratingAvg,
                  label: m.reviewsCount > 0
                      ? s.reviewsCount(m.reviewsCount)
                      : s.noReviews,
                ),
                if (place.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 14, color: AppColors.ink400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption.copyWith(color: AppColors.ink500)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (m.availableToday)
                      Pill(
                        label: s.availableToday,
                        color: AppColors.success700,
                        background: AppColors.success100,
                      ),
                    if (m.priceFrom != null)
                      Pill(label: s.priceFrom(m.priceFrom!)),
                    if (m.completedOrders > 0)
                      Pill(label: s.ordersDone(m.completedOrders)),
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
