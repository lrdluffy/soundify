import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/util/validators.dart';
import '../../../state/auth_controller.dart';
import '../../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    final nav = Navigator.of(context);
    final ok = await runGuarded(
      context,
      (b) {
        if (mounted) setState(() => _busy = b);
      },
      () => auth.register(_email.text, _password.text, _name.text),
      errorText,
    );
    if (ok) nav.popUntil((r) => r.isFirst);
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
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'نام (اختیاری)',
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
