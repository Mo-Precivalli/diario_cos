import 'package:flutter/material.dart';

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
        id: 'now',
        name: 'O Agora',
        color: const Color(0xFFD32F2F), // Red for Action/Immediate
        icon: Icons.bolt,
        order: 0,
      ),
      NotebookTab(
        id: 'world',
        name: 'O Mundo',
        color: const Color(0xFF388E3C), // Green for World/Nature
        icon: Icons.map,
        order: 1,
      ),
      NotebookTab(
        id: 'people',
        name: 'O Povo',
        color: const Color(0xFF1976D2), // Blue for People
        icon: Icons.groups,
        order: 2,
      ),
      NotebookTab(
        id: 'past',
        name: 'O Passado',
        color: const Color(0xFF795548), // Brown/Sepia for History
        icon: Icons.history_edu,
        order: 3,
      ),
    ];
  }
}
