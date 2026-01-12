import 'package:diario_mestre/features/notebook/models/notebook_page.dart';
import 'package:diario_mestre/features/notebook/models/notebook_tab.dart';

/// Interface that defines the contract for accessing notebook data.
/// This allows us to swap the implementation (e.g. for testing) without changing business logic.
abstract class NotebookRepository {
  /// Retrieves all available tabs in sorted order.
  Future<List<NotebookTab>> getTabs();

  /// Retrieves all pages for a specific [tabId], sorted by order.
  Future<List<NotebookPage>> getPagesByTab(String tabId);

  /// Creates a new page and returns its ID.
  Future<String> createPage(NotebookPage page);

  /// Updates an existing page.
  Future<void> updatePage(NotebookPage page);

  /// Deletes a page by its [pageId].
  Future<void> deletePage(String pageId);

  /// Searches pages by title or content matching [query].
  Future<List<NotebookPage>> searchPages(String query);

  /// Retrieves pages that contain a specific [tag].
  Future<List<NotebookPage>> getPagesByTag(String tag);
}
