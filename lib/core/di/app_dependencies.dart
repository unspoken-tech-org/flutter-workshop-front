import 'package:flutter_workshop_front/core/config/app_config.dart';
import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/core/security/secure_key_value_store.dart';
import 'package:flutter_workshop_front/core/security/security_storage.dart';
import 'package:flutter_workshop_front/core/ui/ui_message.dart';
import 'package:flutter_workshop_front/repositories/catalog/catalog_repository.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/repositories/device/device_repository.dart';
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
/// Entregue às páginas pelo `MultiProvider` (`context.read<DeviceRepository>()`,
/// `context.read<CustomerRepository>()`, `context.read<CatalogRepository>()` e
/// `context.read<AppDependencies>()`); as páginas montam seus controllers a
/// partir daqui, nunca instanciando services. Nenhuma dependência é global ou
/// estática.
class AppDependencies {
  AppDependencies({
    required this.config,
    required this.storage,
    required this.authNotifier,
    required this.authService,
    required this.deviceRepository,
    required this.customerRepository,
    required this.catalogRepository,
    required this.updateService,
    required this.uiMessages,
  });

  factory AppDependencies.create(AppConfig config, SecureKeyValueStore store) {
    final storage = SecurityStorage(store, namespace: config.storageNamespace);
    final authNotifier = AuthNotifier();
    final uiMessages = UiMessageBus();
    final dioFactory = CustomDio(
      baseUri: config.baseUri,
      onMessage: uiMessages.publish,
    );

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

    return AppDependencies(
      config: config,
      storage: storage,
      authNotifier: authNotifier,
      authService: authService,
      deviceRepository: DeviceRepository(
        deviceCustomerService: DeviceCustomerService(api),
        paymentService: PaymentService(api),
        customerContactService: CustomerContactService(api),
        deviceStatisticsService: DeviceStatisticsService(api),
      ),
      customerRepository: CustomerRepository(CustomerService(api)),
      catalogRepository: CatalogRepository(
        technicianService: TechnicianService(api),
        colorService: ColorService(api),
        deviceTypeService: DeviceTypeService(api),
        deviceBrandService: DeviceBrandService(api),
        searchService: TypeBrandModelSearchService(api),
      ),
      updateService: UpdateService(
        feedUrl: config.updateFeedUrl,
        githubOwner: config.githubOwner,
        githubRepo: config.githubRepo,
      ),
      uiMessages: uiMessages,
    );
  }

  final AppConfig config;
  final SecurityStorage storage;
  final AuthNotifier authNotifier;
  final AuthService authService;

  final DeviceRepository deviceRepository;
  final CustomerRepository customerRepository;
  final CatalogRepository catalogRepository;

  final UpdateService updateService;

  /// Mensagens globais (erros de infraestrutura do HTTP); a UI as exibe.
  final UiMessageBus uiMessages;
}
