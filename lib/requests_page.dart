part of station_app;

// ════════════════════════════════════════════════════════════════
//  SharedExternalRequestStore — محاكاة محلية
//  الطلبات من Passengers تُضاف هنا، الأدمن والمشرف يقرآن منه
// ════════════════════════════════════════════════════════════════
class SharedExternalRequestStore {
  SharedExternalRequestStore._();

  static final List<ExternalRequest> _requests = [
    // بيانات وهمية تجريبية
    ExternalRequest(
      id: 'ER-001',
      type: RequestType.passengers,
      status: RequestStatus.pending,
      location: 'الخليل — حي الشيخ',
      destination: 'بيت لحم — المركز',
      contactPhone: '0599123456',
      createdAt: '2025-05-19T08:00:00',
      passengersCount: 3,
    ),
    ExternalRequest(
      id: 'ER-002',
      type: RequestType.parcel,
      status: RequestStatus.pending,
      location: 'الخليل — باب الزاوية',
      destination: 'رام الله — البيرة',
      contactPhone: '0598765432',
      createdAt: '2025-05-19T09:30:00',
      parcelName: 'مستندات رسمية',
      parcelDetails: 'مظروف مختوم — عاجل',
    ),
    ExternalRequest(
      id: 'ER-003',
      type: RequestType.passengers,
      status: RequestStatus.accepted,
      location: 'الخليل — الحرس',
      destination: 'القدس — باب العمود',
      contactPhone: '0597654321',
      createdAt: '2025-05-18T14:00:00',
      passengersCount: 2,
      assignedVehicleId: '12-234-12',
      assignedDriver: 'أحمد إسماعيل الحج',
      assignedLine: '[101] الخليل → بيت لحم',
    ),
    ExternalRequest(
      id: 'ER-004',
      type: RequestType.parcel,
      status: RequestStatus.cancelled,
      location: 'الخليل — صحراء',
      destination: 'نابلس — المركز',
      contactPhone: '0592111222',
      createdAt: '2025-05-17T11:15:00',
      parcelName: 'بضاعة تجارية',
      parcelDetails: 'صندوق متوسط الحجم',
    ),
  ];

  static List<ExternalRequest> get all => List.unmodifiable(_requests);

  static List<ExternalRequest> get pending =>
      _requests.where((r) => r.status == RequestStatus.pending).toList();

  // إضافة طلب جديد (يُستدعى من Passengers — محاكاة)
  static void addRequest(ExternalRequest req) {
    _requests.insert(0, req);
    // أضف للـ globalRequests أيضاً
    globalRequests.insert(0, req);
    saveRequests();
  }

  // تحديث حالة طلب
  static void updateStatus(String id, RequestStatus status, {
    String? assignedVehicleId,
    String? assignedDriver,
    String? assignedLine,
    String? movementOrderNote,
  }) {
    final idx = _requests.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _requests[idx] = _requests[idx].copyWith(
        status: status,
        assignedVehicleId: assignedVehicleId,
        assignedDriver: assignedDriver,
        assignedLine: assignedLine,
        movementOrderNote: movementOrderNote,
      );
      // حدّث globalRequests
      final gIdx = globalRequests.indexWhere((r) => r.id == id);
      if (gIdx != -1) globalRequests[gIdx] = _requests[idx];
      else globalRequests.insert(0, _requests[idx]);
      saveRequests();
    }
  }
}

// ════════════════════════════════════════════════════════════════
//  MovementOrderNotification — أوامر حركة من المشرف للأدمن
// ════════════════════════════════════════════════════════════════
class MovementOrderNotification {
  final String id;
  final String vehiclePlate;
  final String driverName;
  final String lineName;
  final String reason; // 'exception' | 'permission'
  final String supervisorName;
  final String createdAt;
  bool isRead;

  MovementOrderNotification({
    required this.id,
    required this.vehiclePlate,
    required this.driverName,
    required this.lineName,
    required this.reason,
    required this.supervisorName,
    required this.createdAt,
    this.isRead = false,
  });

  String get reasonLabel => reason == 'exception' ? 'استثناء' : 'إذن موافق عليه';
}

class SharedMovementOrderAdminStore {
  SharedMovementOrderAdminStore._();

  static final List<MovementOrderNotification> _orders = [
    // بيانات وهمية
    MovementOrderNotification(
      id: 'MO-001',
      vehiclePlate: '12-234-12',
      driverName: 'أحمد إسماعيل الحج',
      lineName: '[101] الخليل → بيت لحم',
      reason: 'exception',
      supervisorName: 'خالد كرم طرشان',
      createdAt: '2025-05-19T08:45:00',
    ),
    MovementOrderNotification(
      id: 'MO-002',
      vehiclePlate: '34-567-89',
      driverName: 'محمد أحمد العمر',
      lineName: '[102] الخليل → القدس',
      reason: 'permission',
      supervisorName: 'يوسف نادر سلامة',
      createdAt: '2025-05-18T14:30:00',
      isRead: true,
    ),
  ];

  static List<MovementOrderNotification> get all =>
      List.unmodifiable(_orders);

  static int get unreadCount =>
      _orders.where((o) => !o.isRead).length;

  // المشرف يرسل أمر حركة للأدمن
  static void issueOrder({
    required String vehiclePlate,
    required String driverName,
    required String lineName,
    required String reason,
    required String supervisorName,
  }) {
    _orders.insert(0, MovementOrderNotification(
      id: 'MO-${DateTime.now().millisecondsSinceEpoch}',
      vehiclePlate: vehiclePlate,
      driverName: driverName,
      lineName: lineName,
      reason: reason,
      supervisorName: supervisorName,
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  static void markRead(String id) {
    final idx = _orders.indexWhere((o) => o.id == id);
    if (idx != -1) _orders[idx].isRead = true;
  }

  static void markAllRead() {
    for (final o in _orders) o.isRead = true;
  }
}

// ─────────────────────────────────────────────
//  نموذج بيانات الطلب (متوافق مع OrderEntity من تطبيق الركاب)
// ─────────────────────────────────────────────
enum RequestType { passengers, parcel }
enum RequestStatus { pending, accepted, inProgress, completed, cancelled }

class ExternalRequest {
  final String id;
  final RequestType type;
  final RequestStatus status;
  final String location;
  final String destination;
  final String contactPhone;
  final String createdAt;
  final int? passengersCount;
  final String? parcelName;
  final String? parcelDetails;
  final double? lat;
  final double? lng;
  // أمر الحركة
  final String? assignedVehicleId;
  final String? assignedDriver;
  final String? assignedLine;
  final String? movementOrderTime;
  final String? movementOrderNote;

  const ExternalRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.location,
    required this.destination,
    required this.contactPhone,
    required this.createdAt,
    this.passengersCount,
    this.parcelName,
    this.parcelDetails,
    this.lat,
    this.lng,
    this.assignedVehicleId,
    this.assignedDriver,
    this.assignedLine,
    this.movementOrderTime,
    this.movementOrderNote,
  });

  ExternalRequest copyWith({
    RequestStatus? status,
    String? assignedVehicleId,
    String? assignedDriver,
    String? assignedLine,
    String? movementOrderTime,
    String? movementOrderNote,
  }) => ExternalRequest(
    id: id, type: type,
    status: status ?? this.status,
    location: location, destination: destination,
    contactPhone: contactPhone, createdAt: createdAt,
    passengersCount: passengersCount,
    parcelName: parcelName, parcelDetails: parcelDetails,
    lat: lat, lng: lng,
    assignedVehicleId: assignedVehicleId ?? this.assignedVehicleId,
    assignedDriver: assignedDriver ?? this.assignedDriver,
    assignedLine: assignedLine ?? this.assignedLine,
    movementOrderTime: movementOrderTime ?? this.movementOrderTime,
    movementOrderNote: movementOrderNote ?? this.movementOrderNote,
  );

  factory ExternalRequest.fromJson(Map<String, dynamic> j) => ExternalRequest(
    id: j['id'] ?? '',
    type: j['type'] == 'parcel' ? RequestType.parcel : RequestType.passengers,
    status: _parseStatus(j['status']),
    location: j['location'] ?? '',
    destination: j['destination'] ?? '',
    contactPhone: j['contact_phone'] ?? '',
    createdAt: j['created_at'] ?? '',
    passengersCount: j['passengers_count'],
    parcelName: j['parcel_name'],
    parcelDetails: j['parcel_details'],
    lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble(),
    assignedVehicleId: j['assigned_vehicle_id'],
    assignedDriver: j['assigned_driver'],
    assignedLine: j['assigned_line'],
    movementOrderTime: j['movement_order_time'],
    movementOrderNote: j['movement_order_note'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type == RequestType.parcel ? 'parcel' : 'passengers',
    'status': status.name,
    'location': location,
    'destination': destination,
    'contact_phone': contactPhone,
    'created_at': createdAt,
    if (passengersCount != null) 'passengers_count': passengersCount,
    if (parcelName != null) 'parcel_name': parcelName,
    if (parcelDetails != null) 'parcel_details': parcelDetails,
    if (lat != null) 'lat': lat,
    if (lng != null) 'lng': lng,
    if (assignedVehicleId != null) 'assigned_vehicle_id': assignedVehicleId,
    if (assignedDriver != null) 'assigned_driver': assignedDriver,
    if (assignedLine != null) 'assigned_line': assignedLine,
    if (movementOrderTime != null) 'movement_order_time': movementOrderTime,
    if (movementOrderNote != null) 'movement_order_note': movementOrderNote,
  };

  static RequestStatus _parseStatus(String? s) {
    switch (s) {
      case 'accepted': case 'approved': return RequestStatus.accepted;
      case 'inProgress': case 'in_progress': return RequestStatus.inProgress;
      case 'completed': return RequestStatus.completed;
      case 'cancelled': case 'rejected': return RequestStatus.cancelled;
      default: return RequestStatus.pending;
    }
  }
}

List<ExternalRequest> globalRequests = [];

// ── حفظ وتحميل الطلبات ────────────────────────
Future<void> saveRequests() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('external_requests',
      jsonEncode(globalRequests.map((r) => r.toJson()).toList()));
}

Future<void> loadRequests() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('external_requests');
  if (raw != null) {
    try {
      final list = jsonDecode(raw) as List;
      globalRequests = list.map((e) => ExternalRequest.fromJson(e)).toList();
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────
//  صفحة الطلبات الخارجية
// ─────────────────────────────────────────────
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});
  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage>
    with DarkModeRebuild<RequestsPage> {
  String _activeFilter = 'الكل';
  int _tabIndex = 0; // 0=طلبات Passengers، 1=أوامر الحركة
  final List<String> _filters = ['الكل', 'معلق', 'مقبول', 'مرفوض'];

  List<ExternalRequest> get _allRequests =>
      SharedExternalRequestStore.all.toList();

  List<ExternalRequest> get _filtered {
    final all = _allRequests;
    switch (_activeFilter) {
      case 'معلق':  return all.where((r) => r.status == RequestStatus.pending).toList();
      case 'مقبول': return all.where((r) => r.status == RequestStatus.accepted).toList();
      case 'مرفوض': return all.where((r) => r.status == RequestStatus.cancelled).toList();
      default: return all;
    }
  }

  int get _pendingCount =>
      SharedExternalRequestStore.pending.length +
      SharedMovementOrderAdminStore.unreadCount;

  Color _statusColor(RequestStatus s) {
    switch (s) {
      case RequestStatus.pending: return const Color(0xFFFFB347);
      case RequestStatus.accepted: return const Color(0xFF00C897);
      case RequestStatus.inProgress: return const Color(0xFF4B9EFF);
      case RequestStatus.completed: return const Color(0xFF2E7D32);
      case RequestStatus.cancelled: return const Color(0xFFFF5A5F);
    }
  }

  String _statusLabel(RequestStatus s) {
    switch (s) {
      case RequestStatus.pending: return 'معلق';
      case RequestStatus.accepted: return 'مقبول';
      case RequestStatus.inProgress: return 'قيد التنفيذ';
      case RequestStatus.completed: return 'مكتمل';
      case RequestStatus.cancelled: return 'ملغي';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          color: const Color(0xFF2D3A5C),
          child: Row(children: [
            Expanded(child: Row(children: [
              const Text('الطلبات الخارجية',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              if (_pendingCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFFFFB347), borderRadius: BorderRadius.circular(20)),
                  child: Text('$_pendingCount جديد',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ])),
            _Tap(
              onTap: () => setState(() {}),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),

        // ── Tabs ──
        Container(
          color: context.cardColor,
          child: Row(children: [
            _TabBtn('طلبات الركاب', 0, Icons.people_outlined, const Color(0xFF4B9EFF)),
            _TabBtn('أوامر الحركة', 1, Icons.directions_car_outlined, const Color(0xFF00C897)),
          ]),
        ),

        // ── إحصائيات سريعة (طلبات) ──
        if (_tabIndex == 0) Container(
          color: context.cardColor,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Row(children: [
            _StatBadge('الكل',     _allRequests.length, const Color(0xFF2D3A5C)),
            _StatBadge('معلق',     _allRequests.where((r) => r.status == RequestStatus.pending).length, const Color(0xFFFFB347)),
            _StatBadge('مقبول',   _allRequests.where((r) => r.status == RequestStatus.accepted).length, const Color(0xFF00C897)),
            _StatBadge('مرفوض',   _allRequests.where((r) => r.status == RequestStatus.cancelled).length, const Color(0xFFFF5A5F)),
          ]),
        ),

        // ── فلاتر (طلبات) ──
        if (_tabIndex == 0) Container(
          color: context.cardColor,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(children: _filters.map((f) {
              final sel = f == _activeFilter;
              Color accent = const Color(0xFF2D3A5C);
              if (f == 'معلق') accent = const Color(0xFFFFB347);
              else if (f == 'مقبول') accent = const Color(0xFF00C897);
              else if (f == 'مرفوض') accent = const Color(0xFFFF5A5F);
              return _Tap(
                onTap: () => setState(() => _activeFilter = f),
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? accent : context.bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? accent : context.dividerColor),
                  ),
                  child: Text(f, style: TextStyle(
                      color: sel ? Colors.white : context.textSecondary,
                      fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              );
            }).toList()),
          ),
        ),

        // ── المحتوى ──
        Expanded(child: _tabIndex == 0 ? _buildRequests() : _buildMovementOrders()),
      ]),
    );
  }

  Widget _TabBtn(String label, int idx, IconData icon, Color color) {
    final sel = _tabIndex == idx;
    return Expanded(child: _Tap(
      onTap: () {
        setState(() => _tabIndex = idx);
        if (idx == 1) SharedMovementOrderAdminStore.markAllRead();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(
            color: sel ? color : Colors.transparent, width: 2.5)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: sel ? color : context.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
              fontSize: 13, fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              color: sel ? color : context.textSecondary)),
          if (idx == 1 && SharedMovementOrderAdminStore.unreadCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Text('${SharedMovementOrderAdminStore.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
      ),
    ));
  }

  Widget _buildRequests() {
    final items = _filtered;
    if (items.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text('لا توجد طلبات', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
    ]));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => _RequestCard(request: items[i]),
    );
  }

  Widget _buildMovementOrders() {
    final orders = SharedMovementOrderAdminStore.all;
    if (orders.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.directions_car_outlined, size: 60, color: Colors.grey[300]),
      const SizedBox(height: 12),
      Text('لا توجد أوامر حركة', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
    ]));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (_, i) {
        final o = orders[i];
        final color = o.reason == 'exception' ? const Color(0xFFFFB347) : const Color(0xFF4B9EFF);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: !o.isRead ? Border.all(color: color.withValues(alpha: 0.4)) : null,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
          ),
          child: Column(children: [
            // رأس
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.15))),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(o.reason == 'exception' ? Icons.alt_route_rounded : Icons.check_circle_outline, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Text(o.reasonLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                const Spacer(),
                if (!o.isRead) Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(o.id, style: TextStyle(fontSize: 11, color: context.textSecondary)),
              ]),
            ),
            // تفاصيل
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.directions_car_outlined, size: 14, color: context.textSecondary),
                  const SizedBox(width: 6),
                  Text(o.vehiclePlate, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.person_outline, size: 14, color: context.textSecondary),
                  const SizedBox(width: 6),
                  Text(o.driverName, style: TextStyle(fontSize: 13, color: context.textPrimary)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.route_outlined, size: 14, color: context.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(o.lineName, style: TextStyle(fontSize: 12, color: context.textSecondary))),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.manage_accounts_outlined, size: 14, color: context.textSecondary),
                  const SizedBox(width: 6),
                  Text('المشرف: ${o.supervisorName}', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                  const Spacer(),
                  Text(_formatTime(o.createdAt), style: TextStyle(fontSize: 10, color: context.textSecondary)),
                ]),
              ]),
            ),
          ]),
        );
      },
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} - ${dt.day}/${dt.month}';
    } catch (_) { return iso; }
  }
}

// ── إحصائية صغيرة ──────────────────────────────
class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatBadge(this.label, this.count, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: context.textSecondary)),
    ]),
  );
}

// ─────────────────────────────────────────────
//  بطاقة الطلب
// ─────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final ExternalRequest request;
  const _RequestCard({required this.request});

  Color get _statusColor {
    switch (request.status) {
      case RequestStatus.pending: return const Color(0xFFFFB347);
      case RequestStatus.accepted: return const Color(0xFF00C897);
      case RequestStatus.inProgress: return const Color(0xFF4B9EFF);
      case RequestStatus.completed: return const Color(0xFF2E7D32);
      case RequestStatus.cancelled: return const Color(0xFFFF5A5F);
    }
  }

  String get _statusLabel {
    switch (request.status) {
      case RequestStatus.pending: return 'معلق';
      case RequestStatus.accepted: return 'مقبول';
      case RequestStatus.inProgress: return 'مقبول';
      case RequestStatus.completed: return 'مقبول';
      case RequestStatus.cancelled: return 'مرفوض';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isParcel = request.type == RequestType.parcel;
    final typeColor = isParcel ? const Color(0xFFB47AFF) : const Color(0xFF4B9EFF);
    final typeIcon = isParcel ? Icons.inventory_2_outlined : Icons.people_outlined;
    final typeLabel = isParcel ? 'طرد' : 'ركاب';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: request.status == RequestStatus.pending
            ? Border.all(color: const Color(0xFFFFB347).withValues(alpha: 0.4))
            : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── رأس البطاقة ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border(bottom: BorderSide(color: typeColor.withValues(alpha: 0.15))),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(typeIcon, size: 16, color: typeColor),
            ),
            const SizedBox(width: 8),
            Text(typeLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: typeColor)),
            const SizedBox(width: 8),
            Text(request.id, style: TextStyle(fontSize: 11, color: context.textSecondary)),
            const Spacer(),
            // حالة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                    decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(_statusLabel, style: TextStyle(fontSize: 11, color: _statusColor, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
        ),

        // ── تفاصيل ──
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // الموقع والوجهة
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF00C897)),
              const SizedBox(width: 6),
              Expanded(child: Text(request.location,
                  style: TextStyle(fontSize: 13, color: context.textPrimary, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.flag_outlined, size: 14, color: Color(0xFFFF5A5F)),
              const SizedBox(width: 6),
              Expanded(child: Text(request.destination,
                  style: TextStyle(fontSize: 13, color: context.textPrimary, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 8),

            // تفاصيل الطلب
            if (!isParcel && request.passengersCount != null)
              _InfoChip(Icons.person_outline, '${request.passengersCount} راكب', const Color(0xFF4B9EFF)),
            if (isParcel && request.parcelName != null)
              _InfoChip(Icons.inventory_2_outlined, request.parcelName!, const Color(0xFFB47AFF)),
            if (isParcel && request.parcelDetails != null) ...[
              const SizedBox(height: 4),
              Text(request.parcelDetails!,
                  style: TextStyle(fontSize: 11, color: context.textSecondary)),
            ],

            const SizedBox(height: 8),

            // رقم الهاتف + الوقت
            Row(children: [
              _InfoChip(Icons.phone_outlined, request.contactPhone, const Color(0xFF00C897)),
              const Spacer(),
              Text(_formatTime(request.createdAt),
                  style: TextStyle(fontSize: 10, color: context.textSecondary)),
            ]),

            // أمر الحركة إذا موجود
            if (request.assignedVehicleId != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C897).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00C897).withValues(alpha: 0.2)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.directions_car_rounded, size: 13, color: Color(0xFF00C897)),
                    const SizedBox(width: 6),
                    Text('أمر الحركة', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00C897))),
                  ]),
                  const SizedBox(height: 6),
                  if (request.assignedVehicleId != null)
                    _OrderRow('المركبة', request.assignedVehicleId!, context),
                  if (request.assignedDriver != null)
                    _OrderRow('السائق', request.assignedDriver!, context),
                  if (request.assignedLine != null)
                    _OrderRow('الخط', request.assignedLine!, context),
                ]),
              ),
            ],

            // الأدمن مشاهدة فقط — القرار تلقائي أو عند مشرف الخط
          ]),
        ),
      ]),
    );
  }

  Widget _InfoChip(IconData icon, String text, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: color),
    const SizedBox(width: 4),
    Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    const SizedBox(width: 12),
  ]);

  Widget _OrderRow(String label, String value, BuildContext ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(children: [
      Text('$label: ', style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
      Expanded(child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ctx.textPrimary), overflow: TextOverflow.ellipsis)),
    ]),
  );

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} - ${dt.day}/${dt.month}';
    } catch (_) { return iso; }
  }

}