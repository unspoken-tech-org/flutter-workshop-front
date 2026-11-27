import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/core/state/safe_change_notifier_mixin.dart';
import 'package:flutter_workshop_front/core/ui/ui_message.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';

/// Loads one page of [T] for the query [Q] (0-based [page]).
typedef PageFetcher<T, Q> = Future<Result<Page<T>>> Function(Q query, int page);

/// Text shown to the user when a page fails; [loadingMore] is true for pages
/// after the first.
typedef PageFailureMessage =
    String Function(AppFailure failure, {required bool loadingMore});

/// Paginated list state shared by listing screens.
///
/// Every reload and every query change starts a new "generation"; a response
/// that arrives after a newer request was issued is discarded, so a slow old
/// request can never overwrite the state of the new one. The first page is
/// requested by the constructor. A failed page is published as a [UiError]
/// ([UiMessageSource]); the screen shows it with `UiMessageListener`.
class PagedListController<T, Q> extends ChangeNotifier
    with SafeChangeNotifierMixin, UiMessageSource {
  PagedListController({
    required Q initialQuery,
    required PageFetcher<T, Q> fetch,
    required PageFailureMessage failureMessage,
    Duration debounce = Duration.zero,
  }) : _query = initialQuery,
       _fetch = fetch,
       _failureMessage = failureMessage,
       _debounce = debounce {
    unawaited(reload());
  }

  final PageFetcher<T, Q> _fetch;
  final PageFailureMessage _failureMessage;
  final Duration _debounce;

  Q _query;
  Q get query => _query;

  List<T> _items = [];
  List<T> get items => _items;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  bool _loadMoreFailed = false;
  bool get loadMoreFailed => _loadMoreFailed;

  int _page = 0;
  int _totalElements = 0;
  int get totalElements => _totalElements;
  int _totalPages = 0;
  int get totalPages => _totalPages;

  int _generation = 0;

  /// Replaces the query and reloads the first page.
  Future<void> updateQuery(Q query) {
    _query = query;
    return reload();
  }

  /// Reloads the first page of the current query.
  Future<void> reload() async {
    final generation = ++_generation;
    try {
      _isLoading = true;
      _isLoadingMore = false;
      _loadMoreFailed = false;
      _page = 0;
      _items = [];
      notifyListeners();
      if (_debounce > Duration.zero) {
        await Future<void>.delayed(_debounce);
        if (generation != _generation) return;
      }
      final result = await _fetch(_query, 0);
      if (generation != _generation) return;
      switch (result) {
        case Ok(:final value):
          _items = List.of(value.content);
          _totalElements = value.totalElements;
          _totalPages = value.totalPages;
          _hasMore = !value.last;
        case Err(:final failure):
          _totalElements = 0;
          _totalPages = 0;
          _hasMore = false;
          if (!failure.shownGlobally) {
            emitError(_failureMessage(failure, loadingMore: false));
          }
      }
    } finally {
      if (generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore || _loadMoreFailed) return;

    final generation = _generation;
    final nextPage = _page + 1;
    try {
      _isLoadingMore = true;
      notifyListeners();

      final result = await _fetch(_query, nextPage);
      if (generation != _generation) return;
      switch (result) {
        case Ok(:final value):
          _page = nextPage;
          _items = [..._items, ...value.content];
          _totalElements = value.totalElements;
          _totalPages = value.totalPages;
          _hasMore = !value.last;
        case Err(:final failure):
          _loadMoreFailed = true;
          if (!failure.shownGlobally) {
            emitError(_failureMessage(failure, loadingMore: true));
          }
      }
    } finally {
      if (generation == _generation) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> retryLoadMore() {
    _loadMoreFailed = false;
    notifyListeners();
    return loadMore();
  }
}
