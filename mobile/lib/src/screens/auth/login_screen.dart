import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _showOtpField = false;
  String? _phoneError;
  String? _otpError;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() => _phoneError = null);

    final phone = _phoneController.text.trim();

    // Validate phone
    if (phone.isEmpty) {
      setState(() => _phoneError = 'Please enter your phone number');
      return;
    }

    if (!phone.startsWith('+233') || phone.length != 13) {
      setState(() => _phoneError = 'Use format: +233501234567');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.requestOtp(phone);

    if (success) {
      setState(() => _showOtpField = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to your phone')),
      );
    } else {
      setState(() => _phoneError = authProvider.error ?? 'Failed to send OTP');
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _otpError = null);

    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      setState(() => _otpError = 'Enter 6-digit OTP');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(otp);

    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      setState(() => _otpError = authProvider.error ?? 'Invalid OTP');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Report Sanitation\nViolations',
                style: AppTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Help keep Ghana clean by reporting violations',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 48),
              // Phone field
              Text(
                'Phone Number',
                style: AppTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: !_showOtpField,
                decoration: InputDecoration(
                  hintText: '+233501234567',
                  errorText: _phoneError,
                  prefixIcon: const Icon(Icons.phone),
                ),
                onChanged: (_) => setState(() => _phoneError = null),
              ),
              if (!_showOtpField) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _requestOtp,
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Send OTP'),
                      );
                    },
                  ),
                ),
              ] else ...[
                const SizedBox(height: 24),
                Text(
                  'One-Time Password',
                  style: AppTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '000000',
                    errorText: _otpError,
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  onChanged: (_) => setState(() => _otpError = null),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _verifyOtp,
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Verify OTP'),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      setState(() => _showOtpField = false);
                      _phoneController.clear();
                      _otpController.clear();
                    },
                    child: const Text('Use different number'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
