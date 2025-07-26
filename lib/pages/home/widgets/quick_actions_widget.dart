import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/pages/home/widgets/fast_action_button_widget.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.add_circle_outline, size: 20),
                SizedBox(width: 8),
                Text(
                  'Ações Rápidas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              spacing: 16,
              children: [
                Expanded(
                  child: FastActionButtonWidget(
                    title: 'Cadastrar Aparelho',
                    description: 'Registrar novo aparelho para reparo',
                    icon: Icons.microwave_outlined,
                    color: const Color(0xFF3B82F6),
                    onPressed: () {
                      WsNavigator.pushDeviceRegister(context);
                    },
                  ),
                ),
                Expanded(
                  child: FastActionButtonWidget(
                    title: 'Novo Cliente',
                    description: 'Adicionar cliente ao sistema',
                    icon: Icons.people,
                    color: const Color(0xFF22C55E),
                    onPressed: () {
                      WsNavigator.pushCustomerRegister(context);
                    },
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
