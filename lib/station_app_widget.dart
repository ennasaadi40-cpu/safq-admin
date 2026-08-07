part of station_app;

class StationApp extends StatelessWidget {
  const StationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: fontSizeNotifier,
      builder: (_, fontSize, __) => ValueListenableBuilder<bool>(
        valueListenable: darkModeNotifier,
        builder: (_, isDark, ___) => ValueListenableBuilder<String>(
          valueListenable: langNotifier,
          builder: (_, lang, __) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(fontSize)),
            child: MaterialApp(
              title: 'Admin Control Panel',
              debugShowCheckedModeBanner: false,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

              // ← التعديلات المضافة
              locale: Locale(lang),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('ar'),
                Locale('en'),
              ],

              theme: ThemeData(
                brightness: Brightness.light,
                textTheme: GoogleFonts.tajawalTextTheme(),
                fontFamily: GoogleFonts.tajawal().fontFamily,
                scaffoldBackgroundColor: const Color(0xFFF4F6FA),
                colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D3A5C)),
                listTileTheme: const ListTileThemeData(mouseCursor: WidgetStateMouseCursor.clickable),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                textTheme: GoogleFonts.tajawalTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
                fontFamily: GoogleFonts.tajawal().fontFamily,
                scaffoldBackgroundColor: const Color(0xFF10182E),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF4A6FA5),
                  brightness: Brightness.dark,
                ),
                cardColor: const Color(0xFF2A3A63),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF10182E),
                  foregroundColor: Colors.white,
                ),
                listTileTheme: const ListTileThemeData(mouseCursor: WidgetStateMouseCursor.clickable),
              ),

              home: const LoginPage(),
            ),
          ),
        ),
      ),
    );
  }
}

// ── مساعد Responsive ─────────────────────────
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static double fontSize(BuildContext context, double base) {
    final w = MediaQuery.of(context).size.width;
    if (w < 360) return base * 0.85;
    if (w < 600) return base;
    if (w < 1024) return base * 1.1;
    return base * 1.2;
  }

  static EdgeInsets padding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 360) return const EdgeInsets.all(10);
    if (w < 600) return const EdgeInsets.all(16);
    return const EdgeInsets.all(24);
  }
}