import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kuangan/shared/utils/responsive.dart';

class NavigationShell extends StatelessWidget {
  const NavigationShell({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final primaryColor = Theme.of(context).primaryColor;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final isCompact = Responsive.isCompact(context);
    final navBarHeight = isCompact ? 60.0 : 64.0;
    final navContainerBottom = isCompact ? 16.0 : 24.0;
    final fabBottom = isCompact ? 22.0 : 32.0;
    final horizontalInset = isCompact ? 12.0 : 20.0;
    final centerGap = isCompact ? 48.0 : 56.0;

    int getIndex() {
      if (location.startsWith('/dashboard')) return 0;
      if (location.startsWith('/transactions')) return 1;
      if (location.startsWith('/ai-scan')) return 2;
      if (location.startsWith('/reports')) return 3;
      if (location.startsWith('/settings')) return 4;
      return 0;
    }

    final currentIndex = getIndex();

    void onTabTapped(int index) {
      if (index == getIndex()) return;
      switch (index) {
        case 0:
          context.go('/dashboard');
          break;
        case 1:
          context.go('/transactions');
          break;
        case 2:
          context.go('/ai-scan');
          break;
        case 3:
          context.go('/reports');
          break;
        case 4:
          context.go('/settings');
          break;
      }
    }

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        reverseDuration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (widget, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(curved);
          final scale = Tween<double>(
            begin: 0.985,
            end: 1.0,
          ).animate(curved);

          return ClipRect(
            child: ScaleTransition(
              scale: scale,
              child: SlideTransition(
                position: slide,
                child: widget,
              ),
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(location),
          child: child,
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: navBarHeight + safeBottom + 56,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: safeBottom + navContainerBottom,
              left: horizontalInset,
              right: horizontalInset,
              child: Container(
                height: navBarHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildNavButton(
                          0,
                          Icons.grid_view_rounded,
                          Icons.grid_view_outlined,
                          'Beranda',
                          currentIndex,
                          onTabTapped,
                          primaryColor,
                          isCompact),
                    ),
                    Expanded(
                      child: _buildNavButton(
                          1,
                          Icons.receipt_long_rounded,
                          Icons.receipt_long_outlined,
                          'Riwayat',
                          currentIndex,
                          onTabTapped,
                          primaryColor,
                          isCompact),
                    ),
                    SizedBox(width: centerGap),
                    Expanded(
                      child: _buildNavButton(
                          3,
                          Icons.bar_chart_rounded,
                          Icons.bar_chart_outlined,
                          'Laporan',
                          currentIndex,
                          onTabTapped,
                          primaryColor,
                          isCompact),
                    ),
                    Expanded(
                      child: _buildNavButton(
                          4,
                          Icons.settings_rounded,
                          Icons.settings_outlined,
                          'Atur',
                          currentIndex,
                          onTabTapped,
                          primaryColor,
                          isCompact),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: safeBottom + fabBottom,
              child: GestureDetector(
                onTap: () => onTabTapped(2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 10 : 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF6366F1).withValues(alpha: 0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(Icons.document_scanner_rounded,
                          color: Colors.white, size: isCompact ? 24 : 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan',
                      style: TextStyle(
                        fontSize: isCompact ? 10 : 11,
                        fontWeight: currentIndex == 2
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: currentIndex == 2
                            ? primaryColor
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(
      int index,
      IconData activeIcon,
      IconData icon,
      String label,
      int currentIndex,
      Function(int) onTap,
      Color primaryColor,
      bool isCompact) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? primaryColor : const Color(0xFF94A3B8),
              size: isCompact ? 22 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
