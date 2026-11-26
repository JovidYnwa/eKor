import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pinput/pinput.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/lang_switch.dart';
import '../../../core/widgets/phone_field.dart';
import '../data/auth_repository.dart';
import '../session.dart';

enum _Step { phone, code, name }

/// Phone → SMS code → (name, for new users).
/// [from] is where to return after signing in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.from});
  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  _Step _step = _Step.phone;
  String _phone = '';
  String _name = '';
  PhoneError? _phoneError;
  String? _error;
  bool _busy = false;

  final _codeController = TextEditingController();
  int _resendIn = 0;
  Timer? _timer;

  AuthRepository get _repo => ref.read(authRepositoryProvider);
  S get _s => ref.read(stringsProvider);

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────

  Future<void> _sendCode() async {
    final err = validatePhone(_phone);
    if (err != null) return setState(() => _phoneError = err);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sent = await _repo.sendCode(_phone, ref.read(langProvider));
      _codeController.clear();
      _startTimer(sent.resendAfter);
      setState(() => _step = _Step.code);
    } catch (e) {
      setState(() => _error = errorText(e, _s));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify(String code) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _repo.verify(_phone, code);
      ref.read(sessionProvider.notifier).signedIn(result.user);
      if (result.needsName || !result.user.hasName) {
        setState(() => _step = _Step.name);
      } else {
        _finish();
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _codeController.clear();
      setState(() => _error = errorText(e, _s));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveName() async {
    final name = _name.trim();
    if (name.length < 2) return setState(() => _error = _s.nameErr);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).saveName(name);
      _finish();
    } catch (e) {
      setState(() => _error = errorText(e, _s));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finish() {
    if (!mounted) return;
    TextInput.finishAutofillContext();
    final from = widget.from;
    context.go(from != null && from.startsWith('/') ? from : '/');
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() => _resendIn = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendIn <= 1) t.cancel();
      setState(() => _resendIn = (_resendIn - 1).clamp(0, 9999));
    });
  }

  void _back() {
    switch (_step) {
      case _Step.phone:
        context.canPop() ? context.pop() : context.go('/');
      case _Step.code:
        setState(() {
          _step = _Step.phone;
          _error = null;
        });
      case _Step.name:
        // Already signed in at this point; name can be added later in profile.
        _finish();
    }
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return PopScope(
      canPop: _step == _Step.phone,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(onBack: _back),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: switch (_step) {
                        _Step.phone => _phoneStep(s),
                        _Step.code => _codeStep(s),
                        _Step.name => _nameStep(s),
                      },
                    ),
                  ),
                ),
              ),
              if (_step != _Step.code) _footer(s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phoneStep(S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(title: s.phoneTitle, sub: Text(s.phoneSub, style: _subStyle)),
        const SizedBox(height: AppSpace.s5),
        PhoneField(
          label: s.phoneLabel,
          hint: s.phoneHint,
          initialDigits: _phone,
          autofocus: true,
          error: switch (_phoneError) {
            PhoneError.length => s.errPhoneLen,
            PhoneError.operator => s.errPhoneOperator,
            null => _error,
          },
          onChanged: (v) => setState(() {
            _phone = v;
            _phoneError = null;
            _error = null;
          }),
          onSubmitted: _sendCode,
        ),
        const SizedBox(height: AppSpace.s5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface50,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined,
                  size: 20, color: AppColors.success700),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.phonePrivacy,
                  style: AppText.style(14, color: AppColors.ink700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _codeStep(S s) {
    final box = PinTheme(
      height: 60,
      textStyle: AppText.style(26, weight: FontWeight.w600, height: 1),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line300, width: 1.5),
      ),
    );

    final mm = (_resendIn ~/ 60).toString();
    final ss = (_resendIn % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(
          title: s.codeTitle,
          sub: Text.rich(
            TextSpan(
              style: _subStyle,
              children: [
                TextSpan(text: '${s.codeSentTo(formatPhone(_phone))} '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: _back,
                    child: Text(
                      s.changeNumber,
                      style: AppText.style(16,
                          weight: FontWeight.w600, color: AppColors.brand600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s5),
        LayoutBuilder(
          builder: (context, c) {
            final w = (c.maxWidth - 8 * 5) / 6;
            return Pinput(
              length: 6,
              controller: _codeController,
              autofocus: true,
              enabled: !_busy,
              separatorBuilder: (_) => const SizedBox(width: 8),
              hapticFeedbackType: HapticFeedbackType.lightImpact,
              defaultPinTheme: box.copyWith(width: w),
              focusedPinTheme: box.copyBorderWith(
                border: Border.all(color: AppColors.ink900, width: 1.5),
              ).copyWith(width: w),
              errorPinTheme: box.copyBorderWith(
                border: Border.all(color: AppColors.danger600, width: 1.5),
              ).copyWith(width: w),
              forceErrorState: _error != null,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onCompleted: _verify,
            );
          },
        ),
        const SizedBox(height: AppSpace.s3),
        if (_busy)
          Text(s.checking, style: AppText.style(14, color: AppColors.ink500))
        else if (_error != null)
          Text(_error!, style: AppText.style(14, color: AppColors.danger600)),
        const SizedBox(height: AppSpace.s2),
        SizedBox(
          height: 44,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _resendIn > 0
                ? Text(s.resendIn('$mm:$ss'),
                    style: AppText.style(15, color: AppColors.ink500))
                : TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: _busy ? null : _sendCode,
                    child: Text(s.resend),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _nameStep(S s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(title: s.nameTitle, sub: Text(s.nameSub, style: _subStyle)),
        const SizedBox(height: AppSpace.s5),
        Text(s.nameLabel, style: AppText.label),
        const SizedBox(height: AppSpace.s2),
        TextField(
          autofocus: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.givenName],
          style: AppText.bodyLg,
          decoration: InputDecoration(
            hintText: s.namePh,
            counterText: '',
            errorText: _error,
          ),
          onChanged: (v) => setState(() {
            _name = v;
            _error = null;
          }),
          onSubmitted: (_) => _saveName(),
        ),
      ],
    );
  }

  Widget _footer(S s) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + (bottom > 0 ? bottom : 8)),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_step == _Step.phone) ...[
            AppButton(
              label: s.getCode,
              busy: _busy,
              onPressed: _phone.length == 9 ? _sendCode : null,
            ),
            const SizedBox(height: 10),
            Text(
              s.terms,
              textAlign: TextAlign.center,
              style: AppText.style(13, color: AppColors.ink500),
            ),
          ] else
            AppButton(
              label: s.save,
              busy: _busy,
              onPressed: _name.trim().length >= 2 ? _saveName : null,
            ),
        ],
      ),
    );
  }

  TextStyle get _subStyle => AppText.style(16, color: AppColors.ink700);
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.only(left: 6, right: 16),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
              color: AppColors.ink900,
            ),
            Expanded(
              child: Text(
                'eKor',
                textAlign: TextAlign.center,
                style: AppText.style(20,
                    weight: FontWeight.w700, color: AppColors.brand600),
              ),
            ),
            const LangSwitch(),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.sub});
  final String title;
  final Widget sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.style(26, weight: FontWeight.w700, height: 1.2)),
        const SizedBox(height: AppSpace.s2),
        sub,
      ],
    );
  }
}
