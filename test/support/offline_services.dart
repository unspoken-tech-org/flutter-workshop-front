import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/repositories/catalog/catalog_repository.dart';
import 'package:flutter_workshop_front/repositories/device/device_repository.dart';
import 'package:flutter_workshop_front/services/color/color_service.dart';
import 'package:flutter_workshop_front/services/customer_contact/customer_contact_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_brand_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_type_service.dart';
import 'package:flutter_workshop_front/services/device_statistics/device_statistics_service.dart';
import 'package:flutter_workshop_front/services/payment/payment_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';
import 'package:flutter_workshop_front/services/types_brands_models/type_brand_model_search_service.dart';

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

DeviceRepository offlineDeviceRepository([ApiClient? api]) {
  final client = api ?? offlineApiClient();
  return DeviceRepository(
    deviceCustomerService: DeviceCustomerService(client),
    paymentService: PaymentService(client),
    customerContactService: CustomerContactService(client),
    deviceStatisticsService: DeviceStatisticsService(client),
  );
}

CatalogRepository offlineCatalogRepository([ApiClient? api]) {
  final client = api ?? offlineApiClient();
  return CatalogRepository(
    technicianService: TechnicianService(client),
    colorService: ColorService(client),
    deviceTypeService: DeviceTypeService(client),
    deviceBrandService: DeviceBrandService(client),
    searchService: TypeBrandModelSearchService(client),
  );
}

/// [DeviceCustomerPageController] com repositórios offline onde o teste não
/// passa um fake.
DeviceCustomerPageController testDeviceCustomerPageController({
  DeviceRepository? deviceRepository,
  CatalogRepository? catalogRepository,
}) {
  final api = offlineApiClient();
  return DeviceCustomerPageController(
    deviceRepository: deviceRepository ?? offlineDeviceRepository(api),
    catalogRepository: catalogRepository ?? offlineCatalogRepository(api),
  );
}
