import 'package:flutter_workshop_front/core/di/app_dependencies.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_infos_widget.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_page_shimmer.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_payments.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/tabs/device_tabs_widget.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:provider/provider.dart';

class DeviceDetailsPage extends StatefulWidget {
  static const route = 'device-details';
  final int deviceId;
  final DeviceCustomerPageController Function()? controllerFactory;

  const DeviceDetailsPage({
    super.key,
    required this.deviceId,
    this.controllerFactory,
  });

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    unawaited(
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      lazy: false,
      create: (context) {
        final controller =
            widget.controllerFactory?.call() ??
            DeviceCustomerPageController.fromDependencies(
              context.read<AppDependencies>(),
            );
        unawaited(controller.init(widget.deviceId));
        return controller;
      },
      child: WsScaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white70,
          onPressed: _scrollToTop,
          child: const Icon(Icons.arrow_upward, color: Colors.black87),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        child:
            Selector<
              DeviceCustomerPageController,
              ({
                bool isLoading,
                DeviceCustomer? deviceCustomer,
                String? loadError,
              })
            >(
              selector: (context, controller) => (
                isLoading: controller.isLoading,
                deviceCustomer: controller.deviceCustomer,
                loadError: controller.loadError,
              ),
              builder: (context, state, child) {
                if (state.isLoading) return const CustomerDevicePageShimmer();

                if (state.deviceCustomer == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.loadError ??
                                'Não foi possível carregar os dados do aparelho.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            identifier: 'deviceDetail.retry',
                            child: ElevatedButton.icon(
                              onPressed: () => context
                                  .read<DeviceCustomerPageController>()
                                  .init(widget.deviceId),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: 1050,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 20,
                              children: [
                                Flexible(
                                  flex: 2,
                                  child: CustomerDeviceInfosWidget(),
                                ),
                                Flexible(
                                  flex: 1,
                                  child: CustomerDevicePayments(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            height: 514,
                            child: DeviceTabsWidget(),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}
