import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/util/validators.dart';
import '../../../state/auth_controller.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/state_views.dart';

/// Step 1: enter email -> server sends a code. Step 2: enter the code, with a
/// resend countdown.
class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _codeForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;
  int _remaining = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _remaining = AppConfig.otpResendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
      }
      if (mounted) setState(() => _remaining = _remaining - 1);
    });
  }

  Future<void> _sendCode() async {
    if (!_emailForm.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await runGuarded(
      context,
      (b) {
        if (mounted) setState(() => _busy = b);
      },
      () => auth.requestOtp(_email.text),
      errorText,
    );
    if (ok && mounted) {
      setState(() => _codeSent = true);
      _startCountdown();
      showSnack(context, 'کد تأیید به ایمیل شما ارسال شد');
    }
  }

  Future<void> _verify() async {
    if (!_codeForm.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final nav = Navigator.of(context);
    final ok = await runGuarded(
      context,
      (b) {
        if (mounted) setState(() => _busy = b);
      },
      () => auth.verifyOtp(_email.text, _code.text),
      errorText,
    );
    if (ok) nav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'ورود با کد یکبار مصرف',
      subtitle: _codeSent
          ? 'کد ارسال‌شده به ${_email.text.trim()} را وارد کنید'
          : 'ایمیل خود را وارد کنید تا کد تأیید برایتان ارسال شود',
      children: [
        Form(
          key: _emailForm,
          child: EmailField(
            controller: _email,
            validator: Validators.email,
            enabled: !_codeSent,
            action: TextInputAction.done,
          ),
        ),
        const SizedBox(height: 16),
        if (!_codeSent)
          BusyButton(label: 'ارسال کد', busy: _busy, onPressed: _sendCode)
        else ...[
          Form(
            key: _codeForm,
            child: TextFormField(
              controller: _code,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              maxLength: 8,
              style: const TextStyle(fontSize: 22, letterSpacing: 6),
              validator: Validators.otp,
              onFieldSubmitted: (_) => _verify(),
              decoration: const InputDecoration(
                labelText: 'کد تأیید',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 16),
          BusyButton(label: 'تأیید و ورود', busy: _busy, onPressed: _verify),
          const SizedBox(height: 12),
          Center(
            child: _remaining > 0
                ? Text('ارسال مجدد کد تا $_remaining ثانیه دیگر')
                : TextButton(
                    onPressed: _busy ? null : _sendCode,
                    child: const Text('ارسال مجدد کد'),
                  ),
          ),
          TextButton(
            onPressed: () {
              _timer?.cancel();
              setState(() {
                _codeSent = false;
                _remaining = 0;
                _code.clear();
              });
            },
            child: const Text('تغییر ایمیل'),
          ),
        ],
      ],
    );
  }
}
