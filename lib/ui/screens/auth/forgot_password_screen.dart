import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/util/validators.dart';
import '../../../state/auth_controller.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/state_views.dart';

/// Two steps: request a code, then submit code + new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_emailForm.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final ok = await runGuarded(
      context,
      (b) => mounted ? setState(() => _busy = b) : null,
      () => auth.requestPasswordReset(_email.text),
      errorText,
    );
    if (ok && mounted) {
      setState(() => _codeSent = true);
      showSnack(context, 'کد بازیابی به ایمیل شما ارسال شد');
    }
  }

  Future<void> _submitReset() async {
    if (!_resetForm.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await runGuarded(
      context,
      (b) => mounted ? setState(() => _busy = b) : null,
      () => auth.confirmPasswordReset(_email.text, _code.text, _password.text),
      errorText,
    );
    if (ok) {
      nav.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('رمز عبور با موفقیت تغییر کرد. وارد شوید.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'بازیابی رمز عبور',
      subtitle: _codeSent
          ? 'کد دریافتی و رمز عبور جدید را وارد کنید'
          : 'ایمیل حساب خود را وارد کنید',
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
          BusyButton(label: 'ارسال کد بازیابی', busy: _busy, onPressed: _requestCode)
        else ...[
          Form(
            key: _resetForm,
            child: Column(
              children: [
                TextFormField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  validator: Validators.otp,
                  decoration: const InputDecoration(
                    labelText: 'کد تأیید',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _password,
                  label: 'رمز عبور جدید',
                  validator: Validators.password,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                PasswordField(
                  controller: _confirm,
                  label: 'تکرار رمز عبور جدید',
                  validator: Validators.confirmPassword(() => _password.text),
                  onSubmitted: _submitReset,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          BusyButton(label: 'ثبت رمز عبور جدید', busy: _busy, onPressed: _submitReset),
          TextButton(
            onPressed: _busy ? null : _requestCode,
            child: const Text('ارسال مجدد کد'),
          ),
        ],
      ],
    );
  }
}
