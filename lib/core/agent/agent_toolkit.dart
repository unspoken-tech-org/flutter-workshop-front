import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mcp_toolkit/mcp_toolkit.dart';

import 'package:flutter_workshop_front/core/logging/app_logger.dart';

/// Liga o mcp_toolkit, que expõe a UI ao agente pela VM service
/// (`flutter-mcp-toolkit`). Ativado com `--dart-define=MCP_TOOLKIT=true`;
/// em release nunca é ligado.
const bool mcpToolkitEnabled = bool.fromEnvironment('MCP_TOOLKIT');

/// Roda o [body] do `main`. Com o toolkit ligado, o corpo inteiro roda dentro
/// da zona do bootstrap, para o binding e o `runApp` ficarem na mesma zona.
Future<void> runWithAgentToolkit(Future<void> Function() body) async {
  if (kReleaseMode || !mcpToolkitEnabled) {
    await body();
    return;
  }
  await MCPToolkitBinding.instance.bootstrapFlutter(
    runApp: body,
    // Dentro da zona guardada, erros assíncronos não chegam ao
    // PlatformDispatcher.onError: registra no log e repassa ao toolkit.
    onZoneError: (error, stackTrace) {
      AppLogger.error(
        'Zone',
        'Uncaught async error',
        error: error,
        stackTrace: stackTrace,
      );
      MCPToolkitBinding.instance.handleZoneError(error, stackTrace);
    },
  );
}
