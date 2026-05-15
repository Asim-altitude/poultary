import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_picker/languages.dart' as lang_picker;
import 'package:googleapis/dfareporting/v4.dart' as dfareporting;
import 'package:poultary/utils/utils.dart';

import '../../database/databse_helper.dart';
import '../model/ai_response.dart';
import '../network_api.dart';

// ─────────────────────────────────────────────────────────────
//  HealthAnalysisScreen
//  Collects all health inputs from JSON schema and navigates
//  to the AI details screen with the assembled payload.
// ─────────────────────────────────────────────────────────────
class HealthAnalysisScreen extends StatefulWidget {
  final int flockId;
  final String flockName;
  final String birdType;
  final String breed;
  final int ageDays;
  final int totalBirds;
  final int currentBirds;
  final String duration;

  const HealthAnalysisScreen({
    Key? key,
    required this.flockId,
    required this.flockName,
    required this.birdType,
    required this.breed,
    required this.ageDays,
    required this.totalBirds,
    required this.currentBirds,
    required this.duration
  }) : super(key: key);

  @override
  State<HealthAnalysisScreen> createState() => _HealthAnalysisScreenState();
}

class _HealthAnalysisScreenState extends State<HealthAnalysisScreen>
    with TickerProviderStateMixin {
  // ── step control ─────────────────────────────────────────
  int _step = 0; // 0=Symptoms 1=Feed&Water 2=Environment 3=Mortality
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // ── THEME ─────────────────────────────────────────────────
  static const Color _bg       = Color(0xFFF7F9FC);
  static const Color _white    = Color(0xFFFFFFFF);
  static const Color _accent   = Color(0xFF0062FF);
  static const Color _accentLt = Color(0xFFEEF3FF);
  static const Color _danger   = Color(0xFFEF4444);
  static const Color _dangerLt = Color(0xFFFEF2F2);
  static const Color _warn     = Color(0xFFF59E0B);
  static const Color _warnLt   = Color(0xFFFFFBEB);
  static const Color _green    = Color(0xFF10B981);
  static const Color _greenLt  = Color(0xFFECFDF5);
  static const Color _txt1     = Color(0xFF111827);
  static const Color _txt2     = Color(0xFF6B7280);
  static const Color _border   = Color(0xFFE5E7EB);
  static const Color _fieldBg  = Color(0xFFF9FAFB);

  // ── Symptoms ──────────────────────────────────────────────
  bool _coughing      = false;
  bool _sneezing      = false;
  bool _diarrhea      = false;
  bool _weakness      = false;
  bool _lowFeed       = false;
  final _otherCtrl    = TextEditingController();

  // ── Feed & Water ──────────────────────────────────────────
  final _feedTodayCtrl   = TextEditingController();
  final _feedAvgCtrl     = TextEditingController();
  final _waterTodayCtrl  = TextEditingController();
  final _waterAvgCtrl    = TextEditingController();

  // ── Environment ───────────────────────────────────────────
  final _tempCtrl        = TextEditingController();
  final _humidityCtrl    = TextEditingController();
  String _ventilation    = 'Medium';
  String _litterCond     = 'Normal';
  bool _ammoniaSmell     = false;

  // ── Mortality (last 2 days) ───────────────────────────────
  final _dead1Ctrl = TextEditingController();
  final _dead2Ctrl = TextEditingController();

  final List<String> _ventOptions   = ['Low', 'Medium', 'High'];
  final List<String> _litterOptions = ['Dry', 'Normal', 'Wet', 'Very Wet'];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _otherCtrl.dispose();
    _feedTodayCtrl.dispose(); _feedAvgCtrl.dispose();
    _waterTodayCtrl.dispose(); _waterAvgCtrl.dispose();
    _tempCtrl.dispose(); _humidityCtrl.dispose();
    _dead1Ctrl.dispose(); _dead2Ctrl.dispose();
    super.dispose();
  }

  void _animateTo(int newStep) {
    _fadeCtrl.reset();
    setState(() => _step = newStep);
    _fadeCtrl.forward();
  }

  // ── steps meta ────────────────────────────────────────────
  final List<Map<String, dynamic>> _steps = [
    {'label': 'Symptoms',    'icon': Icons.sick_rounded},
    {'label': 'Feed & Water','icon': Icons.water_drop_rounded},
    {'label': 'Environment', 'icon': Icons.thermostat_rounded},
    {'label': 'Mortality',   'icon': Icons.monitor_heart_rounded},
  ];

  bool get _canProceed {
    switch (_step) {
      case 0: return true; // symptoms: optional checkboxes
      case 1: return _feedTodayCtrl.text.isNotEmpty && _waterTodayCtrl.text.isNotEmpty;
      case 2: return _tempCtrl.text.isNotEmpty && _humidityCtrl.text.isNotEmpty;
      case 3: return true;
      default: return false;
    }
  }

  Map<String, dynamic> _buildPayload(String lang, String token) => {
    "analysis_type": "health",
    "firebase_token": token,
    "language" : lang,
    "flock": {
      "flock_name": widget.flockName,
      "bird_type": widget.birdType,
      "age_days": widget.ageDays,
      "total_birds": widget.totalBirds,
      "current_birds": widget.currentBirds,
      "breed": widget.breed,
    },
    "mortality": [
      {"date": _dayLabel(1), "dead_birds": int.tryParse(_dead1Ctrl.text) ?? 0},
      {"date": _dayLabel(0), "dead_birds": int.tryParse(_dead2Ctrl.text) ?? 0},
    ],
    "symptoms": {
      "coughing": _coughing,
      "sneezing": _sneezing,
      "diarrhea": _diarrhea,
      "weakness": _weakness,
      "low_feed_intake": _lowFeed,
      "other": _otherCtrl.text.trim(),
    },
    "feed_water": {
      "feed_intake_today_kg": double.tryParse(_feedTodayCtrl.text) ?? 0,
      "average_feed_last_7_days_kg": double.tryParse(_feedAvgCtrl.text) ?? 0,
      "water_intake_today_liters": double.tryParse(_waterTodayCtrl.text) ?? 0,
      "average_water_last_7_days_liters": double.tryParse(_waterAvgCtrl.text) ?? 0,
    },
    "environment": {
      "temperature_c": double.tryParse(_tempCtrl.text) ?? 0,
      "humidity_percent": double.tryParse(_humidityCtrl.text) ?? 0,
      "ventilation": _ventilation,
      "litter_condition": _litterCond,
      "ammonia_smell": _ammoniaSmell,
    },
  };



  String _dayLabel(int daysAgo) {
    final d = DateTime.now().subtract(Duration(days: daysAgo));
    return "${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";
  }

  bool isLoading = false;
  String? aiResponse = null;

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(),
      body:  Column(
        children: [
          _flockBanner(),
          _stepBar(),
          if (aiResponse == null && !isLoading)...[
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  child: _buildStepContent(),
                ),
              ),
            ),
          ],

          if (isLoading) _loadingWidget(),

          if (aiResponse != null) _responseCard(),

        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _loadingWidget() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff3D2DB5), Color(0xff6A5AE0)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff6A5AE0).withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "AI is analyzing your flock...",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xff1A1F36),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Generating smart feed and health recommendations",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const LinearProgressIndicator(
              minHeight: 5,
              backgroundColor: Color(0xffEEEEF5),
              valueColor: AlwaysStoppedAnimation(Color(0xff6A5AE0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _responseCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff3D2DB5), Color(0xff6A5AE0)],
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  "AI Analysis Result",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(
              aiResponse ?? "",
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xff2D3352),
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ── APP BAR ───────────────────────────────────────────────
  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: _white,
    foregroundColor: _txt1,
    centerTitle: true,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.health_and_safety_rounded, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        const Text("Health Analysis",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: 0.3)),
      ],
    ),

  );

  // ── FLOCK BANNER ─────────────────────────────────────────
  Widget _flockBanner() => Container(
    color: _white,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
    child: Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _accentLt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.egg_alt_rounded, color: _accent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.flockName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _txt1)),
              const SizedBox(height: 2),
              Text("${widget.birdType} · ${widget.breed} · ${widget.ageDays} days old",
                  style: const TextStyle(fontSize: 12, color: _txt2)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _pillBadge("${widget.currentBirds}", Icons.sunny_snowing, _accent, _accentLt),
            const SizedBox(height: 4),
            Text("of ${widget.totalBirds} birds",
                style: const TextStyle(fontSize: 11, color: _txt2)),
          ],
        ),
      ],
    ),
  );

  Widget _pillBadge(String text, IconData icon, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: fg),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    ]),
  );

  // ── STEP BAR ──────────────────────────────────────────────
  Widget _stepBar() => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
    decoration: BoxDecoration(
      color: _white,
      border: Border(
        top: BorderSide(color: _border),
        bottom: BorderSide(color: _border),
      ),
    ),
    child: Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          bool filled = _step > i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: filled
                    ? const LinearGradient(colors: [_accent, Color(0xFF004FCC)])
                    : null,
                color: filled ? null : _border,
              ),
            ),
          );
        }
        int s = i ~/ 2;
        bool active = _step == s;
        bool done   = _step > s;
        return Expanded(
          child: GestureDetector(
            onTap: done ? () => _animateTo(s) : null,
            child: Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _accent : (active ? _accentLt : Colors.transparent),
                  border: Border.all(
                      color: done || active ? _accent : _border, width: 2),
                  boxShadow: active
                      ? [BoxShadow(color: _accent.withOpacity(0.25), blurRadius: 10)]
                      : [],
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : Icon(_steps[s]['icon'] as IconData,
                      size: 14,
                      color: active ? _accent : _txt2),
                ),
              ),
              const SizedBox(height: 4),
              Text(_steps[s]['label'] as String,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? _accent : _txt2,
                  )),
            ]),
          ),
        );
      }),
    ),
  );

  // ── STEP CONTENT ROUTER ───────────────────────────────────
  Widget _buildStepContent() {
    switch (_step) {
      case 0: return _symptomsStep();
      case 1: return _feedWaterStep();
      case 2: return _environmentStep();
      case 3: return _mortalityStep();
      default: return const SizedBox();
    }
  }

  // ─────────────────────────────────────────────────────────
  //  STEP 0 — SYMPTOMS
  // ─────────────────────────────────────────────────────────
  Widget _symptomsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader("Observed Symptoms", Icons.sick_rounded,
          "Select all signs visible in the flock right now", _danger, _dangerLt),
      const SizedBox(height: 16),
      _symptomGrid(),
      const SizedBox(height: 20),
      _label("Additional Observations"),
      const SizedBox(height: 8),
      _textField(
        controller: _otherCtrl,
        hint: "e.g. Some birds sitting in corners, unusual sounds…",
        maxLines: 3,
        icon: Icons.notes_rounded,
      ),
      const SizedBox(height: 12),
      _infoTip(Icons.info_outline_rounded, _accent, _accentLt,
          "Selecting no symptoms is also valid — the AI will assess based on other data."),
    ],
  );

  Widget _symptomGrid() {
    final symptoms = [
      {'key': 'coughing',       'label': 'Coughing',        'icon': Icons.air_rounded,            'val': _coughing},
      {'key': 'sneezing',       'label': 'Sneezing',         'icon': Icons.masks_rounded,           'val': _sneezing},
      {'key': 'diarrhea',       'label': 'Diarrhea',         'icon': Icons.water_drop_outlined,     'val': _diarrhea},
      {'key': 'weakness',       'label': 'Weakness',         'icon': Icons.battery_1_bar_rounded,   'val': _weakness},
      {'key': 'low_feed',       'label': 'Low Feed Intake',  'icon': Icons.no_meals_rounded,        'val': _lowFeed},
    ];
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.6,
      ),
      itemCount: symptoms.length,
      itemBuilder: (_, i) {
        final s = symptoms[i];
        bool val = s['val'] as bool;
        return _symptomTile(
          label: s['label'] as String,
          icon:  s['icon'] as IconData,
          selected: val,
          onTap: () => setState(() {
            switch (s['key']) {
              case 'coughing': _coughing = !_coughing; break;
              case 'sneezing': _sneezing = !_sneezing; break;
              case 'diarrhea': _diarrhea = !_diarrhea; break;
              case 'weakness': _weakness = !_weakness; break;
              case 'low_feed': _lowFeed  = !_lowFeed;  break;
            }
          }),
        );
      },
    );
  }

  Widget _symptomTile({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? _dangerLt : _white,
          border: Border.all(
            color: selected ? _danger : _border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: selected ? _danger : _txt2),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? _danger : _txt1,
                )),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? _danger : Colors.transparent,
              border: Border.all(color: selected ? _danger : _border, width: 1.5),
            ),
            child: selected
                ? const Icon(Icons.check, size: 11, color: Colors.white)
                : null,
          ),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  //  STEP 1 — FEED & WATER
  // ─────────────────────────────────────────────────────────
  Widget _feedWaterStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader("Feed & Water Intake", Icons.water_drop_rounded,
          "Enter today's and 7-day average consumption", _accent, _accentLt),
      const SizedBox(height: 20),

      // Feed card
      _groupCard(
        title: "Feed Consumption",
        icon: Icons.restaurant_rounded,
        iconColor: _warn,
        iconBg: _warnLt,
        children: [
          _label("Today's Feed Intake (kg) *"),
          const SizedBox(height: 8),
          _textField(
            controller: _feedTodayCtrl,
            hint: "e.g. 45",
            icon: Icons.scale_rounded,
            keyboardType: TextInputType.number,
            suffix: "kg",
          ),
          const SizedBox(height: 14),
          _label("7-Day Average Feed (kg)"),
          const SizedBox(height: 8),
          _textField(
            controller: _feedAvgCtrl,
            hint: "e.g. 52",
            icon: Icons.show_chart_rounded,
            keyboardType: TextInputType.number,
            suffix: "kg",
          ),
        ],
      ),

      const SizedBox(height: 16),

      // Water card
      _groupCard(
        title: "Water Consumption",
        icon: Icons.water_drop_rounded,
        iconColor: _accent,
        iconBg: _accentLt,
        children: [
          _label("Today's Water Intake (L) *"),
          const SizedBox(height: 8),
          _textField(
            controller: _waterTodayCtrl,
            hint: "e.g. 110",
            icon: Icons.opacity_rounded,
            keyboardType: TextInputType.number,
            suffix: "L",
          ),
          const SizedBox(height: 14),
          _label("7-Day Average Water (L)"),
          const SizedBox(height: 8),
          _textField(
            controller: _waterAvgCtrl,
            hint: "e.g. 125",
            icon: Icons.show_chart_rounded,
            keyboardType: TextInputType.number,
            suffix: "L",
          ),
        ],
      ),

      const SizedBox(height: 12),
      _infoTip(Icons.lightbulb_outline_rounded, _warn, _warnLt,
          "A drop of >15% in feed or water intake is an early disease indicator."),
    ],
  );

  // ─────────────────────────────────────────────────────────
  //  STEP 2 — ENVIRONMENT
  // ─────────────────────────────────────────────────────────
  Widget _environmentStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader("Environment Conditions", Icons.thermostat_rounded,
          "Current shed conditions affect flock health significantly", _green, _greenLt),
      const SizedBox(height: 20),

      _groupCard(
        title: "Temperature & Humidity",
        icon: Icons.device_thermostat_rounded,
        iconColor: _danger,
        iconBg: _dangerLt,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label("Temperature (°C) *"),
              const SizedBox(height: 8),
              _textField(
                controller: _tempCtrl,
                hint: "e.g. 34",
                icon: Icons.thermostat_rounded,
                keyboardType: TextInputType.number,
                suffix: "°C",
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label("Humidity (%) *"),
              const SizedBox(height: 8),
              _textField(
                controller: _humidityCtrl,
                hint: "e.g. 70",
                icon: Icons.water_outlined,
                keyboardType: TextInputType.number,
                suffix: "%",
              ),
            ])),
          ]),
        ],
      ),

      const SizedBox(height: 16),

      _groupCard(
        title: "Shed Conditions",
        icon: Icons.home_work_rounded,
        iconColor: _accent,
        iconBg: _accentLt,
        children: [
          _label("Ventilation Level"),
          const SizedBox(height: 10),
          _segmentedRow(_ventOptions, _ventilation, (v) => setState(() => _ventilation = v),
              [_green, _warn, _danger]),
          const SizedBox(height: 16),
          _label("Litter Condition"),
          const SizedBox(height: 10),
          _segmentedRow(_litterOptions, _litterCond, (v) => setState(() => _litterCond = v),
              [_green, _green, _warn, _danger]),
          const SizedBox(height: 16),
          _toggleRow(
            label: "Ammonia Smell Present",
            sublabel: "Strong smell indicates poor air quality",
            icon: Icons.warning_amber_rounded,
            value: _ammoniaSmell,
            onChanged: (v) => setState(() => _ammoniaSmell = v),
            activeColor: _danger,
          ),
        ],
      ),

      const SizedBox(height: 12),
      _infoTip(Icons.thermostat_rounded, _danger, _dangerLt,
          "Ideal broiler temperature at 28 days is 24–26°C. High humidity + heat stresses birds."),
    ],
  );

  // ─────────────────────────────────────────────────────────
  //  STEP 3 — MORTALITY
  // ─────────────────────────────────────────────────────────
  Widget _mortalityStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader("Mortality Records", Icons.monitor_heart_rounded,
          "Enter dead bird counts for the last 2 days", _danger, _dangerLt),
      const SizedBox(height: 20),

      _groupCard(
        title: "Recent Deaths",
        icon: Icons.calendar_today_rounded,
        iconColor: _danger,
        iconBg: _dangerLt,
        children: [
          _label("Yesterday  (${_dayLabel(1)})"),
          const SizedBox(height: 8),
          _textField(
            controller: _dead1Ctrl,
            hint: "Number of dead birds",
            icon: Icons.remove_circle_outline_rounded,
            keyboardType: TextInputType.number,
            suffix: "birds",
          ),
          const SizedBox(height: 14),
          _label("Today  (${_dayLabel(0)})"),
          const SizedBox(height: 8),
          _textField(
            controller: _dead2Ctrl,
            hint: "Number of dead birds",
            icon: Icons.remove_circle_outline_rounded,
            keyboardType: TextInputType.number,
            suffix: "birds",
          ),
        ],
      ),

      const SizedBox(height: 16),

      // Summary card
      _summaryCard(),

      const SizedBox(height: 12),
      _infoTip(Icons.monitor_heart_rounded, _danger, _dangerLt,
          "Normal mortality for broilers is <0.5% per day. Higher rates require immediate attention."),

      const SizedBox(height: 24),
      _analyzeButton(),
    ],
  );

  Widget _summaryCard() {
    int active = _symptomCount();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [_accent.withOpacity(0.06), _accent.withOpacity(0.02)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: _accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.summarize_rounded, size: 16, color: _accent),
            const SizedBox(width: 6),
            const Text("Analysis Summary",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _accent)),
          ]),
          const SizedBox(height: 14),
          _summaryRow("Flock", widget.flockName),
          _summaryRow("Breed / Age", "${widget.breed} · ${widget.ageDays} days"),
          _summaryRow("Active Birds", "${widget.currentBirds} / ${widget.totalBirds}"),
          _summaryRow("Symptoms Selected", "$active symptom${active != 1 ? 's' : ''}"),
          _summaryRow("Feed Today", _feedTodayCtrl.text.isEmpty ? "—" : "${_feedTodayCtrl.text} kg"),
          _summaryRow("Temp / Humidity", _tempCtrl.text.isEmpty
              ? "—" : "${_tempCtrl.text}°C / ${_humidityCtrl.text}%"),
          _summaryRow("Ventilation", _ventilation),
          _summaryRow("Litter Condition", _litterCond),
          _summaryRow("Ammonia Smell", _ammoniaSmell ? "Yes ⚠️" : "No"),
        ],
      ),
    );
  }

  int _symptomCount() =>
      [_coughing, _sneezing, _diarrhea, _weakness, _lowFeed].where((v) => v).length;

  Widget _summaryRow(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(child: Text(k, style: const TextStyle(fontSize: 12.5, color: _txt2))),
        Text(v, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _txt1)),
      ],
    ),
  );

  // ── ANALYZE BUTTON ────────────────────────────────────────
  Widget _analyzeButton() => GestureDetector(
    onTap: () async {
      try {


        String? token = await FirebaseAuth.instance.currentUser!
            .getIdToken();

        lang_picker.Language _selectedCupertinoLanguage = await Utils.getSelectedLanguage();
        // Build payload and navigate
        final payload = _buildPayload(
            _selectedCupertinoLanguage.name, token!);


        setState(() {
          isLoading = true;
        });

        // ==========================================
        // API RESPONSE
        // ==========================================
        final result = await AIServer.askHealthAI(payload);

        if (result == null) {
          Utils.showToast("Error occured");
          setState(() {
            isLoading = false;
          });

          return;
        }

        aiResponse = result;

        double weeks = widget.ageDays / 7;

        await DatabaseHelper.insertResponse(
          AIResponse(
            flockId: widget.flockId.toString(),
            category: "health",
            title: "health",
            response: aiResponse!,
            creditsUsed: 3,
            createdAt: DateTime.now(),
            birdCount: widget.currentBirds,
            ageWeeks: weeks.toInt(),
          ),
        );

        isLoading = false;

        setState(() {});
      }
      catch(ex){
        Utils.showToast(ex.toString());
        print(ex);
      }

    },
    child: Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(
          color: const Color(0xFFEF4444).withOpacity(0.35),
          blurRadius: 20, offset: const Offset(0, 6),
        )],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.health_and_safety_rounded, size: 20, color: Colors.white),
          SizedBox(width: 10),
          Text("Analyze Health with AI",
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: Colors.white, letterSpacing: 0.4)),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
        ],
      ),
    ),
  );

  // ── BOTTOM NAV BAR ────────────────────────────────────────
  Widget _bottomBar() {
    bool isLast = _step == _steps.length - 1;
    return Container(

      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: _white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(children: [
        if (_step > 0) ...[
          GestureDetector(
            onTap: () => _animateTo(_step - 1),
            child: Container(
              height: 50, width: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _fieldBg,
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: _txt2),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (!isLast)
          Expanded(child: _nextBtn()),
      ]),
    );
  }

  Widget _nextBtn() {
    bool enabled = _canProceed;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.45,
      child: GestureDetector(
        onTap: enabled ? () => _animateTo(_step + 1) : null,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: enabled
                ? const LinearGradient(colors: [_accent, Color(0xFF004FCC)])
                : null,
            color: enabled ? null : const Color(0xFFF3F4F6),
            border: Border.all(color: enabled ? Colors.transparent : _border),
            boxShadow: enabled
                ? [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 5))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Next: ${_steps[_step + 1]['label']}",
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: enabled ? Colors.white : _txt2,
                    letterSpacing: 0.3,
                  )),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 17,
                  color: enabled ? Colors.white : _txt2),
            ],
          ),
        ),
      ),
    );
  }

  // ── SHARED WIDGETS ────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon, String sub,
      Color fg, Color bg) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: bg,
      border: Border.all(color: fg.withOpacity(0.2)),
    ),
    child: Row(children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: fg.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: fg, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 12, color: fg.withOpacity(0.7))),
        ],
      )),
    ]),
  );

  Widget _groupCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required List<Widget> children,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: _white,
      border: Border.all(color: _border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _txt1)),
      ]),
      const SizedBox(height: 16),
      const Divider(height: 1, color: Color(0xFFF3F4F6)),
      const SizedBox(height: 16),
      ...children,
    ]),
  );

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _txt2));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? suffix,
  }) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    onChanged: (_) => setState(() {}),
    style: const TextStyle(fontSize: 14, color: _txt1, fontWeight: FontWeight.w500),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFFD1D5DB)),
      filled: true,
      fillColor: _fieldBg,
      prefixIcon: Icon(icon, size: 18, color: _txt2),
      suffixText: suffix,
      suffixStyle: const TextStyle(fontSize: 13, color: _txt2, fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
    ),
  );

  Widget _segmentedRow(List<String> options, String selected,
      ValueChanged<String> onSelect, List<Color> colors) => Row(
    children: List.generate(options.length, (i) {
      bool sel = selected == options[i];
      Color c = colors[i < colors.length ? i : colors.length - 1];
      return Expanded(
        child: GestureDetector(
          onTap: () => onSelect(options[i]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: sel ? c.withOpacity(0.1) : _fieldBg,
              border: Border.all(
                color: sel ? c : _border,
                width: sel ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Text(options[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? c : _txt2,
                  )),
            ),
          ),
        ),
      );
    }),
  );

  Widget _toggleRow({
    required String label,
    required String sublabel,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color activeColor = _accent,
  }) => Row(children: [
    Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: value ? activeColor.withOpacity(0.1) : _fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value ? activeColor.withOpacity(0.3) : _border),
      ),
      child: Icon(icon, size: 18, color: value ? activeColor : _txt2),
    ),
    const SizedBox(width: 12),
    Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _txt1)),
        Text(sublabel, style: const TextStyle(fontSize: 11, color: _txt2)),
      ],
    )),
    Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
    ),
  ]);

  Widget _infoTip(IconData icon, Color fg, Color bg, String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: bg,
      border: Border.all(color: fg.withOpacity(0.2)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: fg),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
          style: TextStyle(fontSize: 12, color: fg.withOpacity(0.85), height: 1.5))),
    ]),
  );
}