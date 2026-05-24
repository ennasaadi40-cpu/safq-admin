part of station_app;

class _AddViolationPage extends StatefulWidget {
  final String vehicleId;
  const _AddViolationPage({required this.vehicleId});
  @override
  State<_AddViolationPage> createState() => _AddViolationPageState();
}

class _AddViolationPageState extends State<_AddViolationPage> with DarkModeRebuild<_AddViolationPage> {
  final _formKey        = GlobalKey<FormState>();
  final _numCtrl        = TextEditingController();
  final _msgCtrl        = TextEditingController();
  final _amountCtrl     = TextEditingController();
  final _customTypeCtrl = TextEditingController();
  String? _selectedType;
  bool _banVehicle = false;

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

  // نوع الشكوى الأخرى
  String get _otherType => L.get('other_complaint');

  List<String> get _violationItems => kViolationTypes
      .map((t) => t['name']! == 'مخالفة أخرى' ? _otherType : t['name']!)
      .toList();

  void _showViolationFollowUp(
      BuildContext ctx, String vehicleId, String violationNum, String amount, String typeName) {
    bool feesPaid    = false;
    bool extendEntry = false;
    DateTime? entryDate;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (dlgCtx, setDlg) => Directionality(
          textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ── رأس الـ dialog ─────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E2B45), Color(0xFF2D3A5C)],
                        begin: Alignment.topRight, end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(L.get('complaint_recorded'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(violationNum, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        ])),
                      ]),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(L.get('vehicle'), style: const TextStyle(color: Colors.white60, fontSize: 11)),
                            Text(vehicleId, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ])),
                          Container(width: 1, height: 30, color: Colors.white24),
                          Expanded(child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(L.get('amount'), style: const TextStyle(color: Colors.white60, fontSize: 11)),
                              Text('$amount ₪', style: const TextStyle(
                                  color: Color(0xFFFFB347), fontSize: 13, fontWeight: FontWeight.bold)),
                            ]),
                          )),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // ── دفع الرسوم ─────────────────────────
                  Text(L.get('fees_and_fine'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: dlgCtx.textPrimary)),
                  const SizedBox(height: 10),
                  _Tap(
                    onTap: () => setDlg(() => feesPaid = !feesPaid),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: feesPaid ? const Color(0xFFE8F5E9) : dlgCtx.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: feesPaid ? const Color(0xFF2E7D32) : dlgCtx.dividerColor,
                          width: feesPaid ? 2 : 1,
                        ),
                      ),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: feesPaid ? const Color(0xFF2E7D32) : Colors.transparent,
                            border: Border.all(
                              color: feesPaid ? const Color(0xFF2E7D32) : Colors.grey,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: feesPaid ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(L.get('fees_paid'),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                  color: feesPaid ? const Color(0xFF2E7D32) : dlgCtx.textPrimary)),
                          Text(
                            feesPaid
                                ? '${L.get('received')} $amount ₪ ✓'
                                : '${L.get('amount_due')} $amount ₪',
                            style: TextStyle(fontSize: 12,
                                color: feesPaid ? const Color(0xFF2E7D32) : Colors.orange[700])),
                        ])),
                        if (!feesPaid)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(L.get('pending'),
                                style: TextStyle(fontSize: 11, color: Colors.orange[700], fontWeight: FontWeight.bold)),
                          ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── السماح بالدخول ─────────────────────
                  Text(L.get('allow_entry'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: dlgCtx.textPrimary)),
                  const SizedBox(height: 10),
                  _Tap(
                    onTap: () => setDlg(() => extendEntry = !extendEntry),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: extendEntry ? const Color(0xFFE3F2FD) : dlgCtx.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: extendEntry ? const Color(0xFF1565C0) : dlgCtx.dividerColor,
                          width: extendEntry ? 2 : 1,
                        ),
                      ),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: extendEntry ? const Color(0xFF1565C0) : Colors.transparent,
                            border: Border.all(
                              color: extendEntry ? const Color(0xFF1565C0) : Colors.grey,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: extendEntry ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(L.get('extend_entry_date'),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                  color: extendEntry ? const Color(0xFF1565C0) : dlgCtx.textPrimary)),
                          Text(L.get('set_entry_date'),
                              style: TextStyle(fontSize: 12, color: dlgCtx.textSecondary)),
                        ])),
                        const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF1565C0)),
                      ]),
                    ),
                  ),

                  if (extendEntry) ...[
                    const SizedBox(height: 10),
                    _Tap(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dlgCtx,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2035),
                          helpText: L.get('select_entry_date'),
                          confirmText: L.get('confirm'),
                          cancelText: L.get('cancel'),
                        );
                        if (picked != null) setDlg(() => entryDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: dlgCtx.bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: entryDate != null ? const Color(0xFF1565C0) : dlgCtx.dividerColor,
                          ),
                        ),
                        child: Row(children: [
                          Icon(Icons.calendar_today_outlined, size: 18,
                              color: entryDate != null ? const Color(0xFF1565C0) : Colors.grey),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            entryDate != null
                                ? '${entryDate!.year}-${entryDate!.month.toString().padLeft(2,"0")}-${entryDate!.day.toString().padLeft(2,"0")}'
                                : L.get('tap_to_select_date'),
                            style: TextStyle(
                              fontSize: 14,
                              color: entryDate != null ? const Color(0xFF1565C0) : Colors.grey,
                              fontWeight: entryDate != null ? FontWeight.bold : FontWeight.normal,
                            ),
                          )),
                          if (entryDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${entryDate!.difference(DateTime.now()).inDays} ${L.get('days')}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
                            ),
                        ]),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── أزرار ─────────────────────────────
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: dlgCtx.dividerColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.pop(dlgCtx),
                        child: Text(L.get('later'),
                            style: TextStyle(color: dlgCtx.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D3A5C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                        label: Text(L.get('save_and_close'),
                            style: const TextStyle(color: Colors.white, fontSize: 14)),
                        onPressed: () {
                          final idx = globalEvents.lastIndexWhere(
                              (e) => e.type == EventType.violation && e.vehicleId == vehicleId);
                          if (idx != -1) {
                            final dateStr = entryDate != null
                                ? '${entryDate!.year}-${entryDate!.month.toString().padLeft(2,"0")}-${entryDate!.day.toString().padLeft(2,"0")}'
                                : null;
                            globalEvents[idx] = globalEvents[idx].copyWith(
                              feesPaid: feesPaid,
                              allowedEntryDate: dateStr,
                            );
                          }
                          Navigator.pop(dlgCtx);
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Row(children: [
                              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(child: Text(
                                feesPaid && entryDate != null
                                    ? L.get('fees_paid_entry_extended')
                                    : feesPaid
                                        ? L.get('saved_fees_paid')
                                        : extendEntry && entryDate != null
                                            ? L.get('saved_entry_extended')
                                            : L.get('complaint_saved'),
                                textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                                style: const TextStyle(fontSize: 13),
                              )),
                            ]),
                            backgroundColor: const Color(0xFF2D3A5C),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 4),
                          ));
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
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
          title: Text(L.get('add_violation'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── رقم الشكوى ──────────────────────────
                _label(L.get('complaint_number')),
                TextFormField(
                  controller: _numCtrl,
                  textDirection: TextDirection.ltr,
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  decoration: _inputDec('V-0001').copyWith(
                    prefixIcon: const Icon(Icons.tag, size: 18, color: Color(0xFF2D3A5C)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? L.get('complaint_num_required')
                      : null,
                ),
                const SizedBox(height: 16),

                // ── نوع الشكوى ──────────────────────────
                _label(L.get('violation_type')),
                _SearchableDropdown(
                  hint: L.get('select_complaint_type'),
                  items: _violationItems,
                  selected: _selectedType,
                  onSelected: (v) {
                    setState(() => _selectedType = v);
                    final found = kViolationTypes.firstWhere(
                        (t) => t['name'] == v || (v == _otherType && t['name'] == 'مخالفة أخرى'),
                        orElse: () => {});
                    if (found.isNotEmpty) _amountCtrl.text = found['amount']!;
                  },
                  validator: (v) => (v == null || v.isEmpty)
                      ? L.get('complaint_required')
                      : null,
                ),
                const SizedBox(height: 16),

                // ── وصف (عند شكوى أخرى) ─────────────────
                if (_selectedType == _otherType) ...[
                  _label(L.get('complaint_description')),
                  TextFormField(
                    onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    controller: _customTypeCtrl,
                    decoration: _inputDec(L.get('write_description')),
                    validator: (v) {
                      if (_selectedType == _otherType && (v == null || v.trim().isEmpty))
                        return L.get('description_required');
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // ── ملاحظات ─────────────────────────────
                _label(L.get('notes')),
                TextFormField(
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  controller: _msgCtrl,
                  decoration: _inputDec(L.get('additional_notes')),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? L.get('notes_required')
                      : null,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // ── زر الحظر ────────────────────────────
                _Tap(
                  onTap: () => setState(() => _banVehicle = !_banVehicle),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _banVehicle
                          ? const Color(0xFFFF5A5F).withValues(alpha: 0.1)
                          : context.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _banVehicle ? const Color(0xFFFF5A5F) : context.dividerColor,
                        width: _banVehicle ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: _banVehicle ? const Color(0xFFFF5A5F) : Colors.transparent,
                          border: Border.all(
                            color: _banVehicle ? const Color(0xFFFF5A5F) : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _banVehicle
                            ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.block_rounded, size: 20,
                          color: _banVehicle ? const Color(0xFFFF5A5F) : context.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(L.get('ban_vehicle'),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                color: _banVehicle ? const Color(0xFFFF5A5F) : context.textPrimary)),
                        Text(
                          _banVehicle
                              ? L.get('vehicle_will_be_banned')
                              : L.get('tap_to_ban'),
                          style: TextStyle(fontSize: 11,
                              color: _banVehicle
                                  ? const Color(0xFFFF5A5F).withValues(alpha: 0.8)
                                  : context.textSecondary),
                        ),
                      ])),
                    ]),
                  ),
                ),

                const SizedBox(height: 20),

                // ── زر الحفظ ────────────────────────────
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3A5C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      final typeName = _selectedType == _otherType && _customTypeCtrl.text.trim().isNotEmpty
                          ? _customTypeCtrl.text.trim()
                          : _selectedType!;

                      logEvent(EventItem(
                        vehicleId: widget.vehicleId.isEmpty
                            ? L.get('unknown')
                            : widget.vehicleId,
                        location: typeName,
                        time:     nowTime(),
                        type:     EventType.violation,
                        violationNote: '${_numCtrl.text.trim()} | $typeName | ${_amountCtrl.text.trim()} ₪'
                            '${_msgCtrl.text.trim().isNotEmpty ? " | ${_msgCtrl.text.trim()}" : ""}',
                      ));

                      if (_banVehicle && widget.vehicleId.isNotEmpty) {
                        String supervisorName = '';
                        for (int i = 0; i < globalLines.length; i++) {
                          for (int j = 0; j < globalVehicles[i].length; j++) {
                            if (globalVehicles[i][j].vehicleId == widget.vehicleId) {
                              final old = globalVehicles[i][j];
                              globalVehicles[i][j] = LineVehicle(
                                number:           old.number,
                                vehicleId:        old.vehicleId,
                                status:           'محظورة',
                                note:             old.note,
                                ownerName:        old.ownerName,
                                carLicExpiry:     old.carLicExpiry,
                                insuranceExpiry:  old.insuranceExpiry,
                                operatingLicNum:  old.operatingLicNum,
                                operatingLicDate: old.operatingLicDate,
                                rfidTag:          old.rfidTag,
                              );
                              if (i < globalLines.length) supervisorName = globalLines[i].supervisor;
                            }
                          }
                        }
                        autoSave();

                        final now = nowTime();
                        final vid = widget.vehicleId;

                        globalSecurityNotifications.insert(0, {
                          'title': L.isArabic ? '🚫 تم حظر مركبة' : '🚫 Vehicle Banned',
                          'body':  L.isArabic
                              ? 'المركبة $vid محظورة بسبب: $typeName — مطلوبة لدى مدير المحطة'
                              : 'Vehicle $vid banned due to: $typeName — required by station manager',
                          'time':  now,
                          'type':  'banned',
                          'role':  'security',
                        });

                        if (supervisorName.isNotEmpty) {
                          globalSecurityNotifications.insert(0, {
                            'title': L.isArabic ? '⚠️ مركبة محظورة في خطك' : '⚠️ Banned vehicle in your line',
                            'body':  L.isArabic
                                ? 'المركبة $vid في خطك محظورة — يرجى التواصل مع الإدارة'
                                : 'Vehicle $vid in your line is banned — contact management',
                            'time':      now,
                            'type':      'supervisor_alert',
                            'role':      'supervisor',
                            'supervisor': supervisorName,
                          });
                        }
                      }

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Row(children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _banVehicle
                                ? L.get('complaint_and_banned')
                                : L.get('complaint_saved'),
                            textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                          ),
                        ]),
                        backgroundColor: _banVehicle ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                        duration: const Duration(seconds: 3),
                      ));
                      
                      _showViolationFollowUp(context, widget.vehicleId, _numCtrl.text.trim(), _amountCtrl.text.trim(), typeName);
                      Navigator.pop(context);
                    },
                    child: Text(L.get('save_complaint'),
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