import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import '../network/api_exception.dart';
import '../theme/tokens.dart';

/// Round avatar with the first letter as fallback.
class Avatar extends StatelessWidget {
  const Avatar({super.key, this.url, this.name, this.size = 48});
  final String? url;
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final letter = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()[0].toUpperCase()
        : '?';
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.brand100,
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: AppText.style(size * 0.42,
            weight: FontWeight.w700, height: 1, color: AppColors.brand600),
      ),
    );
    if (url == null) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}

/// ★ 4.5 · 12 отзывов
class RatingLine extends StatelessWidget {
  const RatingLine({
    super.key,
    required this.rating,
    required this.label,
    this.size = 14,
  });

  final double? rating;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded,
            size: size + 3,
            color: rating == null ? AppColors.line300 : AppColors.warn600),
        const SizedBox(width: 3),
        if (rating != null) ...[
          Text(rating!.toStringAsFixed(1).replaceAll('.', ','),
              style: AppText.style(size, weight: FontWeight.w600, height: 1.2)),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: AppText.style(size, height: 1.2, color: AppColors.ink500)),
        ),
      ],
    );
  }
}

/// Five stars for a review.
class Stars extends StatelessWidget {
  const Stars({super.key, required this.value, this.size = 16});
  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(Icons.star_rounded,
              size: size,
              color: i <= value ? AppColors.warn600 : AppColors.line200),
      ],
    );
  }
}

/// Small colored label, e.g. "Свободен сегодня", "Открыто".
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.color = AppColors.ink700,
    this.background = AppColors.surface50,
    this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(label, style: AppText.badge.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Network photo with a neutral placeholder.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => const ColoredBox(color: AppColors.skeleton),
      errorWidget: (_, _, _) => const ColoredBox(
        color: AppColors.surface50,
        child: Center(
            child: Icon(LucideIcons.imageOff, color: AppColors.ink400, size: 20)),
      ),
    );
  }
}

/// Centered empty / info state.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.brand100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.brand600, size: 28),
          ),
          const SizedBox(height: AppSpace.s4),
          Text(title, textAlign: TextAlign.center, style: AppText.h3),
          if (body != null) ...[
            const SizedBox(height: AppSpace.s2),
            Text(body!,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.ink500)),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpace.s5),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Error with a retry button.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.error,
    required this.s,
    required this.onRetry,
  });

  final Object error;
  final S s;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = error is ApiException && (error as ApiException).isNetwork;
    return EmptyState(
      icon: offline ? LucideIcons.wifiOff : LucideIcons.cloudAlert,
      title: errorText(error, s),
      action: OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
        onPressed: onRetry,
        child: Text(s.retry),
      ),
    );
  }
}

/// Section title used on detail screens.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
              child: Text(text, style: AppText.style(19, weight: FontWeight.w600))),
          ?trailing,
        ],
      ),
    );
  }
}

/// White rounded card with a hairline border.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

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
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpace.s4),
          child: child,
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
