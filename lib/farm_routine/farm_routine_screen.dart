import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

import '../database/databse_helper.dart';
import '../model/farm_item.dart';
import 'guided_routine_screen.dart';
import 'custom_routine_screen.dart';
import 'routine_prefs.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  FARM ROUTINE SCREEN  (with custom routines)
// ═══════════════════════════════════════════════════════════════════════════

class FarmRoutineScreen extends StatefulWidget {
  final String farmName;
  const FarmRoutineScreen({Key? key, this.farmName = ''}) : super(key: key);


  @override
  State<FarmRoutineScreen> createState() => _FarmRoutineScreenState();
}

class _FarmRoutineScreenState extends State<FarmRoutineScreen> {
  static const _builtInOrder = ['Egg', 'Feed', 'Health'];
  final _prefs = RoutinePrefs.instance;

  Map<String, bool>    _statuses       = {for (final t in _builtInOrder) t: false};
  Map<String, String?> _summaries      = {for (final t in _builtInOrder) t: null};
  List<CustomRoutineEntry> _customs    = [];
  bool _loading                        = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  FarmSetup? farmSetup;
  Future<void> _loadAll() async {
    final statuses  = await _prefs.loadAllStatuses(_builtInOrder);
    final summaries = await _prefs.loadAllSummaries(_builtInOrder);
    final customs   = await _prefs.loadCustomRoutines();

    List<FarmSetup> list = await DatabaseHelper.getFarmInfo();
    farmSetup = list.elementAt(0);

    if (mounted) {
      setState(() {
        _statuses  = statuses;
        _summaries = summaries;
        _customs   = customs;
        _loading   = false;
      });
    }
  }

  int get _completedBuiltIn =>
      _statuses.values.where((v) => v).length;
  int get _totalConfigured  =>
      _completedBuiltIn + _customs.length;
  bool get _allBuiltInDone  =>
      _completedBuiltIn == _builtInOrder.length;

  // ── Open built-in routine ─────────────────────────────────────────────
  Future<void> _openBuiltIn(String type) async {
    final result = await Navigator.of(context)
        .push<String>(_slideRoute(GuidedRoutineScreen(
      routineType: type,
      farmName:  farmSetup == null? "Dear Farm User" : farmSetup!.name,
    )));
    if (result != null && mounted) {
      final summaries = await _prefs.loadAllSummaries(_builtInOrder);
      setState(() {
        _statuses[result] = true;
        _summaries        = summaries;
      });
    }
  }

  // ── Open custom routine setup ─────────────────────────────────────────
  Future<void> _openCustomSetup() async {
    final result = await Navigator.of(context)
        .push<CustomRoutineResult>(_slideRoute(CustomRoutineScreen(
      farmName:  farmSetup == null? "Dear Farm User" : farmSetup!.name,
    )));
    if (result != null && mounted) {
      final customs = await _prefs.loadCustomRoutines();
      setState(() => _customs = customs);
    }
  }

  // ── Reset built-in routine ────────────────────────────────────────────
  Future<void> _resetBuiltIn(String type) async {
    final ok = await _confirmDialog(
      title:   'routine_reset_title'.tr(),
      body:    'routine_reset_body'.tr(namedArgs: {'type': type}),
      confirm: 'routine_reset_confirm'.tr(),
    );
    if (ok && mounted) {
      await _prefs.clearRoutine(type);
      setState(() {
        _statuses[type]  = false;
        _summaries[type] = null;
      });
    }
  }

  // ── Delete custom routine ─────────────────────────────────────────────
  Future<void> _deleteCustom(CustomRoutineEntry entry) async {
    final ok = await _confirmDialog(
      title:   'custom_routine_delete_title'.tr(),
      body:    'custom_routine_delete_body'.tr(
          namedArgs: {'name': entry.name}),
      confirm: 'custom_routine_delete_confirm'.tr(),
    );
    if (ok && mounted) {
      await _prefs.deleteCustomRoutine(entry.id);
      final customs = await _prefs.loadCustomRoutines();
      setState(() => _customs = customs);
    }
  }

  // ── Slide route helper ────────────────────────────────────────────────
  PageRoute<T> _slideRoute<T>(Widget page) => PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end:   Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut)).animate(anim),
          child: child,
        ),
      );

  // ── Confirm dialog helper ─────────────────────────────────────────────
  Future<bool> _confirmDialog({
    required String title,
    required String body,
    required String confirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:   Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('routine_reset_cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirm,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6EBF2),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation:       0,
        title: Text(
          'routine_screen_title'.tr(),
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // ── Assistant card ─────────────────────────────────
                _AssistantCard(
                  allDone:  _allBuiltInDone,
                  farmName:  farmSetup == null? "Dear Farm User" : farmSetup!.name,
                  onYes:    _showRoutinePicker,
                  onSkip:   () => Navigator.maybePop(context),
                ),
                const SizedBox(height: 14),

                // ── Progress pill ──────────────────────────────────
                if (_totalConfigured > 0) ...[
                  _ProgressPill(
                    completed: _totalConfigured,
                    total:     _builtInOrder.length + _customs.length,
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Scrollable content ────────────────────────────
                Expanded(
                  child: ListView(children: [
                    // Built-in routine cards
                    ..._builtInOrder.map((key) => RoutineCard(
                          routineName: key,
                          isCompleted: _statuses[key] ?? false,
                          summary:     _summaries[key],
                          onTap:       () => _openBuiltIn(key),
                          onLongPress: (_statuses[key] ?? false)
                              ? () => _resetBuiltIn(key)
                              : null,
                        )),

                    const SizedBox(height: 6),

                    // ── Section divider ──────────────────────────
                    _SectionDivider(
                      labelKey: 'custom_routine_section_label',
                    ),
                    const SizedBox(height: 10),

                    // Custom routine cards
                    ..._customs.map((entry) => _CustomRoutineCard(
                          entry:      entry,
                          onTap:      () => _openCustomSetup(),
                          onDelete:   () => _deleteCustom(entry),
                        )),

                    // ── Add custom routine button ─────────────────
                    _AddCustomButton(onTap: _openCustomSetup),
                    const SizedBox(height: 16),
                  ]),
                ),
              ]),
            ),
    );
  }

  // ── Bottom sheet routine picker ───────────────────────────────────────
  void _showRoutinePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Text('routine_picker_title'.tr(),
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._builtInOrder.map((type) {
            final done = _statuses[type] ?? false;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: CircleAvatar(
                backgroundColor: _routineColor(type).withOpacity(0.12),
                child: Text(_routineEmoji(type),
                    style: const TextStyle(fontSize: 18)),
              ),
              title: Text(
                'routine_card_label'.tr(namedArgs: {'type': type}),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              subtitle: done && _summaries[type] != null
                  ? Text(_summaries[type]!,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.green.shade700))
                  : null,
              trailing: done
                  ? const Icon(Icons.check_circle_rounded,
                      color: Colors.green)
                  : const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: Colors.grey),
              onTap: () {
                Navigator.pop(ctx);
                _openBuiltIn(type);
              },
            );
          }),
          const Divider(height: 24),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.12),
              child: const Icon(Icons.add_rounded,
                  color: Color(0xFF6C63FF)),
            ),
            title: Text(
              'custom_routine_add_label'.tr(),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'custom_routine_add_subtitle'.tr(),
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.black45),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey),
            onTap: () {
              Navigator.pop(ctx);
              _openCustomSetup();
            },
          ),
        ]),
      ),
    );
  }

  String _routineEmoji(String r) =>
      {'Egg': '🥚', 'Feed': '🌾', 'Health': '💊', 'Finance': '💰'}[r] ?? '📋';

  Color _routineColor(String r) => switch (r) {
        'Egg'     => const Color(0xFFF59E0B),
        'Feed'    => const Color(0xFF22C55E),
        'Health'  => const Color(0xFF8B5CF6),
        'Finance' => const Color(0xFF3B82F6),
        _         => const Color(0xFF6C63FF),
      };
}

// ═══════════════════════════════════════════════════════════════════════════
//  CUSTOM ROUTINE CARD
// ═══════════════════════════════════════════════════════════════════════════

class _CustomRoutineCard extends StatelessWidget {
  final CustomRoutineEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CustomRoutineCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
          BoxShadow(
              color: Colors.black12, offset: Offset(5, 5), blurRadius: 10),
        ],
      ),
      child: Row(children: [
        // Emoji icon
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(entry.emoji,
                style: const TextStyle(fontSize: 26)),
          ),
        ),
        const SizedBox(width: 14),

        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.name,
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
              const SizedBox(height: 3),
              Text(entry.summary,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.green.shade700)),
              Text('custom_routine_card_hint'.tr(),
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: Colors.black26)),
            ],
          ),
        ),

        // Delete button
        GestureDetector(
          onTap: onDelete,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.red, size: 18),
          ),
        ),

        const SizedBox(width: 6),

        // Active indicator
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 22),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ADD CUSTOM BUTTON
// ═══════════════════════════════════════════════════════════════════════════

class _AddCustomButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCustomButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.35),
            width: 1.5,
            // dashed look via BoxBorder isn't built-in — solid thin border works fine
          ),
          boxShadow: const [
            BoxShadow(
                color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
            BoxShadow(
                color: Colors.black12, offset: Offset(5, 5), blurRadius: 10),
          ],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add_rounded,
                color: Color(0xFF6C63FF), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'custom_routine_add_label'.tr(),
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6C63FF)),
                ),
                const SizedBox(height: 3),
                Text(
                  'custom_routine_add_subtitle'.tr(),
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Color(0xFF6C63FF)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SECTION DIVIDER
// ═══════════════════════════════════════════════════════════════════════════

class _SectionDivider extends StatelessWidget {
  final String labelKey;
  const _SectionDivider({required this.labelKey});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider(thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          labelKey.tr(),
          style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black38),
        ),
      ),
      const Expanded(child: Divider(thickness: 1)),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ASSISTANT CARD
// ═══════════════════════════════════════════════════════════════════════════

class _AssistantCard extends StatelessWidget {
  final bool allDone;
  final String farmName;
  final VoidCallback onYes, onSkip;

  const _AssistantCard({
    required this.allDone,
    required this.farmName,
    required this.onYes,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
          BoxShadow(color: Colors.black12, offset: Offset(5, 5), blurRadius: 10),
        ],
      ),
      child: allDone ? _allDoneContent() : _setupContent(context),
    );
  }

  Widget _setupContent(BuildContext context) {
    final name = farmName.isNotEmpty ? farmName : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        name != null
            ? 'routine_assistant_greeting_named'.tr(namedArgs: {'farm': name})
            : 'routine_assistant_greeting'.tr(),
        style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      Text('routine_assistant_subtitle'.tr(),
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onYes,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('routine_assistant_yes'.tr(),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: onSkip,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF6C63FF), width: 2),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('routine_assistant_skip'.tr(),
                style: GoogleFonts.poppins(
                    color: const Color(0xFF6C63FF),
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    ]);
  }

  Widget _allDoneContent() {
    return Row(children: [
      const Text('🎉', style: TextStyle(fontSize: 36)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('routine_all_done_title'.tr(),
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          Text('routine_all_done_subtitle'.tr(),
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54)),
        ]),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  PROGRESS PILL
// ═══════════════════════════════════════════════════════════════════════════

class _ProgressPill extends StatelessWidget {
  final int completed, total;
  const _ProgressPill({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded,
            color: Color(0xFF6C63FF), size: 17),
        const SizedBox(width: 8),
        Text(
          'routine_progress_label'.tr(namedArgs: {
            'completed': '$completed',
            'total':     '$total',
          }),
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6C63FF)),
        ),
        const Spacer(),
        SizedBox(
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           completed / total,
              minHeight:       5,
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6C63FF)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  BUILT-IN ROUTINE CARD  (unchanged design)
// ═══════════════════════════════════════════════════════════════════════════

class RoutineCard extends StatelessWidget {
  final String  routineName;
  final bool    isCompleted;
  final String? summary;
  final VoidCallback  onTap;
  final VoidCallback? onLongPress;

  const RoutineCard({
    Key? key,
    required this.routineName,
    required this.isCompleted,
    required this.onTap,
    this.summary,
    this.onLongPress,
  }) : super(key: key);

  String get _emoji =>
      {'Egg': '🥚', 'Feed': '🌾', 'Health': '💊', 'Finance': '💰'}[routineName] ?? '📋';

  Color get _color => switch (routineName) {
        'Egg'     => const Color(0xFFF59E0B),
        'Feed'    => const Color(0xFF22C55E),
        'Health'  => const Color(0xFF8B5CF6),
        'Finance' => const Color(0xFF3B82F6),
        _         => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return GestureDetector(
      onTap:      onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3F7),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
                color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
            BoxShadow(
                color: Colors.black12, offset: Offset(5, 5), blurRadius: 10),
          ],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(_emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'routine_card_label'.tr(namedArgs: {'type': routineName}),
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
              const SizedBox(height: 3),
              Text(
                isCompleted
                    ? (summary ?? 'routine_card_configured'.tr())
                    : 'routine_card_not_configured'.tr(),
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isCompleted
                        ? Colors.green.shade700
                        : Colors.black45),
              ),
              if (isCompleted && onLongPress != null)
                Text('routine_card_long_press_hint'.tr(),
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.black26)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: isCompleted ? Colors.green : Colors.grey,
              size:  isCompleted ? 22 : 15,
            ),
          ),
        ]),
      ),
    );
  }
}
