import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CustomerDevicePageShimmer extends StatelessWidget {
  const CustomerDevicePageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _CustomerDeviceInfosShimmer()),
                    SizedBox(width: 20),
                    Expanded(flex: 2, child: _CustomerDevicePaymentsShimmer()),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _DeviceTabsShimmer(),
              ),
            ],
          ),
        ),
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

// Shimmer for CustomerDeviceInfosWidget
class _CustomerDeviceInfosShimmer extends StatelessWidget {
  const _CustomerDeviceInfosShimmer();

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
          _CustomerDeviceInfoHeaderShimmer(),
          SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Column(
                  children: [
                    _DeviceDetailsShimmer(),
                    SizedBox(height: 28),
                    _DiagnosticDeviceInfoShimmer(),
                  ],
                ),
              ),
              SizedBox(width: 28),
              Flexible(
                child: Column(
                  children: [
                    _DeviceValuesShimmer(),
                    SizedBox(height: 28),
                    _CustomerDeviceObservationShimmer(),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(color: Colors.white),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ShimmerBox(width: 120, height: 36),
            ],
          )
        ],
      ),
    );
  }
}

class _CustomerDeviceInfoHeaderShimmer extends StatelessWidget {
  const _CustomerDeviceInfoHeaderShimmer();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBox(width: 150, height: 20),
            SizedBox(height: 8),
            _ShimmerBox(width: 250, height: 18),
            SizedBox(height: 8),
            _ShimmerBox(width: 180, height: 16),
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
                _ShimmerBox(width: 20, height: 20, borderRadius: 10),
                SizedBox(width: 8),
                _ShimmerBox(width: 120, height: 16),
              ],
            )
          ],
        )
      ],
    );
  }
}

class _DeviceDetailsShimmer extends StatelessWidget {
  const _DeviceDetailsShimmer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBox(width: 120, height: 18),
        SizedBox(height: 16),
        _ShimmerBox(width: double.infinity, height: 40),
        SizedBox(height: 16),
        _ShimmerBox(width: double.infinity, height: 40),
        SizedBox(height: 16),
        _ShimmerBox(width: double.infinity, height: 40),
      ],
    );
  }
}

class _DiagnosticDeviceInfoShimmer extends StatelessWidget {
  const _DiagnosticDeviceInfoShimmer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBox(width: 150, height: 18),
        SizedBox(height: 16),
        _ShimmerBox(width: double.infinity, height: 80),
        SizedBox(height: 16),
        _ShimmerBox(width: 120, height: 40),
      ],
    );
  }
}

class _DeviceValuesShimmer extends StatelessWidget {
  const _DeviceValuesShimmer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBox(width: 120, height: 18),
        SizedBox(height: 16),
        _ShimmerBox(width: double.infinity, height: 40),
        SizedBox(height: 16),
        _ShimmerBox(width: double.infinity, height: 40),
        SizedBox(height: 16),
        Row(
          children: [
            _ShimmerBox(width: 24, height: 24),
            SizedBox(width: 8),
            _ShimmerBox(width: 150, height: 16),
          ],
        ),
      ],
    );
  }
}

class _CustomerDeviceObservationShimmer extends StatelessWidget {
  const _CustomerDeviceObservationShimmer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBox(width: 150, height: 18),
        SizedBox(height: 16),
        _ShimmerBox(width: double.infinity, height: 128),
      ],
    );
  }
}

// Shimmer for CustomerDevicePayments
class _CustomerDevicePaymentsShimmer extends StatelessWidget {
  const _CustomerDevicePaymentsShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          _PaymentsHeaderShimmer(),
          SizedBox(height: 24),
          _PaymentItemShimmer(),
          SizedBox(height: 8),
          _PaymentItemShimmer(),
          SizedBox(height: 8),
          _PaymentItemShimmer(),
          SizedBox(height: 24),
          _PaymentTotalsShimmer(),
        ],
      ),
    );
  }
}

class _PaymentsHeaderShimmer extends StatelessWidget {
  const _PaymentsHeaderShimmer();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _ShimmerBox(width: 24, height: 24),
            SizedBox(width: 8),
            _ShimmerBox(width: 120, height: 20),
          ],
        ),
        _ShimmerBox(width: 110, height: 36),
      ],
    );
  }
}

class _PaymentItemShimmer extends StatelessWidget {
  const _PaymentItemShimmer();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ShimmerBox(width: 100, height: 16),
        _ShimmerBox(width: 80, height: 16),
      ],
    );
  }
}

class _PaymentTotalsShimmer extends StatelessWidget {
  const _PaymentTotalsShimmer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Divider(color: Colors.white),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ShimmerBox(width: 120, height: 18),
            _ShimmerBox(width: 90, height: 18),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ShimmerBox(width: 100, height: 16),
            _ShimmerBox(width: 80, height: 16),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ShimmerBox(width: 100, height: 16),
            _ShimmerBox(width: 80, height: 16),
          ],
        ),
      ],
    );
  }
}

// Shimmer for DeviceTabsWidget
class _DeviceTabsShimmer extends StatelessWidget {
  const _DeviceTabsShimmer();

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SizedBox(
      height: 514,
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
              width: size.width,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              // We'll just shimmer the first tab's content
              // as they will likely have similar layouts
              child: const _CustomerContactsShimmer(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerContactsShimmer extends StatelessWidget {
  const _CustomerContactsShimmer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _ShimmerBox(width: 150, height: 40),
          ],
        ),
        SizedBox(height: 16),
        Expanded(
          child: Column(
            children: [
              _ContactCardShimmer(),
              SizedBox(height: 16),
              _ContactCardShimmer(),
              SizedBox(height: 16),
              _ContactCardShimmer(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactCardShimmer extends StatelessWidget {
  const _ContactCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShimmerBox(width: 150, height: 18),
              _ShimmerBox(width: 80, height: 16),
            ],
          ),
          SizedBox(height: 12),
          _ShimmerBox(width: double.infinity, height: 40),
        ],
      ),
    );
  }
}
