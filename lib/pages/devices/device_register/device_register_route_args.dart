/// Dados opcionais da rota de cadastro de aparelho que não podem ir na URI.
///
/// `customerName` é dado pessoal: trafega via `extra` do go_router, nunca na
/// query string (que aparece em logs, histórico e deep-links).
class DeviceRegisterExtra {
  final String? customerName;

  const DeviceRegisterExtra({this.customerName});
}

/// Argumentos já resolvidos da rota `/device/register`.
class DeviceRegisterRouteArgs {
  final int? customerId;
  final String? customerName;

  const DeviceRegisterRouteArgs({this.customerId, this.customerName});

  /// Lê `customerId` da query string e `customerName` do `extra` (type-check
  /// seguro: qualquer outro tipo de `extra` é ignorado).
  factory DeviceRegisterRouteArgs.fromRoute(Uri uri, Object? extra) {
    final customerId = int.tryParse(uri.queryParameters['customerId'] ?? '');
    final customerName = extra is DeviceRegisterExtra
        ? extra.customerName
        : null;
    return DeviceRegisterRouteArgs(
      customerId: customerId,
      customerName: customerName,
    );
  }
}
