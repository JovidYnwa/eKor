import '../../../core/models/ref.dart';

/// `MasterCardOut` — a master in the catalog list.
class MasterCard {
  const MasterCard({
    required this.id,
    required this.reviewsCount,
    required this.completedOrders,
    required this.verified,
    required this.availableToday,
    this.name,
    this.avatarUrl,
    this.headline,
    this.city,
    this.district,
    this.ratingAvg,
    this.priceFrom,
    this.experience,
  });

  final int id;
  final String? name;
  final String? avatarUrl;
  final NamedRef? headline;
  final NamedRef? city;
  final NamedRef? district;
  final double? ratingAvg;
  final int reviewsCount;
  final int completedOrders;
  final bool verified;
  final bool availableToday;
  final int? priceFrom;
  final String? experience;

  factory MasterCard.fromJson(Map<String, dynamic> j) => MasterCard(
        id: j['id'] as int,
        name: j['name'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        headline: NamedRef.maybe(j['headline']),
        city: NamedRef.maybe(j['city']),
        district: NamedRef.maybe(j['district']),
        ratingAvg: (j['rating_avg'] as num?)?.toDouble(),
        reviewsCount: j['reviews_count'] as int? ?? 0,
        completedOrders: j['completed_orders_count'] as int? ?? 0,
        verified: j['verified'] as bool? ?? false,
        availableToday: j['available_today'] as bool? ?? false,
        priceFrom: j['price_from'] as int?,
        experience: j['experience'] as String?,
      );
}

class Profession {
  const Profession({
    required this.nameRu,
    required this.nameTj,
    required this.negotiable,
    this.priceFrom,
  });

  final String nameRu;
  final String nameTj;
  final int? priceFrom;
  final bool negotiable;

  factory Profession.fromJson(Map<String, dynamic> j) => Profession(
        nameRu: j['name_ru'] as String,
        nameTj: j['name_tj'] as String,
        priceFrom: j['price_from'] as int?,
        negotiable: j['negotiable'] as bool? ?? false,
      );
}

class Service {
  const Service({required this.title, this.price});
  final String title;
  final int? price;

  factory Service.fromJson(Map<String, dynamic> j) =>
      Service(title: j['title'] as String, price: j['price'] as int?);
}

class PortfolioItem {
  const PortfolioItem({
    required this.url,
    required this.width,
    required this.height,
    this.caption,
  });

  final String url;
  final int width;
  final int height;
  final String? caption;

  factory PortfolioItem.fromJson(Map<String, dynamic> j) => PortfolioItem(
        url: j['url'] as String,
        width: j['width'] as int? ?? 1,
        height: j['height'] as int? ?? 1,
        caption: j['caption'] as String?,
      );
}

/// `MasterPublicOut` — full public profile.
class MasterProfile {
  const MasterProfile({
    required this.card,
    required this.professions,
    required this.services,
    required this.portfolio,
    required this.districts,
    required this.languages,
    required this.hasPhone,
    this.about,
    this.memberSince,
  });

  final MasterCard card;
  final String? about;
  final List<Profession> professions;
  final List<Service> services;
  final List<PortfolioItem> portfolio;
  final List<NamedRef> districts;
  final List<String> languages;
  final bool hasPhone;
  final DateTime? memberSince;

  factory MasterProfile.fromJson(Map<String, dynamic> j) => MasterProfile(
        card: MasterCard.fromJson(j),
        about: j['about'] as String?,
        professions: [
          for (final p in j['professions'] as List? ?? const [])
            Profession.fromJson(p as Map<String, dynamic>),
        ],
        services: [
          for (final s in j['services'] as List? ?? const [])
            Service.fromJson(s as Map<String, dynamic>),
        ],
        portfolio: [
          for (final p in j['portfolio'] as List? ?? const [])
            PortfolioItem.fromJson(p as Map<String, dynamic>),
        ],
        districts: [
          for (final d in j['districts'] as List? ?? const [])
            NamedRef.fromJson(d as Map<String, dynamic>),
        ],
        languages: [for (final l in j['languages'] as List? ?? const []) l as String],
        hasPhone: j['has_phone'] as bool? ?? false,
        memberSince: parseDate(j['member_since']),
      );
}

/// `ReviewOut` / `LatestReviewOut`.
class Review {
  const Review({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.text,
    required this.taskTitle,
    this.createdAt,
    this.replyText,
    this.masterId,
    this.masterName,
    this.masterHeadlineRu,
    this.masterHeadlineTj,
  });

  final int id;
  final String authorName;
  final int rating;
  final String text;
  final String taskTitle;
  final DateTime? createdAt;
  final String? replyText;
  final int? masterId;
  final String? masterName;
  final String? masterHeadlineRu;
  final String? masterHeadlineTj;

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'] as int,
        authorName: j['author_name'] as String? ?? '',
        rating: j['rating'] as int? ?? 0,
        text: j['text'] as String? ?? '',
        taskTitle: j['task_title'] as String? ?? '',
        createdAt: parseDate(j['created_at']),
        replyText: j['reply_text'] as String?,
        masterId: j['master_id'] as int?,
        masterName: j['master_name'] as String?,
        masterHeadlineRu: j['master_headline_ru'] as String?,
        masterHeadlineTj: j['master_headline_tj'] as String?,
      );
}

/// Catalog filters (query of `GET /masters`).
class MasterFilters {
  const MasterFilters({
    this.q = '',
    this.categoryId,
    this.available = false,
    this.rating4 = false,
    this.sort = 'rel',
  });

  final String q;
  final int? categoryId;
  final bool available;
  final bool rating4;
  final String sort;

  bool get isDefault =>
      q.isEmpty && categoryId == null && !available && !rating4 && sort == 'rel';

  MasterFilters copyWith({
    String? q,
    int? Function()? categoryId,
    bool? available,
    bool? rating4,
    String? sort,
  }) =>
      MasterFilters(
        q: q ?? this.q,
        categoryId: categoryId != null ? categoryId() : this.categoryId,
        available: available ?? this.available,
        rating4: rating4 ?? this.rating4,
        sort: sort ?? this.sort,
      );

  @override
  bool operator ==(Object other) =>
      other is MasterFilters &&
      other.q == q &&
      other.categoryId == categoryId &&
      other.available == available &&
      other.rating4 == rating4 &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(q, categoryId, available, rating4, sort);
}
