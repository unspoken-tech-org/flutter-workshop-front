import 'package:flutter/material.dart';
import '../setup_controller.dart';

class ApiKeyInput extends StatelessWidget {
  final SetupController controller;
  final TextEditingController apiKeyController;
  final VoidCallback onSubmitted;
  final VoidCallback onChanged;

  const ApiKeyInput({
    super.key,
    required this.controller,
    required this.apiKeyController,
    required this.onSubmitted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = controller.errorMessage != null;
    final isSuccess = controller.isSuccess;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasError
                      ? Colors.red
                      : isSuccess
                          ? Colors.green
                          : const Color(0xFF79747E),
                  width: hasError || isSuccess ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: apiKeyController,
                obscureText: true,
                enabled: !controller.isLoading && !controller.isSuccess,
                onSubmitted: (_) => onSubmitted(),
                style: TextStyle(
                  color: isSuccess ? Colors.green.shade700 : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Insira a sua Chave de API',
                  hintStyle: const TextStyle(color: Color(0xFF49454F)),
                  prefixIcon: Icon(
                    Icons.vpn_key,
                    color: apiKeyController.text.isNotEmpty || isSuccess
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF49454F),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
            Positioned(
              left: 12,
              top: -10,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: const Text(
                  'Chave de API',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        if (isSuccess)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conexão estabelecida com sucesso! Redirecionando...',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
