import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_client.dart';

class Subcategory {
  const Subcategory({
    required this.id,
    required this.key,
    required this.nameRu,
    required this.nameTj,
    required this.mastersCount,
  });

  final int id;
  final String key;
  final String nameRu;
  final String nameTj;
  final int mastersCount;

  factory Subcategory.fromJson(Map<String, dynamic> j) => Subcategory(
        id: j['id'] as int,
        key: j['key'] as String,
        nameRu: j['name_ru'] as String,
        nameTj: j['name_tj'] as String,
        mastersCount: j['masters_count'] as int? ?? 0,
      );
}

/// `CategoryOut` from the API.
class Category {
  const Category({
    required this.id,
    required this.key,
    required this.nameRu,
    required this.nameTj,
    required this.icon,
    required this.photoRequired,
    required this.pricePerHour,
    required this.isOther,
    required this.mastersCount,
    required this.children,
    this.typicalPriceFrom,
  });

  final int id;
  final String key;
  final String nameRu;
  final String nameTj;
  final String? icon;
  final bool photoRequired;
  final bool pricePerHour;
  final int? typicalPriceFrom;
  final bool isOther;
  final int mastersCount;
  final List<Subcategory> children;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as int,
        key: j['key'] as String,
        nameRu: j['name_ru'] as String,
        nameTj: j['name_tj'] as String,
        icon: j['icon'] as String?,
        photoRequired: j['photo_required'] as bool? ?? false,
        pricePerHour: j['price_per_hour'] as bool? ?? false,
        typicalPriceFrom: j['typical_price_from'] as int?,
        isOther: j['is_other'] as bool? ?? false,
        mastersCount: j['masters_count'] as int? ?? 0,
        children: [
          for (final c in (j['children'] as List? ?? const []))
            Subcategory.fromJson(c as Map<String, dynamic>),
        ],
      );

  /// Maps the Lucide icon name sent by the API to the Flutter icon.
  IconData get iconData => _icons[icon] ?? LucideIcons.wrench;

  static const _icons = <String, IconData>{
    'PaintRoller': LucideIcons.paintRoller,
    'HardHat': LucideIcons.hardHat,
    'WashingMachine': LucideIcons.washingMachine,
    'Truck': LucideIcons.truck,
    'GraduationCap': LucideIcons.graduationCap,
    'Scissors': LucideIcons.scissors,
    'PartyPopper': LucideIcons.partyPopper,
    'Laptop': LucideIcons.laptop,
    'Sparkles': LucideIcons.sparkles,
    'CircleEllipsis': LucideIcons.circleEllipsis,
  };
}

/// Category tree, cached for the app session.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get<List<dynamic>>('/categories');
  return [for (final c in data) Category.fromJson(c as Map<String, dynamic>)];
});
