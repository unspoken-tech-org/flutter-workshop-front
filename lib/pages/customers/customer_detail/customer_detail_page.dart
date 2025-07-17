import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/customer_detail_controller.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/inherited_customer_detail_controller.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/widgets/customer_detail_form.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_remote_data_source.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_devices_list.dart';
import 'package:flutter_workshop_front/widgets/shared/empty_list_widget.dart';

class CustomerDetailPage extends StatefulWidget {
  static const String route = 'customer_detail';
  final int customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  late final CustomerDetailController controller;
  final _isEditing = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    controller = CustomerDetailController(CustomerRemoteDataSource());
    controller.fetchCustomer(widget.customerId);
  }

  @override
  void dispose() {
    _isEditing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return InheritedCustomerDetailController(
      controller: controller,
      child: WsScaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              margin: const EdgeInsets.symmetric(vertical: 24.0),
              width: width * 0.5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ValueListenableBuilder<bool>(
                valueListenable: controller.isLoading,
                builder: (context, isLoading, _) {
                  if (isLoading) {
                    // TODO: add shimmer effect
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ValueListenableBuilder<CustomerModel?>(
                    valueListenable: controller.customer,
                    builder: (context, customer, _) {
                      if (customer == null) {
                        return const EmptyListWidget(
                          message: 'Nenhum cliente encontrado.',
                        );
                      }
                      return Column(
                        children: [
                          CustomerDetailForm(
                            customer: customer,
                            controller: controller,
                            isEditingNotifier: _isEditing,
                          ),
                          const SizedBox(height: 16),
                          ValueListenableBuilder<bool>(
                            valueListenable: _isEditing,
                            builder: (context, isEditing, _) {
                              if (isEditing) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withAlpha(50),
                                          spreadRadius: 2,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 500,
                                          child: Visibility(
                                            visible: customer
                                                .customerDevices.isNotEmpty,
                                            replacement: const EmptyListWidget(
                                              message:
                                                  'Nenhum aparelho encontrado',
                                            ),
                                            child: CustomerDevicesList(
                                              customerDevices:
                                                  customer.customerDevices,
                                              onTap: (id) {
                                                WsNavigator.pushDevice(
                                                    context, id);
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
