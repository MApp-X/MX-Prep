class Chapter {
  final String id;
  final String name;
  final int chapterNo;
  final int startPage;
  final int endPage;

  const Chapter({
    required this.id,
    required this.name,
    required this.chapterNo,
    required this.startPage,
    required this.endPage,
  });

  int get totalPages => (endPage - startPage) + 1;

  Chapter copyWith({
    String? id,
    String? name,
    int? chapterNo,
    int? startPage,
    int? endPage,
  }) {
    return Chapter(
      id: id ?? this.id,
      name: name ?? this.name,
      chapterNo: chapterNo ?? this.chapterNo,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'chapterNo': chapterNo,
        'startPage': startPage,
        'endPage': endPage,
      };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'] as String,
        name: json['name'] as String,
        chapterNo: json['chapterNo'] as int,
        startPage: json['startPage'] as int,
        endPage: json['endPage'] as int,
      );
}

class Book {
  final String id;
  final String name;
  final String banglaName;
  final String className; // 'HSC' or 'SSC'
  final String groupName; // 'Science', 'Commerce', 'Humanities', 'Compulsory'
  final String imagePath;
  final int colorHex;
  final List<Chapter> chapters;

  const Book({
    required this.id,
    required this.name,
    required this.banglaName,
    required this.className,
    required this.groupName,
    required this.imagePath,
    required this.colorHex,
    required this.chapters,
  });

  int get totalPages {
    if (chapters.isEmpty) return 0;
    return chapters.fold(0, (sum, ch) => sum + ch.totalPages);
  }

  Book copyWith({
    String? id,
    String? name,
    String? banglaName,
    String? className,
    String? groupName,
    String? imagePath,
    int? colorHex,
    List<Chapter>? chapters,
  }) {
    return Book(
      id: id ?? this.id,
      name: name ?? this.name,
      banglaName: banglaName ?? this.banglaName,
      className: className ?? this.className,
      groupName: groupName ?? this.groupName,
      imagePath: imagePath ?? this.imagePath,
      colorHex: colorHex ?? this.colorHex,
      chapters: chapters ?? this.chapters,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'banglaName': banglaName,
        'className': className,
        'groupName': groupName,
        'imagePath': imagePath,
        'colorHex': colorHex,
        'chapters': chapters.map((c) => c.toJson()).toList(),
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as String,
        name: json['name'] as String,
        banglaName: json['banglaName'] as String,
        className: json['className'] as String,
        groupName: json['groupName'] as String,
        imagePath: json['imagePath'] as String,
        colorHex: json['colorHex'] as int,
        chapters: (json['chapters'] as List<dynamic>)
            .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}