import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/widgets/customer_card_shimmer.dart';

class CustomersListShimmer extends StatelessWidget {
  const CustomersListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 10,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        return const CustomerCardShimmer();
      },
      separatorBuilder: (context, index) {
        return const SizedBox(height: 8);
      },
    );
  }
}
