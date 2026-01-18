import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/constants.dart';
import '../models/auth_response.dart';
import '../models/report.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() =>
      'ApiException: $message ${statusCode != null ? '(Status: $statusCode)' : ''}';
}

class ApiService {
  late Dio _dio;
  String? _accessToken;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectionTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        contentType: 'application/json',
      ),
    );

    // Add request interceptor for auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Handle token expiration
            return handler.next(error);
          }
          return handler.next(error);
        },
      ),
    );
  }

  void setAccessToken(String token) {
    _accessToken = token;
  }

  void clearAccessToken() {
    _accessToken = null;
  }

  // Auth endpoints

  Future<OtpResponse> requestOtp(String phoneNumber) async {
    try {
      final response = await _dio.post(
        '/auth/request-otp',
        data: {'phone_number': phoneNumber},
      );
      return OtpResponse.fromJson(response.data);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<AuthResponse> verifyOtp(String phoneNumber, String otpCode) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {
          'phone_number': phoneNumber,
          'otp_code': otpCode,
        },
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<AuthResponse> refreshAccessToken(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      return AuthResponse.fromJson(response.data);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Report endpoints

  Future<Report> createReport({
    required String category,
    required double latitude,
    required double longitude,
    required double gpsAccuracy,
    required String capturedAt,
    String? description,
    bool anonymous = false,
    List<String>? photoPaths,
    List<String>? videoPaths,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      if ((photoPaths != null && photoPaths.isNotEmpty) || (videoPaths != null && videoPaths.isNotEmpty)) {
        // Multipart upload
        final formData = FormData.fromMap({
          'category': category,
          'latitude': latitude,
          'longitude': longitude,
          'gps_accuracy': gpsAccuracy,
          'captured_at': capturedAt,
          'description': description,
          'anonymous': anonymous,
        });

        if (photoPaths != null && photoPaths.isNotEmpty) {
          final List<MultipartFile> photos = [];
          for (final path in photoPaths) {
            try {
              photos.add(await MultipartFile.fromFile(path, filename: path.split(Platform.pathSeparator).last));
            } catch (_) {}
          }
          if (photos.isNotEmpty) {
            formData.files.add(MapEntry('photo', photos));
          }
        }

        if (videoPaths != null && videoPaths.isNotEmpty) {
          final List<MultipartFile> videos = [];
          for (final path in videoPaths) {
            try {
              videos.add(await MultipartFile.fromFile(path, filename: path.split(Platform.pathSeparator).last));
            } catch (_) {}
          }
          if (videos.isNotEmpty) {
            formData.files.add(MapEntry('video', videos));
          }
        }

        final response = await _dio.post('/reports', data: formData, onSendProgress: onSendProgress);
        return Report.fromJson(response.data);
      } else {
        final response = await _dio.post(
          '/reports',
          data: {
            'category': category,
            'latitude': latitude,
            'longitude': longitude,
            'gps_accuracy': gpsAccuracy,
            'captured_at': capturedAt,
            'description': description,
            'anonymous': anonymous,
            'photo_urls': photoPaths,
            'video_urls': videoPaths,
          },
        );
        return Report.fromJson(response.data);
      }
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<Report> getReport(String reportId) async {
    try {
      final response = await _dio.get('/reports/$reportId');
      return Report.fromJson(response.data);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> listReports({
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final params = {
        'limit': limit,
        'offset': offset,
      };
      if (category != null) {
        params['category'] = category;
      }

      final response = await _dio.get(
        '/reports',
        queryParameters: params,
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getReportsByLocation({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    int zoomLevel = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/reports/analytics/heatmap',
        queryParameters: {
          'min_lat': minLat,
          'max_lat': maxLat,
          'min_lon': minLon,
          'max_lon': maxLon,
          'zoom_level': zoomLevel,
        },
      );
      return response.data;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void _handleError(dynamic error) {
    if (error is DioException) {
      String message = 'An error occurred';

      if (error.response != null) {
        message = error.response?.data['message'] ??
            error.response?.statusMessage ??
            message;
      } else if (error.type == DioExceptionType.connectionTimeout) {
        message = 'Connection timeout. Please check your internet.';
      } else if (error.type == DioExceptionType.receiveTimeout) {
        message = 'Request timeout. Please try again.';
      } else if (error.type == DioExceptionType.unknown) {
        message = 'Network error. Please check your internet connection.';
      }

      throw ApiException(
        message: message,
        statusCode: error.response?.statusCode,
        originalError: error,
      );
    }
  }
}
