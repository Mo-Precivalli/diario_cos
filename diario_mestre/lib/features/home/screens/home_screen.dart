import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:diario_mestre/providers/notebook_provider.dart';
import '../widgets/book_cover.dart'; // Import da capa
import 'package:diario_mestre/features/notebook/screens/notebook_view.dart';
import 'package:diario_mestre/core/theme/colors.dart';

import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isBookOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Inicializar o provider após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotebookProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openBook() {
    setState(() {
      _isBookOpen = true;
      _controller.forward();
    });
  }

  void _closeBook() {
    setState(() {
      _isBookOpen = false;
      _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.menu_book, color: AppColors.accentGold, size: 28),
            const SizedBox(width: 12),
            Text(
              'Diário do Mestre',
              style: GoogleFonts.libreBaskerville(
                color: AppColors.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background.withValues(
          alpha: 0.8,
        ), // AppBar combina com a mesa
        elevation: 0,
        actions: [
          if (_isBookOpen) // Só mostra ações se o livro estiver aberto
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.accentGold),
              onPressed: _closeBook,
              tooltip: 'Fechar Livro',
            ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.accentGold),
            onPressed: () {},
            tooltip: 'Buscar',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.accentGold),
            onPressed: () {},
            tooltip: 'Configurações',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calcula o tamanho base do livro de acordo com a tela
          // Queremos que o livro fechado seja metade do aberto.
          final bookHeight = constraints.maxHeight * 0.85;
          final bookWidthOpen =
              constraints.maxWidth * 0.9; // Largura total aberto
          final bookWidthClosed = bookWidthOpen / 2;

          return Stack(
            children: [
              // Padrão de fundo (Patinhas)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                        ),
                    itemBuilder: (context, index) =>
                        const Icon(Icons.pets, size: 40, color: Colors.white),
                  ),
                ),
              ),

              // Conteúdo Principal (Capa ou Livro Aberto)
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: bookWidthOpen,
                    height: bookHeight,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // --- METADE DIREITA (Base) ---
                            // Página Direita do Livro
                            Positioned(
                              right: 0,
                              width: bookWidthClosed,
                              height: bookHeight,
                              child: ClipRect(
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 0,
                                      width: bookWidthOpen, // Largura total
                                      height: bookHeight,
                                      child: NotebookView(),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // --- METADE ESQUERDA / CAPA (Móvel) ---
                            // Página Esquerda do Livro (Verso da Capa)
                            Positioned(
                              right: 0,
                              width: bookWidthClosed,
                              height: bookHeight,
                              child: Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(
                                    3,
                                    2,
                                    -0.0005,
                                  ) // Perspectiva Negativa (2000px)
                                  ..rotateY(
                                    -(_controller.value * pi),
                                  ), // -180 graus (pi)
                                alignment:
                                    Alignment.centerLeft, // Pivô na lombada
                                child: (_controller.value * pi) < (pi / 2)
                                    ? BookCoverView(onOpen: _openBook)
                                    : Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..rotateY(
                                            -pi,
                                          ), // Desvira para conteúdo
                                        child: ClipRect(
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                left: 0,
                                                width:
                                                    bookWidthOpen, // Largura total
                                                height: bookHeight,
                                                child: NotebookView(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
