import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/priority_chip.dart';

enum GoalCategory { daily, weekly, monthly, yearly }

class GoalsTabView extends StatefulWidget {
  final GoalCategory category;
  final StorageService store;
  final VoidCallback? onOpenSplit;
  final bool isSplitPane;

  const GoalsTabView({
    super.key,
    required this.category,
    required this.store,
    this.onOpenSplit,
    this.isSplitPane = false,
  });

  @override
  State<GoalsTabView> createState() => _GoalsTabViewState();
}

class _GoalsTabViewState extends State<GoalsTabView> {
  final TextEditingController _goalController = TextEditingController();
  PriorityLevel _selectedPriority = PriorityLevel.none;

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.category) {
      case GoalCategory.daily:
        return 'Daily Goals';
      case GoalCategory.weekly:
        return 'Weekly Goals (Fri–Fri)';
      case GoalCategory.monthly:
        return 'Monthly Goals';
      case GoalCategory.yearly:
        return 'Yearly Goals';
    }
  }

  Future<void> _pickDateForDaily() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Color(0xFF101424),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final dateId = DateFormat('yyyy-MM-dd').format(picked);
      widget.store.addDayTab(dateId);
    }
  }

  void _submitGoal(String activeId) {
    final text = _goalController.text.trim();
    if (text.isEmpty) return;

    switch (widget.category) {
      case GoalCategory.daily:
        widget.store.addDailyGoal(activeId, text, _selectedPriority.key);
        break;
      case GoalCategory.weekly:
        widget.store.addWeeklyGoal(activeId, text, _selectedPriority.key);
        break;
      case GoalCategory.monthly:
        widget.store.addMonthlyGoal(activeId, text, _selectedPriority.key);
        break;
      case GoalCategory.yearly:
        widget.store.addYearlyGoal(activeId, text, _selectedPriority.key);
        break;
    }

    _goalController.clear();
    setState(() => _selectedPriority = PriorityLevel.none);
  }

  void _showEditGoalDialog(String activeId, int goalId, String currentText) {
    final controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Goal'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Goal description'),
          onSubmitted: (val) {
            _commitEdit(activeId, goalId, val);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _commitEdit(activeId, goalId, controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _commitEdit(String activeId, int goalId, String newText) {
    switch (widget.category) {
      case GoalCategory.daily:
        widget.store.editDailyGoal(activeId, goalId, newText);
        break;
      case GoalCategory.weekly:
        widget.store.editWeeklyGoal(activeId, goalId, newText);
        break;
      case GoalCategory.monthly:
        widget.store.editMonthlyGoal(activeId, goalId, newText);
        break;
      case GoalCategory.yearly:
        widget.store.editYearlyGoal(activeId, goalId, newText);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: widget.isSplitPane ? double.infinity : 780),
      padding: EdgeInsets.all(widget.isSplitPane ? 14 : 20),
      decoration: BoxDecoration(
        color: AppTheme.cardGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isSplitPane ? AppTheme.primary.withOpacity(0.2) : AppTheme.cardBorder,
        ),
      ),
      child: _buildCategoryContent(),
    );
  }

  Widget _buildCategoryContent() {
    switch (widget.category) {
      case GoalCategory.daily:
        final activeId = widget.store.activeDayTab ?? getTodayDate();
        final currentDay = widget.store.days.firstWhere(
          (d) => d.dateId == activeId,
          orElse: () => DayTab(dateId: activeId, goals: []),
        );
        final isToday = activeId == getTodayDate();
        return _buildLayout(
          activeId: activeId,
          tabs: _buildDailyTabs(activeId),
          goals: currentDay.goals,
          isRunningItem: isToday,
        );

      case GoalCategory.weekly:
        final curWeek = getFridayWeek();
        final activeId = widget.store.activeWeekTab ?? curWeek;
        final currentWeek = widget.store.weeks.firstWhere(
          (w) => w.weekId == activeId,
          orElse: () => WeekTab(weekId: activeId, label: getWeekLabel(activeId), goals: []),
        );
        final isCurrentWeek = activeId == curWeek;
        return _buildLayout(
          activeId: activeId,
          tabs: _buildWeeklyTabs(activeId),
          goals: currentWeek.goals,
          isRunningItem: isCurrentWeek,
        );

      case GoalCategory.monthly:
        final curMonth = getCurrentMonthId();
        final activeId = widget.store.activeMonthTab ?? curMonth;
        final currentMonth = widget.store.months.firstWhere(
          (m) => m.monthId == activeId,
          orElse: () => MonthTab(monthId: activeId, goals: []),
        );
        final isCurrentMonth = activeId == curMonth;
        return _buildLayout(
          activeId: activeId,
          tabs: _buildMonthlyTabs(activeId),
          goals: currentMonth.goals,
          isRunningItem: isCurrentMonth,
        );

      case GoalCategory.yearly:
        final curYear = getCurrentYearId();
        final activeId = widget.store.activeYearTab ?? curYear;
        final currentYear = widget.store.years.firstWhere(
          (y) => y.yearId == activeId,
          orElse: () => YearTab(yearId: activeId, goals: []),
        );
        final isCurrentYear = activeId == curYear;
        return _buildLayout(
          activeId: activeId,
          tabs: _buildYearlyTabs(activeId),
          goals: currentYear.goals,
          isRunningItem: isCurrentYear,
        );
    }
  }

  Widget _buildLayout({
    required String activeId,
    required List<Widget> tabs,
    required List<GoalItem> goals,
    required bool isRunningItem,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Board Header (hidden if split pane to save space or styled smaller)
        if (!widget.isSplitPane) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  if (widget.category != GoalCategory.yearly) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF38BDF8),
                        side: const BorderSide(color: Color(0x4438BDF8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        if (widget.category == GoalCategory.daily) {
                          widget.store.copyDayTab(activeId);
                        } else if (widget.category == GoalCategory.weekly) {
                          widget.store.copyWeeklyTab(activeId);
                        } else if (widget.category == GoalCategory.monthly) {
                          widget.store.copyMonthlyTab(activeId);
                        }
                      },
                      icon: const Icon(Icons.content_copy_outlined, size: 13),
                      label: const Text('Copy Tab', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.onOpenSplit != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC4B5FD),
                        side: const BorderSide(color: Color(0x447C5CFC)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: widget.onOpenSplit,
                      icon: const Icon(Icons.splitscreen_outlined, size: 14),
                      label: const Text('Split Screen', style: TextStyle(fontSize: 12)),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${goals.length}',
                      style: const TextStyle(color: AppTheme.textDim, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Tabs Row (Horizontal scrollable)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: tabs),
        ),
        const SizedBox(height: 14),

        // Goals List
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: widget.isSplitPane ? 380 : 460,
          ),
          child: goals.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No goals added yet for this tab.',
                          style: TextStyle(color: AppTheme.textDim, fontSize: 13),
                        ),
                        if (widget.category != GoalCategory.yearly) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF38BDF8),
                              side: const BorderSide(color: Color(0x3338BDF8)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () => widget.store.copyPreviousTasks(widget.category.name, activeId),
                            icon: const Icon(Icons.copy_all_outlined, size: 14),
                            label: Text(
                              'Copy all tasks from previous ${widget.category.name} tab',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    return _buildGoalItem(activeId, goal, isRunningItem);
                  },
                ),
        ),

        const SizedBox(height: 14),

        // Add Goal Row
        _buildAddGoalRow(activeId),
      ],
    );
  }

  Widget _buildGoalItem(String activeId, GoalItem goal, bool isRunningTab) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3.5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRunningTab ? AppTheme.runningGreen.withOpacity(0.3) : Colors.white.withOpacity(0.05),
          width: isRunningTab ? 1.2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: InkWell(
              onTap: () {
                switch (widget.category) {
                  case GoalCategory.daily:
                    widget.store.toggleDailyGoal(activeId, goal.id);
                    break;
                  case GoalCategory.weekly:
                    widget.store.toggleWeeklyGoal(activeId, goal.id);
                    break;
                  case GoalCategory.monthly:
                    widget.store.toggleMonthlyGoal(activeId, goal.id);
                    break;
                  case GoalCategory.yearly:
                    widget.store.toggleYearlyGoal(activeId, goal.id);
                    break;
                }
              },
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: goal.done ? const Color(0xFFA78BFA) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: goal.done ? const Color(0xFFA78BFA) : Colors.white30,
                    width: 1.5,
                  ),
                ),
                child: goal.done
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  goal.text,
                  style: TextStyle(
                    color: goal.done ? AppTheme.textDim : AppTheme.textMain,
                    fontSize: 13.5,
                    decoration: goal.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (goal.priority.isNotEmpty) PriorityChipWidget(priorityKey: goal.priority),
                if (goal.copyTag != null && goal.copyTag!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.4)),
                    ),
                    child: Text(
                      goal.copyTag!,
                      style: const TextStyle(
                        color: Color(0xFFC4B5FD),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isRunningTab)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.runningGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.runningGreen.withOpacity(0.4)),
                    ),
                    child: const Text(
                      'Running',
                      style: TextStyle(
                        color: AppTheme.runningGreen,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.category != GoalCategory.yearly)
            IconButton(
              icon: const Icon(Icons.content_copy_outlined, size: 15, color: AppTheme.textDim),
              onPressed: () {
                widget.store.duplicateSingleGoal(widget.category.name, activeId, goal.id);
              },
              tooltip: 'Copy task',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textDim),
            onPressed: () => _showEditGoalDialog(activeId, goal.id, goal.text),
            tooltip: 'Edit',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppTheme.textDim),
            onPressed: () {
              switch (widget.category) {
                case GoalCategory.daily:
                  widget.store.deleteDailyGoal(activeId, goal.id);
                  break;
                case GoalCategory.weekly:
                  widget.store.deleteWeeklyGoal(activeId, goal.id);
                  break;
                case GoalCategory.monthly:
                  widget.store.deleteMonthlyGoal(activeId, goal.id);
                  break;
                case GoalCategory.yearly:
                  widget.store.deleteYearlyGoal(activeId, goal.id);
                  break;
              }
            },
            tooltip: 'Delete',
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  Widget _buildAddGoalRow(String activeId) {
    return Column(
      children: [
        TextField(
          controller: _goalController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Add ${_title.toLowerCase()} goal...',
          ),
          onSubmitted: (_) => _submitGoal(activeId),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x18FFFFFF)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PriorityLevel>(
                    value: _selectedPriority,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF13172E),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: PriorityLevel.values.map((p) {
                      return DropdownMenuItem<PriorityLevel>(
                        value: p,
                        child: Text(
                          p == PriorityLevel.none ? 'No Priority' : p.label,
                          style: TextStyle(
                            color: p == PriorityLevel.none ? AppTheme.textDim : p.textColor,
                            fontWeight: p == PriorityLevel.none ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPriority = val);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _submitGoal(activeId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B5BDB),
              ),
              child: const Text('Add Goal'),
            ),
          ],
        ),
      ],
    );
  }

  // Daily tabs generator
  List<Widget> _buildDailyTabs(String activeId) {
    final today = getTodayDate();
    final items = <Widget>[];

    for (final day in widget.store.days) {
      final isCurrent = day.dateId == today;
      final isActive = day.dateId == activeId;
      final label = day.label ?? formatDayLabel(day.dateId);
      items.add(_buildTabPill(
        label: label,
        isActive: isActive,
        isCurrent: isCurrent,
        onTap: () => widget.store.selectDayTab(day.dateId),
        onCopy: () => widget.store.copyDayTab(day.dateId),
        onDelete: isCurrent ? null : () => widget.store.deleteDayTab(day.dateId),
      ));
    }

    items.add(_buildAddTabButton(
      tooltip: 'Pick date to add day tab',
      onTap: _pickDateForDaily,
    ));

    return items;
  }

  // Weekly tabs generator
  List<Widget> _buildWeeklyTabs(String activeId) {
    final curWeek = getFridayWeek();
    final items = <Widget>[];

    for (final week in widget.store.weeks) {
      final isCurrent = week.weekId == curWeek;
      final isActive = week.weekId == activeId;
      items.add(_buildTabPill(
        label: week.label,
        isActive: isActive,
        isCurrent: isCurrent,
        onTap: () => widget.store.selectWeekTab(week.weekId),
        onCopy: () => widget.store.copyWeeklyTab(week.weekId),
        onDelete: isCurrent ? null : () => widget.store.deleteWeekTab(week.weekId),
      ));
    }

    items.add(_buildAddTabButton(
      tooltip: 'Add new week tab',
      onTap: widget.store.addNewWeekTab,
    ));

    return items;
  }

  // Monthly tabs generator
  List<Widget> _buildMonthlyTabs(String activeId) {
    final curMonth = getCurrentMonthId();
    final items = <Widget>[];

    for (final month in widget.store.months) {
      final isCurrent = month.monthId == curMonth;
      final isActive = month.monthId == activeId;
      final label = month.label ?? getMonthLabel(month.monthId);
      items.add(_buildTabPill(
        label: label,
        isActive: isActive,
        isCurrent: isCurrent,
        onTap: () => widget.store.selectMonthTab(month.monthId),
        onCopy: () => widget.store.copyMonthlyTab(month.monthId),
        onDelete: isCurrent ? null : () => widget.store.deleteMonthTab(month.monthId),
      ));
    }

    items.add(_buildAddTabButton(
      tooltip: 'Add next month tab',
      onTap: widget.store.addNewMonthTab,
    ));

    return items;
  }

  // Yearly tabs generator (Max 2 tabs: Running & Upcoming)
  List<Widget> _buildYearlyTabs(String activeId) {
    final curYear = getCurrentYearId();
    final upYear = getUpcomingYearId();
    final items = <Widget>[];

    for (final year in widget.store.years) {
      final isCurrent = year.yearId == curYear;
      final isActive = year.yearId == activeId;
      items.add(_buildTabPill(
        label: year.yearId,
        isActive: isActive,
        isCurrent: isCurrent,
        onTap: () => widget.store.selectYearTab(year.yearId),
        onDelete: isCurrent ? null : () => widget.store.deleteYearTab(year.yearId),
      ));
    }

    if (widget.store.years.length < 2 && !widget.store.years.any((y) => y.yearId == upYear)) {
      items.add(_buildAddTabButton(
        tooltip: 'Add upcoming year ($upYear)',
        onTap: widget.store.addNewYearTab,
      ));
    }

    return items;
  }

  Widget _buildTabPill({
    required String label,
    required bool isActive,
    required bool isCurrent,
    required VoidCallback onTap,
    VoidCallback? onCopy,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary.withOpacity(0.2) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppTheme.primary.withOpacity(0.5) : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCurrent) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppTheme.runningGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isActive ? const Color(0xFFC4B5FD) : AppTheme.textMuted,
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Copy tab and all its tasks',
                  child: InkWell(
                    onTap: onCopy,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.content_copy_outlined, size: 12.5, color: AppTheme.textDim),
                    ),
                  ),
                ),
              ],
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Close tab',
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close, size: 13, color: AppTheme.textDim),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddTabButton({required String tooltip, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1), style: BorderStyle.solid),
          ),
          child: const Icon(Icons.add, size: 16, color: AppTheme.textMuted),
        ),
      ),
    );
  }
}

