import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/controllers/all_customer_controller.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/widgets/customer_card.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/widgets/customer_card_shimmer.dart';
import 'package:flutter_workshop_front/widgets/shared/infinite_scroll_listener.dart';

class CustomersList extends StatefulWidget {
  final AllCustomerController controller;
  final List<MinifiedCustomerModel> customers;
  final void Function(int) onTap;

  const CustomersList({
    super.key,
    required this.controller,
    required this.customers,
    required this.onTap,
  });

  @override
  State<CustomersList> createState() => _CustomersListState();
}

class _CustomersListState extends State<CustomersList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount =
        widget.customers.length +
        (widget.controller.isLoadingMore || widget.controller.hasMore ? 1 : 0);

    return InfiniteScrollListener(
      scrollController: _scrollController,
      hasMore: widget.controller.hasMore,
      isLoading: widget.controller.isLoading,
      isLoadingMore: widget.controller.isLoadingMore,
      loadMoreFailed: widget.controller.loadMoreFailed,
      onLoadMore: widget.controller.loadMore,
      child: ListView.separated(
        controller: _scrollController,
        itemCount: itemCount,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          if (index == widget.customers.length) {
            if (widget.controller.loadMoreFailed &&
                !widget.controller.isLoadingMore) {
              return LoadMoreErrorFooter(
                message: 'Erro ao carregar mais clientes.',
                onRetry: widget.controller.retryLoadMore,
              );
            }
            return Column(
              children: [
                ...List.generate(2, (index) => const CustomerCardShimmer()),
              ],
            );
          }

          final customer = widget.customers[index];
          return CustomerCard(customer: customer, onTap: widget.onTap);
        },
        separatorBuilder: (context, index) => const SizedBox(height: 8),
      ),
    );
  }
}
