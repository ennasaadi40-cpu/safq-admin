part of station_app;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with DarkModeRebuild<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = false;

  // ── دالة حذف كل البيانات ────────────────────────
  Future<void> _resetAllData() async {
    globalVehicles.clear();
    globalLines.clear();
    globalUsers.clear();
    globalEvents.clear();
    globalSecurityNotifications.clear();
    globalGates.clear();
    globalRequests.clear();

    profileName = 'المدير';
    profileImageBytes = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lines_data');
    await prefs.remove('users_data');
    await prefs.remove('events_data');
    await prefs.remove('gates_data');
    await prefs.remove('external_requests');
    await prefs.remove('profile_name');
    await prefs.remove('profile_image');
    // نحافظ على كلمة السر الحالية صريحاً
    await prefs.setString('admin_password', adminPassword);
  }

  Widget _deleteItem(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      const Icon(Icons.circle, size: 6, color: Colors.red),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 12)),
    ]),
  );

  void _showResetDataConfirm(BuildContext context) {
    final passwordCtrl = TextEditingController();
    bool passwordVisible = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 26)),
              const SizedBox(width: 12),
              const Expanded(child: Text('⚠️ تحذير خطير', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18))),
            ]),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withValues(alpha: 0.2))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20), SizedBox(width: 8), Text('سيتم حذف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
                    const SizedBox(height: 10),
                    _deleteItem('جميع المركبات والخطوط'),
                    _deleteItem('جميع المستخدمين'),
                    _deleteItem('جميع الأحداث والسجلات'),
                    _deleteItem('جميع البوابات'),
                    _deleteItem('الإشعارات والتنبيهات'),
                    _deleteItem('بيانات الحساب الشخصي'),
                  ]),
                ),
                const SizedBox(height: 16),
                const Text('⚠️ هذا الإجراء لا يمكن التراجع عنه!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 16),
                const Text('أدخل كلمة مرور المدير للتأكيد:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: !passwordVisible,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: 'كلمة مرور المدير',
                    hintStyle: const TextStyle(fontSize: 13),
                    suffixIcon: IconButton(icon: Icon(passwordVisible ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: () => setDlg(() => passwordVisible = !passwordVisible)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                  ),
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                icon: const Icon(Icons.delete_forever, color: Colors.white, size: 18),
                label: const Text('حذف كل شي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  if (passwordCtrl.text != adminPassword) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور خاطئة!', textDirection: TextDirection.rtl), backgroundColor: Colors.red));
                    return;
                  }
                  await _resetAllData();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Row(children: const [Icon(Icons.check_circle, color: Colors.white, size: 20), SizedBox(width: 10), Text('تم حذف جميع البيانات بنجاح ✓', textDirection: TextDirection.rtl)]),
                    backgroundColor: const Color(0xFF2E7D32), duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16),
                  ));
                  Future.delayed(const Duration(seconds: 2), () {
                    if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: const BoxDecoration(color: Color(0xFF2D3A5C)),
          child: const Row(children: [Expanded(child: Text('الإعدادات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)))]),
        ),
        Expanded(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SettingsSectionTitle(title: 'الحساب'),
                _SettingsCard(children: [
                  _SettingsTile(icon: Icons.person_outline, label: 'الملف الشخصي', trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF8A93A8)), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _ProfilePage()))),

                ]),

                const SizedBox(height: 20),
                _SettingsSectionTitle(title: 'الإشعارات'),
                _SettingsCard(children: [
                  _SettingsTile(icon: Icons.notifications_outlined, label: 'تفعيل الإشعارات',
                    trailing: Switch(value: _notificationsEnabled, activeTrackColor: const Color(0xFF2D3A5C), activeThumbColor: Colors.white, inactiveTrackColor: Colors.grey[300], inactiveThumbColor: Colors.white,
                      onChanged: (v) => setState(() { _notificationsEnabled = v; if (!v) _soundEnabled = false; }))),
                  if (_notificationsEnabled) ...[
                    _SettingsDivider(),
                    _SettingsTile(icon: Icons.volume_up_outlined, label: 'صوت الإشعارات',
                      trailing: Switch(value: _soundEnabled, activeTrackColor: const Color(0xFF2D3A5C), activeThumbColor: Colors.white, inactiveTrackColor: Colors.grey[300], inactiveThumbColor: Colors.white,
                        onChanged: (v) => setState(() => _soundEnabled = v))),
                  ],
                ]),
                const SizedBox(height: 20),
                _SettingsSectionTitle(title: 'التطبيق'),
                _SettingsCard(children: [
                  ValueListenableBuilder<String>(valueListenable: langNotifier, builder: (_, lang, __) => _SettingsTile(icon: Icons.language_outlined, label: lang == 'ar' ? 'اللغة — عربي' : 'اللغة — English',
                    trailing: Switch(value: lang == 'en', activeTrackColor: const Color(0xFF2D3A5C), activeThumbColor: Colors.white, inactiveTrackColor: Colors.grey[300], inactiveThumbColor: Colors.white,
                      onChanged: (v) { langNotifier.value = v ? 'en' : 'ar'; SharedPreferences.getInstance().then((p) => p.setString('lang', v ? 'en' : 'ar')); }))),
                  _SettingsDivider(),
                  _SettingsTile(icon: Icons.dark_mode_outlined, label: 'الوضع الليلي',
                    trailing: Switch(value: darkModeNotifier.value, activeTrackColor: const Color(0xFF2D3A5C), activeThumbColor: Colors.white, inactiveTrackColor: Colors.grey[300], inactiveThumbColor: Colors.white,
                      onChanged: (v) { darkModeNotifier.value = v; SharedPreferences.getInstance().then((p) => p.setBool('dark_mode', v)); })),
                  _SettingsDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.text_fields_rounded, color: context.textPrimary, size: 22), const SizedBox(width: 14),
                        Text('حجم الخط', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textPrimary)),
                        const Spacer(),
                        ValueListenableBuilder<double>(valueListenable: fontSizeNotifier, builder: (_, v, __) {
                          final label = v <= 1.0 ? 'عادي' : v <= 1.2 ? 'كبير' : 'كبير جداً';
                          return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF2D3A5C).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3A5C))));
                        }),
                      ]),
                      const SizedBox(height: 14),
                      ValueListenableBuilder<double>(valueListenable: fontSizeNotifier, builder: (_, cur, __) => Row(children: [
                        _FontSizeBtn(label: 'أ', size: 14, value: 1.0, current: cur), const SizedBox(width: 10),
                        _FontSizeBtn(label: 'أ', size: 18, value: 1.2, current: cur), const SizedBox(width: 10),
                        _FontSizeBtn(label: 'أ', size: 22, value: 1.4, current: cur),
                      ])),
                      const SizedBox(height: 10),
                      ValueListenableBuilder<double>(valueListenable: fontSizeNotifier, builder: (_, v, __) => Container(
                        width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: context.bgColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: context.dividerColor)),
                        child: Text('معاينة: نظام إدارة المحطة', textAlign: TextAlign.center, style: TextStyle(fontSize: 13 * v, color: context.textPrimary)))),
                    ]),
                  ),
                ]),
                const SizedBox(height: 20),
                _SettingsSectionTitle(title: 'الأمان'),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.email_outlined,
                    label: 'إيميل الأدمن',
                    subtitle: adminEmail.isEmpty ? 'غير محدد' : adminEmail,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF8A93A8)),
                    onTap: () => _changeAdminEmail(context),
                  ),

                ]),
                const SizedBox(height: 20),
                _SettingsSectionTitle(title: 'إدارة البيانات'),
                _SettingsCard(children: [
                  _SettingsTile(icon: Icons.delete_sweep_outlined, label: 'مسح جميع البيانات', labelColor: Colors.red,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red), onTap: () => _showResetDataConfirm(context)),
                ]),
                const SizedBox(height: 20),
                _SettingsSectionTitle(title: 'النظام'),
                _SettingsCard(children: [
                  _SettingsTile(icon: Icons.info_outline, label: 'عن التطبيق', trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF8A93A8)), onTap: () => _showAbout(context)),
                  _SettingsDivider(),
                  _SettingsTile(icon: Icons.logout, label: 'تسجيل الخروج', labelColor: Colors.red, trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red), onTap: () => _showLogoutConfirm(context)),
                ]),
                const SizedBox(height: 30),
                Center(child: Text('الإصدار 1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey[400]))),
                const SizedBox(height: 10),
              ]),
            ),
          ),
        ),
      ]),
    );
  }



  void _changeAdminEmail(BuildContext context) {
    final emailCtrl = TextEditingController(text: adminEmail);
    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, setDlg) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF2D3A5C).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.email_outlined, color: Color(0xFF2D3A5C), size: 20)),
          const SizedBox(width: 10),
          Text('إيميل الأدمن', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('إذا حُدِّد الإيميل يُشترط إدخاله عند تسجيل الدخول.\nاتركه فارغاً لإلغاء الاشتراط.',
              style: TextStyle(fontSize: 12, color: ctx.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني',
              hintText: 'admin@example.com',
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: TextStyle(color: ctx.textSecondary))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D3A5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.check, color: Colors.white, size: 18),
            label: const Text('حفظ', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              adminEmail = emailCtrl.text.trim();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('admin_email', adminEmail);
              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(adminEmail.isEmpty ? 'تم إزالة اشتراط الإيميل' : 'تم حفظ الإيميل: $adminEmail',
                    textDirection: TextDirection.rtl),
                backgroundColor: const Color(0xFF2E7D32),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ));
            }),
        ],
      ),
    )));
  }





  void _showAbout(BuildContext context) {
    showDialog(context: context, builder: (_) => Directionality(textDirection: TextDirection.rtl, child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), clipBehavior: Clip.hardEdge,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0D1B35), Color(0xFF2D3A5C), Color(0xFF1E3A5F)], begin: Alignment.topRight, end: Alignment.bottomLeft)),
          child: Column(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2)),
              child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 38)),
            const SizedBox(height: 14),
            const Text('نظام إدارة المحطة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('نظام إدارة طابور باستخدام تقنية RFID', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
              child: const Text('الإصدار 1.0.0', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
          ])),
        Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          _aboutRow(context, Icons.location_on_outlined, 'المحطة', 'محطة الحافلات المركزية — الخليل', const Color(0xFF4B9EFF)),
          const SizedBox(height: 10),
          _aboutRow(context, Icons.nfc_rounded, 'التقنية المستخدمة', 'RFID — تحديد الهوية بالترددات الراديوية', const Color(0xFF00C897)),
          const SizedBox(height: 10),
          _aboutRow(context, Icons.school_outlined, 'الجامعة', 'جامعة فلسطين التقنية — خضوري', const Color(0xFFFFB347)),
          const SizedBox(height: 10),
          _aboutRow(context, Icons.emoji_events_outlined, 'النوع', 'مشروع تخرج — هندسة الحاسوب', const Color(0xFFB47AFF)),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D3A5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)))),
        ])),
      ]),
    )));
  }

  Widget _aboutRow(BuildContext context, IconData icon, String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, color: context.textPrimary, fontWeight: FontWeight.w500)),
      ])),
    ]),
  );

  void _showLogoutConfirm(BuildContext context) {
    showDialog(context: context, builder: (_) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20)),
        const SizedBox(width: 10), const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
      content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟\nسيتم حفظ جميع البيانات.', style: TextStyle(fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: TextStyle(color: context.textSecondary))),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18), label: const Text('خروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () async {
            await saveAllData();
            if (!context.mounted) return;
            Navigator.pop(context);
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
          }),
      ],
    )));
  }
}

// ── Settings helper widgets ───────────────────
class _SettingsSectionTitle extends StatelessWidget {
  final String title;
  const _SettingsSectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8A93A8))));
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: context.cardColor, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
    child: Column(children: children));
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(height: 1, thickness: 1, color: Colors.grey.withValues(alpha: 0.1), indent: 52);
}

class _SettingsTile extends StatelessWidget {
  final IconData icon; final String label; final String? subtitle; final Color? labelColor; final Widget trailing; final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.label, required this.trailing, this.subtitle, this.labelColor, this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(onTap: onTap,
    leading: Icon(icon, color: labelColor ?? context.textPrimary, size: 22),
    title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor ?? context.textPrimary)),
    subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 11, color: context.textSecondary)) : null,
    trailing: trailing);
}

class _FontSizeBtn extends StatelessWidget {
  final String label; final double size, value, current;
  const _FontSizeBtn({required this.label, required this.size, required this.value, required this.current});
  @override
  Widget build(BuildContext context) {
    final selected = (current - value).abs() < 0.05;
    return Expanded(child: _Tap(
      onTap: () { fontSizeNotifier.value = value; SharedPreferences.getInstance().then((p) => p.setDouble('font_size', value)); },
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: selected ? const Color(0xFF2D3A5C) : context.bgColor, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF2D3A5C) : context.dividerColor, width: selected ? 2 : 1)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label, textScaler: TextScaler.noScaling, style: TextStyle(fontSize: size, fontWeight: FontWeight.bold, color: selected ? Colors.white : context.textPrimary)),
          const SizedBox(height: 4),
          Text(value <= 1.0 ? 'عادي' : value <= 1.2 ? 'كبير' : 'كبير جداً', textScaler: TextScaler.noScaling,
            style: TextStyle(fontSize: 10, color: selected ? Colors.white70 : context.textSecondary)),
        ]))));
  }
}