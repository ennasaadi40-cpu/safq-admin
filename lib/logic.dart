part of station_app;
// ignore: unused_import

// ════════════════════════════════════════════════════════════════
//  logic.dart — Models, Storage, Global State, Helpers
// ════════════════════════════════════════════════════════════════

String adminPassword = 'Admin123';
String adminEmail    = ''; // فارغ = لا يُشترط

final ValueNotifier<bool>   darkModeNotifier  = ValueNotifier(false);
ValueNotifier<double>       fontSizeNotifier  = ValueNotifier(1.0);

String     profileName        = 'مدير النظام';
String     profileEmail       = 'admin@station.ps';
String     profilePhone       = '';
List<int>? profileImageBytes;

List<EventItem>          globalEvents          = [];
List<UserModel>          globalUsers           = [];
List<LineModel>          globalLines           = [];
List<Map<String,String>> globalSecurityNotifications = [];
List<List<LineVehicle>>  globalVehicles        = [];

enum EventType  { entry, exit, violation }

abstract class BaseModel {
  final String id;
  String status;
  BaseModel({required this.id, this.status = ''});
  bool get isEnabled => status == 'فعال' || status == 'نشط' || status == 'جاهزة';
  String get summary;
  @override
  String toString() => '$runtimeType(id: $id, status: $status)';
}

abstract class BaseStorage<T> {
  final String storageKey;
  BaseStorage({required this.storageKey});
  String encode(T item);
  T decode(String raw);

  Future<List<T>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(storageKey);
    if (saved == null) return loadDefaults();
    return saved.map(decode).toList();
  }

  Future<void> saveAll(List<T> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(storageKey, items.map(encode).toList());
  }

  List<T> loadDefaults() => [];
}

mixin SearchFilterMixin<T> {
  String searchQuery = '';
  String activeFilter = 'الكل';
  List<String> get filterOptions;
  bool itemMatchesSearch(T item, String query);
  bool itemMatchesFilter(T item, String filter);

  List<T> applyFilter(List<T> all) {
    return all.where((item) {
      final matchSearch = searchQuery.isEmpty || itemMatchesSearch(item, searchQuery);
      final matchFilter = activeFilter == 'الكل' || itemMatchesFilter(item, activeFilter);
      return matchSearch && matchFilter;
    }).toList();
  }
}

mixin DarkModeRebuild<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    darkModeNotifier.addListener(_onDarkModeChanged);
    fontSizeNotifier.addListener(_onDarkModeChanged);
    langNotifier.addListener(_onDarkModeChanged);
  }
  void _onDarkModeChanged() { if (mounted) setState(() {}); }
  @override
  void dispose() {
    darkModeNotifier.removeListener(_onDarkModeChanged);
    fontSizeNotifier.removeListener(_onDarkModeChanged);
    langNotifier.removeListener(_onDarkModeChanged);
    super.dispose();
  }
}

extension AppThemeContext on BuildContext {
  bool  get isDark        => Theme.of(this).brightness == Brightness.dark;
  Color get bgColor       => isDark ? const Color(0xFF1A2540) : const Color(0xFFF5F5F5);
  Color get cardColor     => isDark ? const Color(0xFF243560) : Colors.white;
  Color get textPrimary   => isDark ? Colors.white : const Color(0xFF1A1A2E);
  Color get textSecondary => isDark ? Colors.white60 : Colors.black54;
  Color get dividerColor  => isDark ? Colors.white12 : Colors.black12;
}

class StatItem {
  final String label;
  final int    value;
  const StatItem({required this.label, required this.value});
}

class EventItem {
  final String    vehicleId;
  final String    location;
  final String    time;
  final EventType type;
  final String?   violationNote;
  final bool      feesPaid;
  final String?   allowedEntryDate;
  const EventItem({
    required this.vehicleId,
    required this.location,
    required this.time,
    required this.type,
    this.violationNote,
    this.feesPaid        = false,
    this.allowedEntryDate,
  });
  EventItem copyWith({bool? feesPaid, String? allowedEntryDate}) => EventItem(
    vehicleId: vehicleId, location: location, time: time, type: type,
    violationNote: violationNote,
    feesPaid: feesPaid ?? this.feesPaid,
    allowedEntryDate: allowedEntryDate ?? this.allowedEntryDate,
  );
}

class UserModel extends BaseModel {
  final String name;
  final String username;
  final String role;
  final String phone;
  final String idNumber;
  final String licenseNum;
  final String licenseExpiry;
  final String licenseGrade;
  final String medicalExpiry;
  final String phone2;
  final String macAddress;
  final bool   isActive;
  final String licenseIssueDate;
  String password;

  UserModel({
    required this.name,
    required this.role,
    required String status,
    this.username         = '',
    this.phone            = '',
    this.idNumber         = '',
    this.licenseNum       = '',
    this.licenseExpiry    = '',
    this.licenseGrade     = '',
    this.medicalExpiry    = '',
    this.phone2           = '',
    this.macAddress       = '',
    this.isActive         = true,
    this.licenseIssueDate = '',
    this.password         = '',
  }) : super(id: idNumber.isNotEmpty ? idNumber : name, status: status);

  @override
  String get summary => '$name ($role)';
}

class LineModel {
  final String       name;
  final String       subtitle;
  final String       supervisor;
  final List<String> drivers;
  final String       gateId;
  final String       entryGateId;
  final String       exitGateId;
  final String       fare;
  final int          loadingSlots;
  LineModel({
    required this.name,
    required this.subtitle,
    this.supervisor   = '',
    this.drivers      = const [],
    this.gateId       = '',
    this.entryGateId  = '',
    this.exitGateId   = '',
    this.fare         = '',
    this.loadingSlots = 0,
  });
}

// ✅ LineVehicle المحدّث مع جميع الحقول
class LineVehicle extends BaseModel {
  final int     number;
  final String  vehicleId;
  final String? note;
  final String  ownerName;
  final String  carLicExpiry;
  final String  insuranceExpiry;
  final String  operatingLicNum;
  final String  operatingLicDate;
  final String  rfidTag;
  final String  loadingExpiry;
  
  // ✅ الحقول الجديدة
  final String  maker;           // الشركة المصنعة
  final String  model;           // الطراز
  final String  year;            // سنة الإنتاج
  final String  chassis;         // رقم الشاصي
  final String  ownerPhone;      // هاتف المالك
  final String  ownerId;         // هوية المالك
  final String  driverName;      // اسم السائق

  LineVehicle({
    required this.number,
    required this.vehicleId,
    required String status,
    this.note,
    this.ownerName        = '',
    this.carLicExpiry     = '',
    this.insuranceExpiry  = '',
    this.operatingLicNum  = '',
    this.operatingLicDate = '',
    this.rfidTag          = '',
    this.loadingExpiry    = '',
    this.maker            = '',
    this.model            = '',
    this.year             = '',
    this.chassis          = '',
    this.ownerPhone       = '',
    this.ownerId          = '',
    this.driverName       = '',
  }) : super(id: vehicleId, status: status);

  @override
  String get summary => 'مركبة $vehicleId (${ownerName.isNotEmpty ? ownerName : "بدون مالك"})';
}

class VehicleModel {
  final int    id;
  final String owner;
  final String line;
  final String plateNumber;
  final String oldPlateNumber;
  final String rfidTag;
  final String carType;
  final String carModel;
  final String seats;
  final String operatingLicNum;
  final String operatingLicDate;
  final String carLicExpiry;
  final String insuranceExpiry;
  final String lineNumber;
  final String stationName;

  VehicleModel({
    required this.id,
    required this.owner,
    required this.line,
    required this.plateNumber,
    this.oldPlateNumber   = '',
    this.rfidTag          = '',
    this.carType          = '',
    this.carModel         = '',
    this.seats            = '',
    this.operatingLicNum  = '',
    this.operatingLicDate = '',
    this.carLicExpiry     = '',
    this.insuranceExpiry  = '',
    this.lineNumber       = '',
    this.stationName      = 'محطة الحافلات المركزية - الخليل',
  });
}

class EventStorage extends BaseStorage<EventItem> {
  EventStorage._() : super(storageKey: 'events_data');
  static final EventStorage instance = EventStorage._();

  @override
  EventItem decode(String raw) {
    final p    = raw.split('|');
    final type = EventType.values.firstWhere((e) => e.name == p[3], orElse: () => EventType.entry);
    return EventItem(
      vehicleId: p[0], location: p[1], time: p[2], type: type,
      violationNote: p.length > 4 && p[4].isNotEmpty ? p[4] : null,
      feesPaid: p.length > 5 && p[5] == '1',
    );
  }

  @override
  String encode(EventItem item) =>
      '${item.vehicleId}|${item.location}|${item.time}|${item.type.name}|${item.violationNote ?? ""}|${item.feesPaid ? "1" : "0"}';

  Future<void> save() => saveAll(globalEvents);
}

class UserStorage extends BaseStorage<UserModel> {
  UserStorage._() : super(storageKey: 'users_data');
  static final UserStorage instance = UserStorage._();

  static const List<Map<String, String>> _defaultUsers = [];

  @override
  UserModel decode(String raw) {
    final p = raw.split('|');
    return UserModel(
      name:             p[0],
      role:             p[1],
      status:           p[2],
      phone:            p.length > 3  ? p[3]  : '',
      idNumber:         p.length > 4  ? p[4]  : '',
      licenseNum:       p.length > 5  ? p[5]  : '',
      licenseExpiry:    p.length > 6  ? p[6]  : '',
      isActive:         p.length > 7  ? p[7] == '1' : true,
      password:         p.length > 8  ? p[8]  : '',
      licenseIssueDate: p.length > 9  ? p[9]  : '',
      licenseGrade:     p.length > 10 ? p[10] : '',
      username:         p.length > 11 ? p[11] : '',
      macAddress:       p.length > 12 ? p[12] : '',
    );
  }

  @override
  String encode(UserModel u) =>
      '${u.name}|${u.role}|${u.status}|${u.phone}|${u.idNumber}|${u.licenseNum}|'
      '${u.licenseExpiry}|${u.isActive ? "1" : "0"}|${u.password}|'
      '${u.licenseIssueDate}|${u.licenseGrade}|${u.username}|${u.macAddress}';

  @override
  List<UserModel> loadDefaults() => _defaultUsers
      .map((u) => UserModel(name: u['name']!, role: u['role']!, status: u['status']!))
      .toList();

  Future<void> save(List<UserModel> users) => saveAll(users);
}

class LineStorage {
  LineStorage._();
  static final LineStorage instance = LineStorage._();

  static const _linesKey    = 'lines_data';
  static const _vehiclesKey = 'vehicles_data';
  static const List<String> _defaultLines    = [];
  static const List<String> _defaultVehicles = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLines = prefs.getStringList(_linesKey);
    if (savedLines == null) {
      await prefs.setStringList(_linesKey, _defaultLines);
      globalLines = _parseLines(_defaultLines);
    } else {
      globalLines = _parseLines(savedLines);
    }
    final savedVehicles = prefs.getStringList(_vehiclesKey);
    if (savedVehicles == null) {
      await prefs.setStringList(_vehiclesKey, _defaultVehicles);
      globalVehicles = _parseVehicles(_defaultVehicles);
    } else {
      globalVehicles = _parseVehicles(savedVehicles);
    }
  }

  List<LineModel> _parseLines(List<String> raw) =>
      raw.map((s) {
        final p = s.split('|');
        return LineModel(
          name:         p[0],
          subtitle:     p[1],
          supervisor:   p.length > 2 ? p[2] : '',
          drivers:      p.length > 3 && p[3].isNotEmpty ? p[3].split(',') : [],
          fare:         p.length > 4 ? p[4] : '',
          loadingSlots: p.length > 5 ? (int.tryParse(p[5]) ?? 0) : 0,
        );
      }).toList();

  // ✅ _parseVehicles المحدّث لقراءة جميع الحقول
  List<List<LineVehicle>> _parseVehicles(List<String> raw) =>
      raw.map((lineStr) {
        if (lineStr.isEmpty) return <LineVehicle>[];
        return lineStr.split(',').where((s) => s.isNotEmpty).map((s) {
          final p = s.split(':');
          return LineVehicle(
            number:           int.tryParse(p[0]) ?? 1,
            vehicleId:        p[1],
            status:           p[2],
            note:             p.length > 3  && p[3].isNotEmpty  ? p[3]  : null,
            ownerName:        p.length > 4  ? p[4]  : '',
            carLicExpiry:     p.length > 5  ? p[5]  : '',
            insuranceExpiry:  p.length > 6  ? p[6]  : '',
            operatingLicNum:  p.length > 7  ? p[7]  : '',
            operatingLicDate: p.length > 8  ? p[8]  : '',
            rfidTag:          p.length > 9  ? p[9]  : '',
            loadingExpiry:    p.length > 10 ? p[10] : '',
            maker:            p.length > 11 ? p[11] : '',
            model:            p.length > 12 ? p[12] : '',
            year:             p.length > 13 ? p[13] : '',
            chassis:          p.length > 14 ? p[14] : '',
            ownerPhone:       p.length > 15 ? p[15] : '',
            ownerId:          p.length > 16 ? p[16] : '',
            driverName:       p.length > 17 ? p[17] : '',
          );
        }).toList();
      }).toList();

  // ✅ دالة save المحدّثة لحفظ جميع الحقول
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _linesKey,
      globalLines.map((l) =>
          '${l.name}|${l.subtitle}|${l.supervisor}|${l.drivers.join(",")}|${l.fare}|${l.loadingSlots}').toList(),
    );
    await prefs.setStringList(
      _vehiclesKey,
      globalVehicles.map((list) =>
          list.map((v) =>
              '${v.number}:${v.vehicleId}:${v.status}:${v.note ?? ""}:${v.ownerName}:'
              '${v.carLicExpiry}:${v.insuranceExpiry}:${v.operatingLicNum}:${v.operatingLicDate}:'
              '${v.rfidTag}:${v.loadingExpiry}:${v.maker}:${v.model}:${v.year}:${v.chassis}:'
              '${v.ownerPhone}:${v.ownerId}:${v.driverName}')
          .join(',')).toList(),
    );
  }
}

Future<void> saveAllData() async {
  await UserStorage.instance.save(globalUsers);
  await LineStorage.instance.save();
  await EventStorage.instance.save();
  await _saveGates();
}

void autoSave() {
  UserStorage.instance.save(globalUsers);
  LineStorage.instance.save();
  EventStorage.instance.save();
  _saveGates();
}

Future<void> _saveGates() async {
  final prefs = await SharedPreferences.getInstance();
  final list = globalGates.map((g) => jsonEncode(g.toJson())).toList();
  await prefs.setStringList('gates_v1', list);
}

Future<void> loadGates() async {
  final prefs = await SharedPreferences.getInstance();
  final list  = prefs.getStringList('gates_v1');
  if (list != null && list.isNotEmpty) {
    globalGates = list.map((s) => GateModel.fromJson(jsonDecode(s))).toList();
  }
}

void logEvent(EventItem event) {
  globalEvents.insert(0, event);
  if (globalEvents.length > 50) globalEvents.removeLast();
  autoSave();
}

String nowTime() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2,"0")}-${now.day.toString().padLeft(2,"0")} ${now.hour.toString().padLeft(2,"0")}:${now.minute.toString().padLeft(2,"0")}';
}

// استخرج التاريخ فقط من time string (يدعم HH:MM و YYYY-MM-DD HH:MM)
String eventDate(String time) {
  if (time.contains(' ')) return time.split(' ')[0];
  // قديم: بس وقت بدون تاريخ — نرجع اليوم كافتراضي
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2,"0")}-${now.day.toString().padLeft(2,"0")}';
}

// استخرج الوقت فقط من time string
String eventTime(String time) {
  if (time.contains(' ')) return time.split(' ')[1];
  return time;
}

String? validateDate(String? v, {bool required = true, bool mustBeFuture = false, bool mustBePast = false}) {
  if (v == null || v.trim().isEmpty) return required ? 'التاريخ مطلوب' : null;
  final s = v.trim();
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) return 'الصيغة غير صحيحة — مثال: 2025-06-15';
  final parts = s.split('-');
  final year  = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day   = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return 'تاريخ غير صالح';
  if (year < 2000 || year > 2100) return 'السنة بين 2000 و 2100';
  if (month < 1   || month > 12)  return 'الشهر بين 1 و 12';
  if (day < 1     || day > 31)    return 'اليوم بين 1 و 31';
  try {
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) return 'هذا اليوم غير موجود في هذا الشهر';
    if (mustBeFuture && date.isBefore(DateTime.now())) return 'يجب أن يكون في المستقبل';
    if (mustBePast  && date.isAfter(DateTime.now()))   return 'يجب أن يكون في الماضي';
  } catch (_) { return 'تاريخ غير صالح'; }
  return null;
}

String expiryStatus(String dateStr) {
  if (dateStr.isEmpty) return 'unknown';
  try {
    final p = dateStr.split('-');
    if (p.length != 3) return 'unknown';
    final d    = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    final diff = d.difference(DateTime.now()).inDays;
    if (diff < 0)   return 'expired';
    if (diff <= 30) return 'soon';
    return 'ok';
  } catch (_) { return 'unknown'; }
}

const List<Map<String, String>> kViolationTypes = [
  {'name': 'تجاوز الطابور',           'amount': '150'},
  {'name': 'شكوى وقوف',             'amount': '200'},
  {'name': 'حمولة زائدة',             'amount': '300'},
  {'name': 'قيادة بدون رخصة',         'amount': '500'},
  {'name': 'إزعاج الركاب',            'amount': '100'},
  {'name': 'عدم الالتزام بالمسار',     'amount': '250'},
  {'name': 'مخالفة أخرى',             'amount': '0'},
];

class GateModel {
  final String id;
  final String floor;
  final String type;
  final String number;
  final String ip;

  GateModel({
    required this.id,
    required this.floor,
    required this.type,
    required this.number,
    this.ip = '',
  });

  String get label => 'طابق $floor — $type $number';

  Map<String, dynamic> toJson() => {
    'id': id, 'floor': floor, 'type': type, 'number': number, 'ip': ip,
  };

  factory GateModel.fromJson(Map<String, dynamic> j) => GateModel(
    id:     j['id']     ?? '',
    floor:  j['floor']  ?? '',
    type:   j['type']   ?? 'مدخل',
    number: j['number'] ?? '',
    ip:     j['ip']     ?? '',
  );
}

List<GateModel> globalGates = [
  GateModel(id: 'g1', floor: '1', type: 'مدخل',  number: '1'),
  GateModel(id: 'g2', floor: '1', type: 'مخرج',  number: '1'),
  GateModel(id: 'g3', floor: '2', type: 'مدخل',  number: '1'),
  GateModel(id: 'g4', floor: '2', type: 'مخرج',  number: '1'),
];

Widget expiryBadge(String label, String dateStr, {bool compact = false}) {
  final status = expiryStatus(dateStr);
  if (status == 'unknown') return const SizedBox.shrink();
  final isExpired = status == 'expired';
  final color = isExpired ? const Color(0xFFFF5A5F) : const Color(0xFFFFB347);
  final text = compact
      ? (isExpired ? '$label منتهية' : '$label قريباً')
      : (isExpired ? 'انتهت $label' : '$label تنتهي قريباً');
  return Container(
    padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(text, style: TextStyle(
      fontSize: compact ? 10 : 11,
      color: color,
      fontWeight: FontWeight.bold,
    )),
  );
}

// ════════════════════════════════════════════════════════════════
//  Dummy Data — بيانات وهمية للعرض
// ════════════════════════════════════════════════════════════════
void loadDummyData() {
  // ── البوابات ─────────────────────────────
  globalGates = [
    GateModel(id: 'g1', floor: '1', type: 'مدخل', number: '1'),
    GateModel(id: 'g2', floor: '1', type: 'مخرج', number: '1'),
    GateModel(id: 'g3', floor: '2', type: 'مدخل', number: '2'),
    GateModel(id: 'g4', floor: '2', type: 'مخرج', number: '2'),
  ];

  // ── المستخدمون ───────────────────────────
  globalUsers = [
    UserModel(name: 'خالد كرم طرشان',   role: 'مشرف خط',  status: 'نشط', phone: '0592111001', idNumber: '123456789', isActive: true,  password: '1234'),
    UserModel(name: 'محمد أحمد العمر',   role: 'سائق',      status: 'نشط', phone: '0592111002', idNumber: '987654321', isActive: true,  password: '1234',
      licenseNum: 'DL-2021-001', licenseExpiry: '2026-08-15', licenseIssueDate: '2021-08-15', licenseGrade: 'D'),
    UserModel(name: 'أحمد إسماعيل الحج', role: 'سائق',      status: 'نشط', phone: '0592111003', idNumber: '112233445', isActive: true,  password: '1234',
      licenseNum: 'DL-2020-045', licenseExpiry: '2025-12-01', licenseIssueDate: '2020-12-01', licenseGrade: 'D'),
    UserModel(name: 'سامر يوسف ناصر',   role: 'سائق',      status: 'نشط', phone: '0592111004', idNumber: '556677889', isActive: true,  password: '1234',
      licenseNum: 'DL-2019-078', licenseExpiry: '2026-03-20', licenseIssueDate: '2019-03-20', licenseGrade: 'D'),
    UserModel(name: 'عمر فارس حلوم',    role: 'موظف أمن',  status: 'نشط', phone: '0592111005', idNumber: '334455667', isActive: true,  password: '1234'),
    UserModel(name: 'يوسف نادر سلامة',  role: 'مشرف خط',  status: 'نشط', phone: '0592111006', idNumber: '778899001', isActive: true,  password: '1234'),
  ];

  // ── الخطوط والمركبات ─────────────────────
  globalLines = [
    LineModel(name: '[101] الخليل → بيت لحم', subtitle: '3 في الانتظار', supervisor: 'خالد كرم طرشان',
      gateId: '101', entryGateId: 'g1', exitGateId: 'g2', fare: '8', loadingSlots: 5),
    LineModel(name: '[102] الخليل → القدس',   subtitle: '2 في الانتظار', supervisor: 'يوسف نادر سلامة',
      gateId: '102', entryGateId: 'g3', exitGateId: 'g4', fare: '15', loadingSlots: 4),
    LineModel(name: '[103] الخليل → رام الله', subtitle: '1 في الانتظار', supervisor: 'خالد كرم طرشان',
      gateId: '103', entryGateId: 'g1', exitGateId: 'g2', fare: '12', loadingSlots: 3),
  ];

  globalVehicles = [
    // خط 101
    [
      LineVehicle(
        number: 1, 
        vehicleId: '12-234-12', 
        status: 'في الخط',
        ownerName: 'محمود خليل أبو صالح',
        carLicExpiry: '2026-06-01', 
        insuranceExpiry: '2026-05-15', 
        loadingExpiry: '2025-08-01',
        operatingLicNum: 'OP-2023-1001',
        operatingLicDate: '2023-01-15',
        rfidTag: 'RFID-101-AAA',
        maker: 'Toyota',
        model: 'Hiace',
        year: '2018',
        chassis: 'JTD1234567890',
        ownerPhone: '0598765001',
        ownerId: '900111222',
        driverName: 'أحمد إسماعيل الحج',
      ),
      LineVehicle(
        number: 2, 
        vehicleId: '34-567-89', 
        status: 'في الانتظار', 
        ownerName: 'عمر فيصل الطويل',   
        carLicExpiry: '2025-11-20', 
        insuranceExpiry: '2025-10-10', 
        loadingExpiry: '2025-07-15',
        operatingLicNum: 'OP-2022-2045',
        operatingLicDate: '2022-05-20',
        rfidTag: 'RFID-101-BBB',
        maker: 'Mercedes',
        model: 'Sprinter',
        year: '2020',
        chassis: 'WDB9066091234567',
        ownerPhone: '0599876002',
        ownerId: '900222333',
        driverName: 'محمد أحمد العمر',
      ),
      LineVehicle(
        number: 3, 
        vehicleId: '56-789-01', 
        status: 'مخالفة',      
        ownerName: 'ياسر محمود الدبس',   
        carLicExpiry: '2026-02-28', 
        insuranceExpiry: '2026-01-05', 
        loadingExpiry: '2025-06-30',
        operatingLicNum: 'OP-2021-3078',
        operatingLicDate: '2021-08-10',
        rfidTag: 'RFID-101-CCC',
        maker: 'Hyundai',
        model: 'H350',
        year: '2019',
        chassis: 'KMJST35GBKU123456',
        ownerPhone: '0597654003',
        ownerId: '900333444',
        driverName: 'سامر يوسف ناصر',
      ),
    ],
    // خط 102
    [
      LineVehicle(
        number: 1, 
        vehicleId: '78-901-23', 
        status: 'في الخط',       
        ownerName: 'سعيد رامي حسونة',   
        carLicExpiry: '2026-09-10', 
        insuranceExpiry: '2026-08-20', 
        loadingExpiry: '2025-09-01',
        operatingLicNum: 'OP-2023-4123',
        operatingLicDate: '2023-03-05',
        rfidTag: 'RFID-102-AAA',
        maker: 'Ford',
        model: 'Transit',
        year: '2021',
        chassis: 'WF0VXXTTGVDC12345',
        ownerPhone: '0596543004',
        ownerId: '900444555',
        driverName: 'محمد أحمد العمر',
      ),
      LineVehicle(
        number: 2, 
        vehicleId: '90-123-45', 
        status: 'في الانتظار', 
        ownerName: 'طارق نبيل جرادات', 
        carLicExpiry: '2025-12-15', 
        insuranceExpiry: '2025-11-30', 
        loadingExpiry: '2025-08-20',
        operatingLicNum: 'OP-2022-5156',
        operatingLicDate: '2022-07-12',
        rfidTag: 'RFID-102-BBB',
        maker: 'Toyota',
        model: 'Coaster',
        year: '2017',
        chassis: 'JTGDE413507654321',
        ownerPhone: '0595432005',
        ownerId: '900555666',
        driverName: 'أحمد إسماعيل الحج',
      ),
    ],
    // خط 103
    [
      LineVehicle(
        number: 1, 
        vehicleId: '11-222-33', 
        status: 'جاهزة',       
        ownerName: 'بلال كمال شاهين',   
        carLicExpiry: '2026-07-05', 
        insuranceExpiry: '2026-06-15', 
        loadingExpiry: '2025-10-01',
        operatingLicNum: 'OP-2020-6189',
        operatingLicDate: '2020-11-25',
        rfidTag: 'RFID-103-AAA',
        maker: 'Mitsubishi',
        model: 'Rosa',
        year: '2016',
        chassis: 'JL6FE27J9AK098765',
        ownerPhone: '0594321006',
        ownerId: '900666777',
        driverName: 'سامر يوسف ناصر',
      ),
    ],
  ];

  // ── الأحداث ──────────────────────────────
  globalEvents = [
    EventItem(vehicleId: '12-234-12', location: '[101] الخليل → بيت لحم', time: '2025-05-19 08:30', type: EventType.entry),
    EventItem(vehicleId: '34-567-89', location: '[101] الخليل → بيت لحم', time: '2025-05-19 09:15', type: EventType.entry),
    EventItem(vehicleId: '56-789-01', location: '[101] الخليل → بيت لحم', time: '2025-05-19 10:00', type: EventType.violation, violationNote: 'تجاوز الطابور — 150 ₪'),
    EventItem(vehicleId: '78-901-23', location: '[102] الخليل → القدس',   time: '2025-05-19 07:45', type: EventType.entry),
    EventItem(vehicleId: '34-567-89', location: '[101] الخليل → بيت لحم', time: '2025-05-18 16:30', type: EventType.exit),
    EventItem(vehicleId: '90-123-45', location: '[102] الخليل → القدس',   time: '2025-05-18 14:20', type: EventType.entry),
    EventItem(vehicleId: '11-222-33', location: '[103] الخليل → رام الله', time: '2025-05-18 11:00', type: EventType.entry),
    EventItem(vehicleId: '56-789-01', location: '[101] الخليل → بيت لحم', time: '2025-05-17 09:30', type: EventType.violation, violationNote: 'حمولة زائدة — 300 ₪'),
  ];
}