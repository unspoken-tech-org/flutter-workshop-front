import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';

Map<String, dynamic> _json() => {
  'deviceId': 5,
  'customerId': 2,
  'customerName': 'Maria Teste',
  'deviceStatus': 'EM_ANDAMENTO',
  'brandName': 'MarcaTeste',
  'modelName': 'ModeloX',
  'typeName': 'Celular',
  'technicianId': 1,
  'technicianName': 'Tecnico',
  'problem': 'Tela quebrada',
  'budget': 'Troca de tela',
  'budgetFee': 0.0,
  'serviceValue': 450.0,
  'deviceColors': ['Preto'],
  'hasUrgency': false,
  'revision': false,
  'entryDate': '2026-11-22T09:05:59.877558',
  'lastUpdate': '2026-11-25T09:05:59.877558',
  'customerPhones': <dynamic>[],
  'customerContacts': <dynamic>[],
  'otherDevices': <dynamic>[],
  'payments': <dynamic>[],
};

void main() {
  group('DeviceCustomer.fromJson', () {
    test('aceita observation ausente (API omite campos nulos)', () {
      final device = DeviceCustomer.fromJson(_json());

      expect(device.deviceId, 5);
      expect(device.observation, '');
    });

    test('aceita observation nula', () {
      final device = DeviceCustomer.fromJson(_json()..['observation'] = null);

      expect(device.observation, '');
    });

    test('mantém observation preenchida', () {
      final device = DeviceCustomer.fromJson(
        _json()..['observation'] = 'Obs inicial',
      );

      expect(device.observation, 'Obs inicial');
    });
  });
}
