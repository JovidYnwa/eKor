import '../../../core/l10n/strings.dart';

/// `UserOut` from the API.
class User {
  const User({
    required this.id,
    required this.phone,
    required this.lang,
    required this.isClient,
    required this.isMaster,
    this.name,
    this.cityId,
    this.avatarUrl,
  });

  final int id;
  final String phone;
  final String? name;
  final AppLang lang;
  final int? cityId;
  final String? avatarUrl;
  final bool isClient;
  final bool isMaster;

  bool get hasName => name != null && name!.trim().isNotEmpty;

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as int,
        phone: j['phone'] as String,
        name: j['name'] as String?,
        lang: AppLang.fromCode(j['lang'] as String?),
        cityId: j['city_id'] as int?,
        avatarUrl: j['avatar_url'] as String?,
        isClient: j['is_client'] as bool? ?? true,
        isMaster: j['is_master'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'name': name,
        'lang': lang.code,
        'city_id': cityId,
        'avatar_url': avatarUrl,
        'is_client': isClient,
        'is_master': isMaster,
      };
}
