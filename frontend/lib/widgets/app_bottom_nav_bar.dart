import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Navigation item data model
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Reusable bottom navigation bar widget
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavItem> items;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = defaultItems,
  });

  /// Default navigation items for the app
  static const List<NavItem> defaultItems = [
    NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    NavItem(
      icon: Icons.show_chart_outlined,
      activeIcon: Icons.show_chart,
      label: 'Tracking',
    ),
    NavItem(
      icon: Icons.self_improvement_outlined,
      activeIcon: Icons.self_improvement,
      label: 'Therapy',
    ),
    NavItem(
      icon: Icons.sports_esports_outlined,
      activeIcon: Icons.sports_esports,
      label: 'Games',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (index) => _NavItemWidget(
                item: items[index],
                isActive: currentIndex == index,
                onTap: () => onTap(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual navigation item widget
class _NavItemWidget extends StatelessWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? item.activeIcon : item.icon,
            color: isActive ? AppColors.primary : AppColors.textHint,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isActive ? AppColors.primary : AppColors.textHint,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          // Active indicator dot
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 4 : 0,
            height: isActive ? 4 : 0,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
