import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';

void main() {
  group('CustomerSearchFilter.getCustomerSearchFilter', () {
    test('populates searchName preserving spaces and accents', () {
      final filter = CustomerSearchFilter.getCustomerSearchFilter(
        '  José   da Conceição ',
        page: 0,
        size: 10,
      );

      expect(filter, isNotNull);
      expect(filter!.searchName, 'José da Conceição');
      expect(filter.cpf, isNull);
      expect(filter.phone, isNull);
      expect(filter.searchEmail, isNull);
      expect(filter.id, isNull);
    });

    test('populates searchEmail preserving email characters', () {
      final filter = CustomerSearchFilter.getCustomerSearchFilter(
        '  maria.silva@oficina.com.br ',
      );

      expect(filter, isNotNull);
      expect(filter!.searchEmail, 'maria.silva@oficina.com.br');
      expect(filter.searchName, isNull);
    });

    test('populates cpf with digits only', () {
      final filter = CustomerSearchFilter.getCustomerSearchFilter(
        '529.982.247-25',
      );

      expect(filter, isNotNull);
      expect(filter!.cpf, '52998224725');
    });

    test('populates phone with digits only', () {
      final filter = CustomerSearchFilter.getCustomerSearchFilter(
        '(11) 98765-4321',
      );

      expect(filter, isNotNull);
      expect(filter!.phone, '11987654321');
    });

    test('parses id even with leading/trailing spaces', () {
      final filter = CustomerSearchFilter.getCustomerSearchFilter('  123  ');

      expect(filter, isNotNull);
      expect(filter!.id, 123);
    });

    test('returns null for null, blank, or repeated-digit masked CPF', () {
      expect(CustomerSearchFilter.getCustomerSearchFilter(null), isNull);
      expect(CustomerSearchFilter.getCustomerSearchFilter('   '), isNull);
      expect(
        CustomerSearchFilter.getCustomerSearchFilter('111.111.111-11'),
        isNull,
      );
    });
  });
}
