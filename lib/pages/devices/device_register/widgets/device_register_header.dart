import 'package:flutter/material.dart';

class DeviceRegisterHeader extends StatelessWidget {
  const DeviceRegisterHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(Icons.local_laundry_service, size: 32),
            Text(
              'Cadastro de Aparelho',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          'Registre os detalhes do aparelho e do serviço solicitado',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
