part of station_app;

// ── Shared Widgets ──────────────────────────────────────────────
class _Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? hoverColor;
  final BorderRadius? borderRadius;
  const _Tap({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.hoverColor,
    this.borderRadius,
  });
  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hoverBg = widget.hoverColor ??
        (isDark
            ? const Color(0xFF2D3A5C).withValues(alpha: 0.25)
            : const Color(0xFF2D3A5C).withValues(alpha: 0.07));
    final pressBg = isDark
        ? const Color(0xFF2D3A5C).withValues(alpha: 0.4)
        : const Color(0xFF2D3A5C).withValues(alpha: 0.14);

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() { _hovered = false; _pressed = false; }),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp:   (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: widget.onTap == null
                ? Colors.transparent
                : _pressed
                    ? pressBg
                    : _hovered
                        ? hoverBg
                        : Colors.transparent,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String title;
  const _PlaceholderPage({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: context.textPrimary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              L.isArabic ? 'قريباً...' : 'Coming soon...',
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _BottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: context.cardColor,
      selectedItemColor: context.isDark ? Colors.lightBlueAccent : const Color(0xFF2D3A5C),
      unselectedItemColor: context.isDark ? Colors.grey[500] : const Color(0xFFB0B8CC),
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: items
          .map((n) => BottomNavigationBarItem(
                icon: Icon(n.icon),
                label: n.label,
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────
//  Searchable Dropdown
// ─────────────────────────────────────────────
class _SearchableDropdown extends StatefulWidget {
  final String hint;
  final List<String> items;
  final String? selected;
  final void Function(String?) onSelected;
  final String? Function(String?)? validator;
  const _SearchableDropdown({
    required this.hint,
    required this.items,
    required this.onSelected,
    this.selected,
    this.validator,
  });
  @override
  State<_SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<_SearchableDropdown> {
  final _ctrl = TextEditingController();
  bool _showList = false;
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.selected ?? '';
    _filtered = widget.items;
  }

  void _filter(String q) {
    setState(() {
      _filtered = widget.items.where((i) => i.contains(q)).toList();
      _showList = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.selected,
      validator: widget.validator,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _ctrl,
            textDirection: L.isArabic ? TextDirection.rtl : TextDirection.ltr,
            onChanged: _filter,
            onTap: () => setState(() { _showList = true; _filtered = widget.items; }),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: context.cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: Icon(Icons.search, color: context.textSecondary, size: 18),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: state.hasError ? Colors.red : context.dividerColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2D3A5C), width: 1.5)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red)),
            ),
          ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 12),
              child: Text(state.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          if (_showList && _filtered.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.dividerColor),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filtered.length,
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  title: Text(_filtered[i], style: TextStyle(fontSize: 14, color: context.textPrimary)),
                  onTap: () {
                    setState(() {
                      _ctrl.text = _filtered[i];
                      _showList = false;
                    });
                    widget.onSelected(_filtered[i]);
                    state.didChange(_filtered[i]);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}