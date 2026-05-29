part of station_app;

// ═══════════════════════════════════════════════════════════════════
//  ثوابت الحالات
// ═══════════════════════════════════════════════════════════════════
const String STATUS_IN_LINE = 'في الخط';
const String STATUS_WAITING = 'في الانتظار';
const String STATUS_READY = 'جاهزة';
const String STATUS_BANNED = 'محظورة';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with DarkModeRebuild<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    _DashboardBody(),
    _GateScannerPage(),
    LinesPage(),
    UsersPage(),
    VehiclesPage(),
    ViolationsPage(),
    RequestsPage(),
    ReportsPage(),
    SettingsPage(),
  ];

  List<_NavItem> get _navItems => [
    _NavItem(icon: Icons.home_outlined,           label: L.get('dashboard')),
    _NavItem(icon: Icons.qr_code_scanner_rounded, label: L.get('gates')),
    _NavItem(icon: Icons.route_outlined,          label: L.get('lines')),
    _NavItem(icon: Icons.people_outline,          label: L.get('users')),
    _NavItem(icon: Icons.directions_car_outlined, label: L.get('vehicles')),
    _NavItem(icon: Icons.warning_amber_outlined,  label: L.get('violations')),
    _NavItem(icon: Icons.inbox_outlined,          label: L.get('requests')),
    _NavItem(icon: Icons.bar_chart_outlined,      label: L.get('reports')),
    _NavItem(icon: Icons.settings_outlined,       label: L.get('settings')),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: context.bgColor,
        body: _pages[_selectedIndex],
        bottomNavigationBar: _BottomNav(
          items: _navItems,
          selectedIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Dashboard body
// ─────────────────────────────────────────────
class _DashboardBody extends StatefulWidget {
  const _DashboardBody();
  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> with DarkModeRebuild<_DashboardBody> {

  int get _totalVehicles => globalVehicles.fold(0, (s, l) => s + l.length);
  int get _totalLines    => globalLines.length;
  int get _totalUsers    => globalUsers.length;
  int get _violations    => globalEvents.where((e) => e.type == EventType.violation).length;
  int get _waiting       => globalVehicles.fold(0, (s, l) => s + l.where((v) => v.status == STATUS_WAITING).length);
  int get _ready         => globalVehicles.fold(0, (s, l) => s + l.where((v) => v.status == STATUS_READY).length);
  int get _banned        => globalVehicles.fold(0, (s, l) => s + l.where((v) => v.status == STATUS_BANNED).length);
  int get _activeUsers   => globalVehicles.fold(0, (s, l) => s + l.where((v) => v.status == STATUS_IN_LINE).length);

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return L.get('greeting_morning');
    if (h < 17) return L.get('greeting_afternoon');
    return L.get('greeting_evening');
  }

  String _dateString() {
    final now = DateTime.now();
    final dayKey   = 'day_${now.weekday % 7}';
    final monthKey = 'month_${now.month}';
    final dayName   = L.get(dayKey);
    final monthName = L.get(monthKey);
    return '$dayName، ${now.day} $monthName ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ══ HERO HEADER ══════════════════════════════════════════
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1B35), Color(0xFF1B2A4A), Color(0xFF243560)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Stack(children: [
              Positioned(top: -30, left: -30, child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.03)),
              )),
              Positioned(bottom: -20, right: 40, child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF4B9EFF).withValues(alpha: 0.08)),
              )),
              Positioned(top: 20, left: 80, child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00C897).withValues(alpha: 0.06)),
              )),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // شريط علوي
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined, color: Colors.white54, size: 11),
                        const SizedBox(width: 5),
                        Text(_dateString(), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ]),
                    ),
                    const Spacer(),
                    _Tap(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _NotificationsPage())),
                      child: Stack(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 19),
                        ),
                        if (globalEvents.isNotEmpty)
                          Positioned(top: 5, left: 5, child: Container(
                            width: 9, height: 9,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4D6D),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF0D1B35), width: 1.5),
                            ),
                          )),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    _Tap(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _ProfilePage())),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFF4B9EFF), Color(0xFF00C897)]),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
                        ),
                        child: profileImageBytes != null
                            ? ClipOval(child: Image.memory(Uint8List.fromList(profileImageBytes!), fit: BoxFit.cover))
                            : const Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // التحية
                  Text(_greeting(), style: const TextStyle(color: Colors.white38, fontSize: 13, letterSpacing: 0.3)),
                  const SizedBox(height: 4),
                  Text(profileName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
                  const SizedBox(height: 4),
                  Text(L.get('station_name'), style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
                  const SizedBox(height: 24),

                  // بطاقات الإحصاء
                  Row(children: [
                    _statChip('$_totalVehicles', L.get('vehicle'),   Icons.directions_car_rounded, const Color(0xFF4B9EFF)),
                    const SizedBox(width: 10),
                    _statChip('$_totalLines',    L.get('line'),      Icons.route_rounded,           const Color(0xFF00C897)),
                    const SizedBox(width: 10),
                    _statChip('$_totalUsers',    L.get('user'),      Icons.people_rounded,          const Color(0xFFFFB347)),
                    const SizedBox(width: 10),
                    _statChip('$_violations',    L.get('complaint'), Icons.warning_rounded,
                        _violations > 0 ? const Color(0xFFFF4D6D) : const Color(0xFF8A93A8)),
                  ]),
                ]),
              ),
            ]),
          ),

          // ══ BODY ════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              Row(children: [
                _quickCard(icon: Icons.person_rounded, label: L.get('in_line'),
                    value: _activeUsers, accent: const Color(0xFF4B9EFF), darkBg: const Color(0xFF0D1E35)),
                const SizedBox(width: 12),
                _quickCard(icon: Icons.block_rounded, label: L.get('banned'),
                    value: _banned, accent: const Color(0xFFFF4D6D), darkBg: const Color(0xFF2C0A12)),
              ]),
              const SizedBox(height: 24),

              _sectionTitle('🚗 ${L.get('vehicle_status')}', '', const Color(0xFF00C897)),
              const SizedBox(height: 10),
              _VehiclesPieChart(ready: _ready, waiting: _waiting, banned: _banned),
              const SizedBox(height: 24),

              _sectionTitle('📊 ${L.get('event_stats')}', '', const Color(0xFF4B9EFF)),
              const SizedBox(height: 10),
              _EventsBarChart(events: globalEvents),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, IconData icon, Color accent) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: accent, size: 20),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10)),
      ]),
    ),
  );

  Widget _quickCard({required IconData icon, required String label, required int value,
      required Color accent, required Color darkBg}) {
    final isDark = context.isDark;
    final bg = isDark ? darkBg : accent.withValues(alpha: 0.07);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accent)),
            Text(label, style: TextStyle(fontSize: 11, color: accent.withValues(alpha: 0.8))),
          ]),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title, String badge, Color color) => Row(children: [
    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary)),
    const Spacer(),
    if (badge.isNotEmpty)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(badge, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
      ),
  ]);
}

// ─────────────────────────────────────────────
//  Pie Chart
// ─────────────────────────────────────────────
class _VehiclesPieChart extends StatelessWidget {
  final int ready, waiting, banned;
  const _VehiclesPieChart({required this.ready, required this.waiting, required this.banned});

  @override
  Widget build(BuildContext context) {
    final total = ready + waiting + banned;
    final segments = [
      _PieSegment(L.get('ready'),   ready,   const Color(0xFF00C897)),
      _PieSegment(L.get('waiting'), waiting, const Color(0xFFFFB347)),
      _PieSegment(L.get('banned'),  banned,  const Color(0xFFFF5A5F)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: total == 0
          ? Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(L.get('no_vehicles'), style: TextStyle(color: context.textSecondary, fontSize: 13)),
            ))
          : Row(children: [
              SizedBox(
                width: 110, height: 110,
                child: CustomPaint(painter: _PiePainter(segments: segments, total: total)),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: segments.map((s) {
                    final pct = total > 0 ? (s.value / total * 100).toStringAsFixed(1) : '0';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        Container(width: 12, height: 12,
                          decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s.label, style: TextStyle(fontSize: 13, color: context.textPrimary))),
                        Text('${s.value}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: s.color)),
                        const SizedBox(width: 4),
                        Text('($pct%)', style: TextStyle(fontSize: 11, color: context.textSecondary)),
                      ]),
                    );
                  }).toList(),
                ),
              ),
            ]),
    );
  }
}

class _PieSegment {
  final String label;
  final int value;
  final Color color;
  const _PieSegment(this.label, this.value, this.color);
}

class _PiePainter extends CustomPainter {
  final List<_PieSegment> segments;
  final int total;
  const _PiePainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    double startAngle = -3.14159 / 2;
    for (final s in segments) {
      if (s.value == 0) continue;
      final sweep = 2 * 3.14159 * s.value / total;
      canvas.drawArc(rect, startAngle, sweep, true,
          Paint()..color = s.color..style = PaintingStyle.fill);
      startAngle += sweep;
    }
    canvas.drawCircle(rect.center, size.width * 0.28,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_PiePainter old) => true;
}

// ─────────────────────────────────────────────
//  Bar Chart
// ─────────────────────────────────────────────
class _EventsBarChart extends StatelessWidget {
  final List<EventItem> events;
  const _EventsBarChart({required this.events});

  @override
  Widget build(BuildContext context) {
    final entry     = events.where((e) => e.type == EventType.entry).length;
    final exit      = events.where((e) => e.type == EventType.exit).length;
    final violation = events.where((e) => e.type == EventType.violation).length;

    final bars = [
      _BarData(L.get('entry'),     entry,     const Color(0xFF00C897)),
      _BarData(L.get('exit'),      exit,      const Color(0xFF4B9EFF)),
      _BarData(L.get('violation'), violation, const Color(0xFFFF5A5F)),
    ];
    final maxVal = [entry, exit, violation].fold(0, (a, b) => b > a ? b : a);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: events.isEmpty
          ? Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(L.get('no_events'), style: TextStyle(color: context.textSecondary, fontSize: 13)),
            ))
          : Column(children: [
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: bars.map((b) {
                    final ratio = maxVal > 0 ? b.value / maxVal : 0.0;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${b.value}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: b.color)),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: 48,
                          height: (ratio * 100).clamp(6.0, 100.0),
                          decoration: BoxDecoration(
                            color: b.color,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: context.dividerColor),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: bars.map((b) => Row(children: [
                  Container(width: 10, height: 10,
                      decoration: BoxDecoration(color: b.color, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(b.label, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                ])).toList(),
              ),
            ]),
    );
  }
}

class _BarData {
  final String label;
  final int value;
  final Color color;
  const _BarData(this.label, this.value, this.color);
}