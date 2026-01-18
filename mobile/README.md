# Ghana Sanitation Platform - Mobile App

A Flutter mobile application for reporting sanitation violations in Ghana with offline support.

## Features

- 📱 **OTP-based Authentication** - Secure phone number verification
- 🚨 **Report Violations** - Report plastic dumping, gutter contamination, and more
- 📍 **GPS Integration** - Auto-capture location with accuracy
- 📷 **Photo & Video Capture** - Attach evidence to reports
- 🔄 **Offline Support** - Queue reports offline, auto-sync when online
- 📊 **Status Tracking** - Track report status in real-time
- 🎁 **Incentive System** - Earn points for verified reports
- 🌓 **Dark Mode** - Beautiful light and dark themes

## Setup Instructions

### Prerequisites

- Flutter 3.0+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Android SDK 21+ or iOS 11+
- Git

### Installation

1. **Clone the repository**
   ```bash
   cd /home/mawutor/ghana-sanitation-platform/mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate model files**
   ```bash
   flutter pub run build_runner build
   ```

4. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your backend server URL
   ```

5. **Run the app**
   ```bash
   # On Android emulator
   flutter run

   # On iOS simulator
   flutter run -d all

   # On Chrome (for web testing)
   flutter run -d chrome
   ```

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── src/
│   ├── config/
│   │   ├── constants.dart   # API endpoints, validation rules
│   │   └── theme.dart       # App themes and styles
│   ├── models/
│   │   ├── user.dart        # User model
│   │   ├── report.dart      # Report model with Hive support
│   │   └── auth_response.dart
│   ├── services/
│   │   ├── api_service.dart # HTTP client with Dio
│   │   └── offline_storage_service.dart # Hive database
│   ├── providers/
│   │   ├── auth_provider.dart # Authentication state
│   │   ├── report_provider.dart # Report management
│   │   └── sync_provider.dart # Network state
│   └── screens/
│       ├── splash_screen.dart
│       ├── auth/
│       │   └── login_screen.dart
│       └── home_screen.dart # Main app interface
```

## Architecture

### State Management
- **Provider**: Used for state management across the app
- **ChangeNotifier**: For reactive UI updates

### Data Persistence
- **Hive**: Local database for offline report queue
- **SharedPreferences**: For auth tokens and user preferences
- **FlutterSecureStorage**: For secure token storage

### Network
- **Dio**: HTTP client with interceptors for auth
- **Connectivity Plus**: For network state monitoring

## API Integration

The app connects to the backend API at `http://localhost:3000/api/v1`

### Authentication Flow

```
1. User enters phone number
   ↓
2. POST /auth/request-otp → OTP sent via SMS
   ↓
3. User enters OTP code
   ↓
4. POST /auth/verify-otp → Receive access_token & refresh_token
   ↓
5. Authenticated requests use Bearer token
```

### Report Submission

#### Online Mode
```
POST /reports {
  category: "plastic_dumping",
  latitude: 5.6037,
  longitude: -0.187,
  gps_accuracy: 15.0,
  captured_at: "2025-01-17T10:30:00Z",
  description: "Plastic pile at market entrance",
  anonymous: false
}
```

#### Offline Mode
- Reports stored locally in Hive
- Auto-queued with local ID
- Synced when connectivity restored
- Status visible in real-time

## Development

### Running Tests
```bash
flutter test
```

### Generate Code
```bash
flutter pub run build_runner build
```

### Build Release APK
```bash
flutter build apk --release
```

### Build iOS App
```bash
flutter build ios --release
```

## Key Dependencies

| Package | Purpose |
|---------|---------|
| provider | State management |
| dio | HTTP client |
| hive_flutter | Local database (offline) |
| geolocator | GPS location |
| image_picker | Photo/video selection |
| camera | Camera integration |
| flutter_secure_storage | Secure token storage |
| connectivity_plus | Network state |
| json_serializable | JSON serialization |

## Configuration

### Environment Variables (`.env`)
```
API_BASE_URL=http://localhost:3000/api/v1
APP_NAME=Ghana Sanitation Platform
ENABLE_OFFLINE_MODE=true
ENABLE_GPS_TRACKING=true
ENABLE_CAMERA=true
```

### Validation Rules (see `config/constants.dart`)
- Phone: +233XXXXXXXXX (13 digits)
- OTP: 6 digits
- GPS: WGS84 format with accuracy in meters
- Files: Max 10MB photos, 50MB videos

## Common Tasks

### Adding a New Screen
1. Create file in `lib/src/screens/`
2. Implement StatefulWidget or StatelessWidget
3. Use Consumer<Provider> for state
4. Add route in main.dart

### Adding a New Model
1. Create file in `lib/src/models/`
2. Add @JsonSerializable() and @HiveType() decorators
3. Run: `flutter pub run build_runner build`

### Testing Offline Features
1. Enable airplane mode in emulator
2. Submit report (queued locally)
3. Disable airplane mode
4. App auto-syncs pending reports

## Troubleshooting

### Build Issues
```bash
# Clean build
flutter clean
flutter pub get
flutter pub run build_runner build
flutter run
```

### Connection Issues
- Verify backend server is running on `localhost:3000`
- Check firewall/antivirus isn't blocking port 3000
- Use `flutter run -v` for verbose logs

### GPS Issues
- Ensure location permission is granted in app settings
- On emulator, set mock location in dev settings
- Check GPS accuracy (should be < 50m)

## Contributing

1. Create a branch for your feature
2. Implement changes with tests
3. Submit a pull request

## License

MIT License

---

**Status**: Phase 2 Mobile App ✅ In Progress
**Last Updated**: January 17, 2026
