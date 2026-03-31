import 'package:flutter/material.dart';
import '../theme/app_design_system.dart';
import '../theme/app_components.dart';

class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              return _NavItem(
                item: items[index],
                isSelected: currentIndex == index,
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final BottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : Colors.transparent,
          borderRadius: AppBorderRadius.fullAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                size: 24,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  item.label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? badge;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
  });
}

class CircleBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CircleBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CircleBottomNavBar> createState() => _CircleBottomNavBarState();
}

class _CircleBottomNavBarState extends State<CircleBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _CircleNavItem(
              icon: Icons.map_outlined,
              activeIcon: Icons.map,
              label: 'Mapa',
              isSelected: widget.currentIndex == 0,
              onTap: () => widget.onTap(0),
            ),
            _CircleNavItem(
              icon: Icons.people_outline,
              activeIcon: Icons.people,
              label: 'Miembros',
              isSelected: widget.currentIndex == 1,
              onTap: () => widget.onTap(1),
            ),
            _CenterNavButton(
              isSelected: false,
              onTap: () {},
            ),
            _CircleNavItem(
              icon: Icons.place_outlined,
              activeIcon: Icons.place,
              label: 'Lugares',
              isSelected: widget.currentIndex == 2,
              onTap: () => widget.onTap(2),
            ),
            _CircleNavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Ajustes',
              isSelected: widget.currentIndex == 4,
              onTap: () => widget.onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CircleNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterNavButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CenterNavButton({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppGradients.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: AppShadows.button,
        ),
        child: const Icon(
          Icons.history,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}