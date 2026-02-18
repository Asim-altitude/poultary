import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../database/databse_helper.dart';
import '../../utils/utils.dart';
import '../task_calender/recurring_tasks/task_calendar_screen.dart';
import 'routine_prefs.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  GUIDED ROUTINE SCREEN
//  – Step-by-step onboarding (neumorphic UI preserved)
//  – Builds smart, farm-personalised notification titles & bodies
//  – Saves to DB + schedules notifications + persists to SharedPrefs
// ═══════════════════════════════════════════════════════════════════════════

class GuidedRoutineScreen extends StatefulWidget {
  final String routineType;   // "Egg" | "Feed" | "Health" | "Finance"
  final String farmName;      // passed from parent, e.g. "GracyFarms"

  const GuidedRoutineScreen({
    Key? key,
    required this.routineType,
    this.farmName = '',
  }) : super(key: key);

  @override
  State<GuidedRoutineScreen> createState() => _GuidedRoutineScreenState();
}

class _GuidedRoutineScreenState extends State<GuidedRoutineScreen> {
  int  _step   = 0;
  bool _saving = false;

  // ── Collected answers ──────────────────────────────────────────────────
  String?    _frequency;       // egg/feed frequency choice
  TimeOfDay? _time1;           // primary time
  TimeOfDay? _time2;           // second time (Twice Daily)
  int?       _customDays;      // custom interval value
  bool       _reminderEnabled = false;
  int        _reminderMinutes = 30;
  String?    _auxFrequency;    // health / finance frequency
  bool       _trackOutcome    = false;

  final _db    = DatabaseHelper.instance;
  final _prefs = RoutinePrefs.instance;

  // ── Step list (dynamic — rebuilds when state changes) ─────────────────
  List<_RoutineStep> get _steps {
    switch (widget.routineType) {
      case 'Egg':     return _eggSteps();
      case 'Feed':    return _feedSteps();
      case 'Health':  return _healthSteps();
      case 'Finance': return _financeSteps();
      default:        return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  STEP DEFINITIONS
  // ══════════════════════════════════════════════════════════════════════

  List<_RoutineStep> _eggSteps() => [
    _RoutineStep(
      emoji: '🥚',
      title: 'routine_egg_q_frequency'.tr(),
      content: _OptionSelector(
        optionKeys: const [
          'routine_option_once_daily',
          'routine_option_twice_daily',
          'routine_option_every_2_days',
          'routine_option_custom',
        ],
        selected: _frequency,
        onSelect: (v) => setState(() { _frequency = v; _time2 = null; }),
      ),
    ),
    _RoutineStep(
      emoji: '⏰',
      title: _frequency == 'routine_option_twice_daily'.tr()
          ? 'routine_egg_q_time_first'.tr()
          : 'routine_egg_q_time'.tr(),
      content: _TimePickerTile(
        labelKey: _frequency == 'routine_option_twice_daily'.tr()
            ? 'routine_label_morning_collection'
            : 'routine_label_collection_time',
        time: _time1,
        onSelect: (t) => setState(() => _time1 = t),
      ),
    ),
    if (_frequency == 'routine_option_twice_daily'.tr())
      _RoutineStep(
        emoji: '⏰',
        title: 'routine_egg_q_time_second'.tr(),
        content: _TimePickerTile(
          labelKey: 'routine_label_evening_collection',
          time: _time2,
          onSelect: (t) => setState(() => _time2 = t),
        ),
      ),
    if (_frequency == 'routine_option_custom'.tr())
      _RoutineStep(
        emoji: '📅',
        title: 'routine_q_custom_days'.tr(),
        content: _NumberStepperTile(
          value: _customDays ?? 2,
          min: 1, max: 30,
          unitKey: 'routine_unit_days',
          onChanged: (v) => setState(() => _customDays = v),
        ),
      ),
    _RoutineStep(
      emoji: '🔔',
      title: 'routine_q_enable_reminders'.tr(),
      content: _ReminderStep(
        enabled: _reminderEnabled,
        minutes: _reminderMinutes,
        onToggle: (v) => setState(() => _reminderEnabled = v),
        onMinutesChanged: (m) => setState(() => _reminderMinutes = m),
      ),
    ),
  ];

  List<_RoutineStep> _feedSteps() => [
    _RoutineStep(
      emoji: '🌾',
      title: 'routine_feed_q_frequency'.tr(),
      content: _OptionSelector(
        optionKeys: const [
          'routine_option_once_daily',
          'routine_option_twice_daily',
          'routine_option_three_times',
          'routine_option_custom',
        ],
        selected: _frequency,
        onSelect: (v) => setState(() { _frequency = v; _time2 = null; }),
      ),
    ),
    _RoutineStep(
      emoji: '⏰',
      title: 'routine_feed_q_time_first'.tr(),
      content: _TimePickerTile(
        labelKey: 'routine_label_morning_feed',
        time: _time1,
        onSelect: (t) => setState(() => _time1 = t),
      ),
    ),
    if (_frequency == 'routine_option_twice_daily'.tr() ||
        _frequency == 'routine_option_three_times'.tr())
      _RoutineStep(
        emoji: '⏰',
        title: 'routine_feed_q_time_second'.tr(),
        content: _TimePickerTile(
          labelKey: 'routine_label_afternoon_feed',
          time: _time2,
          onSelect: (t) => setState(() => _time2 = t),
        ),
      ),
    if (_frequency == 'routine_option_custom'.tr())
      _RoutineStep(
        emoji: '📅',
        title: 'routine_q_custom_hours'.tr(),
        content: _NumberStepperTile(
          value: _customDays ?? 8,
          min: 1, max: 24,
          unitKey: 'routine_unit_hours',
          onChanged: (v) => setState(() => _customDays = v),
        ),
      ),
    _RoutineStep(
      emoji: '🔔',
      title: 'routine_q_enable_reminders'.tr(),
      content: _ReminderStep(
        enabled: _reminderEnabled,
        minutes: _reminderMinutes,
        onToggle: (v) => setState(() => _reminderEnabled = v),
        onMinutesChanged: (m) => setState(() => _reminderMinutes = m),
      ),
    ),
  ];

  List<_RoutineStep> _healthSteps() => [
    _RoutineStep(
      emoji: '💊',
      title: 'routine_health_q_frequency'.tr(),
      content: _OptionSelector(
        optionKeys: const [
          'routine_option_daily',
          'routine_option_weekly',
          'routine_option_every_2_weeks',
          'routine_option_custom',
        ],
        selected: _auxFrequency,
        onSelect: (v) => setState(() => _auxFrequency = v),
      ),
    ),
    if (_auxFrequency == 'routine_option_custom'.tr())
      _RoutineStep(
        emoji: '📅',
        title: 'routine_q_custom_days'.tr(),
        content: _NumberStepperTile(
          value: _customDays ?? 3,
          min: 1, max: 60,
          unitKey: 'routine_unit_days',
          onChanged: (v) => setState(() => _customDays = v),
        ),
      ),
    _RoutineStep(
      emoji: '⏰',
      title: 'routine_health_q_time'.tr(),
      content: _TimePickerTile(
        labelKey: 'routine_label_health_check_time',
        time: _time1,
        onSelect: (t) => setState(() => _time1 = t),
      ),
    ),
    _RoutineStep(
      emoji: '📊',
      title: 'routine_health_q_track'.tr(),
      content: _OptionSelector(
        optionKeys: const [
          'routine_option_yes_track',
          'routine_option_no_thanks',
        ],
        selected: _trackOutcome ? 'routine_option_yes_track'.tr() : null,
        onSelect: (v) => setState(
            () => _trackOutcome = v == 'routine_option_yes_track'.tr()),
      ),
    ),
    _RoutineStep(
      emoji: '🔔',
      title: 'routine_q_enable_reminders'.tr(),
      content: _ReminderStep(
        enabled: _reminderEnabled,
        minutes: _reminderMinutes,
        onToggle: (v) => setState(() => _reminderEnabled = v),
        onMinutesChanged: (m) => setState(() => _reminderMinutes = m),
      ),
    ),
  ];

  List<_RoutineStep> _financeSteps() => [
    _RoutineStep(
      emoji: '💰',
      title: 'routine_finance_q_frequency'.tr(),
      content: _OptionSelector(
        optionKeys: const [
          'routine_option_daily',
          'routine_option_weekly',
          'routine_option_monthly',
          'routine_option_custom',
        ],
        selected: _auxFrequency,
        onSelect: (v) => setState(() => _auxFrequency = v),
      ),
    ),
    _RoutineStep(
      emoji: '⏰',
      title: 'routine_finance_q_time'.tr(),
      content: _TimePickerTile(
        labelKey: 'routine_label_finance_time',
        time: _time1,
        onSelect: (t) => setState(() => _time1 = t),
      ),
    ),
    _RoutineStep(
      emoji: '🔔',
      title: 'routine_q_enable_reminders'.tr(),
      content: _ReminderStep(
        enabled: _reminderEnabled,
        minutes: _reminderMinutes,
        onToggle: (v) => setState(() => _reminderEnabled = v),
        onMinutesChanged: (m) => setState(() => _reminderMinutes = m),
      ),
    ),
  ];

  // ══════════════════════════════════════════════════════════════════════
  //  NAVIGATION
  // ══════════════════════════════════════════════════════════════════════

  void _next() {
    final steps = _steps;
    if (_step < steps.length - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_step > 0) setState(() => _step--);
  }

  // ══════════════════════════════════════════════════════════════════════
  //  FINISH — save + schedule + persist
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final tasks   = _buildTasks();
      final summary = _buildSummaryText();

      for (final entry in tasks) {
        await _db.createTask(entry.task, entry.date);
        if (entry.task.enableNotification &&
            entry.task.notificationMinutesBefore != null) {
          await _scheduleNotification(entry.task, entry.date);
        }
      }

      // ── Persist to SharedPrefs ──────────────────────────────────────
      await _prefs.saveRoutine(widget.routineType, summary);

      if (!mounted) return;
      setState(() => _saving = false);
      _showSuccessDialog(summary);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('routine_save_error'.tr()),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  TASK BUILDERS
  // ══════════════════════════════════════════════════════════════════════

  List<_ScheduledTask> _buildTasks() {
    final now       = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final t1        = _time1 ?? const TimeOfDay(hour: 7,  minute: 0);
    final t2        = _time2 ?? const TimeOfDay(hour: 17, minute: 0);
    final baseId    =
        '${widget.routineType.toLowerCase()}_routine_${now.millisecondsSinceEpoch}';

    switch (widget.routineType) {
      case 'Egg':     return _eggTasks(baseId, startDate, t1, t2);
      case 'Feed':    return _feedTasks(baseId, startDate, t1, t2);
      case 'Health':  return _healthTasks(baseId, startDate, t1);
      case 'Finance': return _financeTasks(baseId, startDate, t1);
      default:        return [];
    }
  }

  List<_ScheduledTask> _eggTasks(
      String base, DateTime start, TimeOfDay t1, TimeOfDay t2) {
    final pattern  = _eggRecurrence();
    final isTwice  = _frequency == 'routine_option_twice_daily'.tr();
    final farmLine = _farmGreeting();

    final title1 = 'routine_notif_egg_title'.tr();
    final body1  = 'routine_notif_egg_body'.tr(namedArgs: {
      'farm':    farmLine,
      'session': isTwice ? 'routine_notif_session_morning'.tr() : '',
      'minutes': '$_reminderMinutes',
    });

    final tasks = [
      _ScheduledTask(
        task: LivestockTask(
          id:          '${base}_1',
          title:       title1,
          description: body1,
          time:        t1,
          taskType:    TaskType.egg_collection,
          assignedUsers: [],
          recurrencePattern:         pattern,
          enableNotification:        _reminderEnabled,
          notificationMinutesBefore: _reminderEnabled ? _reminderMinutes : null,
        ),
        date: start,
      ),
    ];

    if (isTwice) {
      tasks.add(_ScheduledTask(
        task: LivestockTask(
          id:          '${base}_2',
          title:       'routine_notif_egg_title_evening'.tr(),
          description: 'routine_notif_egg_body'.tr(namedArgs: {
            'farm':    farmLine,
            'session': 'routine_notif_session_evening'.tr(),
            'minutes': '$_reminderMinutes',
          }),
          time:        t2,
          taskType:    TaskType.egg_collection,
          assignedUsers: [],
          recurrencePattern:         pattern,
          enableNotification:        _reminderEnabled,
          notificationMinutesBefore: _reminderEnabled ? _reminderMinutes : null,
        ),
        date: start,
      ));
    }
    return tasks;
  }

  List<_ScheduledTask> _feedTasks(
      String base, DateTime start, TimeOfDay t1, TimeOfDay t2) {
    final pattern  = _feedRecurrence();
    final farmLine = _farmGreeting();
    final isMulti  = _frequency == 'routine_option_twice_daily'.tr() ||
                     _frequency == 'routine_option_three_times'.tr();

    final tasks = [
      _ScheduledTask(
        task: LivestockTask(
          id:          '${base}_1',
          title:       'routine_notif_feed_title'.tr(),
          description: 'routine_notif_feed_body'.tr(namedArgs: {
            'farm':    farmLine,
            'session': isMulti ? 'routine_notif_session_morning'.tr() : '',
            'minutes': '$_reminderMinutes',
          }),
          time:        t1,
          taskType:    TaskType.feeding,
          assignedUsers: [],
          recurrencePattern:         pattern,
          enableNotification:        _reminderEnabled,
          notificationMinutesBefore: _reminderEnabled ? _reminderMinutes : null,
        ),
        date: start,
      ),
    ];

    if (isMulti) {
      tasks.add(_ScheduledTask(
        task: LivestockTask(
          id:          '${base}_2',
          title:       'routine_notif_feed_title_second'.tr(),
          description: 'routine_notif_feed_body'.tr(namedArgs: {
            'farm':    farmLine,
            'session': 'routine_notif_session_afternoon'.tr(),
            'minutes': '$_reminderMinutes',
          }),
          time:        t2,
          taskType:    TaskType.feeding,
          assignedUsers: [],
          recurrencePattern:         pattern,
          enableNotification:        _reminderEnabled,
          notificationMinutesBefore: _reminderEnabled ? _reminderMinutes : null,
        ),
        date: start,
      ));
    }
    return tasks;
  }

  List<_ScheduledTask> _healthTasks(
      String base, DateTime start, TimeOfDay t1) {
    final interval = _auxFrequency == 'routine_option_daily'.tr()         ? 1
                   : _auxFrequency == 'routine_option_weekly'.tr()        ? 7
                   : _auxFrequency == 'routine_option_every_2_weeks'.tr() ? 14
                   : (_customDays ?? 3);

    final pattern  = RecurrencePattern(
      type:     RecurrenceType.daily,
      interval: interval,
      endDate:  DateTime.now().add(const Duration(days: 365)),
    );
    final farmLine = _farmGreeting();

    return [
      _ScheduledTask(
        task: LivestockTask(
          id:          base,
          title:       'routine_notif_health_title'.tr(),
          description: 'routine_notif_health_body'.tr(namedArgs: {
            'farm':    farmLine,
            'minutes': '$_reminderMinutes',
          }),
          time:        t1,
          taskType:    TaskType.healthCheck,
          assignedUsers: [],
          notes:       _trackOutcome
              ? 'routine_health_track_note'.tr()
              : null,
          recurrencePattern:         pattern,
          enableNotification:        _reminderEnabled,
          notificationMinutesBefore: _reminderEnabled ? _reminderMinutes : null,
        ),
        date: start,
      ),
    ];
  }

  List<_ScheduledTask> _financeTasks(
      String base, DateTime start, TimeOfDay t1) {
    final interval = _auxFrequency == 'routine_option_daily'.tr()   ? 1
                   : _auxFrequency == 'routine_option_weekly'.tr()  ? 7
                   : _auxFrequency == 'routine_option_monthly'.tr() ? 30
                   : (_customDays ?? 7);
    final type     = interval >= 28 ? RecurrenceType.monthly
                   : interval >= 7  ? RecurrenceType.weekly
                                    : RecurrenceType.daily;
    final pattern  = RecurrencePattern(
      type:     type,
      interval: 1,
      endDate:  DateTime.now().add(const Duration(days: 365)),
    );
    final farmLine = _farmGreeting();

    return [
      _ScheduledTask(
        task: LivestockTask(
          id:          base,
          title:       'routine_notif_finance_title'.tr(),
          description: 'routine_notif_finance_body'.tr(namedArgs: {
            'farm':    farmLine,
            'minutes': '$_reminderMinutes',
          }),
          time:        t1,
          taskType:    TaskType.other,
          assignedUsers: [],
          recurrencePattern:         pattern,
          enableNotification:        _reminderEnabled,
          notificationMinutesBefore: _reminderEnabled ? _reminderMinutes : null,
        ),
        date: start,
      ),
    ];
  }

  // ══════════════════════════════════════════════════════════════════════
  //  NOTIFICATION SCHEDULING  (same call as AddEditTaskScreen)
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _scheduleNotification(LivestockTask task, DateTime date) async {
    try {
      final taskDt = DateTime(
          date.year, date.month, date.day,
          task.time.hour, task.time.minute);
      final notifDt  = taskDt.subtract(
          Duration(minutes: task.notificationMinutesBefore!));
      final secDelay = ((notifDt.millisecondsSinceEpoch -
              DateTime.now().millisecondsSinceEpoch) /
          1000).round();

      if (secDelay > 0) {
        // ── Smart, user-friendly notification content ─────────────────
        final smartTitle = _smartNotifTitle(task, task.notificationMinutesBefore!);
        final smartBody  = _smartNotifBody(task, task.notificationMinutesBefore!);

        Utils.showNotification(
          Utils.generateNotificationId(task.id),
          smartTitle,
          smartBody,
          secDelay,
        );
      }
    } catch (e) {
      debugPrint('Routine notification error: $e');
    }
  }

  // ── Smart notification title ───────────────────────────────────────────
  String _smartNotifTitle(LivestockTask task, int minutesBefore) {
    final farm = widget.farmName.isNotEmpty
        ? widget.farmName
        : 'routine_notif_your_farm'.tr();

    // e.g. "🥚 Egg Collection in 30 minutes"
    switch (task.taskType) {
      case TaskType.egg_collection:
        return 'routine_notif_title_egg_smart'.tr(namedArgs: {
          'farm':    farm,
          'minutes': _minutesLabel(minutesBefore),
        });
      case TaskType.feeding:
        return 'routine_notif_title_feed_smart'.tr(namedArgs: {
          'farm':    farm,
          'minutes': _minutesLabel(minutesBefore),
        });
      case TaskType.healthCheck:
        return 'routine_notif_title_health_smart'.tr(namedArgs: {
          'farm':    farm,
          'minutes': _minutesLabel(minutesBefore),
        });
      default:
        return 'routine_notif_title_finance_smart'.tr(namedArgs: {
          'farm':    farm,
          'minutes': _minutesLabel(minutesBefore),
        });
    }
  }

  // ── Smart notification body ────────────────────────────────────────────
  String _smartNotifBody(LivestockTask task, int minutesBefore) {
    final farm = widget.farmName.isNotEmpty
        ? widget.farmName
        : 'routine_notif_your_farm'.tr();

    switch (task.taskType) {
      case TaskType.egg_collection:
        return 'routine_notif_body_egg_smart'.tr(namedArgs: {
          'farm':    farm,
          'minutes': _minutesLabel(minutesBefore),
          'time':    task.time.format(context),
        });
      case TaskType.feeding:
        return 'routine_notif_body_feed_smart'.tr(namedArgs: {
          'farm':    farm,
          'minutes': _minutesLabel(minutesBefore),
          'time':    task.time.format(context),
        });
      case TaskType.healthCheck:
        return 'routine_notif_body_health_smart'.tr(namedArgs: {
          'farm':    farm,
          'minutes': _minutesLabel(minutesBefore),
          'time':    task.time.format(context),
        });
      default:
        return 'routine_notif_body_finance_smart'.tr(namedArgs: {
          'farm':    farm,
          'minutes': _minutesLabel(minutesBefore),
          'time':    task.time.format(context),
        });
    }
  }

  // ── "30 minutes" / "1 hour" label ─────────────────────────────────────
  String _minutesLabel(int m) {
    if (m < 60) return 'routine_notif_minutes'.tr(namedArgs: {'n': '$m'});
    if (m == 60) return 'routine_notif_1_hour'.tr();
    return 'routine_notif_hours'.tr(namedArgs: {'n': '${m ~/ 60}'});
  }

  // ── Farm greeting prefix ───────────────────────────────────────────────
  String _farmGreeting() =>
      widget.farmName.isNotEmpty ? widget.farmName : '';

  // ── Human-readable summary for the card subtitle ──────────────────────
  String _buildSummaryText() {
    final t1str = _time1 != null
        ? '${_time1!.format(context)}'
        : '';
    final freqLabel = _frequency ?? _auxFrequency ?? '';
    if (t1str.isNotEmpty && freqLabel.isNotEmpty) {
      return '$freqLabel · $t1str';
    }
    if (t1str.isNotEmpty) return t1str;
    return freqLabel;
  }

  // ── Recurrence patterns ────────────────────────────────────────────────
  RecurrencePattern _eggRecurrence() {
    final interval = _frequency == 'routine_option_every_2_days'.tr() ? 2
                   : _frequency == 'routine_option_custom'.tr()       ? (_customDays ?? 1)
                   : 1;
    return RecurrencePattern(
      type:     RecurrenceType.daily,
      interval: interval,
      endDate:  DateTime.now().add(const Duration(days: 365)),
    );
  }

  RecurrencePattern _feedRecurrence() => RecurrencePattern(
    type:     RecurrenceType.daily,
    interval: 1,
    endDate:  DateTime.now().add(const Duration(days: 365)),
  );

  // ══════════════════════════════════════════════════════════════════════
  //  SUCCESS DIALOG
  // ══════════════════════════════════════════════════════════════════════

  void _showSuccessDialog(String summary) {
    final emoji = {'Egg': '🥚', 'Feed': '🌾', 'Health': '💊', 'Finance': '💰'}[widget.routineType] ?? '✅';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(
                'routine_success_title'.tr(
                    namedArgs: {'type': widget.routineType}),
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _reminderEnabled
                    ? 'routine_success_body_with_reminder'.tr(
                        namedArgs: {'summary': summary})
                    : 'routine_success_body_no_reminder'.tr(
                        namedArgs: {'summary': summary}),
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);              // close dialog
                  Navigator.pop(context, widget.routineType); // return to list
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('routine_success_done'.tr(),
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════


  @override
  Widget build(BuildContext context) {
    final steps    = _steps;
    final safe     = _step.clamp(0, steps.length - 1);
    final step     = steps[safe];
    final isLast   = safe == steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFE6EBF2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'routine_setup_title'.tr(namedArgs: {'type': widget.routineType}),
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ProgressBar(current: safe + 1, total: steps.length),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: _StepCard(
                  emoji: step.emoji,
                  title: step.title,
                  content: step.content,
                ),
              ),
            ),

            const SizedBox(height: 16),

            _saving
                ? const CircularProgressIndicator(color: Color(0xFF6C63FF))
                : Row(children: [
                    if (safe > 0) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prev,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF6C63FF), width: 2),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('routine_btn_back'.tr(),
                              style: GoogleFonts.poppins(
                                  color: const Color(0xFF6C63FF),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          isLast
                              ? 'routine_btn_finish'.tr()
                              : 'routine_btn_next'.tr(),
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                        ),
                      ),
                    ),
                  ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class _RoutineStep {
  final String emoji;
  final String title;
  final Widget content;
  const _RoutineStep({required this.emoji, required this.title, required this.content});
}

class _ScheduledTask {
  final LivestockTask task;
  final DateTime      date;
  const _ScheduledTask({required this.task, required this.date});
}

// ═══════════════════════════════════════════════════════════════════════════
//  WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _StepCard extends StatelessWidget {
  final String emoji, title;
  final Widget content;
  const _StepCard({required this.emoji, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
          BoxShadow(color: Colors.black12, offset: Offset(5, 5), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int current, total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          'routine_step_of'.tr(namedArgs: {
            'current': '$current',
            'total':   '$total',
          }),
          style: GoogleFonts.poppins(
              fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
        ),
        Text('${((current / total) * 100).round()}%',
            style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF6C63FF),
                fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: current / total,
          minHeight: 6,
          backgroundColor: Colors.black12,
          valueColor:
              const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
        ),
      ),
    ]);
  }
}

// ── Option selector ───────────────────────────────────────────────────────────
// Takes translation KEY strings, renders translated labels

class _OptionSelector extends StatelessWidget {
  final List<String> optionKeys;
  final String?      selected;     // stores the TRANSLATED string
  final ValueChanged<String> onSelect;

  const _OptionSelector({
    required this.optionKeys,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: optionKeys.map((key) {
        final label = key.tr();
        final isSel = selected == label;
        return GestureDetector(
          onTap: () => onSelect(label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isSel
                  ? const Color(0xFF6C63FF)
                  : const Color(0xFFF0F3F7),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSel
                  ? const [
                      BoxShadow(
                          color: Colors.black12,
                          offset: Offset(3, 3),
                          blurRadius: 6),
                      BoxShadow(
                          color: Colors.white,
                          offset: Offset(-3, -3),
                          blurRadius: 6),
                    ]
                  : const [
                      BoxShadow(
                          color: Colors.white,
                          offset: Offset(-5, -5),
                          blurRadius: 10),
                      BoxShadow(
                          color: Colors.black12,
                          offset: Offset(5, 5),
                          blurRadius: 10),
                    ],
            ),
            child: Row(children: [
              Expanded(
                child: Text(label,
                    style: GoogleFonts.poppins(
                        color:      isSel ? Colors.white : Colors.black87,
                        fontSize:   15,
                        fontWeight: FontWeight.w600)),
              ),
              Icon(
                isSel
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: isSel ? Colors.white : Colors.grey,
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── Time picker tile ──────────────────────────────────────────────────────────

class _TimePickerTile extends StatelessWidget {
  final String       labelKey;
  final TimeOfDay?   time;
  final ValueChanged<TimeOfDay> onSelect;

  const _TimePickerTile({
    required this.labelKey,
    required this.time,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final selected = time != null;
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(
                    primary: Color(0xFF6C63FF))),
            child: child!,
          ),
        );
        if (picked != null) onSelect(picked);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF).withOpacity(0.08)
              : const Color(0xFFF0F3F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C63FF).withOpacity(0.45)
                : Colors.transparent,
          ),
          boxShadow: const [
            BoxShadow(
                color: Colors.white,
                offset: Offset(-5, -5),
                blurRadius: 10),
            BoxShadow(
                color: Colors.black12,
                offset: Offset(5, 5),
                blurRadius: 10),
          ],
        ),
        child: Row(children: [
          Icon(Icons.access_time_rounded,
              color: selected ? const Color(0xFF6C63FF) : Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(labelKey.tr(),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.black45)),
                Text(
                  selected
                      ? time!.format(context)
                      : 'routine_time_tap_hint'.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? const Color(0xFF6C63FF)
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.black26),
        ]),
      ),
    );
  }
}

// ── Number stepper ────────────────────────────────────────────────────────────

class _NumberStepperTile extends StatelessWidget {
  final int value, min, max;
  final String unitKey;
  final ValueChanged<int> onChanged;

  const _NumberStepperTile({
    required this.value,
    required this.min,
    required this.max,
    required this.unitKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
          BoxShadow(
              color: Colors.black12, offset: Offset(5, 5), blurRadius: 10),
        ],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _StepBtn(
            icon: Icons.remove_rounded,
            onTap: value > min ? () => onChanged(value - 1) : null),
        const SizedBox(width: 28),
        Column(children: [
          Text('$value',
              style: GoogleFonts.poppins(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6C63FF))),
          Text(unitKey.tr(),
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.black45)),
        ]),
        const SizedBox(width: 28),
        _StepBtn(
            icon: Icons.add_rounded,
            onTap: value < max ? () => onChanged(value + 1) : null),
      ]),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: on ? const Color(0xFF6C63FF) : Colors.grey.shade300,
          shape: BoxShape.circle,
          boxShadow: on
              ? const [BoxShadow(color: Colors.black12, offset: Offset(2, 2), blurRadius: 6)]
              : [],
        ),
        child: Icon(icon,
            color: on ? Colors.white : Colors.grey, size: 22),
      ),
    );
  }
}

// ── Reminder step (toggle + lead-time chips) ──────────────────────────────────

class _ReminderStep extends StatelessWidget {
  final bool    enabled;
  final int     minutes;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int>  onMinutesChanged;

  const _ReminderStep({
    required this.enabled,
    required this.minutes,
    required this.onToggle,
    required this.onMinutesChanged,
  });

  static const _opts = [5, 10, 15, 30, 60, 120];

  String _chipLabel(int m, BuildContext ctx) {
    if (m < 60) return 'routine_notif_chip_min'.tr(namedArgs: {'n': '$m'});
    if (m == 60) return 'routine_notif_chip_1h'.tr();
    return 'routine_notif_chip_hours'.tr(namedArgs: {'n': '${m ~/ 60}'});
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Yes/No toggle row
      Row(children: [
        Expanded(
          child: _ToggleChip(
            label: 'routine_option_yes_remind'.tr(),
            selected: enabled,
            color: const Color(0xFF6C63FF),
            onTap: () => onToggle(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToggleChip(
            label: 'routine_option_no_thanks'.tr(),
            selected: !enabled,
            color: Colors.grey,
            onTap: () => onToggle(false),
          ),
        ),
      ]),

      // Lead-time chips (only when enabled)
      if (enabled) ...[
        const SizedBox(height: 16),
        Text('routine_reminder_how_early'.tr(),
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _opts.map((m) {
            final sel = minutes == m;
            return GestureDetector(
              onTap: () => onMinutesChanged(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFFF0F3F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel
                        ? const Color(0xFF6C63FF)
                        : Colors.black12,
                  ),
                ),
                child: Text(_chipLabel(m, context),
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : Colors.black87)),
              ),
            );
          }).toList(),
        ),
      ],
    ]);
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool   selected;
  final Color  color;
  final VoidCallback onTap;
  const _ToggleChip({
    required this.label, required this.selected,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? color : const Color(0xFFF0F3F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? color : Colors.black12),
          boxShadow: const [
            BoxShadow(
                color: Colors.white,
                offset: Offset(-3, -3),
                blurRadius: 6),
            BoxShadow(
                color: Colors.black12,
                offset: Offset(3, 3),
                blurRadius: 6),
          ],
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black54)),
        ),
      ),
    );
  }
}
