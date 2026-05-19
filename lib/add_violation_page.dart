part of station_app;

class _AddViolationPage extends StatefulWidget {
  final String vehicleId;
  const _AddViolationPage({required this.vehicleId});
  @override
  State<_AddViolationPage> createState() => _AddViolationPageState();
}

// قائمة أنواع المخالفات

class _AddViolationPageState extends State<_AddViolationPage> with DarkModeRebuild<_AddViolationPage> {
  final _formKey        = GlobalKey<FormState>();
  final _numCtrl        = TextEditingController();
  final _msgCtrl        = TextEditingController();
  final _amountCtrl     = TextEditingController();
  final _customTypeCtrl = TextEditingController();
  String? _selectedType;
  bool _banVehicle = false; // حظر المركبة عند الحفظ

  @override
  void initState() {
    super.initState();
    // رقم مخالفة مقترح — قابل للتعديل
    final n = globalEvents.where((e) => e.type == EventType.violation).length + 1;
    _numCtrl.text = ''; // رقم يدوي — يكتبه المستخدم
  }

  InputDecoration _inputDec(String hint, {int maxLines = 1}) => InputDecoration(
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

  // ── dialog ما بعد تسجيل المخالفة ──────────────────────────────────
  void _showViolationFollowUp(
      BuildContext ctx, String vehicleId, String violationNum, String amount, String typeName) {
    bool feesPaid       = false;
    bool extendEntry    = false;
    DateTime? entryDate;
    final amountDouble  = double.tryParse(amount) ?? 0;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (dlgCtx, setDlg) => Directionality(
          textDirection: TextDirection.rtl,
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
                          Text('تم تسجيل المخالفة', style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(violationNum, style: const TextStyle(
                              color: Colors.white60, fontSize: 12)),
                        ])),
                      ]),
                      const SizedBox(height: 10),
                      // بطاقة التفاصيل
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('المركبة', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                            Text(vehicleId, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ])),
                          Container(width: 1, height: 30, color: Colors.white24),
                          Expanded(child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('المبلغ', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                              Text('\$amount ₪', style: const TextStyle(
                                  color: Color(0xFFFFB347), fontSize: 13, fontWeight: FontWeight.bold)),
                            ]),
                          )),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // ── قسم دفع الرسوم ─────────────────────
                  Text('الرسوم والغرامة', style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14,
                      color: dlgCtx.textPrimary)),
                  const SizedBox(height: 10),
                  _Tap(
                    onTap: () => setDlg(() => feesPaid = !feesPaid),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: feesPaid
                            ? const Color(0xFFE8F5E9)
                            : dlgCtx.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: feesPaid
                              ? const Color(0xFF2E7D32)
                              : dlgCtx.dividerColor,
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
                          child: feesPaid
                              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('تم دفع رسوم المخالفة',
                              style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: feesPaid ? const Color(0xFF2E7D32) : dlgCtx.textPrimary,
                              )),
                          Text(
                            feesPaid
                                ? 'تم استلام \$amount ₪ ✓'
                                : 'المبلغ المستحق: \$amount ₪',
                            style: TextStyle(
                              fontSize: 12,
                              color: feesPaid ? const Color(0xFF2E7D32) : Colors.orange[700],
                            )),
                        ])),
                        if (!feesPaid)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('معلق', style: TextStyle(
                                fontSize: 11, color: Colors.orange[700], fontWeight: FontWeight.bold)),
                          ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── قسم تمديد تاريخ الدخول ────────────
                  Text('السماح بالدخول', style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14,
                      color: dlgCtx.textPrimary)),
                  const SizedBox(height: 10),
                  _Tap(
                    onTap: () => setDlg(() => extendEntry = !extendEntry),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: extendEntry
                            ? const Color(0xFFE3F2FD)
                            : dlgCtx.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: extendEntry
                              ? const Color(0xFF1565C0)
                              : dlgCtx.dividerColor,
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
                          child: extendEntry
                              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('تمديد تاريخ السماح بالدخول',
                              style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: extendEntry ? const Color(0xFF1565C0) : dlgCtx.textPrimary,
                              )),
                          Text('تحديد تاريخ يُسمح فيه للمركبة بالدخول',
                              style: TextStyle(fontSize: 12, color: dlgCtx.textSecondary)),
                        ])),
                        const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF1565C0)),
                      ]),
                    ),
                  ),

                  // date picker يظهر عند تفعيل التمديد
                  if (extendEntry) ...[
                    const SizedBox(height: 10),
                    _Tap(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dlgCtx,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2035),
                          helpText: 'اختر تاريخ السماح بالدخول',
                          confirmText: 'تأكيد',
                          cancelText: 'إلغاء',
                        );
                        if (picked != null) setDlg(() => entryDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: dlgCtx.bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: entryDate != null
                                ? const Color(0xFF1565C0)
                                : dlgCtx.dividerColor,
                          ),
                        ),
                        child: Row(children: [
                          Icon(Icons.calendar_today_outlined, size: 18,
                              color: entryDate != null ? const Color(0xFF1565C0) : Colors.grey),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            entryDate != null
                                ? '\${entryDate!.year}-\${entryDate!.month.toString().padLeft(2,"0")}-\${entryDate!.day.toString().padLeft(2,"0")}'
                                : 'اضغط لاختيار التاريخ...',
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
                                '\${entryDate!.difference(DateTime.now()).inDays} يوم',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
                              ),
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
                        child: Text('لاحقاً', style: TextStyle(color: dlgCtx.textSecondary)),
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
                        label: const Text('حفظ وإغلاق', style: TextStyle(color: Colors.white, fontSize: 14)),
                        onPressed: () {
                          // تحديث آخر حدث مخالفة بالرسوم والتاريخ
                          final idx = globalEvents.lastIndexWhere(
                              (e) => e.type == EventType.violation && e.vehicleId == vehicleId);
                          if (idx != -1) {
                            final dateStr = entryDate != null
                                ? '\${entryDate!.year}-\${entryDate!.month.toString().padLeft(2,"0")}-\${entryDate!.day.toString().padLeft(2,"0")}'
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
                                    ? 'تم حفظ المخالفة • رسوم مدفوعة • دخول مُمدَّد'
                                    : feesPaid
                                        ? 'تم حفظ المخالفة • رسوم مدفوعة'
                                        : extendEntry && entryDate != null
                                            ? 'تم حفظ المخالفة • دخول مُمدَّد'
                                            : 'تم حفظ المخالفة',
                                textDirection: TextDirection.rtl,
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D3A5C),
          elevation: 0,
          title: const Text('إضافة شكوى جديدة',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                // رقم المخالفة — يدوي
                _label('رقم الشكوى'),
                TextFormField(
                  controller: _numCtrl,
                  textDirection: TextDirection.ltr,
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  decoration: _inputDec('مثال: V-0001').copyWith(
                    prefixIcon: const Icon(Icons.tag, size: 18, color: Color(0xFF2D3A5C)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'رقم الشكوى مطلوب' : null,
                ),
                const SizedBox(height: 16),

                // نوع المخالفة — قائمة منسدلة
                _label('نوع الشكوى'),
                _SearchableDropdown(
                  hint: 'اختر نوع الشكوى',
                  items: kViolationTypes.map((t) => (t['name']! == 'مخالفة أخرى' ? 'شكوى أخرى' : t['name']!)).toList(),
                  selected: _selectedType,
                  onSelected: (v) {
                    setState(() => _selectedType = v);
                    final found = kViolationTypes.firstWhere((t) => t['name'] == v, orElse: () => {});
                    if (found.isNotEmpty) _amountCtrl.text = found['amount']!;
                  },
                  validator: (v) => (v == null || v.isEmpty) ? 'يجب اختيار نوع الشكوى' : null,
                ),
                const SizedBox(height: 16),

                // وصف المخالفة — يظهر فقط عند "مخالفة أخرى"
                if (_selectedType == 'شكوى أخرى') ...[
                  _label('وصف الشكوى'),
                  TextFormField(
         onEditingComplete: () => FocusScope.of(context).nextFocus(),
                    controller: _customTypeCtrl,
                    decoration: _inputDec('اكتب وصف الشكوى...'),
                    validator: (v) {
                      if (_selectedType == 'شكوى أخرى' && (v == null || v.trim().isEmpty))
                        return 'يجب كتابة وصف الشكوى';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),

                // ملاحظات
                _label('ملاحظات'),
                TextFormField(
         onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  controller: _msgCtrl,
                  decoration: _inputDec('أي ملاحظات إضافية...')
                  ,validator: (v) => v == null || v.trim().isEmpty ? 'الملاحظات مطلوبة' : null,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // ── زر المنع ────────────────────────────
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
                        color: _banVehicle
                            ? const Color(0xFFFF5A5F)
                            : context.dividerColor,
                        width: _banVehicle ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: _banVehicle
                              ? const Color(0xFFFF5A5F)
                              : Colors.transparent,
                          border: Border.all(
                            color: _banVehicle
                                ? const Color(0xFFFF5A5F)
                                : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _banVehicle
                            ? const Icon(Icons.check_rounded,
                                size: 15, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.block_rounded,
                        size: 20,
                        color: _banVehicle
                            ? const Color(0xFFFF5A5F)
                            : context.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('حظر المركبة',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _banVehicle
                                    ? const Color(0xFFFF5A5F)
                                    : context.textPrimary,
                              )),
                          Text(
                            _banVehicle
                                ? 'سيتم حظر المركبة عند الحفظ'
                                : 'اضغط لحظر المركبة مع تسجيل المخالفة',
                            style: TextStyle(
                                fontSize: 11,
                                color: _banVehicle
                                    ? const Color(0xFFFF5A5F).withValues(alpha: 0.8)
                                    : context.textSecondary),
                          ),
                        ],
                      )),
                    ]),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3A5C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      final typeName = _selectedType == 'شكوى أخرى' && _customTypeCtrl.text.trim().isNotEmpty
                          ? _customTypeCtrl.text.trim()
                          : _selectedType!;

                      // تسجيل المخالفة
                      logEvent(EventItem(
                        vehicleId: widget.vehicleId.isEmpty ? 'غير محدد' : widget.vehicleId,
                        location: typeName,
                        time: nowTime(),
                        type: EventType.violation,
                        violationNote: '${_numCtrl.text.trim()} | $typeName | ${_amountCtrl.text.trim()} ₪${_msgCtrl.text.trim().isNotEmpty ? " | ${_msgCtrl.text.trim()}" : ""}',
                      ));

                      // تطبيق الحظر إذا مفعّل
                      if (_banVehicle && widget.vehicleId.isNotEmpty) {
                        String supervisorName = '';
                        for (int i = 0; i < globalLines.length; i++) {
                          for (int j = 0; j < globalVehicles[i].length; j++) {
                            if (globalVehicles[i][j].vehicleId == widget.vehicleId) {
                              final old = globalVehicles[i][j];
                              globalVehicles[i][j] = LineVehicle(
                                number: old.number,
                                vehicleId: old.vehicleId,
                                status: 'محظورة',
                                note: old.note,
                                ownerName: old.ownerName,
                                carLicExpiry: old.carLicExpiry,
                                insuranceExpiry: old.insuranceExpiry,
                                operatingLicNum: old.operatingLicNum,
                                operatingLicDate: old.operatingLicDate,
                                rfidTag: old.rfidTag,
                              );
                              // ابحث عن مشرف الخط
                              if (i < globalLines.length) {
                                supervisorName = globalLines[i].supervisor;
                              }
                            }
                          }
                        }
                        autoSave();

                        final now = nowTime();
                        final vid = widget.vehicleId;
                        final vtype = typeName;

                        // ── تنبيه لموظف الأمن ──────────────────
                        globalSecurityNotifications.insert(0, {
                          'title': '🚫 تم حظر مركبة',
                          'body': 'المركبة $vid محظورة بسبب: $vtype — مطلوبة لدى مدير المحطة',
                          'time': now,
                          'type': 'banned',
                          'role': 'security',
                        });

                        // ── تنبيه لمشرف الخط ───────────────────
                        if (supervisorName.isNotEmpty) {
                          globalSecurityNotifications.insert(0, {
                            'title': '⚠️ مركبة محظورة في خطك',
                            'body': 'المركبة $vid في خطك محظورة — يرجى التواصل مع الإدارة',
                            'time': now,
                            'type': 'supervisor_alert',
                            'role': 'supervisor',
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
                                ? 'تم حفظ الشكوى وحظر المركبة'
                                : 'تم حفظ الشكوى',
                            textDirection: TextDirection.rtl,
                          ),
                        ]),
                        backgroundColor: _banVehicle
                            ? const Color(0xFFC62828)
                            : const Color(0xFF2E7D32),
                        duration: const Duration(seconds: 3),
                      ));
                      Navigator.pop(context);
                    },
                    child: const Text('حفظ الشكوى',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

// ─────────────────────────────────────────────
//  Add Vehicle Page