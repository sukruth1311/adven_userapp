import 'package:flutter/material.dart';
import 'package:user_app/features/user/documents_screen.dart';
import 'package:user_app/features/user/services/hotel_request_screen.dart';
import 'package:user_app/features/user/profile_screen.dart';
import 'package:user_app/themes/app_theme.dart';
import 'user_home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;

  static const List<Widget> _pages = [
    UserHomeScreen(),
    HotelRequestScreen(),
    DocumentsScreen(),
    ProfileScreen(),
  ];

  static const _items = [
    _NI(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _NI(Icons.hotel_outlined, Icons.hotel_rounded, 'Hotel'),
    _NI(Icons.folder_outlined, Icons.folder_rounded, 'Docs'),
    _NI(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _idx,
        items: _items,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}

// ── BOTTOM NAV ────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<_NI> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Measure bottom padding for devices with home indicator
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      // 64px tap area + safe bottom inset
      padding: EdgeInsets.only(
        left: 6,
        right: 6,
        top: 8,
        bottom: bottomPadding > 0 ? bottomPadding : 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final sel = selectedIndex == i;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primarySurface : Colors.transparent,
                  borderRadius: AppRadius.medium,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sel ? item.activeIcon : item.icon,
                      color: sel ? AppColors.primary : AppColors.textHint,
                      size: 22,
                    ),
                    // Only show label when selected, clipped with overflow protection
                    if (sel) ...[
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          item.label,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NI {
  final IconData icon, activeIcon;
  final String label;
  const _NI(this.icon, this.activeIcon, this.label);
}
