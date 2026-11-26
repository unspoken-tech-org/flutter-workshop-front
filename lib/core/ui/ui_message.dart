import 'dart:async';

import 'package:flutter/foundation.dart';

/// Mensagem para o usuário publicada por controllers e pelo interceptor HTTP.
///
/// Quem publica não sabe como ela aparece: a UI (`UiMessageListener`) é quem
/// exibe, de modo que camadas abaixo da UI não importam `SnackBarUtil`.
@immutable
sealed class UiMessage {
  const UiMessage(this.text);

  final String text;
}

/// Operação concluída com sucesso.
final class UiSuccess extends UiMessage {
  const UiSuccess(super.text);
}

/// Falha que o usuário precisa ver.
final class UiError extends UiMessage {
  const UiError(super.text);
}

/// Origem de [UiMessage]s: um controller (via [UiMessageSource]) ou o
/// [UiMessageBus] global.
abstract interface class UiMessageStream {
  Stream<UiMessage> get messages;
}

/// Canal global de mensagens, para quem não tem um controller (interceptor
/// HTTP). O `AppDependencies` cria um; o `MaterialApp` o exibe.
class UiMessageBus implements UiMessageStream {
  final StreamController<UiMessage> _controller =
      StreamController<UiMessage>.broadcast(sync: true);

  @override
  Stream<UiMessage> get messages => _controller.stream;

  void publish(UiMessage message) {
    if (!_controller.isClosed) _controller.add(message);
  }

  Future<void> dispose() => _controller.close();
}

/// Dá a um `ChangeNotifier` um fluxo de [UiMessage]s. A página envolve a tela
/// em `UiMessageListener` para exibi-las. Sem ouvinte, a mensagem é descartada.
mixin UiMessageSource on ChangeNotifier implements UiMessageStream {
  final StreamController<UiMessage> _messageController =
      StreamController<UiMessage>.broadcast(sync: true);

  @override
  Stream<UiMessage> get messages => _messageController.stream;

  @protected
  void emit(UiMessage message) {
    if (!_messageController.isClosed) _messageController.add(message);
  }

  @protected
  void emitSuccess(String text) => emit(UiSuccess(text));

  @protected
  void emitError(String text) => emit(UiError(text));

  @override
  void dispose() {
    unawaited(_messageController.close());
    super.dispose();
  }
}
