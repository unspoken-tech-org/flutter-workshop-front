import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/models/device_statistics/device_statistics.dart';
import 'package:flutter_workshop_front/services/device_statistics/device_statistics_service.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class HomeController extends ChangeNotifier {
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
      deviceStatistics = await _deviceStatisticsService.getDeviceStatistics();
    } on RequisitionException catch (e) {
      errorMessage = e.message;
      SnackBarUtil().showError(e.message);
      debugPrint('[HomeController] Error getting device statistics: $e');
    } catch (e) {
      errorMessage = 'Erro ao carregar estatísticas. Tente novamente.';
      SnackBarUtil().showError(errorMessage!);
      debugPrint('[HomeController] Error getting device statistics: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
