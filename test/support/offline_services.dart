import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/services/customer_contact/customer_contact_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/payment/payment_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';

/// [ApiClient] sem rede: toda chamada falha com `connectionError`
/// (`NetworkFailure`). Para dependências que o teste não exercita.
ApiClient offlineApiClient() {
  final dio = Dio(BaseOptions(baseUrl: 'https://offline.test'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException.connectionError(
            requestOptions: options,
            reason: 'offline (teste)',
          ),
        ),
      ),
    );
  return ApiClient(dio);
}

/// [DeviceCustomerPageController] com services offline onde o teste não
/// passa um fake.
DeviceCustomerPageController testDeviceCustomerPageController({
  DeviceCustomerService? deviceCustomerService,
  TechnicianService? technicianService,
  CustomerContactService? customerContactService,
  PaymentService? paymentService,
}) {
  final api = offlineApiClient();
  return DeviceCustomerPageController(
    deviceCustomerService: deviceCustomerService ?? DeviceCustomerService(api),
    technicianService: technicianService ?? TechnicianService(api),
    customerContactService:
        customerContactService ?? CustomerContactService(api),
    paymentService: paymentService ?? PaymentService(api),
  );
}
