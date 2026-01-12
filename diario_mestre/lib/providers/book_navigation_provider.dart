import 'package:flutter/foundation.dart';
import 'package:diario_mestre/features/notebook/models/notebook_page.dart';

/// Provider responsible specifically for Book Navigation and UI State.
/// Manages "physical" aspects like Current Page, Book Open/Closed, Inspector.
class BookNavigationProvider extends ChangeNotifier {
  // --- Book State ---
  bool _isBookOpen = false;
  bool get isBookOpen => _isBookOpen;

  // Key: Tab ID, Value: Current Page Index (physical index, i.e. 0, 2, 4...)
  final Map<String, int> _tabPageIndices = {};

  // --- Index/TOC Pagination ---
  int _indexSpreadIndex = 0; // 0 = First spread of the TOC
  int get indexSpreadIndex => _indexSpreadIndex;
  // static const int _itemsPerIndexPage = 13; // REMOVIDO: Agora é dinâmico

  // --- Inspector ---
  NotebookPage? _inspectorPage;
  NotebookPage? get inspectorPage => _inspectorPage;

  // --- Actions ---

  void openBook() {
    _isBookOpen = true;
    notifyListeners();
  }

  void closeBook() {
    _isBookOpen = false;
    notifyListeners();
  }

  // --- Page Navigation ---

  int getCurrentPageIndex(String tabId) {
    return _tabPageIndices[tabId] ?? -1;
  }

  void openPage(String tabId, int index, int totalPages) {
    if (index >= 0 && index < totalPages) {
      // Ensure we always land on an even number (Left page of spread)
      final newIndex = (index ~/ 2) * 2;
      _tabPageIndices[tabId] = newIndex;
      notifyListeners();
    }
  }

  void nextPage(String tabId, int totalPages) {
    int current = _tabPageIndices[tabId] ?? -1;
    if (current + 2 < totalPages) {
      _tabPageIndices[tabId] = current + 2;
      notifyListeners();
    }
  }

  void prevPage(String tabId) {
    int current = _tabPageIndices[tabId] ?? -1;
    if (current > 0) {
      _tabPageIndices[tabId] = current - 2;
      notifyListeners();
    } else {
      // If at first page, close/return to index?
      // For now, let's say going back from page 0 implies returning to TOC or Closing?
      // Let's reset to -1 which might mean TOC in some views, or just stay at 0.
      // Based on original logic: "closeBook()" was called if current <= 0 in previousPage()
      _tabPageIndices[tabId] = -1;
      notifyListeners();
    }
  }

  bool hasNextPage(String tabId, int totalPages) {
    int current = _tabPageIndices[tabId] ?? -1;
    return current + 2 < totalPages;
  }

  bool hasPreviousPage(String tabId) {
    int current = _tabPageIndices[tabId] ?? -1;
    return current >= 0;
  }

  // --- Index/TOC Navigation ---

  void setIndexSpread(int index) {
    _indexSpreadIndex = index;
    notifyListeners();
  }

  void nextIndexSpread(int totalItems, int pageSize) {
    // Check if we have more items to show
    final coveredItems = (_indexSpreadIndex * 2 + 1) * pageSize;
    if (coveredItems < totalItems) {
      _indexSpreadIndex++;
      notifyListeners();
    }
  }

  void prevIndexSpread() {
    if (_indexSpreadIndex > 0) {
      _indexSpreadIndex--;
      notifyListeners();
    }
  }

  List<NotebookPage> getIndexPageChunk(
    List<NotebookPage> allPages,
    int chunkIndex,
    int pageSize,
  ) {
    if (chunkIndex < 0) return [];

    final start = chunkIndex * pageSize;
    final end = start + pageSize;

    if (start >= allPages.length) return [];
    if (end > allPages.length) return allPages.sublist(start, allPages.length);
    return allPages.sublist(start, end);
  }

  // --- Inspector ---

  void openInInspector(NotebookPage page) {
    _inspectorPage = page;
    notifyListeners();
  }

  void closeInspector() {
    _inspectorPage = null;
    notifyListeners();
  }
}
