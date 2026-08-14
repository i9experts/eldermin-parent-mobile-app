import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'otp_verify_screen.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _phoneController = TextEditingController(text: '+92 ');
  bool _loading = false;
  String? _error;

  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.replaceAll(RegExp(r'[^\d]'), '').length < 10) {
      setState(() => _error = 'Enter your complete WhatsApp number.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final api = ref.read(parentApiProvider);
      final result = await api.requestOtp(phone);
      if (!mounted) return;

      if (result['sent'] == false && result['devCode'] == null) {
        setState(() => _error = "Couldn't send the code right now: ${result['reason'] ?? 'please try again shortly.'}");
        return;
      }

      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpVerifyScreen(phone: phone, devCode: result['devCode'] as String?),
      ));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.heroGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 44),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Eldermin', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28)),
              const SizedBox(height: AppSpacing.xs),
              const Text('Parent App', textAlign: TextAlign.center, style: TextStyle(color: AppColors.faint, fontSize: 15)),
              const Spacer(flex: 2),
              Text('Log in with WhatsApp', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                "Enter the WhatsApp number registered with your child's school. We'll send a verification code — no password needed.",
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+\s]'))],
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: '+92 300 1234567',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.phone_iphone_rounded, color: AppColors.navy),
                  ),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _loading ? null : _requestOtp,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Verification Code'),
              ),
              const Spacer(flex: 3),
              const Text(
                "Haven't registered this number with your school yet? Contact the school office to link it to your child's profile.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.faint, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
