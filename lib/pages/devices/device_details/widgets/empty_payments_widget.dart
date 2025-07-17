import 'package:flutter/material.dart';

class EmptyPaymentsWidget extends StatelessWidget {
  const EmptyPaymentsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Image.asset(
          'assets/images/empty_pockets.png',
          height: 250,
        ),
        const SizedBox(height: 16),
        Text(
          'Não há pagamentos para este aparelho',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}
