import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/dfareporting/v4.dart';
import 'package:poultary/model/flock.dart';
import 'package:poultary/model/weight_record.dart';
import 'package:poultary/utils/utils.dart';
import '../../database/databse_helper.dart';
import '../../model/feed_summary_flock.dart';
import '../model/ai_response.dart';
import '../network_api.dart';

class AskAIDetailsScreen extends StatefulWidget {
  final String duration;
  final String anlaysis_type;
  final int f_id;

  const AskAIDetailsScreen({
    Key? key,
    required this.duration,
    required this.f_id,
    required this.anlaysis_type,
  }) : super(key: key);

  @override
  _AskAIDetailsScreenState createState() => _AskAIDetailsScreenState();
}

class _AskAIDetailsScreenState extends State<AskAIDetailsScreen> {

  // =========================
  // FORM KEY
  // =========================

  final _formKey = GlobalKey<FormState>();

  // =========================
  // CONTROLLERS
  // =========================

  final TextEditingController birds = TextEditingController();
  final TextEditingController age = TextEditingController();
  final TextEditingController weight = TextEditingController();
  final TextEditingController feedUsed = TextEditingController();
  final TextEditingController mortality = TextEditingController();
  final TextEditingController temperature = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController country = TextEditingController();

  // Optional
  final TextEditingController eggProduction = TextEditingController();
  final TextEditingController feedPerBird = TextEditingController();

  // =========================
  // DROPDOWNS
  // =========================

  String flockType = "broiler";
  String climate = "hot";
  String feedType = "grower";

  bool isLoading = false;
  String? aiResponse;

  Flock? flock = null;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {

    getDatesFromDuration(widget.duration);

    flock = await DatabaseHelper.getSingleFlock(widget.f_id);
    birds.text = flock!.active_bird_count.toString();
    age.text = Utils.getAnimalAgeWeeks(flock!.acqusition_date);
    flockType = flock!.purpose.toLowerCase() == "egg" ? "layer" : "broiler";
    WeightRecord? weightRecord = await DatabaseHelper.getLatestWeightRecord(Utils.selected_flock!.f_id);
    weight.text = weightRecord == null? "0.0" : weightRecord.averageWeight.toString();
    temperature.text = "25";
    List<FlockFeedSummary>? flockFeedSummary = await DatabaseHelper.getMyMostUsedFeedsByFlock(flock!.f_id, str_date, end_date);
    feedUsed.text =  flockFeedSummary.isEmpty? "0" : flockFeedSummary[0].totalQuantity.toString();
    feedPerBird.text = flockFeedSummary.isEmpty? "0" : ((flockFeedSummary[0].totalQuantity * 1000) / flock!.active_bird_count!).toString();
    num total_eggs_collected =
    await DatabaseHelper.getEggCalculations(flock!.f_id, 1, str_date, end_date);
    eggProduction.text = total_eggs_collected.toString();
    num reductionCOunt = await DatabaseHelper.getFlockReductionCount(flockId: flock!.f_id, reason: "MORTALITY", str_date: str_date, end_date: end_date);
    mortality.text = ((reductionCOunt / flock!.bird_count!) * 100 ).toStringAsFixed(1);

    setState(() {

    });

  }

  String str_date = "", end_date = "";
  void getDatesFromDuration(String filter){
    int index = 0;

    if (filter == 'TODAY'){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);


    }
    else if (filter == 'YESTERDAY'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

    }
    else if (filter == 'THIS_MONTH'){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


    }else if (filter == 'LAST_MONTH'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


    }else if (filter == 'LAST3_MONTHS'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


    }else if (filter == 'LAST6_MONTHS'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


    }else if (filter == 'THIS_YEAR'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

    }else if (filter == 'LAST_YEAR'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


    }else if (filter == 'ALL_TIME'){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);



    }


  }


  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF0F2F8),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xff1A1F36),
        centerTitle: true,
        title:  Text(
          "AI Analysis".tr(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xff1A1F36),
            letterSpacing: 0.3,
          ),
        ),
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              _topHeader(),

              if (aiResponse == null && !isLoading) ...[
                const SizedBox(height: 20),

                _sectionTitle("Flock Information"),

                _card(
                  child: Column(
                    children: [
                      _inputField(
                        controller: TextEditingController(text: flockType),
                        label: "Flock Type",
                        icon: Icons.category_outlined,
                        isDropdown: true,
                        dropdownValue: flockType,
                        dropdownItems: ["broiler", "layer", "breeder", "desi"],
                        onDropdownChanged: (v) => setState(() => flockType = v!),
                      ),

                      const SizedBox(height: 12),
                      _inputField(
                        controller: birds,
                        label: "Total Birds",
                        icon: Icons.pets_outlined,
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _inputField(
                              controller: age,
                              label: "Age (Weeks)",
                              icon: Icons.calendar_today_outlined,
                              validator: _requiredValidator,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _inputField(
                              controller: weight,
                              label: "Weight (kg)",
                              icon: Icons.monitor_weight_outlined,
                              validator: _requiredValidator,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _inputField(
                        controller: mortality,
                        label: "Mortality %",
                        icon: Icons.warning_amber_outlined,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _sectionTitle("Feed Information"),

                _card(
                  child: Column(
                    children: [
                      _inputField(
                        controller: TextEditingController(text: feedType),
                        label: "Feed Type",
                        icon: Icons.restaurant_outlined,
                        isDropdown: true,
                        dropdownValue: feedType,
                        dropdownItems: ["starter", "grower", "finisher", "layer"],
                        onDropdownChanged: (v) => setState(() => feedType = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _inputField(
                              controller: feedUsed,
                              label: "Feed Used (kg)",
                              icon: Icons.scale_outlined,
                              validator: _requiredValidator,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _inputField(
                              controller: feedPerBird,
                              label: "Feed/Bird (g)",
                              icon: Icons.grain_outlined,
                            ),
                          ),
                        ],
                      ),
                      if (flockType == "layer") ...[
                        const SizedBox(height: 12),
                        _inputField(
                          controller: eggProduction,
                          label: "Egg Production %",
                          icon: Icons.egg_alt_outlined,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _sectionTitle("Environment"),

                _card(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _inputField(
                        controller: TextEditingController(text: climate),
                        label: "Climate",
                        icon: Icons.wb_sunny_outlined,
                        isDropdown: true,
                        dropdownValue: climate,
                        dropdownItems: ["hot", "cold", "controlled"],
                        onDropdownChanged: (v) => setState(() => climate = v!),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _inputField(
                              controller: city,
                              label: "City",
                              icon: Icons.location_city_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _inputField(
                              controller: country,
                              label: "Country",
                              icon: Icons.flag_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _inputField(
                        controller: temperature,
                        label: "Temperature °C",
                        icon: Icons.thermostat_outlined,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                _askAIButton(),
                const SizedBox(height: 24),
              ],

              if (isLoading) _loadingWidget(),

              if (aiResponse != null) _responseCard(),

            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  // HEADER
  // ======================================================

  Widget _topHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff3D2DB5), Color(0xff6A5AE0)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff6A5AE0).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                  "AI Insights".tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "${widget.anlaysis_type.toUpperCase()} • ${widget.duration}",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // SECTION TITLE
  // ======================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xff6A5AE0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.tr(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xff1A1F36),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  // CARD
  // ======================================================

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ======================================================
  // INPUT FIELD (unified — text + dropdown)
  // ======================================================

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool isDropdown = false,
    String? dropdownValue,
    List<String>? dropdownItems,
    Function(String?)? onDropdownChanged,
  }) {
    final fillColor = const Color(0xffF5F6FA);
    const radius = 14.0;

    if (isDropdown && dropdownItems != null && dropdownValue != null) {
      return DropdownButtonFormField<String>(
        value: dropdownValue.tr(),
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        decoration: InputDecoration(
          labelText: label.tr(),
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xff8A94A6)),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xff6A5AE0)),
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: Color(0xff6A5AE0), width: 1.5),
          ),
        ),
        items: dropdownItems.map((e) => DropdownMenuItem(
          value: e,
          child: Text(
            e.toUpperCase(),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        )).toList(),
        onChanged: onDropdownChanged,
      );
    }

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xff8A94A6)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xff6A5AE0)),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: Color(0xff6A5AE0), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }

  // ======================================================
  // BUTTON
  // ======================================================

  Widget _askAIButton() {
    return GestureDetector(
      onTap: () {
        if (!_formKey.currentState!.validate()) {
          return;
        }
        _showCreditDialog(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff3D2DB5), Color(0xff6A5AE0)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff6A5AE0).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:  [
            Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              "Analyze with AI".tr(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================
// LOADING WIDGET
// ======================================================

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

           Text(
            "AI is analyzing your flock...".tr(),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xff1A1F36),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Generating smart feed and health recommendations".tr(),
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

// ======================================================
// CREDIT DIALOG
// ======================================================

  void _showCreditDialog(BuildContext context) {
    int creditsNeeded = getCoinsByAnalysisType();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
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
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                ),

                const SizedBox(height: 20),

                 Text(
                  "AI Analysis".tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff1A1F36),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "This AI request will use".tr(),
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xffF0EEFF),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("🪙", style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        "$creditsNeeded"+ "Credits".tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: Color(0xff6A5AE0),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  "AI will analyze flock performance, feed usage, growth and environmental conditions.".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: Color(0xffDDDDEE)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child:  Text(
                          "CANCEL".tr(),
                          style: TextStyle(
                            color: Color(0xff8A94A6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xff6A5AE0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          setState(() {
                            isLoading = true;
                            aiResponse = null;
                          });
                          await _generateAIResponse();
                          setState(() {
                            isLoading = false;
                          });
                        },
                        child:  Text(
                          "Proceed".tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// ======================================================
// RESPONSE CARD
// ======================================================

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
              children:  [
                Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  "AI Analysis Result".tr(),
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


  // ======================================================
// COIN CALCULATION
// ======================================================

  int getCoinsByAnalysisType() {

    switch (widget.anlaysis_type.toLowerCase()) {

      case "feed":
        return 2;

      case "health":
        return 3;

      case "financial":
        return 3;

      default:
        return 1;
    }
  }

// ======================================================
// GENERATE AI RESPONSE
// ======================================================

  Future<void> _generateAIResponse() async {

    try {

      // ==========================================
      // BUILD DATA TO SEND TO AI
      // ==========================================
      String? token = await FirebaseAuth.instance.currentUser!
          .getIdToken();

      Language? _selectedCupertinoLanguage = await Utils.getSelectedLanguage();
      Map<String, dynamic> aiData = {

        "firebase_token": token,
        "language": _selectedCupertinoLanguage!.name!,
        // FLOCK
        "flock_type": flockType,
        "bird_count": birds.text.trim(),
        "age_weeks": age.text.trim(),
        "avg_weight_kg": weight.text.trim(),
        "mortality_percent": mortality.text.trim(),

        // FEED
        "feed_type": feedType,
        "feed_used_kg": feedUsed.text.trim(),
        "feed_per_bird_g": feedPerBird.text.trim(),

        // LAYERS
        "egg_production_percent": eggProduction.text.trim(),

        // ENVIRONMENT
        "climate": climate,
        "temperature_c": temperature.text.trim(),
        "city": city.text.trim(),
        "country": country.text.trim(),

        // ANALYSIS
        "analysis_type": widget.anlaysis_type,
        "duration": widget.duration,
      };

      debugPrint(aiData.toString());

      // ==========================================
      // API RESPONSE
      // ==========================================
      final result = await AIServer.askAI(aiData);

      if (result == null) {
        Utils.showToast("Error occured".tr());
      }

      aiResponse = result;

      await DatabaseHelper.insertResponse(
        AIResponse(
          flockId: Utils.selected_flock!.f_id.toString(),
          category: widget.anlaysis_type,
          title: widget.anlaysis_type,
          response: aiResponse!,
          creditsUsed: getCoinsByAnalysisType(),
          createdAt: DateTime.now(),
          birdCount: int.tryParse(birds.text),
          ageWeeks: int.tryParse(age.text),
        ),
      );


      setState(() {});

    } catch (e) {

      debugPrint("AI ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to generate AI response".tr()),
        ),
      );
    }

    /*//  aiResponse = """
📊 AI Flock Analysis

🐔 Flock Type: ${flockType.toUpperCase()}
🐥 Birds: ${birds.text}
📅 Age: ${age.text} Weeks
⚖ Avg Weight: ${weight.text} kg

🌡 Climate: ${climate.toUpperCase()}
🌍 Region: ${city.text}, ${country.text}

🍽 Feed Analysis:
• Feed usage appears normal for current flock size
• Slight protein increase may improve growth
• Recommend vitamin supplementation during heat stress

⚠ Health Insights:
• Mortality should remain below 3%
• Ensure proper ventilation and clean water

📈 AI Recommendation:
Increase feed quality and monitor weight weekly for better flock performance.
""";*/

      // ==========================================
      // SAVE RESPONSE TO DATABASE
      // ==========================================



      // ==========================================
      // DEDUCT USER CREDITS
      // ==========================================

     /* final FirebaseAuth auth = FirebaseAuth.instance;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      var user = auth.currentUser;

      if (user != null) {

        int remainingCredits =
            Utils.ai_credits - getCoinsByAnalysisType();

        remainingCredits = remainingCredits < 0
            ? 0
            : remainingCredits;

        await firestore
            .collection("ai_users")
            .doc(user.uid)
            .update({
          "credits": remainingCredits,
          "updatedAt": FieldValue.serverTimestamp(),
        });

        // Update local cache
        Utils.ai_credits = remainingCredits;

        }*/


      // ==========================================
      // UPDATE UI
      // ==========================================


  }

  // ======================================================
  // VALIDATION
  // ======================================================

  String? _requiredValidator(String? value) {
    if (value == null || value
        .trim()
        .isEmpty) {
      return "Required";
    }
    return null;
  }

}