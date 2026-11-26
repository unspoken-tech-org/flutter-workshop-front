import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/device/device_query.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

void main() {
  group('DeviceQuery.withSearchText', () {
    test('keeps spaces and accents in free text', () {
      final query = const DeviceQuery().withSearchText('  José   Antônio  ');

      expect(query.searchQuery, 'José Antônio');
    });

    test('classifies CPF, phone and id and strips masks', () {
      expect(
        const DeviceQuery().withSearchText('529.982.247-25').customerCpf,
        '52998224725',
      );
      expect(
        const DeviceQuery().withSearchText('(11) 3333-4444').customerPhone,
        '1133334444',
      );
      expect(const DeviceQuery().withSearchText('  77  ').deviceId, 77);
    });

    test('replaces the previous search and blank text clears it', () {
      final byId = const DeviceQuery().withSearchText('77');
      final byName = byId.withSearchText('Maria');

      expect(byName.deviceId, isNull);
      expect(byName.searchQuery, 'Maria');
      expect(byName.withSearchText('   ').searchQuery, isNull);
    });
  });

  group('DeviceQuery immutability', () {
    test('toggling returns a new query and leaves the original untouched', () {
      const original = DeviceQuery();
      final toggled = original.withToggledStatus(StatusEnum.ready);

      expect(original.status, isEmpty);
      expect(toggled.status, [StatusEnum.ready]);
      expect(toggled.withToggledStatus(StatusEnum.ready).status, isEmpty);
      expect(
        () => toggled.status.add(StatusEnum.delivered),
        throwsUnsupportedError,
      );
    });

    test('copyWith keeps omitted fields and clears explicit null', () {
      final query = DeviceQuery(
        searchQuery: 'a',
        initialEntryDate: DateTime(2026),
        hasUrgency: true,
      );

      expect(query.copyWith(size: 5).searchQuery, 'a');
      expect(query.copyWith(searchQuery: null).searchQuery, isNull);
      expect(query.withRangeDate(null, null).initialEntryDate, isNull);
      expect(query.clearSelectableFilters().hasUrgency, isNull);
      expect(query.clearSelectableFilters().searchQuery, 'a');
    });
  });

  group('DeviceQuery serialization', () {
    test(
      'search body sends searchQuery and size; filter body sends customerName',
      () {
        const query = DeviceQuery(searchQuery: 'Maria');

        final search = query.toSearchJson(2);
        expect(search['searchQuery'], 'Maria');
        expect(search['page'], 2);
        expect(search['size'], DeviceQuery.defaultSize);

        final filter = query.toFilterJson(2);
        expect(filter['customerName'], 'Maria');
        expect(filter.containsKey('searchQuery'), isFalse);
        expect(filter['page'], 2);
      },
    );

    test('default ordering is entry date descending', () {
      expect(const DeviceQuery().toSearchJson(0)['ordenation'], {
        'orderByField': 'entryDate',
        'orderByDirection': 'DESC',
      });
    });
  });
}
