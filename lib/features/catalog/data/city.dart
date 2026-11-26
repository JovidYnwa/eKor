import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/network/api_client.dart';

class City {
  const City({
    required this.id,
    required this.key,
    required this.nameRu,
    required this.nameTj,
    required this.regionRu,
    required this.regionTj,
    required this.mastersCount,
  });

  final int id;
  final String key;
  final String nameRu;
  final String nameTj;
  final String regionRu;
  final String regionTj;
  final int mastersCount;

  factory City.fromJson(Map<String, dynamic> j) {
    final region = j['region'] as Map<String, dynamic>?;
    return City(
      id: j['id'] as int,
      key: j['key'] as String,
      nameRu: j['name_ru'] as String,
      nameTj: j['name_tj'] as String,
      regionRu: region?['name_ru'] as String? ?? '',
      regionTj: region?['name_tj'] as String? ?? '',
      mastersCount: j['masters_count'] as int? ?? 0,
    );
  }
}

final citiesProvider = FutureProvider<List<City>>((ref) async {
  final data = await ref.watch(apiClientProvider).get<List<dynamic>>('/cities');
  return [for (final c in data) City.fromJson(c as Map<String, dynamic>)];
});

/// The city the user browses in. `null` = all of Tajikistan.
/// Remembered between launches, like on the website.
class SelectedCityNotifier extends Notifier<int?> {
  static const _key = 'city_id';

  @override
  int? build() => ref.read(sharedPrefsProvider).getInt(_key);

  void set(int? cityId) {
    state = cityId;
    final prefs = ref.read(sharedPrefsProvider);
    cityId == null ? prefs.remove(_key) : prefs.setInt(_key, cityId);
  }
}

final selectedCityProvider =
    NotifierProvider<SelectedCityNotifier, int?>(SelectedCityNotifier.new);

/// The selected [City] object, once cities are loaded.
final selectedCityObjProvider = Provider<City?>((ref) {
  final id = ref.watch(selectedCityProvider);
  if (id == null) return null;
  final cities = ref.watch(citiesProvider).value ?? const [];
  for (final c in cities) {
    if (c.id == id) return c;
  }
  return null;
});
