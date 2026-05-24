part of station_app;

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with DarkModeRebuild<UsersPage>, SearchFilterMixin<UserModel> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override List<String> get filterOptions => [L.get('all'), L.get('driver'), L.get('security'), L.get('supervisor_role')];

  @override
  bool itemMatchesSearch(UserModel u, String q) =>
      u.name.contains(q) || u.role.contains(q) || u.idNumber.contains(q) || u.phone.contains(q);

  @override
  bool itemMatchesFilter(UserModel u, String f) {
    if (f == L.get('driver'))          return u.role == 'سائق';
    if (f == L.get('security'))        return u.role == 'موظف أمن';
    if (f == L.get('supervisor_role')) return u.role == 'مشرف خط';
    return false;
  }

  List<UserModel> get _filtered => applyFilter(globalUsers);

  Color _statusColor(String status) {
    switch (status) {
      case 'نشط':    return const Color(0xFF2E7D32);
      case 'علق':
      case 'معلق':   return const Color(0xFFE65100);
      default:        return const Color(0xFFC62828);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'نشط':    return const Color(0xFFE8F5E9);
      case 'علق':
      case 'معلق':   return const Color(0xFFFFF3E0);
      default:        return const Color(0xFFFFEBEE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = _filtered;
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(color: Color(0xFF2D3A5C)),
            child: Row(children: [
              Expanded(
                child: Text(L.get('users'),
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ]),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Spacer(),
                    _Tap(
                      onTap: () async {
                        final newUser = await Navigator.push<UserModel>(
                          context,
                          MaterialPageRoute(builder: (_) => const AddUserPage()),
                        );
                        if (newUser != null) {
                          setState(() => globalUsers.add(newUser));
                          autoSave();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D3A5C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          const Icon(Icons.add, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(L.get('add'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filterOptions.map((f) {
                      final selected = f == activeFilter;
                      return _Tap(
                        onTap: () => setState(() => activeFilter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF2D3A5C) : context.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? const Color(0xFF2D3A5C) : context.dividerColor),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                          ),
                          child: Text(f,
                              style: TextStyle(
                                color: selected ? Colors.white : context.textSecondary,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: users.isEmpty
                        ? Center(child: Text(L.get('no_data'),
                            style: TextStyle(color: Colors.grey[400], fontSize: 15)))
                        : ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (_, i) {
                              final u = users[i];
                              return _Tap(
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => _UserInfoPage(user: u),
                                )),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: context.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 5)],
                                  ),
                                  child: Row(children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: const Color(0xFF2D3A5C).withValues(alpha: 0.1),
                                      child: Text(u.name[0],
                                          style: TextStyle(color: context.textPrimary,
                                              fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(u.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                                        const SizedBox(height: 3),
                                        Text(u.role, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                      ]),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _statusBg(u.status),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(u.status,
                                          style: TextStyle(color: _statusColor(u.status),
                                              fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    _Tap(
                                      onTap: () async {
                                        final updated = await Navigator.push<UserModel>(
                                          context,
                                          MaterialPageRoute(builder: (_) => EditUserPage(user: u)),
                                        );
                                        if (updated != null) {
                                          setState(() {
                                            final idx = globalUsers.indexOf(u);
                                            if (idx != -1) globalUsers[idx] = updated;
                                          });
                                          autoSave();
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: context.textPrimary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.edit_outlined, color: Color(0xFF2D3A5C), size: 18),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _Tap(
                                      onTap: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => Directionality(
                                            textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
                                            child: AlertDialog(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              title: Text(L.get('delete_confirm'),
                                                  style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
                                              content: Text('${L.get('delete_confirm')} "${u.name}"؟'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: Text(L.get('cancel'), style: TextStyle(color: context.textSecondary)),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: Text(L.get('delete'),
                                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                        if (confirm == true) {
                                          setState(() => globalUsers.remove(u));
                                          autoSave();
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                      ),
                                    ),
                                  ]),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}