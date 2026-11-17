import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/util/validators.dart';
import '../../../state/auth_controller.dart';
import '../../widgets/auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'otp_login_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    await runGuarded(
      context,
      (b) {
        if (mounted) setState(() => _busy = b);
      },
      () => auth.login(_email.text, _password.text),
      errorText,
    );
    // On success AuthGate swaps to the main shell by itself.
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: false,
      title: 'ورود به Soundify',
      subtitle: 'برای شنیدن موسیقی وارد حساب خود شوید',
      children: [
        Form(
          key: _form,
          child: Column(
            children: [
              EmailField(controller: _email, validator: Validators.email),
              const SizedBox(height: 14),
              PasswordField(
                controller: _password,
                validator: Validators.password,
                onSubmitted: _submit,
              ),
            ],
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen())),
            child: const Text('رمز عبور را فراموش کرده‌اید؟'),
          ),
        ),
        const SizedBox(height: 8),
        BusyButton(label: 'ورود', busy: _busy, onPressed: _submit),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const OtpLoginScreen())),
          icon: const Icon(Icons.pin_outlined),
          label: const Text('ورود با کد یکبار مصرف'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('حساب کاربری ندارید؟'),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const RegisterScreen())),
              child: const Text('ثبت‌نام'),
            ),
          ],
        ),
      ],
    );
  }
}
