part of station_app;

class LinesPage extends StatefulWidget {
  const LinesPage({super.key});
  @override
  State<LinesPage> createState() => _LinesPageState();
}

class _LinesPageState extends State<LinesPage> with DarkModeRebuild<LinesPage> {
  int? _expandedIndex;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  String? _filterSupervisor;
  String? _filterEntryGate;
  String? _filterExitGate;
  bool _showFilters = false;

  List<LineModel>         get _lines    => globalLines;
  List<List<LineVehicle>> get _vehicles => globalVehicles;

  List<MapEntry<int, LineModel>> get _filteredLines {
    final q = _searchQuery.trim().toLowerCase();
    return _lines.asMap().entries.where((e) {
      final line     = e.value;
      final name     = line.name.toLowerCase();
      final numStr   = (e.key + 1).toString();
      final numMatch = RegExp(r'\[(\d+)\]').firstMatch(line.name);
      final lineNum  = numMatch?.group(1) ?? '';
      final matchSearch = q.isEmpty || name.contains(q) || numStr.contains(q) || lineNum.contains(q);
      final matchSupervisor = _filterSupervisor == null || line.supervisor == _filterSupervisor;
      final matchEntry = _filterEntryGate == null || line.entryGateId == _filterEntryGate;
      final matchExit  = _filterExitGate  == null || line.exitGateId  == _filterExitGate;
      return matchSearch && matchSupervisor && matchEntry && matchExit;
    }).toList();
  }

  void _addLine(BuildContext context) {
    final numCtrl = TextEditingController();
    String? selectedSupervisor;
    final fareCtrl = TextEditingController();
    String? selectedEntryGateId;
    String? selectedExitGateId;
    final supervisors = globalUsers.where((u) => u.role == 'مشرف خط').toList();

    InputDecoration dec(String hint, {IconData? icon}) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, size: 18, color: Colors.grey[400]) : null,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.dividerColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
      contentPadding: EdgeInsets.symmetric(horizontal: icon != null ? 4 : 12, vertical: 10),
    );

    final slotsCtrl = TextEditingController(text: '0');
    final TextEditingController fromCtrl = TextEditingController();
    final TextEditingController toCtrl   = TextEditingController();
    final List<TextEditingController> middleCtrls = [TextEditingController()];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) {
          return Directionality(
            textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              title: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3A5C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.route_outlined, color: Color(0xFF2D3A5C), size: 20),
                ),
                const SizedBox(width: 10),
                Text(L.get('add_line_new'),
                    style: TextStyle(color: ctx.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('${L.get('line_number')} *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                      const SizedBox(height: 5),
                      TextField(
                        controller: numCtrl,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        autofocus: true,
                        decoration: dec(L.get('line_number_example')),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(L.get('from'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                          const SizedBox(height: 5),
                          TextField(controller: fromCtrl, decoration: dec(L.get('from'))),
                        ])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          child: Column(children: [
                            const SizedBox(height: 18),
                            const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF2D3A5C)),
                          ]),
                        ),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(L.get('to'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                          const SizedBox(height: 5),
                          TextField(controller: toCtrl, decoration: dec(L.get('to'))),
                        ])),
                      ]),
                      const SizedBox(height: 12),
                      Text(L.get('middle_stations'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                      const SizedBox(height: 6),
                      ...middleCtrls.asMap().entries.map((e) {
                        final idx  = e.key;
                        final ctrl = e.value;
                        final isLast = idx == middleCtrls.length - 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TextField(
                            controller: ctrl,
                            decoration: dec(isLast ? '...' : '${idx + 1}'),
                            onChanged: (v) {
                              if (isLast && v.trim().isNotEmpty) {
                                setDlg(() => middleCtrls.add(TextEditingController()));
                              }
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.login_rounded, size: 14, color: Color(0xFF00C897)),
                        const SizedBox(width: 6),
                        Text('${L.get('entry_gate')} *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                      ]),
                      const SizedBox(height: 5),
                      StatefulBuilder(builder: (ctx2, setG) {
                        final entries = globalGates.where((g) => g.type == 'مدخل').toList();
                        if (entries.isEmpty) return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB347).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFB347).withValues(alpha: 0.4)),
                          ),
                          child: Text(L.get('no_entry_gates'),
                              style: const TextStyle(fontSize: 12, color: Color(0xFFFFB347))),
                        );
                        return Wrap(spacing: 8, runSpacing: 6, children: entries.map((g) {
                          final sel = selectedEntryGateId == g.id;
                          return _Tap(
                            onTap: () => setDlg(() => selectedEntryGateId = g.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? const Color(0xFF00C897) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: sel ? const Color(0xFF00C897) : ctx.dividerColor),
                              ),
                              child: Text(g.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white : Colors.grey[600])),
                            ),
                          );
                        }).toList());
                      }),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.logout_rounded, size: 14, color: Color(0xFFFF5A5F)),
                        const SizedBox(width: 6),
                        Text('${L.get('exit_gate')} *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                      ]),
                      const SizedBox(height: 5),
                      StatefulBuilder(builder: (ctx3, setG2) {
                        final exits = globalGates.where((g) => g.type == 'مخرج').toList();
                        if (exits.isEmpty) return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB347).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFB347).withValues(alpha: 0.4)),
                          ),
                          child: Text(L.get('no_exit_gates'),
                              style: const TextStyle(fontSize: 12, color: Color(0xFFFFB347))),
                        );
                        return Wrap(spacing: 8, runSpacing: 6, children: exits.map((g) {
                          final sel = selectedExitGateId == g.id;
                          return _Tap(
                            onTap: () => setDlg(() => selectedExitGateId = g.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? const Color(0xFFFF5A5F) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: sel ? const Color(0xFFFF5A5F) : ctx.dividerColor),
                              ),
                              child: Text(g.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white : Colors.grey[600])),
                            ),
                          );
                        }).toList());
                      }),
                      const SizedBox(height: 12),
                      Text(L.get('line_supervisor'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                      const SizedBox(height: 5),
                      supervisors.isEmpty
                        ? Text(L.get('no_supervisor_reg'), style: TextStyle(fontSize: 12, color: Colors.grey[400]))
                        : _SearchableDropdown(
                            hint: L.get('choose_supervisor'),
                            items: supervisors.map((u) => u.name).toList(),
                            selected: selectedSupervisor,
                            onSelected: (v) => setDlg(() => selectedSupervisor = v),
                          ),
                      const SizedBox(height: 12),
                      Text(L.get('fare_shekel'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                      const SizedBox(height: 5),
                      TextField(
                        controller: fareCtrl,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          hintText: '',
                          prefixIcon: const Icon(Icons.payments_outlined, size: 18, color: Color(0xFF00C897)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.dividerColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(L.get('loading_slots_count'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                      const SizedBox(height: 5),
                      TextField(
                        controller: slotsCtrl,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          hintText: '',
                          prefixIcon: const Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF4B9EFF)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.dividerColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(L.get('cancel'), style: TextStyle(color: ctx.textSecondary)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D3A5C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  label: Text(L.get('add_line_btn'), style: const TextStyle(color: Colors.white)),
                  onPressed: () {
                    if (numCtrl.text.trim().isEmpty) return;
                    final from   = fromCtrl.text.trim();
                    final to     = toCtrl.text.trim();
                    final middle = middleCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
                    final lineNum = numCtrl.text.trim();
                    final allZones = [if (from.isNotEmpty) from, ...middle, if (to.isNotEmpty) to];
                    final route = allZones.length >= 2
                        ? allZones.join(' → ')
                        : allZones.length == 1 ? allZones[0] : '${L.get('line')} $lineNum';
                    final hasEntries = globalGates.any((g) => g.type == 'مدخل');
                    final hasExits   = globalGates.any((g) => g.type == 'مخرج');
                    if (hasEntries && selectedEntryGateId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(L.get('choose_entry_gate'),
                            textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr),
                        backgroundColor: const Color(0xFFFF5A5F),
                      ));
                      return;
                    }
                    if (hasExits && selectedExitGateId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(L.get('choose_exit_gate'),
                            textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr),
                        backgroundColor: const Color(0xFFFF5A5F),
                      ));
                      return;
                    }
                    setState(() {
                      _lines.add(LineModel(
                        name:        '[$lineNum] $route',
                        subtitle:    '0 ${L.get('waiting')}',
                        supervisor:  selectedSupervisor ?? '',
                        drivers:     [],
                        gateId:      selectedEntryGateId ?? '',
                        entryGateId: selectedEntryGateId ?? '',
                        exitGateId:  selectedExitGateId  ?? '',
                        fare:        fareCtrl.text.trim(),
                        loadingSlots: int.tryParse(slotsCtrl.text.trim()) ?? 0,
                      ));
                      _vehicles.add([]);
                    });
                    autoSave();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _routeNumberBadge(int number, bool isGray) => Container(
    width: 26, height: 26,
    decoration: BoxDecoration(
      color: isGray ? Colors.grey[200] : const Color(0xFF2D3A5C).withValues(alpha: 0.1),
      shape: BoxShape.circle,
    ),
    child: Center(child: Text('$number',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
            color: isGray ? Colors.grey[400] : const Color(0xFF2D3A5C)))),
  );

  void _editLine(BuildContext context, int i) {
    final line = _lines[i];
    final numMatch = RegExp(r'^\[(\d+)\]\s*(.*)').firstMatch(line.name);
    final lineNum  = numMatch?.group(1) ?? '';
    final fullRoute = numMatch?.group(2) ?? line.name;
    final parts = fullRoute.split(' → ');
    final fromText   = parts.isNotEmpty ? parts.first : '';
    final toText     = parts.length > 1 ? parts.last : '';
    final middleList = parts.length > 2 ? parts.sublist(1, parts.length - 1) : <String>[];

    final numCtrl    = TextEditingController(text: lineNum);
    final fromCtrl   = TextEditingController(text: fromText);
    final toCtrl     = TextEditingController(text: toText);
    final fareCtrl   = TextEditingController(text: line.fare);
    final slotsCtrl  = TextEditingController(text: '${line.loadingSlots}');
    final middleCtrls = [...middleList.map((s) => TextEditingController(text: s)), TextEditingController()];
    String? selectedSupervisor = line.supervisor.isNotEmpty ? line.supervisor : null;
    final supervisors = globalUsers.where((u) => u.role == 'مشرف خط').toList();

    InputDecoration dec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.dividerColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => Directionality(
          textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3A5C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_outlined, color: Color(0xFF2D3A5C), size: 20),
              ),
              const SizedBox(width: 10),
              Text(L.get('edit_line_title'), style: TextStyle(color: ctx.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 8),
                  Text(L.get('line_number'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                  const SizedBox(height: 5),
                  TextField(controller: numCtrl, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, decoration: dec(L.get('line_number_example'))),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(L.get('from'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                      const SizedBox(height: 5),
                      TextField(controller: fromCtrl, decoration: dec(L.get('from'))),
                    ])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(children: [
                        const SizedBox(height: 18),
                        const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF2D3A5C)),
                      ]),
                    ),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(L.get('to'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                      const SizedBox(height: 5),
                      TextField(controller: toCtrl, decoration: dec(L.get('to'))),
                    ])),
                  ]),
                  const SizedBox(height: 12),
                  Text(L.get('middle_stations'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                  const SizedBox(height: 6),
                  ...middleCtrls.asMap().entries.map((e) {
                    final idx = e.key; final ctrl = e.value;
                    final isLast = idx == middleCtrls.length - 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: ctrl,
                        decoration: dec(isLast ? '...' : '${idx + 1}'),
                        onChanged: (v) {
                          if (isLast && v.trim().isNotEmpty)
                            setDlg(() => middleCtrls.add(TextEditingController()));
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  Text(L.get('line_supervisor'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                  const SizedBox(height: 5),
                  supervisors.isEmpty
                    ? Text(L.get('no_supervisor_reg'), style: TextStyle(fontSize: 12, color: Colors.grey[400]))
                    : _SearchableDropdown(
                        hint: L.get('choose_supervisor'),
                        items: supervisors.map((u) => u.name).toList(),
                        selected: selectedSupervisor,
                        onSelected: (v) => setDlg(() => selectedSupervisor = v),
                      ),
                  const SizedBox(height: 12),
                  Text(L.get('fare_shekel'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: fareCtrl,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.payments_outlined, size: 18, color: Color(0xFF00C897)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.dividerColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(L.get('loading_slots_count'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: slotsCtrl,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF4B9EFF)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.dividerColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),
                ]),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(L.get('cancel'), style: TextStyle(color: ctx.textSecondary)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3A5C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                label: Text(L.get('save_changes'), style: const TextStyle(color: Colors.white)),
                onPressed: () {
                  final newNum = numCtrl.text.trim();
                  if (newNum.isEmpty) return;
                  final from   = fromCtrl.text.trim();
                  final to     = toCtrl.text.trim();
                  final middle = middleCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
                  final allZones = [if (from.isNotEmpty) from, ...middle, if (to.isNotEmpty) to];
                  final route = allZones.length >= 2
                      ? allZones.join(' → ')
                      : allZones.length == 1 ? allZones[0] : '${L.get('line')} $newNum';
                  setState(() {
                    _lines[i] = LineModel(
                      name:         '[$newNum] $route',
                      subtitle:     _lines[i].subtitle,
                      supervisor:   selectedSupervisor ?? '',
                      drivers:      _lines[i].drivers,
                      gateId:       _lines[i].gateId,
                      entryGateId:  _lines[i].entryGateId,
                      exitGateId:   _lines[i].exitGateId,
                      fare:         fareCtrl.text.trim(),
                      loadingSlots: int.tryParse(slotsCtrl.text.trim()) ?? 0,
                    );
                  });
                  autoSave();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteLine(BuildContext context, int i) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(L.get('delete_line'),
              style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
          content: Text('${L.get('delete_line_confirm')} "${_lines[i].name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(L.get('cancel'), style: TextStyle(color: context.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(L.get('delete'),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      setState(() {
        _lines.removeAt(i);
        _vehicles.removeAt(i);
        if (_expandedIndex == i) _expandedIndex = null;
      });
      autoSave();
    }
  }

  void _addVehicle(BuildContext context, int lineIndex) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _AddVehiclePage(
        lineName: _lines[lineIndex].name,
        onSave: (vehicleId, qrCode, vehicleType, licenseExpiry, ownerName, driverName, status,
        {String carLicExpiry='', String insuranceExpiry='', String? newLineName}) {
          setState(() {
            final list = _vehicles[lineIndex];
            list.add(LineVehicle(
              number: list.length + 1,
              vehicleId: vehicleId,
              status: status,
              ownerName: ownerName,
            ));
            _lines[lineIndex] = LineModel(
              name: _lines[lineIndex].name,
              subtitle: '${list.length} ${L.get('waiting')}',
              supervisor: _lines[lineIndex].supervisor,
              drivers: _lines[lineIndex].drivers,
            );
          });
          autoSave();
          logEvent(EventItem(
            vehicleId: '${L.get('vehicle')} $vehicleId',
            location: _lines[lineIndex].name,
            time: nowTime(),
            type: status == 'مخالفة' ? EventType.violation : EventType.entry,
            violationNote: status == 'مخالفة' ? L.get('complaint_recorded') : null,
          ));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text(
                '✅  ${L.get('vehicle_added_success')} $vehicleId ${L.get('vehicle_added_suffix')}',
                textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              )),
            ]),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ));
        },
      ),
    ));
  }

  void _editVehicle(BuildContext context, int lineIndex, int vIndex) {
    final v = _vehicles[lineIndex][vIndex];
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _EditVehiclePage(
        vehicle: v,
        lineName: _lines[lineIndex].name,
        onSave: (vehicleId, qrCode, vehicleType, licenseExpiry, ownerName, driverName, status,
        {String carLicExpiry='', String insuranceExpiry='', String? newLineName}) {
          setState(() {
            final updatedVehicle = LineVehicle(
              number: v.number,
              vehicleId: vehicleId,
              status: status,
              ownerName: ownerName,
              carLicExpiry: carLicExpiry,
              insuranceExpiry: insuranceExpiry,
            );
            if (newLineName != null && newLineName.isNotEmpty &&
                newLineName != _lines[lineIndex].name) {
              final targetIdx = _lines.indexWhere((l) => l.name == newLineName);
              if (targetIdx != -1) {
                _vehicles[lineIndex].removeAt(vIndex);
                for (int k = 0; k < _vehicles[lineIndex].length; k++) {
                  final old = _vehicles[lineIndex][k];
                  _vehicles[lineIndex][k] = LineVehicle(
                    number: k + 1, vehicleId: old.vehicleId,
                    status: old.status, note: old.note,
                    ownerName: old.ownerName,
                    carLicExpiry: old.carLicExpiry,
                    insuranceExpiry: old.insuranceExpiry,
                  );
                }
                _vehicles[targetIdx].add(LineVehicle(
                  number: _vehicles[targetIdx].length + 1,
                  vehicleId: vehicleId, status: status,
                  ownerName: ownerName,
                  carLicExpiry: carLicExpiry,
                  insuranceExpiry: insuranceExpiry,
                ));
                logEvent(EventItem(
                  vehicleId: '${L.get('vehicle')} $vehicleId',
                  location: '${_lines[lineIndex].name} ← $newLineName',
                  time: nowTime(),
                  type: EventType.exit,
                ));
              }
            } else {
              _vehicles[lineIndex][vIndex] = updatedVehicle;
            }
          });
          autoSave();
          logEvent(EventItem(
            vehicleId: '${L.get('vehicle')} $vehicleId',
            location: _lines[lineIndex].name,
            time: nowTime(),
            type: status == 'مخالفة' ? EventType.violation : EventType.exit,
            violationNote: status == 'مخالفة' ? L.get('complaint_recorded') : null,
          ));
        },
      ),
    ));
  }

  void _deleteVehicle(BuildContext context, int lineIndex, int vIndex) async {
    final v = _vehicles[lineIndex][vIndex];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(L.get('delete_vehicle'),
              style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
          content: Text('${L.get('delete_vehicle_confirm')} "${v.vehicleId}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(L.get('cancel'), style: TextStyle(color: context.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(L.get('delete'),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      setState(() {
        _vehicles[lineIndex].removeAt(vIndex);
        for (int k = 0; k < _vehicles[lineIndex].length; k++) {
          final old = _vehicles[lineIndex][k];
          _vehicles[lineIndex][k] = LineVehicle(
              number: k + 1, vehicleId: old.vehicleId,
              status: old.status, note: old.note);
        }
        _lines[lineIndex] = LineModel(
          name: _lines[lineIndex].name,
          subtitle: '${_vehicles[lineIndex].length} ${L.get('waiting')}',
          supervisor: _lines[lineIndex].supervisor,
          drivers: _lines[lineIndex].drivers,
        );
      });
      autoSave();
    }
    logEvent(EventItem(
      vehicleId: '${L.get('vehicle')} ${v.vehicleId}',
      location: _lines[lineIndex].name,
      time: nowTime(),
      type: EventType.exit,
    ));
  }

  void _showLineInfo(BuildContext context, int i) {
    final line     = _lines[i];
    final vehicles = _vehicles[i];
    final ready    = vehicles.where((v) => v.status == 'جاهزة').length;
    final waiting  = vehicles.where((v) => v.status == 'في الانتظار').length;
    final viol     = vehicles.where((v) => v.status == 'مخالفة').length;

    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.route_outlined, color: Color(0xFF2D3A5C)),
            const SizedBox(width: 8),
            Expanded(child: Text(line.name,
                style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 16))),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (line.supervisor.isNotEmpty)
                _infoRow(Icons.manage_accounts_outlined, L.get('supervisor_label'), line.supervisor),
              if (line.fare.isNotEmpty)
                _infoRow(Icons.payments_outlined, L.get('fare'), '${line.fare} ${L.get('shekel')}', color: const Color(0xFF00C897)),
              _infoRow(Icons.directions_car_outlined, L.get('total_vehicles'), '${vehicles.length}'),
              _infoRow(Icons.check_circle_outline, L.get('ready_vehicles'), '$ready', color: const Color(0xFF2E7D32)),
              _infoRow(Icons.hourglass_bottom_outlined, L.get('waiting_vehicles'), '$waiting', color: const Color(0xFFE65100)),
              _infoRow(Icons.warning_amber_outlined, L.get('violation_vehicles'), '$viol', color: const Color(0xFFC62828)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L.get('close_dialog'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 16, color: color ?? const Color(0xFF8A93A8)),
      const SizedBox(width: 8),
      Text('$label: ', style: TextStyle(fontSize: 13, color: context.textSecondary)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
          color: color ?? context.textPrimary)),
    ]),
  );

  Color _statusColor(String s) {
    if (s == 'جاهزة')        return const Color(0xFF2E7D32);
    if (s == 'في الانتظار')  return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  Color _statusBg(String s) {
    if (s == 'جاهزة')        return const Color(0xFFE8F5E9);
    if (s == 'في الانتظار')  return const Color(0xFFFFF3E0);
    return const Color(0xFFFFEBEE);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(color: Color(0xFF2D3A5C)),
            child: Row(children: [
              Expanded(
                child: Text(L.get('lines_title'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ]),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Spacer(),
                      _Tap(
                        onTap: () => _addLine(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D3A5C),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(children: [
                            const Icon(Icons.add, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(L.get('add'), style: const TextStyle(color: Colors.white,
                                fontSize: 13, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 5)],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                        onChanged: (v) => setState(() { _searchQuery = v; _expandedIndex = null; }),
                        decoration: InputDecoration(
                          hintText: L.get('search_line'),
                          hintStyle: TextStyle(color: context.textSecondary, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: context.textSecondary, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 18, color: context.textSecondary),
                                  onPressed: () => setState(() { _searchQuery = ''; _searchCtrl.clear(); }))
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_showFilters) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2D3A5C).withValues(alpha: 0.2)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.filter_list_rounded, size: 14, color: Color(0xFF2D3A5C)),
                            const SizedBox(width: 6),
                            Text(L.get('filter_results'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
                            const Spacer(),
                            if (_filterSupervisor != null || _filterEntryGate != null || _filterExitGate != null)
                              _Tap(
                                onTap: () => setState(() { _filterSupervisor = null; _filterEntryGate = null; _filterExitGate = null; }),
                                child: Text(L.get('clear_all'), style: TextStyle(fontSize: 11, color: Colors.red[400])),
                              ),
                          ]),
                          const SizedBox(height: 10),
                          Text(L.get('supervisor_label'), style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Builder(builder: (_) {
                            final supervisors = globalLines.map((l) => l.supervisor).where((s) => s.isNotEmpty).toSet().toList();
                            if (supervisors.isEmpty) return Text(L.get('no_supervisors'), style: TextStyle(fontSize: 11, color: context.textSecondary));
                            return Wrap(spacing: 6, runSpacing: 6, children: supervisors.map((s) {
                              final sel = _filterSupervisor == s;
                              return _Tap(
                                onTap: () => setState(() => _filterSupervisor = sel ? null : s),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: sel ? const Color(0xFF2D3A5C) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: sel ? const Color(0xFF2D3A5C) : context.dividerColor),
                                  ),
                                  child: Text(s, style: TextStyle(fontSize: 11, color: sel ? Colors.white : context.textPrimary)),
                                ),
                              );
                            }).toList());
                          }),
                          const SizedBox(height: 10),
                          Text(L.get('entry_gate'), style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Builder(builder: (_) {
                            final entries = globalGates.where((g) => g.type == 'مدخل').toList();
                            if (entries.isEmpty) return Text(L.get('no_gates'), style: TextStyle(fontSize: 11, color: context.textSecondary));
                            return Wrap(spacing: 6, runSpacing: 6, children: entries.map((g) {
                              final sel = _filterEntryGate == g.id;
                              return _Tap(
                                onTap: () => setState(() => _filterEntryGate = sel ? null : g.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: sel ? const Color(0xFF00C897) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: sel ? const Color(0xFF00C897) : context.dividerColor),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.login_rounded, size: 11, color: sel ? Colors.white : const Color(0xFF00C897)),
                                    const SizedBox(width: 4),
                                    Text(g.label, style: TextStyle(fontSize: 11, color: sel ? Colors.white : context.textPrimary)),
                                  ]),
                                ),
                              );
                            }).toList());
                          }),
                          const SizedBox(height: 10),
                          Text(L.get('exit_gate'), style: TextStyle(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Builder(builder: (_) {
                            final exits = globalGates.where((g) => g.type == 'مخرج').toList();
                            if (exits.isEmpty) return Text(L.get('no_gates'), style: TextStyle(fontSize: 11, color: context.textSecondary));
                            return Wrap(spacing: 6, runSpacing: 6, children: exits.map((g) {
                              final sel = _filterExitGate == g.id;
                              return _Tap(
                                onTap: () => setState(() => _filterExitGate = sel ? null : g.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: sel ? const Color(0xFFFF5A5F) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: sel ? const Color(0xFFFF5A5F) : context.dividerColor),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.logout_rounded, size: 11, color: sel ? Colors.white : const Color(0xFFFF5A5F)),
                                    const SizedBox(width: 4),
                                    Text(g.label, style: TextStyle(fontSize: 11, color: sel ? Colors.white : context.textPrimary)),
                                  ]),
                                ),
                              );
                            }).toList());
                          }),
                        ]),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 6),
                    ..._filteredLines.map((entry) {
                      final i = entry.key;
                      final line = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Tap(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => _LineInfoPage(lineIndex: i),
                            )).then((_) => setState(() {})),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 5)],
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Builder(builder: (ctx) {
                                      final numMatch = RegExp(r'^\[(\d+)\]\s*(.*)').firstMatch(line.name);
                                      final lineNum  = numMatch?.group(1) ?? '';
                                      final route    = numMatch?.group(2) ?? line.name;
                                      final parts = route.split(' → ');
                                      final fromTo = parts.length >= 2
                                          ? '${parts.first} → ${parts.last}'
                                          : route;
                                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Row(children: [
                                          if (lineNum.isNotEmpty) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2D3A5C),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(lineNum,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Expanded(
                                            child: Text(fromTo,
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary),
                                                overflow: TextOverflow.ellipsis),
                                          ),
                                        ]),
                                        if (route.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(children: [
                                            const Icon(Icons.route_outlined, size: 12, color: Color(0xFF8A93A8)),
                                            const SizedBox(width: 4),
                                            Expanded(child: Text('${L.get('route_label')}: $route',
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF8A93A8)),
                                                overflow: TextOverflow.ellipsis)),
                                          ]),
                                        ],
                                      ]);
                                    }),
                                    const SizedBox(height: 3),
                                    Text(line.subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                    if (line.supervisor.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        const Icon(Icons.person_outline, size: 12, color: Color(0xFF8A93A8)),
                                        const SizedBox(width: 3),
                                        Text('${L.get('supervisor_label')}: ${line.supervisor}',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF8A93A8))),
                                      ]),
                                    ],
                                  ]),
                                ),
                                _Tap(
                                  onTap: () => _showLineInfo(context, i),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(Icons.info_outline, size: 16, color: Color(0xFF8A93A8)),
                                  ),
                                ),
                                _Tap(
                                  onTap: () => _editLine(context, i),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D3A5C).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF2D3A5C)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                _Tap(
                                  onTap: () => _deleteLine(context, i),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.delete_outline, size: 15, color: Colors.red),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF8A93A8)),
                              ]),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  _LineInfoPage
// ─────────────────────────────────────────────
class _LineInfoPage extends StatefulWidget {
  final int lineIndex;
  const _LineInfoPage({required this.lineIndex});
  @override
  State<_LineInfoPage> createState() => _LineInfoPageState();
}

class _LineInfoPageState extends State<_LineInfoPage> with DarkModeRebuild<_LineInfoPage> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  LineModel get _line => globalLines[widget.lineIndex];
  List<LineVehicle> get _vehicles => globalVehicles[widget.lineIndex];

  List<LineVehicle> get _filtered => _search.isEmpty
      ? _vehicles
      : _vehicles.where((v) => v.vehicleId.contains(_search) || v.ownerName.contains(_search)).toList();

  @override
  Widget build(BuildContext context) {
    final line = _line;
    final nm = RegExp(r'^\[(\d+)\]\s*(.*)').firstMatch(line.name);
    final lineNum = nm?.group(1) ?? '';
    final route   = nm?.group(2) ?? line.name;

    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D3A5C),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('${L.get('line')} $lineNum — $route',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis),
        ),
        body: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: context.cardColor,
            child: Wrap(spacing: 16, runSpacing: 8, children: [
              if (line.supervisor.isNotEmpty)
                _LineChip(Icons.manage_accounts_outlined, '${L.get('supervisor_label')}: ${line.supervisor}', const Color(0xFFFFB347)),
              if (line.fare.isNotEmpty)
                _LineChip(Icons.payments_outlined, '${L.get('fare')}: ${line.fare} ₪', const Color(0xFF00C897)),
              _LineChip(Icons.directions_car_outlined, '${_vehicles.length} ${L.get('vehicle')}', const Color(0xFF4B9EFF)),
              if (line.loadingSlots > 0)
                _LineChip(Icons.grid_view_rounded, '${L.get('loading_slots_visual')}: ${line.loadingSlots}', const Color(0xFFB47AFF)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 5)]),
              child: TextField(
                controller: _searchCtrl,
                textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                onChanged: (v) => setState(() => _search = v.trim()),
                decoration: InputDecoration(
                  hintText: L.get('search_plate_owner'),
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: context.textSecondary),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(icon: Icon(Icons.clear, size: 18, color: context.textSecondary),
                          onPressed: () => setState(() { _search = ''; _searchCtrl.clear(); }))
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
              ? Center(child: Text(L.get('no_vehicles_found'), style: TextStyle(color: Colors.grey[400])))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _filtered.length,
                  itemBuilder: (_, idx) {
                    final v = _filtered[idx];
                    int daysLeft = -999;
                    bool hasExpiry = v.loadingExpiry.isNotEmpty;
                    if (hasExpiry) {
                      try {
                        final p = v.loadingExpiry.split('-');
                        final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
                        daysLeft = d.difference(DateTime.now()).inDays;
                      } catch (_) {}
                    }
                    final loadColor = !hasExpiry ? const Color(0xFF8A93A8)
                      : daysLeft < 0 ? const Color(0xFFFF5A5F)
                      : daysLeft <= 3 ? const Color(0xFFFFB347)
                      : const Color(0xFF00C897);

                    return _Tap(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _VehicleInfoPage(plateNumber: v.vehicleId, ownerName: v.ownerName, lineName: line.name),
                      )).then((_) => setState(() {})),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 5)]),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: const Color(0xFF2D3A5C).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                            child: Center(child: Text('${v.number}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimary))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(v.vehicleId, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary)),
                            if (v.ownerName.isNotEmpty) Text(v.ownerName, style: TextStyle(fontSize: 11, color: context.textSecondary)),
                            Row(children: [
                              Icon(Icons.local_shipping_outlined, size: 11, color: loadColor),
                              const SizedBox(width: 4),
                              Text(
                                !hasExpiry ? L.get('loading_not_set')
                                  : daysLeft < 0 ? '${L.get('expired_days_ago')} ${daysLeft.abs()} ${L.get('day_word')}'
                                  : daysLeft == 0 ? L.get('expires_today')
                                  : '${L.get('days_left')} $daysLeft ${L.get('day_word')}',
                                style: TextStyle(fontSize: 10, color: loadColor, fontWeight: FontWeight.w600),
                              ),
                            ]),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: v.status == 'محظورة' ? const Color(0xFFFF5A5F).withValues(alpha: 0.1) : const Color(0xFF00C897).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(v.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                color: v.status == 'محظورة' ? const Color(0xFFFF5A5F) : const Color(0xFF00C897))),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_ios, size: 13, color: Color(0xFF8A93A8)),
                        ]),
                      ),
                    );
                  },
                ),
          ),
        ]),
      ),
    );
  }
}

class _LineChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _LineChip(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: color),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
  ]);
}

// ─────────────────────────────────────────────
//  _LineExpandedSection
// ─────────────────────────────────────────────
class _LineExpandedSection extends StatefulWidget {
  final LineModel       line;
  final int             lineIndex;
  final List<LineVehicle> vehicles;
  final VoidCallback    onEdit;
  final VoidCallback    onDelete;
  const _LineExpandedSection({
    required this.line, required this.lineIndex,
    required this.vehicles, required this.onEdit, required this.onDelete,
  });
  @override
  State<_LineExpandedSection> createState() => _LineExpandedSectionState();
}

class _LineExpandedSectionState extends State<_LineExpandedSection>
    with DarkModeRebuild<_LineExpandedSection> {
  String _search = '';

  List<LineVehicle> get _filtered => _search.isEmpty
      ? widget.vehicles
      : widget.vehicles.where((v) =>
          v.vehicleId.contains(_search) ||
          v.ownerName.contains(_search)).toList();

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 5)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(L.get('line_info'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary)),
          const Spacer(),
          _Tap(
            onTap: widget.onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3A5C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF2D3A5C)),
                const SizedBox(width: 4),
                Text(L.get('edit'), style: TextStyle(fontSize: 11, color: context.textPrimary, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          _Tap(
            onTap: widget.onDelete,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red, size: 14),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 10),
        if (line.supervisor.isNotEmpty)
          _InfoRow(icon: Icons.manage_accounts_outlined, label: L.get('supervisor_label'), value: line.supervisor),
        if (line.fare.isNotEmpty)
          _InfoRow(icon: Icons.payments_outlined, label: L.get('fare'), value: '${line.fare} ${L.get('shekel')}', color: const Color(0xFF00C897)),
        if (line.loadingSlots > 0)
          _InfoRow(icon: Icons.grid_view_rounded, label: L.get('loading_slots_visual'), value: '${line.loadingSlots}', color: const Color(0xFF4B9EFF)),
        if (line.entryGateId.isNotEmpty)
          _InfoRow(icon: Icons.login_outlined, label: L.get('entry_gate'), value: line.entryGateId),
        if (line.exitGateId.isNotEmpty)
          _InfoRow(icon: Icons.logout_outlined, label: L.get('exit_gate'), value: line.exitGateId),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.directions_car_outlined, size: 15, color: Color(0xFF4B9EFF)),
          const SizedBox(width: 6),
          Text('${L.get('vehicle_count')}: ', style: TextStyle(fontSize: 12, color: context.textSecondary)),
          Text('${widget.vehicles.length}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4B9EFF))),
        ]),
        const SizedBox(height: 10),
        if (widget.line.loadingSlots > 0) ...[
          Builder(builder: (_) {
            final usedSlots = widget.vehicles.length;
            return Row(children: [
              const Icon(Icons.grid_view_rounded, size: 15, color: Color(0xFF4B9EFF)),
              const SizedBox(width: 6),
              Text(L.get('loading_slots_visual'), style: TextStyle(fontSize: 12, color: context.textSecondary)),
              const SizedBox(width: 4),
              Text('($usedSlots/${widget.line.loadingSlots})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4B9EFF))),
            ]);
          }),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: List.generate(widget.line.loadingSlots, (idx) {
              final occupied = idx < widget.vehicles.length;
              final v = occupied ? widget.vehicles[idx] : null;
              return Tooltip(
                message: occupied ? "${v!.vehicleId} - ${v!.status}" : L.get('slot_empty'),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: occupied
                        ? (v!.status == 'مخالفة' ? const Color(0xFFFF5A5F) : const Color(0xFF00C897))
                        : context.bgColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: occupied
                          ? (v!.status == 'مخالفة' ? const Color(0xFFFF5A5F) : const Color(0xFF00C897))
                          : context.dividerColor,
                      width: 1.5,
                    ),
                  ),
                  child: Center(child: Text('${idx + 1}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                          color: occupied ? Colors.white : context.textSecondary))),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
        ],
        const SizedBox(height: 10),
        TextField(
          onChanged: (v) => setState(() => _search = v.trim()),
          decoration: InputDecoration(
            hintText: L.get('search_plate_owner'),
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF8A93A8)),
            filled: true,
            fillColor: context.bgColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.dividerColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
          ),
        ),
        const SizedBox(height: 8),
        if (_filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(L.get('no_vehicles_found'), style: TextStyle(fontSize: 12, color: context.textSecondary)),
          )
        else
          ...(_filtered.map((v) {
            int daysLeft = -999;
            bool hasExpiry = v.loadingExpiry.isNotEmpty;
            if (hasExpiry) {
              try {
                final p = v.loadingExpiry.split('-');
                final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
                daysLeft = d.difference(DateTime.now()).inDays;
              } catch (_) {}
            }
            final expiryColor = !hasExpiry ? const Color(0xFF8A93A8)
                : daysLeft < 0 ? const Color(0xFFFF5A5F)
                : daysLeft <= 3 ? const Color(0xFFFFB347)
                : const Color(0xFF00C897);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: context.bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.dividerColor),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    const Icon(Icons.directions_car_outlined, size: 15, color: Color(0xFF4B9EFF)),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(v.vehicleId, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary)),
                      if (v.ownerName.isNotEmpty)
                        Text(v.ownerName, style: TextStyle(fontSize: 10, color: context.textSecondary)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: v.status == 'محظورة'
                            ? const Color(0xFFFF5A5F).withValues(alpha: 0.1)
                            : const Color(0xFF00C897).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(v.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                          color: v.status == 'محظورة' ? const Color(0xFFFF5A5F) : const Color(0xFF00C897))),
                    ),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: expiryColor.withValues(alpha: 0.06),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    border: Border(top: BorderSide(color: context.dividerColor)),
                  ),
                  child: Row(children: [
                    Icon(Icons.local_shipping_outlined, size: 13, color: expiryColor),
                    const SizedBox(width: 6),
                    Expanded(child: Text(
                      !hasExpiry
                          ? '${L.get('loading_expiry_label')}: ${L.get('not_specified')}'
                          : '${L.get('loading_expiry_label')}: ${v.loadingExpiry}  •  ${daysLeft < 0 ? "${L.get('expired_days_ago')} ${daysLeft.abs()} ${L.get('day_word')}" : daysLeft == 0 ? L.get('expires_today') : "${L.get('days_left')} $daysLeft ${L.get('day_word')}"}',
                      style: TextStyle(fontSize: 10, color: expiryColor, fontWeight: FontWeight.w600),
                    )),
                    _Tap(
                      onTap: () {
                        final ctrl = TextEditingController(text: v.loadingExpiry);
                        showDialog(
                          context: context,
                          builder: (_) => StatefulBuilder(
                            builder: (ctx, setDlg) => Directionality(
                              textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                              child: AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text(L.get('edit_loading_date'),
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ctx.textPrimary)),
                                content: Column(mainAxisSize: MainAxisSize.min, children: [
                                  TextField(
                                    controller: ctrl,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: L.get('date_format'),
                                      prefixIcon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF2D3A5C)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: ctx.dividerColor)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
                                    ),
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now().add(const Duration(days: 1)),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2,"0")}-${picked.day.toString().padLeft(2,"0")}';
                                        setDlg(() {});
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(spacing: 8, runSpacing: 6, children: [1, 3, 7, 14, 30].map((days) {
                                    return _Tap(
                                      onTap: () {
                                        final base = ctrl.text.isNotEmpty ? () {
                                          try {
                                            final p = ctrl.text.split('-');
                                            final d = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
                                            return d.isAfter(DateTime.now()) ? d : DateTime.now();
                                          } catch (_) { return DateTime.now(); }
                                        }() : DateTime.now();
                                        final nd = base.add(Duration(days: days));
                                        ctrl.text = '${nd.year}-${nd.month.toString().padLeft(2,"0")}-${nd.day.toString().padLeft(2,"0")}';
                                        setDlg(() {});
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4B9EFF).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: const Color(0xFF4B9EFF).withValues(alpha: 0.3)),
                                        ),
                                        child: Text('+$days ${L.get('day_word')}',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF4B9EFF), fontWeight: FontWeight.bold)),
                                      ),
                                    );
                                  }).toList()),
                                ]),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(L.get('cancel'), style: TextStyle(color: ctx.textSecondary)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D3A5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                    onPressed: () {
                                      for (int li = 0; li < globalVehicles.length; li++) {
                                        for (int vi = 0; vi < globalVehicles[li].length; vi++) {
                                          if (globalVehicles[li][vi].vehicleId == v.vehicleId) {
                                            final old = globalVehicles[li][vi];
                                            globalVehicles[li][vi] = LineVehicle(
                                              number: old.number, vehicleId: old.vehicleId,
                                              status: old.status, note: old.note, ownerName: old.ownerName,
                                              carLicExpiry: old.carLicExpiry, insuranceExpiry: old.insuranceExpiry,
                                              operatingLicNum: old.operatingLicNum, operatingLicDate: old.operatingLicDate,
                                              rfidTag: old.rfidTag, loadingExpiry: ctrl.text.trim(),
                                            );
                                          }
                                        }
                                      }
                                      autoSave();
                                      Navigator.pop(context);
                                      setState(() {});
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
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3A5C).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF2D3A5C)),
                      ),
                    ),
                  ]),
                ),
              ]),
            );
          })),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   color;
  const _InfoRow({required this.icon, required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF8A93A8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(fontSize: 12, color: c)),
        Expanded(child: Text(value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                color: color ?? context.textPrimary),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}