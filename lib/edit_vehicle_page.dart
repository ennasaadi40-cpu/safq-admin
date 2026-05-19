part of station_app;

class _EditVehiclePage extends StatefulWidget {
  final LineVehicle vehicle;
  final String lineName;
  final void Function(String vehicleId, String qrCode, String vehicleType,
      String licenseExpiry, String ownerName, String driverName, String status,
      {String carLicExpiry, String insuranceExpiry, String? newLineName}) onSave;

  const _EditVehiclePage({required this.vehicle, required this.lineName, required this.onSave});

  @override
  State<_EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<_EditVehiclePage> with DarkModeRebuild<_EditVehiclePage> {
  final _formKey = GlobalKey<FormState>();

  // ── بطاقة السيارة
  late final _plateCtrl     = TextEditingController(text: widget.vehicle.vehicleId);
  late final _rfidCtrl      = TextEditingController(text: widget.vehicle.rfidTag);
  final _makerCtrl          = TextEditingController();
  final _modelCtrl          = TextEditingController();
  final _yearCtrl           = TextEditingController();
  final _chassisCtrl        = TextEditingController();

  // ── بطاقة الترخيص
  late final _opLicNumCtrl    = TextEditingController(text: widget.vehicle.operatingLicNum);
  late final _opLicExpCtrl    = TextEditingController(text: widget.vehicle.operatingLicDate);
  late final _carLicExpCtrl   = TextEditingController(text: widget.vehicle.carLicExpiry);
  late final _insExpCtrl      = TextEditingController(text: widget.vehicle.insuranceExpiry);
  late final _loadingExpiryCtrl = TextEditingController(text: widget.vehicle.loadingExpiry);

  // ── المالك والسائق والخط
  late final _ownerNameCtrl  = TextEditingController(text: widget.vehicle.ownerName);
  final _ownerPhoneCtrl      = TextEditingController();
  final _ownerIdCtrl         = TextEditingController();
  String? _selectedDriver;
  late String? _selectedLine = widget.lineName.isNotEmpty ? widget.lineName : null;

  List<UserModel> get _drivers => globalUsers.where((u) => u.role == 'سائق').toList();
  List<String>    get _lineNames => globalLines.map((l) => l.name).toList();

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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D3A5C),
          foregroundColor: Colors.white,
          title: Text(L.get('edit_vehicle'),
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

              // ══ معلومات السيارة ════════════════════
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionHeader('معلومات المركبة', const Color(0xFF00C897), Icons.directions_car_outlined),

                _fieldLabel('رقم المركبة *'),
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
                    _fieldLabel(L.get('manufacturer')),
                    TextFormField(
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      controller: _makerCtrl,
                      decoration: _dec('مثال: Toyota', icon: Icons.factory_outlined),
                    ),
                  ])),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel(L.get('model')),
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
                    _fieldLabel(L.get('year')),
                    TextFormField(
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      controller: _yearCtrl,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      decoration: _dec('مثال: 2020', icon: Icons.calendar_month_outlined),
                    ),
                  ])),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel(L.get('chassis')),
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

              // ══ ترخيص التشغيل ══════════════════════
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionHeader('رخصة التشغيل', const Color(0xFFFFB347), Icons.verified_outlined),

                _fieldLabel(L.get('op_lic_num')),
                TextFormField(
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  controller: _opLicNumCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: _dec('مثال: OP-2024-556', icon: Icons.numbers),
                ),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel(L.get('op_lic_exp')),
                    TextFormField(
                      controller: _opLicExpCtrl, readOnly: true,
                      decoration: _dec('YYYY-MM-DD', icon: Icons.event_busy_outlined).copyWith(
                        suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2D3A5C)),
                      ),
                      onTap: () => _pickDate(_opLicExpCtrl),
                      validator: (v) => validateDate(v, required: false),
                    ),
                  ])),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel(L.get('lic_exp')),
                    TextFormField(
                      controller: _carLicExpCtrl, readOnly: true,
                      decoration: _dec('YYYY-MM-DD', icon: Icons.event_busy_outlined).copyWith(
                        suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2D3A5C)),
                      ),
                      onTap: () => _pickDate(_carLicExpCtrl),
                      validator: (v) => validateDate(v, required: false),
                    ),
                  ])),
                ]),
                const SizedBox(height: 12),

                _fieldLabel(L.get('insurance_exp')),
                TextFormField(
                  controller: _insExpCtrl, readOnly: true,
                  decoration: _dec('YYYY-MM-DD', icon: Icons.shield_outlined).copyWith(
                    suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2D3A5C)),
                  ),
                  onTap: () => _pickDate(_insExpCtrl),
                  validator: (v) => validateDate(v, required: false),
                ),
                const SizedBox(height: 12),

                _fieldLabel(L.get('loading_exp')),
                TextFormField(
                  controller: _loadingExpiryCtrl, readOnly: true,
                  decoration: _dec('YYYY-MM-DD', icon: Icons.local_shipping_outlined).copyWith(
                    suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2D3A5C)),
                  ),
                  onTap: () => _pickDate(_loadingExpiryCtrl),
                  validator: (v) => validateDate(v, required: false),
                ),
              ])),
              const SizedBox(height: 12),

              // ══ المالك والسائق والخط ═══════════════
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionHeader('معلومات المالك', const Color(0xFFB47AFF), Icons.badge_outlined),

                _fieldLabel('اسم المالك *'),
                TextFormField(
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  controller: _ownerNameCtrl,
                  decoration: _dec('أدخل اسم المالك', icon: Icons.person_outline),
                  validator: (v) => v == null || v.trim().isEmpty ? 'اسم المالك مطلوب' : null,
                ),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel(L.get('phone')),
                    TextFormField(
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      controller: _ownerPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: _dec('05xxxxxxxx', icon: Icons.phone_outlined),
                    ),
                  ])),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _fieldLabel(L.get('id_number')),
                    TextFormField(
                      onEditingComplete: () => FocusScope.of(context).nextFocus(),
                      controller: _ownerIdCtrl,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      decoration: _dec('xxxxxxxxx', icon: Icons.badge_outlined),
                    ),
                  ])),
                ]),
                const SizedBox(height: 12),

                _sectionHeader('السائق والخط', const Color(0xFF4B9EFF), Icons.people_outlined),

                _fieldLabel('السائق *'),
                _SearchableDropdown(
                  hint: 'ابحث عن سائق',
                  items: _drivers.map((u) => u.name).toList(),
                  selected: _selectedDriver,
                  onSelected: (v) => setState(() => _selectedDriver = v),
                  validator: (v) => (v == null || v.isEmpty) ? 'اختر السائق' : null,
                ),
                const SizedBox(height: 12),

                _fieldLabel('الخط *'),
                _SearchableDropdown(
                  hint: 'اختر الخط',
                  items: _lineNames,
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
                  label: Text('حفظ التعديلات',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    // تحديث المركبة في globalVehicles
                    final vid = widget.vehicle.vehicleId;
                    for (int i = 0; i < globalLines.length; i++) {
                      for (int j = 0; j < globalVehicles[i].length; j++) {
                        if (globalVehicles[i][j].vehicleId == vid) {
                          final old = globalVehicles[i][j];
                          globalVehicles[i][j] = LineVehicle(
                            number:           old.number,
                            vehicleId:        _plateCtrl.text.trim(),
                            status:           old.status,
                            note:             old.note,
                            ownerName:        _ownerNameCtrl.text.trim(),
                            carLicExpiry:     _carLicExpCtrl.text.trim(),
                            insuranceExpiry:  _insExpCtrl.text.trim(),
                            operatingLicNum:  _opLicNumCtrl.text.trim(),
                            operatingLicDate: _opLicExpCtrl.text.trim(),
                            rfidTag:          _rfidCtrl.text.trim(),
                            loadingExpiry:    _loadingExpiryCtrl.text.trim(),
                          );
                        }
                      }
                    }
                    // تحويل الخط لو تغير
                    if (_selectedLine != null && _selectedLine != widget.lineName) {
                      widget.onSave(
                        _plateCtrl.text.trim(), _rfidCtrl.text.trim(), '', '',
                        _ownerNameCtrl.text.trim(), _selectedDriver ?? '', 'في الانتظار',
                        carLicExpiry: _carLicExpCtrl.text.trim(),
                        insuranceExpiry: _insExpCtrl.text.trim(),
                        newLineName: _selectedLine,
                      );
                    } else {
                      widget.onSave(
                        _plateCtrl.text.trim(), _rfidCtrl.text.trim(), '', '',
                        _ownerNameCtrl.text.trim(), _selectedDriver ?? '', 'في الانتظار',
                        carLicExpiry: _carLicExpCtrl.text.trim(),
                        insuranceExpiry: _insExpCtrl.text.trim(),
                      );
                    }
                    autoSave();
                    Navigator.pop(context);
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
}