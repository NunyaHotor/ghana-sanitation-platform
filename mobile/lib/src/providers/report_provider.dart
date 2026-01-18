import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/report.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';

class ReportProvider extends ChangeNotifier {
  final _apiService = ApiService();
  final OfflineStorageService _storageService = OfflineStorageService();

  List<Report> _reports = [];
  Map<String, double> _uploadProgress = {};
  bool _isLoading = false;
  String? _error;

  static const int maxRetries = 5;
  static const int maxBackoffSeconds = 300; // 5 minutes

  ReportProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _storageService.init();
    await loadLocalReports();
  }

  // Getters
  List<Report> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double getUploadProgress(String key) => _uploadProgress[key] ?? 0.0;

  Future<bool> submitReport({
    required String category,
    required double latitude,
    required double longitude,
    required double gpsAccuracy,
    required String capturedAt,
    String? description,
    bool anonymous = false,
    List<String>? photoPaths,
    List<String>? videoPaths,
    void Function(double progress)? onProgress,
    required bool isOnline,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      if (isOnline) {
        final tempKey = const Uuid().v4();
        _uploadProgress[tempKey] = 0.0;
        notifyListeners();

        final response = await _apiService.createReport(
          category: category,
          latitude: latitude,
          longitude: longitude,
          gpsAccuracy: gpsAccuracy,
          capturedAt: capturedAt,
          description: description,
          anonymous: anonymous,
          photoPaths: photoPaths,
          videoPaths: videoPaths,
          onSendProgress: (sent, total) {
            if (total > 0) {
              final progress = sent / total;
              if (onProgress != null) onProgress(progress);
              _uploadProgress[tempKey] = progress;
              notifyListeners();
            }
          },
        );

        // Persist server response
        await _storageService.saveReport(response);
        _reports.insert(0, response);

        final realKey = response.id ?? tempKey;
        _uploadProgress[realKey] = 1.0;
        if (tempKey != realKey) _uploadProgress.remove(tempKey);

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        // Queue for offline submission
        final localId = const Uuid().v4();
        final report = Report(
          localId: localId,
          category: category,
          latitude: latitude,
          longitude: longitude,
          gpsAccuracy: gpsAccuracy,
          capturedAt: capturedAt,
          description: description,
          anonymous: anonymous,
          isSynced: false,
          photoUrls: photoPaths,
          videoUrls: videoPaths,
        );

        await _storageService.saveReport(report);
        _reports.insert(0, report);
        _setLoading(false);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _handleError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadLocalReports() async {
    try {
      final reports = await _storageService.getAllReports();
      _reports = reports.reversed.toList();
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<bool> getReportStatus(String reportId) async {
    try {
      _setLoading(true);
      final report = await _apiService.getReport(reportId);
      await _storageService.saveReport(report);
      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index >= 0) _reports[index] = report;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _handleError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Sync pending reports with retry/backoff. Reports that exceed [maxRetries]
  /// are marked as failed (report.failed == true) and skipped until manual retry.
  Future<bool> syncPendingReports() async {
    try {
      _setLoading(true);
      final pending = await _storageService.getPendingReports();

      for (final report in pending) {
        // Skip reports explicitly marked failed
        if (report.failed == true) continue;

        // If there was a previous attempt, check backoff window
        final now = DateTime.now().millisecondsSinceEpoch;
        if (report.retryCount > 0 && report.lastAttemptAt != null) {
          final elapsed = now - (report.lastAttemptAt ?? 0);
          final backoff = _computeBackoff(report.retryCount) * 1000;
          if (elapsed < backoff) {
            // Not yet ready to retry
            continue;
          }
        }

        try {
          // mark attempt
          final attempted = report.copyWith(
            retryCount: report.retryCount + 1,
            lastAttemptAt: DateTime.now().millisecondsSinceEpoch,
          );
          await _storageService.saveReport(attempted);

          final synced = await _apiService.createReport(
            category: report.category,
            latitude: report.latitude,
            longitude: report.longitude,
            gpsAccuracy: report.gpsAccuracy,
            capturedAt: report.capturedAt,
            description: report.description,
            anonymous: report.anonymous,
            photoPaths: report.photoUrls,
            videoPaths: report.videoUrls,
          );

          // mark synced
          await _storageService.updateReportSyncStatus(
            report.localId ?? report.id ?? '',
            true,
          );

          await _storageService.saveReport(synced);
        } catch (e) {
          // increment retry count and possibly mark failed
          final current = await _storageService.getReport(report.localId ?? report.id ?? '');
          int retries = (current?.retryCount ?? report.retryCount) + 1;
          final failed = retries >= maxRetries;
          final updated = (current ?? report).copyWith(
            retryCount: retries,
            lastAttemptAt: DateTime.now().millisecondsSinceEpoch,
            failed: failed,
          );
          await _storageService.saveReport(updated);
          debugPrint('Failed to sync report: $e');
        }
      }

      await loadLocalReports();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _handleError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> retryReport(String localOrId) async {
    final r = await _storageService.getReport(localOrId);
    if (r == null) return;
    final reset = r.copyWith(retryCount: 0, lastAttemptAt: null, failed: false);
    await _storageService.saveReport(reset);
    await syncPendingReports();
  }

  Future<void> cancelReport(String localOrId) async {
    await _storageService.deleteReport(localOrId);
    _reports.removeWhere((r) => r.id == localOrId || r.localId == localOrId);
    notifyListeners();
  }

  int _computeBackoff(int retryCount) {
    // exponential backoff: min(maxBackoffSeconds, 2^(retryCount) * 2)
    final secs = min(maxBackoffSeconds, pow(2, retryCount) * 2).toInt();
    return secs;
  }

  Future<void> deleteReport(String reportId) async {
    try {
      await _storageService.deleteReport(reportId);
      _reports.removeWhere((r) => r.id == reportId || r.localId == reportId);
      notifyListeners();
    } catch (e) {
      _handleError(e);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _handleError(dynamic error) {
    _error = error.toString();
    notifyListeners();
  }
}
