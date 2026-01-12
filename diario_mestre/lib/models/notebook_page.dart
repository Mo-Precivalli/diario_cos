/// Modelo que representa uma página no caderno
class NotebookPage {
  final String id;
  final String tabId;
  final String title;
  final String content; // JSON do Quill Delta
  final int order;
  final bool isContinuation; // New flag for overflow grouping
  final List<String> tags; // New: Tags support
  final int? ac; // Stats
  final int? hp; // Stats
  final DateTime createdAt;
  final DateTime updatedAt;

  NotebookPage({
    required this.id,
    required this.tabId,
    required this.title,
    required this.content,
    required this.order,
    this.isContinuation = false,
    this.tags = const [],
    this.ac,
    this.hp,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tab_id': tabId,
      'title': title,
      'content': content,
      'order': order,
      'is_continuation': isContinuation ? 1 : 0,
      'tags': tags.join(','),
      'ac': ac,
      'hp': hp,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory NotebookPage.fromMap(Map<String, dynamic> map) {
    return NotebookPage(
      id: map['id'],
      tabId: map['tab_id'],
      title: map['title'],
      content: map['content'],
      order: map['order'],
      isContinuation: map['is_continuation'] == 1,
      tags: (map['tags'] != null && map['tags'].toString().isNotEmpty)
          ? map['tags'].toString().split(',')
          : [],
      ac: map['ac'],
      hp: map['hp'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  NotebookPage copyWith({
    String? id,
    String? tabId,
    String? title,
    String? content,
    int? order,
    bool? isContinuation,
    List<String>? tags,
    int? ac,
    int? hp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotebookPage(
      id: id ?? this.id,
      tabId: tabId ?? this.tabId,
      title: title ?? this.title,
      content: content ?? this.content,
      order: order ?? this.order,
      isContinuation: isContinuation ?? this.isContinuation,
      tags: tags ?? this.tags,
      ac: ac ?? this.ac,
      hp: hp ?? this.hp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
