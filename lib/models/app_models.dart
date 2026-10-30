import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum PriorityLevel {
  none('', 'No Priority', Colors.transparent, Colors.transparent),
  veryVeryImportant(
    'very-very-important',
    'Very Very Important',
    Color(0xFFF87171),
    Color(0x33EF4444),
  ),
  important(
    'important',
    'Important',
    Color(0xFFFB923C),
    Color(0x33F97316),
  ),
  necessary(
    'necessary',
    'Necessary',
    Color(0xFFFACC15),
    Color(0x33EAB308),
  ),
  goodToDone(
    'good-to-done',
    'Good to Done',
    Color(0xFF4ADE80),
    Color(0x3322C55E),
  );

  final String key;
  final String label;
  final Color textColor;
  final Color bgColor;

  const PriorityLevel(this.key, this.label, this.textColor, this.bgColor);

  static PriorityLevel fromKey(String? key) {
    if (key == null) return PriorityLevel.none;
    for (final p in PriorityLevel.values) {
      if (p.key == key) return p;
    }
    return PriorityLevel.none;
  }
}

class TaskItem {
  int id;
  String text;
  bool done;

  TaskItem({required this.id, required this.text, this.done = false});

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'done': done};

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      text: json['text'] ?? '',
      done: json['done'] == true,
    );
  }
}

class NoteItem {
  int id;
  String text;

  NoteItem({required this.id, required this.text});

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      text: json['text'] ?? '',
    );
  }
}

class GoalItem {
  int id;
  String text;
  bool done;
  String priority;

  GoalItem({
    required this.id,
    required this.text,
    this.done = false,
    this.priority = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'done': done,
        'priority': priority,
      };

  factory GoalItem.fromJson(Map<String, dynamic> json) {
    return GoalItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      text: json['text'] ?? '',
      done: json['done'] == true,
      priority: json['priority'] ?? '',
    );
  }
}

class DayTab {
  String dateId; // YYYY-MM-DD
  List<GoalItem> goals;

  DayTab({required this.dateId, required this.goals});

  Map<String, dynamic> toJson() => {
        'dateId': dateId,
        'goals': goals.map((g) => g.toJson()).toList(),
      };

  factory DayTab.fromJson(Map<String, dynamic> json) {
    return DayTab(
      dateId: json['dateId'] ?? '',
      goals: (json['goals'] as List<dynamic>? ?? [])
          .map((item) => GoalItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class WeekTab {
  String weekId; // YYYY-MM-DD (Friday start)
  String label;
  List<GoalItem> goals;

  WeekTab({required this.weekId, required this.label, required this.goals});

  Map<String, dynamic> toJson() => {
        'weekId': weekId,
        'label': label,
        'goals': goals.map((g) => g.toJson()).toList(),
      };

  factory WeekTab.fromJson(Map<String, dynamic> json) {
    final wId = json['weekId'] ?? '';
    return WeekTab(
      weekId: wId,
      label: json['label'] ?? getWeekLabel(wId),
      goals: (json['goals'] as List<dynamic>? ?? [])
          .map((item) => GoalItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class MonthTab {
  String monthId; // YYYY-MM
  List<GoalItem> goals;

  MonthTab({required this.monthId, required this.goals});

  Map<String, dynamic> toJson() => {
        'monthId': monthId,
        'goals': goals.map((g) => g.toJson()).toList(),
      };

  factory MonthTab.fromJson(Map<String, dynamic> json) {
    return MonthTab(
      monthId: json['monthId'] ?? '',
      goals: (json['goals'] as List<dynamic>? ?? [])
          .map((item) => GoalItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class YearTab {
  String yearId; // YYYY
  List<GoalItem> goals;

  YearTab({required this.yearId, required this.goals});

  Map<String, dynamic> toJson() => {
        'yearId': yearId,
        'goals': goals.map((g) => g.toJson()).toList(),
      };

  factory YearTab.fromJson(Map<String, dynamic> json) {
    return YearTab(
      yearId: json['yearId'] ?? '',
      goals: (json['goals'] as List<dynamic>? ?? [])
          .map((item) => GoalItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class NamazItem {
  int id;
  String name;
  String time;
  String note;

  NamazItem({
    required this.id,
    required this.name,
    required this.time,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'time': time,
        'note': note,
      };

  factory NamazItem.fromJson(Map<String, dynamic> json) {
    return NamazItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      time: json['time'] ?? '',
      note: json['note'] ?? '',
    );
  }
}

class NamazTab {
  String tabId;
  String name;
  List<NamazItem> items;

  NamazTab({required this.tabId, required this.name, required this.items});

  Map<String, dynamic> toJson() => {
        'tabId': tabId,
        'name': name,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory NamazTab.fromJson(Map<String, dynamic> json) {
    return NamazTab(
      tabId: json['tabId'] ?? 'tab_main',
      name: json['name'] ?? 'Main Schedule',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => NamazItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

// Utility date functions matching FocusFlow logic
String getTodayDate() {
  final now = DateTime.now();
  return DateFormat('yyyy-MM-dd').format(now);
}

String formatDayLabel(String dateId) {
  try {
    final parsed = DateTime.parse(dateId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(parsed.year, parsed.month, parsed.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today (${DateFormat('MMM d').format(parsed)})';
    if (diff == -1) return 'Yesterday (${DateFormat('MMM d').format(parsed)})';
    if (diff == 1) return 'Tomorrow (${DateFormat('MMM d').format(parsed)})';
    return DateFormat('EEE, MMM d').format(parsed);
  } catch (_) {
    return dateId;
  }
}

// Returns the Friday of the current week (Friday–Friday cycle)
String getFridayWeek([DateTime? date]) {
  final d = date ?? DateTime.now();
  final weekday = d.weekday; // Mon=1, ..., Fri=5, Sat=6, Sun=7
  // Distance back to previous Friday:
  // If Friday (5), diff = 0
  // If Saturday (6), diff = 1
  // If Sunday (7), diff = 2
  // If Monday (1), diff = 3
  // If Tuesday (2), diff = 4
  // If Wednesday (3), diff = 5
  // If Thursday (4), diff = 6
  final diff = (weekday - DateTime.friday + 7) % 7;
  final friday = d.subtract(Duration(days: diff));
  return DateFormat('yyyy-MM-dd').format(friday);
}

String getWeekLabel(String weekId) {
  try {
    final start = DateTime.parse(weekId);
    // Friday to next Friday (7 days)
    final end = start.add(const Duration(days: 7));
    final startStr = DateFormat('MMM d').format(start);
    final endStr = DateFormat('MMM d').format(end);
    return '$startStr – $endStr';
  } catch (_) {
    return weekId;
  }
}

String getCurrentMonthId() {
  return DateFormat('yyyy-MM').format(DateTime.now());
}

String getMonthLabel(String monthId) {
  try {
    final parts = monthId.split('-');
    if (parts.length == 2) {
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final dt = DateTime(year, month);
      return DateFormat('MMMM yyyy').format(dt);
    }
  } catch (_) {}
  return monthId;
}

String getCurrentYearId() {
  return DateTime.now().year.toString();
}

String getUpcomingYearId() {
  return (DateTime.now().year + 1).toString();
}

