import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/customer_detail_controller.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/widgets/customer_detail_shimmer.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/widgets/customer_devices_section.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/widgets/customer_form_section.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_remote_data_source.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:flutter_workshop_front/widgets/shared/empty_list_widget.dart';
import 'package:provider/provider.dart';

class CustomerDetailPage extends StatefulWidget {
  static const String route = 'customer_detail';
  final int customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return ChangeNotifierProvider(
      lazy: false,
      create: (_) =>
          CustomerDetailController(CustomerRemoteDataSource())
            ..fetchCustomer(widget.customerId),
      child: WsScaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(
            child: Container(
              width: width * 0.5,
              margin: const EdgeInsets.symmetric(vertical: 24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Selector<CustomerDetailController, bool>(
                  selector: (_, controller) => controller.isLoading,
                  builder: (context, isLoading, _) {
                    if (isLoading) {
                      return const CustomerDetailShimmer();
                    }
                    final controller = context.read<CustomerDetailController>();
                    if (controller.customer == null) {
                      return const EmptyListWidget(
                        message: 'Nenhum cliente encontrado.',
                      );
                    }
                    return Column(
                      children: [
                        CustomerFormSection(customerId: widget.customerId),
                        const SizedBox(height: 16),
                        CustomerDevicesSection(customerId: widget.customerId),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
