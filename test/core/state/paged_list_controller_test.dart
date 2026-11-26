import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/core/state/paged_list_controller.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';

import '../../support/fixtures/page_fixture.dart';

typedef _Pending = ({
  String query,
  int page,
  Completer<Result<Page<String>>> c,
});

class _Harness {
  _Harness({Duration debounce = Duration.zero}) {
    controller = PagedListController<String, String>(
      initialQuery: 'a',
      debounce: debounce,
      fetch: (query, page) {
        final completer = Completer<Result<Page<String>>>();
        pending.add((query: query, page: page, c: completer));
        return completer.future;
      },
      onFailure: (failure, {required loadingMore}) =>
          failures.add((failure, loadingMore)),
    );
  }

  late final PagedListController<String, String> controller;
  final pending = <_Pending>[];
  final failures = <(AppFailure, bool)>[];
}

Result<Page<String>> _ok(
  List<String> items, {
  int number = 0,
  bool last = true,
}) => Ok(makePage(items, number: number, last: last));

void main() {
  group('PagedListController', () {
    test('loads the first page of the initial query', () async {
      final h = _Harness();

      expect(h.controller.isLoading, isTrue);
      expect(h.pending.single.query, 'a');
      expect(h.pending.single.page, 0);

      h.pending[0].c.complete(_ok(['x'], last: false));
      await Future<void>.delayed(Duration.zero);

      expect(h.controller.items, ['x']);
      expect(h.controller.isLoading, isFalse);
      expect(h.controller.hasMore, isTrue);
    });

    test('discards an old response that arrives after the new one', () async {
      final h = _Harness();

      final second = h.controller.updateQuery('b');
      expect(h.pending.map((p) => p.query), ['a', 'b']);

      h.pending[1].c.complete(_ok(['novo']));
      await second;
      expect(h.controller.items, ['novo']);

      // The first request answers late and must not overwrite the state.
      h.pending[0].c.complete(_ok(['antigo']));
      await Future<void>.delayed(Duration.zero);

      expect(h.controller.items, ['novo']);
      expect(h.controller.isLoading, isFalse);
    });

    test('discards an old error that arrives after the new response', () async {
      final h = _Harness();

      final second = h.controller.updateQuery('b');
      h.pending[1].c.complete(_ok(['novo']));
      await second;

      h.pending[0].c.complete(const Err(NetworkFailure()));
      await Future<void>.delayed(Duration.zero);

      expect(h.controller.items, ['novo']);
      expect(h.failures, isEmpty);
    });

    test(
      'loadMore in flight from an old query is dropped by a new query',
      () async {
        final h = _Harness();
        h.pending[0].c.complete(_ok(['p0'], last: false));
        await Future<void>.delayed(Duration.zero);

        final loadMore = h.controller.loadMore();
        expect(h.controller.isLoadingMore, isTrue);
        expect(h.pending[1].page, 1);

        final reload = h.controller.updateQuery('b');
        expect(h.controller.isLoadingMore, isFalse);
        h.pending[2].c.complete(_ok(['novo']));
        await reload;

        h.pending[1].c.complete(_ok(['pagina-velha'], number: 1));
        await loadMore;

        expect(h.controller.items, ['novo']);
      },
    );

    test('loadMore appends the next page and stops on the last one', () async {
      final h = _Harness();
      h.pending[0].c.complete(_ok(['p0'], last: false));
      await Future<void>.delayed(Duration.zero);

      final loadMore = h.controller.loadMore();
      h.pending[1].c.complete(_ok(['p1'], number: 1));
      await loadMore;

      expect(h.controller.items, ['p0', 'p1']);
      expect(h.controller.hasMore, isFalse);
      await h.controller.loadMore();
      expect(h.pending, hasLength(2));
    });

    test('failed loadMore blocks further loads until retry', () async {
      final h = _Harness();
      h.pending[0].c.complete(_ok(['p0'], last: false));
      await Future<void>.delayed(Duration.zero);

      final failing = h.controller.loadMore();
      h.pending[1].c.complete(const Err(NetworkFailure()));
      await failing;

      expect(h.controller.loadMoreFailed, isTrue);
      expect(h.failures.single.$2, isTrue);
      await h.controller.loadMore();
      expect(h.pending, hasLength(2));

      final retry = h.controller.retryLoadMore();
      expect(h.pending[2].page, 1);
      h.pending[2].c.complete(_ok(['p1'], number: 1));
      await retry;

      expect(h.controller.items, ['p0', 'p1']);
      expect(h.controller.loadMoreFailed, isFalse);
    });

    test('failed first page clears items and totals', () async {
      final h = _Harness();
      h.pending[0].c.complete(_ok(['p0'], last: false));
      await Future<void>.delayed(Duration.zero);

      final reload = h.controller.reload();
      h.pending[1].c.complete(const Err(NetworkFailure()));
      await reload;

      expect(h.controller.items, isEmpty);
      expect(h.controller.totalElements, 0);
      expect(h.controller.hasMore, isFalse);
      expect(h.controller.isLoading, isFalse);
      expect(h.failures.single.$2, isFalse);
    });

    test('debounce lets only the newest query reach the fetcher', () async {
      final h = _Harness(debounce: const Duration(milliseconds: 10));

      unawaited(h.controller.updateQuery('b'));
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(h.pending.map((p) => p.query), ['b']);
    });
  });
}
