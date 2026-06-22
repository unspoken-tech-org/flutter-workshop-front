import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/customer_detail_controller.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/widgets/customer_detail_form.dart';
import 'package:flutter_workshop_front/widgets/shared/empty_list_widget.dart';
import 'package:provider/provider.dart';

class CustomerFormSection extends StatelessWidget {
  const CustomerFormSection({super.key, required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerDetailController>(
      builder: (context, controller, _) {
        final customer = controller.customer;
        if (customer == null) {
          return const EmptyListWidget(message: 'Nenhum cliente encontrado.');
        }
        return CustomerDetailForm(customer: customer, controller: controller);
      },
    );
  }
}
