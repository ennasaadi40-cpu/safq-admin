part of station_app;

class _GateScannerPage extends StatefulWidget {
  const _GateScannerPage();
  @override
  State<_GateScannerPage> createState() => _GateScannerPageState();
}

enum _ScanResult { none, ok, wrongGate, unknown, banned }

class _GateScannerPageState extends State<_GateScannerPage>
    with DarkModeRebuild<_GateScannerPage> {

  final _qrCtrl     = TextEditingController();
  GateModel? _selectedGate;
  _ScanResult _result = _ScanResult.none;
  String _resultTitle = '';
  String _resultSub   = '';
  LineVehicle? _foundVehicle;
  LineModel?   _foundLine;

  @override
  void initState() {
    super.initState();
    if (globalGates.isNotEmpty) _selectedGate = globalGates.first;
  }

  String get _gateLabel => _selectedGate?.label ?? 'غير محددة';
  bool   get _isEntry   => _selectedGate?.type == 'مدخل';

  void _scan(String code) {
    final q = code.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _result = _ScanResult.none; });

    LineVehicle? vehicle;
    LineModel?   line;
    for (int i = 0; i < globalLines.length; i++) {
      for (final v in globalVehicles[i]) {
        if (v.vehicleId.toLowerCase() == q.toLowerCase()) {
          vehicle = v; line = globalLines[i]; break;
        }
      }
      if (vehicle != null) break;
    }

    if (vehicle == null) {
      _result = _ScanResult.unknown;
      _resultTitle = 'مركبة غير مسجلة!';
      _resultSub   = 'لا توجد مركبة بالرقم "$q" في النظام';
      _foundVehicle = null; _foundLine = null;
      _autoVio(q, 'دخول مركبة غير مسجلة — رقم: $q');
      setState(() {}); return;
    }

    _foundVehicle = vehicle; _foundLine = line;

    if (vehicle.status == 'محظورة' || vehicle.status == 'موقوفة') {
      _result = _ScanResult.banned;
      _resultTitle = 'مركبة موقوفة!';
      _resultSub   = '\${vehicle.vehicleId} — \${line!.name}\nالحالة: \${vehicle.status}';
      _autoVio(vehicle.vehicleId, 'محاولة دخول بمركبة موقوفة');
      setState(() {}); return;
    }

    if (_selectedGate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('اختر بوابة أولاً', textDirection: TextDirection.rtl),
        backgroundColor: Color(0xFFFF5A5F),
      ));
      setState(() {}); return;
    }

    // ── فحص تاريخ انتهاء التحميل (عند الدخول فقط) ──
    if (_isEntry) {
      final expiry = vehicle.loadingExpiry;
      bool loadingExpired = expiry.isEmpty;
      if (!loadingExpired) {
        try {
          final p = expiry.split('-');
          final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
          if (d.isBefore(DateTime.now())) loadingExpired = true;
        } catch (_) { loadingExpired = true; }
      }
      if (loadingExpired) {
        _result = _ScanResult.banned;
        _resultTitle = 'انتهت صلاحية التحميل!';
        _resultSub   = '\${vehicle.vehicleId} — \${line.name}\n'
            '\${expiry.isEmpty ? "تاريخ التحميل غير محدد" : "انتهى في: \$expiry"}';
        globalSecurityNotifications.insert(0, {
          'title': '🚫 انتهاء صلاحية التحميل',
          'body': 'المركبة \${vehicle.vehicleId} حاولت الدخول وتاريخ تحميلها منتهي\${expiry.isNotEmpty ? ": \$expiry" : ""}',
          'time': nowTime(),
          'type': 'loading_expired',
          'role': 'security',
        });
        _autoVio(vehicle.vehicleId, 'محاولة دخول بتاريخ تحميل منتهي');
        setState(() {}); return;
      }
    }

    _result = _ScanResult.ok;
    _resultTitle = _isEntry ? 'دخول مسموح ✓' : 'خروج مسموح ✓';
    _resultSub   = '\${vehicle.vehicleId} — \${line.name}\n\$_gateLabel';
    logEvent(EventItem(
      vehicleId: vehicle.vehicleId,
      location: '\${line.name} — \$_gateLabel',
      time: nowTime(),
      type: _isEntry ? EventType.entry : EventType.exit,
    ));
    setState(() {});
    _qrCtrl.clear();
  }

  void _autoVio(String vid, String note) {
    logEvent(EventItem(
      vehicleId: vid, location: _gateLabel,
      time: nowTime(), type: EventType.violation, violationNote: note,
    ));
  }

  Color get _rc {
    switch (_result) {
      case _ScanResult.ok:        return const Color(0xFF00C897);
      case _ScanResult.wrongGate: return const Color(0xFFFFB347);
      default:                    return const Color(0xFFFF5A5F);
    }
  }
  IconData get _ri {
    switch (_result) {
      case _ScanResult.ok:        return Icons.check_circle_rounded;
      case _ScanResult.wrongGate: return Icons.wrong_location_rounded;
      case _ScanResult.unknown:   return Icons.help_outline_rounded;
      case _ScanResult.banned:    return Icons.block_rounded;
      default:                    return Icons.qr_code_scanner_rounded;
    }
  }

  // ── تبديل حالة الحظر ─────────────────────────
  void _toggleBan() {
    if (_foundVehicle == null) return;
    final vid = _foundVehicle!.vehicleId;
    final isBanned = _foundVehicle!.status == 'محظورة';
    final newStatus = isBanned ? 'في الانتظار' : 'محظورة';

    // تحديث في globalVehicles
    for (int i = 0; i < globalLines.length; i++) {
      for (int j = 0; j < globalVehicles[i].length; j++) {
        if (globalVehicles[i][j].vehicleId == vid) {
          final old = globalVehicles[i][j];
          globalVehicles[i][j] = LineVehicle(
            number: old.number,
            vehicleId: old.vehicleId,
            status: newStatus,
            note: old.note,
            ownerName: old.ownerName,
            carLicExpiry: old.carLicExpiry,
            insuranceExpiry: old.insuranceExpiry,
          );
          _foundVehicle = globalVehicles[i][j];
          break;
        }
      }
    }
    autoSave();
    logEvent(EventItem(
      vehicleId: vid,
      location: _gateLabel,
      time: nowTime(),
      type: EventType.violation,
      violationNote: isBanned ? 'رفع الحظر عن المركبة' : 'حظر المركبة من الدخول',
    ));
    setState(() {
      _resultTitle = isBanned ? 'تم رفع الحظر ✓' : 'تم حظر المركبة ✗';
      _resultSub   = '$vid — ${isBanned ? "مسموح لها الآن" : "ممنوعة من الدخول"}';
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isBanned ? Icons.check_circle : Icons.block_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(isBanned ? 'تم رفع الحظر عن $vid' : 'تم حظر المركبة $vid',
            textDirection: TextDirection.rtl),
      ]),
      backgroundColor: isBanned ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── إضافة بوابة جديدة ────────────────────────
  void _addGateDialog(BuildContext context) {
    final floorCtrl  = TextEditingController();
    final numberCtrl = TextEditingController();
    final ipCtrl     = TextEditingController();
    String gateType  = 'مدخل';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B9EFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sensor_door_outlined, color: Color(0xFF4B9EFF), size: 20),
              ),
              const SizedBox(width: 10),
              Text('إضافة بوابة جديدة', style: TextStyle(color: ctx.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              // رقم الطابق
              TextField(
                controller: floorCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'رقم الطابق',
                  hintText: 'مثال: 1',
                  prefixIcon: const Icon(Icons.layers_outlined, size: 18, color: Color(0xFF4B9EFF)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4B9EFF), width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              // نوع البوابة
              Row(children: [
                Expanded(child: _Tap(
                  onTap: () => setDlg(() => gateType = 'مدخل'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: gateType == 'مدخل' ? const Color(0xFF00C897).withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gateType == 'مدخل' ? const Color(0xFF00C897) : ctx.dividerColor, width: gateType == 'مدخل' ? 1.5 : 1),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.login_rounded, size: 15, color: gateType == 'مدخل' ? const Color(0xFF00C897) : Colors.grey),
                      const SizedBox(width: 5),
                      Text('مدخل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: gateType == 'مدخل' ? const Color(0xFF00C897) : Colors.grey)),
                    ]),
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(child: _Tap(
                  onTap: () => setDlg(() => gateType = 'مخرج'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: gateType == 'مخرج' ? const Color(0xFFFF5A5F).withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gateType == 'مخرج' ? const Color(0xFFFF5A5F) : ctx.dividerColor, width: gateType == 'مخرج' ? 1.5 : 1),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.logout_rounded, size: 15, color: gateType == 'مخرج' ? const Color(0xFFFF5A5F) : Colors.grey),
                      const SizedBox(width: 5),
                      Text('مخرج', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: gateType == 'مخرج' ? const Color(0xFFFF5A5F) : Colors.grey)),
                    ]),
                  ),
                )),
              ]),
              const SizedBox(height: 12),
              // رقم البوابة
              TextField(
                controller: numberCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'رقم البوابة',
                  hintText: 'مثال: 1',
                  prefixIcon: const Icon(Icons.sensor_door_outlined, size: 18, color: Color(0xFF4B9EFF)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4B9EFF), width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              // IP Address
              TextField(
                controller: ipCtrl,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: 'IP Address',
                  hintText: 'مثال: 192.168.1.10',
                  prefixIcon: const Icon(Icons.lan_outlined, size: 18, color: Color(0xFF4B9EFF)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4B9EFF), width: 1.5)),
                ),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('إلغاء', style: TextStyle(color: ctx.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B9EFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final floor  = floorCtrl.text.trim();
                  final number = numberCtrl.text.trim();
                  if (floor.isEmpty || number.isEmpty) return;
                  final newGate = GateModel(
                    id:     '\${DateTime.now().millisecondsSinceEpoch}',
                    floor:  floor,
                    type:   gateType,
                    number: number,
                  );
                  setState(() => globalGates.add(newGate));
                  autoSave();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('تمت إضافة \${newGate.label}', textDirection: TextDirection.rtl),
                    backgroundColor: const Color(0xFF4B9EFF),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ));
                },
                child: const Text('إضافة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
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
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: const Text('فحص البوابة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
              tooltip: 'إضافة بوابة',
              onPressed: () => _addGateDialog(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── اختيار البوابة ───────────────────────
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _secHeader('اختيار البوابة', Icons.sensor_door_outlined, const Color(0xFF4B9EFF)),
              const SizedBox(height: 14),

              // قائمة البوابات الديناميكية
              if (globalGates.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB347).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFB347).withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB347), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'لا توجد بوابات مضافة — اطلب من الأدمن إضافة بوابات من الإعدادات',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    )),
                  ]),
                )
              else
                Column(
                  children: globalGates.map((g) {
                    final selected = _selectedGate?.id == g.id;
                    final color = g.type == 'مدخل' ? const Color(0xFF00C897) : const Color(0xFFFF5A5F);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF2D3A5C) : context.bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? const Color(0xFF2D3A5C) : context.dividerColor, width: selected ? 2 : 1),
                      ),
                      child: Row(children: [
                        Expanded(child: _Tap(
                          onTap: () => setState(() { _selectedGate = g; _result = _ScanResult.none; }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(children: [
                              Icon(g.type == 'مدخل' ? Icons.login_rounded : Icons.logout_rounded, size: 16, color: selected ? Colors.white : color),
                              const SizedBox(width: 8),
                              Text('طابق ${g.floor} — ${g.type} ${g.number}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selected ? Colors.white : context.textPrimary)),
                            ]),
                          ),
                        )),
                        _Tap(
                          onTap: () => _editGateDialog(context, g),
                          child: Container(
                            padding: const EdgeInsets.all(8), margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(color: const Color(0xFF4B9EFF).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.edit_outlined, size: 15, color: selected ? Colors.white70 : const Color(0xFF4B9EFF)),
                          ),
                        ),
                        _Tap(
                          onTap: () => _deleteGateConfirm(context, g),
                          child: Container(
                            padding: const EdgeInsets.all(8), margin: const EdgeInsets.only(left: 4, right: 6),
                            decoration: BoxDecoration(color: const Color(0xFFFF5A5F).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.delete_outline, size: 15, color: selected ? Colors.white70 : const Color(0xFFFF5A5F)),
                          ),
                        ),
                      ]),
                    );
                  }).toList(),
                ),

              // عرض البوابة المحددة
              if (_selectedGate != null) ...{
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3A5C).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF00C897), size: 16),
                    const SizedBox(width: 8),
                    Text('البوابة المحددة: ', style: TextStyle(fontSize: 13, color: context.textSecondary)),
                    Text(_selectedGate!.label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3A5C))),
                  ]),
                ),
              },
            ])),
            const SizedBox(height: 14),

            // ── حقل القراءة ─────────────────────────
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _secHeader('قراءة QR / RFID', Icons.qr_code_scanner_rounded, const Color(0xFFB47AFF)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(
                         controller: _qrCtrl,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _scan,
                  onEditingComplete: () => _scan(_qrCtrl.text),
                  decoration: InputDecoration(
                    hintText: 'أدخل رقم اللوحة أو RFID...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: true, fillColor: context.bgColor,
                    prefixIcon: const Icon(Icons.nfc_rounded, color: Color(0xFFB47AFF), size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.dividerColor)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFB47AFF), width: 1.5)),
                  ),
                )),
                const SizedBox(width: 10),
                _Tap(
                  onTap: () => _scan(_qrCtrl.text),
                  child: Container(
                    height: 50, width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D3A5C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ]),
            ])),
            const SizedBox(height: 14),

            // ── نتيجة الفحص ─────────────────────────
            if (_result != _ScanResult.none)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _rc.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _rc.withValues(alpha: 0.45), width: 1.5),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ── رأس النتيجة ──
                  Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                          color: _rc.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(_ri, color: _rc, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_resultTitle, style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: _rc)),
                      const SizedBox(height: 2),
                      Text(_resultSub, style: TextStyle(
                          fontSize: 12, color: _rc.withValues(alpha: 0.8), height: 1.5)),
                    ])),
                  ]),

                  // ── بطاقة تفاصيل المركبة والمكان ──
                  if (_foundVehicle != null && _foundLine != null) ...{
                    const SizedBox(height: 14),
                    Divider(color: _rc.withValues(alpha: 0.2), height: 1),
                    const SizedBox(height: 14),
                    Row(children: [
                      Icon(Icons.info_outline_rounded, size: 14,
                          color: context.textSecondary),
                      const SizedBox(width: 6),
                      Text('تفاصيل المركبة والموقع',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                              color: context.textSecondary)),
                    ]),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.dividerColor),
                      ),
                      child: Column(children: [
                        _infoRow(Icons.directions_car_rounded, 'رقم اللوحة',
                            _foundVehicle!.vehicleId, const Color(0xFF4B9EFF)),
                        _infoDivider(),
                        _infoRow(Icons.route_outlined, 'الخط',
                            _foundLine!.name, const Color(0xFF00C897)),
                        _infoDivider(),
                        _infoRow(Icons.sensor_door_outlined,
                            _isEntry ? 'بوابة الدخول' : 'بوابة الخروج',
                            _isEntry
                              ? (globalGates.where((g) => g.id == _foundLine!.entryGateId).isNotEmpty
                                  ? globalGates.firstWhere((g) => g.id == _foundLine!.entryGateId).label
                                  : _foundLine!.gateId.isNotEmpty ? 'بوابة ${_foundLine!.gateId}' : 'غير محدد')
                              : (globalGates.where((g) => g.id == _foundLine!.exitGateId).isNotEmpty
                                  ? globalGates.firstWhere((g) => g.id == _foundLine!.exitGateId).label
                                  : 'غير محدد'),
                            _isEntry ? const Color(0xFF00C897) : const Color(0xFFFF5A5F)),
                        _infoDivider(),
                        _infoRow(Icons.format_list_numbered_rounded,
                            'رقم المركبة في الخط',
                            '#${_foundVehicle!.number}',
                            const Color(0xFFB47AFF)),
                        if (_foundVehicle!.ownerName.isNotEmpty) ...{
                          _infoDivider(),
                          _infoRow(Icons.person_outline_rounded, 'المالك',
                              _foundVehicle!.ownerName, const Color(0xFF4B9EFF)),
                        },
                        _infoDivider(),
                        _infoRow(Icons.circle_outlined, 'الحالة',
                            _foundVehicle!.status,
                            _foundVehicle!.status == 'في الانتظار'
                                ? const Color(0xFF00C897)
                                : _foundVehicle!.status == 'محظورة'
                                    ? const Color(0xFFFF5A5F)
                                    : const Color(0xFFFFB347)),
                      ]),
                    ),
                  },

                  // ── تحذير مخالفة تلقائية ──
                  if (_result != _ScanResult.ok) ...{
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _rc.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _rc.withValues(alpha: 0.25)),
                      ),
                      child: Row(children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: _rc),
                        const SizedBox(width: 8),
                        Expanded(child: Text('تم تسجيل مخالفة تلقائية في النظام',
                            style: TextStyle(
                                fontSize: 12, color: _rc, fontWeight: FontWeight.w600))),
                      ]),
                    ),
                  },
                ]),
              ),
            const SizedBox(height: 14),

          ]),
        ),
      ),
    );
  }


  void _editGateDialog(BuildContext context, GateModel gate) {
    final floorCtrl  = TextEditingController(text: gate.floor);
    final numberCtrl = TextEditingController(text: gate.number);
    final ipCtrl     = TextEditingController(text: gate.ip);
    String gateType  = gate.type;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(children: [
              Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF4B9EFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_outlined, color: Color(0xFF4B9EFF), size: 20)),
              const SizedBox(width: 10),
              Text('تعديل البوابة', style: TextStyle(color: ctx.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: floorCtrl, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'رقم الطابق',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4B9EFF), width: 1.5)))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _Tap(onTap: () => setDlg(() => gateType = 'مدخل'),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: gateType == 'مدخل' ? const Color(0xFF00C897).withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gateType == 'مدخل' ? const Color(0xFF00C897) : ctx.dividerColor)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.login_rounded, size: 15, color: gateType == 'مدخل' ? const Color(0xFF00C897) : Colors.grey),
                      const SizedBox(width: 5),
                      Text('مدخل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: gateType == 'مدخل' ? const Color(0xFF00C897) : Colors.grey)),
                    ])))),
                const SizedBox(width: 8),
                Expanded(child: _Tap(onTap: () => setDlg(() => gateType = 'مخرج'),
                  child: AnimatedContainer(duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: gateType == 'مخرج' ? const Color(0xFFFF5A5F).withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gateType == 'مخرج' ? const Color(0xFFFF5A5F) : ctx.dividerColor)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.logout_rounded, size: 15, color: gateType == 'مخرج' ? const Color(0xFFFF5A5F) : Colors.grey),
                      const SizedBox(width: 5),
                      Text('مخرج', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: gateType == 'مخرج' ? const Color(0xFFFF5A5F) : Colors.grey)),
                    ])))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: numberCtrl, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'رقم البوابة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4B9EFF), width: 1.5)))),
              const SizedBox(height: 12),
              TextField(controller: ipCtrl, keyboardType: TextInputType.url, textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: 'IP Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4B9EFF), width: 1.5)))),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: TextStyle(color: ctx.textSecondary))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D3A5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  final floor = floorCtrl.text.trim(); final number = numberCtrl.text.trim();
                  if (floor.isEmpty || number.isEmpty) return;
                  final idx = globalGates.indexOf(gate);
                  if (idx >= 0) {
                    setState(() { globalGates[idx] = GateModel(id: gate.id, floor: floor, type: gateType, number: number, ip: ipCtrl.text.trim()); });
                    autoSave();
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث البوابة ✓', textDirection: TextDirection.rtl), backgroundColor: Color(0xFF00C897)));
                },
                child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteGateConfirm(BuildContext context, GateModel gate) {
    showDialog(context: context, builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف البوابة', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل تريد حذف: \${gate.label}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              setState(() {
                globalGates.remove(gate);
                if (_selectedGate?.id == gate.id) _selectedGate = globalGates.isNotEmpty ? globalGates.first : null;
              });
              autoSave();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف البوابة', textDirection: TextDirection.rtl), backgroundColor: Color(0xFFFF5A5F)));
            },
            child: const Text('حذف', style: TextStyle(color: Color(0xFFFF5A5F), fontWeight: FontWeight.bold))),
        ],
      ),
    ));
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.cardColor, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
    ),
    child: child,
  );

  Widget _secHeader(String t, IconData i, Color c) => Row(children: [
    Container(width: 28, height: 28,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Icon(i, size: 15, color: c)),
    const SizedBox(width: 8),
    Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: c)),
  ]);

  Widget _dirBtn(String lbl, IconData i, Color c, bool selected, VoidCallback onTap) =>
    _Tap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? c : context.bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? c : context.dividerColor, width: selected ? 2 : 1),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(i, size: 16, color: selected ? Colors.white : context.textSecondary),
          const SizedBox(width: 6),
          Text(lbl, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
              color: selected ? Colors.white : context.textSecondary)),
        ]),
      ),
    );

  Widget _infoRow(IconData icon, String label, String value, Color color) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(
            fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500)),
        const Spacer(),
        Flexible(child: Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                color: context.textPrimary),
            textAlign: TextAlign.left)),
      ]),
    );

  Widget _infoDivider() =>
    Divider(height: 1, indent: 54, endIndent: 14, color: context.dividerColor);

  Widget _chip(IconData i, String lbl) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: _rc.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _rc.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(i, size: 13, color: _rc),
      const SizedBox(width: 5),
      Text(lbl, style: TextStyle(fontSize: 11, color: _rc, fontWeight: FontWeight.w600)),
    ]),
  );
}


// ─────────────────────────────────────────────
//  Manual Ban Section — بحث وحظر/رفع حظر يدوي
// ─────────────────────────────────────────────
class _ManualBanSection extends StatefulWidget {
  final VoidCallback onChanged;
  const _ManualBanSection({required this.onChanged});
  @override
  State<_ManualBanSection> createState() => _ManualBanSectionState();
}

class _ManualBanSectionState extends State<_ManualBanSection>
    with DarkModeRebuild<_ManualBanSection> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  List<(LineVehicle, int, int)> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final out = <(LineVehicle, int, int)>[];
    for (int i = 0; i < globalLines.length; i++) {
      for (int j = 0; j < globalVehicles[i].length; j++) {
        final v = globalVehicles[i][j];
        if (v.vehicleId.toLowerCase().contains(q) ||
            v.ownerName.toLowerCase().contains(q)) {
          out.add((v, i, j));
        }
      }
    }
    return out;
  }

  void _toggleBan(LineVehicle v, int li, int vi) {
    final isBanned = v.status == 'محظورة';
    final newStatus = isBanned ? 'في الانتظار' : 'محظورة';
    globalVehicles[li][vi] = LineVehicle(
      number: v.number, vehicleId: v.vehicleId, status: newStatus,
      note: v.note, ownerName: v.ownerName,
      carLicExpiry: v.carLicExpiry, insuranceExpiry: v.insuranceExpiry,
      operatingLicNum: v.operatingLicNum, operatingLicDate: v.operatingLicDate,
      rfidTag: v.rfidTag,
    );
    autoSave();
    logEvent(EventItem(
      vehicleId: v.vehicleId,
      location: globalLines[li].name,
      time: nowTime(),
      type: EventType.violation,
      violationNote: isBanned ? 'رفع الحظر عن المركبة' : 'حظر المركبة يدوياً',
    ));
    setState(() {});
    widget.onChanged();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        isBanned ? 'تم رفع الحظر عن ${v.vehicleId}' : 'تم حظر المركبة ${v.vehicleId}',
        textDirection: TextDirection.rtl,
      ),
      backgroundColor: isBanned ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5A5F).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.block_rounded, size: 15, color: Color(0xFFFF5A5F)),
            ),
            const SizedBox(width: 8),
            Text('منع/رفع حظر مركبة',
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 14, color: const Color(0xFFFF5A5F))),
            const Spacer(),
            // عدد المحظورات
            Builder(builder: (ctx) {
              final banned = globalVehicles.fold(0,
                  (s, l) => s + l.where((v) => v.status == 'محظورة').length);
              if (banned == 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5A5F).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$banned محظورة',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFFF5A5F),
                        fontWeight: FontWeight.bold)),
              );
            }),
          ]),
        ),
        const SizedBox(height: 12),
        // search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
             controller: _searchCtrl,
            textDirection: TextDirection.rtl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'ابحث عن مركبة بالرقم أو المالك...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              filled: true, fillColor: context.bgColor,
              prefixIcon: const Icon(Icons.search_rounded,
                  color: Color(0xFFFF5A5F), size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded,
                          size: 17, color: context.textSecondary),
                      onPressed: () => setState(() { _query = ''; _searchCtrl.clear(); }))
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.dividerColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF5A5F), width: 1.5)),
            ),
          ),
        ),
        // results
        if (_query.isNotEmpty) ...{
          const SizedBox(height: 8),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Text('لا توجد نتائج',
                  style: TextStyle(fontSize: 13, color: context.textSecondary)),
            )
          else
            ...results.map((rec) {
              final (v, li, vi) = rec;
              final isBanned = v.status == 'محظورة';
              return Column(children: [
                Divider(height: 1, color: context.dividerColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    // أيقونة حالة
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: isBanned
                            ? const Color(0xFFFF5A5F).withValues(alpha: 0.1)
                            : const Color(0xFF00C897).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isBanned ? Icons.block_rounded : Icons.directions_car_rounded,
                        size: 18,
                        color: isBanned ? const Color(0xFFFF5A5F) : const Color(0xFF00C897),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // معلومات المركبة
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.vehicleId, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold,
                            color: context.textPrimary)),
                        Row(children: [
                          if (v.ownerName.isNotEmpty) ...{
                            Text(v.ownerName,
                                style: TextStyle(fontSize: 11, color: context.textSecondary)),
                            const SizedBox(width: 8),
                          },
                          Text(globalLines[li].name,
                              style: TextStyle(fontSize: 11, color: context.textSecondary)),
                        ]),
                      ],
                    )),
                    // زر المنع/رفع الحظر
                    _Tap(
                      onTap: () => _toggleBan(v, li, vi),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isBanned
                              ? const Color(0xFF00C897)
                              : const Color(0xFFC62828),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
                            size: 14, color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isBanned ? 'رفع الحظر' : 'حظر',
                            style: const TextStyle(fontSize: 12,
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ]);
            }),
        } else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: Text('ابحث عن مركبة لمنعها أو رفع الحظر عنها',
                style: TextStyle(fontSize: 12, color: context.textSecondary)),
          ),
        if (_query.isEmpty) const SizedBox(height: 0),
      ]),
    );
  }
}