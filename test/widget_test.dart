import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusflow/main.dart';
import 'package:focusflow/services/storage_service.dart';
import 'package:focusflow/widgets/doc_editor_widget.dart';

void main() {
  testWidgets('FocusFlow smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(FocusFlowApp(storageService: storage));
    await tester.pumpAndSettle();

    expect(find.text('FocusFlow'), findsOneWidget);
  });

  group('AutoPointTextInputFormatter Tests', () {
    final formatter = AutoPointTextInputFormatter();

    test('Auto-adds bullet point when Enter is pressed on bullet line', () {
      const oldVal = TextEditingValue(
        text: '• First task',
        selection: TextSelection.collapsed(offset: 12),
      );
      const newVal = TextEditingValue(
        text: '• First task\n',
        selection: TextSelection.collapsed(offset: 13),
      );

      final res = formatter.formatEditUpdate(oldVal, newVal);
      expect(res.text, equals('• First task\n• '));
      expect(res.selection.baseOffset, equals(15));
    });

    test('Auto-adds checkpoint when Enter is pressed on checkpoint line', () {
      const oldVal = TextEditingValue(
        text: '☑ Target 1',
        selection: TextSelection.collapsed(offset: 10),
      );
      const newVal = TextEditingValue(
        text: '☑ Target 1\n',
        selection: TextSelection.collapsed(offset: 11),
      );

      final res = formatter.formatEditUpdate(oldVal, newVal);
      expect(res.text, equals('☑ Target 1\n☑ '));
      expect(res.selection.baseOffset, equals(13));
    });

    test('Auto-increments numbered list on Enter', () {
      const oldVal = TextEditingValue(
        text: '1. First step',
        selection: TextSelection.collapsed(offset: 13),
      );
      const newVal = TextEditingValue(
        text: '1. First step\n',
        selection: TextSelection.collapsed(offset: 14),
      );

      final res = formatter.formatEditUpdate(oldVal, newVal);
      expect(res.text, equals('1. First step\n2. '));
      expect(res.selection.baseOffset, equals(17));
    });

    test('Clears bullet when Enter is pressed on an empty bullet line', () {
      const oldVal = TextEditingValue(
        text: '• First\n• ',
        selection: TextSelection.collapsed(offset: 10),
      );
      const newVal = TextEditingValue(
        text: '• First\n• \n',
        selection: TextSelection.collapsed(offset: 11),
      );

      final res = formatter.formatEditUpdate(oldVal, newVal);
      expect(res.text, equals('• First\n'));
      expect(res.selection.baseOffset, equals(8));
    });
  });

  group('Tab & Task Copy Operations Tests', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await storage.init();
    });

    test('Copy Day Tab creates copied and copied(1) tabs with copied tasks', () {
      final today = storage.days.first.dateId;
      storage.addDailyGoal(today, 'Goal A', 'high');
      storage.addDailyGoal(today, 'Goal B', 'medium');

      // First copy
      storage.copyDayTab(today);
      expect(storage.days.length, equals(2));
      final copy1 = storage.days.last;
      expect(copy1.label, contains('(copied)'));
      expect(copy1.goals.length, equals(2));
      expect(copy1.goals[0].copyTag, equals('copied'));
      expect(copy1.goals[1].copyTag, equals('copied'));

      // Second copy of same base
      storage.copyDayTab(today);
      expect(storage.days.length, equals(3));
      final copy2 = storage.days.last;
      expect(copy2.label, contains('(copied(1))'));
      expect(copy2.goals[0].copyTag, equals('copied(1)'));
    });

    test('Copy Weekly Tab creates copied and copied(1) tabs', () {
      final curWeek = storage.weeks.first.weekId;
      storage.addWeeklyGoal(curWeek, 'Weekly Task 1', 'high');

      storage.copyWeeklyTab(curWeek);
      expect(storage.weeks.length, equals(2));
      final copy1 = storage.weeks.last;
      expect(copy1.label, contains('(copied)'));
      expect(copy1.goals.first.copyTag, equals('copied'));

      storage.copyWeeklyTab(curWeek);
      expect(storage.weeks.length, equals(3));
      final copy2 = storage.weeks.last;
      expect(copy2.label, contains('(copied(1))'));
      expect(copy2.goals.first.copyTag, equals('copied(1)'));
    });

    test('Copy Monthly Tab creates copied and copied(1) tabs', () {
      final curMonth = storage.months.first.monthId;
      storage.addMonthlyGoal(curMonth, 'Monthly Task 1', 'none');

      storage.copyMonthlyTab(curMonth);
      expect(storage.months.length, equals(2));
      final copy1 = storage.months.last;
      expect(copy1.label, contains('(copied)'));
      expect(copy1.goals.first.copyTag, equals('copied'));

      storage.copyMonthlyTab(curMonth);
      expect(storage.months.length, equals(3));
      final copy2 = storage.months.last;
      expect(copy2.label, contains('(copied(1))'));
      expect(copy2.goals.first.copyTag, equals('copied(1)'));
    });

    test('Toggling task to done triggers sound without exception', () {
      storage.addTask('Quick task');
      final taskId = storage.tasks.first.id;
      expect(storage.tasks.first.done, isFalse);

      storage.toggleTask(taskId);
      expect(storage.tasks.first.done, isTrue);
    });
  });
}
