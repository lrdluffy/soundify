import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/util/validators.dart';
import '../../../state/auth_controller.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/state_views.dart';

/// Email verification with the 6-digit OTP.
///
/// - After registration: [email] + [password] are passed, the server already
///   sent the code, so we just start the resend countdown. After a successful
///   verification we log in automatically.
/// - From a login that failed with `account_not_verified`: [sendOnOpen] asks
///   the server for a fresh code. After verifying, the user returns to login.
/// - Opened without [email]: the user types the email first.
class VerifyAccountScreen extends StatefulWidget {
  const VerifyAccountScreen({
    super.key,
    this.email,
    this.password,
    this.sendOnOpen = false,
  });

  final String? email;
  final String? password;
  final bool sendOnOpen;

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _codeForm = GlobalKey<FormState>();
  late final TextEditingController _email =
      TextEditingController(text: widget.email);
  final _code = TextEditingController();

  late bool _codeSent = widget.email != null;
  bool _busy = false;
  int _remaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.email == null) return;
    if (widget.sendOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
    } else {
      _remaining = AppConfig.otpResendSeconds;
      _tick();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining = _remaining - 1);
      if (_remaining <= 0) t.cancel();
    });
  }

  void _startCountdown() {
    setState(() => _remaining = AppConfig.otpResendSeconds);
    _tick();
  }

  Future<void> _sendCode() async {
    if (!_codeSent && !_emailForm.currentState!.validate()) return;
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
    final messenger = ScaffoldMessenger.of(context);
    final password = widget.password;

    final ok = await runGuarded(
      context,
      (b) {
        if (mounted) setState(() => _busy = b);
      },
      () async {
        await auth.verifyOtp(_email.text, _code.text);
        if (password != null) await auth.login(_email.text, password);
      },
      errorText,
    );
    if (!ok) return;

    if (password != null) {
      // AuthGate switches to the main shell by itself.
      nav.popUntil((r) => r.isFirst);
    } else {
      nav.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('حساب شما تأیید شد. اکنون وارد شوید.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'تأیید حساب کاربری',
      subtitle: _codeSent
          ? 'کد ۶ رقمی ارسال‌شده به ${_email.text.trim()} را وارد کنید'
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
              maxLength: 6,
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
          BusyButton(label: 'تأیید حساب', busy: _busy, onPressed: _verify),
          const SizedBox(height: 12),
          Center(
            child: _remaining > 0
                ? Text('ارسال مجدد کد تا $_remaining ثانیه دیگر')
                : TextButton(
                    onPressed: _busy ? null : _sendCode,
                    child: const Text('ارسال مجدد کد'),
                  ),
          ),
          if (widget.email == null)
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
