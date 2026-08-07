part of station_app;

class _ApiConfig {
  static const String baseUrl  = 'https://your-api.example.com/api/v1';
  static const String adminKey = 'your-admin-api-key';
  static const int    timeout  = 10;
}

enum RequestType   { passengers, parcel }
enum RequestStatus { pending, accepted, inProgress, completed, cancelled }

class ExternalRequest {
  final String        id;
  final RequestType   type;
  final RequestStatus status;
  final String        location;
  final String        destination;
  final String        contactPhone;
  final String        createdAt;
  final String?       senderName;
  final String?       lineName;
  final int?          passengersCount;
  final String?       parcelName;
  final String?       parcelDetails;
  final double?       lat;
  final double?       lng;
  final String?       assignedVehicleId;
  final String?       assignedDriver;
  final String?       assignedLine;
  final String?       movementOrderNote;
  // ✅ حالة وصول الطلب (خاصة بالأوردرات) — منفصلة عن حالة القبول/الرفض
  final bool           delivered;

  const ExternalRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.location,
    required this.destination,
    required this.contactPhone,
    required this.createdAt,
    this.senderName,
    this.lineName,
    this.passengersCount,
    this.parcelName,
    this.parcelDetails,
    this.lat,
    this.lng,
    this.assignedVehicleId,
    this.assignedDriver,
    this.assignedLine,
    this.movementOrderNote,
    this.delivered = false,
  });

  ExternalRequest copyWith({
    RequestStatus? status,
    String? assignedVehicleId,
    String? assignedDriver,
    String? assignedLine,
    String? movementOrderNote,
    bool? delivered,
  }) => ExternalRequest(
    id: id, type: type,
    status: status ?? this.status,
    location: location, destination: destination,
    contactPhone: contactPhone, createdAt: createdAt,
    senderName: senderName, lineName: lineName,
    passengersCount: passengersCount,
    parcelName: parcelName, parcelDetails: parcelDetails,
    lat: lat, lng: lng,
    assignedVehicleId: assignedVehicleId ?? this.assignedVehicleId,
    assignedDriver: assignedDriver ?? this.assignedDriver,
    assignedLine: assignedLine ?? this.assignedLine,
    movementOrderNote: movementOrderNote ?? this.movementOrderNote,
    delivered: delivered ?? this.delivered,
  );

  factory ExternalRequest.fromJson(Map<String, dynamic> j) => ExternalRequest(
    id:              j['id']              ?? '',
    type:            j['type'] == 'parcel' ? RequestType.parcel : RequestType.passengers,
    status:          _parseStatus(j['status']),
    location:        j['location']        ?? '',
    destination:     j['destination']     ?? '',
    contactPhone:    j['contact_phone']   ?? j['passenger_phone'] ?? '',
    createdAt:       j['created_at']      ?? '',
    senderName:      j['passenger_name']  ?? j['sender']?['name'],
    lineName:        j['line_name'],
    passengersCount: j['passengers_count'],
    parcelName:      j['parcel_name'],
    parcelDetails:   j['parcel_details'],
    lat:             (j['latitude']  as num?)?.toDouble(),
    lng:             (j['longitude'] as num?)?.toDouble(),
    assignedVehicleId: j['assigned_vehicle_id'],
    assignedDriver:    j['assigned_driver'],
    assignedLine:      j['assigned_line'],
    movementOrderNote: j['note'],
    delivered:         j['delivered'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type == RequestType.parcel ? 'parcel' : 'passengers',
    'status': status.name,
    'location': location,
    'destination': destination,
    'contact_phone': contactPhone,
    'created_at': createdAt,
    if (senderName != null)      'passenger_name':    senderName,
    if (lineName != null)        'line_name':         lineName,
    if (passengersCount != null) 'passengers_count':  passengersCount,
    if (parcelName != null)      'parcel_name':       parcelName,
    if (parcelDetails != null)   'parcel_details':    parcelDetails,
    if (lat != null)             'latitude':          lat,
    if (lng != null)             'longitude':         lng,
    if (assignedVehicleId != null) 'assigned_vehicle_id': assignedVehicleId,
    if (assignedDriver != null)    'assigned_driver':     assignedDriver,
    if (assignedLine != null)      'assigned_line':        assignedLine,
    if (movementOrderNote != null) 'note':                movementOrderNote,
    'delivered': delivered,
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

class _RequestsRepository {
  static Future<List<ExternalRequest>> fetchRequests() async {
    try {
      final token = await _getAdminToken();
      final res = await http.get(
        Uri.parse('${_ApiConfig.baseUrl}/admin/requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Api-Key': _ApiConfig.adminKey,
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: _ApiConfig.timeout));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => ExternalRequest.fromJson(e)).toList();
      }
    } catch (_) {}
    return [...globalOrders, ...globalDeliveryRequests];
  }

  static Future<String> _getAdminToken() async => 'mock-token';
}

// ════════════════════════════════════════════════════════════════
//  ✅ قائمتان منفصلتان تماماً — بدون أي دمج بينهما إطلاقاً
//  - globalOrders: طلبات الأوردر (طرود) فقط
//  - globalDeliveryRequests: طلبات توصيل الركاب فقط
// ════════════════════════════════════════════════════════════════
List<ExternalRequest> globalOrders           = [];
List<ExternalRequest> globalDeliveryRequests = [];

Future<void> saveOrders() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('orders_data',
      jsonEncode(globalOrders.map((r) => r.toJson()).toList()));
}

Future<void> saveDeliveryRequests() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('delivery_requests_data',
      jsonEncode(globalDeliveryRequests.map((r) => r.toJson()).toList()));
}

Future<void> loadOrders() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('orders_data');
  if (raw != null) {
    try {
      final list = jsonDecode(raw) as List;
      globalOrders = list.map((e) => ExternalRequest.fromJson(e)).toList();
    } catch (_) {}
  }
  if (globalOrders.isEmpty) {
    globalOrders = [
      ExternalRequest(
        id: 'OR-001', type: RequestType.parcel, status: RequestStatus.pending,
        location: 'الخليل — باب الزاوية', destination: 'رام الله — البيرة',
        contactPhone: '0598765432', createdAt: '2025-05-19T09:30:00',
        senderName: 'منى الجعبري', lineName: 'الخليل / رام الله',
        parcelName: 'مستندات رسمية', parcelDetails: 'مظروف مختوم — عاجل',
      ),
      ExternalRequest(
        id: 'OR-002', type: RequestType.parcel, status: RequestStatus.cancelled,
        location: 'الخليل — صحراء', destination: 'نابلس — المركز',
        contactPhone: '0592111222', createdAt: '2025-05-17T11:15:00',
        senderName: 'ريم حسن', lineName: 'الخليل / نابلس',
        parcelName: 'بضاعة تجارية', parcelDetails: 'صندوق متوسط الحجم',
      ),
      ExternalRequest(
        id: 'OR-003', type: RequestType.parcel, status: RequestStatus.accepted,
        location: 'الخليل — عين سارة', destination: 'دورا — المركز',
        contactPhone: '0591998877', createdAt: '2025-05-19T07:00:00',
        senderName: 'وليد أبو شريخ', lineName: 'الخليل / دورا',
        parcelName: 'قطع غيار', parcelDetails: 'كرتونة صغيرة',
        delivered: true,
      ),
    ];
    await saveOrders();
  }
}

Future<void> loadDeliveryRequests() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('delivery_requests_data');
  if (raw != null) {
    try {
      final list = jsonDecode(raw) as List;
      globalDeliveryRequests = list.map((e) => ExternalRequest.fromJson(e)).toList();
    } catch (_) {}
  }
  if (globalDeliveryRequests.isEmpty) {
    globalDeliveryRequests = [
      ExternalRequest(
        id: 'DL-001', type: RequestType.passengers, status: RequestStatus.pending,
        location: 'الخليل — حي الشيخ', destination: 'بيت لحم — المركز',
        contactPhone: '0599123456', createdAt: '2025-05-19T08:00:00',
        senderName: 'سامر أبو عيشة', lineName: 'الخليل / بيت لحم',
        passengersCount: 3,
      ),
      ExternalRequest(
        id: 'DL-002', type: RequestType.passengers, status: RequestStatus.accepted,
        location: 'الخليل — الحرس', destination: 'القدس — باب العمود',
        contactPhone: '0597654321', createdAt: '2025-05-18T14:00:00',
        senderName: 'خالد العمر', lineName: 'الخليل / القدس',
        passengersCount: 2,
        assignedVehicleId: '12-234-12', assignedDriver: 'أحمد إسماعيل الحج',
        assignedLine: '[101] الخليل - بيت لحم',
      ),
      ExternalRequest(
        id: 'DL-003', type: RequestType.passengers, status: RequestStatus.pending,
        location: 'الخليل — عين سارة', destination: 'دورا — المركز',
        contactPhone: '0591999888', createdAt: '2025-05-19T10:45:00',
        senderName: 'عمر الشريف', lineName: 'الخليل / دورا',
        passengersCount: 1,
      ),
    ];
    await saveDeliveryRequests();
  }
}

// ════════════════════════════════════════════
//  صفحة الطلبات — حاوية عامة فيها تبويبان منفصلان
//  تماماً (الأوردر / خدمات توصيل الركاب)، بدون أي دمج بينهما
// ════════════════════════════════════════════
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});
  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage>
    with DarkModeRebuild<RequestsPage> {
  int _tab = 0; // 0 = الأوردر, 1 = خدمات توصيل الركاب

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(children: [

        // ── Header ──────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          color: const Color(0xFF2D3A5C),
          child: Text(L.get('external_requests'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ),

        // ── تبويبان منفصلان تماماً ───────────
        Container(
          color: context.cardColor,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            Expanded(
              child: _MainTabButton(
                label: L.get('orders_tab'),
                icon: Icons.inventory_2_outlined,
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MainTabButton(
                label: L.get('delivery_tab'),
                icon: Icons.people_outline,
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
            ),
          ]),
        ),

        // ── المحتوى ─────────────────────────
        Expanded(child: _tab == 0 ? const _OrdersView() : const _DeliveryView()),
      ]),
    );
  }
}

class _MainTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _MainTabButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF2D3A5C);
    return _Tap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent : context.bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? accent : context.dividerColor),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: selected ? Colors.white : context.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
              color: selected ? Colors.white : context.textSecondary,
              fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

// ── إحصائية صغيرة ──────────────────────────
class _StatBadge extends StatelessWidget {
  final String label;
  final int    count;
  final Color  color;
  const _StatBadge(this.label, this.count, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: TextStyle(fontSize: 10, color: context.textSecondary)),
  ]));
}

Widget _infoChip(IconData icon, String text, Color color) =>
    Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(
          fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      const SizedBox(width: 12),
    ]);

String _formatReqTime(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} - ${dt.day}/${dt.month}';
  } catch (_) { return iso; }
}

// ════════════════════════════════════════════════════════════════
//  ✅ 1) واجهة الأوردر — مقسّمة على 3 أقسام: مرفوضة / في الانتظار / مقبولة
// ════════════════════════════════════════════════════════════════
class _OrdersView extends StatefulWidget {
  const _OrdersView();
  @override
  State<_OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<_OrdersView> {
  String _section = 'pending'; // pending | accepted | rejected
  bool   _loading = false;

  List<ExternalRequest> get _pending  => globalOrders.where((r) => r.status == RequestStatus.pending).toList();
  List<ExternalRequest> get _accepted => globalOrders.where((r) =>
      r.status == RequestStatus.accepted || r.status == RequestStatus.inProgress || r.status == RequestStatus.completed).toList();
  List<ExternalRequest> get _rejected => globalOrders.where((r) => r.status == RequestStatus.cancelled).toList();

  List<ExternalRequest> get _current {
    switch (_section) {
      case 'accepted': return _accepted;
      case 'rejected': return _rejected;
      default: return _pending;
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final fetched = await _RequestsRepository.fetchRequests();
      setState(() {
        globalOrders = fetched.where((r) => r.type == RequestType.parcel).toList();
      });
      await saveOrders();
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _accept(ExternalRequest r) {
    setState(() {
      final idx = globalOrders.indexWhere((x) => x.id == r.id);
      if (idx != -1) globalOrders[idx] = r.copyWith(status: RequestStatus.accepted);
    });
    saveOrders();
  }

  void _reject(ExternalRequest r) {
    setState(() {
      final idx = globalOrders.indexWhere((x) => x.id == r.id);
      if (idx != -1) globalOrders[idx] = r.copyWith(status: RequestStatus.cancelled);
    });
    saveOrders();
  }

  void _toggleDelivered(ExternalRequest r) {
    setState(() {
      final idx = globalOrders.indexWhere((x) => x.id == r.id);
      if (idx != -1) globalOrders[idx] = r.copyWith(delivered: !r.delivered);
    });
    saveOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── إحصائيات ────────────────────────
      Container(
        color: context.cardColor,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          _StatBadge(L.get('req_status_pending'),  _pending.length,  const Color(0xFFFFB347)),
          _StatBadge(L.get('req_status_accepted'), _accepted.length, const Color(0xFF00C897)),
          _StatBadge(L.get('req_status_cancelled'),_rejected.length, const Color(0xFFFF5A5F)),
          _Tap(
            onTap: _refresh,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: context.bgColor, borderRadius: BorderRadius.circular(8)),
              child: _loading
                  ? SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: context.textSecondary, strokeWidth: 2))
                  : Icon(Icons.refresh_rounded, color: context.textSecondary, size: 18),
            ),
          ),
        ]),
      ),

      // ── 3 أقسام ثابتة: مرفوضة / في الانتظار / مقبولة ──
      Container(
        color: context.cardColor,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(children: [
          Expanded(child: _SectionChip(
              label: L.get('req_status_cancelled'), count: _rejected.length,
              color: const Color(0xFFFF5A5F), selected: _section == 'rejected',
              onTap: () => setState(() => _section = 'rejected'))),
          const SizedBox(width: 6),
          Expanded(child: _SectionChip(
              label: L.get('req_status_pending'), count: _pending.length,
              color: const Color(0xFFFFB347), selected: _section == 'pending',
              onTap: () => setState(() => _section = 'pending'))),
          const SizedBox(width: 6),
          Expanded(child: _SectionChip(
              label: L.get('req_status_accepted'), count: _accepted.length,
              color: const Color(0xFF00C897), selected: _section == 'accepted',
              onTap: () => setState(() => _section = 'accepted'))),
        ]),
      ),

      Expanded(child: _buildList()),
    ]);
  }

  Widget _buildList() {
    final items = _current;
    if (items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(L.get('no_orders'), style: TextStyle(color: Colors.grey[400], fontSize: 15)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) => _OrderCard(
        request: items[i],
        onAccept: () => _accept(items[i]),
        onReject: () => _reject(items[i]),
        onToggleDelivered: () => _toggleDelivered(items[i]),
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _SectionChip({required this.label, required this.count, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => _Tap(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color : context.bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: selected ? color : context.dividerColor),
      ),
      child: Column(children: [
        Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
            color: selected ? Colors.white : color)),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : context.textSecondary)),
      ]),
    ),
  );
}

// ── بطاقة الأوردر ───────────────────────────
class _OrderCard extends StatelessWidget {
  final ExternalRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onToggleDelivered;
  const _OrderCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
    required this.onToggleDelivered,
  });

  Color get _statusColor {
    switch (request.status) {
      case RequestStatus.pending:    return const Color(0xFFFFB347);
      case RequestStatus.accepted:   return const Color(0xFF00C897);
      case RequestStatus.inProgress: return const Color(0xFF4B9EFF);
      case RequestStatus.completed:  return const Color(0xFF2E7D32);
      case RequestStatus.cancelled:  return const Color(0xFFFF5A5F);
    }
  }

  String _statusLabel() {
    switch (request.status) {
      case RequestStatus.pending:    return L.get('req_status_pending');
      case RequestStatus.accepted:   return L.get('req_status_accepted');
      case RequestStatus.inProgress: return L.get('req_status_in_progress');
      case RequestStatus.completed:  return L.get('req_status_completed');
      case RequestStatus.cancelled:  return L.get('req_status_cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    const typeColor = Color(0xFFB47AFF);
    final isPending  = request.status == RequestStatus.pending;
    final isAccepted = request.status == RequestStatus.accepted ||
        request.status == RequestStatus.inProgress || request.status == RequestStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: isPending
            ? Border.all(color: const Color(0xFFFFB347).withValues(alpha: 0.5))
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
              child: const Icon(Icons.inventory_2_outlined, size: 16, color: typeColor),
            ),
            const SizedBox(width: 8),
            Text(request.id, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(_statusLabel(), style: TextStyle(fontSize: 11, color: _statusColor, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
        ),

        // ── تفاصيل ──
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ✅ معلومات الشخص اللي طلب الأوردر
            if (request.senderName != null) ...[
              Row(children: [
                const Icon(Icons.person_outline, size: 14, color: Color(0xFF8A93A8)),
                const SizedBox(width: 6),
                Text(request.senderName!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
              ]),
              const SizedBox(height: 6),
            ],

            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF00C897)),
              const SizedBox(width: 6),
              Expanded(child: Text(request.location, style: TextStyle(fontSize: 12, color: context.textPrimary))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.flag_outlined, size: 14, color: Color(0xFFFF5A5F)),
              const SizedBox(width: 6),
              Expanded(child: Text(request.destination, style: TextStyle(fontSize: 12, color: context.textPrimary))),
            ]),
            const SizedBox(height: 8),

            if (request.parcelName != null)
              _infoChip(Icons.inventory_2_outlined, request.parcelName!, const Color(0xFFB47AFF)),
            if (request.parcelDetails != null) ...[
              const SizedBox(height: 4),
              Text(request.parcelDetails!, style: TextStyle(fontSize: 11, color: context.textSecondary)),
            ],
            const SizedBox(height: 8),

            Row(children: [
              _infoChip(Icons.phone_outlined, request.contactPhone, const Color(0xFF00C897)),
              const Spacer(),
              Text(_formatReqTime(request.createdAt), style: TextStyle(fontSize: 10, color: context.textSecondary)),
            ]),

            // ✅ حالة وصول الأوردر — تظهر فقط بعد القبول
            if (isAccepted) ...[
              const SizedBox(height: 10),
              _Tap(
                onTap: onToggleDelivered,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: (request.delivered ? const Color(0xFF00C897) : const Color(0xFFFFB347)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: (request.delivered ? const Color(0xFF00C897) : const Color(0xFFFFB347)).withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(request.delivered ? Icons.check_circle_outline : Icons.local_shipping_outlined,
                        size: 15, color: request.delivered ? const Color(0xFF00C897) : const Color(0xFFFFB347)),
                    const SizedBox(width: 6),
                    Text(request.delivered ? L.get('order_delivered') : L.get('order_not_delivered'),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                            color: request.delivered ? const Color(0xFF00C897) : const Color(0xFFFFB347))),
                  ]),
                ),
              ),
            ],

            // ✅ أزرار القبول / الرفض — تظهر فقط وهو معلّق
            if (isPending) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _Tap(
                  onTap: onReject,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5A5F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFF5A5F).withValues(alpha: 0.3)),
                    ),
                    child: Center(child: Text(L.get('reject'),
                        style: const TextStyle(color: Color(0xFFFF5A5F), fontSize: 13, fontWeight: FontWeight.bold))),
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(child: _Tap(
                  onTap: onAccept,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C897),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(L.get('accept'),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                  ),
                )),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  ✅ 2) واجهة خدمات توصيل الركاب — مين طلب / عدد الركاب / مكان
//  الانتظار / مين السيارة يلي وصلتلهم / من أي خط
// ════════════════════════════════════════════════════════════════
class _DeliveryView extends StatefulWidget {
  const _DeliveryView();
  @override
  State<_DeliveryView> createState() => _DeliveryViewState();
}

class _DeliveryViewState extends State<_DeliveryView> {
  bool _loading = false;

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final fetched = await _RequestsRepository.fetchRequests();
      setState(() {
        globalDeliveryRequests = fetched.where((r) => r.type == RequestType.passengers).toList();
      });
      await saveDeliveryRequests();
    } catch (_) {}
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _availableVehicles {
    final out = <Map<String, dynamic>>[];
    for (int i = 0; i < globalLines.length; i++) {
      final line = globalLines[i];
      if (i >= globalVehicles.length) continue;
      for (final v in globalVehicles[i]) {
        out.add({'vehicle': v, 'lineName': line.name});
      }
    }
    return out;
  }

  void _assignVehicle(ExternalRequest r) {
    final vehicles = _availableVehicles;
    Map<String, dynamic>? selected;
    showDialog(
      context: context,
      builder: (dCtx) => StatefulBuilder(builder: (dCtx, setDlg) => Directionality(
        textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(L.get('assign_vehicle'), style: TextStyle(fontWeight: FontWeight.bold, color: dCtx.textPrimary)),
          content: SizedBox(
            width: 320,
            child: vehicles.isEmpty
                ? Text(L.get('no_data'), style: TextStyle(color: dCtx.textSecondary))
                : SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min,
                      children: vehicles.map((v) {
                        final lv = v['vehicle'] as LineVehicle;
                        final ln = v['lineName'] as String;
                        final sel = selected != null && (selected!['vehicle'] as LineVehicle).vehicleId == lv.vehicleId;
                        return _Tap(
                          onTap: () => setDlg(() => selected = v),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: sel ? const Color(0xFF00C897).withValues(alpha: 0.1) : dCtx.bgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: sel ? const Color(0xFF00C897) : dCtx.dividerColor),
                            ),
                            child: Row(children: [
                              Icon(Icons.directions_car_outlined, size: 16,
                                  color: sel ? const Color(0xFF00C897) : dCtx.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(lv.vehicleId, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: dCtx.textPrimary)),
                                Text('${lv.driverName.isNotEmpty ? lv.driverName : L.get('no_driver')} — $ln',
                                    style: TextStyle(fontSize: 11, color: dCtx.textSecondary)),
                              ])),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(L.get('cancel'))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C897),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: selected == null ? null : () {
                final lv = selected!['vehicle'] as LineVehicle;
                final ln = selected!['lineName'] as String;
                setState(() {
                  final idx = globalDeliveryRequests.indexWhere((x) => x.id == r.id);
                  if (idx != -1) {
                    globalDeliveryRequests[idx] = r.copyWith(
                      status: RequestStatus.accepted,
                      assignedVehicleId: lv.vehicleId,
                      assignedDriver: lv.driverName,
                      assignedLine: ln,
                    );
                  }
                });
                saveDeliveryRequests();
                Navigator.pop(dCtx);
              },
              child: Text(L.get('confirm'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )),
    );
  }

  void _reject(ExternalRequest r) {
    setState(() {
      final idx = globalDeliveryRequests.indexWhere((x) => x.id == r.id);
      if (idx != -1) globalDeliveryRequests[idx] = r.copyWith(status: RequestStatus.cancelled);
    });
    saveDeliveryRequests();
  }

  @override
  Widget build(BuildContext context) {
    final items = globalDeliveryRequests;
    return Column(children: [
      Container(
        color: context.cardColor,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          _StatBadge(L.get('req_status_pending'),
              items.where((r) => r.status == RequestStatus.pending).length, const Color(0xFFFFB347)),
          _StatBadge(L.get('req_status_accepted'),
              items.where((r) => r.status == RequestStatus.accepted).length, const Color(0xFF00C897)),
          _StatBadge(L.get('req_status_cancelled'),
              items.where((r) => r.status == RequestStatus.cancelled).length, const Color(0xFFFF5A5F)),
          _Tap(
            onTap: _refresh,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: context.bgColor, borderRadius: BorderRadius.circular(8)),
              child: _loading
                  ? SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: context.textSecondary, strokeWidth: 2))
                  : Icon(Icons.refresh_rounded, color: context.textSecondary, size: 18),
            ),
          ),
        ]),
      ),
      Expanded(
        child: items.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(L.get('no_delivery_requests'), style: TextStyle(color: Colors.grey[400], fontSize: 15)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) => _DeliveryCard(
                  request: items[i],
                  onAssign: () => _assignVehicle(items[i]),
                  onReject: () => _reject(items[i]),
                ),
              ),
      ),
    ]);
  }
}

// ── بطاقة طلب التوصيل ──────────────────────
class _DeliveryCard extends StatelessWidget {
  final ExternalRequest request;
  final VoidCallback onAssign;
  final VoidCallback onReject;
  const _DeliveryCard({required this.request, required this.onAssign, required this.onReject});

  Color get _statusColor {
    switch (request.status) {
      case RequestStatus.pending:    return const Color(0xFFFFB347);
      case RequestStatus.accepted:   return const Color(0xFF00C897);
      case RequestStatus.inProgress: return const Color(0xFF4B9EFF);
      case RequestStatus.completed:  return const Color(0xFF2E7D32);
      case RequestStatus.cancelled:  return const Color(0xFFFF5A5F);
    }
  }

  String _statusLabel() {
    switch (request.status) {
      case RequestStatus.pending:    return L.get('req_status_pending');
      case RequestStatus.accepted:   return L.get('req_status_accepted');
      case RequestStatus.inProgress: return L.get('req_status_in_progress');
      case RequestStatus.completed:  return L.get('req_status_completed');
      case RequestStatus.cancelled:  return L.get('req_status_cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    const typeColor = Color(0xFF4B9EFF);
    final isPending = request.status == RequestStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: isPending ? Border.all(color: const Color(0xFFFFB347).withValues(alpha: 0.5)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

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
              child: const Icon(Icons.people_outline, size: 16, color: typeColor),
            ),
            const SizedBox(width: 8),
            Text(request.id, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(_statusLabel(), style: TextStyle(fontSize: 11, color: _statusColor, fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ✅ مين الشخص اللي طلب
            if (request.senderName != null) ...[
              Row(children: [
                const Icon(Icons.person_outline, size: 14, color: Color(0xFF8A93A8)),
                const SizedBox(width: 6),
                Text(request.senderName!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
              ]),
              const SizedBox(height: 6),
            ],

            // ✅ عدد الركاب
            if (request.passengersCount != null)
              _infoChip(Icons.groups_outlined, '${request.passengersCount} ${L.get('passenger_count')}', const Color(0xFF4B9EFF)),
            const SizedBox(height: 6),

            // ✅ مكان الانتظار
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF00C897)),
              const SizedBox(width: 6),
              Text(L.get('waiting_location'), style: TextStyle(fontSize: 11, color: context.textSecondary)),
              const SizedBox(width: 4),
              Expanded(child: Text(request.location, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.flag_outlined, size: 14, color: Color(0xFFFF5A5F)),
              const SizedBox(width: 6),
              Expanded(child: Text(request.destination, style: TextStyle(fontSize: 12, color: context.textPrimary))),
            ]),
            const SizedBox(height: 8),

            Row(children: [
              _infoChip(Icons.phone_outlined, request.contactPhone, const Color(0xFF00C897)),
              const Spacer(),
              Text(_formatReqTime(request.createdAt), style: TextStyle(fontSize: 10, color: context.textSecondary)),
            ]),

            // ✅ مين السيارة يلي وصلتلهم + من أي خط
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
                    Text(L.get('movement_order'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00C897))),
                  ]),
                  const SizedBox(height: 6),
                  _reqDetailRow(L.get('assigned_vehicle'), request.assignedVehicleId!, context),
                  if (request.assignedDriver != null)
                    _reqDetailRow(L.get('assigned_driver'), request.assignedDriver!, context),
                  if (request.assignedLine != null)
                    _reqDetailRow(L.get('assigned_line'), request.assignedLine!, context),
                ]),
              ),
            ],

            // ✅ أزرار التعيين/الرفض — تظهر فقط وهو معلّق
            if (isPending) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _Tap(
                  onTap: onReject,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5A5F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFF5A5F).withValues(alpha: 0.3)),
                    ),
                    child: Center(child: Text(L.get('reject'),
                        style: const TextStyle(color: Color(0xFFFF5A5F), fontSize: 13, fontWeight: FontWeight.bold))),
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(child: _Tap(
                  onTap: onAssign,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(color: const Color(0xFF00C897), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(L.get('assign_vehicle'),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                  ),
                )),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}

Widget _reqDetailRow(String label, String value, BuildContext ctx) => Padding(
  padding: const EdgeInsets.only(bottom: 3),
  child: Row(children: [
    Text('$label: ', style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
    Expanded(child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ctx.textPrimary),
        overflow: TextOverflow.ellipsis)),
  ]),
);
