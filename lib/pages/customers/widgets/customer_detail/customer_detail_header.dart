import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';

class CustomerDetailHeader extends StatelessWidget {
  const CustomerDetailHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalhes do Cliente',
          style: WsTextStyles.h1,
        ),
        const SizedBox(height: 4),
        Text(
          'Abaixo estão os detalhes do cliente selecionado.',
          overflow: TextOverflow.ellipsis,
          style: WsTextStyles.subtitle2,
        ),
      ],
    );
  }
}
