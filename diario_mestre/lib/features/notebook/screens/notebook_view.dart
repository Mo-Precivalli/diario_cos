import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../models/notebook_page.dart';
import 'package:diario_mestre/providers/library_provider.dart';
import 'package:diario_mestre/providers/book_navigation_provider.dart';
import 'package:diario_mestre/core/theme/colors.dart';
import 'package:diario_mestre/core/constants/app_layout.dart';

import 'package:diario_mestre/shared/widgets/page_corner_button.dart'; // Importe o novo widget
import 'package:diario_mestre/shared/widgets/tab_sidebar.dart'; // Importe o TabSidebar
import 'package:diario_mestre/shared/widgets/alphabet_sidebar.dart'; // Importe o AlphabetSidebar
import 'package:google_fonts/google_fonts.dart';
import 'package:diario_mestre/features/library/widgets/card_grid.dart'; // Import CardGrid
import 'package:diario_mestre/features/monsters/models/monster_model.dart';
import 'package:diario_mestre/features/notebook/widgets/flexible_page_editor.dart';
import 'package:diario_mestre/shared/widgets/inspector_panel.dart';
import 'package:diario_mestre/features/dashboard/screens/dashboard_view.dart';

class NotebookView extends StatefulWidget {
  const NotebookView({super.key});

  @override
  State<NotebookView> createState() => _NotebookViewState();
}

class _NotebookViewState extends State<NotebookView> {
  NotebookPage? _selectedPage;
  // State for focus management
  String? _pageIdToFocus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final libraryProvider = Provider.of<LibraryProvider>(context, listen: true);

    // Auto-select first character if on Characters tab and nothing selected
    if (libraryProvider.activeTab?.id == 'characters' &&
        _selectedPage == null &&
        libraryProvider.pages.isNotEmpty) {
      // Usando addPostFrameCallback para evitar erro de setState durante o build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedPage = libraryProvider.pages.first;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LibraryProvider, BookNavigationProvider>(
      builder: (context, library, bookNav, child) {
        if (library.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.notebookFrame),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // --- Dynamic Pagination Logic ---
            // Calculate available height for the list
            // Total Height - (Header + Padding + Bottom Nav/Padding)
            final availableHeight =
                constraints.maxHeight -
                (40 + // Top Padding approx
                    AppLayout.indexHeaderHeight +
                    40); // Bottom Padding approx

            // Calculate how many items fit
            int pageSize = (availableHeight ~/ AppLayout.indexItemHeight)
                .toInt();
            // Ensure at least 1 item per page to avoid errors
            if (pageSize < 1) pageSize = 1;

            final tabId = library.activeTab?.id ?? '';
            final currentPageIndex = bookNav.getCurrentPageIndex(tabId);
            final isIndexMode = currentPageIndex == -1;

            // Dados da Página Esquerda (Selecionada ou Índice)
            Widget leftContent;
            if (isIndexMode) {
              if (library.activeTab?.id == 'now') {
                leftContent = const DashboardView();
              } else if (bookNav.indexSpreadIndex == 0) {
                leftContent = _buildEmptyState(library.activeTab?.id);
              } else {
                final items = bookNav.getIndexPageChunk(
                  library.filteredPages,
                  (bookNav.indexSpreadIndex * 2) - 1,
                  pageSize,
                );
                leftContent = _buildIndexList(context, library, bookNav, items);
              }
            } else {
              if (currentPageIndex < library.pages.length) {
                final page = library.pages[currentPageIndex];
                leftContent = _buildEditorForPage(library, bookNav, page);
              } else {
                leftContent = _buildEmptyState(library.activeTab?.id);
              }
            }

            // Dados da Página Direita (Próxima ou Vazio)
            Widget rightContent;
            if (isIndexMode) {
              final items = bookNav.getIndexPageChunk(
                library.filteredPages,
                bookNav.indexSpreadIndex * 2,
                pageSize,
              );
              rightContent = _buildIndexList(context, library, bookNav, items);
            } else {
              final rightIndex = currentPageIndex + 1;
              if (rightIndex < library.pages.length) {
                final page = library.pages[rightIndex];
                rightContent = _buildEditorForPage(library, bookNav, page);
              } else {
                final draftPage = NotebookPage(
                  id: '',
                  tabId: library.activeTab?.id ?? '',
                  title: '',
                  content: library.activeTab?.id == 'monsters'
                      ? MonsterModel.defaultFor('').toJson()
                      : '[]',
                  order: library.pages.length,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                rightContent = _buildEditorForPage(library, bookNav, draftPage);
              }
            }

            return Container(
              decoration: BoxDecoration(
                color: AppColors.notebookFrame,
                borderRadius: BorderRadius.circular(AppLayout.bookBorderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Column(
                    children: [
                      if (!isIndexMode) const SizedBox(height: 10),

                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const AlphabetSidebar(),

                            // --- PÁGINA ESQUERDA ---
                            Expanded(
                              flex: 1,
                              child: Stack(
                                children: [
                                  _buildPageVolume(isLeft: true),
                                  Positioned.fill(
                                    child: _buildPageSurface(
                                      child: leftContent,
                                      isLeft: true,
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    bottom: 0,
                                    width: 60,
                                    height: 60,
                                    child: PageCornerButton(
                                      key: ValueKey(
                                        'corner_left_${isIndexMode ? bookNav.indexSpreadIndex : currentPageIndex}',
                                      ),
                                      isLeft: true,
                                      onTap: isIndexMode
                                          ? bookNav.prevIndexSpread
                                          : () => bookNav.prevPage(tabId),
                                      visible: isIndexMode
                                          ? (bookNav.indexSpreadIndex > 0)
                                          : bookNav.hasPreviousPage(tabId),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // --- DOBRA CENTRAL (LOMBADA) ---
                            Container(width: 2, color: Colors.grey.shade400),

                            // --- PÁGINA DIREITA ---
                            Expanded(
                              flex: 1,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildPageVolume(isLeft: false),
                                  Positioned.fill(
                                    child: _buildPageSurface(
                                      child: rightContent,
                                      isLeft: false,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    width: 60,
                                    height: 60,
                                    child: PageCornerButton(
                                      key: ValueKey(
                                        'corner_right_${isIndexMode ? bookNav.indexSpreadIndex : currentPageIndex}',
                                      ),
                                      isLeft: false,
                                      onTap: isIndexMode
                                          ? () => bookNav.nextIndexSpread(
                                              library.filteredPages.length,
                                              pageSize,
                                            )
                                          : () => bookNav.nextPage(
                                              tabId,
                                              library.pages.length,
                                            ),
                                      visible: isIndexMode
                                          ? ((bookNav.indexSpreadIndex * 2 +
                                                        1) *
                                                    pageSize <
                                                library.filteredPages.length)
                                          : bookNav.hasNextPage(
                                              tabId,
                                              library.pages.length,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const TabSidebar(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (bookNav.inspectorPage != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: InspectorPanel(
                        page: bookNav.inspectorPage,
                        onClose: bookNav.closeInspector,
                        onSave: (updatedPage) async {
                          await library.updatePage(updatedPage);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditorForPage(
    LibraryProvider library,
    BookNavigationProvider bookNav,
    NotebookPage page,
  ) {
    // Determine if right side for focus logic (heuristic)
    final tabId = library.activeTab?.id ?? '';
    final currentPageIndex = bookNav.getCurrentPageIndex(tabId);
    final isRightSide =
        library.pages.indexOf(page) == (currentPageIndex + 1) ||
        page.id.isEmpty;

    return FlexiblePageEditor(
      page: page,
      showTitle: !page.isContinuation,
      showFormatButton: !page.isContinuation,
      shouldFocus: _pageIdToFocus == page.id,
      onNavigate: (title) async {
        final results = await library.searchPages(title);
        if (results.isNotEmpty) {
          final target = results.firstWhere(
            (p) => p.title.toLowerCase() == title.toLowerCase(),
            orElse: () => results.first,
          );
          if (library.activeTab?.id != target.tabId) {
            try {
              final targetTab = library.tabs.firstWhere(
                (t) => t.id == target.tabId,
              );
              await library.setActiveTab(targetTab);
            } catch (_) {}
          }
          final index = library.pages.indexWhere((p) => p.id == target.id);
          if (index != -1) {
            bookNav.openPage(target.tabId, index, library.pages.length);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Página "$title" não encontrada.')),
            );
          }
        }
      },
      onOverflow: (overflowData) {
        // Overflow logic (kept similar but using text chunks)
        final textToMove = overflowData is String ? overflowData : '';
        if (textToMove.isEmpty) return;

        if (!isRightSide) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            // Move to Right Page
            if (currentPageIndex + 1 < library.pages.length) {
              final nextPage = library.pages[currentPageIndex + 1];
              await _appendTextToPage(library, nextPage, textToMove);
              setState(() => _pageIdToFocus = nextPage.id);
            } else {
              // Create new page on right
              await library.createPage('', isContinuation: true);
              if (currentPageIndex + 1 < library.pages.length) {
                final nextPage = library.pages[currentPageIndex + 1];
                await _appendTextToPage(library, nextPage, textToMove);
                setState(() => _pageIdToFocus = nextPage.id);
              }
            }
          });
        }
      },
      onSave: (updatedPage, {bool silent = false}) async {
        if (updatedPage.id.isEmpty) {
          await library.createPageFromObject(updatedPage);
        } else {
          if (silent) {
            await library.updatePageSilent(updatedPage);
          } else {
            await library.updatePage(updatedPage);
          }
        }
      },
    );
  }

  Widget _buildPageVolume({required bool isLeft}) {
    return Stack(
      children: [
        Positioned.fill(
          right: isLeft ? 4 : null,
          left: isLeft ? null : 4,
          top: 4,
          bottom: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.only(
                topLeft: isLeft ? const Radius.circular(12) : Radius.zero,
                bottomLeft: isLeft ? const Radius.circular(12) : Radius.zero,
                topRight: isLeft ? Radius.zero : const Radius.circular(12),
                bottomRight: isLeft ? Radius.zero : const Radius.circular(12),
              ),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
        ),
        Positioned.fill(
          right: isLeft ? 2 : null,
          left: isLeft ? null : 2,
          top: 2,
          bottom: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: isLeft ? const Radius.circular(14) : Radius.zero,
                bottomLeft: isLeft ? const Radius.circular(14) : Radius.zero,
                topRight: isLeft ? Radius.zero : const Radius.circular(14),
                bottomRight: isLeft ? Radius.zero : const Radius.circular(14),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: Offset(isLeft ? -2 : 2, 0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageSurface({required Widget child, required bool isLeft}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.notebookPage,
        borderRadius: BorderRadius.only(
          topLeft: isLeft ? const Radius.circular(16) : Radius.zero,
          bottomLeft: isLeft ? const Radius.circular(16) : Radius.zero,
          topRight: isLeft ? Radius.zero : const Radius.circular(16),
          bottomRight: isLeft ? Radius.zero : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(isLeft ? -1 : 1, 0),
          ),
        ],
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          colors: [
            AppColors.pageGradientStart,
            AppColors.pageGradientMid1,
            AppColors.notebookPage,
            AppColors.notebookPage,
            AppColors.pageGradientMid2,
          ],
          stops: const [0.0, 0.05, 0.2, 0.9, 1.0],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: isLeft ? const Radius.circular(16) : Radius.zero,
          bottomLeft: isLeft ? const Radius.circular(16) : Radius.zero,
          topRight: isLeft ? Radius.zero : const Radius.circular(16),
          bottomRight: isLeft ? Radius.zero : const Radius.circular(16),
        ),
        child: Stack(
          children: [
            // Padrão de Fundo (Patinhas)
            Positioned.fill(
              child: Opacity(
                opacity: 0.03,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                  ),
                  itemBuilder: (context, index) {
                    return const Icon(Icons.pets, size: 24);
                  },
                ),
              ),
            ),
            // Conteúdo da Página
            Container(
              // key: ValueKey(child.hashCode), // Removed key to avoid rebuilds if unnecessary
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String? tabId) {
    IconData? icon;
    switch (tabId) {
      case 'monsters':
        icon = Icons.pets; // Pata
        break;
      case 'story':
        icon = Icons.auto_stories; // Livro aberto
        break;
      case 'sessions':
        icon = Icons.edit_note; // Notas fofas
        break;
      case 'rules':
        icon = Icons.menu_book; // Livro
        break;
      default:
        // Personagens e Itens mantêm o padrão por enquanto
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back,
              size: 32,
              color: AppColors.textLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecione uma página',
              style: TextStyle(color: AppColors.textLight, fontSize: 18),
            ),
          ],
        );
    }

    return Center(
      child: Icon(icon, size: 300, color: Colors.black.withValues(alpha: 0.05)),
    );
  }

  void _showNewPageDialog(BuildContext context, LibraryProvider library) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Página'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Título da página',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await library.createPage(controller.text.trim());
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexList(
    BuildContext context,
    LibraryProvider library,
    BookNavigationProvider bookNav,
    List<NotebookPage> items,
  ) {
    // Se for uma aba de Cards (Itens ou Magia), retorna o Grid diretamente
    if (library.activeTab?.id == 'items' || library.activeTab?.id == 'spells') {
      return CardGrid(activeLetter: library.selectedLetter ?? '');
    }

    return Column(
      children: [
        // Cabeçalho unificado
        Container(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: 8,
          ), // Reduzido bottom
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                library.activeTab?.name ?? 'Caderno',
                style: GoogleFonts.libreBaskerville(
                  color: AppColors.textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão de Deletar / Confirmar Deleção
                  InkWell(
                    onTap: () {
                      if (library.isDeleteMode) {
                        // Se já está no modo delete, ao clicar novamente na lixeira, deleta os itens
                        if (library.selectedPagesToDelete.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                'Excluir ${library.selectedPagesToDelete.length} itens?',
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                'Essa ação não pode ser desfeita.',
                                style: GoogleFonts.lato(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text(
                                    'Cancelar',
                                    style: GoogleFonts.lato(),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    library.deleteSelectedPages();
                                  },
                                  child: Text(
                                    'Excluir',
                                    style: GoogleFonts.lato(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Se nada selecionado, apenas sai do modo
                          library.exitDeleteMode();
                        }
                      } else {
                        // Entra no modo delete
                        library.toggleDeleteMode();
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    highlightColor:
                        Colors.transparent, // Sem animação de clique
                    splashColor: Colors.transparent, // Sem animação de clique
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        library.isDeleteMode
                            ? Icons.delete
                            : Icons.delete_outline,
                        size: 20,
                        color: library.isDeleteMode
                            ? Colors.red
                            : AppColors.textLight,
                      ),
                    ),
                  ),

                  // Botão Adicionar (Só aparece se NÃO estiver deletando)
                  // Usando Visibility com maintainSize para não mover a lixeira de lugar
                  Visibility(
                    visible: !library.isDeleteMode,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showNewPageDialog(context, library),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.pets,
                                  size: 20,
                                  color: AppColors.textLight,
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: AppColors.textLight,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Lista
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: items.isEmpty
                ? Center(
                    child: Text(
                      items.isEmpty && library.filteredPages.isNotEmpty
                          ? '' // Empty page in a book context
                          : 'Vazio...',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    // Filter: Only show main entries (Chapters), hide continuations
                    itemCount: items.where((p) => !p.isContinuation).length,
                    itemBuilder: (context, index) {
                      final visibleItems = items
                          .where((p) => !p.isContinuation)
                          .toList();
                      final page = visibleItems[index];
                      // ...rest of the builder logic
                      final realIndex = library.pages.indexOf(page);
                      final isSelected = library.selectedPagesToDelete.contains(
                        page.id,
                      );

                      return InkWell(
                        onTap: () {
                          if (library.isDeleteMode) {
                            library.togglePageSelection(page.id);
                          } else {
                            bookNav.openPage(
                              library.activeTab?.id ?? '',
                              realIndex,
                              library.pages.length,
                            );
                          }
                        },
                        onLongPress: () {
                          if (!library.isDeleteMode) {
                            bookNav.openInInspector(page);
                          }
                        },
                        hoverColor: Colors.transparent, // Sem cor de hover
                        splashColor:
                            Colors.transparent, // Sem animação de clique
                        highlightColor:
                            Colors.transparent, // Sem animação de clique
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              // Título (Fixo na esquerda)
                              Expanded(
                                child: Text(
                                  page.title.isEmpty
                                      ? 'Página Sem Título'
                                      : page.title,
                                  style: GoogleFonts.libreBaskerville(
                                    color: AppColors.textDark,
                                    fontSize: 16,
                                    decoration:
                                        (library.isDeleteMode && isSelected)
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                ),
                              ),

                              // Espaçador para empurrar o checkbox para a extrema direita
                              const Spacer(),

                              // Checkbox na direita (sempre ocupa espaço para não mover o texto)
                              Visibility(
                                visible: library.isDeleteMode,
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12.0),
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (_) =>
                                        library.togglePageSelection(page.id),
                                    activeColor: AppColors.monsterSheetAccent,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _appendTextToPage(
    LibraryProvider library,
    NotebookPage page,
    String textToAppend,
  ) async {
    try {
      // Decode existing content
      List<dynamic> jsonDetail = [];
      if (page.content.isNotEmpty && page.content != '[]') {
        try {
          jsonDetail = jsonDecode(page.content);
        } catch (_) {}
      }

      // If empty or just has the default \n from Quill (starts with insert \n)
      bool isEmpty = jsonDetail.isEmpty;
      if (!isEmpty && jsonDetail.length == 1) {
        final item = jsonDetail[0];
        if (item['insert'] == '\n') {
          isEmpty = true;
        }
      }

      if (isEmpty) {
        // Overwrite standard empty state with just our text
        // Ensure trailing newline for Quill
        jsonDetail = [
          {'insert': '$textToAppend\n'},
        ];
      } else {
        jsonDetail.add({'insert': textToAppend});
      }

      final newContent = jsonEncode(jsonDetail);

      await library.updatePage(
        page.copyWith(content: newContent, updatedAt: DateTime.now()),
      );
    } catch (e) {
      debugPrint('Error appending text: $e');
    }
  }
} // End of class
