import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'book_model.dart';
import 'book_store.dart';

class StudyRepository {
  static const String _userBooksKey = 'user_customized_books_v1';
  static const String _progressKey = 'user_read_progress_v1';
  static const String _priorityKey = 'user_priority_book_id';

  // In-memory runtime cache for lightning-fast reads
  static List<Book> _cachedBooks = [];
  static Map<String, String> _readProgress = {}; // Key: "bookId:chapterId:page" -> Value: "YYYY-MM-DD"

  static List<Book> get books => _cachedBooks;
  static Map<String, String> get readProgress => _readProgress;

  // Initialize and load data on app startup
  static Future<void> initialize({required String userClass, required String userGroup}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Customized Books or Seed Default
    final String? storedBooksJson = prefs.getString(_userBooksKey);
    if (storedBooksJson != null && storedBooksJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(storedBooksJson);
        _cachedBooks = decoded.map((b) => Book.fromJson(b as Map<String, dynamic>)).toList();
      } catch (_) {
        _loadDefaults(userClass, userGroup);
      }
    } else {
      _loadDefaults(userClass, userGroup);
      await saveBooksToStorage();
    }

    // 2. Load Read Page Progress
    final String? progressJson = prefs.getString(_progressKey);
    if (progressJson != null && progressJson.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(progressJson);
        _readProgress = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {
        _readProgress = {};
      }
    } else {
      _readProgress = {};
    }
  }

  static void _loadDefaults(String userClass, String userGroup) {
    _cachedBooks = BookStore.getBooksForUser(className: userClass, groupName: userGroup);
  }

  // Save current book catalog (including modified pages or chapters)
  static Future<void> saveBooksToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _cachedBooks.map((b) => b.toJson()).toList();
    await prefs.setString(_userBooksKey, jsonEncode(jsonList));
  }

  // Update a chapter's start and end page
  static Future<void> updateChapterPages({
    required String bookId,
    required String chapterId,
    required int newStartPage,
    required int newEndPage,
  }) async {
    final bookIndex = _cachedBooks.indexWhere((b) => b.id == bookId);
    if (bookIndex == -1) return;

    final book = _cachedBooks[bookIndex];
    final chapterIndex = book.chapters.indexWhere((c) => c.id == chapterId);
    if (chapterIndex == -1) return;

    final updatedChapter = book.chapters[chapterIndex].copyWith(
      startPage: newStartPage,
      endPage: newEndPage,
    );

    final updatedChapters = List<Chapter>.from(book.chapters);
    updatedChapters[chapterIndex] = updatedChapter;

    _cachedBooks[bookIndex] = book.copyWith(chapters: updatedChapters);
    await saveBooksToStorage();
  }

  // Reset entire book list back to initial seed data
  static Future<void> resetToDefaultBooks(String userClass, String userGroup) async {
    _loadDefaults(userClass, userGroup);
    await saveBooksToStorage();
  }

  // ==================== READING PROGRESS & TICKS ====================

  static String _todayStr() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // Toggle single page read status
  static Future<bool> togglePageRead({
    required String bookId,
    required String chapterId,
    required int pageNo,
  }) async {
    final key = '$bookId:$chapterId:$pageNo';
    final wasRead = _readProgress.containsKey(key);

    if (wasRead) {
      _readProgress.remove(key);
    } else {
      _readProgress[key] = _todayStr();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(_readProgress));
    return !wasRead;
  }

  // Mark a range of pages as read
  static Future<void> markPageRangeRead({
    required String bookId,
    required String chapterId,
    required int fromPage,
    required int toPage,
  }) async {
    final today = _todayStr();
    for (int p = fromPage; p <= toPage; p++) {
      _readProgress['$bookId:$chapterId:$p'] = today;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(_readProgress));
  }

  // Reset all ticks of a specific chapter
  static Future<void> resetChapterProgress(String bookId, String chapterId) async {
    _readProgress.removeWhere((k, _) => k.startsWith('$bookId:$chapterId:'));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(_readProgress));
  }

  // Check if a page is read
  static bool isPageRead(String bookId, String chapterId, int pageNo) {
    return _readProgress.containsKey('$bookId:$chapterId:$pageNo');
  }

  // Chapter statistics
  static Map<String, dynamic> getChapterStat(Book book, Chapter chapter) {
    int read = 0;
    for (int p = chapter.startPage; p <= chapter.endPage; p++) {
      if (isPageRead(book.id, chapter.id, p)) read++;
    }
    final total = chapter.totalPages;
    final pct = total > 0 ? ((read / total) * 100).round() : 0;
    return {
      'read': read,
      'total': total,
      'pct': pct,
      'isDone': read == total && total > 0,
    };
  }

  // Book overall statistics
  static Map<String, dynamic> getBookStat(Book book) {
    int totalRead = 0;
    int doneChapters = 0;

    for (final ch in book.chapters) {
      final stat = getChapterStat(book, ch);
      totalRead += (stat['read'] as int);
      if (stat['isDone'] as bool) doneChapters++;
    }

    final totalPages = book.totalPages;
    final pct = totalPages > 0 ? ((totalRead / totalPages) * 100).round() : 0;

    return {
      'read': totalRead,
      'total': totalPages,
      'pct': pct,
      'doneChapters': doneChapters,
      'totalChapters': book.chapters.length,
      'isDone': totalRead == totalPages && totalPages > 0,
    };
  }

  // Overall student statistics for dashboard ring
  static Map<String, dynamic> getOverallStat() {
    int read = 0;
    int total = 0;
    int doneChapters = 0;
    int allChapters = 0;

    for (final b in _cachedBooks) {
      final s = getBookStat(b);
      read += (s['read'] as int);
      total += (s['total'] as int);
      doneChapters += (s['doneChapters'] as int);
      allChapters += (s['totalChapters'] as int);
    }

    final pct = total > 0 ? ((read / total) * 100).round() : 0;
    return {
      'read': read,
      'total': total,
      'pct': pct,
      'doneChapters': doneChapters,
      'totalChapters': allChapters,
    };
  }

  // Count pages read today
  static int getPagesReadToday() {
    final today = _todayStr();
    return _readProgress.values.where((d) => d == today).length;
  }

  // Calculate day streak
  static int calculateStreak() {
    if (_readProgress.isEmpty) return 0;

    final dates = _readProgress.values.toSet().toList();
    dates.sort((a, b) => b.compareTo(a)); // Newest first

    final today = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateStr = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";

      if (dates.contains(dateStr)) {
        streak++;
      } else if (i > 0) {
        break; // Streak broken
      }
    }

    return streak;
  }
}