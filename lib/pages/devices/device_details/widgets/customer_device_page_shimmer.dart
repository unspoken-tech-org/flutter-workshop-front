import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/shimmer_container.dart';

class CustomerDevicePageShimmer extends StatelessWidget {
  const CustomerDevicePageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 1010,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _CustomerDeviceInfosShimmer()),
                  SizedBox(width: 20),
                  Expanded(flex: 1, child: _CustomerDevicePaymentsShimmer()),
                ],
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 750,
              child: _DeviceTabsShimmer(),
            ),
          ],
        ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
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
          Spacer(),
          Divider(height: 1),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ShimmerContainer(width: 120, height: 40, borderRadius: 8),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerContainer(width: 250, height: 24),
            Row(
              children: [
                ShimmerContainer(width: 80, height: 28, borderRadius: 16),
                SizedBox(width: 8),
                ShimmerContainer(width: 80, height: 28, borderRadius: 16),
                SizedBox(width: 8),
                ShimmerContainer(width: 100, height: 28, borderRadius: 16),
              ],
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            ShimmerContainer(width: 200, height: 16),
            SizedBox(width: 32),
            ShimmerContainer(width: 250, height: 16),
          ],
        ),
      ],
    );
  }
}

class _DeviceDetailsShimmer extends StatelessWidget {
  const _DeviceDetailsShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ShimmerContainer(width: 24, height: 24),
            SizedBox(width: 12),
            ShimmerContainer(width: 200, height: 18),
          ]),
          SizedBox(height: 24),
          ShimmerContainer(width: double.infinity, height: 50),
          SizedBox(height: 16),
          ShimmerContainer(width: double.infinity, height: 50),
          SizedBox(height: 16),
          ShimmerContainer(width: double.infinity, height: 50),
        ],
      ),
    );
  }
}

class _DiagnosticDeviceInfoShimmer extends StatelessWidget {
  const _DiagnosticDeviceInfoShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ShimmerContainer(width: 24, height: 24),
            SizedBox(width: 12),
            ShimmerContainer(width: 150, height: 18),
          ]),
          SizedBox(height: 24),
          ShimmerContainer(width: double.infinity, height: 80),
          SizedBox(height: 16),
          ShimmerContainer(width: double.infinity, height: 80),
        ],
      ),
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
        ShimmerContainer(width: 120, height: 18),
        SizedBox(height: 16),
        ShimmerContainer(width: double.infinity, height: 40),
        SizedBox(height: 16),
        ShimmerContainer(width: double.infinity, height: 40),
        SizedBox(height: 16),
        Row(
          children: [
            ShimmerContainer(width: 24, height: 24),
            SizedBox(width: 8),
            ShimmerContainer(width: 150, height: 16),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ShimmerContainer(width: 24, height: 24),
            SizedBox(width: 12),
            ShimmerContainer(width: 150, height: 18),
          ]),
          SizedBox(height: 24),
          ShimmerContainer(width: double.infinity, height: 128),
        ],
      ),
    );
  }
}

// Shimmer for CustomerDevicePayments
class _CustomerDevicePaymentsShimmer extends StatelessWidget {
  const _CustomerDevicePaymentsShimmer();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _PaymentsHeaderShimmer(),
            SizedBox(height: 24),
            Expanded(
              child: Column(
                children: [
                  _PaymentItemShimmer(),
                  SizedBox(height: 8),
                  _PaymentItemShimmer(),
                  SizedBox(height: 8),
                  _PaymentItemShimmer(),
                ],
              ),
            ),
            SizedBox(height: 24),
            _PaymentTotalsShimmer(),
          ],
        ),
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
            ShimmerContainer(width: 24, height: 24),
            SizedBox(width: 8),
            ShimmerContainer(width: 120, height: 20),
          ],
        ),
        ShimmerContainer(width: 110, height: 36, borderRadius: 6),
      ],
    );
  }
}

class _PaymentItemShimmer extends StatelessWidget {
  const _PaymentItemShimmer();

  @override
  Widget build(BuildContext context) {
    return const HoverableCard(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ShimmerContainer(width: 36, height: 36, borderRadius: 8),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerContainer(width: 80, height: 12),
                  SizedBox(height: 6),
                  ShimmerContainer(width: 60, height: 16, borderRadius: 16),
                ],
              )
            ],
          ),
          ShimmerContainer(width: 90, height: 20),
        ],
      ),
    );
  }
}

class _PaymentTotalsShimmer extends StatelessWidget {
  const _PaymentTotalsShimmer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Divider(),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShimmerContainer(width: 80, height: 16),
            ShimmerContainer(width: 90, height: 16),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShimmerContainer(width: 70, height: 16),
            ShimmerContainer(width: 90, height: 16),
          ],
        ),
        SizedBox(height: 8),
        Divider(),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShimmerContainer(width: 50, height: 18),
            ShimmerContainer(width: 100, height: 18),
          ],
        ),
        SizedBox(height: 16),
        ShimmerContainer(
          width: double.infinity,
          height: 60,
          borderRadius: 8,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            ShimmerContainer(width: 120, height: 40, borderRadius: 8),
            SizedBox(width: 16),
            ShimmerContainer(width: 120, height: 40, borderRadius: 8),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const _CustomerContactsShimmer(),
          ),
        ),
      ],
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
            ShimmerContainer(width: 180, height: 40, borderRadius: 8),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerContainer(width: 150, height: 16),
                        SizedBox(height: 8),
                        ShimmerContainer(width: 250, height: 16),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                ShimmerContainer(width: double.infinity, height: 100),
              ],
            ),
          ),
          SizedBox(width: 16),
          Column(
            children: [
              ShimmerContainer(width: 90, height: 28, borderRadius: 20),
              SizedBox(height: 8),
              ShimmerContainer(width: 90, height: 24, borderRadius: 4),
            ],
          )
        ],
      ),
    );
  }
}

class HoverableCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const HoverableCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(0),
        child: child,
      ),
    );
  }
}
