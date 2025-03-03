import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/add_vac_med.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'database/databse_helper.dart';
import 'model/flock.dart';
import 'model/med_vac_item.dart';

class MedicationVaccinationScreen extends StatefulWidget {
  const MedicationVaccinationScreen({Key? key}) : super(key: key);

  @override
  _MedicationVaccinationScreen createState() => _MedicationVaccinationScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _MedicationVaccinationScreen extends State<MedicationVaccinationScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  int _other_filter = 2;
  void getFilters() async {
    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr() ,bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1, flock_new: 1));

    for(int i=0;i<flocks.length;i++) {
      _purposeList.add(flocks.elementAt(i).f_name);
    }

    if(Utils.selected_flock != null)
      _purposeselectedValue = Utils.selected_flock!.f_name;
    else {
      _purposeselectedValue = _purposeList[0];
      Utils.selected_flock = flocks[0];
    }

    f_id = getFlockID();
    _other_filter = (await SessionManager.getOtherFilter())!;
    date_filter_name = filterList.elementAt(_other_filter);
    getData(date_filter_name);

  }

  bool isVaccine = false;
  @override
  void initState() {
    super.initState();

    if (Utils.vaccine_medicine.toLowerCase().contains("medication")) {
      isVaccine = false;
    }else{
      isVaccine = true;
    }

    getFilters();
    Utils.setupAds();

  }

  bool no_colection = true;
  List<Vaccination_Medication> vac_med_list = [], tempList = [];
  List<String> flock_name = [];
  void getvaccMedList() async {

    await DatabaseHelper.instance.database;

    tempList = await DatabaseHelper.getAllVaccinationMedications();
    vac_med_list = tempList.reversed.toList();
    feed_total = vac_med_list.length;

    setState(() {

    });

  }

  int feed_total = 0;

  String applied_filter_name = "Health";

  @override
  Widget build(BuildContext context) {

    double safeAreaHeight =  MediaQuery.of(context).padding.top;
    double safeAreaHeightBottom =  MediaQuery.of(context).padding.bottom;
    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height - (safeAreaHeight+safeAreaHeightBottom);
      child:
    return SafeArea(child: Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Container(
          height: 65, // Slightly increased height for better touch area
          width: widthScreen,
          padding: EdgeInsets.symmetric(horizontal: 10), // Added padding for better spacing
          child: Row(
            children: [
              /// 🟢 Vaccination Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    Utils.vaccine_medicine = "Vaccination";
                    addNewVacMad();
                  },
                  borderRadius: BorderRadius.circular(10), // Rounded ripple effect
                  child: Container(
                    height: 55, // Increased height for a more premium feel
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade700, Colors.green.shade400], // Gradient effect
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade900.withOpacity(0.2),
                          blurRadius: 6,
                          spreadRadius: 1,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 28), // Slightly smaller icon
                        SizedBox(width: 6), // Space between icon and text
                        Text(
                          'Vaccination'.tr(),
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(width: 10), // Space between buttons

              /// 🔹 Medication Button
              Expanded(
                child: InkWell(
                  onTap: () {
                    Utils.vaccine_medicine = "Medication";
                    addNewVacMad();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade400], // Blue for differentiation
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade900.withOpacity(0.2),
                          blurRadius: 6,
                          spreadRadius: 1,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 28),
                        SizedBox(width: 6),
                        Text(
                          'Medication'.tr(),
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        elevation: 0,
      ),
      body:SafeArea(
        top: false,

          child:Container(
          width: widthScreen,
          height: heightScreen,
            color: Utils.getScreenBackground(),
            child:SingleChildScrollViewWithStickyFirstWidget(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:  [
              Utils.getDistanceBar(),

              ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Utils.getThemeColorBlue().withOpacity(0.9), Utils.getThemeColorBlue()],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      /// Back Button
                      InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        ),
                      ),

                      /// Title
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: 12),
                          child: Text(
                            applied_filter_name.tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      /// Sort Button
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          openSortDialog(context, (selectedSort) {
                            setState(() {
                              sortOption = selectedSort == "date_desc" ? "Date (New)" : "Date (Old)";
                              sortSelected = selectedSort == "date_desc" ? "DESC" : "ASC";
                            });

                            getFilteredTransactions(str_date, end_date);
                          });
                        },
                        child: Container(
                          height: 45,
                          width: 130,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  sortOption.tr(),
                                  style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.sort, color: Colors.white, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Center(
                child: Container(
                  padding: EdgeInsets.only(top: 10),
                  margin: EdgeInsets.symmetric(horizontal: 10), // Margin of 10 on left & right
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3, // 60% of available space
                        child: SizedBox(
                          height: 55,
                          child: _buildDropdownField(
                            "Select Item",
                            _purposeList,
                            _purposeselectedValue,
                                (String? newValue) {
                              setState(() {
                                _purposeselectedValue = newValue!;
                              });
                            },
                            width: double.infinity,
                            height: 45,
                          ),
                        ),
                      ),
                      SizedBox(width: 5), // Space between the dropdowns
                      Expanded(
                        flex: 2, // 40% of available space
                        child: SizedBox(
                          height: 55,
                          child: _buildDropdownField(
                            "Select Item",
                            filterList,
                            date_filter_name,
                                (String? newValue) {
                              setState(() {
                                date_filter_name = newValue!;
                                getData(date_filter_name);
                              });
                            },
                            width: double.infinity,
                            height: 45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                height: 55,
                width: widthScreen,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white.withOpacity(0.1), // Light transparent background
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildFilterButton('All', 1, Colors.blue),
                    buildFilterButton('Medication', 2, Colors.green),
                    buildFilterButton('Vaccination', 3, Colors.red),
                  ],
                ),
              ),

              vac_med_list.length > 0 ? Container(
                height: heightScreen - 300,
                width: widthScreen,
                child: ListView.builder(
                    itemCount: vac_med_list.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (BuildContext context, int index) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              spreadRadius: 2,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// 🟢 Medicine Name & Options Menu
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "${vac_med_list[index].medicine!.tr()} ",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Utils.getThemeColorBlue(),
                                          ),
                                        ),
                                        TextSpan(
                                          text: "(${vac_med_list[index].f_name!.tr()})",
                                          style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 16,
                                            color: Colors.black54, // Less prominent
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTapDown: (TapDownDetails details) {
                                    selected_id = vac_med_list[index].id;
                                    selected_index = index;
                                    showMemberMenu(details.globalPosition);
                                  },
                                  child: Icon(Icons.more_vert, color: Colors.black54),
                                ),
                              ],
                            ),

                            SizedBox(height: 6),
                            Divider(thickness: 1, color: Colors.grey.withOpacity(0.3)),

                            /// 📅 Date Section (Aligned Right)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                                  SizedBox(width: 4),
                                  Text(
                                    Utils.getFormattedDate(vac_med_list[index].date.toString()),
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 6),

                            /// 🏥 Birds & Disease
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Image.asset("assets/bird_icon.png", width: 25, height: 25),
                                    SizedBox(width: 5),
                                    Text(
                                      'Birds: '.tr(),
                                      style: TextStyle(fontSize: 14, color: Colors.black),
                                    ),
                                    Text(
                                      vac_med_list[index].bird_count!.toString(),
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.coronavirus, size: 16, color: Colors.red),
                                SizedBox(width: 5),
                                Text('Disease: '.tr(), style: TextStyle(fontSize: 14, color: Colors.black)),
                                Text(
                                  vac_med_list[index].disease!,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),

                            /// 👨‍⚕️ Doctor Name
                            Row(
                              children: [
                                Icon(Icons.medical_services, size: 16, color: Colors.green),
                                SizedBox(width: 5),
                                Text(
                                  vac_med_list[index].type == 'Medication' ? 'Med by: '.tr() : 'Vac by: '.tr(),
                                  style: TextStyle(fontSize: 14, color: Colors.black),
                                ),
                                Text(
                                  vac_med_list[index].doctor_name!,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                                ),
                              ],
                            ),

                            /// 📝 Notes Section
                            if (vac_med_list[index].short_note != null && vac_med_list[index].short_note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.notes, size: 16, color: Colors.black54),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        vac_med_list[index].short_note!,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 14, color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );


                    }),
              ) :  Utils.getCustomEmptyMessage("assets/p_health.png", "No vaccination/medication added")

                  ]
      ),),),),),);
  }

  /// Function to Build Filter Buttons
  Widget buildFilterButton(String label, int index, Color color) {
    bool isSelected = selected == index;

    return Flexible( // Use Flexible instead of Expanded
      child: InkWell(
        onTap: () {
          setState(() {
            filter_name = label;
            selected = index;
            getFilteredTransactions(str_date, end_date);
          });
        },
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: 45,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              colors: [color.withOpacity(0.8), color.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.8) : Colors.grey.shade300,
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Icon(Icons.check, color: Colors.white, size: 18), // ✅ Checkmark only on selected
              if (isSelected) SizedBox(width: 6),
              Text(
                label.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildDropdownField(
      String label,
      List<String> items,
      String selectedValue,
      Function(String?) onChanged, {
        double width = double.infinity,
        double height = 70,
      }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Utils.getThemeColorBlue(), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(1, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          icon: Padding(
            padding: EdgeInsets.only(right: 5),
            child: Icon(Icons.arrow_drop_down_circle, color: Colors.blue, size: 25),
          ),
          isExpanded: true,
          style: TextStyle(fontSize: 16, color: Colors.black),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text(value.tr(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> addNewVacMad() async {
   var str = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NewVaccineMedicine()),
    );

   getFilteredTransactions(str_date, end_date);
  }

  //FILTER WORK
  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];


  int isCollection = 1;
  int selected = 1;
  int f_id = -1;


  Widget getDropDownList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _purposeselectedValue,
        elevation: 10,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _purposeselectedValue = newValue!;
            getFlockID();
            getFilteredTransactions(str_date, end_date);

          });
        },
        items: _purposeList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String filter_name = "All";
  void openDatePicker() {
    showDialog(
        context: context,
        builder: (BuildContext bcontext) {
          return AlertDialog(
            title: Text('DATE_FILTER'.tr()),
            content: setupAlertDialoadContainer(bcontext,widthScreen - 40, widthScreen),
          );
        });
  }
  Widget setupAlertDialoadContainer(BuildContext bcontext,double width, double height) {

    return Container(
      height: height, // Change as per your requirement
      width: width, // Change as per your requirement
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filterList.length,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            onTap: () {

              setState(() {
                date_filter_name = filterList.elementAt(index);
              });

              getData(date_filter_name);
              Navigator.pop(bcontext);
            },
            child: ListTile(
              title: Text(filterList.elementAt(index)),
            ),
          );
        },
      ),
    );
  }

  void getFilteredTransactions(String st,String end) async {

    await DatabaseHelper.instance.database;

    tempList = await DatabaseHelper.getFilteredMedicationWithSort(f_id,filter_name,st,end,sortSelected);
    vac_med_list = tempList.reversed.toList();
    setState(() {

    });

  }


  List<String> filterList = ['TODAY','YESTERDAY','THIS_MONTH', 'LAST_MONTH','LAST3_MONTHS', 'LAST6_MONTHS','THIS_YEAR',
    'LAST_YEAR','ALL_TIME','DATE_RANGE'];

  String date_filter_name = 'THIS_MONTH';
  String pdf_formatted_date_filter = 'THIS_MONTH';
  String str_date = '',end_date = '';
  void getData(String filter){
    int index = 0;

    if (filter == 'TODAY'){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);

    }
    else if (filter == 'YESTERDAY'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);

    }
    else if (filter == 'THIS_MONTH'){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST_MONTH'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);

    }else if (filter == 'LAST3_MONTHS'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST6_MONTHS'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'THIS_YEAR'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'LAST_YEAR'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      getFilteredTransactions(str_date, end_date);

    }else if (filter == 'ALL_TIME'){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);

      getFilteredTransactions(str_date, end_date);
    }else if (filter == 'DATE_RANGE'){
     _pickDateRange();
    }


  }

  DateTimeRange? selectedDateRange;
  Future<void> _pickDateRange() async {
    DateTime now = DateTime.now();
    DateTime firstDate = DateTime(now.year - 5); // Allows past 5 years
    DateTime lastDate = DateTime(now.year + 5); // Allows future 5 years

    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: selectedDateRange ?? DateTimeRange(start: now, end: now),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            hintColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      var inputFormat = DateFormat('yyyy-MM-dd');
      selectedDateRange = pickedRange;
      str_date = inputFormat.format(pickedRange.start);
      end_date = inputFormat.format(pickedRange.end);
      print(str_date+" "+end_date);
      getFilteredTransactions(str_date, end_date);

    }
  }



  int getFlockID() {


    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue == flocks.elementAt(i).f_name){
        f_id = flocks.elementAt(i).f_id;
        break;
      }
    }

    return f_id;
  }

  //RECORD DELETEION AND PDF

  int? selected_id = 0;
  int? selected_index = 0;
  void showMemberMenu(Offset offset) async {
    double left = offset.dx;
    double top = offset.dy;
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, 0, 0),

      items: [
        PopupMenuItem(
          value: 2,
          child: Text(
            "EDIT_RECORD".tr(),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Text(
            "DELETE_RECORD".tr(),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ),


      ],
      elevation: 8.0,
    ).then((value) async {
      if (value != null) {
        if(value == 2){
          if(vac_med_list.elementAt(selected_index!).type == 'Medication') {
            Utils.vaccine_medicine = "Medication";
            var str = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      NewVaccineMedicine(
                        vaccination_medication: vac_med_list.elementAt(
                            selected_index!),)),
            );

            getFilteredTransactions(str_date, end_date);
          }else{
            Utils.vaccine_medicine = "Vaccination";
            var str = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      NewVaccineMedicine(
                        vaccination_medication: vac_med_list.elementAt(
                            selected_index!),)),
            );

            getFilteredTransactions(str_date, end_date);
          }
        }
        else if(value == 1){
          showAlertDialog(context);
        }else {
          print(value);
        }
      }
    });
  }

  showAlertDialog(BuildContext context) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("CANCEL".tr()),
      onPressed:  () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("DELETE".tr()),
      onPressed:  () {
        DatabaseHelper.deleteItem("Vaccination_Medication", selected_id!);
        vac_med_list.removeAt(selected_index!);
        Utils.showToast("DONE".tr());
        Navigator.pop(context);
        setState(() {

        });


      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("CONFIRMATION".tr()),
      content: Text("RU_SURE".tr()),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }


  String sortSelected = "DESC"; // Default label
  String sortOption = "Date (new)";
  void openSortDialog(BuildContext context, Function(String) onSortSelected) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Sort By".tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Divider(),
              ListTile(
                title: Text("Date (New)".tr()),
                onTap: () {
                  onSortSelected("date_desc");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text("Date (Old)".tr()),
                onTap: () {
                  onSortSelected("date_asc");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }


}

