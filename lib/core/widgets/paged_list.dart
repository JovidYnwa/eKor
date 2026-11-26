import 'package:material_ui/material_ui.dart';

import '../models/ref.dart';

typedef PageLoader<T> = Future<Paged<T>> Function(String? cursor);

/// Holds a cursor-paginated list: first load, load more, refresh.
class PagedController<T> extends ChangeNotifier {
  PagedController(this._loader);

  PageLoader<T> _loader;
  final List<T> items = [];
  String? _cursor;
  int? total;
  bool loading = false;
  bool hasMore = true;
  Object? error;
  int _generation = 0;

  bool get isFirstLoad => items.isEmpty && loading;

  /// Replace the loader (e.g. when filters change) and reload from scratch.
  Future<void> reset(PageLoader<T> loader) {
    _loader = loader;
    return refresh();
  }

  Future<void> refresh() async {
    _generation++;
    items.clear();
    _cursor = null;
    hasMore = true;
    error = null;
    loading = false;
    await loadMore();
  }

  Future<void> loadMore() async {
    if (loading || !hasMore) return;
    final gen = _generation;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final page = await _loader(_cursor);
      if (gen != _generation) return; // a newer reset happened meanwhile
      items.addAll(page.items);
      _cursor = page.nextCursor;
      hasMore = page.hasMore;
      total = page.total ?? total;
    } catch (e) {
      if (gen != _generation) return;
      error = e;
    } finally {
      if (gen == _generation) {
        loading = false;
        notifyListeners();
      }
    }
  }
}

/// Calls [onEnd] when the user scrolls near the bottom.
class LoadMoreListener extends StatelessWidget {
  const LoadMoreListener({super.key, required this.onEnd, required this.child});
  final VoidCallback onEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical &&
            n.metrics.extentAfter < 600) {
          onEnd();
        }
        return false;
      },
      child: child,
    );
  }
}
