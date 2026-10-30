import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import 'sound_service.dart';

class StorageService extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _initialized = false;
  bool get isInitialized => _initialized;

  List<TaskItem> tasks = [];
  List<NoteItem> notes = [];
  List<DayTab> days = [];
  List<WeekTab> weeks = [];
  List<MonthTab> months = [];
  List<YearTab> years = [];
  List<NamazTab> namazTabs = [];

  String? activeDayTab;
  String? activeWeekTab;
  String? activeMonthTab;
  String? activeYearTab;
  String? activeNamazTab;

  String splitLeft = 'daily';
  String splitRight = 'weekly';

  String achievements = '';
  String targets = '';

  int _nextTaskId = 1;
  int _nextNoteId = 1;
  int _nextDailyGoalId = 1;
  int _nextWeeklyGoalId = 1;
  int _nextMonthlyGoalId = 1;
  int _nextYearlyGoalId = 1;
  int _nextNamazItemId = 1;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAll();
    _initDefaultsIfNeeded();
    _recalcIds();
    _initialized = true;
    notifyListeners();
  }

  void _loadAll() {
    // Tasks
    try {
      final str = _prefs.getString('ff_tasks');
      if (str != null && str.isNotEmpty) {
        final list = jsonDecode(str) as List;
        tasks = list.map((e) => TaskItem.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}

    // Notes
    try {
      final str = _prefs.getString('ff_notes');
      if (str != null && str.isNotEmpty) {
        final list = jsonDecode(str) as List;
        notes = list.map((e) => NoteItem.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}

    // Days
    try {
      final str = _prefs.getString('ff_days');
      if (str != null && str.isNotEmpty) {
        final list = jsonDecode(str) as List;
        days = list.map((e) => DayTab.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}

    // Weeks
    try {
      final str = _prefs.getString('ff_weeks');
      if (str != null && str.isNotEmpty) {
        final list = jsonDecode(str) as List;
        weeks = list.map((e) => WeekTab.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}

    // Months
    try {
      final str = _prefs.getString('ff_months');
      if (str != null && str.isNotEmpty) {
        final list = jsonDecode(str) as List;
        months = list.map((e) => MonthTab.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}

    // Years
    try {
      final str = _prefs.getString('ff_years');
      if (str != null && str.isNotEmpty) {
        final list = jsonDecode(str) as List;
        years = list.map((e) => YearTab.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}

    // Namaz Tabs
    try {
      final str = _prefs.getString('ff_namaz_tabs');
      if (str != null && str.isNotEmpty) {
        final list = jsonDecode(str) as List;
        namazTabs = list.map((e) => NamazTab.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}

    // Active tabs
    activeDayTab = _prefs.getString('ff_activeDayTab');
    activeWeekTab = _prefs.getString('ff_activeWeekTab');
    activeMonthTab = _prefs.getString('ff_activeMonthTab');
    activeYearTab = _prefs.getString('ff_activeYearTab');
    activeNamazTab = _prefs.getString('ff_activeNamazTab');

    // Split settings
    splitLeft = _prefs.getString('ff_splitLeft') ?? 'daily';
    splitRight = _prefs.getString('ff_splitRight') ?? 'weekly';

    // Rich progress content
    achievements = _prefs.getString('ff_ach') ?? '';
    targets = _prefs.getString('ff_tgt') ?? '';
  }

  void _initDefaultsIfNeeded() {
    final today = getTodayDate();
    if (!days.any((d) => d.dateId == today)) {
      days.insert(0, DayTab(dateId: today, goals: []));
    }
    activeDayTab ??= today;

    final curWeek = getFridayWeek();
    if (!weeks.any((w) => w.weekId == curWeek)) {
      weeks.insert(0, WeekTab(weekId: curWeek, label: getWeekLabel(curWeek), goals: []));
    }
    activeWeekTab ??= curWeek;

    final curMonth = getCurrentMonthId();
    if (!months.any((m) => m.monthId == curMonth)) {
      months.insert(0, MonthTab(monthId: curMonth, goals: []));
    }
    activeMonthTab ??= curMonth;

    final curYear = getCurrentYearId();
    if (!years.any((y) => y.yearId == curYear)) {
      years.insert(0, YearTab(yearId: curYear, goals: []));
    }
    activeYearTab ??= curYear;

    if (namazTabs.isEmpty) {
      namazTabs = [
        NamazTab(
          tabId: 'tab_main',
          name: 'Main Schedule',
          items: [
            NamazItem(id: 1, name: 'Fajr', time: '05:00', note: 'Morning Prayer'),
            NamazItem(id: 2, name: 'Dhuhr', time: '12:30', note: 'Noon Prayer'),
            NamazItem(id: 3, name: 'Asr', time: '16:15', note: 'Afternoon Prayer'),
            NamazItem(id: 4, name: 'Maghrib', time: '17:45', note: 'Sunset Prayer'),
            NamazItem(id: 5, name: 'Isha', time: '19:30', note: 'Night Prayer'),
          ],
        )
      ];
      activeNamazTab = 'tab_main';
      _saveNamazTabs();
    } else {
      activeNamazTab ??= namazTabs.first.tabId;
    }
  }

  void _recalcIds() {
    if (tasks.isNotEmpty) {
      _nextTaskId = tasks.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
    }
    if (notes.isNotEmpty) {
      _nextNoteId = notes.map((n) => n.id).reduce((a, b) => a > b ? a : b) + 1;
    }
    for (final d in days) {
      if (d.goals.isNotEmpty) {
        final m = d.goals.map((g) => g.id).reduce((a, b) => a > b ? a : b);
        if (m >= _nextDailyGoalId) _nextDailyGoalId = m + 1;
      }
    }
    for (final w in weeks) {
      if (w.goals.isNotEmpty) {
        final m = w.goals.map((g) => g.id).reduce((a, b) => a > b ? a : b);
        if (m >= _nextWeeklyGoalId) _nextWeeklyGoalId = m + 1;
      }
    }
    for (final mo in months) {
      if (mo.goals.isNotEmpty) {
        final m = mo.goals.map((g) => g.id).reduce((a, b) => a > b ? a : b);
        if (m >= _nextMonthlyGoalId) _nextMonthlyGoalId = m + 1;
      }
    }
    for (final y in years) {
      if (y.goals.isNotEmpty) {
        final m = y.goals.map((g) => g.id).reduce((a, b) => a > b ? a : b);
        if (m >= _nextYearlyGoalId) _nextYearlyGoalId = m + 1;
      }
    }
    for (final t in namazTabs) {
      if (t.items.isNotEmpty) {
        final m = t.items.map((i) => i.id).reduce((a, b) => a > b ? a : b);
        if (m >= _nextNamazItemId) _nextNamazItemId = m + 1;
      }
    }
  }

  // --- SAVE METHODS ---
  Future<void> _saveTasks() async {
    await _prefs.setString('ff_tasks', jsonEncode(tasks.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveNotes() async {
    await _prefs.setString('ff_notes', jsonEncode(notes.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveDays() async {
    await _prefs.setString('ff_days', jsonEncode(days.map((e) => e.toJson()).toList()));
    if (activeDayTab != null) await _prefs.setString('ff_activeDayTab', activeDayTab!);
  }

  Future<void> _saveWeeks() async {
    await _prefs.setString('ff_weeks', jsonEncode(weeks.map((e) => e.toJson()).toList()));
    if (activeWeekTab != null) await _prefs.setString('ff_activeWeekTab', activeWeekTab!);
  }

  Future<void> _saveMonths() async {
    await _prefs.setString('ff_months', jsonEncode(months.map((e) => e.toJson()).toList()));
    if (activeMonthTab != null) await _prefs.setString('ff_activeMonthTab', activeMonthTab!);
  }

  Future<void> _saveYears() async {
    await _prefs.setString('ff_years', jsonEncode(years.map((e) => e.toJson()).toList()));
    if (activeYearTab != null) await _prefs.setString('ff_activeYearTab', activeYearTab!);
  }

  Future<void> _saveNamazTabs() async {
    await _prefs.setString('ff_namaz_tabs', jsonEncode(namazTabs.map((e) => e.toJson()).toList()));
    if (activeNamazTab != null) await _prefs.setString('ff_activeNamazTab', activeNamazTab!);
  }

  Future<void> saveSplitConfig(String left, String right) async {
    splitLeft = left;
    splitRight = right;
    await _prefs.setString('ff_splitLeft', left);
    await _prefs.setString('ff_splitRight', right);
    notifyListeners();
  }

  Future<void> saveAchievements(String text) async {
    achievements = text;
    await _prefs.setString('ff_ach', text);
    notifyListeners();
  }

  Future<void> saveTargets(String text) async {
    targets = text;
    await _prefs.setString('ff_tgt', text);
    notifyListeners();
  }

  // --- TASKS ACTIONS ---
  void addTask(String text) {
    if (text.trim().isEmpty) return;
    tasks.insert(0, TaskItem(id: _nextTaskId++, text: text.trim()));
    _saveTasks();
    notifyListeners();
  }

  void toggleTask(int id) {
    final t = tasks.firstWhere((e) => e.id == id, orElse: () => TaskItem(id: -1, text: ''));
    if (t.id != -1) {
      t.done = !t.done;
      if (t.done) {
        playTaskDoneSound();
      }
      _saveTasks();
      notifyListeners();
    }
  }

  void editTask(int id, String newText) {
    final t = tasks.firstWhere((e) => e.id == id, orElse: () => TaskItem(id: -1, text: ''));
    if (t.id != -1 && newText.trim().isNotEmpty) {
      t.text = newText.trim();
      _saveTasks();
      notifyListeners();
    }
  }

  void deleteTask(int id) {
    tasks.removeWhere((e) => e.id == id);
    _saveTasks();
    notifyListeners();
  }

  // --- NOTES ACTIONS ---
  void addNote([String text = '']) {
    notes.insert(0, NoteItem(id: _nextNoteId++, text: text));
    _saveNotes();
    notifyListeners();
  }

  void updateNote(int id, String text) {
    final n = notes.firstWhere((e) => e.id == id, orElse: () => NoteItem(id: -1, text: ''));
    if (n.id != -1) {
      n.text = text;
      _saveNotes();
      notifyListeners();
    }
  }

  void deleteNote(int id) {
    notes.removeWhere((e) => e.id == id);
    _saveNotes();
    notifyListeners();
  }

  // --- DAILY GOALS ACTIONS ---
  void selectDayTab(String dateId) {
    activeDayTab = dateId;
    _prefs.setString('ff_activeDayTab', dateId);
    notifyListeners();
  }

  void addDayTab(String dateId) {
    if (!days.any((d) => d.dateId == dateId)) {
      days.add(DayTab(dateId: dateId, goals: []));
      _sortDays();
    }
    activeDayTab = dateId;
    _saveDays();
    notifyListeners();
  }

  void deleteDayTab(String dateId) {
    final today = getTodayDate();
    if (dateId == today) return; // Cannot delete running today
    days.removeWhere((d) => d.dateId == dateId);
    if (activeDayTab == dateId) {
      activeDayTab = days.isNotEmpty ? days.first.dateId : today;
    }
    _saveDays();
    notifyListeners();
  }

  void _sortDays() {
    final today = getTodayDate();
    days.sort((a, b) {
      final aToday = a.dateId == today ? 1 : 0;
      final bToday = b.dateId == today ? 1 : 0;
      if (aToday != bToday) return bToday - aToday;
      return b.dateId.compareTo(a.dateId);
    });
  }

  void addDailyGoal(String dateId, String text, String priority) {
    if (text.trim().isEmpty) return;
    final day = days.firstWhere((d) => d.dateId == dateId, orElse: () {
      final newD = DayTab(dateId: dateId, goals: []);
      days.add(newD);
      return newD;
    });
    day.goals.insert(0, GoalItem(id: _nextDailyGoalId++, text: text.trim(), priority: priority));
    _saveDays();
    notifyListeners();
  }

  void toggleDailyGoal(String dateId, int goalId) {
    final day = days.firstWhere((d) => d.dateId == dateId, orElse: () => DayTab(dateId: '', goals: []));
    final g = day.goals.firstWhere((x) => x.id == goalId, orElse: () => GoalItem(id: -1, text: ''));
    if (g.id != -1) {
      g.done = !g.done;
      if (g.done) {
        playTaskDoneSound();
      }
      _saveDays();
      notifyListeners();
    }
  }

  void editDailyGoal(String dateId, int goalId, String newText) {
    final day = days.firstWhere((d) => d.dateId == dateId, orElse: () => DayTab(dateId: '', goals: []));
    final g = day.goals.firstWhere((x) => x.id == goalId, orElse: () => GoalItem(id: -1, text: ''));
    if (g.id != -1 && newText.trim().isNotEmpty) {
      g.text = newText.trim();
      _saveDays();
      notifyListeners();
    }
  }

  void deleteDailyGoal(String dateId, int goalId) {
    final day = days.firstWhere((d) => d.dateId == dateId, orElse: () => DayTab(dateId: '', goals: []));
    day.goals.removeWhere((g) => g.id == goalId);
    _saveDays();
    notifyListeners();
  }

  void copyDayTab(String sourceDateId) {
    final sourceDay = days.firstWhere(
      (d) => d.dateId == sourceDateId,
      orElse: () => DayTab(dateId: sourceDateId, goals: []),
    );
    final baseId = sourceDay.dateId.split('_copy_')[0];
    final existingCopies = days.where((d) => d.dateId.startsWith('${baseId}_copy_')).toList();
    final copyIndex = existingCopies.length;
    final tag = getCopyTag(copyIndex);
    final newDateId = '${baseId}_copy_${copyIndex + 1}';

    final baseLabel = sourceDay.label ?? formatDayLabel(sourceDay.dateId);
    final cleanBaseLabel = baseLabel.replaceAll(RegExp(r'\s*\((copied|copied\(\d+\))\)'), '').trim();
    final newLabel = '$cleanBaseLabel ($tag)';

    final copiedGoals = sourceDay.goals.map((g) {
      return GoalItem(
        id: _nextDailyGoalId++,
        text: g.text,
        priority: g.priority,
        done: false,
        copyTag: tag,
      );
    }).toList();

    days.add(DayTab(dateId: newDateId, label: newLabel, goals: copiedGoals));
    activeDayTab = newDateId;
    _saveDays();
    notifyListeners();
  }

  // --- WEEKLY GOALS ACTIONS ---
  void selectWeekTab(String weekId) {
    activeWeekTab = weekId;
    _prefs.setString('ff_activeWeekTab', weekId);
    notifyListeners();
  }

  void addNewWeekTab() {
    final curWeek = getFridayWeek();
    if (weeks.isEmpty) {
      weeks.add(WeekTab(weekId: curWeek, label: getWeekLabel(curWeek), goals: []));
      activeWeekTab = curWeek;
    } else {
      // Find latest Friday date and add 7 days
      final sortedWeeks = List<WeekTab>.from(weeks)
        ..sort((a, b) => b.weekId.compareTo(a.weekId));
      final latest = DateTime.tryParse(sortedWeeks.first.weekId) ?? DateTime.now();
      final nextFriday = latest.add(const Duration(days: 7));
      final nextId = getFridayWeek(nextFriday);
      if (!weeks.any((w) => w.weekId == nextId)) {
        weeks.add(WeekTab(weekId: nextId, label: getWeekLabel(nextId), goals: []));
      }
      activeWeekTab = nextId;
    }
    _sortWeeks();
    _saveWeeks();
    notifyListeners();
  }

  void deleteWeekTab(String weekId) {
    final curWeek = getFridayWeek();
    if (weekId == curWeek) return; // Cannot delete running week
    weeks.removeWhere((w) => w.weekId == weekId);
    if (activeWeekTab == weekId) {
      activeWeekTab = weeks.isNotEmpty ? weeks.first.weekId : curWeek;
    }
    _saveWeeks();
    notifyListeners();
  }

  void _sortWeeks() {
    final curWeek = getFridayWeek();
    weeks.sort((a, b) {
      final aCur = a.weekId == curWeek ? 1 : 0;
      final bCur = b.weekId == curWeek ? 1 : 0;
      if (aCur != bCur) return bCur - aCur;
      return b.weekId.compareTo(a.weekId);
    });
  }

  void addWeeklyGoal(String weekId, String text, String priority) {
    if (text.trim().isEmpty) return;
    final week = weeks.firstWhere((w) => w.weekId == weekId, orElse: () {
      final newW = WeekTab(weekId: weekId, label: getWeekLabel(weekId), goals: []);
      weeks.add(newW);
      return newW;
    });
    week.goals.insert(0, GoalItem(id: _nextWeeklyGoalId++, text: text.trim(), priority: priority));
    _saveWeeks();
    notifyListeners();
  }

  void toggleWeeklyGoal(String weekId, int goalId) {
    final week = weeks.firstWhere((w) => w.weekId == weekId, orElse: () => WeekTab(weekId: '', label: '', goals: []));
    final g = week.goals.firstWhere((x) => x.id == goalId, orElse: () => GoalItem(id: -1, text: ''));
    if (g.id != -1) {
      g.done = !g.done;
      if (g.done) {
        playTaskDoneSound();
      }
      _saveWeeks();
      notifyListeners();
    }
  }

  void editWeeklyGoal(String weekId, int goalId, String newText) {
    final week = weeks.firstWhere((w) => w.weekId == weekId, orElse: () => WeekTab(weekId: '', label: '', goals: []));
    final g = week.goals.firstWhere((x) => x.id == goalId, orElse: () => GoalItem(id: -1, text: ''));
    if (g.id != -1 && newText.trim().isNotEmpty) {
      g.text = newText.trim();
      _saveWeeks();
      notifyListeners();
    }
  }

  void deleteWeeklyGoal(String weekId, int goalId) {
    final week = weeks.firstWhere((w) => w.weekId == weekId, orElse: () => WeekTab(weekId: '', label: '', goals: []));
    week.goals.removeWhere((g) => g.id == goalId);
    _saveWeeks();
    notifyListeners();
  }

  void copyWeeklyTab(String sourceWeekId) {
    final sourceWeek = weeks.firstWhere(
      (w) => w.weekId == sourceWeekId,
      orElse: () => WeekTab(weekId: sourceWeekId, label: getWeekLabel(sourceWeekId), goals: []),
    );
    final baseId = sourceWeek.weekId.split('_copy_')[0];
    final existingCopies = weeks.where((w) => w.weekId.startsWith('${baseId}_copy_')).toList();
    final copyIndex = existingCopies.length;
    final tag = getCopyTag(copyIndex);
    final newWeekId = '${baseId}_copy_${copyIndex + 1}';

    final cleanBaseLabel = sourceWeek.label.replaceAll(RegExp(r'\s*\((copied|copied\(\d+\))\)'), '').trim();
    final newLabel = '$cleanBaseLabel ($tag)';

    final copiedGoals = sourceWeek.goals.map((g) {
      return GoalItem(
        id: _nextWeeklyGoalId++,
        text: g.text,
        priority: g.priority,
        done: false,
        copyTag: tag,
      );
    }).toList();

    weeks.add(WeekTab(weekId: newWeekId, label: newLabel, goals: copiedGoals));
    activeWeekTab = newWeekId;
    _saveWeeks();
    notifyListeners();
  }

  // --- MONTHLY GOALS ACTIONS ---
  void selectMonthTab(String monthId) {
    activeMonthTab = monthId;
    _prefs.setString('ff_activeMonthTab', monthId);
    notifyListeners();
  }

  void addNewMonthTab() {
    final curMonth = getCurrentMonthId();
    if (months.isEmpty) {
      months.add(MonthTab(monthId: curMonth, goals: []));
      activeMonthTab = curMonth;
    } else {
      final sortedMonths = List<MonthTab>.from(months)
        ..sort((a, b) => b.monthId.compareTo(a.monthId));
      final latest = sortedMonths.first.monthId;
      final parts = latest.split('-');
      var y = int.parse(parts[0]);
      var m = int.parse(parts[1]);
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
      final nextId = '$y-${m.toString().padLeft(2, '0')}';
      if (!months.any((mo) => mo.monthId == nextId)) {
        months.add(MonthTab(monthId: nextId, goals: []));
      }
      activeMonthTab = nextId;
    }
    _sortMonths();
    _saveMonths();
    notifyListeners();
  }

  void deleteMonthTab(String monthId) {
    final curMonth = getCurrentMonthId();
    if (monthId == curMonth) return; // Cannot delete running month
    months.removeWhere((m) => m.monthId == monthId);
    if (activeMonthTab == monthId) {
      activeMonthTab = months.isNotEmpty ? months.first.monthId : curMonth;
    }
    _saveMonths();
    notifyListeners();
  }

  void _sortMonths() {
    final curMonth = getCurrentMonthId();
    months.sort((a, b) {
      final aCur = a.monthId == curMonth ? 1 : 0;
      final bCur = b.monthId == curMonth ? 1 : 0;
      if (aCur != bCur) return bCur - aCur;
      return b.monthId.compareTo(a.monthId);
    });
  }

  void addMonthlyGoal(String monthId, String text, String priority) {
    if (text.trim().isEmpty) return;
    final month = months.firstWhere((m) => m.monthId == monthId, orElse: () {
      final newM = MonthTab(monthId: monthId, goals: []);
      months.add(newM);
      return newM;
    });
    month.goals.insert(0, GoalItem(id: _nextMonthlyGoalId++, text: text.trim(), priority: priority));
    _saveMonths();
    notifyListeners();
  }

  void toggleMonthlyGoal(String monthId, int goalId) {
    final month = months.firstWhere((m) => m.monthId == monthId, orElse: () => MonthTab(monthId: '', goals: []));
    final g = month.goals.firstWhere((x) => x.id == goalId, orElse: () => GoalItem(id: -1, text: ''));
    if (g.id != -1) {
      g.done = !g.done;
      if (g.done) {
        playTaskDoneSound();
      }
      _saveMonths();
      notifyListeners();
    }
  }

  void editMonthlyGoal(String monthId, int goalId, String newText) {
    final month = months.firstWhere((m) => m.monthId == monthId, orElse: () => MonthTab(monthId: '', goals: []));
    final g = month.goals.firstWhere((x) => x.id == goalId, orElse: () => GoalItem(id: -1, text: ''));
    if (g.id != -1 && newText.trim().isNotEmpty) {
      g.text = newText.trim();
      _saveMonths();
      notifyListeners();
    }
  }

  void deleteMonthlyGoal(String monthId, int goalId) {
    final month = months.firstWhere((m) => m.monthId == monthId, orElse: () => MonthTab(monthId: '', goals: []));
    month.goals.removeWhere((g) => g.id == goalId);
    _saveMonths();
    notifyListeners();
  }

  void copyMonthlyTab(String sourceMonthId) {
    final sourceMonth = months.firstWhere(
      (m) => m.monthId == sourceMonthId,
      orElse: () => MonthTab(monthId: sourceMonthId, goals: []),
    );
    final baseId = sourceMonth.monthId.split('_copy_')[0];
    final existingCopies = months.where((m) => m.monthId.startsWith('${baseId}_copy_')).toList();
    final copyIndex = existingCopies.length;
    final tag = getCopyTag(copyIndex);
    final newMonthId = '${baseId}_copy_${copyIndex + 1}';

    final baseLabel = sourceMonth.label ?? getMonthLabel(sourceMonth.monthId);
    final cleanBaseLabel = baseLabel.replaceAll(RegExp(r'\s*\((copied|copied\(\d+\))\)'), '').trim();
    final newLabel = '$cleanBaseLabel ($tag)';

    final copiedGoals = sourceMonth.goals.map((g) {
      return GoalItem(
        id: _nextMonthlyGoalId++,
        text: g.text,
        priority: g.priority,
        done: false,
        copyTag: tag,
      );
    }).toList();

    months.add(MonthTab(monthId: newMonthId, label: newLabel, goals: copiedGoals));
    activeMonthTab = newMonthId;
    _saveMonths();
    notifyListeners();
  }

  // Copy tasks from previous tab into the current active tab
  void copyPreviousTasks(String category, String activeId) {
    if (category == 'daily') {
      final curIndex = days.indexWhere((d) => d.dateId == activeId);
      if (curIndex == -1 || days.length <= 1) return;
      final prevIndex = curIndex > 0 ? curIndex - 1 : 1;
      final prevDay = days[prevIndex];
      final curDay = days[curIndex];
      final copyCount = curDay.goals.where((g) => g.copyTag != null).length;
      final tag = getCopyTag(copyCount > 0 ? 1 : 0);
      final newGoals = prevDay.goals.map((g) => GoalItem(
        id: _nextDailyGoalId++,
        text: g.text,
        priority: g.priority,
        done: false,
        copyTag: tag,
      )).toList();
      curDay.goals.addAll(newGoals);
      _saveDays();
      notifyListeners();
    } else if (category == 'weekly') {
      final curIndex = weeks.indexWhere((w) => w.weekId == activeId);
      if (curIndex == -1 || weeks.length <= 1) return;
      final prevIndex = curIndex > 0 ? curIndex - 1 : 1;
      final prevWeek = weeks[prevIndex];
      final curWeek = weeks[curIndex];
      final copyCount = curWeek.goals.where((g) => g.copyTag != null).length;
      final tag = getCopyTag(copyCount > 0 ? 1 : 0);
      final newGoals = prevWeek.goals.map((g) => GoalItem(
        id: _nextWeeklyGoalId++,
        text: g.text,
        priority: g.priority,
        done: false,
        copyTag: tag,
      )).toList();
      curWeek.goals.addAll(newGoals);
      _saveWeeks();
      notifyListeners();
    } else if (category == 'monthly') {
      final curIndex = months.indexWhere((m) => m.monthId == activeId);
      if (curIndex == -1 || months.length <= 1) return;
      final prevIndex = curIndex > 0 ? curIndex - 1 : 1;
      final prevMonth = months[prevIndex];
      final curMonth = months[curIndex];
      final copyCount = curMonth.goals.where((g) => g.copyTag != null).length;
      final tag = getCopyTag(copyCount > 0 ? 1 : 0);
      final newGoals = prevMonth.goals.map((g) => GoalItem(
        id: _nextMonthlyGoalId++,
        text: g.text,
        priority: g.priority,
        done: false,
        copyTag: tag,
      )).toList();
      curMonth.goals.addAll(newGoals);
      _saveMonths();
      notifyListeners();
    }
  }

  void duplicateSingleGoal(String category, String activeId, int goalId) {
    if (category == 'daily') {
      final day = days.firstWhere((d) => d.dateId == activeId, orElse: () => DayTab(dateId: '', goals: []));
      final idx = day.goals.indexWhere((g) => g.id == goalId);
      if (idx != -1) {
        final orig = day.goals[idx];
        final copyCount = day.goals.where((g) => g.text == orig.text && g.copyTag != null).length;
        final tag = getCopyTag(copyCount);
        day.goals.insert(idx + 1, GoalItem(id: _nextDailyGoalId++, text: orig.text, priority: orig.priority, done: false, copyTag: tag));
        _saveDays();
        notifyListeners();
      }
    } else if (category == 'weekly') {
      final week = weeks.firstWhere((w) => w.weekId == activeId, orElse: () => WeekTab(weekId: '', label: '', goals: []));
      final idx = week.goals.indexWhere((g) => g.id == goalId);
      if (idx != -1) {
        final orig = week.goals[idx];
        final copyCount = week.goals.where((g) => g.text == orig.text && g.copyTag != null).length;
        final tag = getCopyTag(copyCount);
        week.goals.insert(idx + 1, GoalItem(id: _nextWeeklyGoalId++, text: orig.text, priority: orig.priority, done: false, copyTag: tag));
        _saveWeeks();
        notifyListeners();
      }
    } else if (category == 'monthly') {
      final month = months.firstWhere((m) => m.monthId == activeId, orElse: () => MonthTab(monthId: '', goals: []));
      final idx = month.goals.indexWhere((g) => g.id == goalId);
      if (idx != -1) {
        final orig = month.goals[idx];
        final copyCount = month.goals.where((g) => g.text == orig.text && g.copyTag != null).length;
        final tag = getCopyTag(copyCount);
        month.goals.insert(idx + 1, GoalItem(id: _nextMonthlyGoalId++, text: orig.text, priority: orig.priority, done: false, copyTag: tag));
        _saveMonths();
        notifyListeners();
      }
    }
  }

  // --- YEARLY GOALS ACTIONS (Max 2 tabs: Running & Upcoming) ---
  void selectYearTab(String yearId) {
    activeYearTab = yearId;
    _prefs.setString('ff_activeYearTab', yearId);
    notifyListeners();
  }

  void addNewYearTab() {
    final upYear = getUpcomingYearId();
    if (years.length >= 2 || years.any((y) => y.yearId == upYear)) return;
    years.add(YearTab(yearId: upYear, goals: []));
    activeYearTab = upYear;
    _sortYears();
    _saveYears();
    notifyListeners();
  }

  void deleteYearTab(String yearId) {
    final curYear = getCurrentYearId();
    if (yearId == curYear) return; // Cannot delete running year
    years.removeWhere((y) => y.yearId == yearId);
    if (activeYearTab == yearId) {
      activeYearTab = curYear;
    }
    _saveYears();
    notifyListeners();
  }

  void _sortYears() {
    final curYear = getCurrentYearId();
    years.sort((a, b) {
      final aCur = a.yearId == curYear ? 1 : 0;
      final bCur = b.yearId == curYear ? 1 : 0;
      if (aCur != bCur) return bCur - aCur;
      return b.yearId.compareTo(a.yearId);
    });
  }

  void addYearlyGoal(String yearId, String text, String priority) {
    if (text.trim().isEmpty) return;
    final year = years.firstWhere((y) => y.yearId == yearId, orElse: () {
      final newY = YearTab(yearId: yearId, goals: []);
      years.add(newY);
      return newY;
    });
    year.goals.insert(0, GoalItem(id: _nextYearlyGoalId++, text: text.trim(), priority: priority));
    _saveYears();
    notifyListeners();
  }

  void toggleYearlyGoal(String yearId, int goalId) {
    final year = years.firstWhere((y) => y.yearId == yearId, orElse: () => YearTab(yearId: '', goals: []));
    final g = year.goals.firstWhere((x) => x.id == goalId, orElse: () => GoalItem(id: -1, text: ''));
    if (g.id != -1) {
      g.done = !g.done;
      if (g.done) {
        playTaskDoneSound();
      }
      _saveYears();
      notifyListeners();
    }
  }

  void editYearlyGoal(String yearId, int goalId, String newText) {
    final year = years.firstWhere((y) => y.yearId == yearId, orElse: () => YearTab(yearId: '', goals: []));
    final g = year.goals.firstWhere((x) => x.id == goalId, orElse: () => GoalItem(id: -1, text: ''));
    if (g.id != -1 && newText.trim().isNotEmpty) {
      g.text = newText.trim();
      _saveYears();
      notifyListeners();
    }
  }

  void deleteYearlyGoal(String yearId, int goalId) {
    final year = years.firstWhere((y) => y.yearId == yearId, orElse: () => YearTab(yearId: '', goals: []));
    year.goals.removeWhere((g) => g.id == goalId);
    _saveYears();
    notifyListeners();
  }

  // --- NAMAZ TABS ACTIONS (Max 12 Tabs) ---
  void selectNamazTab(String tabId) {
    activeNamazTab = tabId;
    _prefs.setString('ff_activeNamazTab', tabId);
    notifyListeners();
  }

  bool addNewNamazTab() {
    if (namazTabs.length >= 12) return false;
    var num = namazTabs.length + 1;
    var name = 'Timetable $num';
    while (namazTabs.any((t) => t.name.toLowerCase() == name.toLowerCase())) {
      num++;
      name = 'Timetable $num';
    }
    final newId = 'nm_tab_${DateTime.now().millisecondsSinceEpoch}';
    namazTabs.add(NamazTab(tabId: newId, name: name, items: []));
    activeNamazTab = newId;
    _saveNamazTabs();
    notifyListeners();
    return true;
  }

  void renameNamazTab(String tabId, String newName) {
    final t = namazTabs.firstWhere((tab) => tab.tabId == tabId, orElse: () => NamazTab(tabId: '', name: '', items: []));
    if (t.tabId.isNotEmpty && newName.trim().isNotEmpty) {
      t.name = newName.trim();
      _saveNamazTabs();
      notifyListeners();
    }
  }

  bool deleteNamazTab(String tabId) {
    if (namazTabs.length <= 1) return false; // Must keep at least 1
    namazTabs.removeWhere((t) => t.tabId == tabId);
    if (activeNamazTab == tabId) {
      activeNamazTab = namazTabs.first.tabId;
    }
    _saveNamazTabs();
    notifyListeners();
    return true;
  }

  void addNamazItem(String tabId, String name, String time, String note) {
    if (name.trim().isEmpty || time.trim().isEmpty) return;
    final tab = namazTabs.firstWhere((t) => t.tabId == tabId, orElse: () => NamazTab(tabId: '', name: '', items: []));
    if (tab.tabId.isNotEmpty) {
      tab.items.insert(0, NamazItem(id: _nextNamazItemId++, name: name.trim(), time: time.trim(), note: note.trim()));
      _saveNamazTabs();
      notifyListeners();
    }
  }

  void editNamazItem(String tabId, int itemId, String newName, String newTime, String newNote) {
    final tab = namazTabs.firstWhere((t) => t.tabId == tabId, orElse: () => NamazTab(tabId: '', name: '', items: []));
    final item = tab.items.firstWhere((i) => i.id == itemId, orElse: () => NamazItem(id: -1, name: '', time: ''));
    if (item.id != -1) {
      if (newName.trim().isNotEmpty) item.name = newName.trim();
      if (newTime.trim().isNotEmpty) item.time = newTime.trim();
      item.note = newNote.trim();
      _saveNamazTabs();
      notifyListeners();
    }
  }

  void deleteNamazItem(String tabId, int itemId) {
    final tab = namazTabs.firstWhere((t) => t.tabId == tabId, orElse: () => NamazTab(tabId: '', name: '', items: []));
    tab.items.removeWhere((i) => i.id == itemId);
    _saveNamazTabs();
    notifyListeners();
  }

  // --- PROGRESS CALCULATIONS ---
  double get dailyProgress {
    final all = days.expand((d) => d.goals).toList();
    if (all.isEmpty) return 0;
    return all.where((g) => g.done).length / all.length;
  }

  double get weeklyProgress {
    final all = weeks.expand((w) => w.goals).toList();
    if (all.isEmpty) return 0;
    return all.where((g) => g.done).length / all.length;
  }

  double get monthlyProgress {
    final all = months.expand((m) => m.goals).toList();
    if (all.isEmpty) return 0;
    return all.where((g) => g.done).length / all.length;
  }

  double get yearlyProgress {
    final all = years.expand((y) => y.goals).toList();
    if (all.isEmpty) return 0;
    return all.where((g) => g.done).length / all.length;
  }

  Map<String, dynamic> get yearStats {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year + 1, 1, 1);

    // Exact days in current year (365 or 366 in leap year)
    final totalDays = endOfYear.difference(startOfYear).inDays;
    final dayOfYear = today.difference(startOfYear).inDays + 1;
    final passedDays = dayOfYear;
    final leftDays = (totalDays - passedDays).clamp(0, totalDays);

    // Week calculation: Friday to Friday
    // Find the first Friday of the year
    final int diffToFirstFriday = (DateTime.friday - startOfYear.weekday + 7) % 7;
    final DateTime firstFriday = startOfYear.add(Duration(days: diffToFirstFriday));

    int passedWeeks;
    if (today.isBefore(firstFriday)) {
      passedWeeks = 0;
    } else {
      passedWeeks = (today.difference(firstFriday).inDays ~/ 7) + 1;
    }
    const int totalWeeks = 52;
    final int leftWeeks = (totalWeeks - passedWeeks).clamp(0, totalWeeks);

    const int totalMonths = 12;
    final int passedMonths = now.month;
    final int leftMonths = (totalMonths - passedMonths).clamp(0, totalMonths);
    final int yearPct = (passedDays / totalDays * 100).round();

    return {
      'totalDays': totalDays,
      'passedDays': passedDays,
      'leftDays': leftDays,
      'totalWeeks': totalWeeks,
      'passedWeeks': passedWeeks,
      'leftWeeks': leftWeeks,
      'totalMonths': totalMonths,
      'passedMonths': passedMonths,
      'leftMonths': leftMonths,
      'yearPct': yearPct,
    };
  }
}

