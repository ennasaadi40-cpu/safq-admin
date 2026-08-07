part of station_app;

class _GatesManagementPage extends StatefulWidget {
  const _GatesManagementPage();
  @override
  State<_GatesManagementPage> createState() => _GatesManagementPageState();
}

class _GatesManagementPageState extends State<_GatesManagementPage> with DarkModeRebuild<_GatesManagementPage> {
  final _floorCtrl  = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _ipCtrl     = TextEditingController();
  String _type = 'مدخل';

  @override
  void dispose() {
    _floorCtrl.dispose(); _numberCtrl.dispose(); _ipCtrl.dispose(); super.dispose();
  }

  void _addGate() {
    final floor  = _floorCtrl.text.trim();
    final number = _numberCtrl.text.trim();
    if (floor.isEmpty || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.get('val_floor_required'),
            textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr),
        backgroundColor: const Color(0xFFFF5A5F),
      ));
      return;
    }
    final newGate = GateModel(
      id:     '${DateTime.now().millisecondsSinceEpoch}',
      floor:  floor,
      type:   _type,
      number: number,
      ip:     _ipCtrl.text.trim(),
    );
    setState(() => globalGates.add(newGate));
    _floorCtrl.clear(); _numberCtrl.clear(); _ipCtrl.clear();
    autoSave();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${L.get('gate_added')} ${newGate.label}',
          textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr),
      backgroundColor: const Color(0xFF00C897),
    ));
  }

  void _deleteGate(GateModel gate) {
    showDialog(context: context, builder: (_) => Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(L.get('delete_gate')),
        content: Text('${L.get('delete_gate_confirm')} ${gate.label}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text(L.get('cancel'))),
          TextButton(
            onPressed: () {
              setState(() => globalGates.remove(gate));
              autoSave();
              Navigator.pop(context);
            },
            child: Text(L.get('delete'),
                style: const TextStyle(color: Color(0xFFFF5A5F))),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D3A5C),
          foregroundColor: Colors.white,
          title: Text(L.get('gates'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Add New Gate ────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4B9EFF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_rounded,
                        size: 16, color: Color(0xFF4B9EFF)),
                  ),
                  const SizedBox(width: 8),
                  Text(L.get('add_new_gate'), style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14,
                      color: Color(0xFF4B9EFF))),
                ]),
                const SizedBox(height: 16),

                // Floor Number
                Text(L.get('floor_number'), style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: context.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _floorCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: L.get('floor_example'),
                    hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.layers_outlined,
                        color: Color(0xFF4B9EFF), size: 18),
                    filled: true, fillColor: context.bgColor,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.dividerColor)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF4B9EFF), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),

                // Gate Type — Entrance / Exit
                Text(L.get('gate_type'), style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: context.textSecondary)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: _typeBtn('مدخل', Icons.login_rounded,
                      const Color(0xFF00C897))),
                  const SizedBox(width: 10),
                  Expanded(child: _typeBtn('مخرج', Icons.logout_rounded,
                      const Color(0xFFFF5A5F))),
                ]),
                const SizedBox(height: 12),

                // Gate Number
                Text(L.get('gate_number'), style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: context.textSecondary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _numberCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: L.get('gate_num_example'),
                    hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.sensor_door_outlined,
                        color: Color(0xFF4B9EFF), size: 18),
                    filled: true, fillColor: context.bgColor,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.dividerColor)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF4B9EFF), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 12),

                // IP Address
                const Text('IP Address', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _ipCtrl,
                  keyboardType: TextInputType.url,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addGate(),
                  style: TextStyle(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: L.get('ip_example'),
                    hintStyle: TextStyle(color: context.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.lan_outlined,
                        color: Color(0xFF4B9EFF), size: 18),
                    filled: true, fillColor: context.bgColor,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: context.dividerColor)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Color(0xFF4B9EFF), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addGate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3A5C),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    label: Text(L.get('add_gate'),
                        style: const TextStyle(color: Colors.white, fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Existing Gates ──────────────────────
            Row(children: [
              Text(L.get('added_gates'), style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15,
                  color: context.textPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3A5C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${globalGates.length} ${L.get('gate_word')}',
                    style: const TextStyle(fontSize: 12,
                        color: Color(0xFF2D3A5C), fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 10),

            if (globalGates.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  Icon(Icons.sensor_door_outlined,
                      size: 40, color: context.textSecondary),
                  const SizedBox(height: 8),
                  Text(L.get('no_gates_added'),
                      style: TextStyle(color: context.textSecondary)),
                ]),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                ),
                child: Column(
                  children: globalGates.asMap().entries.map((entry) {
                    final i    = entry.key;
                    final gate = entry.value;
                    final isLast = i == globalGates.length - 1;
                    final color = gate.type == 'مدخل'
                        ? const Color(0xFF00C897)
                        : const Color(0xFFFF5A5F);
                    return Column(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              gate.type == 'مدخل'
                                  ? Icons.login_rounded
                                  : Icons.logout_rounded,
                              color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(gate.label, style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold,
                                  color: context.textPrimary)),
                              Text(
                                '${L.get('floor')} ${gate.floor}  •  '
                                '${gate.type == 'مدخل' ? L.get('entrance') : L.get('exit_gate')}  •  '
                                '${L.get('gate_number')} ${gate.number}',
                                style: TextStyle(fontSize: 11,
                                    color: context.textSecondary)),
                              if (gate.ip.isNotEmpty)
                                Text('IP: ${gate.ip}',
                                    style: const TextStyle(
                                        fontSize: 11, color: Color(0xFF4B9EFF))),
                            ],
                          )),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            // Edit button
                            InkWell(
                              onTap: () => _editGate(gate),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4B9EFF).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.edit_outlined,
                                    color: Color(0xFF4B9EFF), size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delete button
                            InkWell(
                              onTap: () => _deleteGate(gate),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5A5F).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.delete_outline_rounded,
                                    color: Color(0xFFFF5A5F), size: 18),
                              ),
                            ),
                          ]),
                        ]),
                      ),
                      if (!isLast) Divider(height: 1, indent: 70,
                          color: context.dividerColor),
                    ]);
                  }).toList(),
                ),
              ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  void _editGate(GateModel gate) {
    final floorCtrl  = TextEditingController(text: gate.floor);
    final numberCtrl = TextEditingController(text: gate.number);
    String type = gate.type;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => Directionality(
          textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(L.get('edit_gate'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              // Floor Number
              TextField(
                controller: floorCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: L.get('floor_number'),
                  prefixIcon: const Icon(Icons.layers_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),

              // Gate Type
              Row(children: [
                Expanded(child: _dlgTypeBtn('مدخل', type, (v) => setDlg(() => type = v))),
                const SizedBox(width: 8),
                Expanded(child: _dlgTypeBtn('مخرج', type, (v) => setDlg(() => type = v))),
              ]),
              const SizedBox(height: 12),

              // Gate Number
              TextField(
                controller: numberCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: L.get('gate_number'),
                  prefixIcon: const Icon(Icons.sensor_door_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(L.get('cancel')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3A5C),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final floor  = floorCtrl.text.trim();
                  final number = numberCtrl.text.trim();
                  if (floor.isEmpty || number.isEmpty) return;
                  final idx = globalGates.indexOf(gate);
                  if (idx >= 0) {
                    setState(() {
                      globalGates[idx] = GateModel(
                        id:     gate.id,
                        floor:  floor,
                        type:   type,
                        number: number,
                        ip:     gate.ip,
                      );
                    });
                    autoSave();
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(L.get('gate_updated'),
                        textDirection: L.isArabic
                            ? TextDirection.rtl
                            : TextDirection.ltr),
                    backgroundColor: const Color(0xFF00C897),
                  ));
                },
                child: Text(L.get('save'),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dlgTypeBtn(String label, String current, ValueChanged<String> onTap) {
    final selected = label == current;
    final color = label == 'مدخل' ? const Color(0xFF00C897) : const Color(0xFFFF5A5F);
    return GestureDetector(
      onTap: () => onTap(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(label == 'مدخل' ? Icons.login_rounded : Icons.logout_rounded,
              size: 15, color: selected ? color : Colors.grey),
          const SizedBox(width: 5),
          Text(
            label == 'مدخل' ? L.get('entrance') : L.get('exit_gate'),
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold,
              color: selected ? color : Colors.grey,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _typeBtn(String label, IconData icon, Color color) => _Tap(
    onTap: () => setState(() => _type = label),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: _type == label ? color.withValues(alpha: 0.12) : context.bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _type == label ? color : context.dividerColor,
          width: _type == label ? 1.5 : 1,
        ),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 16,
            color: _type == label ? color : context.textSecondary),
        const SizedBox(width: 6),
        Text(
          label == 'مدخل' ? L.get('entrance') : L.get('exit_gate'),
          style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold,
            color: _type == label ? color : context.textSecondary,
          ),
        ),
      ]),
    ),
  );
}