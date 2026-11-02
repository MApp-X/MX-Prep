class Chapter {
  final int id;
  final String title;
  final int mcqCount;
  bool isCompleted;

  Chapter({
    required this.id,
    required this.title,
    required this.mcqCount,
    this.isCompleted = false,
  });
}

class Book {
  final String id;
  final String title;
  final String subject;
  final String coverImage;
  final List<Chapter> chapters;

  Book({
    required this.id,
    required this.title,
    required this.subject,
    required this.coverImage,
    required this.chapters,
  });

  int get totalMcq => chapters.fold(0, (sum, c) => sum + c.mcqCount);
  int get completedMcq => chapters.where((c) => c.isCompleted).fold(0, (sum, c) => sum + c.mcqCount);
}

final List<Book> hscBooks = [
  Book(
    id: 'phy1',
    title: 'পদার্থবিজ্ঞান ১ম পত্র',
    subject: 'Physics 1st Paper',
    coverImage: 'assets/images/books/hsc/physics_1.jpg',
    chapters: [
      Chapter(id: 1, title: 'ভৌতজগৎ ও পরিমাপ', mcqCount: 45),
      Chapter(id: 2, title: 'ভেক্টর', mcqCount: 85),
      Chapter(id: 3, title: 'গতিবিদ্যা', mcqCount: 90),
      Chapter(id: 4, title: 'নিউটনিয়ান বলবিদ্যা', mcqCount: 110),
      Chapter(id: 5, title: 'কাজ, শক্তি ও ক্ষমতা', mcqCount: 75),
    ],
  ),
  Book(
    id: 'phy2',
    title: 'পদার্থবিজ্ঞান ২য় পত্র',
    subject: 'Physics 2nd Paper',
    coverImage: 'assets/images/books/hsc/physics_2.jpg',
    chapters: [
      Chapter(id: 1, title: 'তাপগতিবিদ্যা', mcqCount: 80),
      Chapter(id: 2, title: 'স্থির তড়িৎ', mcqCount: 95),
      Chapter(id: 3, title: 'চল তড়িৎ', mcqCount: 105),
    ],
  ),
  Book(
    id: 'chem1',
    title: 'রসায়ন ১ম পত্র',
    subject: 'Chemistry 1st Paper',
    coverImage: 'assets/images/books/hsc/chemistry_1.jpg',
    chapters: [
      Chapter(id: 1, title: 'ল্যাবরেটরির নিরাপদ ব্যবহার', mcqCount: 40),
      Chapter(id: 2, title: 'গুণগত রসায়ন', mcqCount: 120),
      Chapter(id: 3, title: 'পর্যায়বৃত্ত ধর্ম ও রাসায়নিক বন্ধন', mcqCount: 115),
    ],
  ),
  Book(
    id: 'chem2',
    title: 'রসায়ন ২য় পত্র',
    subject: 'Chemistry 2nd Paper',
    coverImage: 'assets/images/books/hsc/chemistry_2.jpg',
    chapters: [
      Chapter(id: 1, title: 'পরিবেশ রসায়ন', mcqCount: 90),
      Chapter(id: 2, title: 'জৈব রসায়ন', mcqCount: 210),
      Chapter(id: 3, title: 'পরিমাণগত রসায়ন', mcqCount: 95),
    ],
  ),
  Book(
    id: 'hmath1',
    title: 'উচ্চতর গণিত ১ম পত্র',
    subject: 'Higher Math 1st Paper',
    coverImage: 'assets/images/books/hsc/hmath_1.jpg',
    chapters: [
      Chapter(id: 1, title: 'ম্যাট্রিক্স ও নির্ণায়ক', mcqCount: 70),
      Chapter(id: 2, title: 'ভেক্টর', mcqCount: 50),
      Chapter(id: 3, title: 'সরলরেখা', mcqCount: 110),
    ],
  ),
  Book(
    id: 'bio2',
    title: 'জীববিজ্ঞান ২য় পত্র',
    subject: 'Biology 2nd Paper',
    coverImage: 'assets/images/books/hsc/biology_2.jpg',
    chapters: [
      Chapter(id: 1, title: 'প্রাণীর বিভিন্নতা ও শ্রেণিবিন্যাস', mcqCount: 85),
      Chapter(id: 2, title: 'প্রাণীর পরিচিতি', mcqCount: 95),
    ],
  ),
  Book(
    id: 'ban1',
    title: 'বাংলা ১ম পত্র',
    subject: 'Bangla 1st Paper',
    coverImage: 'assets/images/books/hsc/bangla_1.jpg',
    chapters: [
      Chapter(id: 1, title: 'অপরিচিতা', mcqCount: 40),
      Chapter(id: 2, title: 'বিলাসী', mcqCount: 35),
    ],
  ),
  Book(
    id: 'eng1',
    title: 'English 1st Paper',
    subject: 'English 1st Paper',
    coverImage: 'assets/images/books/hsc/english_1.jpg',
    chapters: [
      Chapter(id: 1, title: 'People or Institutions Making History', mcqCount: 50),
    ],
  ),
];