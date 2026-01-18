import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/offline_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final _apiService = ApiService();
  final _storageService = OfflineStorageService();

  User? _user;
  String? _phoneNumber;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;

  // Getters
  User? get user => _user;
  String? get phoneNumber => _phoneNumber;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  AuthProvider() {
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    await _storageService.init();
    final token = await _storageService.getAccessToken();
    if (token != null) {
      _apiService.setAccessToken(token);
      _isAuthenticated = true;
      _phoneNumber = await _storageService.getPhoneNumber();
      notifyListeners();
    }
  }

  Future<bool> requestOtp(String phoneNumber) async {
    try {
      _setLoading(true);
      _error = null;

      // Validate phone number format
      if (!phoneNumber.startsWith('+233') || phoneNumber.length != 13) {
        throw Exception('Invalid phone number. Use format +233XXXXXXXXX');
      }

      await _apiService.requestOtp(phoneNumber);
      _phoneNumber = phoneNumber;
      _setLoading(false);
      return true;
    } catch (e) {
      _handleError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOtp(String otpCode) async {
    try {
      _setLoading(true);
      _error = null;

      if (_phoneNumber == null) {
        throw Exception('Phone number not set');
      }

      final response = await _apiService.verifyOtp(_phoneNumber!, otpCode);

      // Save tokens
      await _storageService.saveAccessToken(response.accessToken);
      await _storageService.saveRefreshToken(response.refreshToken);
      await _storageService.saveUserId(response.userId);
      await _storageService.savePhoneNumber(_phoneNumber!);

      // Update API service
      _apiService.setAccessToken(response.accessToken);

      _isAuthenticated = true;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _handleError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _apiService.clearAccessToken();
    await _storageService.clearAuth();
    _isAuthenticated = false;
    _user = null;
    _phoneNumber = null;
    notifyListeners();
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) {
        await logout();
        return false;
      }

      final response = await _apiService.refreshAccessToken(refreshToken);
      await _storageService.saveAccessToken(response.accessToken);
      _apiService.setAccessToken(response.accessToken);
      return true;
    } catch (e) {
      _handleError(e);
      await logout();
      return false;
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
