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
        status: L.get('unknown'), ownerName: widget.ownerName);
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
    if (_lv.driverName.isEmpty) return null;
    try {
      return globalUsers.firstWhere((u) => u.name == _lv.driverName && u.role == 'سائق');
    } catch (_) {
      return null;
    }
  }

  UserModel? get _owner {
    try { return globalUsers.firstWhere((u) => u.name == (_lv.ownerName) && u.role == 'مالك سيارة'); }
    catch (_) { return null; }
  }

  List<EventItem> get _events =>
      globalEvents.where((e) => e.vehicleId == _lv.vehicleId).toList().reversed.take(10).toList();

  Color get _statusColor {
    switch (_lv.status) {
      case 'جاهزة':    return const Color(0xFF00C897);
      case 'في الخط':  return const Color(0xFF4B9EFF);
      case 'محظورة':   return const Color(0xFFFF5A5F);
      default:          return const Color(0xFFFFB347);
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
            decoration: pw.BoxDecoration(color: PdfColors.blueGrey800, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(L.get('vehicle_info'), style: ar(size: 18, w: pw.FontWeight.bold, color: PdfColors.white)),
              pw.SizedBox(height: 4),
              pw.Text(L.get('station_name'), style: ar(size: 12, color: PdfColors.grey300)),
            ]),
          ),
          pw.SizedBox(height: 20),

          pw.Text(L.get('vehicle_info'), style: ar(size: 14, w: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1)},
            children: [
              tRow(L.get('plate_number'), lv.vehicleId),
              tRow(L.get('status'), lv.status),
              tRow(L.get('owner_name'), lv.ownerName.isNotEmpty ? lv.ownerName : '—'),
              tRow(L.get('line_name'), line.name.replaceAll('→', '-')),
            ],
          ),
          pw.SizedBox(height: 16),

          if (owner != null) ...[
            pw.Text(L.get('owner_info'), style: ar(size: 14, w: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1)},
              children: [
                tRow(L.get('full_name'), owner.name),
                tRow(L.get('id_number'), owner.idNumber.isNotEmpty ? owner.idNumber : '—'),
                tRow(L.get('phone'), owner.phone.isNotEmpty ? owner.phone : '—'),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          pw.Text(L.get('operating_license'), style: ar(size: 14, w: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1)},
            children: [
              tRow(L.get('op_lic_num'), lv.operatingLicNum.isNotEmpty ? lv.operatingLicNum : '—'),
              tRow(L.get('lic_exp'), lv.carLicExpiry.isNotEmpty ? lv.carLicExpiry : '—'),
              tRow(L.get('insurance_exp'), lv.insuranceExpiry.isNotEmpty ? lv.insuranceExpiry : '—'),
              tRow(L.get('loading_exp'), lv.loadingExpiry.isNotEmpty ? lv.loadingExpiry : '—'),
            ],
          ),

          pw.Spacer(),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 4),
          pw.Text(L.get('app_title'), style: ar(size: 9, color: PdfColors.grey500)),
        ]),
      ));

      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/vehicle_${lv.vehicleId}.pdf');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${L.get('error')}: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lv   = _lv;
    final line = _line;
    final carNum   = lv.vehicleId;
    final opLicNum = lv.operatingLicNum.isNotEmpty ? lv.operatingLicNum : '—';

    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
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
                  tooltip: L.get('print'),
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
                            Text(L.get('plate_number'), style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                            Text(carNum, style: const TextStyle(
                                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold,
                                letterSpacing: 2)),
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
                  title: L.get('driver'),
                  accentColor: const Color(0xFF4B9EFF),
                  rows: [
                    _Row(L.get('full_name'),      lv.driverName.isNotEmpty ? lv.driverName : L.get('no_driver')),
                    _Row(L.get('id_number'),       _driver?.idNumber   ?? '—'),
                    _Row(L.get('phone'),           _driver?.phone      ?? '—'),
                    _Row(L.get('license_num'),     _driver?.licenseNum ?? '—'),
                    _Row(L.get('license_grade'),   _driver?.licenseGrade.isNotEmpty == true ? _driver!.licenseGrade : '—'),
                  ],
                ),
                const SizedBox(height: 12),

                _VInfoCard(
                  icon: Icons.directions_car_outlined,
                  title: L.get('vehicle_info'),
                  accentColor: const Color(0xFF00C897),
                  rows: [
                    _Row(L.get('plate_number'),  lv.vehicleId),
                    _Row(L.get('rfid_tag'),      lv.rfidTag.isNotEmpty ? lv.rfidTag : '—'),
                    _Row(L.get('manufacturer'),  lv.maker.isNotEmpty ? lv.maker : '—'),
                    _Row(L.get('model'),         lv.model.isNotEmpty ? lv.model : '—'),
                    _Row(L.get('year'),          lv.year.isNotEmpty ? lv.year : '—'),
                    _Row(L.get('chassis'),       lv.chassis.isNotEmpty ? lv.chassis : '—'),
                    _Row(L.get('main_station'),  lv.mainStation.isNotEmpty ? lv.mainStation : '—'),
                    if (lv.subStation.isNotEmpty)
                      _Row(L.get('sub_station'), lv.subStation),
                  ],
                ),
                const SizedBox(height: 12),

                _VInfoCard(
                  icon: Icons.verified_outlined,
                  title: L.get('operating_license'),
                  accentColor: const Color(0xFFFFB347),
                  rows: [
                    _Row(L.get('op_lic_num'),    lv.operatingLicNum.isNotEmpty ? lv.operatingLicNum : opLicNum),
                    _Row(L.get('op_lic_exp'),    lv.operatingLicDate.isNotEmpty ? lv.operatingLicDate : '—'),
                    _Row(L.get('lic_exp'),       lv.carLicExpiry.isNotEmpty ? lv.carLicExpiry : '—',
                        badge: expiryBadge(L.get('lic_exp'), lv.carLicExpiry.isNotEmpty ? lv.carLicExpiry : '—')),
                    _Row(L.get('insurance_exp'), lv.insuranceExpiry.isNotEmpty ? lv.insuranceExpiry : '—',
                        badge: expiryBadge(L.get('insurance_exp'), lv.insuranceExpiry.isNotEmpty ? lv.insuranceExpiry : '—')),
                    _Row(L.get('loading_exp'),   lv.loadingExpiry.isNotEmpty ? lv.loadingExpiry : '—',
                        badge: expiryBadge(L.get('loading_exp'), lv.loadingExpiry)),
                  ],
                ),
                const SizedBox(height: 12),

                _VInfoCard(
                  icon: Icons.badge_outlined,
                  title: L.get('owner_info'),
                  accentColor: const Color(0xFFB47AFF),
                  rows: [
                    _Row(L.get('owner_name'),  lv.ownerName.isNotEmpty ? lv.ownerName : '—'),
                    _Row(L.get('owner_phone'), lv.ownerPhone.isNotEmpty ? lv.ownerPhone : '—'),
                    _Row(L.get('owner_id'),    lv.ownerId.isNotEmpty ? lv.ownerId : '—'),
                  ],
                ),
                const SizedBox(height: 12),

                _VInfoCard(
                  icon: Icons.route_outlined,
                  title: L.get('line_info'),
                  accentColor: const Color(0xFFFF5A5F),
                  rows: [
                    _Row(L.get('line_name'),    line.name),
                    _Row(L.get('line_number'),  line.gateId.isNotEmpty ? line.gateId : '—'),
                    _Row(L.get('station_name'), L.get('station_name')),
                    _Row(L.get('entry_gate'), () {
                      if (line.entryGateId.isEmpty) return '—';
                      final gate = globalGates.cast<GateModel?>().firstWhere(
                        (g) => g?.id == line.entryGateId,
                        orElse: () => null,
                      );
                      return gate?.label ?? line.entryGateId;
                    }()),
                    _Row(L.get('exit_gate'), () {
                      if (line.exitGateId.isEmpty) return '—';
                      final gate = globalGates.cast<GateModel?>().firstWhere(
                        (g) => g?.id == line.exitGateId,
                        orElse: () => null,
                      );
                      return gate?.label ?? line.exitGateId;
                    }()),
                  ],
                ),

                if (_events.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(L.get('event_stats'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                    ),
                    child: Column(children: _events.asMap().entries.map((e) {
                      final ev = e.value;
                      final isLast = e.key == _events.length - 1;
                      final evColor = ev.type == EventType.entry   ? const Color(0xFF00C897)
                                    : ev.type == EventType.exit    ? const Color(0xFF4B9EFF)
                                    : const Color(0xFFFF5A5F);
                      final evIcon  = ev.type == EventType.entry   ? Icons.login_rounded
                                    : ev.type == EventType.exit    ? Icons.logout_rounded
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
                                ? '${L.get('violation')}: ${ev.violationNote ?? ""}'
                                : '${ev.type == EventType.entry ? L.get('entry') : L.get('exit')} — ${ev.location}',
                            style: TextStyle(fontSize: 13, color: context.textPrimary),
                          )),
                          Text(ev.time, style: TextStyle(fontSize: 10, color: context.textSecondary)),
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

class _VInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final List<_Row> rows;
  const _VInfoCard({required this.icon, required this.title, required this.accentColor, required this.rows});

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
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
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
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('• ', style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.bold)),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                      text: TextSpan(
                        style: TextStyle(fontSize: 13, fontFamily: 'Tajawal', color: context.textPrimary),
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