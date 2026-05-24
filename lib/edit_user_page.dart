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
  late final _phoneCtrl        = TextEditingController(text: widget.user.phone);
  late final _idCtrl           = TextEditingController(text: widget.user.idNumber);
  late final _licenseNumCtrl   = TextEditingController(text: widget.user.licenseNum);
  late final _licenseExpiryCtrl = TextEditingController(text: widget.user.licenseExpiry);
  late String? _selectedRole   = widget.user.role;
  late String _currentPassword  = widget.user.password;
  late String? _selectedStatus = widget.user.status;
  late bool _isActive          = widget.user.isActive;
  
  // FocusNodes
  final _feName = FocusNode(); final _feUsername = FocusNode();
  final _fePassword = FocusNode(); final _fePhone = FocusNode();
  final _feId = FocusNode(); final _feLicNum = FocusNode();

  List<String> get _roles => [L.get('driver'), L.get('security'), L.get('supervisor')];
  List<String> get _statuses => [L.get('active'), L.get('suspended'), L.get('banned')];

  @override
  void dispose() {
    _nameCtrl.dispose(); _usernameCtrl.dispose();
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
      // نحول الدور المترجم لقيمة عربية ثابتة للتخزين
      String roleStorage = _selectedRole ?? '';
      if (_selectedRole == L.get('driver'))     roleStorage = 'سائق';
      if (_selectedRole == L.get('security'))   roleStorage = 'موظف أمن';
      if (_selectedRole == L.get('supervisor')) roleStorage = 'مشرف خط';

      final updated = UserModel(
        name:          _nameCtrl.text.trim(),
        username:      _usernameCtrl.text.trim().isNotEmpty
                           ? _usernameCtrl.text.trim()
                           : widget.user.username,
        role:          roleStorage,
        status:        _isActive ? 'نشط' : (_selectedStatus ?? 'معلق'),
        phone:         _phoneCtrl.text.trim(),
        idNumber:      _idCtrl.text.trim(),
        licenseNum:    _licenseNumCtrl.text.trim(),
        licenseExpiry: _licenseExpiryCtrl.text.trim(),
        isActive:      _isActive,
        password:      _currentPassword,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(L.get('user_saved'),
              textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      logEvent(EventItem(
        vehicleId: '${L.get('user')}: ${updated.name}',
        location: '${L.get('edit_user')} — ${updated.role}',
        time: nowTime(),
        type: EventType.exit,
      ));
      Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context, updated));
    }
  }

  void _changePassword(BuildContext context) {
    final newPassCtrl  = TextEditingController();
    final confPassCtrl = TextEditingController();
    bool showNew = false, showConf = false;
    String? error;

    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, setDlg) => Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF2D3A5C).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.lock_outline, color: Color(0xFF2D3A5C), size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(L.get('change_password'),
              style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 15))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(L.get('new_password'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
          const SizedBox(height: 6),
          TextField(controller: newPassCtrl, obscureText: !showNew, textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
              suffixIcon: IconButton(icon: Icon(showNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                onPressed: () => setDlg(() => showNew = !showNew)),
            )),
          const SizedBox(height: 12),
          Text(L.get('confirm_password'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
          const SizedBox(height: 6),
          TextField(controller: confPassCtrl, obscureText: !showConf, textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
              suffixIcon: IconButton(icon: Icon(showConf ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                onPressed: () => setDlg(() => showConf = !showConf)),
            )),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: Color(0xFFFF5A5F), fontSize: 12)),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text(L.get('cancel'), style: TextStyle(color: ctx.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D3A5C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              if (newPassCtrl.text.isEmpty) { setDlg(() => error = L.get('enter_password')); return; }
              if (newPassCtrl.text != confPassCtrl.text) { setDlg(() => error = L.get('passwords_not_match')); return; }
              final idx = globalUsers.indexWhere((u) => u.name == widget.user.name);
              if (idx != -1) {
                globalUsers[idx] = UserModel(
                  name: globalUsers[idx].name, role: globalUsers[idx].role,
                  status: globalUsers[idx].status, phone: globalUsers[idx].phone,
                  idNumber: globalUsers[idx].idNumber, licenseNum: globalUsers[idx].licenseNum,
                  licenseExpiry: globalUsers[idx].licenseExpiry, isActive: globalUsers[idx].isActive,
                  licenseIssueDate: globalUsers[idx].licenseIssueDate,
                  licenseGrade: globalUsers[idx].licenseGrade,
                  username: globalUsers[idx].username, macAddress: globalUsers[idx].macAddress,
                  password: newPassCtrl.text,
                );
                autoSave();
                setState(() => _currentPassword = newPassCtrl.text);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(L.get('password_changed'), textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr),
                backgroundColor: const Color(0xFF2E7D32), behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16),
              ));
            },
            child: Text(L.get('save'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
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
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  decoration: _inputDec(L.get('enter_name')),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return L.get('val_name_required');
                    final name = v.trim();
                    if (name.length < 3) return L.get('val_name_short');
                    if (!RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(name))
                      return L.get('val_name_letters');
                    final original = widget.user.name.trim().toLowerCase();
                    if (name.toLowerCase() != original) {
                      final exists = globalUsers.any((u) =>
                          u.name.trim().toLowerCase() == name.toLowerCase());
                      if (exists) return L.get('val_name_exists');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Username
                _label(L.get('username')),
                TextFormField(
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  controller: _usernameCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: _inputDec(widget.user.username.isNotEmpty
                      ? widget.user.username : L.get('enter_username')),
                ),
                const SizedBox(height: 16),

                // Role
                _label(L.get('role')),
                _SearchableDropdown(
                  hint: L.get('choose_role'),
                  items: _roles,
                  selected: _selectedRole,
                  onSelected: (v) => setState(() => _selectedRole = v),
                  validator: (v) => v == null ? L.get('val_role_required') : null,
                ),
                const SizedBox(height: 16),

                // رقم الهاتف
                _label(L.get('phone')),
                TextFormField(
                  controller: _phoneCtrl,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: _inputDec(L.get('enter_phone')),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final digits = v.trim().replaceAll(RegExp(r'\D'), '');
                    if (digits.length != 10) return L.get('val_phone_length');
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
                  decoration: _inputDec(L.get('enter_id')),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return L.get('val_id_required');
                    if (!RegExp(r'^\d+$').hasMatch(v.trim())) return L.get('val_id_numbers');
                    if (v.trim().length != 9) return L.get('val_id_length');
                    return null;
                  },
                ),

                // حقول الرخصة — للسائق فقط
                if (_selectedRole == L.get('driver')) ...[
                  const SizedBox(height: 16),
                  _label(L.get('license_num')),
                  TextFormField(
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    controller: _licenseNumCtrl,
                    textDirection: TextDirection.ltr,
                    decoration: _inputDec(L.get('enter_license')),
                  ),
                  const SizedBox(height: 16),
                  _label(L.get('license_expiry')),
                  TextFormField(
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    controller: _licenseExpiryCtrl,
                    textDirection: TextDirection.ltr,
                    decoration: _inputDec(L.get('date_format')).copyWith(
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
                      Text(L.get('account_active'), style: TextStyle(fontSize: 14, color: context.textPrimary)),
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
                    child: Text(L.get('save_user'),
                        style: const TextStyle(color: Colors.white,
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