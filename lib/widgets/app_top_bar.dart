import 'dart:math';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;
  final String userName;
  final String? userPhoto;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;

  const AppTopBar({
    super.key,
    required this.currentIndex,
    required this.userName,
    this.userPhoto,
    required this.onProfileTap,
    required this.onNotificationTap,
  });

  String _getDynamicGreeting() {
    final hour = DateTime.now().hour;
    final random = Random();

    final casualStarts = [
      'Welcome back',
      'Ready to study?',
      'Let’s conquer today',
      'Keep the momentum',
    ];

    if (random.nextInt(4) == 0) {
      return casualStarts[random.nextInt(casualStarts.length)];
    }

    if (hour >= 4 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening';
    } else {
      return 'Late night hustle';
    }
  }

  String _getTitle() {
    switch (currentIndex) {
      case 1:
        return 'My Books';
      case 2:
        return 'Exam & Practice';
      case 3:
        return 'Study Plan';
      case 4:
        return 'Settings';
      default:
        return 'Home';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = userName.trim().isNotEmpty ? userName.trim().split(' ')[0] : 'Student';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Profile photo avatar
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: (userPhoto != null && userPhoto!.isNotEmpty)
                      ? Image.network(
                          userPhoto!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackAvatar(displayName),
                        )
                      : _buildFallbackAvatar(displayName),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Header title or greeting
            Expanded(
              child: currentIndex == 0
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDynamicGreeting(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _getTitle(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
            ),

            // Notification Bell with dynamic reactive badge counter
            ValueListenableBuilder<int>(
              valueListenable: NotificationService.unreadCountNotifier,
              builder: (context, unreadCount, child) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: onNotificationTap,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF8FAFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF334155),
                        size: 20,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'S',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}