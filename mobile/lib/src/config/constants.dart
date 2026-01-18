class ApiConstants {
  // Backend Server
  static const String baseUrl = 'http://localhost:3000/api/v1';
  
  // Endpoints
  static const String requestOtp = '$baseUrl/auth/request-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String refreshToken = '$baseUrl/auth/refresh';
  static const String createReport = '$baseUrl/reports';
  static const String getReport = '$baseUrl/reports';
  static const String listReports = '$baseUrl/reports';
  static const String reportHeatmap = '$baseUrl/reports/analytics/heatmap';

  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

class StorageKeys {
  // Auth tokens
  static const String accessToken = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userId = 'user_id';
  static const String phoneNumber = 'phone_number';
  static const String expiresIn = 'expires_in';

  // Offline reports
  static const String pendingReports = 'pending_reports';
  static const String reportQueue = 'report_queue';
}

class ValidationConstraints {
  // Phone number validation
  static const String phonePattern = r'^\+233\d{9}$';
  static const int minPhoneLength = 13; // +233xxxxxxxxx
  static const int maxPhoneLength = 13;

  // OTP validation
  static const int otpLength = 6;

  // GPS validation
  static const double minLatitude = -90.0;
  static const double maxLatitude = 90.0;
  static const double minLongitude = -180.0;
  static const double maxLongitude = 180.0;

  // Ghana-specific bounds
  static const double ghanaMinLat = 1.0;
  static const double ghanaMaxLat = 11.2;
  static const double ghanaMinLon = -3.3;
  static const double ghanaMaxLon = 1.2;

  // GPS accuracy in meters
  static const double acceptableGpsAccuracy = 50.0;

  // File size limits
  static const int maxPhotoSizeMB = 10;
  static const int maxVideoSizeMB = 50;
  static const int maxPhotoSizeBytes = maxPhotoSizeMB * 1024 * 1024;
  static const int maxVideoSizeBytes = maxVideoSizeMB * 1024 * 1024;
}

class ReportCategories {
  static const String plasticDumping = 'plastic_dumping';
  static const String gutterDumping = 'gutter_dumping';
  static const String openDefecation = 'open_defecation';
  static const String constructionWaste = 'construction_waste';

  static const List<String> all = [
    plasticDumping,
    gutterDumping,
    openDefecation,
    constructionWaste,
  ];

  static String displayName(String category) {
    switch (category) {
      case plasticDumping:
        return 'Plastic Dumping';
      case gutterDumping:
        return 'Gutter Dumping';
      case openDefecation:
        return 'Open Defecation';
      case constructionWaste:
        return 'Construction Waste';
      default:
        return 'Unknown';
    }
  }
}

class ReportStatus {
  static const String submitted = 'submitted';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String assigned = 'assigned';
  static const String completed = 'completed';
}
