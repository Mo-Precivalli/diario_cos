import 'package:flutter_test/flutter_test.dart';
import 'package:diario_mestre/providers/library_provider.dart';
import 'package:diario_mestre/core/data/notebook_repository.dart';
import 'package:diario_mestre/features/notebook/models/notebook_tab.dart';
import 'package:diario_mestre/features/notebook/models/notebook_page.dart';
import 'package:flutter/material.dart';

// Manual Mock
class MockNotebookRepository implements NotebookRepository {
  List<NotebookTab> tabs = [];
  List<NotebookPage> pages = [];

  @override
  Future<List<NotebookTab>> getTabs() async => tabs;

  @override
  Future<String> createPage(NotebookPage page) async {
    pages.add(page);
    return page.id;
  }

  @override
  Future<List<NotebookPage>> getPagesByTab(String tabId) async {
    return pages.where((p) => p.tabId == tabId).toList();
  }

  @override
  Future<void> updatePage(NotebookPage page) async {
    final index = pages.indexWhere((p) => p.id == page.id);
    if (index != -1) pages[index] = page;
  }

  @override
  Future<void> deletePage(String pageId) async {
    pages.removeWhere((p) => p.id == pageId);
  }

  @override
  Future<List<NotebookPage>> searchPages(String query) async {
    return pages.where((p) => p.title.contains(query)).toList();
  }

  @override
  Future<List<NotebookPage>> getPagesByTag(String tag) async {
    return pages.where((p) => p.tags.contains(tag)).toList();
  }
}

void main() {
  late LibraryProvider provider;
  late MockNotebookRepository mockRepository;

  setUp(() {
    mockRepository = MockNotebookRepository();
    // Setup default data
    mockRepository.tabs = [
      NotebookTab(
        id: 'now',
        name: 'Now',
        color: Colors.blue,
        icon: Icons.today,
        order: 0,
      ),
      NotebookTab(
        id: 'world',
        name: 'World',
        color: Colors.green,
        icon: Icons.map,
        order: 1,
      ),
    ];
    provider = LibraryProvider(repository: mockRepository);
  });

  group('LibraryProviderTests', () {
    test('initialize loads tabs and sets active tab', () async {
      expect(provider.tabs, isEmpty);
      expect(provider.activeTab, null);

      await provider.initialize();

      expect(provider.tabs.length, 2);
      expect(provider.activeTab?.id, 'now');
    });

    test('setActiveTab updates state and loads pages', () async {
      await provider.initialize();

      final worldTab = provider.tabs.last;
      await provider.setActiveTab(worldTab);

      expect(provider.activeTab?.id, 'world');
    });

    test('createPage adds page and reloads', () async {
      await provider.initialize();

      await provider.createPage('New Page');

      expect(provider.pages.length, 1);
      expect(provider.pages.first.title, 'New Page');
      expect(provider.pages.first.tabId, 'now');
    });

    test('deletePage removes page and reloads', () async {
      await provider.initialize();
      await provider.createPage('To Delete');
      final pageId = provider.pages.first.id;

      await provider.deletePage(pageId);

      expect(provider.pages.isEmpty, true);
    });

    test('filterByLetter filters pages correctly', () async {
      await provider.initialize();
      // Add pages with different starting letters
      // We manually inject into mock to simulate precise titles
      final p1 = NotebookPage(
        id: '1',
        tabId: 'now',
        title: 'Apple',
        content: '',
        order: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final p2 = NotebookPage(
        id: '2',
        tabId: 'now',
        title: 'Banana',
        content: '',
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await mockRepository.createPage(p1);
      await mockRepository.createPage(p2);
      await provider.loadPages(
        'now',
      ); // reload to get them from repo into provider

      expect(provider.pages.length, 2);

      provider.filterByLetter('A');
      expect(provider.filteredPages.length, 1);
      expect(provider.filteredPages.first.title, 'Apple');

      provider.filterByLetter('B');
      expect(provider.filteredPages.length, 1);
      expect(provider.filteredPages.first.title, 'Banana');

      provider.filterByLetter(null); // Clear filter
      expect(provider.filteredPages.length, 2);
    });
  });
}
