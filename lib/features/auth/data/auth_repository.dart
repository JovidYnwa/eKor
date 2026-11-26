import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import 'user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);

class OtpSent {
  const OtpSent({required this.expiresIn, required this.resendAfter});
  final int expiresIn;
  final int resendAfter;
}

class VerifyResult {
  const VerifyResult({required this.user, required this.needsName});
  final User user;
  final bool needsName;
}

/// Tajik mobile operator prefixes accepted by the website's validation.
const tjOperatorPrefixes = {
  '00', '01', '10', '11', '12', '20', '50', '55', '70', //
  '77', '88', '90', '91', '92', '93', '94', '98', '99',
};

enum PhoneError { length, operator }

/// Validates the 9 local digits (without +992).
PhoneError? validatePhone(String digits) {
  if (digits.length < 9) return PhoneError.length;
  if (!tjOperatorPrefixes.contains(digits.substring(0, 2))) {
    return PhoneError.operator;
  }
  return null;
}

/// Formats 9 digits as `93 512 44 07`.
String formatPhone(String digits) {
  final d = digits.replaceAll(RegExp(r'\D'), '');
  final parts = <String>[];
  const groups = [2, 3, 2, 2];
  var i = 0;
  for (final g in groups) {
    if (i >= d.length) break;
    final end = (i + g).clamp(0, d.length);
    parts.add(d.substring(i, end));
    i = end;
  }
  return parts.join(' ');
}

class AuthRepository {
  AuthRepository(this._api, this._storage);
  final ApiClient _api;
  final TokenStorage _storage;

  static String _e164(String digits) => '+992$digits';

  Future<OtpSent> sendCode(String digits, AppLang lang) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/otp/send',
      body: {'phone': _e164(digits), 'lang': lang.code},
    );
    return OtpSent(
      expiresIn: res['expires_in'] as int,
      resendAfter: res['resend_after'] as int,
    );
  }

  Future<VerifyResult> verify(String digits, String code) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/otp/verify',
      body: {'phone': _e164(digits), 'code': code},
    );
    await _storage.save(AuthTokens(
      access: res['access_token'] as String,
      refresh: res['refresh_token'] as String,
    ));
    return VerifyResult(
      user: User.fromJson(res['user'] as Map<String, dynamic>),
      needsName: res['needs_name'] as bool? ?? false,
    );
  }

  Future<bool> hasSession() async => await _storage.read() != null;

  Future<User> fetchMe() async =>
      User.fromJson(await _api.get<Map<String, dynamic>>('/me'));

  Future<User> updateMe({String? name, AppLang? lang, int? cityId}) async {
    final body = <String, dynamic>{
      'name': ?name,
      'lang': ?lang?.code,
      'city_id': ?cityId,
    };
    return User.fromJson(await _api.patch<Map<String, dynamic>>('/me', body: body));
  }

  Future<void> logout() async {
    final tokens = await _storage.read();
    await _storage.clear();
    if (tokens == null) return;
    try {
      await _api.post<void>(
        '/auth/logout',
        body: {'refresh_token': tokens.refresh},
      );
    } catch (_) {
      // Local logout already happened; server-side revoke is best effort.
    }
  }
}
