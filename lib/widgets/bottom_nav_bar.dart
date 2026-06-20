// ─── bottom_nav_bar.dart ─────────────────────────────────────────────────────
// Save as: lib/widgets/bottom_nav_bar.dart

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../routes/app_router.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const AppBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      const _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home', route: AppRouter.dashboard),
      const _NavItem(icon: Icons.medication_outlined, activeIcon: Icons.medication, label: 'Medications', route: AppRouter.myMedication),
      const _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Appointments', route: AppRouter.appointments),
      const _NavItem(icon: Icons.favorite_outline, activeIcon: Icons.favorite, label: 'Check-In', route: AppRouter.dailyCheckIn),
      const _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', route: AppRouter.profile),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 0.8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isActive = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (i != currentIndex) {
                      Navigator.pushReplacementNamed(context, item.route);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive ? AppColors.primary : AppColors.textHint,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? AppColors.primary : AppColors.textHint,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.route});
}