import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:makeup_booking_app/utils/app_text_styles.dart';
import 'package:makeup_booking_app/utils/color_resource.dart';

import '../../data/auth_repository.dart';
import '../provider/auth_provider.dart';

enum _Step { phone, otp }

/// Pops with `true` once the user is signed in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const _countryCode = '+91';
  static const _resendSeconds = 30;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  _Step _step = _Step.phone;
  String? _verificationId;
  int? _resendToken;
  bool _busy = false;
  String? _error;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Indian mobile numbers are 10 digits starting with 6-9.
  bool get _phoneValid => RegExp(r'^[6-9]\d{9}$').hasMatch(_phoneController.text);

  bool get _otpValid => _otpController.text.length == 6;

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _secondsLeft <= 1) {
        t.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _sendOtp({bool resend = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    await ref.read(authRepositoryProvider).sendOtp(
          phoneNumber: '$_countryCode${_phoneController.text}',
          resendToken: resend ? _resendToken : null,
          onCodeSent: (id, token) {
            if (!mounted) return;
            setState(() {
              _verificationId = id;
              _resendToken = token;
              _step = _Step.otp;
              _busy = false;
            });
            _startCountdown();
          },
          onFailed: (message) {
            if (!mounted) return;
            setState(() {
              _error = message;
              _busy = false;
            });
          },
          onAutoSignedIn: () {
            if (mounted) Navigator.pop(context, true);
          },
        );
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).confirmOtp(
            verificationId: _verificationId!,
            smsCode: _otpController.text,
          );
      if (mounted) Navigator.pop(context, true);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onOtpStep = _step == _Step.otp;

    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Text(
              onOtpStep ? 'Enter the code' : 'Welcome',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              onOtpStep
                  ? 'We sent a 6-digit code to $_countryCode ${_phoneController.text}.'
                  : 'Log in with your mobile number to book an artist.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 28),
            if (!onOtpStep)
              TextField(
                controller: _phoneController,
                onChanged: (_) => setState(() => _error = null),
                keyboardType: TextInputType.phone,
                autofocus: true,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: const InputDecoration(
                  prefixText: '$_countryCode  ',
                  prefixStyle: TextStyle(color: Colors.white, fontSize: 18),
                  hintText: 'Mobile number',
                  counterText: '',
                ),
              )
            else
              TextField(
                controller: _otpController,
                onChanged: (_) => setState(() => _error = null),
                keyboardType: TextInputType.number,
                autofocus: true,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '------',
                  counterText: '',
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy
                  ? null
                  : onOtpStep
                      ? (_otpValid ? _verify : null)
                      : (_phoneValid ? _sendOtp : null),
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(onOtpStep ? 'Verify' : 'Send OTP'),
            ),
            if (onOtpStep) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy || _secondsLeft > 0
                    ? null
                    : () => _sendOtp(resend: true),
                child: Text(
                  _secondsLeft > 0
                      ? 'Resend code in ${_secondsLeft}s'
                      : 'Resend code',
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _step = _Step.phone;
                          _otpController.clear();
                          _error = null;
                          _timer?.cancel();
                        }),
                child: const Text(
                  'Change number',
                  style: TextStyle(color: ColorResource.colorPrimaryAccent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
