import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/auth/data/auth_repository.dart';
import '../theme/tokens.dart';

/// `+992 | 93 512 44 07` phone input (`Field_phone` on the web).
/// [onChanged] receives only the digits (max 9).
class PhoneField extends StatefulWidget {
  const PhoneField({
    super.key,
    required this.label,
    required this.onChanged,
    this.initialDigits = '',
    this.hint,
    this.error,
    this.onSubmitted,
    this.autofocus = false,
  });

  final String label;
  final String initialDigits;
  final String? hint;
  final String? error;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;
  final bool autofocus;

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late final _controller =
      TextEditingController(text: formatPhone(widget.initialDigits));
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    final borderColor = hasError
        ? AppColors.danger600
        : _focus.hasFocus
            ? AppColors.ink900
            : AppColors.line300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: AppText.label),
        const SizedBox(height: AppSpace.s2),
        GestureDetector(
          onTap: _focus.requestFocus,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: AppSizes.inputHLg,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                Text('+992', style: AppText.style(18, weight: FontWeight.w600)),
                const SizedBox(width: 10),
                Container(width: 1, height: 24, color: AppColors.line200),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: widget.autofocus,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
                    inputFormatters: [_TjPhoneFormatter()],
                    style: AppText.style(
                      18,
                      weight: FontWeight.w600,
                      letterSpacing: 0.7,
                    ),
                    cursorColor: AppColors.brand600,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '93 512 44 07',
                      hintStyle: AppText.style(
                        18,
                        weight: FontWeight.w600,
                        letterSpacing: 0.7,
                        color: AppColors.line300,
                      ),
                    ),
                    onChanged: (v) =>
                        widget.onChanged(v.replaceAll(RegExp(r'\D'), '')),
                    onSubmitted: (_) => widget.onSubmitted?.call(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s2),
        if (hasError)
          Text(widget.error!,
              style: AppText.style(13, height: 1.4, color: AppColors.danger600))
        else if (widget.hint != null)
          Text(widget.hint!, style: AppText.caption.copyWith(color: AppColors.ink500)),
      ],
    );
  }
}

/// Keeps max 9 digits and formats them as `93 512 44 07`.
/// Also accepts pasted numbers like `+992 93 512 44 07` / `992935124407`.
class _TjPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 9 && digits.startsWith('992')) {
      digits = digits.substring(3);
    }
    if (digits.length > 9) digits = digits.substring(0, 9);
    final text = formatPhone(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
