import 'package:flutter/material.dart';

class InfiniteScrollListener extends StatefulWidget {
  final ScrollController scrollController;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final VoidCallback onLoadMore;
  final double threshold;
  final Widget child;

  const InfiniteScrollListener({
    super.key,
    required this.scrollController,
    required this.hasMore,
    required this.isLoading,
    required this.isLoadingMore,
    required this.loadMoreFailed,
    required this.onLoadMore,
    required this.child,
    this.threshold = 200.0,
  });

  @override
  State<InfiniteScrollListener> createState() => _InfiniteScrollListenerState();
}

class _InfiniteScrollListenerState extends State<InfiniteScrollListener> {
  bool _checkScheduled = false;

  bool get _canLoadMore =>
      widget.hasMore &&
      !widget.isLoading &&
      !widget.isLoadingMore &&
      !widget.loadMoreFailed;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(covariant InfiniteScrollListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_onScroll);
      widget.scrollController.addListener(_onScroll);
    }
    if (_canLoadMore &&
        (oldWidget.hasMore != widget.hasMore ||
            oldWidget.isLoading != widget.isLoading ||
            oldWidget.isLoadingMore != widget.isLoadingMore ||
            oldWidget.loadMoreFailed != widget.loadMoreFailed)) {
      _scheduleCheck();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    _checkAndLoadMore();
  }

  void _scheduleCheck() {
    if (_checkScheduled || !_canLoadMore) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      _checkAndLoadMore();
    });
  }

  void _checkAndLoadMore() {
    if (!mounted || !_canLoadMore) return;
    if (!widget.scrollController.hasClients) return;

    final position = widget.scrollController.position;
    if (!position.hasContentDimensions) return;

    final isShortList = position.maxScrollExtent <= 0;
    final isNearBottom =
        position.pixels >= position.maxScrollExtent - widget.threshold;

    if (isShortList || isNearBottom) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical) {
          _scheduleCheck();
        }
        return false;
      },
      child: widget.child,
    );
  }
}

class LoadMoreErrorFooter extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const LoadMoreErrorFooter({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
