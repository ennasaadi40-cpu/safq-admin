part of station_app;

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});
  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> with DarkModeRebuild<AddUserPage> {
  final _formKey           = GlobalKey<FormState>();
  final _nameCtrl          = TextEditingController();
  final _usernameCtrl      = TextEditingController();
  final _passwordCtrl      = TextEditingController();
  final _phone1Ctrl        = TextEditingController();
  final _phone2Ctrl        = TextEditingController();
  final _idCtrl            = TextEditingController();
  final _licenseNumCtrl    = TextEditingController();
  final _licenseGradeCtrl  = TextEditingController();
  final _licenseExpiryCtrl = TextEditingController();
  final _medicalExpiryCtrl = TextEditingController();
  final _macAddressCtrl    = TextEditingController();

  final _fName     = FocusNode();
  final _fUsername = FocusNode();
  final _fPassword = FocusNode();
  final _fPhone1   = FocusNode();
  final _fPhone2   = FocusNode();
  final _fId       = FocusNode();
  final _fLicNum   = FocusNode();
  final _fLicGrade = FocusNode();

  String? _selectedRole;
  String? _selectedStation;
  bool _passwordVisible = false;
  bool _isActive        = true;

  List<String> get _roles => [L.get('driver'), L.get('security'), L.get('supervisor')];

  @override
  void dispose() {
    _nameCtrl.dispose(); _usernameCtrl.dispose(); _passwordCtrl.dispose();
    _phone1Ctrl.dispose(); _phone2Ctrl.dispose(); _idCtrl.dispose();
    _licenseNumCtrl.dispose(); _licenseGradeCtrl.dispose();
    _licenseExpiryCtrl.dispose(); _medicalExpiryCtrl.dispose(); _macAddressCtrl.dispose();
    _fName.dispose(); _fUsername.dispose(); _fPassword.dispose();
    _fPhone1.dispose(); _fPhone2.dispose(); _fId.dispose();
    _fLicNum.dispose(); _fLicGrade.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2, "0")}-${picked.day.toString().padLeft(2, "0")}';
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      // نحول الدور المترجم لقيمة عربية ثابتة للتخزين
      String roleStorage = _selectedRole ?? '';
      if (_selectedRole == L.get('driver'))     roleStorage = 'سائق';
      if (_selectedRole == L.get('security'))   roleStorage = 'موظف أمن';
      if (_selectedRole == L.get('supervisor')) roleStorage = 'مشرف خط';

      // ✅ المحطة إلزامية لكل الأدوار ما عدا السائق
      final bool needsStation = roleStorage != 'سائق';

      final newUser = UserModel(
        name:          _nameCtrl.text.trim(),
        username:      _usernameCtrl.text.trim(),
        role:          roleStorage,
        status:        _isActive ? 'نشط' : 'معلق',
        phone:         _phone1Ctrl.text.trim(),
        phone2:        _phone2Ctrl.text.trim(),
        idNumber:      _idCtrl.text.trim(),
        licenseNum:    _licenseNumCtrl.text.trim(),
        licenseGrade:  _licenseGradeCtrl.text.trim(),
        licenseExpiry: _licenseExpiryCtrl.text.trim(),
        medicalExpiry: _medicalExpiryCtrl.text.trim(),
        isActive:      _isActive,
        password:      _passwordCtrl.text.trim(),
        station:       needsStation ? (_selectedStation ?? '') : '',
      );
      logEvent(EventItem(
        vehicleId: '${L.get('user')}: ${newUser.name}',
        location:  '${L.get('add_user')} — ${newUser.role}',
        time:      nowTime(),
        type:      EventType.entry,
      ));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(L.get('user_saved'),
              textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
        ]),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
      Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context, newUser));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDriver = _selectedRole == L.get('driver');
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D3A5C),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(L.get('add_user'),
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عنوان
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(L.get('add_user'),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── الاسم ──────────────────────────
                      _FieldLabel(text: L.get('full_name')),
                      _FormField(
                        controller: _nameCtrl,
                        focusNode: _fName, nextFocus: _fUsername,
                        hint: L.get('enter_name'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return L.get('val_name_required');
                          if (v.trim().length < 3) return L.get('val_name_short');
                          if (!RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(v.trim()))
                            return L.get('val_name_letters');
                          if (globalUsers.any((u) => u.name.trim().toLowerCase() == v.trim().toLowerCase()))
                            return L.get('val_name_exists');
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── Username ────────────────────────
                      _FieldLabel(text: L.get('username')),
                      _FormField(
                        controller: _usernameCtrl,
                        focusNode: _fUsername, nextFocus: _fPassword,
                        hint: L.get('enter_username'),
                        isLtr: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return L.get('val_username_required');
                          if (v.trim().length < 4) return L.get('val_username_short');
                          if (v.contains(' ')) return L.get('val_username_spaces');
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── Password ────────────────────────
                      _FieldLabel(text: L.get('password')),
                      _FormField(
                        controller: _passwordCtrl,
                        focusNode: _fPassword, nextFocus: _fPhone1,
                        hint: L.get('enter_password'),
                        isLtr: true,
                        obscure: !_passwordVisible,
                        validator: (v) {
                          if (v == null || v.isEmpty) return L.get('val_pass_required');
                          if (v.length < 8) return L.get('val_pass_short');
                          if (!v.contains(RegExp(r'[A-Z]'))) return L.get('val_pass_upper');
                          if (!v.contains(RegExp(r'[0-9]'))) return L.get('val_pass_number');
                          return null;
                        },
                        suffix: IconButton(
                          icon: Icon(_passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18, color: Colors.grey),
                          onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Role ────────────────────────────
                      _FieldLabel(text: L.get('role')),
                      _SearchableDropdown(
                        hint: L.get('choose_role'),
                        items: _roles,
                        selected: _selectedRole,
                        onSelected: (v) => setState(() {
                          _selectedRole = v;
                          // السائق ما إله محطة ثابتة — نفضّي الاختيار لو تغيّر الدور
                          if (v == L.get('driver')) _selectedStation = null;
                        }),
                        validator: (v) => (v == null || v.isEmpty)
                            ? L.get('val_role_required')
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // ── Station (كل الأدوار ما عدا السائق) ──
                      if (_selectedRole != null && _selectedRole != L.get('driver')) ...[
                        _FieldLabel(text: L.get('station')),
                        _SearchableDropdown(
                          hint: L.get('choose_station'),
                          items: stationsList,
                          selected: _selectedStation,
                          onSelected: (v) => setState(() => _selectedStation = v),
                          validator: (v) => (v == null || v.isEmpty)
                              ? L.get('val_station_required')
                              : null,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── رقم الهوية ──────────────────────
                      _FieldLabel(text: L.get('id_number')),
                      _FormField(
                        controller: _idCtrl,
                        focusNode: _fId, nextFocus: _fPhone1,
                        hint: L.get('enter_id'),
                        keyboardType: TextInputType.number,
                        maxLength: 9,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return L.get('val_id_required');
                          if (!RegExp(r'^\d+$').hasMatch(v.trim())) return L.get('val_id_numbers');
                          if (v.trim().length != 9) return L.get('val_id_length');
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── رقم الهاتف 1 ───────────────────
                      _FieldLabel(text: L.get('phone_required')),
                      _FormField(
                        controller: _phone1Ctrl,
                        focusNode: _fPhone1, nextFocus: _fPhone2,
                        hint: L.get('enter_phone'),
                        keyboardType: TextInputType.phone,
                        isLtr: true,
                        maxLength: 10,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return L.get('val_phone_required');
                          final d = v.trim().replaceAll(RegExp(r'\D'), '');
                          if (d.length != 10) return L.get('val_phone_length');
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── رقم الهاتف 2 ───────────────────
                      _FieldLabel(text: L.get('phone_optional')),
                      _FormField(
                        controller: _phone2Ctrl,
                        focusNode: _fPhone2, nextFocus: isDriver ? _fLicNum : null,
                        hint: L.get('enter_phone'),
                        keyboardType: TextInputType.phone,
                        isLtr: true,
                        maxLength: 10,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final d = v.trim().replaceAll(RegExp(r'\D'), '');
                          if (d.length != 10) return L.get('val_phone_length');
                          return null;
                        },
                      ),

                      // ── حقول السائق فقط ─────────────────
                      if (isDriver) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D3A5C).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(children: [
                            const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF2D3A5C)),
                            const SizedBox(width: 8),
                            Text(L.get('license_data'),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
                          ]),
                        ),
                        const SizedBox(height: 14),

                        _FieldLabel(text: L.get('license_num')),
                        _FormField(
                          controller: _licenseNumCtrl,
                          focusNode: _fLicNum, nextFocus: _fLicGrade,
                          hint: L.get('enter_license'),
                          isLtr: true,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return L.get('val_license_required');
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        _FieldLabel(text: L.get('license_grade')),
                        _FormField(
                          controller: _licenseGradeCtrl,
                          focusNode: _fLicGrade,
                          hint: L.get('enter_grade'),
                          isLtr: true,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return L.get('val_grade_required');
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        _FieldLabel(text: L.get('license_expiry')),
                        _FormField(
                          controller: _licenseExpiryCtrl,
                          hint: L.get('date_format'),
                          isLtr: true,
                          keyboardType: TextInputType.datetime,
                          suffix: IconButton(
                            icon: const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                            onPressed: () => _pickDate(_licenseExpiryCtrl),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return L.get('val_expiry_required');
                            return validateDate(v, required: true);
                          },
                        ),
                        const SizedBox(height: 14),

                        _FieldLabel(text: L.get('medical_expiry')),
                        _FormField(
                          controller: _medicalExpiryCtrl,
                          hint: L.get('date_format'),
                          isLtr: true,
                          keyboardType: TextInputType.datetime,
                          suffix: IconButton(
                            icon: const Icon(Icons.medical_services_outlined, size: 16, color: Colors.grey),
                            onPressed: () => _pickDate(_medicalExpiryCtrl),
                          ),
                          validator: (v) => validateDate(v, required: false),
                        ),
                        const SizedBox(height: 14),

                        _FieldLabel(text: L.get('mac_address')),
                        _FormField(
                          controller: _macAddressCtrl,
                          hint: L.get('enter_mac'),
                          isLtr: true,
                          keyboardType: TextInputType.text,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final clean = v.trim().replaceAll('-', ':').toUpperCase();
                            if (!RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$').hasMatch(clean))
                              return L.get('val_mac_invalid');
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 14),
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
                            Text(L.get('account_active'),
                                style: TextStyle(fontSize: 14, color: context.textPrimary)),
                            Switch(
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                              activeTrackColor: const Color(0xFF2D3A5C),
                              activeThumbColor: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3A5C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(L.get('save_user'),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

// ── Form helper widgets ───────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
      );
}

class _FormField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool isLtr;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final int? maxLength;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final TextInputAction? inputAction;
  final VoidCallback? onSubmit;
  const _FormField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.isLtr = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.maxLength,
    this.focusNode,
    this.nextFocus,
    this.inputAction,
    this.onSubmit,
  });
  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  final _kbFocus = FocusNode();

  @override
  void dispose() { _kbFocus.dispose(); super.dispose(); }

  void _handleEnter() {
    if (widget.nextFocus != null) FocusScope.of(context).requestFocus(widget.nextFocus);
    else if (widget.onSubmit != null) widget.onSubmit!();
    else FocusScope.of(context).nextFocus();
  }

  @override
  Widget build(BuildContext context) => KeyboardListener(
    focusNode: _kbFocus,
    onKeyEvent: (event) {
      if (event is KeyDownEvent &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
           event.logicalKey == LogicalKeyboardKey.numpadEnter ||
           event.logicalKey == LogicalKeyboardKey.tab)) {
        _handleEnter();
      }
    },
    child: TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      textInputAction: widget.inputAction ?? (widget.nextFocus != null ? TextInputAction.next : TextInputAction.done),
      onFieldSubmitted: (_) => _handleEnter(),
      onEditingComplete: () => _handleEnter(),
      obscureText: widget.obscure,
      keyboardType: widget.keyboardType,
      textDirection: widget.isLtr ? TextDirection.ltr : TextDirection.rtl,
      validator: widget.validator,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB0B8CC)),
        suffixIcon: widget.suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E4EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2D3A5C), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    ),
  );
}