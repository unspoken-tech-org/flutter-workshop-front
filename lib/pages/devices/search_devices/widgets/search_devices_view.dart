import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/controllers/search_devices_controller.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/widgets/order_by_overlay_button_view.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/widgets/search_devices_filter_widget.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/widgets/search_devices_header.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:flutter_workshop_front/widgets/device/filtered_device_card.dart';
import 'package:flutter_workshop_front/widgets/shared/empty_list_widget.dart';
import 'package:flutter_workshop_front/widgets/shared/infinite_scroll_listener.dart';
import 'package:provider/provider.dart';

class SearchDevicesView extends StatefulWidget {
  const SearchDevicesView({super.key});

  @override
  State<SearchDevicesView> createState() => _SearchDevicesViewState();
}

class _SearchDevicesViewState extends State<SearchDevicesView> {
  final _scrollController = ScrollController();

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
                      const SearchDevicesHeader(),
                      const SearchDevicesHeaderFilterWidget(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Selector<SearchDevicesController, int>(
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
                          const SearchOrderByButtonView(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child:
                      Selector<
                        SearchDevicesController,
                        (bool, List<DeviceDataTable>, bool, bool, bool)
                      >(
                        selector: (context, controller) => (
                          controller.isLoading,
                          controller.devices,
                          controller.hasMore,
                          controller.isLoadingMore,
                          controller.loadMoreFailed,
                        ),
                        builder: (context, values, _) {
                          final (
                            isLoading,
                            devices,
                            hasMore,
                            isLoadingMore,
                            loadMoreFailed,
                          ) = values;
                          final controller = context
                              .read<SearchDevicesController>();

                          if (isLoading) {
                            return ListView.builder(
                              itemCount: 10,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemBuilder: (context, index) {
                                return const _DeviceCardShimmer();
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

                          return InfiniteScrollListener(
                            scrollController: _scrollController,
                            hasMore: hasMore,
                            isLoading: isLoading,
                            isLoadingMore: isLoadingMore,
                            loadMoreFailed: loadMoreFailed,
                            onLoadMore: controller.loadMore,
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: devices.length + (hasMore ? 1 : 0),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemBuilder: (context, index) {
                                if (index == devices.length) {
                                  if (loadMoreFailed && !isLoadingMore) {
                                    return LoadMoreErrorFooter(
                                      message:
                                          'Erro ao carregar mais aparelhos.',
                                      onRetry: controller.retryLoadMore,
                                    );
                                  }
                                  return Column(
                                    children: [
                                      ...List.generate(
                                        2,
                                        (index) => const _DeviceCardShimmer(),
                                      ),
                                    ],
                                  );
                                }
                                return FilteredDeviceCard(
                                  device: devices[index],
                                  onTap: () {
                                    WsNavigator.pushDeviceDetails(
                                      context,
                                      devices[index].deviceId,
                                    ).then((_) {
                                      if (context.mounted) {
                                        context
                                            .read<SearchDevicesController>()
                                            .searchDevices();
                                      }
                                    });
                                  },
                                );
                              },
                            ),
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

class _DeviceCardShimmer extends StatelessWidget {
  const _DeviceCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
