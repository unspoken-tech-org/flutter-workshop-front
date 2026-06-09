import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/shimmer_container.dart';

class DeviceRegisterShimmer extends StatelessWidget {
  const DeviceRegisterShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderShimmer(),
            SizedBox(height: 16),
            _CustomerInfosShimmer(),
            SizedBox(height: 16),
            _ProblemDescriptionShimmer(),
            SizedBox(height: 16),
            _DeviceDetailsShimmer(),
            SizedBox(height: 16),
            _TechnicianAndUrgencyShimmer(),
            SizedBox(height: 16),
            _ActionButtonsShimmer(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _HeaderShimmer extends StatelessWidget {
  const _HeaderShimmer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ShimmerContainer(width: 32, height: 32, borderRadius: 8),
            SizedBox(width: 8),
            ShimmerContainer(width: 250, height: 28),
          ],
        ),
        SizedBox(height: 8),
        ShimmerContainer(width: 300, height: 18),
      ],
    );
  }
}

class _CustomerInfosShimmer extends StatelessWidget {
  const _CustomerInfosShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerContainer(width: 24, height: 24),
              SizedBox(width: 16),
              ShimmerContainer(width: 180, height: 20),
            ],
          ),
          SizedBox(height: 16),
          ShimmerContainer(width: double.infinity, height: 48),
        ],
      ),
    );
  }
}

class _ProblemDescriptionShimmer extends StatelessWidget {
  const _ProblemDescriptionShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerContainer(width: 24, height: 24),
              SizedBox(width: 8),
              ShimmerContainer(width: 200, height: 20),
            ],
          ),
          SizedBox(height: 16),
          ShimmerContainer(width: double.infinity, height: 72),
          SizedBox(height: 16),
          ShimmerContainer(width: double.infinity, height: 72),
        ],
      ),
    );
  }
}

class _DeviceDetailsShimmer extends StatelessWidget {
  const _DeviceDetailsShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerContainer(width: 24, height: 24),
              SizedBox(width: 8),
              ShimmerContainer(width: 200, height: 20),
            ],
          ),
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ShimmerContainer(width: double.infinity, height: 74)),
              SizedBox(width: 16),
              Expanded(child: ShimmerContainer(width: double.infinity, height: 74)),
            ],
          ),
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ShimmerContainer(width: double.infinity, height: 74)),
              SizedBox(width: 16),
              Expanded(child: ShimmerContainer(width: double.infinity, height: 74)),
            ],
          ),
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ShimmerContainer(width: double.infinity, height: 74)),
              SizedBox(width: 16),
              Expanded(child: ShimmerContainer(width: double.infinity, height: 74)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TechnicianAndUrgencyShimmer extends StatelessWidget {
  const _TechnicianAndUrgencyShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerContainer(width: 24, height: 24),
              SizedBox(width: 8),
              ShimmerContainer(width: 200, height: 20),
            ],
          ),
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: ShimmerContainer(width: double.infinity, height: 48),
              ),
              SizedBox(width: 20),
              Flexible(
                child: ShimmerContainer(width: double.infinity, height: 52),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButtonsShimmer extends StatelessWidget {
  const _ActionButtonsShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ShimmerContainer(width: 120, height: 44, borderRadius: 6),
            SizedBox(width: 16),
            ShimmerContainer(width: 220, height: 44, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}
