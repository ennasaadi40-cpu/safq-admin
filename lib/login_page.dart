part of station_app;

// firebase_auth و firebase_core مستوردان في main.dart

// ─────────────────────────────────────────────
//  Login Page
// ─────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey   = GlobalKey<FormState>();
  final _userCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();
  bool _passVisible = false;
  bool _loading     = false;

  @override
  void initState() {
    super.initState();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    if (_userCtrl.text.trim() != 'admin') {
      setState(() => _loading = false);
      if (!mounted) return;
      _showError('اسم المستخدم غير صحيح');
      return;
    }

    final email = _emailCtrl.text.trim();

    if (adminEmail.isNotEmpty && email != adminEmail) {
      setState(() => _loading = false);
      if (!mounted) return;
      _showError('البريد الإلكتروني غير مصرّح له');
      return;
    }

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: _passCtrl.text,
      );
      setState(() => _loading = false);
      if (!mounted) return;
      TextInput.finishAutofillContext();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
    } on FirebaseAuthException catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      String msg = 'اسم المستخدم أو كلمة المرور خاطئة';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') msg = 'كلمة المرور خاطئة';
      if (e.code == 'user-not-found') msg = 'البريد الإلكتروني غير مسجّل';
      if (e.code == 'invalid-email') msg = 'البريد الإلكتروني غير صحيح';
      if (e.code == 'too-many-requests') msg = 'محاولات كثيرة، حاول لاحقاً';
      _showError(msg);
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      _showError('حدث خطأ، حاول مجدداً');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: const Color(0xFFE53935),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(text: adminEmail);
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFF1a2d50),
            title: const Row(children: [
              Icon(Icons.lock_reset_outlined, color: Color(0xFFF5B800), size: 22),
              SizedBox(width: 10),
              Text('إعادة تعيين كلمة المرور',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('سيتم إرسال رابط إعادة التعيين إلى البريد الإلكتروني المسجّل.',
                  style: TextStyle(color: Color(0xFF8aaccc), fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'البريد الإلكتروني',
                  hintStyle: const TextStyle(color: Color(0xFF4a5f7a), fontSize: 13),
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF4a5f7a), size: 17),
                  filled: true,
                  fillColor: const Color(0xFF0f1c35),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2a3f68))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2a3f68))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFF5B800), width: 1.5)),
                ),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء', style: TextStyle(color: Color(0xFF8aaccc))),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5B800),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.send_rounded, color: Color(0xFF0f1c35), size: 16),
                label: const Text('إرسال', style: TextStyle(color: Color(0xFF0f1c35), fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final email = emailCtrl.text.trim();
                  if (email.isEmpty) return;
                  Navigator.pop(context);
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('تم إرسال رابط إعادة التعيين إلى $email', textDirection: TextDirection.rtl),
                      backgroundColor: const Color(0xFF2E7D32),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      margin: const EdgeInsets.all(16),
                    ));
                  } on FirebaseAuthException catch (e) {
                    if (!mounted) return;
                    String msg = 'حدث خطأ';
                    if (e.code == 'user-not-found') msg = 'البريد الإلكتروني غير مسجّل';
                    if (e.code == 'invalid-email') msg = 'البريد الإلكتروني غير صحيح';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(msg, textDirection: TextDirection.rtl),
                      backgroundColor: const Color(0xFFE53935),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      margin: const EdgeInsets.all(16),
                    ));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); _emailFocus.dispose(); _passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1c35),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ── Logo image ────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const SizedBox(height: 22),

                    // ── Username ──────────────────────
                    TextFormField(
                      controller: _userCtrl,
                      textDirection: TextDirection.ltr,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passFocus),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _dec('Username', Icons.person_outline_rounded),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 11),

                    // ── Email ─────────────────────────
                    TextFormField(
                      controller: _emailCtrl,
                      textDirection: TextDirection.ltr,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passFocus),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _dec('Email', Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),

                    const SizedBox(height: 11),

                    // ── Password ──────────────────────
                    TextFormField(
                      controller: _passCtrl,
                      focusNode: _passFocus,
                      textDirection: TextDirection.ltr,
                      obscureText: !_passVisible,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _login(),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _dec(
                        'Password',
                        Icons.lock_outline_rounded,
                        suffix: IconButton(
                          icon: Icon(
                            _passVisible
                                ? Icons.visibility_off_outlined
                                : Icons.remove_red_eye_outlined,
                            size: 17,
                            color: const Color(0xFF4a5f7a),
                          ),
                          onPressed: () => setState(() => _passVisible = !_passVisible),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 20),

                    // ── Sign In button ────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5B800),
                          disabledBackgroundColor: const Color(0xFFF5B800).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: _loading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Color(0xFF0f1c35), strokeWidth: 2))
                            : const Icon(Icons.login_rounded,
                                color: Color(0xFF0f1c35), size: 18),
                        label: _loading
                            ? const SizedBox.shrink()
                            : Text('تسجيل الدخول',
                                style: const TextStyle(
                                    color: Color(0xFF0f1c35),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Forgot password ───────────────
                    TextButton(
                      onPressed: _forgotPassword,
                      child: const Text(
                        'نسيت كلمة المرور؟',
                        style: TextStyle(color: Color(0xFF8aaccc), fontSize: 12),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF4a5f7a), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF4a5f7a), size: 17),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1a2d50),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2a3f68))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2a3f68))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color(0xFFF5B800), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE53935))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE53935))),
        errorStyle:
            const TextStyle(color: Color(0xFFE53935), fontSize: 11),
      );
}