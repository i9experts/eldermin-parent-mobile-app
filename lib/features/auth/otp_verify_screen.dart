import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String phone;
  final String? devCode;
  const OtpVerifyScreen({super.key, required this.phone, this.devCode});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  String _code = '';
  bool _loading = false;
  String? _error;
  int _resendSeconds = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendSeconds = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 1) {
        t.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.length != 6) return;
    setState(() { _loading = true; _error = null; });

    try {
      final api = ref.read(parentApiProvider);
      final result = await api.verifyOtp(widget.phone, _code);
      if (!mounted) return;

      final user = result['user'] as Map<String, dynamic>;
      await ref.read(authStateProvider.notifier).loginSuccess(
            token: result['accessToken'] as String,
            name: user['name'] as String? ?? 'Parent',
            phone: user['phone'] as String? ?? widget.phone,
          );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _error = null);
    try {
      await ref.read(parentApiProvider).requestOtp(widget.phone);
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code resent.')));
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Number')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text('Enter the code', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text('We sent a 6-digit code via WhatsApp to ${widget.phone}', style: const TextStyle(color: AppColors.muted)),
              if (widget.devCode != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: AppColors.amberBg, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Row(children: [
                    const Icon(Icons.science_outlined, color: AppColors.amberText, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text('Dev mode code: ${widget.devCode}', style: const TextStyle(color: AppColors.amberText, fontWeight: FontWeight.w600))),
                  ]),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PinCodeTextField(
                appContext: context,
                length: 6,
                onChanged: (value) => setState(() => _code = value),
                onCompleted: (_) => _verify(),
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  fieldHeight: 52,
                  fieldWidth: 44,
                  activeColor: AppColors.navy,
                  selectedColor: AppColors.navy,
                  inactiveColor: AppColors.line,
                  activeFillColor: AppColors.background,
                  inactiveFillColor: AppColors.background,
                  selectedFillColor: AppColors.background,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
              ],
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: (_loading || _code.length != 6) ? null : _verify,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify & Continue'),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: _resendSeconds > 0
                    ? Text('Resend code in $_resendSeconds s', style: const TextStyle(color: AppColors.faint))
                    : TextButton(onPressed: _resend, child: const Text('Resend Code')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
