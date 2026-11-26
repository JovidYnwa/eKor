import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'features/auth/session.dart';

class EkorApp extends ConsumerWidget {
  const EkorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final session = ref.watch(sessionProvider);

    return MaterialApp.router(
      title: 'eKor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
      // App texts switch RU/TJ via `stringsProvider`. System widgets (date
      // pickers, copy/paste menus) use Russian: Flutter has no Tajik locale,
      // and Russian is what Tajik users expect there.
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        // Hold a branded splash until the stored session is restored,
        // so the first screen never flashes the wrong state.
        if (session.isLoading && !session.hasValue) return const _Splash();
        return child!;
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: Center(
        child: Text(
          'eKor',
          textDirection: TextDirection.ltr,
          style: AppText.style(34,
              weight: FontWeight.w700, color: AppColors.brand600),
        ),
      ),
    );
  }
}
