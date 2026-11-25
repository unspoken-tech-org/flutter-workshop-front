import 'package:flutter/widgets.dart';

/// Calls [onReturn] each time the enclosing route becomes the top route
/// again, after another route pushed over it is popped or replaced.
///
/// Unlike awaiting `push(...)`, this also fires when the pushed route was
/// replaced (e.g. register → detail via `pushReplacement`), whose future
/// never completes in go_router.
class RefreshOnReturn extends StatefulWidget {
  final VoidCallback onReturn;
  final Widget child;

  const RefreshOnReturn({
    super.key,
    required this.onReturn,
    required this.child,
  });

  @override
  State<RefreshOnReturn> createState() => _RefreshOnReturnState();
}

class _RefreshOnReturnState extends State<RefreshOnReturn> {
  bool? _wasCurrent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrent = ModalRoute.isCurrentOf(context) ?? true;
    if (_wasCurrent == false && isCurrent) {
      // didChangeDependencies runs during build: a controller that notifies
      // synchronously would mark its listeners dirty mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onReturn();
      });
    }
    _wasCurrent = isCurrent;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
