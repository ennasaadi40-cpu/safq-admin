// ════════════════════════════════════════════════════════════════
//  main.dart — Entry point
// ════════════════════════════════════════════════════════════════

library station_app;

import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

// ── Logic ──────────────────────────────────────────────────────
part 'logic.dart';
part 'localization.dart';

// ── Shared UI Widgets ──────────────────────────────────────────
part 'app_shared_widgets.dart';
part 'station_app_widget.dart';
part 'dashboard_widgets.dart';

// ── Pages ──────────────────────────────────────────────────────
part 'login_page.dart';
part 'forgot_password_pages.dart';
part 'admin_dashboard.dart';
part 'users_page.dart';
part 'user_info_page.dart';
part 'add_user_page.dart';
part 'edit_user_page.dart';
part 'vehicles_page.dart';
part 'vehicle_info_page.dart';
part 'add_vehicle_page.dart';
part 'edit_vehicle_page.dart';
part 'lines_page.dart';
part 'violations_page.dart';
part 'add_violation_page.dart';
part 'edit_violation_page.dart';
part 'reports_page.dart';
part 'gates_management_page.dart';
part 'gate_scanner_page.dart';
part 'notifications_page.dart';
part 'profile_page.dart';
part 'settings_page.dart';
part 'requests_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ⚠️⚠️⚠️ حذف البيانات القديمة - احذف هذه الأسطر بعد أول تشغيل ⚠️⚠️⚠️
  final prefsTemp = await SharedPreferences.getInstance();
  await prefsTemp.clear();
  print('✅ تم حذف جميع البيانات القديمة من SharedPreferences');
  // ⚠️⚠️⚠️ نهاية الكود المؤقت - احذف حتى هنا بعد أول تشغيل ⚠️⚠️⚠️
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCOsb6PStcSZY5k_YQctGVEIfoP8TuU-ug',
      appId: '1:521790557172:android:fa36035ea1233058ecc7a1',
      messagingSenderId: '521790557172',
      projectId: 'safq-station',
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final savedPass = prefs.getString('admin_password');
  if (savedPass != null && savedPass.isNotEmpty) adminPassword = savedPass;
  final savedEmail = prefs.getString('admin_email');
  if (savedEmail != null) adminEmail = savedEmail;

  final savedFont = prefs.getDouble('font_size');
  if (savedFont != null) fontSizeNotifier.value = savedFont;
  final savedDark = prefs.getBool('dark_mode');
  if (savedDark != null) darkModeNotifier.value = savedDark;

  await LineStorage.instance.load();
  await loadGates();
  globalUsers  = await UserStorage.instance.load();
  globalEvents = await EventStorage.instance.load();

  // حذف المستخدمين بدور "مالك سيارة" — المالك أصبح في بيانات المركبة
  globalUsers = globalUsers.where((u) => u.role != 'مالك سيارة').toList();
  await UserStorage.instance.save(globalUsers);

  await loadOrders();
  await loadDeliveryRequests();

  // تحميل بيانات وهمية إذا ما في بيانات محفوظة
  if (globalLines.isEmpty && globalUsers.isEmpty) {
    loadDummyData();
    await saveAllData();
  }

  runApp(const StationApp());
}


