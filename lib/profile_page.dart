part of station_app;

class _ProfilePage extends StatefulWidget {
  const _ProfilePage();
  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> with DarkModeRebuild<_ProfilePage> {

  void _editField(String label, String current, void Function(String) onSave) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('${L.get('edit')} $label',
              style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textDirection: label == L.get('phone') || label == 'Email'
                ? TextDirection.ltr : TextDirection.rtl,
            keyboardType: label == L.get('phone') ? TextInputType.phone
                : label == 'Email' ? TextInputType.emailAddress
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: '${L.get('enter_name')} $label',
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.dividerColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L.get('cancel'), style: TextStyle(color: context.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  setState(() => onSave(ctrl.text.trim()));
                }
                Navigator.pop(context);
              },
              child: Text(L.get('save'),
                  style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => profileImageBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          backgroundColor: context.bgColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: context.textPrimary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(L.get('profile'),
              style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: const Color(0xFF2D3A5C).withValues(alpha: 0.12),
                    backgroundImage: profileImageBytes != null
                        ? MemoryImage(Uint8List.fromList(profileImageBytes!))
                        : null,
                    child: profileImageBytes == null
                        ? const Icon(Icons.person, size: 64, color: Color(0xFF2D3A5C))
                        : null,
                  ),
                  _Tap(
                    onTap: _pickImage,
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D3A5C),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(profileName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: context.textPrimary)),
              const SizedBox(height: 4),
              Text(profileEmail,
                  style: TextStyle(fontSize: 13, color: context.textSecondary)),
              const SizedBox(height: 30),

              _EditableProfileRow(
                icon: Icons.person_outline,
                label: L.get('full_name'),
                value: profileName,
                onTap: () => _editField(L.get('full_name'), profileName, (v) => profileName = v),
              ),
              _EditableProfileRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: profileEmail,
                onTap: () => _editField('Email', profileEmail, (v) => profileEmail = v),
              ),
              _EditableProfileRow(
                icon: Icons.phone_outlined,
                label: L.get('phone'),
                value: profilePhone,
                onTap: () => _editField(L.get('phone'), profilePhone, (v) => profilePhone = v),
              ),
              _EditableProfileRow(
                icon: Icons.badge_outlined,
                label: L.get('role'),
                value: 'Admin',
                onTap: null,
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                child: Material(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => Directionality(
                          textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                          child: AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            title: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(L.get('logout'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ]),
                            content: Text(L.get('logout_confirm'),
                                style: const TextStyle(fontSize: 14)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(L.get('cancel'),
                                    style: TextStyle(color: Colors.grey[600])),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                                label: Text(L.get('logout'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (confirm != true) return;
                      await saveAllData();
                      if (!context.mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Text(L.get('logout'),
                              style: const TextStyle(color: Colors.red,
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _EditableProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Tap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: context.cardColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: context.textSecondary, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(fontSize: 11, color: context.textSecondary)),
                      const SizedBox(height: 2),
                      Text(value,
                          style: TextStyle(fontSize: 15, color: context.textPrimary)),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.edit_outlined, size: 16, color: context.textSecondary),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: context.dividerColor),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  const _ProfileInfoRow({required this.icon, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: context.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(value,
                    style: TextStyle(fontSize: 15, color: context.textPrimary)),
              ),
              Icon(icon, color: context.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}