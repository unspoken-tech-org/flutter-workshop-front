import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';

void main() {
  group('Page.fromJson', () {
    test('decodes compact PageResponse without legacy Spring Page fields', () {
      final page = Page<String>.fromJson({
        'content': ['a', 'b'],
        'number': 0,
        'size': 15,
        'totalElements': 2,
        'totalPages': 1,
        'last': true,
      }, (item) => item as String);

      expect(page.content, ['a', 'b']);
      expect(page.number, 0);
      expect(page.size, 15);
      expect(page.totalElements, 2);
      expect(page.totalPages, 1);
      expect(page.last, isTrue);
      expect(page.numberOfElements, 2);
      expect(page.first, isTrue);
      expect(page.empty, isFalse);
    });

    test('computes first=false and empty=true on subsequent empty page', () {
      final page = Page<String>.fromJson({
        'content': <String>[],
        'number': 1,
        'size': 15,
        'totalElements': 0,
        'totalPages': 0,
        'last': true,
      }, (item) => item as String);

      expect(page.numberOfElements, 0);
      expect(page.first, isFalse);
      expect(page.empty, isTrue);
    });

    test('preserves explicit legacy Spring Page fields when provided', () {
      final page = Page<int>.fromJson({
        'content': [10],
        'number': 1,
        'size': 15,
        'totalElements': 16,
        'totalPages': 2,
        'last': true,
        'numberOfElements': 1,
        'first': false,
        'empty': false,
      }, (item) => item as int);

      expect(page.content, [10]);
      expect(page.numberOfElements, 1);
      expect(page.first, isFalse);
      expect(page.empty, isFalse);
    });
  });
}
