import 'package:flutter/foundation.dart';
import 'package:diario_mestre/core/data/notebook_repository.dart';
import 'package:diario_mestre/features/notebook/models/notebook_page.dart';
import 'package:diario_mestre/features/notebook/models/notebook_tab.dart';
import 'package:diario_mestre/services/database_service.dart';
import 'package:diario_mestre/features/monsters/models/monster_model.dart';

/// Provider responsible specifically for Content Management (Data).
/// Using Repository pattern to fetch data.
import 'package:diario_mestre/providers/notification_provider.dart';

class LibraryProvider extends ChangeNotifier {
  final NotebookRepository _repository;
  final NotificationProvider? _notificationProvider;

  LibraryProvider({
    NotebookRepository? repository,
    NotificationProvider? notificationProvider,
  }) : _repository = repository ?? DatabaseService(),
       _notificationProvider = notificationProvider;

  List<NotebookTab> _tabs = [];
  NotebookTab? _activeTab;
  List<NotebookPage> _pages = [];
  bool _isLoading = false;

  List<NotebookTab> get tabs => _tabs;
  NotebookTab? get activeTab => _activeTab;
  List<NotebookPage> get pages => _pages;
  bool get isLoading => _isLoading;

  // --- Filtering & Selection ---
  String? _selectedLetter;
  String? get selectedLetter => _selectedLetter;

  List<NotebookPage> get filteredPages {
    if (_selectedLetter == null) return _pages;
    return _pages.where((page) {
      return page.title.toUpperCase().startsWith(_selectedLetter!);
    }).toList();
  }

  // --- Delete Mode ---
  bool _isDeleteMode = false;
  final Set<String> _selectedPagesToDelete = {};
  bool get isDeleteMode => _isDeleteMode;
  Set<String> get selectedPagesToDelete => _selectedPagesToDelete;

  // --- Actions ---

  Future<void> initialize() async {
    _setLoading(true);
    try {
      _tabs = await _repository.getTabs();
      if (_tabs.isNotEmpty) {
        // Default to first tab if none selected
        if (_activeTab == null) {
          _activeTab = _tabs.first;
          await loadPages(_activeTab!.id);
        }
      }
    } catch (e) {
      debugPrint('Error initializing LibraryProvider: $e');
      _notificationProvider?.notifyError('Erro ao inicializar biblioteca: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setActiveTab(NotebookTab tab) async {
    if (_activeTab?.id == tab.id) return;
    _activeTab = tab;
    _selectedLetter = null;
    _isDeleteMode = false;
    _selectedPagesToDelete.clear();
    notifyListeners(); // Immediate UI update for tab switch
    await loadPages(tab.id);
  }

  Future<void> loadPages(String tabId) async {
    _setLoading(true);
    try {
      _pages = await _repository.getPagesByTab(tabId);
    } catch (e) {
      debugPrint('Error loading pages: $e');
      _notificationProvider?.notifyError('Erro ao carregar páginas: $e');
    } finally {
      _setLoading(false);
    }
  }

  // --- CRUD Operations ---

  /// Creates a page with default content based on the active tab type.
  Future<void> createPage(String title, {bool isContinuation = false}) async {
    if (_activeTab == null) return;

    final defaultContent = _activeTab!.id == 'monsters'
        ? MonsterModel.defaultFor(title).toJson()
        : '[]';

    final page = NotebookPage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tabId: _activeTab!.id,
      title: title,
      content: defaultContent,
      order: _pages.length,
      isContinuation: isContinuation,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.createPage(page);
      await loadPages(_activeTab!.id);
      _notificationProvider?.notifySuccess('Página criada com sucesso!');
    } catch (e) {
      _notificationProvider?.notifyError('Erro ao criar página: $e');
    }
  }

  Future<void> createPageFromObject(NotebookPage page) async {
    await _repository.createPage(page);
    await loadPages(page.tabId);
  }

  Future<void> updatePage(NotebookPage page) async {
    await _repository.updatePage(page);

    // Optimistic local update
    final index = _pages.indexWhere((p) => p.id == page.id);
    if (index != -1) {
      _pages[index] = page;
      notifyListeners();
    }
  }

  Future<void> updatePageSilent(NotebookPage page) async {
    await _repository.updatePage(page);
    // Silent update (no notifyListeners) if we want to avoid rebuilds during typing
    // But we should update local state to keep consistency
    final index = _pages.indexWhere((p) => p.id == page.id);
    if (index != -1) {
      _pages[index] = page;
    }
  }

  Future<void> deletePage(String pageId) async {
    try {
      await _repository.deletePage(pageId);
      if (_activeTab != null) await loadPages(_activeTab!.id);
      _notificationProvider?.notifySuccess('Página excluída.');
    } catch (e) {
      _notificationProvider?.notifyError('Erro ao excluir página: $e');
    }
  }

  Future<void> deleteSelectedPages() async {
    try {
      for (final id in _selectedPagesToDelete) {
        await _repository.deletePage(id);
      }
      exitDeleteMode();
      if (_activeTab != null) await loadPages(_activeTab!.id);
      _notificationProvider?.notifySuccess('Páginas excluídas.');
    } catch (e) {
      _notificationProvider?.notifyError('Erro ao excluir seleção: $e');
    }
  }

  // --- UI Helpers ---

  void filterByLetter(String? letter) {
    if (_isDeleteMode) exitDeleteMode();
    if (_selectedLetter == letter) {
      _selectedLetter = null;
    } else {
      _selectedLetter = letter;
    }
    notifyListeners();
  }

  void toggleDeleteMode() {
    _isDeleteMode = !_isDeleteMode;
    _selectedPagesToDelete.clear();
    notifyListeners();
  }

  void exitDeleteMode() {
    _isDeleteMode = false;
    _selectedPagesToDelete.clear();
    notifyListeners();
  }

  void togglePageSelection(String pageId) {
    if (_selectedPagesToDelete.contains(pageId)) {
      _selectedPagesToDelete.remove(pageId);
    } else {
      _selectedPagesToDelete.add(pageId);
    }
    notifyListeners();
  }

  Future<List<NotebookPage>> searchPages(String query) =>
      _repository.searchPages(query);
  Future<List<NotebookPage>> getPagesByTag(String tag) =>
      _repository.getPagesByTag(tag);
  Future<List<NotebookPage>> getPagesByTab(String tabId) =>
      _repository.getPagesByTab(tabId);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
