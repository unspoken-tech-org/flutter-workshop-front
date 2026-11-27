import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_workshop_front/core/ui/ui_message.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';
import 'package:provider/provider.dart';

/// Exibe as [UiMessage]s de [source] (controller ou `UiMessageBus`) com o
/// `SnackBarUtil`. É a única ponte entre mensagens e UI.
class UiMessageListener extends StatefulWidget {
  const UiMessageListener({
    super.key,
    required this.source,
    required this.child,
  });

  final UiMessageStream source;
  final Widget child;

  @override
  State<UiMessageListener> createState() => _UiMessageListenerState();
}

class _UiMessageListenerState extends State<UiMessageListener> {
  StreamSubscription<UiMessage>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(UiMessageListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.source, widget.source)) {
      unawaited(_subscription?.cancel());
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = widget.source.messages.listen(_show);
  }

  void _show(UiMessage message) {
    switch (message) {
      case UiSuccess(:final text):
        SnackBarUtil().showSuccess(text);
      case UiError(:final text):
        SnackBarUtil().showError(text);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// [UiMessageListener] da fonte `C` já provida acima na árvore (Provider).
class ProviderUiMessageListener<C extends UiMessageStream>
    extends StatelessWidget {
  const ProviderUiMessageListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return UiMessageListener(source: context.read<C>(), child: child);
  }
}
