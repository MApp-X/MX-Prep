import 'book_model.dart';
import 'hsc_data.dart';
import 'ssc_data.dart';

class BookStore {
  // Master combined catalog
  static List<Book> get allBooks => [...HscData.books, ...SscData.books];

  // Specific query by user's target class and group
  static List<Book> getBooksForUser({required String className, required String groupName}) {
    final targetList = className.toUpperCase() == 'HSC' ? HscData.books : SscData.books;

    return targetList.where((book) {
      return book.groupName == groupName || book.groupName == 'Compulsory';
    }).toList();
  }

  // Get single book by ID
  static Book? getBookById(String id) {
    try {
      return allBooks.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}