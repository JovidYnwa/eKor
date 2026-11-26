import 'package:ekor/core/l10n/strings.dart';
import 'package:ekor/core/theme/app_theme.dart';
import 'package:ekor/features/auth/ui/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

String fieldText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

Future<void> pumpLogin(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: MaterialApp(theme: AppTheme.light(), home: const LoginScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const s = S(AppLang.ru);

  testWidgets('"Get code" is disabled until 9 digits are entered',
      (tester) async {
    await pumpLogin(tester);
    expect(find.text(s.phoneTitle), findsOneWidget);

    FilledButton button() =>
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '93512');
    await tester.pump();
    expect(button().onPressed, isNull);

    await tester.enterText(find.byType(TextField), '935124407');
    await tester.pump();
    expect(button().onPressed, isNotNull);
    expect(fieldText(tester), '93 512 44 07');
  });

  testWidgets('shows operator error for an invalid prefix', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(find.byType(TextField), '335124407');
    await tester.pump();
    await tester.tap(find.text(s.getCode));
    await tester.pump();
    expect(find.text(s.errPhoneOperator), findsOneWidget);
  });

  testWidgets('pasted +992 number is normalized', (tester) async {
    await pumpLogin(tester);
    await tester.enterText(find.byType(TextField), '+992 93 512 44 07');
    await tester.pump();
    expect(fieldText(tester), '93 512 44 07');
  });

  testWidgets('switching to TJ translates the screen', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.text('TJ'));
    await tester.pumpAndSettle();
    expect(find.text(const S(AppLang.tj).phoneTitle), findsOneWidget);
  });
}
