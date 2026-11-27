import 'dart:async';

import 'package:flutter/material.dart';

class SnackBarUtil {
  static final SnackBarUtil _instance = SnackBarUtil._internal();
  factory SnackBarUtil() => _instance;
  SnackBarUtil._internal();

  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  GlobalKey<ScaffoldMessengerState> get scaffoldKey => _scaffoldKey;
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  OverlayEntry? _activeOverlayEntry;
  Timer? _overlayTimer;

  static const _animationStyle = AnimationStyle(
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
    duration: Duration(milliseconds: 600),
    reverseDuration: Duration(milliseconds: 600),
  );

  void showSuccess(String message) {
    _showSnackBar(
      message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  void showError(String message) {
    _showSnackBar(
      message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  void showInfo(String message) {
    _showSnackBar(
      message,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );
  }

  void showWarning(String message) {
    _showSnackBar(
      message,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }

  /// Esconde a mensagem exibida agora, se houver.
  void hideCurrent() {
    _removeActiveOverlay();
    _scaffoldKey.currentState?.hideCurrentSnackBar();
  }

  void _showSnackBar(
    String message, {
    required Color backgroundColor,
    required Color textColor,
  }) {
    final overlay = _navigatorKey.currentState?.overlay;
    if (overlay != null) {
      _removeActiveOverlay();
      final entry = OverlayEntry(
        builder: (context) => Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Center(
            child: Material(
              color: Colors.transparent,
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(message, style: TextStyle(color: textColor)),
              ),
            ),
          ),
        ),
      );
      _activeOverlayEntry = entry;
      overlay.insert(entry);
      _overlayTimer = Timer(const Duration(seconds: 3), _removeActiveOverlay);
      return;
    }

    final snackBar = SnackBar(
      content: Text(message, style: TextStyle(color: textColor)),
      width: 300,
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 3),
    );

    _scaffoldKey.currentState?.removeCurrentSnackBar();
    _scaffoldKey.currentState?.showSnackBar(
      snackBar,
      snackBarAnimationStyle: _animationStyle,
    );
  }

  void _removeActiveOverlay() {
    _overlayTimer?.cancel();
    _overlayTimer = null;
    _activeOverlayEntry?.remove();
    _activeOverlayEntry = null;
  }
}
