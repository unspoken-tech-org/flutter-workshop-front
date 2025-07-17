import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/widgets/customer_card.dart';

class CustomersList extends StatelessWidget {
  final List<MinifiedCustomerModel> customers;
  final Function(int) onTap;
  const CustomersList({
    super.key,
    required this.customers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: customers.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final customer = customers[index];
        return CustomerCard(
          customer: customer,
          onTap: onTap,
        );
      },
      separatorBuilder: (context, index) {
        return const SizedBox(height: 8);
      },
    );
  }
}
