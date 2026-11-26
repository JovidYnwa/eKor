/// `Ref` / `NamedRef` from the API: an id with Russian and Tajik names.
class NamedRef {
  const NamedRef({required this.id, required this.nameRu, required this.nameTj});

  final int id;
  final String nameRu;
  final String nameTj;

  factory NamedRef.fromJson(Map<String, dynamic> j) => NamedRef(
        id: j['id'] as int,
        nameRu: j['name_ru'] as String,
        nameTj: (j['name_tj'] as String?) ?? j['name_ru'] as String,
      );

  static NamedRef? maybe(Object? j) =>
      j == null ? null : NamedRef.fromJson(j as Map<String, dynamic>);
}

/// Cursor-paginated list page.
class Paged<T> {
  const Paged({required this.items, this.nextCursor, this.total});
  final List<T> items;
  final String? nextCursor;
  final int? total;

  bool get hasMore => nextCursor != null;
}

DateTime? parseDate(Object? v) =>
    v == null ? null : DateTime.tryParse(v as String)?.toLocal();
