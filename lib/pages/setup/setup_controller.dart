import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

class SetupController extends ChangeNotifier {
  final AuthService _authService;

  SetupController({AuthService? authService})
      : _authService = authService ?? AuthService();

  bool isLoading = false;

  bool isSuccess = false;
  String? errorMessage;

  Future<bool> authenticate(String apiKey) async {
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
      isLoading = false;
      isSuccess = true;
      notifyListeners();
      return true;
    } on RequisitionException catch (e) {
      isLoading = false;
      isSuccess = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      isLoading = false;
      isSuccess = false;
      errorMessage = 'Falha na autenticação. Verifique a chave e sua conexão.';
      notifyListeners();
      return false;
    }
  }
}
