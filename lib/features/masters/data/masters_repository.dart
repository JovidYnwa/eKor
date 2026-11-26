import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/ref.dart';
import '../../../core/network/api_client.dart';
import 'master.dart';

final mastersRepositoryProvider =
    Provider((ref) => MastersRepository(ref.watch(apiClientProvider)));

class MastersRepository {
  MastersRepository(this._api);
  final ApiClient _api;

  Future<Paged<MasterCard>> catalog({
    required MasterFilters filters,
    int? cityId,
    String? cursor,
    int limit = 20,
  }) async {
    final j = await _api.get<Map<String, dynamic>>('/masters', query: {
      'city_id': cityId,
      'category_id': filters.categoryId,
      'q': filters.q.trim().isEmpty ? null : filters.q.trim(),
      'available': filters.available ? true : null,
      'rating_min': filters.rating4 ? 4 : null,
      'sort': filters.sort,
      'cursor': cursor,
      'limit': limit,
    });
    return Paged(
      items: [
        for (final m in j['items'] as List)
          MasterCard.fromJson(m as Map<String, dynamic>),
      ],
      nextCursor: j['next_cursor'] as String?,
      total: j['total'] as int?,
    );
  }

  Future<MasterProfile> profile(int id) async =>
      MasterProfile.fromJson(await _api.get<Map<String, dynamic>>('/masters/$id'));

  Future<Paged<Review>> reviews(int masterId, {String? cursor}) async {
    final j = await _api.get<Map<String, dynamic>>(
      '/masters/$masterId/reviews',
      query: {'cursor': cursor, 'limit': 20},
    );
    return Paged(
      items: [
        for (final r in j['items'] as List) Review.fromJson(r as Map<String, dynamic>),
      ],
      nextCursor: j['next_cursor'] as String?,
      total: j['reviews_count'] as int?,
    );
  }

  Future<List<Review>> latestReviews({int? cityId, int limit = 5}) async {
    final data = await _api.get<List<dynamic>>(
      '/reviews/latest',
      query: {'city_id': cityId, 'limit': limit},
    );
    return [for (final r in data) Review.fromJson(r as Map<String, dynamic>)];
  }

  /// Requires login. Only works if the master allowed showing the phone.
  Future<String> revealPhone(int masterId) async {
    final j = await _api.post<Map<String, dynamic>>('/masters/$masterId/phone');
    return j['phone'] as String;
  }
}

final masterProfileProvider = FutureProvider.autoDispose
    .family<MasterProfile, int>((ref, id) => ref.watch(mastersRepositoryProvider).profile(id));

final masterReviewsProvider = FutureProvider.autoDispose
    .family<Paged<Review>, int>((ref, id) => ref.watch(mastersRepositoryProvider).reviews(id));
