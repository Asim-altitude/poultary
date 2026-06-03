import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

import '../../model/flock.dart';
import '../../utils/fb_analytics.dart';
import '../../utils/ui/flock_ui_list.dart';
import '../model/ai_response.dart';
import 'ai_ask_details_screen.dart';
import 'ai_finance_analysis.dart';
import 'ai_health_analysis.dart';

class AskAIScreen extends StatefulWidget {
  @override
  _AskAIScreenState createState() => _AskAIScreenState();
}

class _AskAIScreenState extends State<AskAIScreen> with TickerProviderStateMixin {
  List<Flock> flocks = [];

  void init() async {
    await DatabaseHelper.instance.database;
    flocks = await DatabaseHelper.getFlocks();
    _purposeselectedValue = flocks[0].f_name;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    init();
    AnalyticsUtil.logScreenView(screenName: "ask_ai_screen");
    _stepController = AnimationController(vsync: this, duration: Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _stepController, curve: Curves.easeOut);
    _stepController.forward();
  }

  @override
  void dispose() {
    _stepController.dispose();
    super.dispose();
  }

  late AnimationController _stepController;
  late Animation<double> _fadeAnim;

  int step = 1;
  String? selectedType;
  String? duration;
  bool isLoading = false;
  String? aiResponse;

  Future<void> _generateAI() async {
    setState(() => isLoading = true);
    await Future.delayed(Duration(seconds: 2));
    String response = "• Increase protein intake\n• Maintain clean water\n• Monitor bird weight weekly";
    await DatabaseHelper.insertResponse(
      AIResponse(
        flockId: "1",
        category: selectedType!,
        title: selectedType!,
        response: response,
        creditsUsed: 1,
        createdAt: DateTime.now(),
        birdCount: 500,
        ageWeeks: 18,
      ),
    );
    setState(() {
      aiResponse = response;
      isLoading = false;
      step = 3;
    });
  }

  void _goToStep(int newStep) {
    _stepController.reset();
    setState(() => step = newStep);
    _stepController.forward();
  }

  // ─── THEME COLORS ───────────────────────────────────────
  static const Color _bg = Color(0xFFF7F9FC);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _accent = Color(0xFF0062FF);
  static const Color _accentDim = Color(0xFF004FCC);
  static const Color _accentGlow = Color(0x150062FF);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _buildStep(),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _surface,
      foregroundColor: _textPrimary,
      centerTitle: true,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_accent, _accentDim]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          ),
          SizedBox(width: 8),
          Text(
            "Ask AI".tr(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontSize: 18,
              color: _textPrimary,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          _stepDot(1, "Flock & Type"),
          _stepLine(step > 1),
          _stepDot(2, "Duration"),
          /*_stepLine(step > 2),
          _stepDot(3, "Result"),*/
        ],
      ),
    );
  }

  Widget _stepDot(int s, String label) {
    bool active = step == s;
    bool done = step > s;
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? _accent : (active ? _accentGlow : Colors.transparent),
              border: Border.all(
                color: done || active ? _accent : _border,
                width: 2,
              ),
              boxShadow: active
                  ? [BoxShadow(color: _accent.withOpacity(0.35), blurRadius: 10)]
                  : [],
            ),
            child: Center(
              child: done
                  ? Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                "$s",
                style: TextStyle(
                  color: active ? _accent : _textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active ? _accent : _textSecondary,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepLine(bool filled) {
    return Container(
      width: 32,
      height: 2,
      margin: EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: filled
            ? LinearGradient(colors: [_accent, _accentDim])
            : null,
        color: filled ? null : _border,
      ),
    );
  }

  Widget _buildStep() {
    if (step == 1) return _stepType();
    if (step == 2) return _stepDuration();
    return _resultView();
  }

  // ================= STEP 1 =================

  Widget _stepType() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel("Select Flock", Icons.grid_view_rounded),
          SizedBox(height: 12),
          FlockHorizontalList(
            flocks: flocks,
            selectedFlockId: _purposeselectedValue,
            onSelect: (flock) => setState(() => _purposeselectedValue = flock.f_name),
          ),
          SizedBox(height: 24),
          _sectionLabel("Select Analysis Type", Icons.analytics_outlined),
          SizedBox(height: 12),
          _typeCard("Feed Suggestion", "feed", Icons.restaurant_menu_rounded,
              "Get optimized feeding recommendations", Color(0xFFFF9F43)),
          _typeCard("Health Advice", "health", Icons.health_and_safety_rounded,
              "Diagnose & prevent flock illnesses", Color(0xFF00CEC9)),
          _typeCard("Financial Analysis", "financial", Icons.bar_chart_rounded,
              "Profit insights & cost breakdowns", Color(0xFF6C5CE7)),
          SizedBox(height: 28),
          _nextButton(
            enabled: selectedType != null,
            onTap: () => _goToStep(2),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _accent),
        SizedBox(width: 6),
        Text(
          text.tr(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _typeCard(String title, String value, IconData icon, String subtitle, Color accent) {
    bool selected = selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => selectedType = value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 220),
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? accent.withOpacity(0.07) : _card,
          border: Border.all(
            color: selected ? accent : _border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: accent.withOpacity(0.12), blurRadius: 16, offset: Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 220),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: selected ? accent.withOpacity(0.15) : Color(0xFFF3F4F6),
                border: Border.all(color: selected ? accent.withOpacity(0.4) : _border),
              ),
              child: Icon(icon, color: selected ? accent : _textSecondary, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.tr(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? _textPrimary : _textPrimary.withOpacity(0.85),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    subtitle.tr(),
                    style: TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 220),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : Colors.transparent,
                border: Border.all(color: selected ? accent : _border, width: 2),
              ),
              child: selected
                  ? Icon(Icons.check, size: 13, color: Colors.white)
                  : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STEP 2 =================

  List<String> filterList = [
    'THIS_MONTH', 'LAST_MONTH', 'LAST3_MONTHS',
    'LAST6_MONTHS', 'THIS_YEAR', 'LAST_YEAR', 'ALL_TIME'
  ];

  String _purposeselectedValue = "Farm Wide";

  Widget _stepDuration() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel("Select Duration", Icons.calendar_today_rounded),
          SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: filterList.map((item) => _durationChip(item)).toList(),
          ),
          Spacer(),
          _nextButton(
            enabled: duration != null,
            onTap: () async {
              if(selectedType!.toLowerCase().toString() == "health"){
                Flock? flock = await getFlock();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        HealthAnalysisScreen(duration: duration!,flockId: getFlockID(), flockName: flock!.f_name, birdType: flock.purpose.toLowerCase() == "meat"? "broiler":"layer", breed: "", ageDays: Utils.getAgeIndays(flock.acqusition_date), totalBirds: flock.bird_count!, currentBirds: flock.active_bird_count!),

                  ),
                );
              }
              else if (selectedType!.toLowerCase().toString() == "feed") {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AskAIDetailsScreen(
                          f_id: getFlockID(),
                          duration: duration!,
                          anlaysis_type: selectedType!,
                        ),
                  ),
                );
              }else if (selectedType!.toLowerCase().toString() == "financial") {
                Flock? flock = await getFlock();

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FinancialAnalysisScreen(duration: duration!,flockId: getFlockID(), flockName: flock!.f_name, birdType: flock.purpose.toLowerCase() == "meat"? "broiler":"layer", ageDays: Utils.getAgeIndays(flock.acqusition_date),  currentBirds: flock.active_bird_count!, initialBirds: flock.bird_count!,),
                  ),
                );
              }
            },
            label: "Analyze with AI".tr(),
            icon: Icons.auto_awesome,
          ),
        ],
      ),
    );
  }

  Future<Flock?> getFlock() async  {
    Flock? flock;
    for (int i = 0; i < flocks.length; i++) {
      if (_purposeselectedValue == flocks.elementAt(i).f_name) {
        flock = flocks.elementAt(i);
        break;
      }
    }
    return flock;
  }

  int getFlockID() {
    int selected_id = -1;
    for (int i = 0; i < flocks.length; i++) {
      if (_purposeselectedValue == flocks.elementAt(i).f_name) {
        selected_id = flocks.elementAt(i).f_id;
        break;
      }
    }
    return selected_id;
  }

  Widget _durationChip(String label) {
    bool selected = duration == label;
    return GestureDetector(
      onTap: () => setState(() => duration = label),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? _accent.withOpacity(0.08) : _card,
          border: Border.all(
            color: selected ? _accent : _border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: _accent.withOpacity(0.12), blurRadius: 8, offset: Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_circle_rounded, size: 14, color: _accent),
              SizedBox(width: 6),
            ],
            Text(
              label.tr(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? _accent : _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STEP 3 =================

  Widget _resultView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        children: [
          // Header badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _accentGlow,
              border: Border.all(color: _accent.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: _accent),
                SizedBox(width: 6),
                Text(
                  "AI Result".tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          Expanded(
            child: isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: _accent,
                      strokeWidth: 3,
                      backgroundColor: _accentGlow,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text("Analyzing your flock...".tr(),
                      style: TextStyle(color: _textSecondary, fontSize: 14)),
                ],
              ),
            )
                : Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _card,
                border: Border.all(color: _border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: SingleChildScrollView(
                child: Text(
                  aiResponse ?? "",
                  style: TextStyle(
                    fontSize: 15,
                    color: _textPrimary,
                    height: 1.7,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _outlineActionButton(
                  icon: Icons.copy_rounded,
                  label: "Copy",
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: aiResponse ?? ""));
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _filledActionButton(
                  icon: Icons.share_rounded,
                  label: "Share",
                  onPressed: () => Share.share(aiResponse ?? ""),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              setState(() {
                step = 1;
                selectedType = null;
                duration = null;
                aiResponse = null;
              });
              _stepController.reset();
              _stepController.forward();
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, size: 16, color: _textSecondary),
                  SizedBox(width: 6),
                  Text(
                    "Ask Again".tr(),
                    style: TextStyle(
                      color: _textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= COMMON =================

  Widget _nextButton({
    required bool enabled,
    required VoidCallback onTap,
    String label = "Next",
    IconData? icon,
  }) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: enabled
                ? LinearGradient(
              colors: [_accent, _accentDim],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: enabled ? null : Color(0xFFF3F4F6),
            border: Border.all(color: enabled ? Colors.transparent : _border),
            boxShadow: enabled
                ? [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 6))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                SizedBox(width: 8),
              ],
              Text(
                label.tr(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: enabled ? Colors.white : _textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              if (icon == null) ...[
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _outlineActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Color(0xFFF9FAFB),
          border: Border.all(color: _border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: _textSecondary),
            SizedBox(width: 7),
            Text(label.tr(),
                style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _filledActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _accentGlow,
          border: Border.all(color: _accent.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: _accent),
            SizedBox(width: 7),
            Text(label.tr(),
                style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}