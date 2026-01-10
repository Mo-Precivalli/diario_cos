import 'package:flutter/foundation.dart';
import '../models/notebook_tab.dart';
import '../models/notebook_page.dart';
import '../services/database_service.dart';

class NotebookProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<NotebookTab> _tabs = [];
  NotebookTab? _activeTab;
  List<NotebookPage> _pages = [];
  bool _isLoading = false;

  List<NotebookTab> get tabs => _tabs;
  NotebookTab? get activeTab => _activeTab;
  List<NotebookPage> get pages => _pages;
  bool get isLoading => _isLoading;

  // --- Filtro Alfabético ---
  String? _selectedLetter;
  String? get selectedLetter => _selectedLetter;

  List<NotebookPage> get filteredPages {
    // Se estiver em modo de delete, talvez mostrar todos? Ou respeitar filtro?
    // Melhor respeitar filtro para o usuário deletar o que vê.
    if (_selectedLetter == null) return _pages;
    return _pages.where((page) {
      return page.title.toUpperCase().startsWith(_selectedLetter!);
    }).toList();
  }

  void filterByLetter(String? letter) {
    if (_isDeleteMode) exitDeleteMode(); // Sair do modo delete ao filtrar
    if (_selectedLetter == letter) {
      _selectedLetter = null; // Toggle off if same letter
    } else {
      _selectedLetter = letter;
    }
    _indexSpreadIndex = 0; // Reset spread pagination
    notifyListeners();
  }
  // --- Fim Filtro ---

  // --- Modo de Seleção / Deletar ---
  bool _isDeleteMode = false;
  final Set<String> _selectedPagesToDelete = {};

  bool get isDeleteMode => _isDeleteMode;
  Set<String> get selectedPagesToDelete => _selectedPagesToDelete;

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

  Future<void> deleteSelectedPages() async {
    for (final id in _selectedPagesToDelete) {
      await _dbService.deletePage(id);
    }
    exitDeleteMode();
    // Recarregar
    if (_activeTab != null) {
      await loadPages(_activeTab!.id);
    }
  }
  // --- Fim Modo Seleção ---

  // --- Paginação do Índice (Lista / Spreads) ---
  int _indexSpreadIndex = 0; // 0 = Capa interna (Esq Vazio, Dir Lista 1)
  final int _itemsPerIndexPage = 13;

  int get indexSpreadIndex => _indexSpreadIndex;

  // Retorna os itens para uma "página" específica do índice (seja esq ou dir)
  List<NotebookPage> getIndexPageChunk(int chunkIndex) {
    if (chunkIndex < 0) return []; // Página negativa (ex: esquerda da spread 0)

    final start = chunkIndex * _itemsPerIndexPage;
    final end = start + _itemsPerIndexPage;
    final filtered = filteredPages;

    if (start >= filtered.length) return [];
    if (end > filtered.length) return filtered.sublist(start, filtered.length);
    return filtered.sublist(start, end);
  }

  // Verifica se existe conteúdo para a DIREITA da spread atual
  bool get canGoNextIndexSpread {
    final coveredItems = (_indexSpreadIndex * 2 + 1) * _itemsPerIndexPage;
    return coveredItems < filteredPages.length;
  }

  bool get canGoPrevIndexSpread {
    return _indexSpreadIndex > 0;
  }

  void nextIndexSpread() {
    if (canGoNextIndexSpread) {
      _indexSpreadIndex++;
      notifyListeners();
    }
  }

  void prevIndexSpread() {
    if (canGoPrevIndexSpread) {
      _indexSpreadIndex--;
      notifyListeners();
    }
  }
  // --- Fim Paginação do Índice ---

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _tabs = await _dbService.getTabs();
    if (_tabs.isNotEmpty) {
      _activeTab = _tabs.first;
      await loadPages(_activeTab!.id);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setActiveTab(NotebookTab tab) async {
    if (_activeTab?.id == tab.id) return;

    _activeTab = tab;
    _selectedLetter = null; // Reset filter
    _isDeleteMode = false; // Reset delete mode
    _selectedPagesToDelete.clear();
    _indexSpreadIndex = 0; // Reset spread pagination
    notifyListeners();
    await loadPages(tab.id);
    _currentPageIndex = -1; // Volta para o índice
    notifyListeners();
  }

  Future<void> loadPages(String tabId) async {
    _isLoading = true;
    notifyListeners();

    _pages = await _dbService.getPagesByTab(tabId);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createPage(String title, {bool isContinuation = false}) async {
    if (_activeTab == null) return;

    final page = NotebookPage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tabId: _activeTab!.id,
      title: title,
      content: _activeTab!.id == 'monsters'
          ? '{"name": "$title", "size": "Médio", "type": "Humanóide", "alignment": "Neutro", "armor_class": 10, "hit_points": 10, "hit_dice": "2d8 + 2", "speed": "30 ft.", "stats": {"for": 10, "des": 10, "con": 10, "int": 10, "sab": 10, "car": 10}, "abilities": [], "actions": []}'
          : '[]', // Quill Delta vazio para outras abas
      order: _pages.length,
      isContinuation: isContinuation,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _dbService.createPage(page);
    await loadPages(_activeTab!.id);
  }

  Future<void> createPageFromObject(NotebookPage page) async {
    // Ensure ID is set if empty (though usually set by caller)
    final pageToCreate = page.id.isEmpty
        ? page.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString())
        : page;

    await _dbService.createPage(pageToCreate);
    await loadPages(page.tabId);
  }

  Future<void> updatePage(NotebookPage page) async {
    await _dbService.updatePage(page);
    // Optimistic update
    final index = _pages.indexWhere((p) => p.id == page.id);
    if (index != -1) {
      _pages[index] = page;
      notifyListeners();
    } else {
      await loadPages(_activeTab!.id);
    }
  }

  Future<void> updatePageSilent(NotebookPage page) async {
    await _dbService.updatePage(page);
    final index = _pages.indexWhere((p) => p.id == page.id);
    if (index != -1) {
      _pages[index] = page;
    }
    // No notifyListeners()
  }

  Future<void> deletePage(String pageId) async {
    await _dbService.deletePage(pageId);
    // Recarregar páginas pode mudar paginação, resetar?
    // Melhor manter spread se possível, mas por segurança resetar ou verificar bounds
    // Por simplicidade, mantemos, mas a view vai tratar vazio
    await loadPages(_activeTab!.id);
  }

  // --- Paginação do Livro ---
  int _currentPageIndex = -1; // -1 indica Índice (Lista)
  int get currentPageIndex => _currentPageIndex;

  void openPage(int index) {
    if (index >= 0 && index < _pages.length) {
      // Garante que o índice seja par para sempre abrir na página ESQUERDA da dupla
      // Ex: Se clicar na pág 1 (índice 0), abre 0 e 1. Se clicar pág 2 (índice 1), abre 0 e 1?
      // NÃO. Cada "folha" tem 2 páginas.
      // O índice da lista é linear.
      // Se eu tenho [A, B, C, D]
      // Abrir A (0) -> Mostra A na Esquerda, B na Direita.
      // Abrir B (1) -> Mostra A na Esquerda, B na Direita.
      // Abrir C (2) -> Mostra C na Esquerda, D na Direita.

      _currentPageIndex = (index ~/ 2) * 2;
      notifyListeners();
    }
  }

  void closeBook() {
    _currentPageIndex = -1;
    notifyListeners();
  }

  void nextPage() {
    if (_currentPageIndex + 2 < _pages.length) {
      _currentPageIndex += 2;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPageIndex > 0) {
      _currentPageIndex -= 2;
      notifyListeners();
    } else {
      closeBook(); // Volta para o índice se voltar da primeira página
    }
  }

  bool get hasNextPage => _currentPageIndex + 2 < _pages.length;
  bool get hasPreviousPage => _currentPageIndex >= 0;

  // --- Fim Paginação ---

  Future<List<NotebookPage>> searchPages(String query) async {
    return await _dbService.searchPages(query);
  }
}
