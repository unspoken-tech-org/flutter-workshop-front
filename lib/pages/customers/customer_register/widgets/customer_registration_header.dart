import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';

class CustomerRegistrationHeader extends StatelessWidget {
  const CustomerRegistrationHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 4,
      children: [
        Row(
          children: [
            Text(
              'Cadastro de Cliente',
              style: WsTextStyles.h1,
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Por favor, preencha o formulário abaixo para registrar o cliente.',
                overflow: TextOverflow.ellipsis,
                style: WsTextStyles.subtitle2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
