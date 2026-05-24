part of station_app;

// ── Dashboard Shared Widgets ─────────────────────────────────────
class _HeaderCard extends StatefulWidget {
  const _HeaderCard();
  @override
  State<_HeaderCard> createState() => _HeaderCardState();
}
class _HeaderCardState extends State<_HeaderCard> with DarkModeRebuild<_HeaderCard> {
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return L.get('greeting_morning');
    if (h < 17) return L.get('greeting_afternoon');
    return L.get('greeting_evening');
  }
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D3A5C), Color(0xFF3D5080)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Title + greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting() + '، $profileName',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text(L.get('dashboard'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          // Notification icon — tappable
          _Tap(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _NotificationsPage()),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar — tappable
          _Tap(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _ProfilePage()),
            ),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white30,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Section title
// ─────────────────────────────────────────────
class _SectionTitle extends StatefulWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  State<_SectionTitle> createState() => _SectionTitleState();
}
class _SectionTitleState extends State<_SectionTitle> with DarkModeRebuild<_SectionTitle> {
  @override
  Widget build(BuildContext context) {
    return Text(
      widget.title,
      style: TextStyle(
        color: context.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Stats 2×2 grid
// ─────────────────────────────────────────────
class _StatsGrid extends StatefulWidget {
  final List<StatItem> stats;
  const _StatsGrid({required this.stats});
  @override
  State<_StatsGrid> createState() => _StatsGridState();
}

class _StatsGridState extends State<_StatsGrid> with DarkModeRebuild<_StatsGrid> {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: widget.stats.map((s) => _StatCard(item: s)).toList(),
    );
  }
}

// ─────────────────────────────────────────────
//  Single stat card
// ─────────────────────────────────────────────
class _StatCard extends StatefulWidget {
  final StatItem item;
  const _StatCard({required this.item});
  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> with DarkModeRebuild<_StatCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${widget.item.value}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: context.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F2F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add, size: 16, color: context.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.item.label,
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Single event card
// ─────────────────────────────────────────────
class _EventCard extends StatefulWidget {
  final EventItem event;
  const _EventCard({required this.event});
  @override
  State<_EventCard> createState() => _EventCardState();
}
class _EventCardState extends State<_EventCard> with DarkModeRebuild<_EventCard> {
  Color get _badgeBg {
    switch (widget.event.type) {
      case EventType.entry:
        return const Color(0xFFE8F5E9);
      case EventType.exit:
        return const Color(0xFFFFF3E0);
      case EventType.violation:
        return const Color(0xFFFFEBEE);
    }
  }

  Color get _badgeText {
    switch (widget.event.type) {
      case EventType.entry:
        return const Color(0xFF2E7D32);
      case EventType.exit:
        return const Color(0xFFE65100);
      case EventType.violation:
        return const Color(0xFFC62828);
    }
  }

  String get _badgeLabel {
    switch (widget.event.type) {
      case EventType.entry:
        return L.get('entry');
      case EventType.exit:
        return L.get('exit');
      case EventType.violation:
        return L.get('violation');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _badgeLabel,
              style: TextStyle(
                color: _badgeText,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Vehicle info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.vehicleId,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.event.location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A93A8),
                  ),
                ),
              ],
            ),
          ),

          // Time
          Text(
            widget.event.time,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8A93A8),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
//  Permits Page (صفحة الأذونات)
// ─────────────────────────────────────────────

/// نموذج الإذن — يرث من BaseModel (id=id, status=status)
// ── نموذج طلب الإذن ─────────────────────────

// قائمة طلبات الأذونات