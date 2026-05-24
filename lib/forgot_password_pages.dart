part of station_app;

// ════════════════════════════════════════════════════════════════
//  API Config — غيري هاي القيم لما يجهز الباك اند
// ════════════════════════════════════════════════════════════════
class _AuthApi {
  static const String baseUrl = 'https://YOUR_BACKEND_URL';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String verifyOtp      = '$baseUrl/auth/verify-otp';
  static const String resetPassword  = '$baseUrl/auth/reset-password';
}

// ════════════════════════════════════════════════════════════════
//  1. صفحة إدخال الإيميل
// ════════════════════════════════════════════════════════════════
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = L.isArabic ? 'أدخل بريد إلكتروني صحيح' : 'Enter a valid email');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      // إرسال رابط إعادة تعيين كلمة المرور عبر Firebase
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => OtpVerifyPage(email: email),
      ));
    } on FirebaseAuthException catch (e) {
      String msg = L.isArabic ? 'حدث خطأ، حاول مجدداً' : 'An error occurred, try again';
      if (e.code == 'user-not-found') msg = L.isArabic ? 'البريد الإلكتروني غير مسجّل' : 'Email not registered';
      if (e.code == 'invalid-email')  msg = L.isArabic ? 'البريد الإلكتروني غير صحيح' : 'Invalid email';
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = L.isArabic ? 'حدث خطأ، حاول مجدداً' : 'An error occurred, try again');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0f1c35),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0f1c35),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5B800).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFF5B800), size: 32),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      L.isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      L.isArabic
                          ? 'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين'
                          : 'Enter your email and we\'ll send you a reset link',
                      style: const TextStyle(color: Color(0xFF8aaccc), fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      L.isArabic ? 'البريد الإلكتروني' : 'Email',
                      style: const TextStyle(color: Color(0xFF8aaccc), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'admin@example.com',
                        hintStyle: const TextStyle(color: Color(0xFF4a5f7a), fontSize: 13),
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF4a5f7a), size: 18),
                        filled: true,
                        fillColor: const Color(0xFF1a2d50),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2a3f68))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2a3f68))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFF5B800), width: 1.5)),
                        errorText: _error,
                        errorStyle: const TextStyle(color: Color(0xFFE53935), fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5B800),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _loading ? null : _sendOtp,
                        child: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF0f1c35), strokeWidth: 2))
                            : Text(
                                L.isArabic ? 'إرسال رابط إعادة التعيين' : 'Send Reset Link',
                                style: const TextStyle(color: Color(0xFF0f1c35), fontSize: 15, fontWeight: FontWeight.bold),
                              ),
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

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }
}

// ════════════════════════════════════════════════════════════════
//  2. صفحة إدخال OTP
// ════════════════════════════════════════════════════════════════
class OtpVerifyPage extends StatefulWidget {
  final String email;
  const OtpVerifyPage({super.key, required this.email});
  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final List<TextEditingController> _ctrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;
  int _resendSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() { _resendSeconds = 60; _canResend = false; });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) {
        setState(() => _canResend = true);
        return false;
      }
      return true;
    });
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) {
      setState(() => _error = L.isArabic ? 'أدخل الرمز كاملاً' : 'Enter the full code');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      // TODO: استبدلي هاد بطلب حقيقي للباك اند لما يجهز
      // final res = await http.post(
      //   Uri.parse(_AuthApi.verifyOtp),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({'email': widget.email, 'otp': _otp}),
      // );
      // if (res.statusCode != 200) throw Exception('رمز خاطئ');

      // مؤقتاً — انتقل لصفحة تغيير كلمة المرور
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ResetPasswordPage(email: widget.email, otp: _otp),
      ));
    } catch (e) {
      setState(() => _error = L.isArabic ? 'الرمز غير صحيح' : 'Invalid code');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    _startTimer();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0f1c35),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0f1c35),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C897).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.mark_email_read_outlined, color: Color(0xFF00C897), size: 32),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      L.isArabic ? 'تحقق من بريدك' : 'Check your email',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      L.isArabic
                          ? 'تم إرسال رابط إعادة التعيين إلى\n${widget.email}\nافتح الرابط ثم ادخل كلمة المرور الجديدة هنا'
                          : 'A reset link was sent to\n${widget.email}\nOpen the link then enter your new password here',
                      style: const TextStyle(color: Color(0xFF8aaccc), fontSize: 13, height: 1.6),
                    ),
                    const SizedBox(height: 32),

                    // حقول OTP
                    Text(
                      L.isArabic ? 'أدخل رمز التحقق (اختياري)' : 'Enter verification code (optional)',
                      style: const TextStyle(color: Color(0xFF8aaccc), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) => SizedBox(
                        width: 44,
                        child: TextField(
                          controller: _ctrls[i],
                          focusNode: _nodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: const Color(0xFF1a2d50),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2a3f68))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2a3f68))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFF5B800), width: 2)),
                          ),
                          onChanged: (v) {
                            if (v.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
                            else if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
                            setState(() => _error = null);
                          },
                        ),
                      )),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Color(0xFFE53935), fontSize: 12)),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5B800),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _loading ? null : _verify,
                        child: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF0f1c35), strokeWidth: 2))
                            : Text(
                                L.isArabic ? 'متابعة' : 'Continue',
                                style: const TextStyle(color: Color(0xFF0f1c35), fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: _canResend
                          ? TextButton(
                              onPressed: _resend,
                              child: Text(
                                L.isArabic ? 'إعادة إرسال الرابط' : 'Resend link',
                                style: const TextStyle(color: Color(0xFFF5B800), fontSize: 13),
                              ),
                            )
                          : Text(
                              '${L.isArabic ? "إعادة الإرسال بعد" : "Resend in"} $_resendSeconds ${L.isArabic ? "ثانية" : "s"}',
                              style: const TextStyle(color: Color(0xFF8aaccc), fontSize: 12),
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

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }
}

// ════════════════════════════════════════════════════════════════
//  3. صفحة تغيير كلمة المرور
// ════════════════════════════════════════════════════════════════
class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String otp;
  const ResetPasswordPage({super.key, required this.email, required this.otp});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _newVis = false, _confVis = false;
  bool _loading = false;
  String? _error;

  Future<void> _reset() async {
    final nw   = _newCtrl.text.trim();
    final conf = _confCtrl.text.trim();

    if (nw.isEmpty) { setState(() => _error = L.get('val_pass_required')); return; }
    if (nw.length < 8) { setState(() => _error = L.get('val_pass_short')); return; }
    if (!nw.contains(RegExp(r'[A-Z]'))) { setState(() => _error = L.get('val_pass_upper')); return; }
    if (!nw.contains(RegExp(r'[0-9]'))) { setState(() => _error = L.get('val_pass_number')); return; }
    if (nw != conf) { setState(() => _error = L.get('passwords_not_match')); return; }

    setState(() { _loading = true; _error = null; });

    try {
      // TODO: استبدلي هاد بطلب حقيقي للباك اند لما يجهز
      // final res = await http.post(
      //   Uri.parse(_AuthApi.resetPassword),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({'email': widget.email, 'otp': widget.otp, 'new_password': nw}),
      // );
      // if (res.statusCode != 200) throw Exception('فشل التغيير');

      // حفظ محلي مؤقت
      adminPassword = nw;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_password', adminPassword);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.get('password_changed'),
            textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (r) => false,
      );
    } catch (e) {
      setState(() => _error = L.isArabic ? 'حدث خطأ، حاول مجدداً' : 'An error occurred, try again');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0f1c35),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0f1c35),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4B9EFF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF4B9EFF), size: 32),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      L.isArabic ? 'كلمة مرور جديدة' : 'New Password',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      L.isArabic ? 'أدخل كلمة المرور الجديدة' : 'Enter your new password',
                      style: const TextStyle(color: Color(0xFF8aaccc), fontSize: 13),
                    ),
                    const SizedBox(height: 32),

                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
                        ]),
                      ),
                    ],

                    _buildPassField(ctrl: _newCtrl, label: L.get('new_password'), visible: _newVis, onToggle: () => setState(() => _newVis = !_newVis)),
                    const SizedBox(height: 16),
                    _buildPassField(ctrl: _confCtrl, label: L.get('confirm_password'), visible: _confVis, onToggle: () => setState(() => _confVis = !_confVis)),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF1a2d50), borderRadius: BorderRadius.circular(8)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _reqRow(L.get('val_pass_short')),
                        _reqRow(L.get('val_pass_upper')),
                        _reqRow(L.get('val_pass_number')),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5B800),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _loading ? null : _reset,
                        child: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF0f1c35), strokeWidth: 2))
                            : Text(
                                L.isArabic ? 'تغيير كلمة المرور' : 'Reset Password',
                                style: const TextStyle(color: Color(0xFF0f1c35), fontSize: 15, fontWeight: FontWeight.bold),
                              ),
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

  Widget _buildPassField({required TextEditingController ctrl, required String label, required bool visible, required VoidCallback onToggle}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Color(0xFF8aaccc), fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        obscureText: !visible,
        textDirection: TextDirection.ltr,
        onChanged: (_) => setState(() => _error = null),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF4a5f7a), size: 18),
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(0xFF4a5f7a)),
            onPressed: onToggle,
          ),
          filled: true,
          fillColor: const Color(0xFF1a2d50),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2a3f68))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2a3f68))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFF5B800), width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _reqRow(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      const Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF8aaccc)),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF8aaccc))),
    ]),
  );

  @override
  void dispose() {
    _newCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }
}