import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_infos_widget.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/customer_device_payments.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/tabs/device_tabs_widget.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';

import 'package:shimmer/shimmer.dart';

class DeviceDetailsPage extends StatefulWidget {
  static const route = 'device-details';
  final int deviceId;
  const DeviceDetailsPage({super.key, required this.deviceId});

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  final _scrollController = ScrollController();

  final DeviceCustomerPageController deviceCustomerPageController =
      DeviceCustomerPageController();

  @override
  void initState() {
    super.initState();
    deviceCustomerPageController.init(widget.deviceId);
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InheritedDeviceCustomerController(
      controller: deviceCustomerPageController,
      child: WsScaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white70,
          onPressed: _scrollToTop,
          child: const Icon(Icons.arrow_upward, color: Colors.black87),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        child: ValueListenableBuilder(
          valueListenable: deviceCustomerPageController.isLoading,
          builder: (context, isLoading, child) {
            if (isLoading) return const CustomerDevicePageShimmer();

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
                        height: 1010,
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

class CustomerDevicePageShimmer extends StatelessWidget {
  const CustomerDevicePageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 550,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _InfosShimmer()),
                      SizedBox(width: 20),
                      Expanded(flex: 2, child: _ContainerShimmer()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16)
                    .copyWith(bottom: 16),
                child: const SizedBox(
                  height: 514,
                  child: _TabsShimmer(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContainerShimmer extends StatelessWidget {
  const _ContainerShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    this.width,
    required this.height,
    this.borderRadius = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class _InfosShimmer extends StatelessWidget {
  const _InfosShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: 120, height: 16),
                  SizedBox(height: 8),
                  _ShimmerBox(width: 200, height: 16),
                  SizedBox(height: 8),
                  _ShimmerBox(width: 150, height: 14),
                  SizedBox(height: 16),
                  _ShimmerBox(width: 220, height: 16),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      _ShimmerBox(width: 80, height: 24, borderRadius: 12),
                      SizedBox(width: 8),
                      _ShimmerBox(width: 100, height: 24, borderRadius: 12),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _ShimmerBox(width: 20, height: 20),
                      SizedBox(width: 8),
                      _ShimmerBox(width: 120, height: 16),
                    ],
                  )
                ],
              )
            ],
          ),
          SizedBox(height: 16),
          _ShimmerBox(width: 180, height: 16),
          SizedBox(height: 8),
          _ShimmerBox(width: 150, height: 16),
          SizedBox(height: 8),
          _ShimmerBox(width: 150, height: 16),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShimmerBox(width: 150, height: 40),
              _ShimmerBox(width: 150, height: 40),
              SizedBox(width: 150),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShimmerBox(width: 200, height: 100),
              _ShimmerBox(width: 200, height: 100),
              _ShimmerBox(width: 200, height: 100),
            ],
          ),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ShimmerBox(width: 100, height: 36),
              SizedBox(width: 16),
              _ShimmerBox(width: 100, height: 36),
            ],
          )
        ],
      ),
    );
  }
}

class _TabsShimmer extends StatelessWidget {
  const _TabsShimmer();

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _ShimmerBox(width: 80, height: 30),
              SizedBox(width: 16),
              _ShimmerBox(width: 120, height: 30),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: size.width * 0.7,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
