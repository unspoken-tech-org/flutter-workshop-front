import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_workshop_front/pages/home/home_page.dart';
import 'package:flutter_workshop_front/pages/setup/setup_controller.dart';
import 'package:flutter_workshop_front/pages/setup/widgets/api_key_input.dart';
import 'package:flutter_workshop_front/pages/setup/widgets/setup_action_button.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

class SetupPage extends StatefulWidget {
  static const route = '/setup';
  final SetupController? controller;

  const SetupPage({super.key, this.controller});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final TextEditingController _apiKeyController = TextEditingController();
  late final SetupController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        SetupController(authService: context.read<AuthService>());
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<SetupController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7F9FC),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo / Branding Area
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB), // blue-600
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.dns, // Server icon equivalent
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Eletroluk Workshop',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1B1F),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gestão Inteligente de Sistemas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF49454F),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 440),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configuração Inicial',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1C1B1F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Para começar a utilizar o sistema, insira a chave de acesso fornecida pelo seu administrador.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF49454F),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ApiKeyInput(
                            controller: controller,
                            apiKeyController: _apiKeyController,
                            onSubmitted: () => _submit(context, controller),
                            onChanged: () => setState(() {}),
                          ),
                          const SizedBox(height: 24),
                          SetupActionButton(
                            controller: controller,
                            apiKeyController: _apiKeyController,
                            onPressed: () => _submit(context, controller),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                // Ação de ajuda
                              },
                              icon: const Icon(
                                Icons.help_outline,
                                size: 16,
                                color: Color(0xFF49454F),
                              ),
                              label: const Text(
                                'Onde encontro a minha chave?',
                                style: TextStyle(
                                  color: Color(0xFF49454F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                overlayColor:
                                    Colors.blue.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    const Text(
                      '© 2024 Eletroluk Workshop. Todos os direitos reservados.',
                      style: TextStyle(
                        color: Color(0xFF938F99),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(BuildContext context, SetupController controller) async {
    final success = await controller.authenticate(_apiKeyController.text);
    if (success && context.mounted) {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        context.go(HomePage.route);
      }
    }
  }
}
