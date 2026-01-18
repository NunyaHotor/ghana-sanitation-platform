import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/report_provider.dart';
import 'src/providers/sync_provider.dart';
import 'src/screens/splash_screen.dart';
import 'src/screens/auth/login_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/camera/camera_screen.dart';
import 'src/screens/camera/preview_screen.dart';
import 'src/screens/report/report_form.dart';
import 'src/config/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Hive for offline storage
  await Hive.initFlutter();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
      ],
      child: MaterialApp(
        title: 'Ghana Sanitation Platform',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/camera': (context) => const CameraScreen(),
          '/camera/preview': (context) => const PreviewScreen(),
          '/report/form': (context) => const ReportFormScreen(),
        },
      ),
    );
  }
}
