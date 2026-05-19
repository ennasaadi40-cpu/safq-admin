part of station_app;

class _UserInfoPage extends StatefulWidget {
  final UserModel user;
  const _UserInfoPage({required this.user});
  @override
  State<_UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<_UserInfoPage> with DarkModeRebuild<_UserInfoPage> {

  List<Map<String, String>> get _history {
    final u = widget.user;
    final result = <Map<String, String>>[];

    // ابحث عن سيارات المستخدم
    final userVehicleIds = <String>{};
    for (final list in globalVehicles) {
      for (final v in list) {
        if (v.ownerName == u.name) userVehicleIds.add(v.vehicleId);
      }
    }

    // حوّل globalEvents إلى history entries
    for (final e in globalEvents) {
      final isUserEvent = e.vehicleId.contains(u.name);
      final isVehicleEvent = userVehicleIds.contains(e.vehicleId);

      if (!isUserEvent && !isVehicleEvent) continue;

      String type;
      String eventText;

      if (isUserEvent) {
        // حدث متعلق بالمستخدم مباشرة
        switch (e.type) {
          case EventType.entry:
            type = 'create';
            eventText = e.location;
            break;
          case EventType.exit:
            type = 'contract';
            eventText = e.location;
            break;
          case EventType.violation:
            type = 'warning';
            eventText = e.violationNote ?? e.location;
            break;
        }
      } else {
        // حدث متعلق بسيارة المستخدم
        switch (e.type) {
          case EventType.entry:
            type = 'vehicle';
            eventText = 'دخول مركبة ${e.vehicleId} — ${e.location}';
            break;
          case EventType.exit:
            type = 'remove';
            eventText = 'خروج مركبة ${e.vehicleId} — ${e.location}';
            break;
          case EventType.violation:
            type = 'warning';
            eventText = 'شكوى للمركبة ${e.vehicleId}: ${e.violationNote ?? e.location}';
            break;
        }
      }

      result.add({
        'type': type,
        'event': eventText,
        'date': e.time,
      });
    }

    if (result.isEmpty) {
      result.add({
        'type': 'create',
        'event': 'تم تسجيل المستخدم "${u.name}" في النظام',
        'date': 'غير محدد',
      });
    }

    return result;
  }

  Color get _roleColor {
    switch (widget.user.role) {
      case 'سائق':        return const Color(0xFF4B9EFF);
      case 'مالك سيارة': return const Color(0xFF00C897);
      case 'مشرف خط':    return const Color(0xFFFFB347);
      case 'موظف أمن':   return const Color(0xFFB47AFF);
      default:             return const Color(0xFF8A93A8);
    }
  }

  IconData get _roleIcon {
    switch (widget.user.role) {
      case 'سائق':        return Icons.drive_eta_outlined;
      case 'مالك سيارة': return Icons.car_rental_outlined;
      case 'مشرف خط':    return Icons.supervised_user_circle_outlined;
      case 'موظف أمن':   return Icons.security_outlined;
      default:             return Icons.person_outlined;
    }
  }

  Future<void> _printUser(UserModel u) async {
    try {
      final pdf = pw.Document();
      pw.Font? arabicFont;
      // حاول تحميل الخط من الإنترنت
      try {
        final res = await http.get(Uri.parse(
          'https://fonts.gstatic.com/s/tajawal/v9/Iurf6YBj_oCad4k1nzSBC45I.ttf',
        )).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          arabicFont = pw.Font.ttf(res.bodyBytes.buffer.asByteData());
        }
      } catch (_) {}
      // fallback: حاول من assets
      if (arabicFont == null) {
        try {
          arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
        } catch (_) {}
      }

      final theme = arabicFont != null
          ? pw.ThemeData.withFont(base: arabicFont, bold: arabicFont)
          : pw.ThemeData.base();

      pw.TextStyle ar({double size = 12, pw.FontWeight w = pw.FontWeight.normal, PdfColor? color}) {
        var s = pw.TextStyle(fontSize: size, fontWeight: w, color: color);
        if (arabicFont != null) s = s.copyWith(font: arabicFont);
        return s;
      }

      pw.TableRow tRow(String label, String value) => pw.TableRow(children: [
        // عمود القيمة (يسار)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: pw.Text(value,
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.right,
            style: ar(w: pw.FontWeight.bold)),
        ),
        // عمود التسمية (يمين)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: pw.Text(label,
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.right,
            style: ar(color: PdfColors.grey700)),
        ),
      ]);

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          // Header
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey800,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('بطاقة معلومات المستخدم', style: ar(size: 18, w: pw.FontWeight.bold, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text('محطة الحافلات المركزية — الخليل', style: ar(size: 12, color: PdfColors.grey300)),
            ]),
          ),
          pw.SizedBox(height: 20),

          // المعلومات الأساسية
          pw.Text('المعلومات الأساسية', style: ar(size: 14, w: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1)},
            children: [
            tRow('الاسم الكامل',  u.name),
            tRow('الدور',         u.role),
            tRow('رقم الهوية',    u.idNumber.isEmpty ? '—' : u.idNumber),
            tRow('رقم الهاتف',    u.phone.isEmpty    ? '—' : u.phone),
            if (u.phone2.isNotEmpty) tRow('رقم الهاتف 2', u.phone2),
            tRow('الحالة',        u.isActive ? 'نشط' : 'معلق'),
            if (u.macAddress.isNotEmpty) tRow('MAC Address', u.macAddress),
          ]),
          pw.SizedBox(height: 16),

          // بيانات الرخصة (سائق فقط)
          if (u.role == 'سائق') ...[
            pw.Text('رخصة القيادة', style: ar(size: 14, w: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1)},
              children: [
              tRow('رقم الرخصة',     u.licenseNum.isEmpty       ? '—' : u.licenseNum),
              tRow('تاريخ الإصدار',  u.licenseIssueDate.isEmpty ? '—' : u.licenseIssueDate),
              tRow('تاريخ الانتهاء', u.licenseExpiry.isEmpty    ? '—' : u.licenseExpiry),
              tRow('الدرجة',         u.licenseGrade.isEmpty     ? '—' : u.licenseGrade),
            ]),
            pw.SizedBox(height: 16),
          ],

          // خطوط مشرف الخط
          if (u.role == 'مشرف خط') ...[
            pw.Text('الخطوط المسؤول عنها', style: ar(size: 14, w: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1)},
              children: [
              ...() {
                final rows = <pw.TableRow>[];
                for (int i = 0; i < globalLines.length; i++) {
                  if (globalLines[i].supervisor == u.name) {
                    final nm = RegExp(r'\[(\d+)\]\s*(.*)').firstMatch(globalLines[i].name);
                    rows.add(tRow('رقم الخط', nm?.group(1) ?? '${i+1}'));
                    rows.add(tRow('اسم الخط', nm?.group(2) ?? globalLines[i].name));
                  }
                }
                if (rows.isEmpty) rows.add(tRow('لا توجد خطوط مسندة', ''));
                return rows;
              }(),
            ]),
            pw.SizedBox(height: 16),
          ],

          pw.Spacer(),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 4),
          pw.Text('تم الإنشاء تلقائياً — نظام إدارة محطة الخليل',
              style: ar(size: 9, color: PdfColors.grey500)),
        ]),
      ));

      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/user_${u.name}.pdf');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('خطأ في الطباعة: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _changeUserPassword(UserModel u) {
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showNew = false, showConfirm = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setDlg) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF2D3A5C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.lock_reset_outlined, color: Color(0xFF2D3A5C), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('تغيير كلمة سر ${u.name}',
                style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 15))),
          ]),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (u.password.isNotEmpty) ...[
              Text('كلمة السر الحالية', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                  color: context.textSecondary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: context.bgColor, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(Icons.lock_outline, size: 15, color: context.textSecondary),
                  const SizedBox(width: 8),
                  Text(u.password, style: TextStyle(color: context.textSecondary, fontFamily: 'monospace')),
                ]),
              ),
              const SizedBox(height: 16),
            ],
            Text('كلمة السر الجديدة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                color: context.textSecondary)),
            const SizedBox(height: 6),
            StatefulBuilder(builder: (_, sf) => TextField(
                  controller: newPassCtrl, obscureText: !showNew,
              decoration: InputDecoration(
                hintText: 'أدخل كلمة السر الجديدة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: Icon(showNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () { sf(() => showNew = !showNew); },
                ),
              ),
            )),
            const SizedBox(height: 12),
            Text('تأكيد كلمة السر', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                color: context.textSecondary)),
            const SizedBox(height: 6),
            StatefulBuilder(builder: (_, sf) => TextField(
                  controller: confirmCtrl, obscureText: !showConfirm,
              decoration: InputDecoration(
                hintText: 'أعد إدخال كلمة السر',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: Icon(showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                  onPressed: () { sf(() => showConfirm = !showConfirm); },
                ),
              ),
            )),
            if (errorMsg != null) ...[
              const SizedBox(height: 8),
              Text(errorMsg!, style: const TextStyle(color: Color(0xFFFF5A5F), fontSize: 12)),
            ],
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: Text('إلغاء', style: TextStyle(color: context.textSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D3A5C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                if (newPassCtrl.text.isEmpty) { setDlg(() => errorMsg = 'أدخل كلمة السر'); return; }
                if (newPassCtrl.text != confirmCtrl.text) { setDlg(() => errorMsg = 'كلمتا السر غير متطابقتين'); return; }
                final idx = globalUsers.indexWhere((u2) => u2.name == u.name);
                if (idx != -1) {
                  final updated = UserModel(name: u.name, role: u.role, status: u.status,
                      phone: u.phone, idNumber: u.idNumber, licenseNum: u.licenseNum,
                      licenseExpiry: u.licenseExpiry, isActive: u.isActive,
                      licenseIssueDate: u.licenseIssueDate, licenseGrade: u.licenseGrade,
                      password: newPassCtrl.text);
                  globalUsers[idx] = updated;
                  autoSave();
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Row(children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                    SizedBox(width: 8), Text('تم تغيير كلمة السر ✅'),
                  ]),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              },
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.bgColor,
        body: CustomScrollView(slivers: [

          // ══ Hero Header ════════════════════════
          SliverAppBar(
            expandedHeight: 220,
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
                onPressed: () => _printUser(u),
              ),
              IconButton(
                icon: const Icon(Icons.lock_reset_outlined, color: Colors.white),
                onPressed: () => _changeUserPassword(u),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(fit: StackFit.expand, children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight, end: Alignment.bottomLeft,
                      colors: [const Color(0xFF1A2540), _roleColor.withValues(alpha: 0.6), const Color(0xFF1A2540)],
                    ),
                  ),
                ),
                // decorative circles
                Positioned(right: -30, top: -30, child: Container(
                  width: 180, height: 180,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: _roleColor.withValues(alpha: 0.08)),
                )),
                Positioned(left: -20, bottom: -20, child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04)),
                )),
                // content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.end, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      // status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: u.isActive ? const Color(0xFF00C897).withValues(alpha: 0.15) : const Color(0xFFFF5A5F).withValues(alpha: 0.15),
                          border: Border.all(color: u.isActive ? const Color(0xFF00C897) : const Color(0xFFFF5A5F)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(
                              color: u.isActive ? const Color(0xFF00C897) : const Color(0xFFFF5A5F),
                              shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(u.isActive ? 'نشط' : 'معلق', style: TextStyle(
                              color: u.isActive ? const Color(0xFF00C897) : const Color(0xFFFF5A5F),
                              fontWeight: FontWeight.bold, fontSize: 11)),
                        ]),
                      ),
                      // avatar + name
                      Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(u.name, style: const TextStyle(color: Colors.white,
                              fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _roleColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(_roleIcon, size: 12, color: _roleColor),
                              const SizedBox(width: 4),
                              Text(u.role, style: TextStyle(color: _roleColor, fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ]),
                        const SizedBox(width: 14),
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _roleColor.withValues(alpha: 0.2),
                            border: Border.all(color: _roleColor.withValues(alpha: 0.5), width: 2),
                          ),
                          child: Icon(_roleIcon, color: _roleColor, size: 26),
                        ),
                      ]),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),

          // ══ Body ════════════════════════════════
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([

              // بطاقة المعلومات الأساسية
              _UInfoCard(
                icon: Icons.person_outlined,
                title: 'المعلومات الأساسية',
                accentColor: _roleColor,
                rows: [
                  _URow('الاسم الكامل',  u.name),
                  _URow('نوع المستخدم', u.role),
                  _URow('رقم الهاتف',   u.phone.isEmpty    ? 'غير مسجل' : u.phone),
                  _URow('رقم الهوية',   u.idNumber.isEmpty ? 'غير مسجل' : u.idNumber),
                  _URow('الحالة',       u.status.isEmpty ? (u.isActive ? 'نشط' : 'معلق') : u.status),
                  if ((u.role == 'سائق' || u.role == 'موظف أمن') && u.macAddress.isNotEmpty)
                    _URow('MAC Address', u.macAddress),
                ],
              ),
              const SizedBox(height: 12),

              // بطاقة الرخصة (سائق فقط)
              if (u.role == 'سائق') ...[
                _UInfoCard(
                  icon: Icons.drive_eta_outlined,
                  title: 'رخصة القيادة',
                  accentColor: const Color(0xFF4B9EFF),
                  rows: [
                    _URow('رقم الرخصة',         u.licenseNum.isEmpty       ? 'غير مسجل' : u.licenseNum),
                    _URow('تاريخ الإصدار',       u.licenseIssueDate.isEmpty ? 'غير مسجل' : u.licenseIssueDate),
                    _URow('تاريخ الانتهاء',      u.licenseExpiry.isEmpty    ? 'غير مسجل' : u.licenseExpiry,
                        badge: _licenseBadge(u)),
                    _URow('درجة الرخصة',        u.licenseGrade.isEmpty     ? 'غير مسجل' : u.licenseGrade),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // بطاقة الأمان
              _UInfoCard(
                icon: Icons.security_outlined,
                title: 'الأمان',
                accentColor: const Color(0xFFFFB347),
                rows: [
                  _URow('كلمة السر', u.password.isEmpty ? 'غير محددة' : '●' * u.password.length),
                ],
              ),
              const SizedBox(height: 12),

              // ── خطوط مشرف الخط ────────────────────────
              if (u.role == 'مشرف خط') Builder(builder: (ctx) {
                final supervisedLines = <int>[];
                for (int i = 0; i < globalLines.length; i++) {
                  if (globalLines[i].supervisor == u.name) supervisedLines.add(i);
                }
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _UInfoCard(
                    icon: Icons.route_outlined,
                    title: 'الخطوط المسؤول عنها (${supervisedLines.length})',
                    accentColor: const Color(0xFFFFB347),
                    rows: supervisedLines.isEmpty
                      ? [const _URow('لا توجد خطوط مسندة لهذا المشرف', '')]
                      : supervisedLines.map((i) {
                          final line = globalLines[i];
                          final numMatch = RegExp(r'\[(\d+)\]\s*(.*)').firstMatch(line.name);
                          final lineNum  = numMatch?.group(1) ?? '—';
                          final lineName = numMatch?.group(2) ?? line.name;
                          return _URow('خط $lineNum', lineName);
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                ]);
              }),

              // ── معلومات موظف الأمن ───────────────────────
              if (u.role == 'موظف أمن') Builder(builder: (ctx) {
                // تنبيهات الأمن الخاصة بهذا الموظف
                final myAlerts = globalSecurityNotifications
                    .where((n) => n['role'] == 'security')
                    .toList();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _UInfoCard(
                    icon: Icons.shield_outlined,
                    title: 'تنبيهات الأمن (${myAlerts.length})',
                    accentColor: const Color(0xFFB47AFF),
                    rows: myAlerts.isEmpty
                      ? [const _URow('لا توجد تنبيهات أمنية', '')]
                      : myAlerts.take(5).map((n) => _URow(
                            n['title'] ?? '—',
                            '${n['body'] ?? ''}  •  ${n['time'] ?? ''}',
                          )).toList(),
                  ),
                  const SizedBox(height: 12),
                ]);
              }),

              // ── مركبات المالك ──────────────────────────
              if (u.role == 'مالك سيارة') Builder(builder: (ctx) {
                final owned = <LineVehicle>[];
                for (final list in globalVehicles)
                  for (final v in list)
                    if (v.ownerName == u.name) owned.add(v);
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _UInfoCard(
                    icon: Icons.directions_car_outlined,
                    title: 'السيارات المملوكة (${owned.length})',
                    accentColor: const Color(0xFF00C897),
                    rows: owned.isEmpty
                      ? [const _URow('لا توجد سيارات مسجلة', '')]
                      : owned.map((v) {
                          // ابحث عن الخط
                          String lineName = '—';
                          for (int i = 0; i < globalVehicles.length; i++) {
                            if (globalVehicles[i].any((x) => x.vehicleId == v.vehicleId)) {
                              lineName = globalLines.length > i ? globalLines[i].name : '—';
                              break;
                            }
                          }
                          return _URow(
                            'رقم: ${v.vehicleId}  |  خط: $lineName',
                            '',
                            badge: _statusBadge(v.status),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                ]);
              }),

              // ── مركبة السائق ────────────────────────────
              if (u.role == 'سائق') Builder(builder: (ctx) {
                LineVehicle? driven;
                String driverLineName = '—';
                outer:
                for (int i = 0; i < globalVehicles.length; i++) {
                  for (final v in globalVehicles[i]) {
                    if (v.ownerName == u.name) {
                      driven = v;
                      driverLineName = globalLines.length > i ? globalLines[i].name : '—';
                      break outer;
                    }
                  }
                }
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _UInfoCard(
                    icon: Icons.drive_eta_outlined,
                    title: 'السيارة المُقادة',
                    accentColor: const Color(0xFF4B9EFF),
                    rows: driven == null
                      ? [const _URow('لا توجد سيارة مرتبطة بهذا السائق', '')]
                      : [
                          _URow('رقم السيارة',  driven.vehicleId),
                          _URow('اسم المالك',   driven.ownerName),
                          _URow('الخط',         driverLineName),
                          _URow('الحالة',       driven.status, badge: _statusBadge(driven.status)),
                        ],
                  ),
                  const SizedBox(height: 12),
                ]);
              }),

              // ── السجل التاريخي ─────────────────
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text('السجل التاريخي',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _roleColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.history_rounded, size: 13, color: _roleColor),
                    const SizedBox(width: 4),
                    Text('${_history.length} أحداث',
                        style: TextStyle(fontSize: 11, color: _roleColor, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),

              // Timeline cards
              ..._history.asMap().entries.map((entry) {
                final i      = entry.key;
                final h      = entry.value;
                final type   = h['type'] ?? 'default';
                final isLast = i == _history.length - 1;

                // لون وأيقونة حسب النوع
                final Color evColor;
                final IconData evIcon;
                switch (type) {
                  case 'create':   evColor = const Color(0xFF00C897); evIcon = Icons.person_add_alt_1_rounded; break;
                  case 'vehicle':  evColor = const Color(0xFF4B9EFF); evIcon = Icons.directions_car_rounded;   break;
                  case 'contract': evColor = const Color(0xFFB47AFF); evIcon = Icons.handshake_outlined;       break;
                  case 'warning':  evColor = const Color(0xFFFFB347); evIcon = Icons.warning_amber_rounded;    break;
                  case 'remove':   evColor = const Color(0xFFFF5A5F); evIcon = Icons.link_off_rounded;         break;
                  default:         evColor = const Color(0xFF8A93A8); evIcon = Icons.radio_button_checked;
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── عمود الخط والنقطة
                    SizedBox(
                      width: 48,
                      child: Column(children: [
                        const SizedBox(height: 10),
                        // النقطة الدائرية المضيئة
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: evColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: evColor.withValues(alpha: 0.35), width: 1.5),
                          ),
                          child: Icon(evIcon, size: 17, color: evColor),
                        ),
                        // خط رابط
                        if (!isLast)
                          Container(
                            width: 2, height: 28,
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                colors: [evColor.withValues(alpha: 0.4), Colors.transparent],
                              ),
                            ),
                          ),
                      ]),
                    ),
                    const SizedBox(width: 10),

                    // ── بطاقة الحدث
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: evColor.withValues(alpha: 0.18)),
                            boxShadow: [
                              BoxShadow(
                                color: evColor.withValues(alpha: 0.07),
                                blurRadius: 8, offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h['event']!,
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                    )),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Icon(Icons.calendar_today_outlined,
                                      size: 11, color: context.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(h['date']!,
                                      style: TextStyle(fontSize: 11, color: context.textSecondary)),
                                ]),
                              ],
                            )),
                            // رقم الحدث
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: evColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text('${i + 1}',
                                    style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.bold, color: evColor,
                                    )),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 32),
            ])),
          ),
        ]),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final Color c;
    switch (status) {
      case 'جاهزة':   c = const Color(0xFF00C897); break;
      case 'في الخط': c = const Color(0xFF4B9EFF); break;
      case 'محظورة':  c = const Color(0xFFFF5A5F); break;
      default:         c = const Color(0xFFFFB347);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c)),
    );
  }

  Widget? _licenseBadge(UserModel u) {
    if (u.licenseExpiry.isEmpty) return null;
    DateTime? expDate;
    try { expDate = DateTime.parse(u.licenseExpiry); } catch (_) {}
    if (expDate == null) return null;
    final isExpired = expDate.isBefore(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isExpired ? const Color(0xFFFF5A5F).withValues(alpha: 0.12) : const Color(0xFF00C897).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(isExpired ? 'منتهية!' : 'سارية', style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.bold,
        color: isExpired ? const Color(0xFFFF5A5F) : const Color(0xFF00C897),
      )),
    );
  }
}

// ── Card widget للمستخدم ─────────────────────
class _UInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final List<_URow> rows;
  const _UInfoCard({required this.icon, required this.title, required this.accentColor, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
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
              decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: accentColor),
            ),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: accentColor)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(children: rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            final row = e.value;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text('• ', style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.bold)),
                Expanded(child: RichText(
                  textDirection: TextDirection.rtl,
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, fontFamily: 'Tajawal', color: context.textPrimary),
                    children: [
                      TextSpan(text: '${row.label} : ', style: const TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: row.value, style: TextStyle(color: context.textSecondary)),
                    ],
                  ),
                )),
                if (row.badge != null) ...[const SizedBox(width: 8), row.badge!],
              ]),
            );
          }).toList()),
        ),
      ]),
    );
  }
}

class _URow {
  final String label, value;
  final Widget? badge;
  const _URow(this.label, this.value, {this.badge});
}