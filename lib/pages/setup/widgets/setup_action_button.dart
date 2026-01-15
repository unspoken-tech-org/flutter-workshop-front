import 'package:flutter/material.dart';
import '../setup_controller.dart';

class SetupActionButton extends StatelessWidget {
  final SetupController controller;
  final TextEditingController apiKeyController;
  final VoidCallback onPressed;

  const SetupActionButton({
    super.key,
    required this.controller,
    required this.apiKeyController,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = controller.isSuccess;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            (controller.isLoading || apiKeyController.text.isEmpty || isSuccess)
                ? null
                : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSuccess ? Colors.green : const Color(0xFF2563EB),
          disabledBackgroundColor:
              isSuccess ? Colors.green : Colors.grey.shade200,
          disabledForegroundColor:
              isSuccess ? Colors.white : Colors.grey.shade500,
          elevation: (controller.isLoading || isSuccess) ? 0 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: controller.isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF49454F),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Conectando...'),
                ],
              )
            : isSuccess
                ? const Text(
                    'Conectado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Conectar ao Servidor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                    ],
                  ),
      ),
    );
  }
}
