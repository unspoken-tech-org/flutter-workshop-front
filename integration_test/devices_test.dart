// Device scenarios against the local E2E API (skill e2e-local-api).
// Run with .agents/skills/flutter-ui-mcp/scripts/run_integration_tests.sh.
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/intl.dart';

import 'support/harness.dart';

final _format = DateFormat('dd/MM/yyyy');

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('device total disappears when the search gets a 502', (
    tester,
  ) async {
    await bootApp(tester, (tester) async {
      final total = find.textContaining('Aparelhos encontrados:');
      final search = field(identifier: 'allDevices.search');

      // The "Novo" dashboard card opens the all-devices list (seed device #1).
      await tapId(tester, 'home.stats.new');
      await pumpUntilFound(tester, total);

      await setProxyMode('502');
      await enter(tester, search, 'sem resultado 502');
      await pumpUntilGone(tester, total);

      await setProxyMode('pass');
      await enter(tester, search, '');
      await pumpUntilFound(tester, total);
    });
  });

  testWidgets('range picker: one date ends today and reopens on the range', (
    tester,
  ) async {
    await bootApp(tester, (tester) async {
      final today = _today();
      final first = DateTime(today.year, today.month);
      final entry = field(identifier: 'searchDevices.filter.entryDate');
      final picker = find.byType(CalendarDatePicker2WithActionButtons);

      await tapId(tester, 'drawer.searchDevices');
      await tapId(tester, 'searchDevices.filterToggle');
      await tapId(tester, 'searchDevices.filter.entryDate');
      await pumpUntilFound(tester, picker);
      await tester.tap(
        find.descendant(of: picker, matching: find.text('1')).first,
      );
      await tester.pump();
      await tapText(tester, 'OK');
      await pumpUntilGone(tester, picker);

      final expected = '${_format.format(first)} - ${_format.format(today)}';
      expect(fieldText(tester, entry), expected);

      await tapId(tester, 'searchDevices.filter.entryDate');
      await pumpUntilFound(tester, picker);
      final reopened = tester.widget<CalendarDatePicker2WithActionButtons>(
        picker,
      );
      expect(reopened.value, [first, today]);
      await tapText(tester, 'CANCELAR');
      await pumpUntilGone(tester, picker);
      expect(fieldText(tester, entry), expected);
    });
  });

  testWidgets('entry date picker opens on the selected date', (tester) async {
    await bootApp(tester, (tester) async {
      final today = _today();
      final first = DateTime(today.year, today.month);
      final entry = field(identifier: 'deviceDetail.entryDate');
      final picker = find.byType(DatePickerDialog);

      await tapId(tester, 'drawer.searchDevices');
      await tapId(tester, 'device.card.1');
      await tapId(tester, 'deviceDetail.edit');
      await pumpUntilFound(tester, byId('deviceDetail.save'));

      await tapId(tester, 'deviceDetail.entryDate');
      await pumpUntilFound(tester, picker);
      await tester.tap(
        find.descendant(of: picker, matching: find.text('1')).first,
      );
      await tester.pump();
      await tapText(tester, 'OK');
      await pumpUntilGone(tester, picker);
      expect(fieldText(tester, entry), _format.format(first));

      await tapId(tester, 'deviceDetail.entryDate');
      await pumpUntilFound(tester, picker);
      expect(tester.widget<DatePickerDialog>(picker).initialDate, first);
      await tapText(tester, 'Cancelar');
      await pumpUntilGone(tester, picker);

      // Leave the device as it was.
      await tapId(tester, 'deviceDetail.cancel');
      await pumpUntilFound(tester, byId('deviceDetail.edit'));
    });
  });
}
