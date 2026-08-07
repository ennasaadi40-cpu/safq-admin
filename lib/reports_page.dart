part of station_app;

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with DarkModeRebuild<ReportsPage> {
  String? _dateFrom;
  String? _dateTo;

  int get _totalVehicles   => globalVehicles.fold(0, (s, l) => s + l.length);
  int get _totalLines      => globalLines.length;
  int get _totalUsers      => globalUsers.length;
  int get _activeUsers     => globalUsers.where((u) => u.status == 'نشط').length;
  int get _violations      => globalVehicles.fold(0, (s, l) => s + l.where((v) => v.status == 'مخالفة').length);
  int get _totalEvents     => globalEvents.length;

  Widget _statRow(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: context.textPrimary))),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 6),
    child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimary)),
  );

  Future<void> _printPdf(BuildContext ctx) async {
    try {
      final pdf = await _buildPdf();
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'station_report.pdf',
      );
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('${L.get('error')}: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _downloadPdf(BuildContext ctx) async {
    try {
      final pdf = await _buildPdf();
      final bytes = await pdf.save();
      final now = DateTime.now();
      final name = 'station_report_${now.year}${now.month.toString().padLeft(2,"0")}${now.day.toString().padLeft(2,"0")}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: name);
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('${L.get('error')}: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<pw.Document> _buildPdf() async {
    final now = DateTime.now();
    final dateStr = '${now.year}/${now.month.toString().padLeft(2,"0")}/${now.day.toString().padLeft(2,"0")}';

    pw.Font? arabicFont;
    pw.Font? arabicBoldFont;

    try {
      arabicFont     = pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
      arabicBoldFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Bold.ttf'));
    } catch (_) {
      try {
        final loader = FontLoader('Tajawal')
          ..addFont(rootBundle.load('assets/fonts/Tajawal-Regular.ttf').catchError((_) async {
            final r = await http.get(Uri.parse(
              'https://fonts.gstatic.com/s/tajawal/v9/Iurf6YBj_oCad4k1nzSBC45I.ttf'));
            return r.bodyBytes.buffer.asByteData();
          }));
        await loader.load();
      } catch (_) {}
      try {
        final r = await http.get(Uri.parse(
          'https://fonts.gstatic.com/s/cairo/v28/SLXVc1nY6HkvangtZmpcWmhzfH5lkSs2SgRjCAGMQ1z0hGA.ttf',
        )).timeout(const Duration(seconds: 12));
        if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) {
          arabicFont     = pw.Font.ttf(r.bodyBytes.buffer.asByteData());
          arabicBoldFont = arabicFont;
        }
      } catch (_) {}
    }

    final theme = arabicFont != null
        ? pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicBoldFont ?? arabicFont,
          )
        : pw.ThemeData.base();

    pw.TextStyle arStyle({
      double fontSize = 11,
      pw.FontWeight fontWeight = pw.FontWeight.normal,
      PdfColor? color,
    }) {
      final base = pw.TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color);
      return arabicFont != null
          ? base.copyWith(font: fontWeight == pw.FontWeight.bold ? (arabicBoldFont ?? arabicFont) : arabicFont)
          : base;
    }

    final pdf = pw.Document(theme: theme);

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: L.isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context c) => [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.blueGrey800,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text(L.get('app_subtitle'),
                style: arStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            pw.SizedBox(height: 4),
            pw.Text(L.get('station_name'),
                style: arStyle(fontSize: 13, color: PdfColors.white)),
            pw.SizedBox(height: 4),
            pw.Text('${L.get('date')}: $dateStr',
                style: arStyle(fontSize: 10, color: PdfColors.grey300)),
          ]),
        ),
        pw.SizedBox(height: 20),

        pw.Text(L.get('event_stats'),
            style: arStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            _pdfTRow(L.get('details'), L.get('amount'), header: true, font: arabicFont, boldFont: arabicBoldFont),
            _pdfTRow(L.get('total_vehicles'),    '$_totalVehicles', font: arabicFont, boldFont: arabicBoldFont),
            _pdfTRow(L.get('lines_title'),       '$_totalLines',    font: arabicFont, boldFont: arabicBoldFont),
            _pdfTRow(L.get('users'),             '$_totalUsers',    font: arabicFont, boldFont: arabicBoldFont),
            _pdfTRow(L.get('active'),            '$_activeUsers',   font: arabicFont, boldFont: arabicBoldFont),
            _pdfTRow(L.get('violations'),        '$_violations',    font: arabicFont, boldFont: arabicBoldFont),
            _pdfTRow(L.get('no_events'),         '$_totalEvents',   font: arabicFont, boldFont: arabicBoldFont),
          ],
        ),
        pw.SizedBox(height: 16),

        pw.Text(L.get('users'),
            style: arStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            _pdfTRow(L.get('role'), L.get('amount'), header: true, font: arabicFont, boldFont: arabicBoldFont),
            ...['سائق', 'مالك سيارة', 'موظف أمن', 'مشرف خط'].map((r) =>
                _pdfTRow(r, '${globalUsers.where((u) => u.role == r).length}',
                    font: arabicFont, boldFont: arabicBoldFont)),
          ],
        ),
        pw.SizedBox(height: 16),

        if (globalLines.isNotEmpty) ...[
          pw.Text('${L.get('lines_title')} & ${L.get('vehicles')}',
              style: arStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              _pdfTRow(L.get('line_name'), L.get('vehicle_count'), header: true, font: arabicFont, boldFont: arabicBoldFont),
              ...List.generate(globalLines.length, (i) =>
                  _pdfTRow(globalLines[i].name, '${globalVehicles[i].length}',
                      font: arabicFont, boldFont: arabicBoldFont)),
            ],
          ),
          pw.SizedBox(height: 16),
        ],

        if (globalEvents.where((e) => e.type == EventType.violation).isNotEmpty) ...[
          pw.Text(L.get('violation_report'),
              style: arStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              _pdfTRow(L.get('vehicle'), L.get('details'), header: true, font: arabicFont, boldFont: arabicBoldFont),
              ...globalEvents
                  .where((e) => e.type == EventType.violation)
                  .take(10)
                  .map((e) => _pdfTRow(e.vehicleId, e.violationNote ?? e.location,
                      font: arabicFont, boldFont: arabicBoldFont)),
            ],
          ),
          pw.SizedBox(height: 16),
        ],

        if (globalEvents.isNotEmpty) ...[
          pw.Text(L.get('no_events'),
              style: arStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              _pdfTRow(L.get('vehicle'), '${L.get('status')} — ${L.get('details')}', header: true, font: arabicFont, boldFont: arabicBoldFont),
              ...globalEvents.take(10).map((e) {
                final t = e.type == EventType.entry ? L.get('entry')
                        : e.type == EventType.exit  ? L.get('exit') : L.get('violation');
                return _pdfTRow(e.vehicleId, '$t — ${e.location}',
                    font: arabicFont, boldFont: arabicBoldFont);
              }),
            ],
          ),
        ],

        pw.SizedBox(height: 28),
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 6),
        pw.Text('${L.get('app_title')} — $dateStr',
            style: arStyle(fontSize: 9, color: PdfColors.grey500)),
      ],
    ));
    return pdf;
  }

  pw.TableRow _pdfTRow(String a, String b, {bool header = false, pw.Font? font, pw.Font? boldFont}) {
    final bg   = header ? PdfColors.blueGrey800 : PdfColors.white;
    final fg   = header ? PdfColors.white : PdfColors.black;
    final w    = header ? pw.FontWeight.bold : pw.FontWeight.normal;
    final usedFont = (w == pw.FontWeight.bold ? (boldFont ?? font) : font);
    pw.TextStyle style = pw.TextStyle(fontSize: 11, color: fg, fontWeight: w);
    if (usedFont != null) style = style.copyWith(font: usedFont);
    return pw.TableRow(decoration: pw.BoxDecoration(color: bg), children: [
      pw.Padding(padding: const pw.EdgeInsets.all(6),
          child: pw.Text(pdfSafe(a), textDirection: pdfDir(a), style: style)),
      pw.Padding(padding: const pw.EdgeInsets.all(6),
          child: pw.Text(pdfSafe(b), textDirection: pdfDir(b), style: style)),
    ]);
  }

  void _showPrintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3A5C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2D3A5C), size: 22),
            ),
            const SizedBox(width: 10),
            Text(L.get('export'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3A5C).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(children: [
                _pdfRow(L.get('total_vehicles'),    '$_totalVehicles'),
                _pdfRow(L.get('lines_title'),       '$_totalLines'),
                _pdfRow(L.get('active'),            '$_activeUsers / $_totalUsers'),
                _pdfRow(L.get('violations'),        '$_violations'),
                _pdfRow(L.get('event_stats'),       '$_totalEvents'),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _Tap(
                onTap: () {
                  Navigator.pop(context);
                  _printPdf(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3A5C).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2D3A5C).withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    const Icon(Icons.print_rounded, color: Color(0xFF2D3A5C), size: 24),
                    const SizedBox(height: 5),
                    Text(L.get('print'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: _Tap(
                onTap: () {
                  Navigator.pop(context);
                  _downloadPdf(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC62828).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC62828).withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    const Icon(Icons.download_rounded, color: Color(0xFFC62828), size: 24),
                    const SizedBox(height: 5),
                    Text(L.get('export'), style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
              )),
            ]),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L.get('close'), style: TextStyle(color: context.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pdfRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, color: context.textSecondary)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          color: const Color(0xFF2D3A5C),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(L.get('reports'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            Row(children: [
              _Tap(
                onTap: () => _downloadPdf(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC62828).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 5),
                    Text(L.get('export'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _DateFilterBar(
                dateFrom: _dateFrom,
                dateTo: _dateTo,
                onChanged: (f, t) => setState(() { _dateFrom = f; _dateTo = t; }),
              ),
              const SizedBox(height: 8),
              _sectionTitle('🚌 ${L.get('daily_report')}'),
              _DailyMovementReport(dateFrom: _dateFrom, dateTo: _dateTo),
              const SizedBox(height: 8),
              _sectionTitle('⚡ ${L.get('requests')}'),
              const _ExceptionOrdersSection(),
              const SizedBox(height: 8),
              _sectionTitle('📊 ${L.get('event_stats')}'),
              _statRow(L.get('total_vehicles'),  '$_totalVehicles', Icons.directions_car_outlined,  const Color(0xFF1565C0)),
              _statRow(L.get('lines_title'),     '$_totalLines',    Icons.route_outlined,            const Color(0xFF2E7D32)),
              _statRow(L.get('users'),           '$_totalUsers',    Icons.people_outline,            const Color(0xFF6A1B9A)),
              _statRow(L.get('active'),          '$_activeUsers',   Icons.person_outline,            const Color(0xFF00838F)),
              _statRow(L.get('violations'),      '$_violations',    Icons.warning_amber_outlined,    const Color(0xFFC62828)),
              _statRow(L.get('event_stats'),     '$_totalEvents',   Icons.history_outlined,          const Color(0xFFE65100)),
              const SizedBox(height: 8),
              _sectionTitle('📋 ${L.get('no_events')}'),
              if (globalEvents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(L.get('no_events'), style: TextStyle(color: context.textSecondary))),
                )
              else
                ...globalEvents.take(5).map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: e.type == EventType.violation ? Colors.red
                            : e.type == EventType.entry ? Colors.green : Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(e.vehicleId, style: TextStyle(fontSize: 13, color: context.textPrimary))),
                    Text(e.time, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                  ]),
                )),
              const SizedBox(height: 8),
              _sectionTitle('👥 ${L.get('users')}'),
              ...['سائق', 'مالك سيارة', 'موظف أمن', 'مشرف خط'].map((role) {
                final count = globalUsers.where((u) => u.role == role).length;
                final total = globalUsers.isEmpty ? 1 : globalUsers.length;
                final pct = (count / total * 100).round();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(role, style: TextStyle(fontSize: 13, color: context.textPrimary)),
                      Text('$count ($pct%)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3A5C))),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: count / total,
                        backgroundColor: context.dividerColor,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF2D3A5C)),
                        minHeight: 6,
                      ),
                    ),
                  ]),
                );
              }),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  _DailyMovementReport
// ─────────────────────────────────────────────
class _DailyMovementReport extends StatefulWidget {
  final String? dateFrom;
  final String? dateTo;
  const _DailyMovementReport({this.dateFrom, this.dateTo});
  @override
  State<_DailyMovementReport> createState() => _DailyMovementReportState();
}

class _DailyMovementReportState extends State<_DailyMovementReport> with DarkModeRebuild<_DailyMovementReport> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2,"0")}-${now.day.toString().padLeft(2,"0")}';
    final from = widget.dateFrom ?? todayStr;
    final to   = widget.dateTo   ?? todayStr;

    final exits = globalEvents.where((e) {
      if (e.type != EventType.exit) return false;
      final d = eventDate(e.time);
      return d.compareTo(from) >= 0 && d.compareTo(to) <= 0;
    }).toList();

    if (exits.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(L.get('no_events'), style: TextStyle(color: context.textSecondary))),
      );
    }

    return Column(children: exits.take(20).map((e) {
      final isException = [...globalOrders, ...globalDeliveryRequests].any((r) =>
          r.assignedVehicleId == e.vehicleId && r.status == RequestStatus.accepted);
      final color = isException ? const Color(0xFFFFB347) : const Color(0xFF00C897);
      final label = isException ? L.get('requests') : L.get('success');
      final icon  = isException ? Icons.star_outline_rounded : Icons.check_circle_outline;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.directions_car_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.vehicleId, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary)),
            Text(e.location, style: TextStyle(fontSize: 12, color: context.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 11, color: color),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 4),
            Text(e.time, style: TextStyle(fontSize: 10, color: context.textSecondary)),
          ]),
        ]),
      );
    }).toList());
  }
}

// ─────────────────────────────────────────────
//  _ExceptionOrdersSection
// ─────────────────────────────────────────────
class _ExceptionOrdersSection extends StatelessWidget {
  const _ExceptionOrdersSection();

  @override
  Widget build(BuildContext context) {
    final exceptions = [...globalOrders, ...globalDeliveryRequests].where((r) =>
        r.assignedVehicleId != null &&
        r.status == RequestStatus.accepted).toList();

    if (exceptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(L.get('no_data'), style: TextStyle(color: context.textSecondary))),
      );
    }

    return Column(children: exceptions.map((r) {
      final typeLabel = r.type == RequestType.parcel ? L.get('note') : L.get('users');
      final typeColor = r.type == RequestType.parcel ? const Color(0xFFB47AFF) : const Color(0xFF4B9EFF);

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB347).withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(typeLabel, style: TextStyle(fontSize: 11, color: typeColor, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFFFB347).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(L.get('requests'), style: const TextStyle(fontSize: 11, color: Color(0xFFFFB347), fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            Text(r.id, style: TextStyle(fontSize: 11, color: context.textSecondary)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.directions_car_outlined, size: 14, color: Color(0xFF2D3A5C)),
            const SizedBox(width: 6),
            Text(r.assignedVehicleId ?? '—', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
            if (r.assignedDriver != null) ...[
              const SizedBox(width: 8),
              Text('• ${r.assignedDriver}', style: TextStyle(fontSize: 12, color: context.textSecondary)),
            ],
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF00C897)),
            const SizedBox(width: 4),
            Text(r.location, style: TextStyle(fontSize: 12, color: context.textSecondary)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_back_rounded, size: 13, color: Color(0xFF8A93A8)),
            const SizedBox(width: 4),
            Text(r.destination, style: TextStyle(fontSize: 12, color: context.textSecondary)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF4B9EFF)),
            const SizedBox(width: 4),
            Text(r.contactPhone, style: TextStyle(fontSize: 12, color: context.textSecondary)),
          ]),
          if (r.assignedLine != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.route_outlined, size: 13, color: Color(0xFFFFB347)),
              const SizedBox(width: 4),
              Expanded(child: Text(r.assignedLine!, style: TextStyle(fontSize: 11, color: context.textSecondary), overflow: TextOverflow.ellipsis)),
            ]),
          ],
        ]),
      );
    }).toList());
  }
}

// ─────────────────────────────────────────────
//  _DateFilterBar
// ─────────────────────────────────────────────
class _DateFilterBar extends StatelessWidget {
  final String? dateFrom;
  final String? dateTo;
  final void Function(String? from, String? to) onChanged;
  const _DateFilterBar({required this.dateFrom, required this.dateTo, required this.onChanged});

  static String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2,"0")}-${now.day.toString().padLeft(2,"0")}';
  }

  static String _fmt(String? date) {
    if (date == null) return '—';
    try { final p = date.split('-'); return '${p[2]}/${p[1]}/${p[0]}'; } catch (_) { return date; }
  }

  @override
  Widget build(BuildContext context) {
    final td = _todayStr;
    final isToday = (dateFrom == null || dateFrom == td) && (dateTo == null || dateTo == td);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.date_range_outlined, size: 16, color: Color(0xFF2D3A5C)),
          const SizedBox(width: 6),
          Text(L.get('date'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
          const Spacer(),
          if (!isToday)
            _Tap(
              onTap: () => onChanged(null, null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFF5A5F).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(L.get('daily_report'), style: const TextStyle(fontSize: 11, color: Color(0xFFFF5A5F), fontWeight: FontWeight.bold)),
              ),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(L.get('from'), style: TextStyle(fontSize: 11, color: context.textSecondary)),
            const SizedBox(height: 4),
            _Tap(
              onTap: () async {
                final picked = await showDatePicker(context: context,
                    initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
                if (picked != null) {
                  final str = '${picked.year}-${picked.month.toString().padLeft(2,"0")}-${picked.day.toString().padLeft(2,"0")}';
                  onChanged(str, dateTo ?? str);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3A5C).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2D3A5C).withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF2D3A5C)),
                  const SizedBox(width: 6),
                  Text(_fmt(dateFrom ?? td), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary)),
                ]),
              ),
            ),
          ])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Icon(Icons.arrow_back_rounded, size: 16, color: context.textSecondary),
          ),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(L.get('to'), style: TextStyle(fontSize: 11, color: context.textSecondary)),
            const SizedBox(height: 4),
            _Tap(
              onTap: () async {
                final picked = await showDatePicker(context: context,
                    initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
                if (picked != null) {
                  final str = '${picked.year}-${picked.month.toString().padLeft(2,"0")}-${picked.day.toString().padLeft(2,"0")}';
                  onChanged(dateFrom ?? td, str);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3A5C).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2D3A5C).withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF2D3A5C)),
                  const SizedBox(width: 6),
                  Text(_fmt(dateTo ?? td), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary)),
                ]),
              ),
            ),
          ])),
        ]),
      ]),
    );
  }
}