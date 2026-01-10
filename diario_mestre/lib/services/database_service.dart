import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/notebook_tab.dart';
import '../models/notebook_page.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Inicializar FFI para desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'diario_mestre.db');

    final db = await openDatabase(path, version: 1, onCreate: _onCreate);

    // Migration Fix: Ensure 'monsters' tab is named 'Bestiário'
    await db.update(
      'tabs',
      {'name': 'Bestiário'},
      where: 'id = ?',
      whereArgs: ['monsters'],
    );

    // Migration Fix: Add is_continuation column if it doesn't exist
    try {
      await db.execute(
        'ALTER TABLE pages ADD COLUMN is_continuation INTEGER DEFAULT 0',
      );
    } catch (e) {
      // Column might already exist
    }

    // Check for missing tabs and insert them
    // This ensures new tabs (like 'spells') are added to existing databases
    final defaultTabs = NotebookTab.getDefaultTabs();
    for (var tab in defaultTabs) {
      final existing = await db.query(
        'tabs',
        where: 'id = ?',
        whereArgs: [tab.id],
      );
      if (existing.isEmpty) {
        await db.insert('tabs', {
          'id': tab.id,
          'name': tab.name,
          'color': tab.color.value,
          'icon': tab.icon.codePoint,
          'sort_order': tab.order,
        });
      }
    }

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de abas
    await db.execute('''
      CREATE TABLE tabs (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        icon INTEGER NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');

    // Tabela de páginas
    await db.execute('''
      CREATE TABLE pages (
        id TEXT PRIMARY KEY,
        tab_id TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        is_continuation INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (tab_id) REFERENCES tabs (id) ON DELETE CASCADE
      )
    ''');

    // Criar índice para busca rápida
    await db.execute('''
      CREATE INDEX idx_pages_tab_id ON pages(tab_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_pages_title ON pages(title)
    ''');

    // Inserir abas padrão
    final defaultTabs = NotebookTab.getDefaultTabs();
    for (var tab in defaultTabs) {
      await db.insert('tabs', {
        'id': tab.id,
        'name': tab.name,
        'color': tab.color.value,
        'icon': tab.icon.codePoint,
        'sort_order': tab.order,
      });
    }
  }

  // CRUD Tabs
  Future<List<NotebookTab>> getTabs() async {
    final db = await database;
    final result = await db.query('tabs', orderBy: 'sort_order ASC');
    return result
        .map(
          (map) => NotebookTab.fromMap({
            'id': map['id'],
            'name': map['name'],
            'color': map['color'],
            'icon': map['icon'],
            'order': map['sort_order'],
          }),
        )
        .toList();
  }

  // CRUD Pages
  Future<String> createPage(NotebookPage page) async {
    final db = await database;
    await db.insert('pages', {
      'id': page.id,
      'tab_id': page.tabId,
      'title': page.title,
      'content': page.content,
      'sort_order': page.order,
      'is_continuation': page.isContinuation ? 1 : 0,
      'created_at': page.createdAt.toIso8601String(),
      'updated_at': page.updatedAt.toIso8601String(),
    });
    return page.id;
  }

  Future<List<NotebookPage>> getPagesByTab(String tabId) async {
    final db = await database;
    final result = await db.query(
      'pages',
      where: 'tab_id = ?',
      whereArgs: [tabId],
      orderBy: 'sort_order ASC, created_at ASC', // Order by sequence
    );
    return result
        .map(
          (map) => NotebookPage.fromMap({
            'id': map['id'],
            'tab_id': map['tab_id'],
            'title': map['title'],
            'content': map['content'],
            'order': map['sort_order'],
            'is_continuation': map['is_continuation'] ?? 0,
            'created_at': map['created_at'],
            'updated_at': map['updated_at'],
          }),
        )
        .toList();
  }

  Future<void> updatePage(NotebookPage page) async {
    final db = await database;
    await db.update(
      'pages',
      {
        'title': page.title,
        'content': page.content,
        'sort_order': page.order,
        'is_continuation': page.isContinuation ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [page.id],
    );
  }

  Future<void> deletePage(String pageId) async {
    final db = await database;
    await db.delete('pages', where: 'id = ?', whereArgs: [pageId]);
  }

  Future<List<NotebookPage>> searchPages(String query) async {
    final db = await database;
    final result = await db.query(
      'pages',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );
    return result
        .map(
          (map) => NotebookPage.fromMap({
            'id': map['id'],
            'tab_id': map['tab_id'],
            'title': map['title'],
            'content': map['content'],
            'order': map['sort_order'],
            'is_continuation': map['is_continuation'] ?? 0,
            'created_at': map['created_at'],
            'updated_at': map['updated_at'],
          }),
        )
        .toList();
  }
}
