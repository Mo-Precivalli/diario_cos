import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../models/notebook_page.dart';
import '../providers/notebook_provider.dart';
import '../theme/colors.dart';

import 'page_corner_button.dart'; // Importe o novo widget
import 'tab_sidebar.dart'; // Importe o TabSidebar
import 'alphabet_sidebar.dart'; // Importe o AlphabetSidebar
import 'package:google_fonts/google_fonts.dart';
import 'card_grid.dart'; // Import CardGrid
import 'flexible_page_editor.dart';
import 'inspector_panel.dart';
import 'dashboard_view.dart';

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
    final provider = Provider.of<NotebookProvider>(context, listen: true);
    // Auto-select first character if on Characters tab and nothing selected
    if (provider.activeTab?.id == 'characters' &&
        _selectedPage == null &&
        provider.pages.isNotEmpty) {
      // Usando addPostFrameCallback para evitar erro de setState durante o build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedPage = provider.pages.first;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotebookProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.notebookFrame),
          );
        }

        final isIndexMode = provider.currentPageIndex == -1;

        // Dados da Página Esquerda (Selecionada ou Índice)
        Widget leftContent;
        if (isIndexMode) {
          if (provider.activeTab?.id == 'now') {
            // "O Agora" uses Dashboard as its "Index" or Main View
            leftContent = const DashboardView();
          } else if (provider.indexSpreadIndex == 0) {
            leftContent = _buildEmptyState(provider.activeTab?.id);
          } else {
            final items = provider.getIndexPageChunk(
              (provider.indexSpreadIndex * 2) - 1,
            );
            leftContent = _buildIndexList(context, provider, items);
          }
        } else {
          // Modo Leitura: Página Esquerda (Index atual)
          if (provider.currentPageIndex < provider.pages.length) {
            final page = provider.pages[provider.currentPageIndex];
            leftContent = _buildEditorForPage(provider, page);
          } else {
            leftContent = _buildEmptyState(provider.activeTab?.id);
          }
        }

        // Dados da Página Direita (Próxima ou Vazio)
        Widget rightContent;
        if (isIndexMode) {
          final items = provider.getIndexPageChunk(
            provider.indexSpreadIndex * 2,
          );
          rightContent = _buildIndexList(context, provider, items);
        } else {
          // Modo Leitura: Página Direita (Index + 1)
          final rightIndex = provider.currentPageIndex + 1;
          if (rightIndex < provider.pages.length) {
            final page = provider.pages[rightIndex];
            rightContent = _buildEditorForPage(provider, page);
          } else {
            // Se não tem página na direita, mostramos uma página "Rascunho"
            // que permite escrever e criar uma nova página automaticamente ao salvar.
            final draftPage = NotebookPage(
              id: '', // ID vazio indica que é uma nova página
              tabId: provider.activeTab?.id ?? '',
              title: '',
              content: provider.activeTab?.id == 'monsters'
                  ? '{"name": "", "size": "Médio", "type": "Humanóide", "alignment": "Neutro", "armor_class": 10, "hit_points": 10, "hit_dice": "2d8 + 2", "speed": "30 ft.", "stats": {"for": 10, "des": 10, "con": 10, "int": 10, "sab": 10, "car": 10}, "abilities": [], "actions": []}'
                  : '[]',
              order: provider.pages.length,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            rightContent = _buildEditorForPage(provider, draftPage);
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.notebookFrame, // Capa do livro
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16), // Margem da capa
          child: Stack(
            children: [
              Column(
                children: [
                  // Barra de Navegação Superior (Back / Next / Prev)
                  // Navegação removida do topo (movida para as laterais)
                  if (!isIndexMode) const SizedBox(height: 10),

                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .stretch, // Ensure sidebars fill height
                      children: [
                        // --- SIDEBAR DE ALFABETO (ESQUERDA) ---
                        const AlphabetSidebar(),

                        // --- PÁGINA ESQUERDA ---
                        Expanded(
                          flex: 1,
                          child: Stack(
                            children: [
                              // Camadas de páginas (Volume)
                              _buildPageVolume(isLeft: true),
                              // Conteúdo
                              _buildPageSurface(
                                child: leftContent,
                                isLeft: true,
                              ),

                              // Navegação: Voltar (Índice ou Páginas)
                              Positioned(
                                left: 0,
                                bottom: 0,
                                width: 60,
                                height: 60,
                                child: PageCornerButton(
                                  key: ValueKey(
                                    'corner_left_${isIndexMode ? provider.indexSpreadIndex : provider.currentPageIndex}',
                                  ),
                                  isLeft: true,
                                  onTap: isIndexMode
                                      ? provider.prevIndexSpread
                                      : provider.previousPage,
                                  visible: isIndexMode
                                      ? provider.canGoPrevIndexSpread
                                      : provider.hasPreviousPage,
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
                              // Camadas de páginas (Volume)
                              _buildPageVolume(isLeft: false),
                              // Conteúdo
                              _buildPageSurface(
                                child: rightContent,
                                isLeft: false,
                              ),

                              // Navegação: Avançar (Índice ou Páginas)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                width: 60,
                                height: 60,
                                child: PageCornerButton(
                                  key: ValueKey(
                                    'corner_right_${isIndexMode ? provider.indexSpreadIndex : provider.currentPageIndex}',
                                  ),
                                  isLeft: false,
                                  onTap: isIndexMode
                                      ? provider.nextIndexSpread
                                      : provider.nextPage,
                                  visible: isIndexMode
                                      ? provider.canGoNextIndexSpread
                                      : provider.hasNextPage,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- ABAS LATERAIS ---
                        const TabSidebar(),
                      ],
                    ),
                  ),
                ],
              ),
              // --- INSPECTOR PANEL OVERLAY ---
              if (provider.inspectorPage != null)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: InspectorPanel(
                    page: provider.inspectorPage,
                    onClose: provider.closeInspector,
                    onSave: (updatedPage) async {
                      await provider.updatePage(updatedPage);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditorForPage(NotebookProvider provider, NotebookPage page) {
    // Determine if right side for focus logic (heuristic)
    final isRightSide =
        provider.pages.indexOf(page) == (provider.currentPageIndex + 1) ||
        page.id.isEmpty;

    return FlexiblePageEditor(
      page: page,
      showTitle: !page.isContinuation,
      showFormatButton: !page.isContinuation,
      shouldFocus: _pageIdToFocus == page.id,
      onNavigate: (title) async {
        final results = await provider.searchPages(title);
        if (results.isNotEmpty) {
          final target = results.firstWhere(
            (p) => p.title.toLowerCase() == title.toLowerCase(),
            orElse: () => results.first,
          );
          if (provider.activeTab?.id != target.tabId) {
            try {
              final targetTab = provider.tabs.firstWhere(
                (t) => t.id == target.tabId,
              );
              await provider.setActiveTab(targetTab);
            } catch (_) {}
          }
          final index = provider.pages.indexWhere((p) => p.id == target.id);
          if (index != -1) {
            provider.openPage(index);
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
            if (provider.currentPageIndex + 1 < provider.pages.length) {
              final nextPage = provider.pages[provider.currentPageIndex + 1];
              await _appendTextToPage(provider, nextPage, textToMove);
              setState(() => _pageIdToFocus = nextPage.id);
            } else {
              // Create new page on right
              await provider.createPage('', isContinuation: true);
              if (provider.currentPageIndex + 1 < provider.pages.length) {
                final nextPage = provider.pages[provider.currentPageIndex + 1];
                await _appendTextToPage(provider, nextPage, textToMove);
                setState(() => _pageIdToFocus = nextPage.id);
              }
            }
          });
        }
      },
      onSave: (updatedPage, {bool silent = false}) async {
        if (updatedPage.id.isEmpty) {
          await provider.createPageFromObject(updatedPage);
        } else {
          if (silent) {
            await provider.updatePageSilent(updatedPage);
          } else {
            await provider.updatePage(updatedPage);
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
              color: Colors.white.withOpacity(0.9),
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
                  color: Colors.black.withOpacity(0.05),
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(isLeft ? -1 : 1, 0),
          ),
        ],
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          colors: [
            const Color(0xFFE5DECF),
            const Color(0xFFF5F0E1),
            AppColors.notebookPage,
            AppColors.notebookPage,
            const Color(0xFFF1EAD8),
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
              color: AppColors.textLight.withOpacity(0.5),
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
      child: Icon(icon, size: 300, color: Colors.black.withOpacity(0.05)),
    );
  }

  void _showNewPageDialog(BuildContext context, NotebookProvider provider) {
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
                await provider.createPage(controller.text.trim());
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
    NotebookProvider provider,
    List<NotebookPage> items,
  ) {
    // Se for uma aba de Cards (Itens ou Magia), retorna o Grid diretamente
    if (provider.activeTab?.id == 'items' ||
        provider.activeTab?.id == 'spells') {
      return CardGrid(activeLetter: provider.selectedLetter ?? '');
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
                provider.activeTab?.name ?? 'Caderno',
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
                      if (provider.isDeleteMode) {
                        // Se já está no modo delete, ao clicar novamente na lixeira, deleta os itens
                        if (provider.selectedPagesToDelete.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                'Excluir ${provider.selectedPagesToDelete.length} itens?',
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
                                    provider.deleteSelectedPages();
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
                          provider.exitDeleteMode();
                        }
                      } else {
                        // Entra no modo delete
                        provider.toggleDeleteMode();
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    highlightColor:
                        Colors.transparent, // Sem animação de clique
                    splashColor: Colors.transparent, // Sem animação de clique
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        provider.isDeleteMode
                            ? Icons.delete
                            : Icons.delete_outline,
                        size: 20,
                        color: provider.isDeleteMode
                            ? Colors.red
                            : AppColors.textLight,
                      ),
                    ),
                  ),

                  // Botão Adicionar (Só aparece se NÃO estiver deletando)
                  // Usando Visibility com maintainSize para não mover a lixeira de lugar
                  Visibility(
                    visible: !provider.isDeleteMode,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showNewPageDialog(context, provider),
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
                      items.isEmpty && provider.filteredPages.isNotEmpty
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
                      final realIndex = provider.pages.indexOf(page);
                      final isSelected = provider.selectedPagesToDelete
                          .contains(page.id);

                      return InkWell(
                        onTap: () {
                          if (provider.isDeleteMode) {
                            provider.togglePageSelection(page.id);
                          } else {
                            provider.openPage(realIndex);
                          }
                        },
                        onLongPress: () {
                          if (!provider.isDeleteMode) {
                            provider.openInInspector(page);
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
                                        (provider.isDeleteMode && isSelected)
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
                                visible: provider.isDeleteMode,
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12.0),
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (_) =>
                                        provider.togglePageSelection(page.id),
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
    NotebookProvider provider,
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
          {"insert": "$textToAppend\n"},
        ];
      } else {
        jsonDetail.add({"insert": textToAppend});
      }

      final newContent = jsonEncode(jsonDetail);

      final updatedPage = page.copyWith(
        content: newContent,
        updatedAt: DateTime.now(),
      );

      await provider.updatePage(updatedPage);
    } catch (e) {
      debugPrint('Error appending text: $e');
    }
  }
} // End of class
