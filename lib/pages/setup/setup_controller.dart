import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

class SetupController extends ChangeNotifier {
  final AuthService _authService;

  SetupController({required AuthService authService})
    : _authService = authService;

  bool isLoading = false;
  bool isSuccess = false;

  String apiKey = '';
  String? errorMessage;

  Future<String?> get storedApiKey async => await _authService.apiKey;

  Future<void> init() async {
    apiKey = await storedApiKey ?? '';
    notifyListeners();
  }

  Future<bool> authenticate(String apiKey) async {
    if (isLoading) return false;
    if (apiKey.trim().isEmpty) {
      errorMessage = 'A API Key não pode estar vazia.';
      isSuccess = false;
      notifyListeners();
      return false;
    }

    isLoading = true;
    isSuccess = false;
    errorMessage = null;
    notifyListeners();

    try {
      await _authService.authenticate(apiKey);
      isSuccess = true;
      return true;
    } on RequisitionException catch (e) {
      isSuccess = false;
      errorMessage = e.message;
      return false;
    } catch (e) {
      isSuccess = false;
      errorMessage = 'Falha na autenticação. Verifique a chave e sua conexão.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
