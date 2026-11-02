import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String selectedClass = 'HSC';
  String selectedGroup = 'Science';

  Future<void> _saveSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_class', selectedClass);
    await prefs.setString('student_group', selectedGroup);
    await prefs.setBool('is_configured', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Academic Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Choose your class and track to tailor books.', style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 32),
              
              const Text('Target Class', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: ['SSC', 'HSC'].map((c) {
                  final active = selectedClass == c;
                  return ChoiceChip(
                    label: Text(c, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                    selected: active,
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: Colors.white,
                    onSelected: (_) => setState(() => selectedClass = c),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),
              const Text('Group Track', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: ['Science', 'Commerce', 'Arts'].map((g) {
                  final active = selectedGroup == g;
                  return ChoiceChip(
                    label: Text(g, style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                    selected: active,
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: Colors.white,
                    onSelected: (_) => setState(() => selectedGroup = g),
                  );
                }).toList(),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save & Get Started', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}