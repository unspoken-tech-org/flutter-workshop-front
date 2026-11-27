import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/ui/ui_message.dart';

/// Registra as [UiMessage]s de [source] numa lista; a assinatura é cancelada
/// no `tearDown` do teste.
List<UiMessage> recordMessages(UiMessageStream source) {
  final messages = <UiMessage>[];
  final subscription = source.messages.listen(messages.add);
  addTearDown(() => unawaited(subscription.cancel()));
  return messages;
}

/// Atalho para afirmar uma única mensagem de sucesso/erro com o texto dado.
Matcher isUiSuccess(String text) =>
    isA<UiSuccess>().having((m) => m.text, 'text', text);

Matcher isUiError(String text) =>
    isA<UiError>().having((m) => m.text, 'text', text);
