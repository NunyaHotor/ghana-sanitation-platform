import 'package:hive_flutter/hive_flutter.dart';
import '../models/report.dart';

class OfflineStorageService {
  static const String reportBoxName = 'reports';
  static const String authBoxName = 'auth';

  late Box<Report> _reportBox;
  late Box _authBox;

  OfflineStorageService();

  Future<void> init() async {
    _reportBox = await Hive.openBox<Report>(reportBoxName);
    _authBox = await Hive.openBox(authBoxName);
  }

  // Report queue operations

  Future<void> saveReport(Report report) async {
    await _reportBox.put(report.localId ?? report.id ?? DateTime.now().toString(), report);
  }

  Future<void> deleteReport(String reportId) async {
    final key = _reportBox.keys.firstWhere(
      (k) => (_reportBox.get(k)?.id == reportId || _reportBox.get(k)?.localId == reportId),
      orElse: () => reportId,
    );
    await _reportBox.delete(key);
  }

  Future<Report?> getReport(String reportId) async {
    final key = _reportBox.keys.firstWhere(
      (k) => (_reportBox.get(k)?.id == reportId || _reportBox.get(k)?.localId == reportId),
      orElse: () => null,
    );
    if (key != null) {
      return _reportBox.get(key);
    }
    return null;
  }

  Future<List<Report>> getPendingReports() async {
    final reports = <Report>[];
    for (var report in _reportBox.values) {
      if (!report.isSynced) {
        reports.add(report);
      }
    }
    return reports;
  }

  Future<List<Report>> getAllReports() async {
    return List<Report>.from(_reportBox.values);
  }

  Future<void> updateReportSyncStatus(String reportId, bool synced) async {
    final key = _reportBox.keys.firstWhere(
      (k) => (_reportBox.get(k)?.id == reportId || _reportBox.get(k)?.localId == reportId),
      orElse: () => null,
    );
    if (key != null) {
      final report = _reportBox.get(key);
      if (report != null) {
        final updatedReport = report.copyWith(isSynced: synced);
        await _reportBox.put(key, updatedReport);
      }
    }
  }

  Future<void> clearSyncedReports() async {
    final keysToDelete = <dynamic>[];
    for (var key in _reportBox.keys) {
      final report = _reportBox.get(key);
      if (report != null && report.isSynced) {
        keysToDelete.add(key);
      }
    }
    await _reportBox.deleteAll(keysToDelete);
  }

  // Auth operations

  Future<void> saveAccessToken(String token) async {
    await _authBox.put('access_token', token);
  }

  Future<String?> getAccessToken() async {
    return _authBox.get('access_token');
  }

  Future<void> saveRefreshToken(String token) async {
    await _authBox.put('refresh_token', token);
  }

  Future<String?> getRefreshToken() async {
    return _authBox.get('refresh_token');
  }

  Future<void> saveUserId(String userId) async {
    await _authBox.put('user_id', userId);
  }

  Future<String?> getUserId() async {
    return _authBox.get('user_id');
  }

  Future<void> savePhoneNumber(String phoneNumber) async {
    await _authBox.put('phone_number', phoneNumber);
  }

  Future<String?> getPhoneNumber() async {
    return _authBox.get('phone_number');
  }

  Future<void> clearAuth() async {
    await _authBox.deleteAll(['access_token', 'refresh_token', 'user_id', 'phone_number']);
  }

  Future<void> clearAll() async {
    await _reportBox.clear();
    await _authBox.clear();
  }
}
