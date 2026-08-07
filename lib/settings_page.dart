part of station_app;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with DarkModeRebuild<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = false;

  Future<void> _resetAllData() async {
    globalVehicles.clear();
    globalLines.clear();
    globalUsers.clear();
    globalEvents.clear();
    globalSecurityNotifications.clear();
    globalGates.clear();
    globalOrders.clear();
    globalDeliveryRequests.clear();

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 26)),
            const SizedBox(width: 12),
            Expanded(child: Text(L.get('danger_warning'),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18))),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(L.get('will_delete'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ]),
                  const SizedBox(height: 10),
                  _deleteItem(L.get('del_vehicles_lines')),
                  _deleteItem(L.get('del_users')),
                  _deleteItem(L.get('del_events')),
                  _deleteItem(L.get('del_gates')),
                  _deleteItem(L.get('del_notifs')),
                  _deleteItem(L.get('del_profile')),
                ]),
              ),
              const SizedBox(height: 16),
              Text(L.get('irreversible'),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L.get('cancel'), style: const TextStyle(color: Colors.grey))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.delete_forever, color: Colors.white, size: 18),
              label: Text(L.get('delete_all'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final confirm2 = await showDialog<bool>(
                  context: context,
                  builder: (_) => Directionality(
                    textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                    child: AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text(L.get('delete_confirm'),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      content: Text(L.get('delete_second_confirm')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(L.get('cancel'), style: const TextStyle(color: Colors.grey))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(L.get('delete_ok'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                );
                if (confirm2 != true) return;
                await _resetAllData();
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Row(children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(L.get('data_deleted'),
                        textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr),
                  ]),
                  backgroundColor: const Color(0xFF2E7D32),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
                Future.delayed(const Duration(seconds: 2), () {
                  if (context.mounted) Navigator.pushAndRemoveUntil(
                      context, MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── تغيير كلمة مرور الأدمن ──────────────────
  void _showChangePassword(BuildContext context) {
    final oldCtrl  = TextEditingController();
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    bool oldVis = false, newVis = false, confVis = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => Directionality(
          textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3A5C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF2D3A5C), size: 22)),
              const SizedBox(width: 10),
              Text(L.get('change_password'),
                  style: TextStyle(color: ctx.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (errorMsg != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(errorMsg!, style: const TextStyle(fontSize: 12, color: Colors.red))),
                    ]),
                  ),
                ],
                // كلمة المرور الحالية
                _PassField(
                  ctrl: oldCtrl,
                  label: L.isArabic ? 'كلمة المرور الحالية' : 'Current password',
                  visible: oldVis,
                  onToggle: () => setDlg(() => oldVis = !oldVis),
                  ctx: ctx,
                ),
                const SizedBox(height: 14),
                // كلمة المرور الجديدة
                _PassField(
                  ctrl: newCtrl,
                  label: L.get('new_password'),
                  visible: newVis,
                  onToggle: () => setDlg(() => newVis = !newVis),
                  ctx: ctx,
                ),
                const SizedBox(height: 14),
                // تأكيد كلمة المرور
                _PassField(
                  ctrl: confCtrl,
                  label: L.get('confirm_password'),
                  visible: confVis,
                  onToggle: () => setDlg(() => confVis = !confVis),
                  ctx: ctx,
                ),
              ]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(L.get('cancel'), style: TextStyle(color: ctx.textSecondary))),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3A5C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                label: Text(L.get('save'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final old  = oldCtrl.text.trim();
                  final nw   = newCtrl.text.trim();
                  final conf = confCtrl.text.trim();

                  if (old != adminPassword) {
                    setDlg(() => errorMsg = L.isArabic ? 'كلمة المرور الحالية غير صحيحة' : 'Current password is incorrect');
                    return;
                  }
                  if (nw.isEmpty) {
                    setDlg(() => errorMsg = L.get('val_pass_required'));
                    return;
                  }
                  if (nw.length < 8) {
                    setDlg(() => errorMsg = L.get('val_pass_short'));
                    return;
                  }
                  if (!nw.contains(RegExp(r'[A-Z]'))) {
                    setDlg(() => errorMsg = L.get('val_pass_upper'));
                    return;
                  }
                  if (!nw.contains(RegExp(r'[0-9]'))) {
                    setDlg(() => errorMsg = L.get('val_pass_number'));
                    return;
                  }
                  if (nw != conf) {
                    setDlg(() => errorMsg = L.get('passwords_not_match'));
                    return;
                  }

                  adminPassword = nw;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('admin_password', adminPassword);

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Row(children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(L.get('password_changed'),
                          textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr),
                    ]),
                    backgroundColor: const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ));
                }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: const BoxDecoration(color: Color(0xFF2D3A5C)),
          child: Row(children: [
            Expanded(child: Text(L.get('settings'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
          ]),
        ),
        Expanded(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── الحساب ──────────────────
                _SettingsSectionTitle(title: L.get('account')),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.person_outline,
                    label: L.get('profile'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF8A93A8)),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _ProfilePage()))),
                ]),

                const SizedBox(height: 20),

                // ── الإشعارات ───────────────
                _SettingsSectionTitle(title: L.get('notif_section')),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: L.get('notif_enable'),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      activeTrackColor: const Color(0xFF2D3A5C),
                      activeThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey[300],
                      inactiveThumbColor: Colors.white,
                      onChanged: (v) => setState(() {
                        _notificationsEnabled = v;
                        if (!v) _soundEnabled = false;
                      }))),
                  if (_notificationsEnabled) ...[
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.volume_up_outlined,
                      label: L.get('notif_sound'),
                      trailing: Switch(
                        value: _soundEnabled,
                        activeTrackColor: const Color(0xFF2D3A5C),
                        activeThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[300],
                        inactiveThumbColor: Colors.white,
                        onChanged: (v) => setState(() => _soundEnabled = v))),
                  ],
                ]),

                const SizedBox(height: 20),

                // ── التطبيق ─────────────────
                _SettingsSectionTitle(title: L.isArabic ? 'التطبيق' : 'App'),
                _SettingsCard(children: [
                  ValueListenableBuilder<String>(
                    valueListenable: langNotifier,
                    builder: (_, lang, __) => _SettingsTile(
                      icon: Icons.language_outlined,
                      label: lang == 'ar' ? L.get('lang_ar') : L.get('lang_en'),
                      trailing: Switch(
                        value: lang == 'en',
                        activeTrackColor: const Color(0xFF2D3A5C),
                        activeThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey[300],
                        inactiveThumbColor: Colors.white,
                        onChanged: (v) {
                          langNotifier.value = v ? 'en' : 'ar';
                          SharedPreferences.getInstance()
                              .then((p) => p.setString('lang', v ? 'en' : 'ar'));
                        }))),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    label: L.get('dark_mode'),
                    trailing: Switch(
                      value: darkModeNotifier.value,
                      activeTrackColor: const Color(0xFF2D3A5C),
                      activeThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey[300],
                      inactiveThumbColor: Colors.white,
                      onChanged: (v) {
                        darkModeNotifier.value = v;
                        SharedPreferences.getInstance().then((p) => p.setBool('dark_mode', v));
                      })),
                  _SettingsDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(Icons.text_fields_rounded, color: context.textPrimary, size: 22),
                        const SizedBox(width: 14),
                        Text(L.get('font_size'),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textPrimary)),
                        const Spacer(),
                        ValueListenableBuilder<double>(
                          valueListenable: fontSizeNotifier,
                          builder: (_, v, __) {
                            final label = v <= 1.0 ? L.get('font_normal')
                                : v <= 1.2 ? L.get('font_large') : L.get('font_xlarge');
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D3A5C).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10)),
                              child: Text(label, style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3A5C))));
                          }),
                      ]),
                      const SizedBox(height: 14),
                      ValueListenableBuilder<double>(
                        valueListenable: fontSizeNotifier,
                        builder: (_, cur, __) => Row(children: [
                          _FontSizeBtn(label: 'أ', size: 14, value: 1.0, current: cur),
                          const SizedBox(width: 10),
                          _FontSizeBtn(label: 'أ', size: 18, value: 1.2, current: cur),
                          const SizedBox(width: 10),
                          _FontSizeBtn(label: 'أ', size: 22, value: 1.4, current: cur),
                        ])),
                      const SizedBox(height: 10),
                      ValueListenableBuilder<double>(
                        valueListenable: fontSizeNotifier,
                        builder: (_, v, __) => Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: context.bgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.dividerColor)),
                          child: Text(L.get('font_preview'),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13 * v, color: context.textPrimary)))),
                    ]),
                  ),
                ]),

                const SizedBox(height: 20),

                // ── الأمان ──────────────────
                _SettingsSectionTitle(title: L.get('security_section')),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    label: L.get('change_password'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF8A93A8)),
                    onTap: () => _showChangePassword(context)),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.email_outlined,
                    label: L.get('admin_email'),
                    subtitle: adminEmail.isEmpty ? L.get('not_set') : adminEmail,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF8A93A8)),
                    onTap: () => _changeAdminEmail(context)),
                ]),

                const SizedBox(height: 20),

                // ── إدارة البيانات ──────────
                _SettingsSectionTitle(title: L.get('data_mgmt')),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.delete_sweep_outlined,
                    label: L.get('clear_data'),
                    labelColor: Colors.red,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red),
                    onTap: () => _showResetDataConfirm(context)),
                ]),

                const SizedBox(height: 20),

                // ── النظام ──────────────────
                _SettingsSectionTitle(title: L.get('system')),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.info_outline,
                    label: L.get('about_app'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF8A93A8)),
                    onTap: () => _showAbout(context)),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.logout,
                    label: L.get('logout'),
                    labelColor: Colors.red,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red),
                    onTap: () => _showLogoutConfirm(context)),
                ]),

                const SizedBox(height: 30),
                Center(child: Text(L.get('app_version'),
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]))),
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
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => Directionality(
          textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFF2D3A5C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.email_outlined, color: Color(0xFF2D3A5C), size: 20)),
              const SizedBox(width: 10),
              Text(L.get('admin_email'),
                  style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(L.get('admin_email_note'),
                  style: TextStyle(fontSize: 12, color: ctx.textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: L.isArabic ? 'البريد الإلكتروني' : 'Email address',
                  hintText: L.get('admin_email_hint'),
                  prefixIcon: const Icon(Icons.email_outlined, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
                ),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(L.get('cancel'), style: TextStyle(color: ctx.textSecondary))),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D3A5C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                icon: const Icon(Icons.check, color: Colors.white, size: 18),
                label: Text(L.get('save'), style: const TextStyle(color: Colors.white)),
                onPressed: () async {
                  adminEmail = emailCtrl.text.trim();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('admin_email', adminEmail);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      adminEmail.isEmpty
                          ? L.get('email_removed')
                          : '${L.get('email_saved')}: $adminEmail',
                      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr),
                    backgroundColor: const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ));
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.hardEdge,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0D1B35), Color(0xFF2D3A5C), Color(0xFF1E3A5F)],
                  begin: Alignment.topRight, end: Alignment.bottomLeft)),
              child: Column(children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2)),
                  child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 38)),
                const SizedBox(height: 14),
                Text(L.get('app_title'),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(L.get('app_subtitle'),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                  child: Text(L.get('app_version'),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
              ])),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                _aboutRow(context, Icons.location_on_outlined,
                    L.isArabic ? 'المحطة' : 'Station', L.get('station_name'), const Color(0xFF4B9EFF)),
                const SizedBox(height: 10),
                _aboutRow(context, Icons.nfc_rounded,
                    L.isArabic ? 'التقنية المستخدمة' : 'Technology', L.get('technology'), const Color(0xFF00C897)),
                const SizedBox(height: 10),
                _aboutRow(context, Icons.school_outlined,
                    L.isArabic ? 'الجامعة' : 'University', L.get('university'), const Color(0xFFFFB347)),
                const SizedBox(height: 10),
                _aboutRow(context, Icons.emoji_events_outlined,
                    L.isArabic ? 'النوع' : 'Type', L.get('project_type'), const Color(0xFFB47AFF)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3A5C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: () => Navigator.pop(context),
                    child: Text(L.get('ok'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)))),
              ])),
          ]),
        ),
      ),
    );
  }

  Widget _aboutRow(BuildContext context, IconData icon, String label, String value, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 13, color: context.textPrimary, fontWeight: FontWeight.w500)),
          ])),
        ]),
      );

  void _showLogoutConfirm(BuildContext context) {
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
                  color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20)),
            const SizedBox(width: 10),
            Text(L.get('logout'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          content: Text(L.get('logout_confirm'), style: const TextStyle(fontSize: 14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L.get('cancel'), style: TextStyle(color: context.textSecondary))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
              label: Text(L.isArabic ? 'خروج' : 'Logout',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () async {
                await saveAllData();
                if (!context.mounted) return;
                Navigator.pop(context);
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => const LoginPage()));
              }),
          ],
        ),
      ),
    );
  }
}

// ── حقل كلمة المرور ──────────────────────────
class _PassField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool visible;
  final VoidCallback onToggle;
  final BuildContext ctx;
  const _PassField({required this.ctrl, required this.label, required this.visible, required this.onToggle, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ctx.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        obscureText: !visible,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF2D3A5C)),
          suffixIcon: IconButton(
            icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18, color: Colors.grey),
            onPressed: onToggle),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: ctx.dividerColor)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF2D3A5C))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    ]);
  }
}

// ── Settings helper widgets ───────────────────
class _SettingsSectionTitle extends StatelessWidget {
  final String title;
  const _SettingsSectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8A93A8))));
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
    child: Column(children: children));
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
      height: 1, thickness: 1,
      color: Colors.grey.withValues(alpha: 0.1), indent: 52);
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final Widget trailing;
  final VoidCallback? onTap;
  const _SettingsTile({
    required this.icon, required this.label, required this.trailing,
    this.subtitle, this.labelColor, this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(icon, color: labelColor ?? context.textPrimary, size: 22),
    title: Text(label, style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, color: labelColor ?? context.textPrimary)),
    subtitle: subtitle != null
        ? Text(subtitle!, style: TextStyle(fontSize: 11, color: context.textSecondary))
        : null,
    trailing: trailing);
}

class _FontSizeBtn extends StatelessWidget {
  final String label;
  final double size, value, current;
  const _FontSizeBtn({required this.label, required this.size, required this.value, required this.current});
  @override
  Widget build(BuildContext context) {
    final selected = (current - value).abs() < 0.05;
    return Expanded(child: _Tap(
      onTap: () {
        fontSizeNotifier.value = value;
        SharedPreferences.getInstance().then((p) => p.setDouble('font_size', value));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2D3A5C) : context.bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? const Color(0xFF2D3A5C) : context.dividerColor,
              width: selected ? 2 : 1)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label, textScaler: TextScaler.noScaling,
              style: TextStyle(fontSize: size, fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : context.textPrimary)),
          const SizedBox(height: 4),
          Text(
            value <= 1.0 ? L.get('font_normal') : value <= 1.2 ? L.get('font_large') : L.get('font_xlarge'),
            textScaler: TextScaler.noScaling,
            style: TextStyle(fontSize: 10, color: selected ? Colors.white70 : context.textSecondary)),
        ]))));
  }
}