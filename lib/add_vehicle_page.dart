part of station_app;

class _AddVehiclePage extends StatefulWidget {
  final String lineName;
  final String? presetOwner;
  final void Function(String vehicleId, String qrCode, String vehicleType,
      String licenseExpiry, String ownerName, String driverName, String status,
      {String carLicExpiry, String insuranceExpiry, String? newLineName}) onSave;

  const _AddVehiclePage({required this.lineName, required this.onSave, this.presetOwner});

  @override
  State<_AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<_AddVehiclePage> with DarkModeRebuild<_AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();

  // ── بيانات المالك
  final _ownerNameCtrl  = TextEditingController(); // اسم المالك
  final _ownerPhoneCtrl = TextEditingController(); // هاتف المالك
  final _ownerIdCtrl    = TextEditingController(); // هوية المالك

  // ── بطاقة السيارة
  final _loadingExpiryCtrl = TextEditingController(); // تاريخ انتهاء التحميل
  final _plateCtrl      = TextEditingController(); // رقم المركبة
  final _rfidCtrl       = TextEditingController(); // RFID Tag
  final _makerCtrl      = TextEditingController(); // الشركة المصنعة
  final _modelCtrl      = TextEditingController(); // طراز السيارة
  final _yearCtrl       = TextEditingController(); // سنة الإنتاج
  final _chassisCtrl    = TextEditingController(); // رقم الشصي

  // ── بطاقة الترخيص
  final _opLicNumCtrl   = TextEditingController(); // رقم رخصة التشغيل
  final _opLicExpCtrl   = TextEditingController(); // انتهاء رخصة التشغيل
  final _carLicExpCtrl  = TextEditingController(); // انتهاء الترخيص
  final _insExpCtrl     = TextEditingController(); // انتهاء التأمين

  // ── المالك والسائق والخط
  String? _selectedDriver;
  String? _selectedLine;


  List<UserModel> get _drivers => globalUsers.where((u) => u.role == 'سائق').toList();

  @override
  void initState() {
    super.initState();
    if (widget.presetOwner != null) _ownerNameCtrl.text = widget.presetOwner!;
    _selectedLine = widget.lineName.isNotEmpty
        ? widget.lineName
        : null;
  }

  InputDecoration _dec(String hint, {IconData? icon}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    filled: true,
    fillColor: context.cardColor,
    prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF2D3A5C)) : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: context.dividerColor)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2D3A5C), width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red)),
  );

  Widget _sectionHeader(String title, Color accent, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 4),
    child: Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: accent),
      ),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: accent)),
    ]),
  );

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
        color: context.textSecondary)),
  );

  Future<void> _pickDate(TextEditingController ctrl) async {
    FocusScope.of(context).requestFocus(FocusNode());
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2,"0")}-${picked.day.toString().padLeft(2,"0")}';
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
          foregroundColor: Colors.white,
          title: Text('إضافة مركبة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ══ بطاقة معلومات السيارة ══════════════
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionHeader('معلومات المركبة', const Color(0xFF00C897), Icons.directions_car_outlined),

                _fieldLabel('رقم اللوحة'),
                TextFormField(
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  controller: _plateCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: _dec('مثال: 35-123-17', icon: Icons.tag),
                  validator: (v) => v == null || v.trim().isEmpty ? 'رقم المركبة مطلوب' : null,
                ),
                const SizedBox(height: 12),

                _fieldLabel('وسم RFID'),
                TextFormField(
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  controller: _rfidCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: _dec('مثال: RFID-458921', icon: Icons.nfc),
                ),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel('الشركة المصنعة'),
                    TextFormField(
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      controller: _makerCtrl,
                      decoration: _dec('مثال: Toyota', icon: Icons.factory_outlined),
                    ),
                  ])),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel('الطراز'),
                    TextFormField(
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      controller: _modelCtrl,
                      decoration: _dec('مثال: Hiace', icon: Icons.directions_car_outlined),
                    ),
                  ])),
                ]),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel('سنة الإنتاج'),
                    TextFormField(
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      controller: _yearCtrl,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      decoration: _dec('مثال: 2020', icon: Icons.calendar_month_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final y = int.tryParse(v.trim());
                        if (y == null || y < 1980 || y > DateTime.now().year + 1) return 'سنة غير صحيحة';
                        return null;
                      },
                    ),
                  ])),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel('رقم الشصي'),
                    TextFormField(
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      controller: _chassisCtrl,
                      textDirection: TextDirection.ltr,
                      decoration: _dec('رقم الشصي', icon: Icons.numbers),
                    ),
                  ])),
                ]),
              ])),
              const SizedBox(height: 12),

              // ══ بطاقة ترخيص التشغيل ════════════════
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionHeader('رخصة التشغيل', const Color(0xFFFFB347), Icons.verified_outlined),

                _fieldLabel('رقم رخصة التشغيل'),
                TextFormField(
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  controller: _opLicNumCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: _dec('مثال: OP-2024-556', icon: Icons.numbers),
                ),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel('انتهاء رخصة التشغيل'),
                    TextFormField(
                      controller: _opLicExpCtrl,
                      readOnly: true,
                      decoration: _dec('YYYY-MM-DD', icon: Icons.event_busy_outlined).copyWith(
                        suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2D3A5C)),
                      ),
                      onTap: () => _pickDate(_opLicExpCtrl),
                      validator: (v) => validateDate(v, required: false),
                    ),
                  ])),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel('انتهاء الترخيص'),
                    TextFormField(
                      controller: _carLicExpCtrl,
                      readOnly: true,
                      decoration: _dec('YYYY-MM-DD', icon: Icons.event_busy_outlined).copyWith(
                        suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2D3A5C)),
                      ),
                      onTap: () => _pickDate(_carLicExpCtrl),
                      validator: (v) => validateDate(v, required: false),
                    ),
                  ])),
                ]),
                const SizedBox(height: 12),

                _fieldLabel('انتهاء التأمين'),
                TextFormField(
                  controller: _insExpCtrl,
                  readOnly: true,
                  decoration: _dec('YYYY-MM-DD', icon: Icons.shield_outlined).copyWith(
                    suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2D3A5C)),
                  ),
                  onTap: () => _pickDate(_insExpCtrl),
                  validator: (v) => validateDate(v, required: false),
                ),
                const SizedBox(height: 12),

                _fieldLabel('انتهاء التحميل'),
                TextFormField(
                  controller: _loadingExpiryCtrl,
                  readOnly: true,
                  decoration: _dec('YYYY-MM-DD', icon: Icons.local_shipping_outlined).copyWith(
                    suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2D3A5C)),
                  ),
                  onTap: () => _pickDate(_loadingExpiryCtrl),
                  validator: (v) => validateDate(v, required: false),
                ),
                const SizedBox(height: 8),
                // أزرار تمديد سريعة
                Wrap(
                  spacing: 8,
                  children: [1, 3, 7, 14, 30].map((days) {
                    return _Tap(
                      onTap: () {
                        final base = _loadingExpiryCtrl.text.isNotEmpty
                            ? () {
                                try {
                                  final p = _loadingExpiryCtrl.text.split('-');
                                  final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
                                  return d.isAfter(DateTime.now()) ? d : DateTime.now();
                                } catch (_) { return DateTime.now(); }
                              }()
                            : DateTime.now();
                        final newDate = base.add(Duration(days: days));
                        setState(() {
                              _loadingExpiryCtrl.text = '${newDate.year}-${newDate.month.toString().padLeft(2,"0")}-${newDate.day.toString().padLeft(2,"0")}';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4B9EFF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF4B9EFF).withValues(alpha: 0.3)),
                        ),
                        child: Text('+$days يوم',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF4B9EFF), fontWeight: FontWeight.bold)),
                      ),
                    );
                  }).toList(),
                ),
              ])),
              const SizedBox(height: 12),

              // ══ بطاقة المالك والسائق والخط ═════════
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionHeader('المالك والسائق والخط', const Color(0xFFB47AFF), Icons.people_outlined),

                _sectionHeader('معلومات المالك', const Color(0xFFB47AFF), Icons.badge_outlined),

                _fieldLabel('اسم المالك'),
                TextFormField(
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  controller: _ownerNameCtrl,
                  decoration: _dec('أدخل اسم المالك', icon: Icons.person_outline),
                  validator: (v) => v == null || v.trim().isEmpty ? 'اسم المالك مطلوب' : null,
                ),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel('هاتف المالك'),
                    TextFormField(
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      controller: _ownerPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      maxLength: 10,
                      decoration: _dec('05xxxxxxxx', icon: Icons.phone_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final d = v.trim().replaceAll(RegExp(r'\D'), '');
                        if (d.length != 10) return '10 أرقام بالضبط';
                        return null;
                      },
                    ),
                  ])),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel('هوية المالك'),
                    TextFormField(
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      controller: _ownerIdCtrl,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      maxLength: 9,
                      decoration: _dec('xxxxxxxxx', icon: Icons.badge_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (!RegExp(r'^\d+$').hasMatch(v.trim())) return 'أرقام فقط';
                        if (v.trim().length != 9) return '9 أرقام بالضبط';
                        return null;
                      },
                    ),
                  ])),
                ]),
                const SizedBox(height: 12),

                _fieldLabel('السائق'),
                _SearchableDropdown(
                  hint: 'ابحث عن سائق',
                  items: ['بدون سائق', ..._drivers.map((u) => u.name)],
                  selected: _selectedDriver,
                  onSelected: (v) => setState(() => _selectedDriver = v == 'بدون سائق' ? '' : v),
                  validator: (v) => (v == null || v.isEmpty) ? 'اختر السائق' : null,
                ),
                const SizedBox(height: 12),

                _fieldLabel('الخط'),
                globalLines.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4B9EFF).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF4B9EFF).withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline, size: 15, color: Color(0xFF4B9EFF)),
                        const SizedBox(width: 8),
                        Text('لا توجد خطوط — ستُحفظ تحت "بدون خط"',
                            style: TextStyle(fontSize: 12, color: context.textSecondary)),
                      ]),
                    )
                  : _SearchableDropdown(
                      hint: 'اختر الخط',
                      items: globalLines.map((l) => l.name).toList(),
                      selected: _selectedLine,
                      onSelected: (v) => setState(() => _selectedLine = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'اختر الخط' : null,
                    ),

              ])),

              const SizedBox(height: 24),

              // ── زر الحفظ ─────────────────────────────
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D3A5C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text('حفظ',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;

                    // ── فحص إذا المركبة محظورة ──────────────
                    final plateNum = _plateCtrl.text.trim();
                    bool isBanned = false;
                    for (final list in globalVehicles) {
                      for (final v in list) {
                        if (v.vehicleId == plateNum && v.status == 'محظورة') {
                          isBanned = true;
                          break;
                        }
                      }
                      if (isBanned) break;
                    }
                    if (isBanned) {
                      // إرسال تنبيه لموظف الأمن
                      globalSecurityNotifications.insert(0, {
                        'title': '🚫 مركبة محظورة حاولت التسجيل',
                        'body': 'المركبة $plateNum محظورة ومطلوبة لدى مدير المحطة',
                        'time': nowTime(),
                        'type': 'banned',
                      });
                      showDialog(
                        context: context,
                        builder: (_) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5A5F).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.block_rounded, color: Color(0xFFFF5A5F), size: 22),
                              ),
                              const SizedBox(width: 10),
                              const Text('مركبة محظورة', style: TextStyle(color: Color(0xFFFF5A5F), fontWeight: FontWeight.bold)),
                            ]),
                            content: Text(
                              'المركبة $plateNum محظورة من النظام.\n\nتم إرسال تنبيه لموظف الأمن — المركبة مطلوبة لدى مدير المحطة.',
                              style: const TextStyle(fontSize: 14),
                            ),
                            actions: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF5A5F),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text('حسناً', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      );
                      return;
                    }

                    final newVehicle = LineVehicle(
                      number:           1,
                      vehicleId:        _plateCtrl.text.trim(),
                      status:           'في الانتظار',
                      ownerName:        _ownerNameCtrl.text.trim(),
                      carLicExpiry:     _carLicExpCtrl.text.trim(),
                      insuranceExpiry:  _insExpCtrl.text.trim(),
                      operatingLicNum:  _opLicNumCtrl.text.trim(),
                      operatingLicDate: _opLicExpCtrl.text.trim(),
                      rfidTag:          _rfidCtrl.text.trim(),
                      loadingExpiry:    _loadingExpiryCtrl.text.trim(),
                      
                      // ✅ الحقول المضافة
                      maker:            _makerCtrl.text.trim(),
                      model:            _modelCtrl.text.trim(),
                      year:             _yearCtrl.text.trim(),
                      chassis:          _chassisCtrl.text.trim(),
                      ownerPhone:       _ownerPhoneCtrl.text.trim(),
                      ownerId:          _ownerIdCtrl.text.trim(),
                      driverName:       _selectedDriver ?? '',
                    );

                    final lineIndex = _selectedLine != null
                        ? globalLines.indexWhere((l) => l.name == _selectedLine)
                        : -1;

                    if (lineIndex != -1) {
                      // أضف للخط المختار
                      final updated = LineVehicle(
                        number: globalVehicles[lineIndex].length + 1,
                        vehicleId: newVehicle.vehicleId,
                        status: newVehicle.status,
                        ownerName: newVehicle.ownerName,
                        carLicExpiry: newVehicle.carLicExpiry,
                        insuranceExpiry: newVehicle.insuranceExpiry,
                        operatingLicNum: newVehicle.operatingLicNum,
                        operatingLicDate: newVehicle.operatingLicDate,
                        rfidTag: newVehicle.rfidTag,
                        loadingExpiry: newVehicle.loadingExpiry,
                        maker: newVehicle.maker,
                        model: newVehicle.model,
                        year: newVehicle.year,
                        chassis: newVehicle.chassis,
                        ownerPhone: newVehicle.ownerPhone,
                        ownerId: newVehicle.ownerId,
                        driverName: newVehicle.driverName,
                      );
                      globalVehicles[lineIndex].add(updated);
                    } else {
                      // بدون خط — أضف لخط افتراضي "بدون خط"
                      final noLineIdx = globalLines.indexWhere((l) => l.name == 'بدون خط');
                      if (noLineIdx == -1) {
                        globalLines.add(LineModel(name: 'بدون خط', subtitle: ''));
                        globalVehicles.add([newVehicle]);
                      } else {
                        globalVehicles[noLineIdx].add(LineVehicle(
                          number: globalVehicles[noLineIdx].length + 1,
                          vehicleId: newVehicle.vehicleId,
                          status: newVehicle.status,
                          ownerName: newVehicle.ownerName,
                          carLicExpiry: newVehicle.carLicExpiry,
                          insuranceExpiry: newVehicle.insuranceExpiry,
                          operatingLicNum: newVehicle.operatingLicNum,
                          operatingLicDate: newVehicle.operatingLicDate,
                          rfidTag: newVehicle.rfidTag,
                          loadingExpiry: newVehicle.loadingExpiry,
                          maker: newVehicle.maker,
                          model: newVehicle.model,
                          year: newVehicle.year,
                          chassis: newVehicle.chassis,
                          ownerPhone: newVehicle.ownerPhone,
                          ownerId: newVehicle.ownerId,
                          driverName: newVehicle.driverName,
                        ));
                      }
                    }
                    autoSave();
                    logEvent(EventItem(
                      vehicleId: _plateCtrl.text.trim(),
                      location:  _selectedLine ?? 'بدون خط',
                      time:      nowTime(),
                      type:      EventType.entry,
                    ));
                    Navigator.pop(context, true);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
    ),
    child: child,
  );
}