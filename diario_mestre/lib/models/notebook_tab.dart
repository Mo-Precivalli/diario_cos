import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Modelo que representa uma aba do caderno
class NotebookTab {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final int order;

  NotebookTab({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'icon': icon.codePoint,
      'order': order,
    };
  }

  factory NotebookTab.fromMap(Map<String, dynamic> map) {
    return NotebookTab(
      id: map['id'],
      name: map['name'],
      color: Color(map['color']),
      icon: IconData(map['icon'], fontFamily: 'MaterialIcons'),
      order: map['order'],
    );
  }

  static List<NotebookTab> getDefaultTabs() {
    return [
      NotebookTab(
        id: 'monsters',
        name: 'Bestiário',
        color: AppColors.tabMonster,
        icon: Icons.pets, // Patinha
        order: 0,
      ),
      NotebookTab(
        id: 'story',
        name: 'História',
        color: AppColors.tabStory,
        icon: Icons.auto_stories, // Livro aberto
        order: 1,
      ),
      NotebookTab(
        id: 'sessions',
        name: 'Sessões',
        color: AppColors.tabSessions,
        icon: Icons.edit_note, // Notas fofas
        order: 2,
      ),
      NotebookTab(
        id: 'characters',
        name: 'Personagens',
        color: AppColors.tabCharacters,
        icon: Icons.face, // Carinha
        order: 3,
      ),
      NotebookTab(
        id: 'items',
        name: 'Itens',
        color: AppColors.tabItems,
        icon: Icons.backpack, // Mochila de aventura
        order: 4,
      ),
      NotebookTab(
        id: 'spells',
        name: 'Magia',
        color: AppColors.tabSpells, // You'll need to add this color too
        icon: Icons.auto_fix_high, // Varinha mágica
        order: 5,
      ),
      NotebookTab(
        id: 'rules',
        name: 'Regras',
        color: AppColors.tabRules,
        icon: Icons.menu_book, // Livro de regras
        order: 6,
      ),
    ];
  }
}
