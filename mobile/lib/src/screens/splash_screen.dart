import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.isAuthenticated) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green[800],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.recycling,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ghana Sanitation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Platform',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
