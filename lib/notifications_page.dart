part of station_app;

class _NotificationsPage extends StatefulWidget {
  const _NotificationsPage();
  @override
  State<_NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<_NotificationsPage> with DarkModeRebuild<_NotificationsPage> {
  List<Map<String, String>> get _notifs {
    return globalEvents.map((e) => {
      'title': e.type == EventType.entry ? 'مركبة دخلت'
             : e.type == EventType.exit  ? 'مركبة خرجت'
             : 'مخالفة جديدة',
      'body': '${e.vehicleId} • ${e.location}',
      'time': e.time,
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
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
          title: Text(L.get('notifications'),
              style: TextStyle(color: context.textPrimary,
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: _notifs.isEmpty
            ? Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No notifications yet',
                      style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                ],
              ))
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: _notifs.length,
          itemBuilder: (context, i) {
            final n = _notifs[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    child: Row(
                      children: [
                        // Bell icon
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: n['type'] == 'banned'
                                ? const Color(0xFFFF5A5F).withValues(alpha: 0.12)
                                : n['type'] == 'supervisor_alert'
                                    ? const Color(0xFFFFB347).withValues(alpha: 0.12)
                                    : const Color(0xFF2D3A5C).withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            n['type'] == 'banned'
                                ? Icons.block_rounded
                                : n['type'] == 'supervisor_alert'
                                    ? Icons.warning_amber_rounded
                                    : Icons.notifications_outlined,
                            color: n['type'] == 'banned'
                                ? const Color(0xFFFF5A5F)
                                : n['type'] == 'supervisor_alert'
                                    ? const Color(0xFFFFB347)
                                    : const Color(0xFF2D3A5C),
                            size: 20),
                        ),
                        const SizedBox(width: 14),
                        // Title + body
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n['title']!,
                                  style: TextStyle(fontWeight: FontWeight.bold,
                                      fontSize: 14, color: context.textPrimary)),
                              const SizedBox(height: 4),
                              Text(n['body']!,
                                  style: TextStyle(fontSize: 12, color: context.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(n['time']!,
                            style: TextStyle(fontSize: 11, color: context.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}