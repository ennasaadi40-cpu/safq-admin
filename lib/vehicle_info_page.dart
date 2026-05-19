part of station_app;

class _VehicleInfoPage extends StatefulWidget {
  final String plateNumber;
  final String ownerName;
  final String lineName;
  const _VehicleInfoPage({
    required this.plateNumber,
    required this.ownerName,
    required this.lineName,
  });
  @override
  State<_VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<_VehicleInfoPage> with DarkModeRebuild<_VehicleInfoPage> {

  LineVehicle get _lv {
    for (final list in globalVehicles) {
      for (final v in list) {
        if (v.vehicleId == widget.plateNumber) return v;
      }
    }
    return LineVehicle(number: 0, vehicleId: widget.plateNumber,
        status: 'غير معروف', ownerName: widget.ownerName);
  }

  LineModel get _line {
    for (int i = 0; i < globalLines.length; i++) {
      for (final v in globalVehicles[i]) {
        if (v.vehicleId == widget.plateNumber) return globalLines[i];
      }
    }
    return LineModel(name: widget.lineName, subtitle: '');
  }

  UserModel? get _driver {
    try { return globalUsers.firstWhere((u) => u.name == (_lv.ownerName) && u.role == 'سائق'); }
    catch (_) { return null; }
  }

  UserModel? get _owner {
    try { return globalUsers.firstWhere((u) => u.name == (_lv.ownerName) && u.role == 'مالك سيارة'); }
    catch (_) { return null; }
  }

  List<EventItem> get _events =>
      globalEvents.where((e) => e.vehicleId == _lv.vehicleId).toList().reversed.take(10).toList();

  Color get _statusColor {
    switch (_lv.status) {
      case 'جاهزة':   return const Color(0xFF00C897);
      case 'في الخط': return const Color(0xFF4B9EFF);
      case 'محظورة':  return const Color(0xFFFF5A5F);
      default:         return const Color(0xFFFFB347);
    }
  }

  Future<void> _printVehicle(LineVehicle lv, LineModel line) async {
    try {
      final pdf = pw.Document();
      pw.Font? arabicFont;
      try {
        final res = await http.get(Uri.parse(
          'https://fonts.gstatic.com/s/tajawal/v9/Iurf6YBj_oCad4k1nzSBC45I.ttf',
        )).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) arabicFont = pw.Font.ttf(res.bodyBytes.buffer.asByteData());
      } catch (_) {}
      if (arabicFont == null) {
        try { arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Regular.ttf')); } catch (_) {}
      }

      pw.TextStyle ar({double size = 12, pw.FontWeight w = pw.FontWeight.normal, PdfColor? color}) {
        var s = pw.TextStyle(fontSize: size, fontWeight: w, color: color);
        if (arabicFont != null) s = s.copyWith(font: arabicFont);
        return s;
      }

      pw.TableRow tRow(String label, String value) => pw.TableRow(children: [
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: pw.Text(value, textDirection: pw.TextDirection.rtl, textAlign: pw.TextAlign.right, style: ar(w: pw.FontWeight.bold))),
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: pw.Text(label, textDirection: pw.TextDirection.rtl, textAlign: pw.TextAlign.right, style: ar(color: PdfColors.grey700))),
      ]);

      final owner = _driver ?? _owner;

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey800,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('بطاقة معلومات المركبة', style: ar(size: 18, w: pw.FontWeight.bold, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text('محطة الحافلات المركزية — الخليل', style: ar(size: 12, color: PdfColors.grey300)),
            ]),
          ),
          pw.SizedBox(height: 20),

          pw.Text('معلومات المركبة', style: ar(size: 14, w: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5), // ← تم التصحيح هنا
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1)},
            children: [
              tRow('رقم اللوحة', lv.vehicleId),
              tRow('الحالة', lv.status),
              tRow('اسم المالك', lv.ownerName.isNotEmpty ? lv.ownerName : '—'),
              tRow('رقم الخط', line.name),
            ],
          ),
          pw.SizedBox(height: 16),

          if (owner != null) ...[
            pw.Text('معلومات المالك', style: ar(size: 14, w: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1)},
              children: [
                tRow('الاسم', owner.name),
                tRow('رقم الهوية', owner.idNumber.isNotEmpty ? owner.idNumber : '—'),
                tRow('رقم الهاتف', owner.phone.isNotEmpty ? owner.phone : '—'),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          pw.Text('التراخيص', style: ar(size: 14, w: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1)},
            children: [
              tRow('رقم رخصة التشغيل', lv.operatingLicNum.isNotEmpty ? lv.operatingLicNum : '—'),
              tRow('انتهاء رخصة السيارة', lv.carLicExpiry.isNotEmpty ? lv.carLicExpiry : '—'),
              tRow('انتهاء التأمين', lv.insuranceExpiry.isNotEmpty ? lv.insuranceExpiry : '—'),
              tRow('انتهاء التحميل', lv.loadingExpiry.isNotEmpty ? lv.loadingExpiry : '—'),
            ],
          ),

          pw.Spacer(),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 4),
          pw.Text('تم الإنشاء تلقائياً — نظام إدارة محطة الخليل',
              style: ar(size: 9, color: PdfColors.grey500)),
        ]),
      ));

      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/vehicle_${lv.vehicleId}.pdf');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الطباعة: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lv      = _lv;
    final line    = _line;
    final carNum  = lv.vehicleId;
    final rfidTag = lv.rfidTag.isNotEmpty ? lv.rfidTag : '—';
    final opLicNum = lv.operatingLicNum.isNotEmpty ? lv.operatingLicNum : '—';
    final lineNum  = line.gateId.isNotEmpty ? line.gateId : '—';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.bgColor,
        body: CustomScrollView(
          slivers: [

            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: const Color(0xFF1A2540),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.print_rounded, color: Colors.white),
                  tooltip: 'طباعة',
                  onPressed: () => _printVehicle(lv, line),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(fit: StackFit.expand, children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Color(0xFF1A2540), Color(0xFF2D3A5C), Color(0xFF1E3A5F)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: -40, top: -40,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20, bottom: -30,
                    child: Container(
                      width: 150, height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _statusColor.withValues(alpha: 0.15),
                              border: Border.all(color: _statusColor.withValues(alpha: 0.6)),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 7, height: 7,
                                decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(lv.status, style: TextStyle(
                                  color: _statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ]),
                          ),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('رقم المركبة', style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                            Text(carNum, style: const TextStyle(
                                color: Colors.white, fontSize: 32,
                                fontWeight: FontWeight.bold, letterSpacing: 2)),
                          ]),
                        ]),
                        const SizedBox(height: 8),
                        Text(line.name, style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                      ],
                    ),
                  ),
                ]),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(delegate: SliverChildListDelegate([

                _VInfoCard(
                  icon: Icons.person_outlined,
                  title: 'السائق',
                  accentColor: const Color(0xFF4B9EFF),
                  rows: [
                    _Row('الاسم',             _driver?.name       ?? lv.ownerName),
                    _Row('رقم الهوية',         _driver?.idNumber   ?? '—'),
                    _Row('رقم الهاتف',         _driver?.phone      ?? '—'),
                    _Row('رقم رخصة القيادة',   _driver?.licenseNum ?? '—'),
                    _Row('تاريخ إصدار الرخصة', _driver?.licenseIssueDate ?? '—'),
                    _Row('درجة الرخصة',
                        _driver?.licenseGrade.isNotEmpty == true ? _driver!.licenseGrade : 'نقل عام'),
                  ],
                ),
                const SizedBox(height: 12),

                _VInfoCard(
                  icon: Icons.directions_car_outlined,
                  title: 'المركبة',
                  accentColor: const Color(0xFF00C897),
                  rows: [
                    _Row('رقم السيارة', carNum),
                    _Row('وسم RFID',    rfidTag),
                    _Row('نوع السيارة', '—'),
                    _Row('اسم المحطة', 'محطة الحافلات المركزية — الخليل'),
                  ],
                ),
                const SizedBox(height: 12),

                _VInfoCard(
                  icon: Icons.verified_outlined,
                  title: 'رخصة التشغيل',
                  accentColor: const Color(0xFFFFB347),
                  rows: [
                    _Row('رقم ترخيص التشغيل',
                        lv.operatingLicNum.isNotEmpty ? lv.operatingLicNum : opLicNum),
                    _Row('تاريخ ترخيص التشغيل',
                        lv.operatingLicDate.isNotEmpty ? lv.operatingLicDate : '—'),
                    _Row('انتهاء رخصة السيارة',
                        lv.carLicExpiry.isNotEmpty ? lv.carLicExpiry : '—',
                        badge: expiryBadge('الرخصة',
                            lv.carLicExpiry.isNotEmpty ? lv.carLicExpiry : '—')),
                    _Row('انتهاء التأمين',
                        lv.insuranceExpiry.isNotEmpty ? lv.insuranceExpiry : '—',
                        badge: expiryBadge('التأمين',
                            lv.insuranceExpiry.isNotEmpty ? lv.insuranceExpiry : '—')),
                  ],
                ),
                const SizedBox(height: 12),

                Builder(builder: (ctx) {
                  UserModel? ownerUser;
                  try {
                    ownerUser = globalUsers.firstWhere(
                        (u) => u.name == lv.ownerName && u.role == 'مالك سيارة');
                  } catch (_) {}
                  ownerUser ??= _driver;
                  return _VInfoCard(
                    icon: Icons.badge_outlined,
                    title: 'المالك',
                    accentColor: const Color(0xFFB47AFF),
                    rows: [
                      _Row('اسم المالك',
                          lv.ownerName.isNotEmpty ? lv.ownerName : widget.ownerName),
                      _Row('رقم الهاتف',
                          ownerUser?.phone.isNotEmpty == true ? ownerUser!.phone : '—'),
                      _Row('رقم الهوية',
                          ownerUser?.idNumber.isNotEmpty == true ? ownerUser!.idNumber : '—'),
                    ],
                  );
                }),
                const SizedBox(height: 12),

                _VInfoCard(
                  icon: Icons.route_outlined,
                  title: 'الخط',
                  accentColor: const Color(0xFFFF5A5F),
                  rows: [
                    _Row('اسم الخط',    line.name),
                    _Row('رقم الخط',    lineNum),
                    _Row('اسم المحطة', 'محطة الخليل المركزية'),
                    _Row('بوابة الدخول',
                        line.entryGateId.isNotEmpty ? line.entryGateId : '—'),
                    _Row('بوابة الخروج',
                        line.exitGateId.isNotEmpty ? line.exitGateId : '—'),
                  ],
                ),
                const SizedBox(height: 12),

                _RenewLicenseButton(
                  vehicle: lv,
                  onRenewed: () => setState(() {}),
                ),
                const SizedBox(height: 12),

                _LoadingPermitCard(
                  vehicle: lv,
                  onUpdated: () => setState(() {}),
                ),

                if (_events.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('آخر الأحداث',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 14, color: context.textPrimary)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                    ),
                    child: Column(children: _events.asMap().entries.map((e) {
                      final ev     = e.value;
                      final isLast = e.key == _events.length - 1;
                      final evColor = ev.type == EventType.entry  ? const Color(0xFF00C897)
                                    : ev.type == EventType.exit   ? const Color(0xFF4B9EFF)
                                    : const Color(0xFFFF5A5F);
                      final evIcon  = ev.type == EventType.entry  ? Icons.login_rounded
                                    : ev.type == EventType.exit   ? Icons.logout_rounded
                                    : Icons.warning_rounded;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: isLast ? null : Border(
                              bottom: BorderSide(color: context.dividerColor, width: 0.5)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: evColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(evIcon, size: 17, color: evColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(
                            ev.type == EventType.violation
                                ? 'شكوى: ${ev.violationNote ?? ""}'
                                : '${ev.type == EventType.entry ? "دخول" : "خروج"} — ${ev.location}',
                            style: TextStyle(fontSize: 13, color: context.textPrimary),
                          )),
                          Text(ev.time,
                              style: TextStyle(fontSize: 10, color: context.textSecondary)),
                        ]),
                      );
                    }).toList()),
                  ),
                ],
                const SizedBox(height: 32),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card widget للمركبة ───────────────────────
class _VInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final List<_Row> rows;
  const _VInfoCard({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: accentColor.withValues(alpha: 0.2))),
          ),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: accentColor),
            ),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: accentColor)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(children: rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('• ', style: TextStyle(
                    color: accentColor, fontSize: 14, fontWeight: FontWeight.bold)),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      textDirection: TextDirection.rtl,
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, fontFamily: 'Tajawal',
                            color: context.textPrimary),
                        children: [
                          TextSpan(text: '${e.value.label} : ',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(text: e.value.value,
                              style: TextStyle(color: context.textSecondary)),
                        ],
                      ),
                    ),
                    if (e.value.badge != null) ...[
                      const SizedBox(height: 4),
                      e.value.badge!,
                    ],
                  ],
                )),
              ]),
            );
          }).toList()),
        ),
      ]),
    );
  }
}

class _Row {
  final String label, value;
  final Widget? badge;
  const _Row(this.label, this.value, {this.badge});
}

// ─────────────────────────────────────────────
//  Renew License Button
// ─────────────────────────────────────────────
class _RenewLicenseButton extends StatefulWidget {
  final LineVehicle vehicle;
  final VoidCallback onRenewed;
  const _RenewLicenseButton({required this.vehicle, required this.onRenewed});
  @override
  State<_RenewLicenseButton> createState() => _RenewLicenseButtonState();
}

class _RenewLicenseButtonState extends State<_RenewLicenseButton>
    with DarkModeRebuild<_RenewLicenseButton> {

  String _extend(String dateStr, int months) {
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;
      var d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      if (d.isBefore(DateTime.now())) d = DateTime.now();
      int newMonth = d.month + months;
      int newYear  = d.year + (newMonth - 1) ~/ 12;
      newMonth     = ((newMonth - 1) % 12) + 1;
      return '$newYear-${newMonth.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    } catch (_) { return dateStr; }
  }

  void _showRenewDialog() {
    String selectedType = 'رخصة السيارة';
    bool paid = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final current = selectedType == 'رخصة السيارة'
              ? widget.vehicle.carLicExpiry
              : widget.vehicle.insuranceExpiry;
          final newDate = _extend(current, 1);
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C897).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_outlined, color: Color(0xFF00C897), size: 20),
                ),
                const SizedBox(width: 10),
                Text('تجديد رخصة التشغيل',
                    style: TextStyle(color: ctx.textPrimary,
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              content: Column(mainAxisSize: MainAxisSize.min, children: [

                Text('نوع الرخصة', style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                const SizedBox(height: 8),
                Row(children: ['رخصة السيارة', 'التأمين'].map((type) {
                  final sel = selectedType == type;
                  return Expanded(child: _Tap(
                    onTap: () => setDlg(() => selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(left: type == 'التأمين' ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF00C897) : ctx.bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? const Color(0xFF00C897) : ctx.dividerColor,
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Text(type, textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : ctx.textPrimary)),
                    ),
                  ));
                }).toList()),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C897).withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF00C897).withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF00C897)),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('التاريخ الحالي: ${current.isEmpty ? "غير محدد" : current}',
                          style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
                      const SizedBox(height: 2),
                      Text('بعد التجديد (شهر): $newDate',
                          style: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.bold, color: Color(0xFF00C897))),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),

                _Tap(
                  onTap: () => setDlg(() => paid = !paid),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: paid
                          ? const Color(0xFF00C897).withValues(alpha: 0.1)
                          : ctx.bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: paid ? const Color(0xFF00C897) : ctx.dividerColor,
                        width: paid ? 2 : 1,
                      ),
                    ),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: paid ? const Color(0xFF00C897) : Colors.transparent,
                          border: Border.all(
                            color: paid ? const Color(0xFF00C897) : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: paid
                            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text('تم استلام الدفع',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: paid ? const Color(0xFF00C897) : ctx.textPrimary)),
                    ]),
                  ),
                ),
              ]),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('إلغاء', style: TextStyle(color: ctx.textSecondary)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paid ? const Color(0xFF00C897) : Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  label: const Text('تجديد شهر',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: paid ? () {
                    for (int i = 0; i < globalLines.length; i++) {
                      for (int j = 0; j < globalVehicles[i].length; j++) {
                        if (globalVehicles[i][j].vehicleId == widget.vehicle.vehicleId) {
                          final old = globalVehicles[i][j];
                          globalVehicles[i][j] = LineVehicle(
                            number: old.number, vehicleId: old.vehicleId,
                            status: old.status, note: old.note, ownerName: old.ownerName,
                            operatingLicNum: old.operatingLicNum,
                            operatingLicDate: old.operatingLicDate,
                            carLicExpiry: selectedType == 'رخصة السيارة'
                                ? newDate : old.carLicExpiry,
                            insuranceExpiry: selectedType == 'التأمين'
                                ? newDate : old.insuranceExpiry,
                          );
                        }
                      }
                    }
                    autoSave();
                    logEvent(EventItem(
                      vehicleId: widget.vehicle.vehicleId,
                      location: 'تجديد $selectedType — شهر',
                      time: nowTime(),
                      type: EventType.entry,
                    ));
                    widget.onRenewed();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('تم تجديد $selectedType حتى $newDate',
                          textDirection: TextDirection.rtl),
                      backgroundColor: const Color(0xFF00C897),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 3),
                    ));
                  } : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final licStatus  = expiryStatus(widget.vehicle.carLicExpiry);
    final insStatus  = expiryStatus(widget.vehicle.insuranceExpiry);
    final needsRenew = licStatus == 'expired' || licStatus == 'soon' ||
                       insStatus == 'expired' || insStatus == 'soon';

    return _Tap(
      onTap: _showRenewDialog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: needsRenew
              ? const Color(0xFF00C897).withValues(alpha: 0.08)
              : context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: needsRenew
                ? const Color(0xFF00C897).withValues(alpha: 0.4)
                : context.dividerColor,
          ),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF00C897).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.autorenew_rounded, color: Color(0xFF00C897), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('تجديد رخصة التشغيل / التأمين',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                    color: Color(0xFF00C897))),
            Text(needsRenew ? 'يوجد رخصة تحتاج تجديد' : 'اضغط لتمديد صلاحية الرخصة',
                style: TextStyle(fontSize: 11, color: context.textSecondary)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF00C897)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Loading Permit Card
// ─────────────────────────────────────────────
class _LoadingPermitCard extends StatefulWidget {
  final LineVehicle vehicle;
  final VoidCallback onUpdated;
  const _LoadingPermitCard({required this.vehicle, required this.onUpdated});
  @override
  State<_LoadingPermitCard> createState() => _LoadingPermitCardState();
}

class _LoadingPermitCardState extends State<_LoadingPermitCard>
    with DarkModeRebuild<_LoadingPermitCard> {

  bool get _hasPermit => widget.vehicle.loadingExpiry.isNotEmpty;

  int get _daysLeft {
    if (!_hasPermit) return 0;
    try {
      final p = widget.vehicle.loadingExpiry.split('-');
      final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      return d.difference(DateTime.now()).inDays;
    } catch (_) { return 0; }
  }

  Color get _permitColor {
    if (!_hasPermit) return const Color(0xFF8A93A8);
    if (_daysLeft < 0)  return const Color(0xFFFF5A5F);
    if (_daysLeft <= 3) return const Color(0xFFFFB347);
    return const Color(0xFF00C897);
  }

  void _showEditDialog() {
    final ctrl = TextEditingController(text: widget.vehicle.loadingExpiry);
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('انتهاء التحميل',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (ctrl.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _permitColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(Icons.timer_outlined, color: _permitColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _daysLeft < 0
                        ? 'انتهى منذ ${_daysLeft.abs()} يوم'
                        : _daysLeft == 0 ? 'ينتهي اليوم' : 'متبقي $_daysLeft يوم',
                    style: TextStyle(color: _permitColor,
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ]),
              ),
            TextField(
              controller: ctrl,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'YYYY-MM-DD',
                prefixIcon: const Icon(Icons.calendar_today,
                    size: 18, color: Color(0xFF2D3A5C)),
                suffixIcon: ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () { ctrl.clear(); setState(() {}); })
                    : null,
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E4EE))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  ctrl.text =
                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (ctx2, setInner) => Wrap(
                spacing: 8, runSpacing: 6,
                children: [3, 7, 14, 30].map((days) {
                  final date = DateTime.now().add(Duration(days: days));
                  return _Tap(
                    onTap: () {
                      ctrl.text =
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      setInner(() {});
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D3A5C).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF2D3A5C).withValues(alpha: 0.2)),
                      ),
                      child: Text('+$days يوم',
                          style: const TextStyle(fontSize: 12,
                              color: Color(0xFF2D3A5C), fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: TextStyle(color: context.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3A5C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                for (int i = 0; i < globalVehicles.length; i++) {
                  for (int j = 0; j < globalVehicles[i].length; j++) {
                    if (globalVehicles[i][j].vehicleId == widget.vehicle.vehicleId) {
                      final old = globalVehicles[i][j];
                      globalVehicles[i][j] = LineVehicle(
                        number: old.number,
                        vehicleId: old.vehicleId,
                        status: old.status,
                        note: old.note,
                        ownerName: old.ownerName,
                        carLicExpiry: old.carLicExpiry,
                        insuranceExpiry: old.insuranceExpiry,
                        operatingLicNum: old.operatingLicNum,
                        operatingLicDate: old.operatingLicDate,
                        rfidTag: old.rfidTag,
                        loadingExpiry: ctrl.text.trim(),
                      );
                    }
                  }
                }
                autoSave();
                Navigator.pop(context);
                widget.onUpdated();
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Tap(
      onTap: _showEditDialog,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _permitColor.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _permitColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_shipping_outlined, color: _permitColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('إذن التحميل',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                    color: context.textPrimary)),
            const SizedBox(height: 3),
            if (!_hasPermit)
              Text('اضغط لتحديد تاريخ الانتهاء',
                  style: TextStyle(fontSize: 11, color: context.textSecondary))
            else
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('حتى: ${widget.vehicle.loadingExpiry}',
                    style: TextStyle(fontSize: 11, color: context.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  _daysLeft < 0
                      ? 'انتهى منذ ${_daysLeft.abs()} يوم'
                      : _daysLeft == 0 ? 'ينتهي اليوم!' : 'متبقي $_daysLeft يوم',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: _permitColor),
                ),
              ]),
          ])),
          Icon(Icons.edit_outlined, size: 16, color: context.textSecondary),
        ]),
      ),
    );
  }
}