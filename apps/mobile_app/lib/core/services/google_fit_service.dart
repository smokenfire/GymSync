import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class GoogleFitService {
  final Health _health = Health();

  final List<HealthDataType> _types = [
    HealthDataType.WORKOUT,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.HEART_RATE,
  ];

  static Future<bool> requestPermission({bool preferSamsung = false}) async {
    // Permissões obrigatórias
    List<Permission> permissions = [
      Permission.activityRecognition,
      Permission.sensors,
      Permission.locationWhenInUse,
    ];
    if (Platform.isAndroid && (await _isAndroid13OrUp())) {
      permissions.add(Permission.notification);
    }

    final statuses = await permissions.request();
    if (statuses.values.any((status) => !status.isGranted)) {
      return false;
    }

    // Solicita autorização do Google Fit ou Samsung Health
    return await GoogleFitService().requestPermissions(preferSamsung: preferSamsung);
  }

  Future<bool> requestPermissions({bool preferSamsung = false}) async {
    final bool requested = await _health.requestAuthorization(
      _types,
      permissions: _types.map((e) => HealthDataAccess.READ).toList(),
    );
    return requested;
  }

  static Future<bool> _isAndroid13OrUp() async {
    if (!Platform.isAndroid) return false;
    // Android 13 = SDK 33, mas o package_info_plus ou device_info_plus pode ser usado aqui.
    // Para simplificação do exemplo, sempre pede notification se Android.
    return true;
  }

  Future<bool> checkAllPermissionsGranted() async {
    try {
      final now = DateTime.now();
      await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: now.subtract(const Duration(minutes: 1)),
        endTime: now,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Retorna o exercício atual detalhado, se houver um em andamento
  Future<Map<String, dynamic>?> getCurrentExerciseDetailed() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 6));
    final workouts = await _health.getHealthDataFromTypes(
      types: [HealthDataType.WORKOUT],
      startTime: start,
      endTime: now,
    );
    final ongoing = workouts.cast<HealthDataPoint?>().firstWhere(
      (point) => point != null && (point.dateTo == null || point.dateTo!.isAfter(now)),
      orElse: () => null,
    );
    if (ongoing == null) return null;
    return {
      'exerciseType': ongoing.typeString,
      'value': ongoing.value,
      'unit': ongoing.unitString,
      'startTime': ongoing.dateFrom.toIso8601String(),
      'endTime': ongoing.dateTo?.toIso8601String(),
      'source': ongoing.sourceName,
      'metadata': ongoing.metadata.toString(),
    };
  }

  /// Verifica se há algum exercício ativo atualmente (ex: caminhada, corrida, etc)
  Future<String?> getCurrentActiveExerciseType() async {
    final exercise = await getCurrentExerciseDetailed();
    if (exercise != null) {
      return exercise['exerciseType'];
    }
    return null;
  }
}