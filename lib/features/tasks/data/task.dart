import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/ref.dart';
import '../../../core/network/api_client.dart';

class TaskPhoto {
  const TaskPhoto({required this.url, required this.width, required this.height});
  final String url;
  final int width;
  final int height;

  factory TaskPhoto.fromJson(Map<String, dynamic> j) => TaskPhoto(
        url: j['url'] as String,
        width: j['width'] as int? ?? 1,
        height: j['height'] as int? ?? 1,
      );
}

/// `TaskCardOut` (list) and `TaskOwnOut` / `TaskPublicOut` (detail).
/// Detail-only fields are null in list items.
class Task {
  const Task({
    required this.id,
    required this.status,
    required this.title,
    required this.category,
    required this.when,
    required this.budgetMode,
    required this.photosCount,
    required this.responsesCount,
    required this.viewsCount,
    this.subcategory,
    this.city,
    this.district,
    this.date,
    this.timeOfDay,
    this.budgetMin,
    this.budgetMax,
    this.coverUrl,
    this.publishedAt,
    this.description,
    this.photos = const [],
    this.clientName,
    this.clientSinceYear,
    this.address,
    this.rejectComment,
    this.expiresAt,
  });

  final int id;
  final String status;
  final String title;
  final NamedRef category;
  final NamedRef? subcategory;
  final NamedRef? city;
  final NamedRef? district;
  final String when;
  final DateTime? date;
  final String? timeOfDay;
  final String budgetMode;
  final int? budgetMin;
  final int? budgetMax;
  final int photosCount;
  final String? coverUrl;
  final int responsesCount;
  final int viewsCount;
  final DateTime? publishedAt;

  // Detail fields
  final String? description;
  final List<TaskPhoto> photos;
  final String? clientName;
  final int? clientSinceYear;
  final String? address;
  final String? rejectComment;
  final DateTime? expiresAt;

  factory Task.fromJson(Map<String, dynamic> j) {
    final client = j['client'] as Map<String, dynamic>?;
    return Task(
      id: j['id'] as int,
      status: j['status'] as String,
      title: j['title'] as String,
      category: NamedRef.fromJson(j['category'] as Map<String, dynamic>),
      subcategory: NamedRef.maybe(j['subcategory']),
      city: NamedRef.maybe(j['city']),
      district: NamedRef.maybe(j['district']),
      when: j['when'] as String? ?? 'flexible',
      date: parseDate(j['date']),
      timeOfDay: j['time_of_day'] as String?,
      budgetMode: j['budget_mode'] as String? ?? 'negotiable',
      budgetMin: j['budget_min'] as int?,
      budgetMax: j['budget_max'] as int?,
      photosCount: j['photos_count'] as int? ?? 0,
      coverUrl: j['cover_url'] as String?,
      responsesCount: j['responses_count'] as int? ?? 0,
      viewsCount: j['views_count'] as int? ?? 0,
      publishedAt: parseDate(j['published_at']),
      description: j['description'] as String?,
      photos: [
        for (final p in j['photos'] as List? ?? const [])
          TaskPhoto.fromJson(p as Map<String, dynamic>),
      ],
      clientName: client?['name'] as String?,
      clientSinceYear: client?['member_since_year'] as int?,
      address: j['address'] as String?,
      rejectComment: j['reject_comment'] as String?,
      expiresAt: parseDate(j['expires_at']),
    );
  }
}

final tasksRepositoryProvider =
    Provider((ref) => TasksRepository(ref.watch(apiClientProvider)));

class TasksRepository {
  TasksRepository(this._api);
  final ApiClient _api;

  /// Public feed of open tasks (guests can see it too).
  Future<Paged<Task>> feed({int? cityId, int? categoryId, String? cursor, int limit = 20}) async {
    final j = await _api.get<Map<String, dynamic>>('/feed', query: {
      'city_id': cityId,
      'category_id': categoryId,
      'cursor': cursor,
      'limit': limit,
    });
    return _page(j);
  }

  /// "My tasks" — `tab` is `active` or `archive`. Requires login.
  Future<Paged<Task>> mine({required String tab, String? cursor}) async {
    final j = await _api.get<Map<String, dynamic>>('/me/tasks', query: {
      'tab': tab,
      'cursor': cursor,
      'limit': 20,
    });
    return _page(j);
  }

  Future<Task> get(int id) async =>
      Task.fromJson(await _api.get<Map<String, dynamic>>('/tasks/$id'));

  Paged<Task> _page(Map<String, dynamic> j) => Paged(
        items: [for (final t in j['items'] as List) Task.fromJson(t as Map<String, dynamic>)],
        nextCursor: j['next_cursor'] as String?,
        total: j['total'] as int?,
      );
}

final taskDetailProvider = FutureProvider.autoDispose
    .family<Task, int>((ref, id) => ref.watch(tasksRepositoryProvider).get(id));
