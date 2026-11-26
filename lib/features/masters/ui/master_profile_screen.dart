import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/common.dart';
import '../../auth/session.dart';
import '../data/master.dart';
import '../data/masters_repository.dart';

class MasterProfileScreen extends ConsumerWidget {
  const MasterProfileScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final profile = ref.watch(masterProfileProvider(id));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(title: Text(s.navMasters)),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: ErrorState(
              error: e, s: s, onRetry: () => ref.invalidate(masterProfileProvider(id))),
        ),
        data: (p) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(masterReviewsProvider(id));
            ref.invalidate(masterProfileProvider(id));
            await ref.read(masterProfileProvider(id).future);
          },
          child: _Content(p: p, s: s),
        ),
      ),
      bottomNavigationBar: profile.value?.hasPhone == true
          ? _PhoneBar(masterId: id, s: s)
          : null,
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.p, required this.s});
  final MasterProfile p;
  final S s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = p.card;
    final reviews = ref.watch(masterReviewsProvider(m.id));
    final place = [
      if (m.city != null) s.pick(m.city!.nameRu, m.city!.nameTj),
      if (m.district != null) s.pick(m.district!.nameRu, m.district!.nameTj),
    ].join(', ');

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // ── Header ──
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Avatar(url: m.avatarUrl, name: m.name, size: 72),
                  const SizedBox(width: AppSpace.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(m.name ?? '—', style: AppText.h2)),
                            if (m.verified) ...[
                              const SizedBox(width: 6),
                              const Icon(LucideIcons.badgeCheck,
                                  size: 22, color: AppColors.brand600),
                            ],
                          ],
                        ),
                        if (m.headline != null)
                          Text(s.pick(m.headline!.nameRu, m.headline!.nameTj),
                              style: AppText.bodyLg.copyWith(color: AppColors.ink700)),
                        if (place.isNotEmpty)
                          Text(place,
                              style: AppText.caption.copyWith(color: AppColors.ink500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s4),
              Row(
                children: [
                  _Stat(
                    value: m.ratingAvg?.toStringAsFixed(1).replaceAll('.', ',') ?? '—',
                    label: s.reviewsCount(m.reviewsCount),
                    icon: Icons.star_rounded,
                  ),
                  _Stat(value: '${m.completedOrders}', label: s.ordersDone(m.completedOrders).split(' ').skip(1).join(' ')),
                  if (m.experience != null)
                    _Stat(value: s.experience(m.experience), label: s.exp),
                ],
              ),
              const SizedBox(height: AppSpace.s3),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Pill(
                    label: m.availableToday ? s.availableToday : s.busyNow,
                    color: m.availableToday ? AppColors.success700 : AppColors.ink500,
                    background: m.availableToday ? AppColors.success100 : AppColors.surface50,
                  ),
                  if (m.priceFrom != null) Pill(label: s.priceFrom(m.priceFrom!)),
                  if (p.memberSince != null) Pill(label: s.memberSince(p.memberSince!)),
                ],
              ),
              if (m.verified) ...[
                const SizedBox(height: AppSpace.s3),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.brand100),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.shieldCheck,
                          size: 20, color: AppColors.brand600),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(s.verifiedLong,
                              style: AppText.style(14, color: AppColors.ink700))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── About ──
        if (p.about != null && p.about!.trim().isNotEmpty) ...[
          SectionTitle(s.about),
          _Block(child: Text(p.about!, style: AppText.bodyLg)),
        ],

        // ── Services & prices ──
        if (p.professions.isNotEmpty || p.services.isNotEmpty) ...[
          SectionTitle(s.servicesTitle),
          _Block(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final pr in p.professions)
                  _PriceRow(
                    title: s.pick(pr.nameRu, pr.nameTj),
                    price: pr.priceFrom != null
                        ? s.priceFrom(pr.priceFrom!)
                        : s.negotiable,
                  ),
                for (final sv in p.services)
                  _PriceRow(
                    title: sv.title,
                    price: sv.price != null ? s.priceFrom(sv.price!) : s.negotiable,
                  ),
              ],
            ),
          ),
        ],

        // ── Portfolio ──
        if (p.portfolio.isNotEmpty) ...[
          SectionTitle(s.portfolio),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: p.portfolio.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _openPhotos(context, p.portfolio.map((e) => e.url).toList(), i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: SizedBox(width: 140, child: NetImage(p.portfolio[i].url)),
                ),
              ),
            ),
          ),
        ],

        // ── Areas & languages ──
        if (p.districts.isNotEmpty || p.languages.isNotEmpty) ...[
          SectionTitle(s.areas),
          _Block(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.districts.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final d in p.districts)
                        Pill(label: s.pick(d.nameRu, d.nameTj), icon: LucideIcons.mapPin),
                    ],
                  ),
                if (p.languages.isNotEmpty) ...[
                  if (p.districts.isNotEmpty) const SizedBox(height: 12),
                  Text('${s.langs}: ${p.languages.map(s.langName).join(', ')}',
                      style: AppText.body.copyWith(color: AppColors.ink700)),
                ],
              ],
            ),
          ),
        ],

        // ── Reviews ──
        SectionTitle(s.reviews,
            trailing: m.ratingAvg == null
                ? null
                : RatingLine(rating: m.ratingAvg, label: s.reviewsCount(m.reviewsCount))),
        reviews.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _Block(child: Text(errorText(e, s))),
          data: (page) => page.items.isEmpty
              ? _Block(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.noReviewsTitle, style: AppText.label),
                      const SizedBox(height: 4),
                      Text(s.noReviewsBody,
                          style: AppText.body.copyWith(color: AppColors.ink500)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (final r in page.items)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: ReviewCard(r: r, s: s),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  void _openPhotos(BuildContext context, List<String> urls, int index) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PhotoViewer(urls: urls, initial: index),
    ));
  }
}

/// Review card, shared with the home screen.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.r, required this.s, this.showMaster = false});
  final Review r;
  final S s;
  final bool showMaster;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: showMaster && r.masterId != null
          ? () => context.push('/master/${r.masterId}')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stars(value: r.rating),
              const Spacer(),
              if (r.createdAt != null)
                Text(s.ago(r.createdAt!),
                    style: AppText.caption.copyWith(color: AppColors.ink500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(r.text, style: AppText.bodyLg),
          const SizedBox(height: 8),
          Text('${r.authorName} · ${r.taskTitle}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(color: AppColors.ink500)),
          if (showMaster && r.masterName != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Avatar(name: r.masterName, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      r.masterName!,
                      if (r.masterHeadlineRu != null)
                        s.pick(r.masterHeadlineRu!, r.masterHeadlineTj),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.style(14, weight: FontWeight.w600),
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.ink400),
              ],
            ),
          ],
          if (r.replyText != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface50,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.masterReply, style: AppText.style(13, weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(r.replyText!, style: AppText.body),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen swipeable photos with pinch-zoom.
class PhotoViewer extends StatelessWidget {
  const PhotoViewer({super.key, required this.urls, this.initial = 0});
  final List<String> urls;
  final int initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: urls.length,
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(child: NetImage(urls[i], fit: BoxFit.contain)),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.icon});
  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: AppColors.warn600),
                const SizedBox(width: 2),
              ],
              Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.style(17, weight: FontWeight.w700, height: 1.2)),
              ),
            ],
          ),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(color: AppColors.ink500)),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(AppSpace.s4),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.line200),
        ),
        child: child,
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.title, required this.price});
  final String title;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line100)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppText.bodyLg)),
          const SizedBox(width: 12),
          Text(price, style: AppText.label),
        ],
      ),
    );
  }
}

/// "Show phone" bar. Requires login; reveals and lets the user call.
class _PhoneBar extends ConsumerStatefulWidget {
  const _PhoneBar({required this.masterId, required this.s});
  final int masterId;
  final S s;

  @override
  ConsumerState<_PhoneBar> createState() => _PhoneBarState();
}

class _PhoneBarState extends ConsumerState<_PhoneBar> {
  String? _phone;
  bool _busy = false;

  Future<void> _reveal() async {
    final s = widget.s;
    if (ref.read(sessionProvider).value == null) {
      context.push('/login?from=/master/${widget.masterId}');
      return;
    }
    setState(() => _busy = true);
    try {
      final phone = await ref.read(mastersRepositoryProvider).revealPhone(widget.masterId);
      setState(() => _phone = phone);
    } catch (e) {
      if (mounted) showSnack(context, errorText(e, s));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: _phone == null ? s.showPhone : '${s.call} · $_phone',
            busy: _busy,
            onPressed: _phone == null
                ? _reveal
                : () => launchUrl(Uri(scheme: 'tel', path: _phone!.replaceAll(' ', ''))),
          ),
          const SizedBox(height: 8),
          Text(s.phoneNote,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: AppColors.ink500)),
        ],
      ),
    );
  }
}
