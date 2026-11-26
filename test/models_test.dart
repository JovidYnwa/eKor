import 'dart:convert';
import 'dart:io';

import 'package:ekor/core/format.dart';
import 'package:ekor/core/l10n/strings.dart';
import 'package:ekor/features/catalog/data/category.dart';
import 'package:ekor/features/catalog/data/city.dart';
import 'package:ekor/features/masters/data/master.dart';
import 'package:ekor/features/tasks/data/task.dart';
import 'package:flutter_test/flutter_test.dart';

/// Responses saved from the live ekor.tj API (test/fixtures).
dynamic fixture(String name) =>
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync());

void main() {
  test('parses masters catalog', () {
    final j = fixture('masters') as Map<String, dynamic>;
    final items = [for (final m in j['items'] as List) MasterCard.fromJson(m)];
    expect(items, isNotEmpty);
    expect(items.first.name, isNotNull);
  });

  test('parses master profile and reviews', () {
    final p = MasterProfile.fromJson(fixture('master'));
    expect(p.card.id, 41);
    expect(p.languages, isNotEmpty);
    final reviews = fixture('master_reviews') as Map<String, dynamic>;
    for (final r in reviews['items'] as List) {
      Review.fromJson(r);
    }
  });

  test('parses feed, task detail and latest reviews', () {
    final feed = fixture('feed') as Map<String, dynamic>;
    final tasks = [for (final t in feed['items'] as List) Task.fromJson(t)];
    expect(tasks, isNotEmpty);
    final t = Task.fromJson(fixture('task'));
    expect(t.description, isNotNull);
    for (final r in fixture('reviews_latest') as List) {
      Review.fromJson(r);
    }
  });

  test('parses cities and categories', () {
    final cities = [for (final c in fixture('cities') as List) City.fromJson(c)];
    final cats = [for (final c in fixture('categories') as List) Category.fromJson(c)];
    expect(cities, isNotEmpty);
    expect(cats, isNotEmpty);
  });

  group('format', () {
    const ru = S(AppLang.ru);
    test('russian plurals', () {
      expect(ru.masters(1), '1 мастер');
      expect(ru.masters(3), '3 мастера');
      expect(ru.masters(11), '11 мастеров');
      expect(ru.masters(21), '21 мастер');
    });
    test('budget', () {
      expect(ru.budget('negotiable', null, null), 'Договорная');
      expect(ru.budget('sum', 150, 300), '150–300 сомони');
      expect(ru.budget('sum', 1500, null), '1 500 сомони');
    });
  });
}
