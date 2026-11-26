import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'data/auth_repository.dart';
import 'data/user.dart';

/// The signed-in user, or `null` for guests.
///
/// Browsing (home, masters, categories) works without an account, like on the
/// website. Posting a task and "my tasks" require signing in.
final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, User?>(SessionNotifier.new);

class SessionNotifier extends AsyncNotifier<User?> {
  static const _cacheKey = 'session_user';

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<User?> build() async {
    ref.read(apiClientProvider).onSessionExpired = _expire;

    if (!await _repo.hasSession()) return null;
    try {
      final user = await _repo.fetchMe();
      _cache(user);
      return user;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        _cache(null);
        return null;
      }
      // Offline or server down: stay signed in with the last known profile.
      return _cached();
    }
  }

  /// Called after a successful OTP verification.
  void signedIn(User user) {
    _cache(user);
    state = AsyncData(user);
    _syncLang(user);
  }

  Future<void> saveName(String name) async {
    final user = await _repo.updateMe(name: name);
    _cache(user);
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await _repo.logout();
    _cache(null);
    state = const AsyncData(null);
  }

  void _expire() {
    _cache(null);
    state = const AsyncData(null);
  }

  /// The app language wins: if the user switched it before logging in,
  /// tell the server so SMS and notifications come in that language.
  void _syncLang(User user) {
    final appLang = ref.read(langProvider);
    if (user.lang != appLang) {
      _repo.updateMe(lang: appLang).ignore();
    }
  }

  void _cache(User? user) {
    final prefs = ref.read(sharedPrefsProvider);
    if (user == null) {
      prefs.remove(_cacheKey);
    } else {
      prefs.setString(_cacheKey, jsonEncode(user.toJson()));
    }
  }

  User? _cached() {
    final raw = ref.read(sharedPrefsProvider).getString(_cacheKey);
    if (raw == null) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
