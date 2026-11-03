import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'data/study_repository.dart';
import 'screens/login_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.initialize();

  final prefs = await SharedPreferences.getInstance();
  final isAuthed = prefs.getBool('is_authed') ?? false;
  final isConfigured = prefs.getBool('is_configured') ?? false;

  final userClass = prefs.getString('user_class') ?? 'HSC';
  final userGroup = prefs.getString('user_group') ?? 'Science';

  if (isAuthed && isConfigured) {
    await StudyRepository.initialize(userClass: userClass, userGroup: userGroup);
  }

  Widget startPage = const LoginScreen();
  if (isAuthed && !isConfigured) {
    startPage = const SetupScreen();
  } else if (isAuthed && isConfigured) {
    startPage = const HomeScreen();
  }

  runApp(MXPrepApp(startScreen: startPage));
}

class MXPrepApp extends StatefulWidget {
  final Widget startScreen;
  const MXPrepApp({super.key, required this.startScreen});

  @override
  State<MXPrepApp> createState() => _MXPrepAppState();
}

class _MXPrepAppState extends State<MXPrepApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
    });
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MX Prep',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        fontFamily: 'Inter',
      ),
      home: widget.startScreen,
    );
  }
}