part of station_app;

class ViolationsPage extends StatefulWidget {
  const ViolationsPage({super.key});
  @override
  State<ViolationsPage> createState() => _ViolationsPageState();
}

class _ViolationsPageState extends State<ViolationsPage>
    with DarkModeRebuild<ViolationsPage>, SearchFilterMixin<Map<String, String>> {
  final _searchCtrl = TextEditingController();

  @override List<String> get filterOptions => [L.get('all'), L.get('fees_paid'), L.get('fees_unpaid'), L.get('banned')];

  @override
  bool itemMatchesSearch(Map<String, String> v, String q) {
    final lq = q.toLowerCase();
    return v['name']!.contains(lq) ||
           v['vehicle']!.toLowerCase().contains(lq) ||
           v['id']!.toLowerCase().contains(lq) ||
           v['owner']!.contains(lq);
  }

  @override
  bool itemMatchesFilter(Map<String, String> v, String f) {
    if (f == L.get('banned')) {
      for (final list in globalVehicles) {
        for (final lv in list) {
          if (lv.vehicleId == v['vehicle'] && lv.status == 'محظورة') return true;
        }
      }
      return false;
    }
    if (f == L.get('all')) return v['status'] != 'تم التعامل معها';
    if (f == L.get('fees_paid'))   return v['status'] == 'تم التعامل معها';
    if (f == L.get('fees_unpaid')) return v['status'] == 'لم يتم التعامل معها';
    return v['status'] == f;
  }

  List<Map<String, String>> get _violations {
    final result = <Map<String, String>>[];
    for (int i = 0; i < globalEvents.length; i++) {
      final e = globalEvents[i];
      if (e.type != EventType.violation) continue;
      final num = result.length + 1;
      final note = e.violationNote ?? '';
      final amtMatch = RegExp(r'(\d+)\s*₪').firstMatch(note);
      result.add({
        'id': "V-${num.toString().padLeft(4, '0')}",
        'name': e.location,
        'vehicle': e.vehicleId,
        'owner': '',
        'status': e.feesPaid == true ? 'تم التعامل معها' : 'لم يتم التعامل معها',
        'amount': amtMatch?.group(1) ?? '0',
        'date': e.time,
        '_idx': i.toString(),
      });
    }
    return result;
  }

  void _togglePayment(int eventIdx) {
    setState(() {
      final e = globalEvents[eventIdx];
      globalEvents[eventIdx] = e.copyWith(feesPaid: !(e.feesPaid ?? false));
      autoSave();
    });
  }

  List<Map<String, String>> get _filtered {
    final all = _violations;
    if (activeFilter == L.get('all')) return all.where((v) => v['status'] != 'تم التعامل معها').toList();
    if (activeFilter == L.get('banned')) return all.where((v) => itemMatchesFilter(v, L.get('banned'))).toList();
    if (activeFilter == L.get('fees_paid'))   return all.where((v) => v['status'] == 'تم التعامل معها').toList();
    if (activeFilter == L.get('fees_unpaid')) return all.where((v) => v['status'] == 'لم يتم التعامل معها').toList();
    return all;
  }

  Future<void> _printViolations(BuildContext context, List<Map<String, String>> items) async {
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

      pw.TextStyle ar({double size = 11, pw.FontWeight w = pw.FontWeight.normal, PdfColor? color}) {
        var s = pw.TextStyle(fontSize: size, fontWeight: w, color: color);
        if (arabicFont != null) s = s.copyWith(font: arabicFont);
        return s;
      }

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(color: PdfColors.blueGrey800, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(L.get('violation_report'), style: ar(size: 16, w: pw.FontWeight.bold, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text(L.get('station_name'), style: ar(size: 11, color: PdfColors.grey300)),
            ]),
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(L.get('complaint_number'), textDirection: pw.TextDirection.rtl, style: ar(w: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(L.get('complaint_type'), textDirection: pw.TextDirection.rtl, style: ar(w: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(L.get('vehicle'), textDirection: pw.TextDirection.rtl, style: ar(w: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(L.get('violation_amount'), textDirection: pw.TextDirection.rtl, style: ar(w: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(L.get('status'), textDirection: pw.TextDirection.rtl, style: ar(w: pw.FontWeight.bold))),
                ],
              ),
              ...items.map((v) => pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(v['id'] ?? '', textDirection: pw.TextDirection.rtl, style: ar())),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(v['name'] ?? '', textDirection: pw.TextDirection.rtl, style: ar())),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(v['vehicle'] ?? '', textDirection: pw.TextDirection.ltr, style: ar())),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(v['amount'] ?? '—', textDirection: pw.TextDirection.rtl, style: ar())),
                pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(v['status'] ?? '', textDirection: pw.TextDirection.rtl, style: ar(color: v['status'] == 'تم التعامل معها' ? PdfColors.green700 : PdfColors.red700))),
              ])),
            ],
          ),
          pw.Spacer(),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 4),
          pw.Text('${items.length} ${L.get('violations')}   |   ${L.get('fees_paid')}: ${items.where((v) => v['status'] == 'تم التعامل معها').length}   |   ${L.get('fees_unpaid')}: ${items.where((v) => v['status'] != 'تم التعامل معها').length}',
              textDirection: pw.TextDirection.rtl, style: ar(size: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(L.get('app_title'), style: ar(size: 9, color: PdfColors.grey500)),
        ]),
      ));

      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/violations.pdf');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${L.get('error')}: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    final banned = <(LineVehicle, int, int)>[];
    for (int li = 0; li < globalLines.length; li++) {
      for (int vi = 0; vi < globalVehicles[li].length; vi++) {
        if (globalVehicles[li][vi].status == 'محظورة') {
          banned.add((globalVehicles[li][vi], li, vi));
        }
      }
    }

    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          color: const Color(0xFF2D3A5C),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(L.get('violations'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            Row(children: [
              _Tap(
                onTap: () => _printViolations(context, items),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    const Icon(Icons.print_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(L.get('print'), style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ]),
                ),
              ),
            ]),
          ]),
        ),

        Container(
          color: context.cardColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: filterOptions.map((f) {
              final sel = f == activeFilter;
              Color accent = const Color(0xFF2D3A5C);
              if (f == L.get('banned'))      accent = const Color(0xFFFF5A5F);
              else if (f == L.get('fees_paid')) accent = const Color(0xFF00C897);
              return _Tap(
                onTap: () => setState(() { activeFilter = f; }),
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? accent : context.bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? accent : context.dividerColor),
                  ),
                  child: Text(f, style: TextStyle(
                      color: sel ? Colors.white : context.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
        ),

        Expanded(child: activeFilter == L.get('banned')
          ? (banned.isEmpty
            ? Center(child: Text(L.get('no_violations'), style: TextStyle(color: Colors.grey[400], fontSize: 15)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: banned.length,
                itemBuilder: (_, idx) {
                  final (lv, li, vi) = banned[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF5A5F).withValues(alpha: 0.3)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFFF5A5F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.directions_car_outlined, color: Color(0xFFFF5A5F), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(lv.vehicleId, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                        if (lv.ownerName.isNotEmpty) Text(lv.ownerName, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                        if (lv.note != null && lv.note!.isNotEmpty)
                          Text('${L.get('note')}: ${lv.note}', style: const TextStyle(fontSize: 11, color: Color(0xFFFF5A5F))),
                      ])),
                      _Tap(
                        onTap: () {
                          final reasonCtrl = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (_) => StatefulBuilder(
                              builder: (ctx, setDlg) => Directionality(
                                textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                                child: AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Row(children: [
                                    const Icon(Icons.lock_open_rounded, color: Color(0xFF00C897), size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('${L.get('lift_ban')} ${lv.vehicleId}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00C897)))),
                                  ]),
                                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                                    if (lv.note != null && lv.note!.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        margin: const EdgeInsets.only(bottom: 10),
                                        decoration: BoxDecoration(color: const Color(0xFFFF5A5F).withValues(alpha: 0.07), borderRadius: BorderRadius.circular(8)),
                                        child: Row(children: [
                                          const Icon(Icons.info_outline, size: 14, color: Color(0xFFFF5A5F)),
                                          const SizedBox(width: 6),
                                          Expanded(child: Text('${L.get('note')}: ${lv.note}', style: const TextStyle(fontSize: 12, color: Color(0xFFFF5A5F)))),
                                        ]),
                                      ),
                                    ],
                                    Text(L.get('notes'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: reasonCtrl,
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        hintText: L.get('additional_notes'),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E4EE))),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00C897))),
                                      ),
                                    ),
                                  ]),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: Text(L.get('cancel'), style: TextStyle(color: ctx.textSecondary))),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C897), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                      onPressed: () {
                                        final old = globalVehicles[li][vi];
                                        globalVehicles[li][vi] = LineVehicle(
                                          number: old.number, vehicleId: old.vehicleId,
                                          status: 'في الانتظار',
                                          note: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
                                          ownerName: old.ownerName, carLicExpiry: old.carLicExpiry,
                                          insuranceExpiry: old.insuranceExpiry, operatingLicNum: old.operatingLicNum,
                                          operatingLicDate: old.operatingLicDate, rfidTag: old.rfidTag, loadingExpiry: old.loadingExpiry,
                                        );
                                        logEvent(EventItem(
                                          vehicleId: lv.vehicleId,
                                          location: L.get('ban_lifted'),
                                          time: nowTime(),
                                          type: EventType.exit,
                                          violationNote: reasonCtrl.text.trim().isNotEmpty
                                              ? '${L.get('ban_lifted')}: ${reasonCtrl.text.trim()}'
                                              : L.get('ban_lifted'),
                                        ));
                                        autoSave(); setState(() {}); Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text('${L.get('ban_lifted_for')} ${lv.vehicleId}',
                                              textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr),
                                          backgroundColor: const Color(0xFF00C897),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          margin: const EdgeInsets.all(16),
                                        ));
                                      },
                                      child: Text(L.get('lift_ban'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFF00C897).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00C897).withValues(alpha: 0.3))),
                          child: Text(L.get('lift_ban'), style: const TextStyle(fontSize: 12, color: Color(0xFF00C897), fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]),
                  );
                },
              ))
          : (items.isEmpty
            ? Center(child: Text(L.get('no_violations'), style: TextStyle(color: Colors.grey[400], fontSize: 15)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final v = items[i];
                  final isPaid = v['status'] == 'تم التعامل معها';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(v['name']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.tag, size: 14, color: context.textSecondary),
                        const SizedBox(width: 4),
                        Text(v['id']!, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                        const SizedBox(width: 16),
                        Icon(Icons.directions_car_outlined, size: 14, color: context.textSecondary),
                        const SizedBox(width: 4),
                        Text(v['vehicle']!, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                      ]),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(v['date']!, style: TextStyle(fontSize: 11, color: context.textSecondary)),
                        _Tap(
                          onTap: () {
                            final idx = int.tryParse(v['_idx'] ?? '') ?? -1;
                            if (idx >= 0) _togglePayment(idx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isPaid ? const Color(0xFF00C897) : const Color(0xFFC62828),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isPaid ? '✓ ${L.get('fees_paid')}' : L.get('fees_unpaid'),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ]),
                    ]),
                  );
                },
              )),
        ),
      ]),
    );
  }
}