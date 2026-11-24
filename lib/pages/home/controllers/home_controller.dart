import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/core/state/safe_change_notifier_mixin.dart';
import 'package:flutter_workshop_front/models/device_statistics/device_statistics.dart';
import 'package:flutter_workshop_front/services/device_statistics/device_statistics_service.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class HomeController extends ChangeNotifier with SafeChangeNotifierMixin {
  final DeviceStatisticsService _deviceStatisticsService =
      DeviceStatisticsService();

  HomeController();

  DeviceStatistics? deviceStatistics;
  String? errorMessage;
  bool isLoading = false;

  Future<void> getDeviceStatistics() async {
    if (isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      switch (await _deviceStatisticsService.getDeviceStatistics()) {
        case Ok(:final value):
          deviceStatistics = value;
        case Err(:final failure):
          final message = failure.messageOr(
            'Erro ao carregar estatísticas. Tente novamente.',
          );
          errorMessage = message;
          SnackBarUtil().showError(message);
          debugPrint(
            '[HomeController] Error getting device statistics: $failure',
          );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
