part of station_app;

class VehiclesPage extends StatefulWidget {
  const VehiclesPage({super.key});
  @override
  State<VehiclesPage> createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> with DarkModeRebuild<VehiclesPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int? _expandedVehicleIdx;

  List<_VehicleEntry> get _allEntries {
    final result = <_VehicleEntry>[];
    for (int li = 0; li < globalLines.length; li++) {
      for (int vi = 0; vi < globalVehicles[li].length; vi++) {
        final v = globalVehicles[li][vi];
        if (_searchQuery.isEmpty ||
            v.vehicleId.contains(_searchQuery) ||
            v.ownerName.contains(_searchQuery) ||
            v.driverName.contains(_searchQuery)) {
          result.add(_VehicleEntry(lineIdx: li, vehIdx: vi, lv: v, lineName: globalLines[li].name));
        }
      }
    }
    return result;
  }

  void _showBulkLoadingDialog(BuildContext context) {
    final daysCtrl = TextEditingController();
    String? selectedLine;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => Directionality(
          textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.local_shipping_outlined, color: Color(0xFFFFB347), size: 22),
              const SizedBox(width: 8),
              Text(L.get('edit_loading_date'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Builder(builder: (ctx2) {
                final days = int.tryParse(daysCtrl.text.trim()) ?? 0;
                if (days <= 0) return const SizedBox.shrink();
                final newDate = DateTime.now().add(Duration(days: days));
                final newStr = '${newDate.year}-${newDate.month.toString().padLeft(2,'0')}-${newDate.day.toString().padLeft(2,'0')}';
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: const Color(0xFFFFB347).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFB347).withValues(alpha: 0.4))),
                  child: Row(children: [
                    const Icon(Icons.event_available_rounded, size: 16, color: Color(0xFFFFB347)),
                    const SizedBox(width: 8),
                    Text('$newStr ($days ${L.get('day_word')})', style: const TextStyle(fontSize: 12, color: Color(0xFFFFB347), fontWeight: FontWeight.bold)),
                  ]),
                );
              }),
              Text(L.get('line'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE0E4EE)), borderRadius: BorderRadius.circular(10), color: ctx.cardColor),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: selectedLine,
                    isExpanded: true,
                    hint: Text(L.get('all'), style: const TextStyle(fontSize: 13)),
                    items: [
                      DropdownMenuItem<String?>(value: null, child: Text(L.get('all'), style: const TextStyle(fontSize: 13))),
                      ...globalLines.map((l) => DropdownMenuItem<String?>(
                        value: l.name,
                        child: Text(l.name, style: TextStyle(fontSize: 13, color: ctx.textPrimary), overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (val) => setDlg(() => selectedLine = val),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(L.get('days'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: daysCtrl,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                onChanged: (_) => setDlg(() {}),
                decoration: InputDecoration(
                  hintText: '7',
                  prefixIcon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFFFFB347)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE0E4EE))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFFB347))),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [3, 7, 14, 30].map((d) => _Tap(
                onTap: () => setDlg(() => daysCtrl.text = '$d'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFFFB347).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFB347).withValues(alpha: 0.3))),
                  child: Text('+$d ${L.get('day_word')}', style: const TextStyle(fontSize: 11, color: Color(0xFFFFB347), fontWeight: FontWeight.bold)),
                ),
              )).toList()),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(L.get('cancel'), style: TextStyle(color: ctx.textSecondary))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB347), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: () {
                  final days = int.tryParse(daysCtrl.text.trim()) ?? 0;
                  if (days <= 0) return;
                  final newExpiry = DateTime.now().add(Duration(days: days));
                  final newStr = '${newExpiry.year}-${newExpiry.month.toString().padLeft(2,'0')}-${newExpiry.day.toString().padLeft(2,'0')}';
                  int updated = 0;
                  for (int li = 0; li < globalLines.length; li++) {
                    if (selectedLine != null && globalLines[li].name != selectedLine) continue;
                    for (int vi = 0; vi < globalVehicles[li].length; vi++) {
                      final old = globalVehicles[li][vi];
                      globalVehicles[li][vi] = LineVehicle(
                        number: old.number, vehicleId: old.vehicleId, status: old.status,
                        note: old.note, ownerName: old.ownerName, carLicExpiry: old.carLicExpiry,
                        insuranceExpiry: old.insuranceExpiry, operatingLicNum: old.operatingLicNum,
                        operatingLicDate: old.operatingLicDate, rfidTag: old.rfidTag,
                        loadingExpiry: newStr, maker: old.maker, model: old.model,
                        year: old.year, chassis: old.chassis, ownerPhone: old.ownerPhone,
                        ownerId: old.ownerId, driverName: old.driverName,
                      );
                      updated++;
                    }
                  }
                  autoSave();
                  if (mounted) setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${L.get('success')}: $updated ${L.get('vehicle')} — $newStr',
                        textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr),
                    backgroundColor: const Color(0xFFFFB347),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ));
                },
                child: Text(L.get('save'), style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _allEntries;
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          color: const Color(0xFF2D3A5C),
          child: Row(children: [
            Expanded(child: Text(L.get('vehicles'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
            _Tap(
              onTap: () => _showBulkLoadingDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: const Color(0xFFFFB347), borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(L.get('loading_exp'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            _Tap(
              onTap: () async {
                final added = await Navigator.push<bool>(context, MaterialPageRoute(
                  builder: (_) => _AddVehiclePage(lineName: '', onSave: (_, __, ___, ____, _____, ______, _______, {carLicExpiry = '', insuranceExpiry = '', newLineName}) {}),
                ));
                if (added == true) setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: const Color(0xFF00C897), borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(L.get('add'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
          ]),
        ),
        Expanded(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 5)]),
                  child: TextField(
                    controller: _searchCtrl,
                    textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    onChanged: (v) => setState(() { _searchQuery = v; _expandedVehicleIdx = null; }),
                    decoration: InputDecoration(
                      hintText: L.get('search_plate_owner'),
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: context.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: entries.isEmpty
                  ? Center(child: Text(L.get('no_vehicles_found'), style: TextStyle(color: Colors.grey[400], fontSize: 15)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: entries.length,
                      itemBuilder: (_, idx) {
                        final e = entries[idx];
                        final lv = e.lv;
                        final isExpanded = _expandedVehicleIdx == idx;

                        int daysLeft = -999;
                        bool hasExpiry = lv.loadingExpiry.isNotEmpty;
                        if (hasExpiry) {
                          try {
                            final p = lv.loadingExpiry.split('-');
                            final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
                            daysLeft = d.difference(DateTime.now()).inDays;
                          } catch (_) {}
                        }
                        final loadColor = !hasExpiry ? const Color(0xFF8A93A8)
                          : daysLeft < 0 ? const Color(0xFFFF5A5F)
                          : daysLeft <= 3 ? const Color(0xFFFFB347)
                          : const Color(0xFF00C897);

                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (idx == 0 || entries[idx - 1].lineIdx != e.lineIdx) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 6),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFF2D3A5C), borderRadius: BorderRadius.circular(8)),
                                  child: Text(e.lineName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                ),
                              ]),
                            ),
                          ],
                          _Tap(
                            onTap: () => setState(() => _expandedVehicleIdx = isExpanded ? null : idx),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 5)]),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(color: const Color(0xFF2D3A5C).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                                    child: Center(child: Text('${lv.number}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(lv.vehicleId, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(lv.driverName.isNotEmpty ? lv.driverName : L.get('no_driver'), style: TextStyle(fontSize: 12, color: context.textSecondary)),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      Icon(Icons.local_shipping_outlined, size: 12, color: loadColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        !hasExpiry ? L.get('loading_not_set')
                                          : daysLeft < 0 ? '${L.get('expired_days_ago')} ${daysLeft.abs()} ${L.get('day_word')}'
                                          : daysLeft == 0 ? L.get('expires_today')
                                          : '${L.get('days_left')} $daysLeft ${L.get('day_word')}',
                                        style: TextStyle(fontSize: 11, color: loadColor, fontWeight: FontWeight.w600),
                                      ),
                                    ]),
                                  ])),
                                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: context.textSecondary, size: 20),
                                ]),
                              ),
                            ),
                          ),
                          if (isExpanded)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(color: context.cardColor, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)), border: Border(top: BorderSide(color: context.dividerColor))),
                              child: Column(children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    _DetailRow(L.get('lic_exp'), lv.carLicExpiry.isNotEmpty ? lv.carLicExpiry : '—', context),
                                    const SizedBox(height: 4),
                                    _DetailRow(L.get('insurance_exp'), lv.insuranceExpiry.isNotEmpty ? lv.insuranceExpiry : '—', context),
                                    const SizedBox(height: 4),
                                    _DetailRow(L.get('op_lic_exp'), lv.operatingLicDate.isNotEmpty ? lv.operatingLicDate : '—', context),
                                  ]),
                                ),
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Row(children: [
                                    Expanded(child: _Tap(
                                      onTap: () {
                                        final ctrl = TextEditingController(text: lv.loadingExpiry);
                                        showDialog(
                                          context: context,
                                          builder: (_) => StatefulBuilder(
                                            builder: (ctx, setDlg) => Directionality(
                                              textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                                              child: AlertDialog(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                                title: Text('${L.get('edit_loading_date')} — ${lv.vehicleId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                content: Column(mainAxisSize: MainAxisSize.min, children: [
                                                  GestureDetector(
                                                    onTap: () async {
                                                      final picked = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2035));
                                                      if (picked != null) { ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2,"0")}-${picked.day.toString().padLeft(2,"0")}'; setDlg(() {}); }
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE0E4EE)), borderRadius: BorderRadius.circular(10)),
                                                      child: Row(children: [
                                                        const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF2D3A5C)),
                                                        const SizedBox(width: 8),
                                                        Text(ctrl.text.isEmpty ? L.get('tap_to_select_date') : ctrl.text, style: TextStyle(fontSize: 13, color: ctrl.text.isEmpty ? Colors.grey : ctx.textPrimary)),
                                                      ]),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Wrap(spacing: 6, children: [1, 3, 7, 14, 30].map((days) => _Tap(
                                                    onTap: () {
                                                      final base = ctrl.text.isNotEmpty ? () { try { final p = ctrl.text.split('-'); final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2])); return d.isAfter(DateTime.now()) ? d : DateTime.now(); } catch (_) { return DateTime.now(); } }() : DateTime.now();
                                                      final nd = base.add(Duration(days: days));
                                                      ctrl.text = '${nd.year}-${nd.month.toString().padLeft(2,"0")}-${nd.day.toString().padLeft(2,"0")}';
                                                      setDlg(() {});
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                                      decoration: BoxDecoration(color: const Color(0xFF4B9EFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4B9EFF).withValues(alpha: 0.3))),
                                                      child: Text('+$days ${L.get('day_word')}', style: const TextStyle(fontSize: 11, color: Color(0xFF4B9EFF), fontWeight: FontWeight.bold)),
                                                    ),
                                                  )).toList()),
                                                ]),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(context), child: Text(L.get('cancel'), style: TextStyle(color: ctx.textSecondary))),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D3A5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                                    onPressed: () {
                                                      final old = globalVehicles[e.lineIdx][e.vehIdx];
                                                      globalVehicles[e.lineIdx][e.vehIdx] = LineVehicle(
                                                        number: old.number, vehicleId: old.vehicleId, status: old.status,
                                                        note: old.note, ownerName: old.ownerName, carLicExpiry: old.carLicExpiry,
                                                        insuranceExpiry: old.insuranceExpiry, operatingLicNum: old.operatingLicNum,
                                                        operatingLicDate: old.operatingLicDate, rfidTag: old.rfidTag,
                                                        loadingExpiry: ctrl.text.trim(), maker: old.maker, model: old.model,
                                                        year: old.year, chassis: old.chassis, ownerPhone: old.ownerPhone,
                                                        ownerId: old.ownerId, driverName: old.driverName,
                                                      );
                                                      autoSave(); setState(() {}); Navigator.pop(context);
                                                    },
                                                    child: Text(L.get('save'), style: const TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        decoration: BoxDecoration(color: const Color(0xFF4B9EFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF4B9EFF).withValues(alpha: 0.3))),
                                        child: Center(child: Text(L.get('edit_loading_date'), style: const TextStyle(fontSize: 12, color: Color(0xFF4B9EFF), fontWeight: FontWeight.bold))),
                                      ),
                                    )),
                                    const SizedBox(width: 8),
                                    Expanded(child: _Tap(
                                      onTap: () {
                                        final carLicCtrl  = TextEditingController(text: lv.carLicExpiry);
                                        final insCtrl     = TextEditingController(text: lv.insuranceExpiry);
                                        final opLicCtrl   = TextEditingController(text: lv.operatingLicDate);
                                        final loadCtrl    = TextEditingController(text: lv.loadingExpiry);
                                        String? selLine   = e.lineName;
                                        final nm = RegExp(r'^\[(\d+)\]\s*(.*)').firstMatch(e.lineName);
                                        final route = nm?.group(2) ?? e.lineName;
                                        final parts = route.split(' → ');
                                        final fromCtrl = TextEditingController(text: parts.isNotEmpty ? parts.first : '');
                                        final toCtrl   = TextEditingController(text: parts.length > 1 ? parts.last : '');

                                        Future<void> pickD(TextEditingController ctrl, BuildContext ctx) async {
                                          final picked = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2040));
                                          if (picked != null) ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2,"0")}-${picked.day.toString().padLeft(2,"0")}';
                                        }

                                        showDialog(
                                          context: context,
                                          builder: (_) => StatefulBuilder(
                                            builder: (ctx, setDlg) => Directionality(
                                              textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                                              child: AlertDialog(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                title: Row(children: [
                                                  const Icon(Icons.edit_outlined, color: Color(0xFF2D3A5C), size: 20),
                                                  const SizedBox(width: 8),
                                                  Expanded(child: Text('${L.get('edit')} ${lv.vehicleId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                                ]),
                                                content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                  Text(L.get('operating_license'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFB347))),
                                                  const SizedBox(height: 8),
                                                  _editDateRow(L.get('lic_exp'), carLicCtrl, ctx, () => pickD(carLicCtrl, ctx).then((_) => setDlg(() {}))),
                                                  const SizedBox(height: 8),
                                                  _editDateRow(L.get('insurance_exp'), insCtrl, ctx, () => pickD(insCtrl, ctx).then((_) => setDlg(() {}))),
                                                  const SizedBox(height: 8),
                                                  _editDateRow(L.get('op_lic_exp'), opLicCtrl, ctx, () => pickD(opLicCtrl, ctx).then((_) => setDlg(() {}))),
                                                  const SizedBox(height: 14),
                                                  Text(L.get('loading_expiry_label'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4B9EFF))),
                                                  const SizedBox(height: 8),
                                                  _editDateRow(L.get('loading_expiry_label'), loadCtrl, ctx, () => pickD(loadCtrl, ctx).then((_) => setDlg(() {}))),
                                                  const SizedBox(height: 6),
                                                  Wrap(spacing: 6, children: [1, 3, 7, 14, 30].map((days) => _Tap(
                                                    onTap: () {
                                                      final base = loadCtrl.text.isNotEmpty ? () { try { final p = loadCtrl.text.split('-'); final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2])); return d.isAfter(DateTime.now()) ? d : DateTime.now(); } catch (_) { return DateTime.now(); } }() : DateTime.now();
                                                      final nd = base.add(Duration(days: days));
                                                      loadCtrl.text = '${nd.year}-${nd.month.toString().padLeft(2,"0")}-${nd.day.toString().padLeft(2,"0")}';
                                                      setDlg(() {});
                                                    },
                                                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF4B9EFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF4B9EFF).withValues(alpha: 0.3))), child: Text('+$days ${L.get('day_word')}', style: const TextStyle(fontSize: 11, color: Color(0xFF4B9EFF), fontWeight: FontWeight.bold))),
                                                  )).toList()),
                                                  const SizedBox(height: 14),
                                                  Text(L.get('route_label'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00C897))),
                                                  const SizedBox(height: 8),
                                                  Row(children: [
                                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                      Text(L.get('from'), style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
                                                      const SizedBox(height: 3),
                                                      TextField(controller: fromCtrl, decoration: InputDecoration(hintText: L.get('from'), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E4EE))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00C897))))),
                                                    ])),
                                                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF00C897))),
                                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                                      Text(L.get('to'), style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
                                                      const SizedBox(height: 3),
                                                      TextField(controller: toCtrl, decoration: InputDecoration(hintText: L.get('to'), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE0E4EE))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00C897))))),
                                                    ])),
                                                  ]),
                                                  const SizedBox(height: 12),
                                                  Text(L.get('choose_line'), style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE0E4EE)), borderRadius: BorderRadius.circular(10), color: ctx.cardColor),
                                                    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                                                      value: selLine,
                                                      isExpanded: true,
                                                      hint: Text(L.get('choose_line'), style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                                                      items: globalLines.map((l) => DropdownMenuItem(value: l.name, child: Text(l.name, style: TextStyle(fontSize: 13, color: ctx.textPrimary), overflow: TextOverflow.ellipsis))).toList(),
                                                      onChanged: (val) => setDlg(() => selLine = val),
                                                    )),
                                                  ),
                                                ])),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(context), child: Text(L.get('cancel'), style: TextStyle(color: ctx.textSecondary))),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D3A5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                                    onPressed: () {
                                                      final old = globalVehicles[e.lineIdx][e.vehIdx];
                                                      final updatedV = LineVehicle(
                                                        number: old.number, vehicleId: old.vehicleId, status: old.status,
                                                        note: old.note, ownerName: old.ownerName,
                                                        carLicExpiry: carLicCtrl.text.trim(), insuranceExpiry: insCtrl.text.trim(),
                                                        operatingLicNum: old.operatingLicNum, operatingLicDate: opLicCtrl.text.trim(),
                                                        rfidTag: old.rfidTag, loadingExpiry: loadCtrl.text.trim(),
                                                        maker: old.maker, model: old.model, year: old.year, chassis: old.chassis,
                                                        ownerPhone: old.ownerPhone, ownerId: old.ownerId, driverName: old.driverName,
                                                      );
                                                      final targetIdx = selLine != null ? globalLines.indexWhere((l) => l.name == selLine) : e.lineIdx;
                                                      final useIdx = targetIdx != -1 ? targetIdx : e.lineIdx;
                                                      if (useIdx >= 0 && useIdx < globalLines.length) {
                                                        final oldLine = globalLines[useIdx];
                                                        final nm2 = RegExp(r'^\[(\d+)\]').firstMatch(oldLine.name);
                                                        final lineNum = nm2?.group(1) ?? '';
                                                        final from = fromCtrl.text.trim(), to = toCtrl.text.trim();
                                                        final allParts = [if (from.isNotEmpty) from, if (to.isNotEmpty) to];
                                                        final newRoute = allParts.length >= 2 ? allParts.join(' → ') : allParts.isNotEmpty ? allParts[0] : oldLine.name;
                                                        final newName = lineNum.isNotEmpty ? '[$lineNum] $newRoute' : newRoute;
                                                        globalLines[useIdx] = LineModel(name: newName, subtitle: oldLine.subtitle, supervisor: oldLine.supervisor, drivers: oldLine.drivers, gateId: oldLine.gateId, entryGateId: oldLine.entryGateId, exitGateId: oldLine.exitGateId, fare: oldLine.fare, loadingSlots: oldLine.loadingSlots);
                                                      }
                                                      if (targetIdx != -1 && targetIdx != e.lineIdx) {
                                                        globalVehicles[e.lineIdx].removeAt(e.vehIdx);
                                                        globalVehicles[targetIdx].add(updatedV);
                                                      } else {
                                                        globalVehicles[e.lineIdx][e.vehIdx] = updatedV;
                                                      }
                                                      autoSave(); setState(() {}); Navigator.pop(context);
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                        content: Text(L.get('saved'), textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr),
                                                        backgroundColor: const Color(0xFF2D3A5C),
                                                        duration: const Duration(seconds: 2),
                                                      ));
                                                    },
                                                    child: Text(L.get('save'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        decoration: BoxDecoration(color: const Color(0xFF2D3A5C).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF2D3A5C).withValues(alpha: 0.2))),
                                        child: Center(child: Text(L.get('edit_vehicle'), style: const TextStyle(fontSize: 12, color: Color(0xFF2D3A5C), fontWeight: FontWeight.bold))),
                                      ),
                                    )),
                                    const SizedBox(width: 8),
                                    _Tap(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _VehicleInfoPage(plateNumber: lv.vehicleId, ownerName: lv.ownerName, lineName: e.lineName))).then((_) => setState(() {})),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                        decoration: BoxDecoration(color: const Color(0xFF00C897).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF00C897).withValues(alpha: 0.3))),
                                        child: Text(L.get('details'), style: const TextStyle(fontSize: 12, color: Color(0xFF00C897), fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _Tap(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _AddViolationPage(vehicleId: lv.vehicleId))),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                        decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                                        child: Text(L.get('complaint'), style: const TextStyle(fontSize: 12, color: Color(0xFFC62828), fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _Tap(
                                      onTap: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => Directionality(
                                            textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                                            child: AlertDialog(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              title: Text(L.get('delete_vehicle'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
                                              content: Text('${L.get('delete_vehicle_confirm')} "${lv.vehicleId}"؟'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(L.get('cancel'), style: TextStyle(color: context.textSecondary))),
                                                TextButton(onPressed: () => Navigator.pop(context, true), child: Text(L.get('delete'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                                              ],
                                            ),
                                          ),
                                        );
                                        if (confirm == true) {
                                          globalVehicles[e.lineIdx].removeAt(e.vehIdx);
                                          autoSave();
                                          setState(() { _expandedVehicleIdx = null; });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                      ),
                                    ),
                                  ]),
                                ),
                              ]),
                            ),
                        ]);
                      },
                    ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _VehicleEntry {
  final int lineIdx, vehIdx;
  final LineVehicle lv;
  final String lineName;
  const _VehicleEntry({required this.lineIdx, required this.vehIdx, required this.lv, required this.lineName});
}

Widget _DetailRow(String label, String value, BuildContext ctx) => Row(children: [
  Text('$label: ', style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
  Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ctx.textPrimary)),
]);

Widget _editDateRow(String label, TextEditingController ctrl, BuildContext ctx, VoidCallback onTap) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
    const SizedBox(height: 4),
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: ctx.bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: ctx.dividerColor)),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF2D3A5C)),
          const SizedBox(width: 8),
          Expanded(child: Text(ctrl.text.isEmpty ? L.get('tap_to_select_date') : ctrl.text, style: TextStyle(fontSize: 13, color: ctrl.text.isEmpty ? Colors.grey : ctx.textPrimary))),
        ]),
      ),
    ),
  ]);
}

class _VehicleDetailRow extends StatelessWidget {
  final String label, value;
  const _VehicleDetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text('$label: ', style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54)),
    Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1A1A2E)), overflow: TextOverflow.ellipsis)),
  ]);
}