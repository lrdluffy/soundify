import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/util/validators.dart';
import '../../../state/auth_controller.dart';
import '../../widgets/auth_widgets.dart';
import 'verify_account_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final nav = Navigator.of(context);
    final email = _email.text.trim();
    final password = _password.text;
    final ok = await runGuarded(
      context,
      (b) {
        if (mounted) setState(() => _busy = b);
      },
      () => auth.register(_email.text, _username.text, _password.text, _name.text),
      errorText,
    );
    // Account is created but unverified: the server emailed an OTP.
    if (ok) {
      nav.pushReplacement(MaterialPageRoute<void>(
          builder: (_) => VerifyAccountScreen(email: email, password: password)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'ایجاد حساب کاربری',
      subtitle: 'چند ثانیه تا شروع موسیقی',
      children: [
        Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _username,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.next,
                validator: Validators.username,
                decoration: const InputDecoration(
                  labelText: 'نام کاربری',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'نام نمایشی (اختیاری)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),
              EmailField(controller: _email, validator: Validators.email),
              const SizedBox(height: 14),
              PasswordField(
                controller: _password,
                validator: Validators.password,
                action: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _confirm,
                label: 'تکرار رمز عبور',
                validator: Validators.confirmPassword(() => _password.text),
                onSubmitted: _submit,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        BusyButton(label: 'ثبت‌نام', busy: _busy, onPressed: _submit),
      ],
    );
  }
}
