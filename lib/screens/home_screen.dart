import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_bottom_nav.dart';
import '../services/notification_service.dart';

import 'profile_screen.dart';
import 'notifications_screen.dart';

import 'tabs/home_tab.dart';
import 'tabs/books_tab.dart';
import 'tabs/exam_tab.dart';
import 'tabs/plan_tab.dart';
import 'tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = 'Student';
  String? _userPhoto;
  int _refreshTrigger = 0;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    NotificationService.autoAuditOnAppOpen();
    NotificationService.syncPendingNotifications();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Student';
        _userPhoto = prefs.getString('user_photo');
      });
    }
  }

  // Generate tab dynamically to ensure fresh data fetch on every switch
  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 1:
        return BooksTab(key: ValueKey('books_$_refreshTrigger'));
      case 2:
        return ExamTab(key: ValueKey('exam_$_refreshTrigger'));
      case 3:
        return PlanTab(key: ValueKey('plan_$_refreshTrigger'));
      case 4:
        return SettingsTab(key: ValueKey('settings_$_refreshTrigger'));
      default:
        return HomeTab(key: ValueKey('home_$_refreshTrigger'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppTopBar(
            currentIndex: _currentIndex,
            userName: _userName,
            userPhoto: _userPhoto,
            onProfileTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              _loadUserInfo();
              setState(() => _refreshTrigger++);
            },
            onNotificationTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              await NotificationService.syncPendingNotifications();
              if (mounted) {
                setState(() => _refreshTrigger++);
              }
            },
          ),
          body: _buildCurrentTab(),
          bottomNavigationBar: AppBottomNav(
            currentIndex: _currentIndex,
            onTabSelected: (index) {
              setState(() {
                _currentIndex = index;
                _refreshTrigger++;
              });
            },
          ),
        ),
      ),
    );
  }
}