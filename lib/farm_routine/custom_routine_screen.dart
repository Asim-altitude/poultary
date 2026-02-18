import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../database/databse_helper.dart';
import '../../utils/utils.dart';
import '../task_calender/recurring_tasks/task_calendar_screen.dart';
import 'routine_prefs.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  CUSTOM ROUTINE SCREEN
//  Guides the user through creating a completely custom farm routine:
//    Step 1 – Name your routine
//    Step 2 – Pick an icon / emoji
//    Step 3 – How often? (frequency)
//    Step 4 – What time?  (+ second time if twice daily)
//    Step 5 – Custom interval (only if "Custom" selected)
//    Step 6 – Enable reminders + lead time
//
//  Returns a CustomRoutineResult to FarmRoutineScreen on success.
// ═══════════════════════════════════════════════════════════════════════════

class CustomRoutineResult {
  final String id;       // unique key for prefs
  final String name;
  final String emoji;
  final String summary;

  const CustomRoutineResult({
    required this.id,
    required this.name,
    required this.emoji,
    required this.summary,
  });
}

class CustomRoutineScreen extends StatefulWidget {
  final String farmName;

  const CustomRoutineScreen({Key? key, this.farmName = ''}) : super(key: key);

  @override
  State<CustomRoutineScreen> createState() => _CustomRoutineScreenState();
}

class _CustomRoutineScreenState extends State<CustomRoutineScreen> {
  int  _step   = 0;
  bool _saving = false;

  // ── Step 1: Name ──────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  String? _nameError;

  // ── Step 2: Icon ──────────────────────────────────────────────────────
  String _selectedEmoji = '📋';

  // ── Step 3: Frequency ─────────────────────────────────────────────────
  String? _frequency;

  // ── Step 4: Time(s) ───────────────────────────────────────────────────
  TimeOfDay? _time1;
  TimeOfDay? _time2;

  // ── Step 5: Custom interval ───────────────────────────────────────────
  int _customDays = 1;

  // ── Step 6: Reminder ─────────────────────────────────────────────────
  bool _reminderEnabled = false;
  int  _reminderMinutes = 30;

  final _db    = DatabaseHelper.instance;
  final _prefs = RoutinePrefs.instance;

  // ── All available emoji options ───────────────────────────────────────
  static const _emojiOptions = [
    '📋', '🐔', '🐣', '🌿', '💉', '🧹', '🔬', '🌡️',
    '🚿', '🌾', '🥩', '🐾', '💊', '🧴', '🪣', '🔧',
    '📦', '🚛', '💡', '⚙️', '🛡️', '🌱', '🌻', '🧺',
  ];

  static const _frequencyKeys = [
    'routine_option_once_daily',
    'routine_option_twice_daily',
    'routine_option_every_2_days',
    'routine_option_weekly',
    'routine_option_custom',
  ];

  // ── Step list ──────────────────────────────────────────────────────────
  List<_CRoutineStep> get _steps {
    final steps = <_CRoutineStep>[
      // 0 — Name
      _CRoutineStep(
        emoji: '✏️',
        titleKey: 'custom_routine_q_name',
        content: _NameInputStep(
          controller: _nameController,
          error: _nameError,
          onChanged: (_) => setState(() => _nameError = null),
        ),
      ),
      // 1 — Icon
      _CRoutineStep(
        emoji: _selectedEmoji,
        titleKey: 'custom_routine_q_icon',
        content: _EmojiPickerStep(
          options:  _emojiOptions,
          selected: _selectedEmoji,
          onSelect: (e) => setState(() => _selectedEmoji = e),
        ),
      ),
      // 2 — Frequency
      _CRoutineStep(
        emoji: '🔄',
        titleKey: 'custom_routine_q_frequency',
        content: _OptionSelector(
          optionKeys: _frequencyKeys,
          selected:   _frequency,
          onSelect:   (v) => setState(() {
            _frequency = v;
            _time2     = null;
          }),
        ),
      ),
      // 3 — Time 1
      _CRoutineStep(
        emoji: '⏰',
        titleKey: _frequency == 'routine_option_twice_daily'.tr()
            ? 'custom_routine_q_time_first'
            : 'custom_routine_q_time',
        content: _TimePickerTile(
          labelKey: _frequency == 'routine_option_twice_daily'.tr()
              ? 'routine_label_morning_collection'
              : 'custom_routine_label_task_time',
          time:     _time1,
          onSelect: (t) => setState(() => _time1 = t),
        ),
      ),
      // 4 — Time 2 (only Twice Daily)
      if (_frequency == 'routine_option_twice_daily'.tr())
        _CRoutineStep(
          emoji: '⏰',
          titleKey: 'custom_routine_q_time_second',
          content: _TimePickerTile(
            labelKey: 'routine_label_evening_collection',
            time:     _time2,
            onSelect: (t) => setState(() => _time2 = t),
          ),
        ),
      // 5 — Custom interval
      if (_frequency == 'routine_option_custom'.tr())
        _CRoutineStep(
          emoji: '📅',
          titleKey: 'routine_q_custom_days',
          content: _NumberStepperTile(
            value:   _customDays,
            min:     1,
            max:     60,
            unitKey: 'routine_unit_days',
            onChanged: (v) => setState(() => _customDays = v),
          ),
        ),
      // Last — Reminder
      _CRoutineStep(
        emoji: '🔔',
        titleKey: 'routine_q_enable_reminders',
        content: _ReminderStep(
          enabled:          _reminderEnabled,
          minutes:          _reminderMinutes,
          onToggle:         (v) => setState(() => _reminderEnabled = v),
          onMinutesChanged: (m) => setState(() => _reminderMinutes = m),
        ),
      ),
    ];
    return steps;
  }

  // ── Navigation ────────────────────────────────────────────────────────
  void _next() {
    // Validate step 0 (name)
    if (_step == 0) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        setState(() => _nameError = 'custom_routine_name_required'.tr());
        return;
      }
    }
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

  // ── Finish ────────────────────────────────────────────────────────────
  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final name    = _nameController.text.trim();
      final now     = DateTime.now();
      final start   = DateTime(now.year, now.month, now.day);
      final baseId  = 'custom_${name.toLowerCase().replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}';
      final t1      = _time1 ?? const TimeOfDay(hour: 8, minute: 0);
      final t2      = _time2 ?? const TimeOfDay(hour: 17, minute: 0);
      final summary = _buildSummary();

      final tasks = _buildTasks(baseId, name, start, t1, t2);

      for (final entry in tasks) {
        await _db.createTask(entry.task, entry.date);
        if (entry.task.enableNotification &&
            entry.task.notificationMinutesBefore != null) {
          await _scheduleNotification(entry.task, entry.date, name);
        }
      }

      // Persist custom routine
      final routineId = 'custom_$baseId';
      await _prefs.saveCustomRoutine(
        id:      routineId,
        name:    name,
        emoji:   _selectedEmoji,
        summary: summary,
      );

      if (!mounted) return;
      setState(() => _saving = false);
      _showSuccess(name, summary, routineId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('routine_save_error'.tr()),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ── Build tasks ───────────────────────────────────────────────────────
  List<_ST> _buildTasks(
      String baseId, String name, DateTime start,
      TimeOfDay t1, TimeOfDay t2) {
    final isTwice   = _frequency == 'routine_option_twice_daily'.tr();
    final interval  = _frequency == 'routine_option_every_2_days'.tr() ? 2
                    : _frequency == 'routine_option_weekly'.tr()        ? 7
                    : _frequency == 'routine_option_custom'.tr()        ? _customDays
                    : 1;

    final pattern = RecurrencePattern(
      type:     RecurrenceType.daily,
      interval: interval,
      endDate:  DateTime.now().add(const Duration(days: 365)),
    );

    final tasks = [
      _ST(
        task: LivestockTask(
          id:          '${baseId}_1',
          title:       name,
          description: 'custom_routine_task_desc'.tr(namedArgs: {'name': name}),
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

    if (isTwice) {
      tasks.add(_ST(
        task: LivestockTask(
          id:          '${baseId}_2',
          title:       '$name (2)',
          description: 'custom_routine_task_desc'.tr(namedArgs: {'name': name}),
          time:        t2,
          taskType:    TaskType.other,
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

  // ── Schedule notification ─────────────────────────────────────────────
  Future<void> _scheduleNotification(
      LivestockTask task, DateTime date, String routineName) async {
    try {
      final taskDt  = DateTime(date.year, date.month, date.day,
          task.time.hour, task.time.minute);
      final notifDt = taskDt.subtract(
          Duration(minutes: task.notificationMinutesBefore!));
      final sec     = ((notifDt.millisecondsSinceEpoch -
              DateTime.now().millisecondsSinceEpoch) /
          1000).round();

      if (sec > 0) {
        final farm = widget.farmName.isNotEmpty
            ? widget.farmName
            : 'routine_notif_your_farm'.tr();
        final minLabel = _minutesLabel(task.notificationMinutesBefore!);

        final title = 'custom_routine_notif_title'.tr(
            namedArgs: {'name': routineName, 'minutes': minLabel});
        final body  = 'custom_routine_notif_body'.tr(namedArgs: {
          'farm':    farm,
          'name':    routineName,
          'minutes': minLabel,
          'time':    task.time.format(context),
        });

        Utils.showNotification(
            Utils.generateNotificationId(task.id), title, body, sec);
      }
    } catch (e) {
      debugPrint('Custom routine notification error: $e');
    }
  }

  String _minutesLabel(int m) {
    if (m < 60) return 'routine_notif_minutes'.tr(namedArgs: {'n': '$m'});
    if (m == 60) return 'routine_notif_1_hour'.tr();
    return 'routine_notif_hours'.tr(namedArgs: {'n': '${m ~/ 60}'});
  }

  String _buildSummary() {
    final freq = _frequency ?? '';
    final t    = _time1 != null ? _time1!.format(context) : '';
    if (freq.isNotEmpty && t.isNotEmpty) return '$freq · $t';
    if (t.isNotEmpty) return t;
    return freq;
  }

  // ── Success dialog ────────────────────────────────────────────────────
  void _showSuccess(String name, String summary, String id) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_selectedEmoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              'custom_routine_success_title'.tr(namedArgs: {'name': name}),
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
                Navigator.pop(context); // close dialog
                Navigator.pop(context,  // return result
                  CustomRoutineResult(
                    id:      id,
                    name:    name,
                    emoji:   _selectedEmoji,
                    summary: summary,
                  ),
                );
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
          ]),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final safe  = _step.clamp(0, steps.length - 1);
    final step  = steps[safe];
    final isLast= safe == steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFE6EBF2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'custom_routine_setup_title'.tr(),
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _ProgressBar(current: safe + 1, total: steps.length),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: _StepCard(
                emoji:   step.emoji,
                titleKey: step.titleKey,
                content: step.content,
              ),
            ),
          ),

          const SizedBox(height: 16),

          _saving
              ? const CircularProgressIndicator(
                  color: Color(0xFF6C63FF))
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
        ]),
      ),
    );
  }
}

// ── Alias for shorter internal use ───────────────────────────────────────────
class _ST {
  final LivestockTask task;
  final DateTime      date;
  const _ST({required this.task, required this.date});
}

class _CRoutineStep {
  final String emoji;
  final String titleKey;
  final Widget content;
  const _CRoutineStep({
    required this.emoji,
    required this.titleKey,
    required this.content,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
//  STEP 1: NAME INPUT
// ═══════════════════════════════════════════════════════════════════════════

class _NameInputStep extends StatelessWidget {
  final TextEditingController controller;
  final String?               error;
  final ValueChanged<String>  onChanged;

  const _NameInputStep({
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3F7),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
                color: Colors.white, offset: Offset(-4, -4), blurRadius: 8),
            BoxShadow(
                color: Colors.black12, offset: Offset(4, 4), blurRadius: 8),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'custom_routine_name_hint'.tr(),
            hintStyle: GoogleFonts.poppins(
                color: Colors.black26, fontSize: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            filled:      true,
            fillColor:   Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            prefixIcon: const Icon(Icons.edit_rounded,
                color: Color(0xFF6C63FF), size: 20),
          ),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.red, size: 14),
          const SizedBox(width: 4),
          Text(error!,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.red)),
        ]),
      ],
      const SizedBox(height: 12),
      Text('custom_routine_name_examples'.tr(),
          style: GoogleFonts.poppins(
              fontSize: 11, color: Colors.black38)),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STEP 2: EMOJI PICKER
// ═══════════════════════════════════════════════════════════════════════════

class _EmojiPickerStep extends StatelessWidget {
  final List<String>     options;
  final String           selected;
  final ValueChanged<String> onSelect;

  const _EmojiPickerStep({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('custom_routine_icon_subtitle'.tr(),
          style: GoogleFonts.poppins(
              fontSize: 12, color: Colors.black45)),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing:  10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemBuilder: (_, i) {
          final emoji = options[i];
          final isSel = selected == emoji;
          return GestureDetector(
            onTap: () => onSelect(emoji),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSel
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFFF0F3F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSel
                      ? const Color(0xFF6C63FF)
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSel
                    ? const [
                        BoxShadow(
                            color: Color(0x336C63FF),
                            blurRadius: 8,
                            offset: Offset(0, 3)),
                      ]
                    : const [
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
                child: Text(emoji,
                    style: TextStyle(
                        fontSize: isSel ? 22 : 20)),
              ),
            ),
          );
        },
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS (re-exported from guided_routine_screen pattern)
//  Keeping them in this file avoids import cycles — identical design.
// ═══════════════════════════════════════════════════════════════════════════

class _StepCard extends StatelessWidget {
  final String emoji, titleKey;
  final Widget content;
  const _StepCard({
    required this.emoji,
    required this.titleKey,
    required this.content,
  });

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(titleKey.tr(),
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 16),
        content,
      ]),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int current, total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          'routine_step_of'
              .tr(namedArgs: {'current': '$current', 'total': '$total'}),
          style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500),
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
          value:           current / total,
          minHeight:       6,
          backgroundColor: Colors.black12,
          valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFF6C63FF)),
        ),
      ),
    ]);
  }
}

class _OptionSelector extends StatelessWidget {
  final List<String>     optionKeys;
  final String?          selected;
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
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isSel ? const Color(0xFF6C63FF) : const Color(0xFFF0F3F7),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSel
                  ? const [
                      BoxShadow(color: Colors.black12, offset: Offset(3, 3), blurRadius: 6),
                      BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
                    ]
                  : const [
                      BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
                      BoxShadow(color: Colors.black12, offset: Offset(5, 5), blurRadius: 10),
                    ],
            ),
            child: Row(children: [
              Expanded(
                child: Text(label,
                    style: GoogleFonts.poppins(
                        color: isSel ? Colors.white : Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
              Icon(
                isSel ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSel ? Colors.white : Colors.grey,
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

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
    final sel = time != null;
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF6C63FF).withOpacity(0.08) : const Color(0xFFF0F3F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: sel ? const Color(0xFF6C63FF).withOpacity(0.45) : Colors.transparent),
          boxShadow: const [
            BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
            BoxShadow(color: Colors.black12, offset: Offset(5, 5), blurRadius: 10),
          ],
        ),
        child: Row(children: [
          Icon(Icons.access_time_rounded,
              color: sel ? const Color(0xFF6C63FF) : Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(labelKey.tr(),
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45)),
              Text(
                sel ? time!.format(context) : 'routine_time_tap_hint'.tr(),
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: sel ? const Color(0xFF6C63FF) : Colors.black87),
              ),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.black26),
        ]),
      ),
    );
  }
}

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
          BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
          BoxShadow(color: Colors.black12, offset: Offset(5, 5), blurRadius: 10),
        ],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _StepBtn(icon: Icons.remove_rounded,
            onTap: value > min ? () => onChanged(value - 1) : null),
        const SizedBox(width: 28),
        Column(children: [
          Text('$value',
              style: GoogleFonts.poppins(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6C63FF))),
          Text(unitKey.tr(),
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black45)),
        ]),
        const SizedBox(width: 28),
        _StepBtn(icon: Icons.add_rounded,
            onTap: value < max ? () => onChanged(value + 1) : null),
      ]),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
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
          boxShadow: on ? const [BoxShadow(
              color: Colors.black12, offset: Offset(2, 2), blurRadius: 6)] : [],
        ),
        child: Icon(icon, color: on ? Colors.white : Colors.grey, size: 22),
      ),
    );
  }
}

class _ReminderStep extends StatelessWidget {
  final bool enabled;
  final int  minutes;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int>  onMinutesChanged;

  const _ReminderStep({
    required this.enabled,
    required this.minutes,
    required this.onToggle,
    required this.onMinutesChanged,
  });

  static const _opts = [5, 10, 15, 30, 60, 120];

  String _chip(int m, BuildContext ctx) {
    if (m < 60) return 'routine_notif_chip_min'.tr(namedArgs: {'n': '$m'});
    if (m == 60) return 'routine_notif_chip_1h'.tr();
    return 'routine_notif_chip_hours'.tr(namedArgs: {'n': '${m ~/ 60}'});
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: _ToggleChip(
            label:    'routine_option_yes_remind'.tr(),
            selected: enabled,
            color:    const Color(0xFF6C63FF),
            onTap:    () => onToggle(true),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToggleChip(
            label:    'routine_option_no_thanks'.tr(),
            selected: !enabled,
            color:    Colors.grey,
            onTap:    () => onToggle(false),
          ),
        ),
      ]),
      if (enabled) ...[
        const SizedBox(height: 16),
        Text('routine_reminder_how_early'.tr(),
            style: GoogleFonts.poppins(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _opts.map((m) {
            final sel = minutes == m;
            return GestureDetector(
              onTap: () => onMinutesChanged(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF6C63FF) : const Color(0xFFF0F3F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel ? const Color(0xFF6C63FF) : Colors.black12),
                ),
                child: Text(_chip(m, context),
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
          border: Border.all(color: selected ? color : Colors.black12),
          boxShadow: const [
            BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
            BoxShadow(color: Colors.black12, offset: Offset(3, 3), blurRadius: 6),
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
