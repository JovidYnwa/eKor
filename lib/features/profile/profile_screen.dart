import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/config.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/lang_switch.dart';
import '../auth/data/auth_repository.dart';
import '../auth/data/user.dart';
import '../auth/session.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final user = ref.watch(sessionProvider).value;

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(title: Text(s.navProfile)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.pageX),
        children: [
          if (user == null)
            _GuestCard(s: s)
          else
            _UserCard(user: user, s: s),
          const SizedBox(height: AppSpace.s4),
          _Group(children: [
            ListTile(
              leading: const Icon(LucideIcons.globe, color: AppColors.ink700),
              title: Text(s.language, style: AppText.label),
              trailing: const LangSwitch(),
            ),
            const Divider(indent: 56),
            ListTile(
              leading: const Icon(LucideIcons.phone, color: AppColors.ink700),
              title: Text(s.support, style: AppText.label),
              subtitle: Text(
                '${AppConfig.supportPhoneDisplay} · ${s.supportHours}',
                style: AppText.caption.copyWith(color: AppColors.ink500),
              ),
            ),
          ]),
          if (user != null) ...[
            const SizedBox(height: AppSpace.s4),
            _Group(children: [
              ListTile(
                leading:
                    const Icon(LucideIcons.logOut, color: AppColors.danger600),
                title: Text(s.logout,
                    style: AppText.label.copyWith(color: AppColors.danger600)),
                onTap: () => _confirmLogout(context, ref, s),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref, S s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.logoutTitle),
        content: Text(s.logoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger600),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.logout),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(sessionProvider.notifier).logout();
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.s});
  final S s;

  @override
  Widget build(BuildContext context) {
    return _Group(
      padding: const EdgeInsets.all(AppSpace.s4),
      children: [
        Text(s.phoneTitle, style: AppText.h3),
        const SizedBox(height: AppSpace.s1),
        Text(s.phoneSub, style: AppText.body.copyWith(color: AppColors.ink700)),
        const SizedBox(height: AppSpace.s4),
        AppButton(
          label: s.login,
          onPressed: () => context.push('/login?from=/profile'),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.s});
  final User user;
  final S s;

  @override
  Widget build(BuildContext context) {
    final digits = user.phone.replaceAll(RegExp(r'\D'), '');
    final local = digits.length >= 9 ? digits.substring(digits.length - 9) : digits;
    final initial = user.hasName ? user.name!.trim()[0].toUpperCase() : '?';

    return _Group(
      padding: const EdgeInsets.all(AppSpace.s4),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.brand100,
              foregroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: Text(initial,
                  style: AppText.style(22,
                      weight: FontWeight.w700, color: AppColors.brand600)),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.hasName ? user.name! : s.noName,
                    style: AppText.h3.copyWith(
                        color: user.hasName ? AppColors.ink900 : AppColors.ink500),
                  ),
                  const SizedBox(height: 2),
                  Text('+992 ${formatPhone(local)}',
                      style: AppText.body.copyWith(color: AppColors.ink500)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children, this.padding});
  final List<Widget> children;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
