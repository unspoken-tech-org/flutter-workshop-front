import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';

class DeviceCustomerCancelButton extends StatelessWidget {
  final VoidCallback onCancel;

  /// Salvamento em andamento: cancelar agora sairia da edição com o save
  /// ainda rodando, então o botão fica desabilitado.
  final bool isSaving;
  const DeviceCustomerCancelButton({
    super.key,
    required this.onCancel,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'deviceDetail.cancel',
      child: TextButton.icon(
        onPressed: isSaving ? null : onCancel,
        icon: const Icon(Icons.close),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.grey.shade500,
          disabledBackgroundColor: Colors.grey.shade300,
          iconColor: Colors.white,
        ),
        label: Text(
          'Cancelar',
          style: WsTextStyles.body1.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
