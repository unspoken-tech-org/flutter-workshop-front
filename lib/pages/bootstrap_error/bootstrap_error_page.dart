import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

class BootstrapErrorPage extends StatefulWidget {
  static const route = '/bootstrap-error';

  const BootstrapErrorPage({super.key});

  @override
  State<BootstrapErrorPage> createState() => _BootstrapErrorPageState();
}

class _BootstrapErrorPageState extends State<BootstrapErrorPage> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      await context.read<AuthService>().initializeAuthState();
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  void _goToSetup() {
    if (_isRetrying) return;
    context.read<AuthNotifier>().setState(AuthRouteState.needsSetup);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>().state;
    final isStorageError = authState == AuthRouteState.storageError;

    final icon = isStorageError
        ? Icons.lock_outline_rounded
        : Icons.cloud_off_rounded;
    final iconBgColor = isStorageError
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFFEF3C7);
    final iconColor = isStorageError
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);

    final title = isStorageError
        ? 'Erro ao acessar credenciais'
        : 'Sem conexão com o servidor';
    final description = isStorageError
        ? 'Não foi possível acessar as credenciais salvas neste dispositivo. Tente novamente ou configure uma nova chave de acesso.'
        : 'Não foi possível conectar ao servidor para validar sua sessão. Verifique sua internet e tente novamente.';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 32),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1B1F),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF49454F),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isRetrying ? null : _retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade500,
                      elevation: _isRetrying ? 0 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: _isRetrying
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF49454F),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Tentando...'),
                            ],
                          )
                        : const Text(
                            'Tentar novamente',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: _isRetrying ? null : _goToSetup,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF49454F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: const Text(
                      'Configurar outra chave',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
