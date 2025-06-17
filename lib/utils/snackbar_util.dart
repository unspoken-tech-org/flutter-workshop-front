import 'package:flutter/material.dart';

class SnackBarUtil {
  static final SnackBarUtil _instance = SnackBarUtil._internal();
  factory SnackBarUtil() => _instance;
  SnackBarUtil._internal();

  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  GlobalKey<ScaffoldMessengerState> get scaffoldKey => _scaffoldKey;

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

  void _showSnackBar(
    String message, {
    required Color backgroundColor,
    required Color textColor,
  }) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: textColor),
      ),
      width: 300,
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      // margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () {
          _scaffoldKey.currentState?.hideCurrentSnackBar();
        },
      ),
    );

    _scaffoldKey.currentState?.showSnackBar(snackBar);
  }
}
