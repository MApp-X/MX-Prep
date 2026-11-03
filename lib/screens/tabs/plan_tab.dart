import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/book_model.dart';
import '../../data/study_repository.dart';
import '../../services/notification_service.dart';
import '../chapter_screen.dart';

class ScheduledPlan {
  final int id;
  String date;
  String time;
  String bookId;
  int ch;
  String note;
  bool done;

  ScheduledPlan({
    required this.id,
    required this.date,
    required this.time,
    required this.bookId,
    required this.ch,
    required this.note,
    this.done = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'time': time,
        'bookId': bookId,
        'ch': ch,
        'note': note,
        'done': done,
      };

  factory ScheduledPlan.fromJson(Map<String, dynamic> json) => ScheduledPlan(
        id: json['id'] as int,
        date: json['date'] as String,
        time: json['time'] as String,
        bookId: json['bookId'] as String,
        ch: json['ch'] as int,
        note: json['note'] as String? ?? '',
        done: json['done'] as bool? ?? false,
      );
}

class PlanTab extends StatefulWidget {
  const PlanTab({super.key});

  @override
  State<PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<PlanTab> with SingleTickerProviderStateMixin {
  String _activeSubTab = 'goals';

  Map<String, int> _perBookGoals = {};
  Map<String, String> _bookTargetDates = {};
  String? _priorityBookId;

  final Map<String, int> _cachedLeftPages = {};
  List<ScheduledPlan> _plans = [];

  bool _isLoading = true;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1200));
    _loadAllPlanSettings();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPlanSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final goalsRaw = prefs.getString('plan_per_book_goals');
    final targetsRaw = prefs.getString('plan_book_targets');
    final plansRaw = prefs.getString('plan_study_plans');

    Map<String, int> loadedGoals = {};
    if (goalsRaw != null && goalsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(goalsRaw) as Map;
        loadedGoals = decoded.map((k, v) => MapEntry(k.toString(), v as int));
      } catch (_) {}
    } else {
      for (final b in StudyRepository.books) {
        loadedGoals[b.id] = 5;
      }
    }

    Map<String, String> loadedTargets = {};
    if (targetsRaw != null && targetsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(targetsRaw) as Map;
        loadedTargets = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      } catch (_) {}
    }

    List<ScheduledPlan> loadedPlans = [];
    if (plansRaw != null && plansRaw.isNotEmpty) {
      try {
        final List decoded = jsonDecode(plansRaw);
        loadedPlans = decoded
            .map((e) => ScheduledPlan.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {}
    }

    _cachedLeftPages.clear();
    for (final b in StudyRepository.books) {
      final stat = StudyRepository.getBookStat(b);
      _cachedLeftPages[b.id] = (stat['total'] as int) - (stat['read'] as int);
    }

    if (mounted) {
      setState(() {
        _perBookGoals = loadedGoals;
        _bookTargetDates = loadedTargets;
        _priorityBookId = prefs.getString('plan_priority_book_id') ??
            (StudyRepository.books.isNotEmpty ? StudyRepository.books.first.id : null);
        _plans = loadedPlans;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePerBookGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('plan_per_book_goals', jsonEncode(_perBookGoals));
  }

  Future<void> _saveBookTargets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('plan_book_targets', jsonEncode(_bookTargetDates));
  }

  Future<void> _savePlans() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_plans.map((p) => p.toJson()).toList());
    await prefs.setString('plan_study_plans', encoded);
  }

  int get _totalDailyGoal {
    int total = 0;
    for (final b in StudyRepository.books) {
      total += _perBookGoals[b.id] ?? 0;
    }
    return total;
  }

  String _format12Hour(String time24) {
    try {
      final parts = time24.split(':');
      int h = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      final suffix = h >= 12 ? 'PM' : 'AM';
      final hour12 = ((h + 11) % 12) + 1;
      return '$hour12:${m.toString().padLeft(2, '0')} $suffix';
    } catch (_) {
      return time24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0).withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _buildTabButton('goals', 'Goals'),
                _buildTabButton('time', 'Schedule'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            _buildSkeletonLoader()
          else if (_activeSubTab == 'goals')
            _buildGoalsTab()
          else
            _buildScheduleTab(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTabButton(String key, String title) {
    final isSelected = _activeSubTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_activeSubTab != key) {
            setState(() => _activeSubTab = key);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Column(
          children: List.generate(4, (i) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _shimmerBox(width: 40, height: 40, radius: 10),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _shimmerBox(width: 140, height: 14, radius: 4),
                            const SizedBox(height: 6),
                            _shimmerBox(width: 80, height: 10, radius: 4),
                          ],
                        ),
                      ),
                      _shimmerBox(width: 24, height: 24, radius: 12),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _shimmerBox(height: 44, radius: 12)),
                      const SizedBox(width: 12),
                      Expanded(child: _shimmerBox(height: 44, radius: 12)),
                    ],
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _shimmerBox({double? width, required double height, required double radius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + _shimmerController.value * 2, -0.3),
          end: Alignment(1.0 + _shimmerController.value * 2, 0.3),
          colors: const [
            Color(0xFFF1F5F9),
            Color(0xFFE2E8F0),
            Color(0xFFF1F5F9),
          ],
          stops: const [0.1, 0.3, 0.4],
        ),
      ),
    );
  }

  Widget _buildGoalsTab() {
    final books = StudyRepository.books;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.track_changes_rounded, color: Color(0xFF2563EB), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total daily target', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_totalDailyGoal',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 6),
                        const Text('pages / day', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: books.length,
          itemBuilder: (context, idx) {
            final b = books[idx];
            final leftPages = _cachedLeftPages[b.id] ?? 0;
            final currentPerDay = _perBookGoals[b.id] ?? 0;
            final isPriority = _priorityBookId == b.id;
            final targetDateStr = _bookTargetDates[b.id];

            int needPagesPerDay = 0;
            String hintMessage = '';
            bool isOnTrack = true;

            if (targetDateStr != null && leftPages > 0) {
              try {
                final targetDate = DateTime.parse(targetDateStr);
                final diffDays = targetDate.difference(DateTime.now()).inDays + 1;
                final validDays = diffDays > 0 ? diffDays : 1;
                needPagesPerDay = (leftPages / validDays).ceil();

                if (currentPerDay >= needPagesPerDay) {
                  hintMessage = 'On track to finish in time';
                  isOnTrack = true;
                } else {
                  hintMessage = 'Requires at least $needPagesPerDay pages/day';
                  isOnTrack = false;
                }
              } catch (_) {}
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Color(b.colorHex).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.menu_book_rounded, color: Color(b.colorHex), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.banglaName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            Text('$leftPages pages left', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _priorityBookId = b.id;
                          });
                          SharedPreferences.getInstance().then((p) => p.setString('plan_priority_book_id', b.id));
                        },
                        icon: Icon(
                          isPriority ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: isPriority ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pages / day', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      if (currentPerDay > 0) {
                                        setState(() {
                                          _perBookGoals[b.id] = currentPerDay - 1;
                                        });
                                        _savePerBookGoals();
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.remove_rounded, size: 16),
                                    ),
                                  ),
                                  Text(
                                    '$currentPerDay',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _perBookGoals[b.id] = currentPerDay + 1;
                                      });
                                      _savePerBookGoals();
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.add_rounded, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Finish by', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            const SizedBox(height: 5),
                            InkWell(
                              onTap: () async {
                                final initial = targetDateStr != null
                                    ? DateTime.tryParse(targetDateStr) ?? DateTime.now().add(const Duration(days: 30))
                                    : DateTime.now().add(const Duration(days: 30));

                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initial,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 730)),
                                );
                                if (picked != null) {
                                  final formatted =
                                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                  setState(() {
                                    _bookTargetDates[b.id] = formatted;
                                  });
                                  _saveBookTargets();
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      targetDateStr ?? 'Select date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: targetDateStr != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF2563EB)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hintMessage.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          isOnTrack ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                          size: 14,
                          color: isOnTrack ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hintMessage,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOnTrack ? const Color(0xFF10B981) : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Star a book to mark it as priority. It will be prioritized on your Home dashboard.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleTab() {
    final books = StudyRepository.books;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Scheduled Plans', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  Text('${_plans.where((p) => p.done).length}/${_plans.length} completed',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Specific chapters scheduled for target dates and times.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              const SizedBox(height: 14),
              if (_plans.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No study plans scheduled yet.\nTap below to add a chapter study plan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _plans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final p = _plans[idx];
                    final targetBook = books.firstWhere((b) => b.id == p.bookId, orElse: () => books.first);
                    final chName = (p.ch >= 0 && p.ch < targetBook.chapters.length)
                        ? targetBook.chapters[p.ch].name
                        : 'Chapter ${p.ch + 1}';

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () async {
                              setState(() {
                                p.done = !p.done;
                              });
                              await _savePlans();
                              if (p.done) {
                                await NotificationService.cancelAlarm(p.id % 100000, 'plan_${p.id}');
                              }
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.done ? const Color(0xFF10B981) : Colors.transparent,
                                border: Border.all(
                                  color: p.done ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                                  width: 2,
                                ),
                              ),
                              child: p.done ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChapterScreen(book: targetBook, chapterIndex: p.ch),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${targetBook.banglaName} — $chName',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      decoration: p.done ? TextDecoration.lineThrough : null,
                                      color: p.done ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    '${p.date} at ${_format12Hour(p.time)}${p.note.isNotEmpty ? " • ${p.note}" : ""}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final removedPlan = _plans.removeAt(idx);
                              await _savePlans();
                              await NotificationService.cancelAlarm(removedPlan.id % 100000, 'plan_${removedPlan.id}');
                              if (mounted) setState(() {});
                            },
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 18),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openAddPlanSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.white),
                  label: const Text('Add Scheduled Plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openAddPlanSheet() {
    final books = StudyRepository.books;
    if (books.isEmpty) return;

    Book selectedBook = books.first;
    int selectedCh = 0;
    String date = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    String time = '18:00';
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add Scheduled Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  date = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Date', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                                  Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final parts = time.split(':');
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
                              );
                              if (picked != null) {
                                setSheetState(() {
                                  time = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Time', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                                  Text(_format12Hour(time), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Book>(
                          value: selectedBook,
                          isExpanded: true,
                          items: books.map((b) {
                            return DropdownMenuItem(value: b, child: Text(b.banglaName, style: const TextStyle(fontSize: 13)));
                          }).toList(),
                          onChanged: (b) {
                            if (b != null) {
                              setSheetState(() {
                                selectedBook = b;
                                selectedCh = 0;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedCh,
                          isExpanded: true,
                          items: List.generate(selectedBook.chapters.length, (i) {
                            return DropdownMenuItem(
                              value: i,
                              child: Text(
                                '${i + 1}. ${selectedBook.chapters[i].name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            );
                          }),
                          onChanged: (ci) {
                            if (ci != null) setSheetState(() => selectedCh = ci);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteCtrl,
                      decoration: InputDecoration(
                        hintText: 'Note (optional, e.g. Math practice)',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () async {
                          final planId = DateTime.now().millisecondsSinceEpoch;
                          final newPlan = ScheduledPlan(
                            id: planId,
                            date: date,
                            time: time,
                            bookId: selectedBook.id,
                            ch: selectedCh,
                            note: noteCtrl.text.trim(),
                            done: false,
                          );

                          setState(() {
                            _plans.add(newPlan);
                          });
                          await _savePlans();

                          final timeParts = time.split(':');
                          final dateParts = date.split('-');
                          final targetDateTime = DateTime(
                            int.parse(dateParts[0]),
                            int.parse(dateParts[1]),
                            int.parse(dateParts[2]),
                            int.parse(timeParts[0]),
                            int.parse(timeParts[1]),
                          );

                          await NotificationService.scheduleAlarm(
                            alarmId: planId % 100000,
                            notifId: 'plan_$planId',
                            title: 'পড়ার সময় হয়েছে! 📚',
                            body: '${selectedBook.banglaName} এর ${selectedBook.chapters[selectedCh].name} পড়ার শিডিউল ছিল। শুরু করে দাও!',
                            scheduledDate: targetDateTime,
                            type: 'plan_alert',
                          );

                          if (mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Plan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}