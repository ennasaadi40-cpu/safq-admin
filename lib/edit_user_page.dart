part of station_app;

class EditUserPage extends StatefulWidget {
  final UserModel user;
  const EditUserPage({super.key, required this.user});
  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> with DarkModeRebuild<EditUserPage> {
  final _formKey           = GlobalKey<FormState>();
  late final _nameCtrl         = TextEditingController(text: widget.user.name);
  late final _usernameCtrl     = TextEditingController(text: widget.user.username);
  late final _passwordCtrl     = TextEditingController(text: widget.user.password);
  late final _phoneCtrl        = TextEditingController(text: widget.user.phone);
  late final _idCtrl           = TextEditingController(text: widget.user.idNumber);
  late final _licenseNumCtrl   = TextEditingController(text: widget.user.licenseNum);
  late final _licenseExpiryCtrl = TextEditingController(text: widget.user.licenseExpiry);
  late String? _selectedRole   = widget.user.role;
  late String? _selectedStatus = widget.user.status;
  late bool _isActive          = widget.user.isActive;
  bool _obscurePassword = true;
  // FocusNodes
  final _feName = FocusNode(); final _feUsername = FocusNode();
  final _fePassword = FocusNode(); final _fePhone = FocusNode();
  final _feId = FocusNode(); final _feLicNum = FocusNode();

  static const List<String> _roles     = ['سائق', 'موظف أمن', 'مشرف خط'];
  static const List<String> _statuses  = ['نشط', 'معلق', 'محظور'];

  @override
  void dispose() {
    _nameCtrl.dispose(); _usernameCtrl.dispose(); _passwordCtrl.dispose();
    _phoneCtrl.dispose(); _idCtrl.dispose();
    _feName.dispose(); _feUsername.dispose(); _fePassword.dispose();
    _fePhone.dispose(); _feId.dispose(); _feLicNum.dispose();
    super.dispose();
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    filled: true,
    fillColor: context.cardColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.dividerColor)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D3A5C), width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red)),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: TextStyle(
        fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
  );

  void _save() {
    if (_formKey.currentState!.validate()) {
      final updated = UserModel(
        name:          _nameCtrl.text.trim(),
        username:      _usernameCtrl.text.trim().isNotEmpty
                           ? _usernameCtrl.text.trim()
                           : widget.user.username,
        role:          _selectedRole!,
        status:        _isActive ? 'نشط' : (_selectedStatus ?? 'معلق'),
        phone:         _phoneCtrl.text.trim(),
        idNumber:      _idCtrl.text.trim(),
        licenseNum:    _licenseNumCtrl.text.trim(),
        licenseExpiry: _licenseExpiryCtrl.text.trim(),
        isActive:      _isActive,
        password:      _passwordCtrl.text.isNotEmpty
                           ? _passwordCtrl.text
                           : widget.user.password,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('تم تعديل المستخدم بنجاح ✓',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      logEvent(EventItem(
        vehicleId: 'مستخدم: ${updated.name}',
        location: 'تعديل بيانات المستخدم — ${updated.role}',
        time: nowTime(),
        type: EventType.exit,
      ));
      Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context, updated));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D3A5C),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(L.get('edit_user'),
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الاسم الكامل
                _label(L.get('full_name')),
                TextFormField(
         onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  controller: _nameCtrl,
                  decoration: _inputDec('ادخل اسم المستخدم كاملاً'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'الاسم مطلوب';
                    final name = v.trim();
                    if (name.length < 3) return '3 أحرف على الأقل';
                    // لا أرقام أو رموز
                    if (!RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(name))
                      return 'الاسم يجب أن يحتوي على أحرف فقط';
                    // لا تكرار — إلا إذا هو نفس الاسم الأصلي
                    final original = widget.user.name.trim().toLowerCase();
                    if (name.toLowerCase() != original) {
                      final exists = globalUsers.any((u) =>
                          u.name.trim().toLowerCase() == name.toLowerCase());
                      if (exists) return 'هذا الاسم مسجل مسبقاً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Username
                _label('اسم المستخدم'),
                TextFormField(
         onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  controller: _usernameCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: _inputDec(widget.user.username.isNotEmpty
                      ? widget.user.username : 'Enter username'),
                ),
                const SizedBox(height: 16),

                // Password
                _label('كلمة المرور'),
                TextFormField(
                          controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  decoration: _inputDec('كلمة السر الحالية: ${widget.user.password.isNotEmpty ? "●" * widget.user.password.length : "غير محددة"}').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Role
                _label('الدور'),
                _SearchableDropdown(
                  hint: 'اختر الدور',
                  items: _roles,
                  selected: _selectedRole,
                  onSelected: (v) => setState(() => _selectedRole = v),
                  validator: (v) => v == null ? 'اختر الدور' : null,
                ),
                const SizedBox(height: 16),

                // رقم الهاتف
                _label(L.get('phone')),
                TextFormField(
                          controller: _phoneCtrl,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: _inputDec('05xxxxxxxx — 10 أرقام'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // اختياري
                    final digits = v.trim().replaceAll(RegExp(r'\D'), '');
                    if (digits.length != 10) return 'رقم الهاتف يجب أن يكون 10 أرقام بالظبط';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // رقم الهوية
                _label(L.get('id_number')),
                TextFormField(
                          controller: _idCtrl,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                  maxLength: 9,
                  decoration: _inputDec('ادخل رقم الهوية (9 أرقام)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'رقم الهوية مطلوب';
                    if (!RegExp(r'^\d+$').hasMatch(v.trim())) return 'أرقام فقط — لا حروف أو رموز';
                    if (v.trim().length != 9) return 'رقم الهوية يجب أن يكون 9 أرقام بالظبط';
                    return null;
                  },
                ),

                // حقول الرخصة — للسائق فقط
                if (_selectedRole == 'سائق') ...[
                  const SizedBox(height: 16),
                  _label('رقم الرخصة'),
                  TextFormField(
         onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    controller: _licenseNumCtrl,
                    textDirection: TextDirection.ltr,
                    decoration: _inputDec('ادخل رقم الرخصة'),
                  ),
                  const SizedBox(height: 16),
                  _label('تاريخ انتهاء الرخصة'),
                  TextFormField(
         onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    controller: _licenseExpiryCtrl,
                    textDirection: TextDirection.ltr,
                    decoration: _inputDec('YYYY-MM-DD').copyWith(
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2040),
                          );
                          if (picked != null) {
                            _licenseExpiryCtrl.text =
                                '${picked.year}-${picked.month.toString().padLeft(2, "0")}-${picked.day.toString().padLeft(2, "0")}';
                          }
                        },
                      ),
                    ),
                    validator: (v) => validateDate(v, required: false),
                  ),
                ],

                // حالة الحساب
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الحساب مفعّل', style: TextStyle(fontSize: 14, color: context.textPrimary)),
                      Switch(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeTrackColor: const Color(0xFF2D3A5C),
                        activeThumbColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // زر الحفظ
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3A5C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('حفظ المستخدم',
                        style: TextStyle(color: Colors.white,
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}