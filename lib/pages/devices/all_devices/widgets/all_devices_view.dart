import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/controllers/all_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/all_devices_header.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/all_devices_header_filter_widget.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/device_card_shimmer.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/widgets/order_by_overlay_button_view.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:flutter_workshop_front/widgets/device/filtered_device_card.dart';
import 'package:flutter_workshop_front/widgets/shared/empty_list_widget.dart';
import 'package:provider/provider.dart';

class AllDevicesView extends StatefulWidget {
  const AllDevicesView({super.key});

  @override
  State<AllDevicesView> createState() => _AllDevicesViewState();
}

class _AllDevicesViewState extends State<AllDevicesView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<AllDevicesController>();
      _scrollController.addListener(() {
        if (_scrollController.position.maxScrollExtent ==
            _scrollController.offset) {
          controller.loadMore();
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WsScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    spacing: 18,
                    children: [
                      const AllDevicesHeader(),
                      const AllDevicesHeaderFilterWidget(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Selector<AllDevicesController, int>(
                            selector: (context, controller) =>
                                controller.totalElements,
                            builder: (context, totalElements, _) {
                              if (totalElements == 0) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                'Aparelhos encontrados: $totalElements',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              );
                            },
                          ),
                          const OrderByButtonView(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Selector<AllDevicesController,
                      (bool, List<DeviceDataTable>, bool, bool)>(
                    selector: (context, controller) => (
                      controller.isLoading,
                      controller.devices,
                      controller.hasMore,
                      controller.isLoadingMore
                    ),
                    builder: (context, values, _) {
                      final (isLoading, devices, hasMore, isLoadingMore) =
                          values;

                      if (isLoading) {
                        return ListView.builder(
                          itemCount: 10,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            return const DeviceCardShimmer();
                          },
                        );
                      }

                      if (devices.isEmpty) {
                        return const Center(
                          child: EmptyListWidget(
                            message: 'Nenhum aparelho encontrado',
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: devices.length + (hasMore ? 1 : 0),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          if (index == devices.length) {
                            return Column(
                              children: [
                                ...List.generate(
                                    2, (index) => const DeviceCardShimmer()),
                              ],
                            );
                          }
                          return FilteredDeviceCard(
                            device: devices[index],
                            onTap: () {
                              WsNavigator.pushDeviceDetails(
                                context,
                                devices[index].deviceId,
                              ).then(
                                (_) {
                                  if (context.mounted) {
                                    context
                                        .read<AllDevicesController>()
                                        .fetchAllDevicesFiltering();
                                  }
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
