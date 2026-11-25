import 'package:flutter_workshop_front/core/config/app_config.dart';
import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/secure_key_value_store.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';
import 'package:flutter_workshop_front/repositories/all_devices/all_devices_remote_data_source.dart';
import 'package:flutter_workshop_front/repositories/all_devices/all_devices_repository.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_remote_data_source.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/repositories/types_brands_models/types_brands_models_remote_data_source.dart';
import 'package:flutter_workshop_front/repositories/types_brands_models/types_brands_models_repository.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import 'package:flutter_workshop_front/services/color/color_service.dart';
import 'package:flutter_workshop_front/services/customer/customer_service.dart';
import 'package:flutter_workshop_front/services/customer_contact/customer_contact_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_brand_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_type_service.dart';
import 'package:flutter_workshop_front/services/device_statistics/device_statistics_service.dart';
import 'package:flutter_workshop_front/services/payment/payment_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';
import 'package:flutter_workshop_front/services/types_brands_models/type_brand_model_search_service.dart';
import 'package:flutter_workshop_front/services/update/update_service.dart';

/// Composition root: o grafo de objetos do app, montado uma vez no `main`.
///
/// Entregue às páginas pelo `MultiProvider` (`context.read<AppDependencies>()`);
/// as páginas montam seus controllers a partir daqui, nunca instanciando
/// services. Nenhuma dependência é global ou estática.
class AppDependencies {
  AppDependencies({
    required this.config,
    required this.storage,
    required this.authNotifier,
    required this.authService,
    required this.colorService,
    required this.customerContactService,
    required this.deviceCustomerService,
    required this.deviceStatisticsService,
    required this.paymentService,
    required this.technicianService,
    required this.customerRepository,
    required this.allDevicesRepository,
    required this.typesBrandsModelsRepository,
    required this.updateService,
  });

  factory AppDependencies.create(AppConfig config, SecureKeyValueStore store) {
    final storage = SecurityStorage(store, namespace: config.storageNamespace);
    final authNotifier = AuthNotifier();
    final dioFactory = CustomDio(baseUri: config.baseUri);

    final authService = AuthService(
      dio: dioFactory.createAuthDio(),
      storage: storage,
      authNotifier: authNotifier,
      devApiKey: config.devApiKey,
    );
    final api = ApiClient(
      dioFactory.createAppDio(
        storage: storage,
        onRefresh: authService.refreshToken,
        authNotifier: authNotifier,
        onCredentialRejected: authService.forceLogout,
      ),
    );

    final deviceCustomerService = DeviceCustomerService(api);

    return AppDependencies(
      config: config,
      storage: storage,
      authNotifier: authNotifier,
      authService: authService,
      colorService: ColorService(api),
      customerContactService: CustomerContactService(api),
      deviceCustomerService: deviceCustomerService,
      deviceStatisticsService: DeviceStatisticsService(api),
      paymentService: PaymentService(api),
      technicianService: TechnicianService(api),
      customerRepository: CustomerRemoteDataSource(CustomerService(api)),
      allDevicesRepository: AllDevicesRemoteDataSource(
        deviceCustomerService,
        DeviceTypeService(api),
        DeviceBrandService(api),
      ),
      typesBrandsModelsRepository: TypesBrandsModelsRemoteDataSource(
        TypeBrandModelSearchService(api),
      ),
      updateService: UpdateService(
        feedUrl: config.updateFeedUrl,
        githubOwner: config.githubOwner,
        githubRepo: config.githubRepo,
      ),
    );
  }

  final AppConfig config;
  final SecurityStorage storage;
  final AuthNotifier authNotifier;
  final AuthService authService;

  final ColorService colorService;
  final CustomerContactService customerContactService;
  final DeviceCustomerService deviceCustomerService;
  final DeviceStatisticsService deviceStatisticsService;
  final PaymentService paymentService;
  final TechnicianService technicianService;

  final CustomerRepository customerRepository;
  final AllDevicesRepository allDevicesRepository;
  final TypesBrandsModelsRepository typesBrandsModelsRepository;

  final UpdateService updateService;
}
