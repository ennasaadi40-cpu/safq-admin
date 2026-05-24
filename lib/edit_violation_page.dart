part of station_app;

class _EditViolationPage extends StatefulWidget {
  final String vehicleId;
  final String violationNum;
  final String violationName;
  final String message;
  final String amount;
  const _EditViolationPage({
    required this.vehicleId,
    this.violationNum = '',
    this.violationName = '',
    this.message = '',
    this.amount = '',
  });
  @override
  State<_EditViolationPage> createState() => _EditViolationPageState();
}

class _EditViolationPageState extends State<_EditViolationPage> with DarkModeRebuild<_EditViolationPage> {
  final _formKey    = GlobalKey<FormState>();
  late final _numCtrl    = TextEditingController(text: widget.violationNum);
  late final _nameCtrl   = TextEditingController(text: widget.violationName);
  late final _msgCtrl    = TextEditingController(text: widget.message);
  late final _amountCtrl = TextEditingController(text: widget.amount);
  
  InputDecoration _inputDec(String hint) => InputDecoration(
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D3A5C),
          elevation: 0,
          title: Text(L.get('edit_violation'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.dividerColor),
                  ),
                  child: Text(L.get('edit_violation'),
                      style: TextStyle(color: context.textSecondary, fontSize: 14)),
                ),
                const SizedBox(height: 20),

                _label(L.get('complaint_number')),
                TextFormField(
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  controller: _numCtrl,
                  textDirection: TextDirection.ltr,
                  decoration: _inputDec(L.get('enter_violation_num')),
                  validator: (v) => v == null || v.isEmpty ? L.get('required') : null,
                ),
                const SizedBox(height: 16),

                _label(L.get('violation_type')),
                TextFormField(
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  controller: _nameCtrl,
                  decoration: _inputDec(L.get('enter_violation_name')),
                  validator: (v) => v == null || v.isEmpty ? L.get('required') : null,
                ),
                const SizedBox(height: 16),

                _label(L.get('violation_description')),
                TextFormField(
                  onEditingComplete: () => FocusScope.of(context).nextFocus(),
                  controller: _msgCtrl,
                  decoration: _inputDec(L.get('enter_violation_message')),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                _label(L.get('violation_amount_shekel')),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  decoration: _inputDec(L.get('enter_default_amount')),
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 32),

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
                      logEvent(EventItem(
                        vehicleId: widget.vehicleId,
                        location: '${L.get('edit_violation')}: ${_nameCtrl.text.trim()}',
                        time: nowTime(),
                        type: EventType.violation,
                        violationNote: '${L.get('violation_value')} = ${_amountCtrl.text.trim()} ${L.get('shekel')}',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(L.get('violation_updated'), 
                            textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr),
                        backgroundColor: const Color(0xFF2D3A5C),
                      ));
                      Navigator.pop(context);
                    },
                    child: Text(L.get('save_violation'),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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