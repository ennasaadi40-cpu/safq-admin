part of station_app;

// ════════════════════════════════════════════════════════════════
//  API Config — غيّر BASE_URL عند ربط الـ Backend
// ════════════════════════════════════════════════════════════════
class _ApiConfig {
  static const String baseUrl   = 'https://your-api.example.com/api/v1';
  static const String adminKey  = 'your-admin-api-key';
  static const int    timeout   = 10; // seconds
}

// ════════════════════════════════════════════════════════════════
//  نموذج بيانات الطلب
// ════════════════════════════════════════════════════════════════
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
  });

  ExternalRequest copyWith({
    RequestStatus? status,
    String? assignedVehicleId,
    String? assignedDriver,
    String? assignedLine,
    String? movementOrderNote,
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

// ════════════════════════════════════════════════════════════════
//  Repository — يستدعي API الحقيقي أو يرجع بيانات محلية
// ════════════════════════════════════════════════════════════════
class _RequestsRepository {
  // GET /admin/requests  — جلب الطلبات للأدمن
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
    // fallback: البيانات المحلية
    return globalRequests;
  }

  // GET /lines — جلب الخطوط المتاحة
  static Future<List<Map<String, String>>> fetchLines() async {
    try {
      final res = await http.get(
        Uri.parse('${_ApiConfig.baseUrl}/lines'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: _ApiConfig.timeout));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map<Map<String, String>>((e) => {
          'line_id':   e['line_id']   ?? '',
          'line_name': e['line_name'] ?? '',
        }).toList();
      }
    } catch (_) {}
    return globalLines.map((l) => {'line_id': l.entryGateId, 'line_name': l.name}).toList();
  }

  static Future<String> _getAdminToken() async => 'mock-token';
}

// ════════════════════════════════════════════════════════════════
//  Storage
// ════════════════════════════════════════════════════════════════
List<ExternalRequest> globalRequests = [];

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
  // أضف بيانات وهمية إذا فارغ
  if (globalRequests.isEmpty) {
    globalRequests = [
      ExternalRequest(
        id: 'ER-001', type: RequestType.passengers, status: RequestStatus.pending,
        location: 'الخليل — حي الشيخ', destination: 'بيت لحم — المركز',
        contactPhone: '0599123456', createdAt: '2025-05-19T08:00:00',
        senderName: 'سامر أبو عيشة', lineName: 'الخليل / بيت لحم',
        passengersCount: 3,
      ),
      ExternalRequest(
        id: 'ER-002', type: RequestType.parcel, status: RequestStatus.pending,
        location: 'الخليل — باب الزاوية', destination: 'رام الله — البيرة',
        contactPhone: '0598765432', createdAt: '2025-05-19T09:30:00',
        senderName: 'منى الجعبري', lineName: 'الخليل / رام الله',
        parcelName: 'مستندات رسمية', parcelDetails: 'مظروف مختوم — عاجل',
      ),
      ExternalRequest(
        id: 'ER-003', type: RequestType.passengers, status: RequestStatus.accepted,
        location: 'الخليل — الحرس', destination: 'القدس — باب العمود',
        contactPhone: '0597654321', createdAt: '2025-05-18T14:00:00',
        senderName: 'خالد العمر', lineName: 'الخليل / القدس',
        passengersCount: 2,
        assignedVehicleId: '12-234-12', assignedDriver: 'أحمد إسماعيل الحج',
        assignedLine: '[101] الخليل → بيت لحم',
      ),
      ExternalRequest(
        id: 'ER-004', type: RequestType.parcel, status: RequestStatus.cancelled,
        location: 'الخليل — صحراء', destination: 'نابلس — المركز',
        contactPhone: '0592111222', createdAt: '2025-05-17T11:15:00',
        senderName: 'ريم حسن', lineName: 'الخليل / نابلس',
        parcelName: 'بضاعة تجارية', parcelDetails: 'صندوق متوسط الحجم',
      ),
      ExternalRequest(
        id: 'ER-005', type: RequestType.passengers, status: RequestStatus.pending,
        location: 'الخليل — عين سارة', destination: 'دورا — المركز',
        contactPhone: '0591999888', createdAt: '2025-05-19T10:45:00',
        senderName: 'عمر الشريف', lineName: 'الخليل / دورا',
        passengersCount: 1,
      ),
    ];
  }
}

// ════════════════════════════════════════════════════════════════
//  صفحة الطلبات
// ════════════════════════════════════════════════════════════════
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});
  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage>
    with DarkModeRebuild<RequestsPage> {
  String _activeFilter = 'الكل';
  bool   _loading     = false;
  final List<String> _filters = ['الكل', 'مقبول', 'مرفوض'];

  List<ExternalRequest> get _allRequests => globalRequests;

  List<ExternalRequest> get _filtered {
    switch (_activeFilter) {
      case 'معلق':  return _allRequests.where((r) => r.status == RequestStatus.pending).toList();
      case 'مقبول': return _allRequests.where((r) => r.status == RequestStatus.accepted || r.status == RequestStatus.inProgress || r.status == RequestStatus.completed).toList();
      case 'مرفوض': return _allRequests.where((r) => r.status == RequestStatus.cancelled).toList();
      default:      return _allRequests;
    }
  }

  int get _pendingCount =>
      _allRequests.where((r) => r.status == RequestStatus.pending).length;

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final fetched = await _RequestsRepository.fetchRequests();
      setState(() { globalRequests = fetched; });
      await saveRequests();
    } catch (_) {}
    setState(() => _loading = false);
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
              onTap: _refresh,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                child: _loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),


        // ── إحصائيات (طلبات) ──
        Container(
          color: context.cardColor,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Row(children: [
            _StatBadge('الكل',   _allRequests.length, const Color(0xFF2D3A5C)),
            _StatBadge('معلق',   _allRequests.where((r) => r.status == RequestStatus.pending).length, const Color(0xFFFFB347)),
            _StatBadge('مقبول',  _allRequests.where((r) => r.status == RequestStatus.accepted).length, const Color(0xFF00C897)),
            _StatBadge('مرفوض', _allRequests.where((r) => r.status == RequestStatus.cancelled).length, const Color(0xFFFF5A5F)),
          ]),
        ),

        // ── فلاتر (طلبات) ──
        Container(
          color: context.cardColor,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(children: _filters.map((f) {
              final sel = f == _activeFilter;
              Color accent = const Color(0xFF2D3A5C);
              if (f == 'معلق')  accent = const Color(0xFFFFB347);
              else if (f == 'مقبول')  accent = const Color(0xFF00C897);
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
        Expanded(child: _buildRequests()),
      ]),
    );
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
  final int    count;
  final Color  color;
  const _StatBadge(this.label, this.count, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: TextStyle(fontSize: 10, color: context.textSecondary)),
  ]));
}

// ─────────────────────────────────────────────
//  بطاقة الطلب
// ─────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final ExternalRequest request;
  const _RequestCard({required this.request});

  Color get _statusColor {
    switch (request.status) {
      case RequestStatus.pending:    return const Color(0xFFFFB347);
      case RequestStatus.accepted:   return const Color(0xFF00C897);
      case RequestStatus.inProgress: return const Color(0xFF4B9EFF);
      case RequestStatus.completed:  return const Color(0xFF2E7D32);
      case RequestStatus.cancelled:  return const Color(0xFFFF5A5F);
    }
  }

  String get _statusLabel {
    switch (request.status) {
      case RequestStatus.pending:    return 'معلق';
      case RequestStatus.accepted:   return 'مقبول';
      case RequestStatus.inProgress: return 'قيد التنفيذ';
      case RequestStatus.completed:  return 'مكتمل';
      case RequestStatus.cancelled:  return 'مرفوض';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isParcel   = request.type == RequestType.parcel;
    final typeColor  = isParcel ? const Color(0xFFB47AFF) : const Color(0xFF4B9EFF);
    final typeIcon   = isParcel ? Icons.inventory_2_outlined : Icons.people_outlined;
    final typeLabel  = isParcel ? 'طرد' : 'ركاب';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: request.status == RequestStatus.pending
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
              child: Icon(typeIcon, size: 16, color: typeColor),
            ),
            const SizedBox(width: 8),
            Text(typeLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: typeColor)),
            const SizedBox(width: 8),
            Text(request.id, style: TextStyle(fontSize: 11, color: context.textSecondary)),
            const Spacer(),
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

            // المرسل
            if (request.senderName != null) ...[
              Row(children: [
                const Icon(Icons.person_outline, size: 14, color: Color(0xFF8A93A8)),
                const SizedBox(width: 6),
                Text(request.senderName!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
              ]),
              const SizedBox(height: 6),
            ],

            // الموقع والوجهة
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF00C897)),
              const SizedBox(width: 6),
              Expanded(child: Text(request.location,
                  style: TextStyle(fontSize: 12, color: context.textPrimary))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.flag_outlined, size: 14, color: Color(0xFFFF5A5F)),
              const SizedBox(width: 6),
              Expanded(child: Text(request.destination,
                  style: TextStyle(fontSize: 12, color: context.textPrimary))),
            ]),

            // الخط
            if (request.lineName != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.route_outlined, size: 14, color: Color(0xFF8A93A8)),
                const SizedBox(width: 6),
                Text(request.lineName!, style: TextStyle(fontSize: 11, color: context.textSecondary)),
              ]),
            ],
            const SizedBox(height: 8),

            // تفاصيل إضافية
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

            Row(children: [
              _InfoChip(Icons.phone_outlined, request.contactPhone, const Color(0xFF00C897)),
              const Spacer(),
              Text(_formatTime(request.createdAt),
                  style: TextStyle(fontSize: 10, color: context.textSecondary)),
            ]),

            // أمر الحركة
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
                  const Row(children: [
                    Icon(Icons.directions_car_rounded, size: 13, color: Color(0xFF00C897)),
                    SizedBox(width: 6),
                    Text('أمر الحركة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00C897))),
                  ]),
                  const SizedBox(height: 6),
                  if (request.assignedVehicleId != null)
                    _OrderDetailRow('المركبة', request.assignedVehicleId!),
                  if (request.assignedDriver != null)
                    _OrderDetailRow('السائق', request.assignedDriver!),
                  if (request.assignedLine != null)
                    _OrderDetailRow('الخط', request.assignedLine!),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _InfoChip(IconData icon, String text, Color color) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
      ]);

  Widget _OrderDetailRow(String label, String value) => Builder(builder: (ctx) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(children: [
      Text('$label: ', style: TextStyle(fontSize: 11, color: ctx.textSecondary)),
      Expanded(child: Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ctx.textPrimary), overflow: TextOverflow.ellipsis)),
    ]),
  ));

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} - ${dt.day}/${dt.month}';
    } catch (_) { return iso; }
  }
}