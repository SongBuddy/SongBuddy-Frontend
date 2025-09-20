import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:songbuddy/constants/app_colors.dart';
import 'package:songbuddy/constants/app_text_styles.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    final items = [
      {"icon": Icons.home_rounded, "label": "Home"},
      {"icon": Icons.search_rounded, "label": "Search"},
      {"icon": Icons.person_rounded, "label": "Profile"},
      {"icon": Icons.settings_rounded, "label": "Settings"},
    ];

    return Container(
     
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0), // fits full width
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0D0D0F).withOpacity(0.95),
                  const Color(0xFF1A1A1D).withOpacity(0.95),
                ],
              ),
              border: const Border(
                top: BorderSide(color: Colors.white24, width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final isActive = index == currentIndex;
                return GestureDetector(
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF5EEAD4).withOpacity(0.4),
                                blurRadius: 14,
                                spreadRadius: 1,
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[index]["icon"] as IconData,
                          size: 22,
                          color: isActive
                              ? const Color(0xFF5EEAD4)
                              : Colors.white60,
                        ),
                        if (isActive)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              items[index]["label"] as String,
                              style: const TextStyle(
                                color: Color(0xFF5EEAD4),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
=======
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.darkBackgroundStart, AppColors.darkBackgroundEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlack60,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.onDarkPrimary.withOpacity(0.03),
              border: Border(
                top: BorderSide(
                  color: AppColors.onDarkPrimary.withOpacity(0.06),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      context: context,
                      index: 0,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: 'Home',
                    ),
                    _buildNavItem(
                      context: context,
                      index: 1,
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'Profile',
                    ),
                    _buildNavItem(
                      context: context,
                      index: 2,
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
>>>>>>> 34bf3750aa08e53a43b6d5d19a161475c42e8b06
            ),
          ),
        ),
      ),
<<<<<<< HEAD
=======
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.accentMint.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: AppColors.accentMint.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey('${isSelected}_$index'),
                color: isSelected 
                    ? AppColors.accentMint 
                    : AppColors.onDarkSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.captionOnDark.copyWith(
                color: isSelected 
                    ? AppColors.accentMint 
                    : AppColors.onDarkSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
>>>>>>> 34bf3750aa08e53a43b6d5d19a161475c42e8b06
    );
  }
}
