import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/pages/customers/controllers/customer_detail/customer_detail_controller.dart';
import 'package:flutter_workshop_front/pages/customers/widgets/customer_detail/customer_detail_form.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_remote_data_source.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_devices_list.dart';

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
  final GlobalKey<CustomerDetailFormState> _formKey =
      GlobalKey<CustomerDetailFormState>();

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

    return WsScaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
                return const Center(child: CircularProgressIndicator());
              }

              return ValueListenableBuilder<String?>(
                valueListenable: controller.error,
                builder: (context, error, _) {
                  if (error != null) {
                    return Center(child: Text(error));
                  }
                  return ValueListenableBuilder<CustomerModel?>(
                    valueListenable: controller.customer,
                    builder: (context, customer, _) {
                      if (customer == null) {
                        return const Center(
                            child: Text('Nenhum cliente encontrado.'));
                      }
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Column(
                              children: [
                                ValueListenableBuilder<bool>(
                                  valueListenable: _isEditing,
                                  builder: (context, isEditing, _) {
                                    return CustomerDetailForm(
                                      key: _formKey,
                                      customer: customer,
                                      isEditing: isEditing,
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
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
                                        child: CustomerDevicesList(
                                          customerDevices:
                                              customer.customerDevices,
                                          onTap: (id) {
                                            WsNavigator.pushDevice(context, id);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ValueListenableBuilder<bool>(
                              valueListenable: _isEditing,
                              builder: (context, isEditing, _) {
                                if (isEditing) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          _formKey.currentState?.resetForm();
                                          _isEditing.value = false;
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Cancelar'),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final input =
                                              _formKey.currentState?.getInput();
                                          if (input != null) {
                                            final success =
                                                await controller.updateCustomer(
                                              widget.customerId,
                                              input,
                                            );
                                            if (success) {
                                              _isEditing.value = false;
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF6750a4),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Salvar'),
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _isEditing.value = true,
                                      child: const Text('Editar'),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
