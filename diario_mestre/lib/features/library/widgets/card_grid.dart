import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:diario_mestre/features/notebook/models/notebook_page.dart';
import 'package:diario_mestre/providers/notebook_provider.dart';
import 'package:diario_mestre/core/theme/colors.dart';
import 'flip_card.dart';

class CardGrid extends StatelessWidget {
  final String activeLetter;

  const CardGrid({super.key, required this.activeLetter});

  Future<void> _addNewCard(
    BuildContext context,
    NotebookProvider provider,
  ) async {
    // 1. Pick Image
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      dialogTitle: 'Selecione a imagem da carta',
    );

    if (result != null && result.files.single.path != null) {
      final imagePath = result.files.single.path!;

      // 2. Default Title (Filename)
      String defaultTitle = result.files.single.name.split('.').first;

      // 3. Create Card Page
      final newPage = NotebookPage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tabId: provider.activeTab!.id,
        title: defaultTitle,
        content: jsonEncode({
          'imagePath': imagePath,
          'description': '',
          'type': provider.activeTab!.id == 'spells' ? 'spell' : 'item',
        }),
        order: provider.pages.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await provider.createPageFromObject(newPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotebookProvider>(
      builder: (context, provider, child) {
        // Filter and Sort Pages Alphabetically
        final pages =
            provider.filteredPages; // Already filtered by Sidebar if selected
        pages.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 80,
              ),
              child: pages.isEmpty
                  ? Center(
                      child: Text(
                        provider.selectedLetter != null
                            ? "Nenhuma carta com a letra '${provider.selectedLetter}'"
                            : "Adicione sua primeira carta clicando no '+'",
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5, // Adjust based on screen width?
                            childAspectRatio: 0.7, // Card Aspect Ratio
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        final page = pages[index];
                        return FlipCard(
                          key: ValueKey(page.id),
                          page: page,
                          onSave: (updatedPage) =>
                              provider.updatePage(updatedPage),
                          onDelete: () =>
                              _confirmDelete(context, provider, page),
                        );
                      },
                    ),
            ),

            // Add Button (Floating at top-right of the page/grid area)
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => _addNewCard(context, provider),
                backgroundColor: AppColors.accentGold,
                tooltip: 'Adicionar Nova Carta',
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    NotebookProvider provider,
    NotebookPage page,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Carta'),
        content: Text('Tem certeza que deseja excluir "${page.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deletePage(page.id);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
