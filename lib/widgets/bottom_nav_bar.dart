import 'dart:ui';
import 'package:flutter/material.dart';

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
            ),
          ),
        ),
      ),
    );
  }
}
