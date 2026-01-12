import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/notebook_provider.dart';
import '../models/notebook_page.dart';
import '../theme/colors.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late TextEditingController _notesController;
  NotebookPage? _notesPage;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final provider = Provider.of<NotebookProvider>(context, listen: false);
    // Find or create the dashboard notes page
    try {
      final pages = await provider.databaseService.searchPages(
        'Dashboard Quick Notes',
      );
      if (pages.isNotEmpty) {
        _notesPage = pages.first;
        _notesController.text = _extractText(_notesPage!.content);
      } else {
        // Create it
        await provider.createPage('Dashboard Quick Notes');
        // creation is async, refresh list to find it
        try {
          _notesPage = provider.pages.firstWhere(
            (p) => p.title == 'Dashboard Quick Notes',
          );
        } catch (_) {}
        _notesController.text = "";
      }
    } catch (e) {
      debugPrint('Error loading dashboard notes: $e');
    }
  }

  String _extractText(String content) {
    if (content.startsWith('[')) {
      return "Conteúdo das notas (Edite na página completa)";
    }
    return content;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // --- Helper to toggle tag 'Cena' ---
  Future<void> _toggleCenaTag(NotebookPage page) async {
    final provider = Provider.of<NotebookProvider>(context, listen: false);
    final List<String> newTags = List.from(page.tags);
    if (newTags.contains('Cena')) {
      newTags.remove('Cena');
    } else {
      newTags.add('Cena');
    }
    final updatedPage = page.copyWith(tags: newTags);
    await provider.updatePage(updatedPage);
    setState(() {});
  }

  void _showAddCharacterDialog() async {
    final provider = Provider.of<NotebookProvider>(context, listen: false);
    // Load all 'people' pages
    final peoplePages = await provider.databaseService.getPagesByTab('people');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Adicionar à Cena',
          style: GoogleFonts.libreBaskerville(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.monsterSheetBackground,
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView.builder(
            itemCount: peoplePages.length,
            itemBuilder: (context, index) {
              final page = peoplePages[index];
              final isInScene = page.tags.contains('Cena');
              return ListTile(
                title: Text(
                  page.title.isEmpty ? 'Sem Nome' : page.title,
                  style: GoogleFonts.lato(),
                ),
                trailing: isInScene
                    ? const Icon(
                        Icons.check_circle,
                        color: AppColors.accentGold,
                      )
                    : const Icon(Icons.circle_outlined, color: Colors.grey),
                onTap: () async {
                  await _toggleCenaTag(page);
                  Navigator.pop(context); // Close for simplicity
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Painel do Mestre',
            style: GoogleFonts.libreBaskerville(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),

          // --- Pinned PJs (Resumo) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personagens em Cena',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentGold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.accentGold),
                onPressed: _showAddCharacterDialog,
                tooltip: 'Adicionar Personagem',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: Consumer<NotebookProvider>(
              builder: (context, provider, child) {
                return FutureBuilder<List<NotebookPage>>(
                  future: provider.getPagesByTag('Cena'),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentGold,
                        ),
                      );
                    final scenePages = snapshot.data!;

                    if (scenePages.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhum personagem na cena.',
                          style: GoogleFonts.lato(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: scenePages.length,
                      itemBuilder: (context, index) {
                        final page = scenePages[index];
                        return _buildCompactCharCard(page);
                      },
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // --- Quick Notes ---
          Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.textDark),
              const SizedBox(width: 8),
              Text(
                'Anotações Rápidas',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textLight.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Digite notas rápidas da sessão aqui...',
                  border: InputBorder.none,
                ),
                style: GoogleFonts.lato(fontSize: 15, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCharCard(NotebookPage page) {
    return InkWell(
      onTap: () {
        Provider.of<NotebookProvider>(
          context,
          listen: false,
        ).openInInspector(page);
      },
      onLongPress: () async {
        await _toggleCenaTag(page);
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF1DC), // Monster sheet bg
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: AppColors.accentGold.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryBlue,
              radius: 16,
              child: Text(
                page.title.isNotEmpty ? page.title[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              page.title,
              style: GoogleFonts.libreBaskerville(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // AC
                Icon(Icons.shield, size: 10, color: AppColors.textLight),
                Text(
                  " ${page.ac ?? '-'}",
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 6),
                // HP
                Icon(Icons.favorite, size: 10, color: Colors.red[300]),
                Text(
                  " ${page.hp ?? '-'}",
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
