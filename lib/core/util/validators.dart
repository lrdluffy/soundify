class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[\w.+\-]+@([\w\-]+\.)+[\w\-]{2,}$');

  static String? email(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'ایمیل را وارد کنید';
    if (!_email.hasMatch(t)) return 'ایمیل معتبر نیست';
    return null;
  }

  static String? username(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'نام کاربری را وارد کنید';
    if (t.length < 3) return 'نام کاربری باید حداقل ۳ کاراکتر باشد';
    if (!RegExp(r'^[A-Za-z0-9_.]+$').hasMatch(t)) {
      return 'فقط حروف انگلیسی، عدد، نقطه و _ مجاز است';
    }
    return null;
  }

  static String? password(String? v) {
    final t = v ?? '';
    if (t.isEmpty) return 'رمز عبور را وارد کنید';
    if (t.length < 8) return 'رمز عبور باید حداقل ۸ کاراکتر باشد';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) =>
      (v) {
        if ((v ?? '').isEmpty) return 'تکرار رمز عبور را وارد کنید';
        if (v != original()) return 'رمز عبور و تکرار آن یکسان نیست';
        return null;
      };

  static String? otp(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'کد تأیید را وارد کنید';
    if (t.length < 4 || int.tryParse(t) == null) return 'کد تأیید معتبر نیست';
    return null;
  }

  static String? required(String? v, [String label = 'این فیلد']) =>
      (v ?? '').trim().isEmpty ? '$label را وارد کنید' : null;
}
