import 'package:flutter/material.dart';
import '../data/book_model.dart';
import '../data/study_repository.dart';
import '../services/notification_service.dart';

class ChapterScreen extends StatefulWidget {
  final Book book;
  final int chapterIndex;

  const ChapterScreen({
    super.key,
    required this.book,
    required this.chapterIndex,
  });

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  late int _currentIndex;
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.chapterIndex;
    _initRangeControllers();
  }

  void _initRangeControllers() {
    final chapter = _currentChapter;
    _fromController.text = '${chapter.startPage}';
    _toController.text = '${chapter.endPage}';
  }

  Chapter get _currentChapter {
    final liveBook = StudyRepository.books.firstWhere(
      (b) => b.id == widget.book.id,
      orElse: () => widget.book,
    );
    return liveBook.chapters[_currentIndex];
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _openPageCustomizerSheet() {
    final chapter = _currentChapter;
    final startCtrl = TextEditingController(text: '${chapter.startPage}');
    final endCtrl = TextEditingController(text: '${chapter.endPage}');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Customize Chapter Pages',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Customize the starting and ending page numbers for "${chapter.name}". These changes are saved permanently.',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Page', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: startCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Page', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: endCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final newStart = int.tryParse(startCtrl.text.trim());
                    final newEnd = int.tryParse(endCtrl.text.trim());

                    if (newStart == null || newEnd == null || newStart > newEnd || newStart < 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid page range! Please enter valid page numbers.'),
                          backgroundColor: Color(0xFFF43F5E),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    await StudyRepository.updateChapterPages(
                      bookId: widget.book.id,
                      chapterId: chapter.id,
                      newStartPage: newStart,
                      newEndPage: newEnd,
                    );

                    Navigator.pop(ctx);
                    setState(() {
                      _initRangeControllers();
                    });

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pages updated to $newStart–$newEnd and saved permanently!'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Save & Apply', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePageTick(int pageNo) async {
    final chapter = _currentChapter;
    await StudyRepository.togglePageRead(
      bookId: widget.book.id,
      chapterId: chapter.id,
      pageNo: pageNo,
    );
    setState(() {});

    // পেইজ টিক পড়ার সাথে সাথে নোটিফিকেশন চেক ও অ্যাডাপ্ট হবে
    NotificationService.handleDailyProgressUpdate();
  }

  Future<void> _handleRangeMark() async {
    final chapter = _currentChapter;
    final from = int.tryParse(_fromController.text.trim()) ?? chapter.startPage;
    final to = int.tryParse(_toController.text.trim()) ?? chapter.endPage;

    if (from > to || from < chapter.startPage || to > chapter.endPage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid page range!'),
          backgroundColor: Color(0xFFF43F5E),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await StudyRepository.markPageRangeRead(
      bookId: widget.book.id,
      chapterId: chapter.id,
      fromPage: from,
      toPage: to,
    );
    setState(() {});

    // রেঞ্জ মার্ক করার পরও নোটিফিকেশন আপডেট হবে
    NotificationService.handleDailyProgressUpdate();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pages $from to $to marked as read!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _handleMarkAll() async {
    final chapter = _currentChapter;
    await StudyRepository.markPageRangeRead(
      bookId: widget.book.id,
      chapterId: chapter.id,
      fromPage: chapter.startPage,
      toPage: chapter.endPage,
    );
    setState(() {});

    // সব মার্ক হলে নোটিফিকেশন আপডেট হবে
    NotificationService.handleDailyProgressUpdate();
  }

  Future<void> _handleResetChapter() async {
    final chapter = _currentChapter;
    await StudyRepository.resetChapterProgress(widget.book.id, chapter.id);
    setState(() {});

    // রিসেট হলে প্রগ্রেস কমে যাওয়ায় নোটিফিকেশন স্ট্যাটাস রি-চেক হবে
    NotificationService.handleDailyProgressUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final chapter = _currentChapter;
    final stat = StudyRepository.getChapterStat(widget.book, chapter);
    final pct = stat['pct'] as int;
    final readCount = stat['read'] as int;

    final List<int> pagesList = [];
    for (int p = chapter.startPage; p <= chapter.endPage; p++) {
      pagesList.add(p);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          chapter.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            onPressed: _openPageCustomizerSheet,
            tooltip: 'Customize Pages',
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: chapter.totalPages > 0 ? pct / 100 : 0.0,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(widget.book.colorHex)),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.book.banglaName} • Chapter ${_currentIndex + 1}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                      Text(
                        chapter.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$readCount/${chapter.totalPages} pages read • ${chapter.totalPages - readCount} left',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mark pages as read',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    InkWell(
                      onTap: _openPageCustomizerSheet,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              'Pages ${chapter.startPage}–${chapter.endPage}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF2563EB)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: pagesList.length,
                  itemBuilder: (context, i) {
                    final p = pagesList[i];
                    final isRead = StudyRepository.isPageRead(widget.book.id, chapter.id, p);

                    return InkWell(
                      onTap: () => _handlePageTick(p),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isRead ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isRead
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$p',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isRead ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fromController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'From',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('–', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _toController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'To',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _handleRangeMark,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleMarkAll,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF2563EB)),
                        label: const Text('Mark all', style: TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleResetChapter,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFFE4E6)),
                          backgroundColor: const Color(0xFFFFF1F2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFFF43F5E)),
                        label: const Text('Reset', style: TextStyle(fontSize: 12, color: Color(0xFFF43F5E), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              if (_currentIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentIndex--;
                        _initRangeControllers();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.chevron_left_rounded, size: 18),
                    label: const Text('Previous', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 12),
              if (_currentIndex < widget.book.chapters.length - 1)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentIndex++;
                        _initRangeControllers();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    label: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    icon: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white),
                  ),
                )
              else
                const Spacer(),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}