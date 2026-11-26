import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/security/auth_notifier.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';

/// Fake tipado de [AuthService] para testes unitários e de widget.
class FakeAuthService extends Fake implements AuthService {
  FakeAuthService({
    this.authNotifier,
    this.storedApiKey,
    this.hasValidSession = false,
    this.admin = false,
    this.nextAuthState = AuthRouteState.authenticated,
    this.onAuthenticate,
    this.onInitializeAuthState,
    this.onLogout,
  });

  final AuthNotifier? authNotifier;
  String? storedApiKey;
  bool hasValidSession;
  bool admin;
  AuthRouteState nextAuthState;

  Future<void> Function(String apiKey)? onAuthenticate;
  Future<AuthRouteState> Function()? onInitializeAuthState;
  Future<void> Function()? onLogout;

  String? lastApiKey;
  int authenticateCalls = 0;
  int initializeCalls = 0;
  int logoutCalls = 0;
  int forceLogoutCalls = 0;

  @override
  Future<String?> get apiKey async => storedApiKey;

  @override
  Future<bool> get hasApiKey async => storedApiKey != null;

  @override
  Future<bool> get hasSession async => hasValidSession;

  @override
  Future<bool> get isAdmin async => admin;

  @override
  Future<void> authenticate(String apiKey) async {
    authenticateCalls++;
    lastApiKey = apiKey;
    if (onAuthenticate != null) {
      await onAuthenticate!(apiKey);
    }
  }

  @override
  Future<AuthRouteState> initializeAuthState() async {
    initializeCalls++;
    final state = onInitializeAuthState != null
        ? await onInitializeAuthState!()
        : nextAuthState;
    authNotifier?.setState(state);
    return state;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (onLogout != null) {
      await onLogout!();
    }
  }

  @override
  Future<void> forceLogout() async {
    forceLogoutCalls++;
  }
}
