import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:diario_mestre/services/database_service.dart';
import 'package:diario_mestre/features/notebook/models/notebook_page.dart';

void main() {
  late DatabaseService databaseService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Use in-memory database for testing
    // inMemoryDatabasePath is actually just null or a special string used by sqflite_ffi?
    // checking documentation: sqflite_common_ffi supports inMemoryDatabasePath literal.

    databaseService = DatabaseService(dbName: inMemoryDatabasePath);
    // Ensure we start fresh?
    // inMemoryDatabasePath creates a new one per openDatabase call IF the path is distinct?
    // Actually, inMemoryDatabasePath is distinct per connection usually or shared if named?
    // 'inMemoryDatabasePath' constant is just ':memory:'.
    // Each openDatabase(':memory:') creates a private, temporary database.
    // BUT DatabaseService checks `if (_database != null) return _database!;`
    // So if I create a new instance of DatabaseService, it has _database = null initally.
    // It calls `openDatabase`, getting a FRESH memory DB. Perfect.
  });

  tearDown(() async {
    try {
      final db = await databaseService.database;
      await db.close();
    } catch (_) {}
  });

  group('NotebookRepository CRUD', () {
    test('getTabs returns default tabs on initialization', () async {
      final tabs = await databaseService.getTabs();
      expect(tabs.isNotEmpty, true);
      // Check for mandatory tabs
      expect(tabs.any((t) => t.id == 'now'), true);
      expect(tabs.any((t) => t.id == 'world'), true);
    });

    test('createPage adds a page to the database', () async {
      final newPage = NotebookPage(
        id: 'test_page_1',
        tabId: 'now',
        title: 'Test Page',
        content: 'Content',
        order: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await databaseService.createPage(newPage);
      expect(id, 'test_page_1');

      final pages = await databaseService.getPagesByTab('now');
      expect(pages.length, 1);
      expect(pages.first.title, 'Test Page');
    });

    test('updatePage modifies existing page', () async {
      final newPage = NotebookPage(
        id: 'test_page_2',
        tabId: 'now',
        title: 'Original Title',
        content: 'Content',
        order: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await databaseService.createPage(newPage);

      final updatedPage = newPage.copyWith(title: 'Updated Title');
      await databaseService.updatePage(updatedPage);

      final pages = await databaseService.getPagesByTab('now');
      expect(pages.first.title, 'Updated Title');
    });

    test('deletePage removes page from database', () async {
      final newPage = NotebookPage(
        id: 'test_page_3',
        tabId: 'now',
        title: 'To Delete',
        content: 'Content',
        order: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await databaseService.createPage(newPage);
      await databaseService.deletePage('test_page_3');

      final pages = await databaseService.getPagesByTab('now');
      expect(pages.isEmpty, true);
    });

    test('searchPages finds relevant pages', () async {
      final p1 = NotebookPage(
        id: 'p1',
        tabId: 'now',
        title: 'Alpha One',
        content: 'Hidden Secret',
        order: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final p2 = NotebookPage(
        id: 'p2',
        tabId: 'now',
        title: 'Beta Two',
        content: 'Nothing here',
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await databaseService.createPage(p1);
      await databaseService.createPage(p2);

      final resultsTitle = await databaseService.searchPages('Alpha');
      expect(resultsTitle.length, 1);
      expect(resultsTitle.first.id, 'p1');

      final resultsContent = await databaseService.searchPages('Secret');
      expect(resultsContent.length, 1);
      expect(resultsContent.first.id, 'p1');
    });
  });
}
