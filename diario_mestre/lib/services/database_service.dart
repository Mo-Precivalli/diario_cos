import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:diario_mestre/core/data/notebook_repository.dart';
import 'package:diario_mestre/features/notebook/models/notebook_page.dart';
import 'package:diario_mestre/features/notebook/models/notebook_tab.dart';

class DatabaseService implements NotebookRepository {
  Database? _database;
  final String _dbName;

  DatabaseService({String? dbName}) : _dbName = dbName ?? 'diario_mestre.db';

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
    final path = _dbName == inMemoryDatabasePath
        ? _dbName
        : join(dbPath, _dbName);

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

    // Migration Fix: Add tags column if it doesn't exist
    try {
      await db.execute('ALTER TABLE pages ADD COLUMN tags TEXT');
    } catch (e) {
      // Column might already exist
    }

    // Migration Fix: Add stats columns
    try {
      await db.execute('ALTER TABLE pages ADD COLUMN ac INTEGER');
    } catch (e) {
      // Column might already exist
    }
    try {
      await db.execute('ALTER TABLE pages ADD COLUMN hp INTEGER');
    } catch (e) {
      // Column might already exist
    }

    // Check for missing tabs and insert them
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
          'color': tab.color.toARGB32(),
          'icon': tab.icon.codePoint,
          'sort_order': tab.order,
        });
      } else {
        // Update existing tab (name/color/icon) if it matches our new defaults
        await db.update(
          'tabs',
          {
            'name': tab.name,
            'color': tab.color.toARGB32(),
            'icon': tab.icon.codePoint,
            'sort_order': tab.order,
          },
          where: 'id = ?',
          whereArgs: [tab.id],
        );
      }
    }

    // --- Data Migration ---
    // Move 'sessions' -> 'now' (if 'now' is empty or we just want to move them)
    // Move 'monsters' + 'characters' -> 'people'
    // Move 'story' -> 'past'
    // Move 'items' -> 'world' (or just keep them? User didn't specify items destination, but World seems fit for loot/locations)

    // Helper to move pages
    Future<void> movePages(String oldTabId, String newTabId) async {
      await db.update(
        'pages',
        {'tab_id': newTabId},
        where: 'tab_id = ?',
        whereArgs: [oldTabId],
      );
      // Verify if oldTabId is not in new defaults, we might want to delete the tab entry?
      // For safety, we keep the tab entry in DB but it will be empty and not loaded by getDefaultTabs logic if we only load what we want?
      // Actually getTabs() loads ALL tabs from DB. So we should delete old tabs after migration.
    }

    await movePages('sessions', 'now');
    await movePages('monsters', 'people');
    await movePages('characters', 'people');
    await movePages('story', 'past');
    await movePages('items', 'world');
    await movePages(
      'rules',
      'world',
    ); // Rules fit in World? or Now? Let's put in World for reference.

    // Delete old tabs that are not in the new list
    final newTabIds = defaultTabs.map((t) => t.id).toList();
    // We can't easily do "DELETE FROM tabs WHERE id NOT IN (...)" safely without binding parameters for list.
    // So let's just delete specific known old ones.
    final oldTabsToDelete = [
      'monsters',
      'characters',
      'story',
      'items',
      'rules',
      'spells',
      'sessions',
    ];
    for (var oldId in oldTabsToDelete) {
      if (!newTabIds.contains(oldId)) {
        // Only delete if we successfully moved pages (count pages first?)
        // For now, assume moved.
        await db.delete('tabs', where: 'id = ?', whereArgs: [oldId]);
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
        tags TEXT,
        ac INTEGER,
        hp INTEGER,
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
        'color': tab.color.toARGB32(),
        'icon': tab.icon.codePoint,
        'sort_order': tab.order,
      });
    }
  }

  // CRUD Tabs
  @override
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
  @override
  Future<String> createPage(NotebookPage page) async {
    final db = await database;
    await db.insert('pages', {
      'id': page.id,
      'tab_id': page.tabId,
      'title': page.title,
      'content': page.content,
      'sort_order': page.order,
      'is_continuation': page.isContinuation ? 1 : 0,
      'tags': page.tags.join(','),
      'ac': page.ac,
      'hp': page.hp,
      'created_at': page.createdAt.toIso8601String(),
      'updated_at': page.updatedAt.toIso8601String(),
    });
    return page.id;
  }

  @override
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
            'tags': map['tags'],
            'ac': map['ac'],
            'hp': map['hp'],
            'created_at': map['created_at'],
            'updated_at': map['updated_at'],
          }),
        )
        .toList();
  }

  @override
  Future<void> updatePage(NotebookPage page) async {
    final db = await database;
    await db.update(
      'pages',
      {
        'title': page.title,
        'content': page.content,
        'sort_order': page.order,
        'is_continuation': page.isContinuation ? 1 : 0,
        'tags': page.tags.join(','),
        'ac': page.ac,
        'hp': page.hp,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [page.id],
    );
  }

  @override
  Future<void> deletePage(String pageId) async {
    final db = await database;
    await db.delete('pages', where: 'id = ?', whereArgs: [pageId]);
  }

  @override
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
            'tags': map['tags'],
            'ac': map['ac'],
            'hp': map['hp'],
            'created_at': map['created_at'],
            'updated_at': map['updated_at'],
          }),
        )
        .toList();
  }

  @override
  Future<List<NotebookPage>> getPagesByTag(String tag) async {
    final db = await database;
    // Tags are stored as "tag1,tag2,tag3"
    // We search for whole word match ideally, or just simple substring for now
    final result = await db.query(
      'pages',
      where: 'tags LIKE ?',
      whereArgs: ['%$tag%'],
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
            'tags': map['tags'],
            'ac': map['ac'],
            'hp': map['hp'],
            'created_at': map['created_at'],
            'updated_at': map['updated_at'],
          }),
        )
        .toList();
  }
}
