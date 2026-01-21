import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/med_vac_item.dart';
import 'package:poultary/pdf/pdf_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'model/flock.dart';
import 'model/health_chart_data.dart';
import 'model/health_report_item.dart';

class HealthReportScreen extends StatefulWidget {
  const HealthReportScreen({Key? key}) : super(key: key);

  @override
  _HealthReportScreen createState() => _HealthReportScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _HealthReportScreen extends State<HealthReportScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  int _reports_filter = 2;
  void getFilters() async {

    _reports_filter = (await SessionManager.getReportFilter())!;
    date_filter_name = filterList.elementAt(_reports_filter);
    getData(date_filter_name);
  }

  late ZoomPanBehavior _zoomPanBehavior;
  @override
  void initState() {
    super.initState();
     try
     {
       date_filter_name = Utils.applied_filter;
       _zoomPanBehavior = ZoomPanBehavior(
           enableDoubleTapZooming: true,
           enablePinching: true,
           // Enables the selection zooming
           enableSelectionZooming: true,
           selectionRectBorderColor: Colors.red,
           selectionRectBorderWidth: 1,
           selectionRectColor: Colors.grey
       );
       getFilters();
       getList();

     }
     catch(ex)
     {
       print(ex);
     }
    Utils.setupAds();

    AnalyticsUtil.logScreenView(screenName: "health_screen");
  }

  List<Vaccination_Medication> list = [];
  List<Health_Chart_Item> medlist = [], vaclist = [];
  List<String> flock_name = [];

  int egg_total = 0;

  int vac_count = 0;
  int med_count = 0;
  int total_health_count = 0;

  void clearValues(){

     vac_count = 0;
     med_count = 0;
     total_health_count = 0;
     list = [];

  }

  void getAllData() async{

    await DatabaseHelper.instance.database;

    clearValues();

    vac_count = await DatabaseHelper.getHealthTotal(f_id, "Vaccination", str_date, end_date);
    med_count = await DatabaseHelper.getHealthTotal(f_id, "Medication", str_date, end_date);

    medlist = await DatabaseHelper.getHealthReportData( str_date, end_date, "Medication");
    vaclist = await DatabaseHelper.getHealthReportData( str_date, end_date, "Vaccination");

    for(int i=0;i<vaclist.length;i++){
      vaclist.elementAt(i).date = Utils.getFormattedDate(vaclist.elementAt(i).date).substring(0,Utils.getFormattedDate(vaclist.elementAt(i).date).length-4);
    }

    for(int i=0;i<medlist.length;i++){
      medlist.elementAt(i).date = Utils.getFormattedDate(medlist.elementAt(i).date).substring(0,Utils.getFormattedDate(medlist.elementAt(i).date).length-4);
    }

    total_health_count = med_count + vac_count;

    getFilteredTransactions(str_date, end_date);

    setState(() {

    });

  }
  List<TopDisease> topDiseases=[];
  List<TopMedicine> topMedicines=[];
  List<VaccinationGrouped> groupedList = [];
  void getFilteredTransactions(String st,String end) async {

    await DatabaseHelper.instance.database;


    list = await DatabaseHelper.getFilteredMedication(f_id,"All",st,end);

     groupedList = _groupRecordsByFlock(list);
     topDiseases = getTopDiseases(list);
     topMedicines = getTopMedicines(list);

     Utils.groupedList = groupedList;

    setState(() {

    });

  }

  // Group records by flock name
  List<VaccinationGrouped> _groupRecordsByFlock(List<Vaccination_Medication> records) {
    Map<String, List<Vaccination_Medication>> groupedMap = {};

    for (var record in records) {
      groupedMap.putIfAbsent(record.f_name, () => []).add(record);
    }

    return groupedMap.entries.map((entry) => VaccinationGrouped(flockName: entry.key, records: entry.value)).toList();
  }



  Future<void> generateHealthReportExcel(
      String totalVaccinations,
      String totalMedications,
      List<Health_Report_Item> medicationReportList,
      List<Health_Report_Item> vaccinationReportList,
      ) async
  {
    var excel = Excel.createExcel();
    var sheet = excel['Health Report'.tr()];

    // ==== Define Styles ====
    var titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString("#1F4E78"), // dark blue
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    var sectionTitleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.fromHexString("#BDD7EE"), // light section
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    var headerStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.fromHexString("#B7DEE8"), // header
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    var numberStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Right,
    );

    int row = 0;

    // ==== Report Title ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("Birds Health Report".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = titleStyle;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));

    row += 2;

    // ==== Summary ====
    /*sheet.appendRow([
      TextCellValue("Total Vaccinations".tr()),
      TextCellValue("Total Medications".tr()),
    ]);*/

    List<String> totalListHeaders = ["Total Vaccinations".tr(),
      "Total Medications".tr()];

// Apply header style to the header row
    for (int i = 0; i < totalListHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .value = TextCellValue(totalListHeaders[i]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;

    }

    row++; // Move to the totals row

// Totals row
    sheet.appendRow([
      TextCellValue(totalVaccinations),
      TextCellValue(totalMedications),
    ]);

// Apply number style to totals row
    for (int i = 0; i < 2; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = numberStyle;
    }

    row += 2; // Add spacing before next section

    // ==== Section 1: Medication Report ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("Medication Report".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));

    row++;

    List<String> medHeaders = [
      "Medicine name".tr(),
      "Diseaese Name".tr(),
      "Flock Name".tr(),
      "Date".tr(),
      "Birds".tr(),
    ];

    for (int i = 0; i < medHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .value = TextCellValue(medHeaders[i]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }

    row++;

    for (var item in medicationReportList) {
      sheet.appendRow([
        TextCellValue(item.medicine_name),
        TextCellValue(item.disease_name),
        TextCellValue(item.f_name),
        TextCellValue(item.date),
        TextCellValue(item.birds),
      ]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .cellStyle = numberStyle;
      row++;
    }

    row += 2;

    // ==== Section 2: Vaccination Report ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("Vaccination Report".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));

    row++;

    List<String> vaccHeaders = [
      "Vaccine name".tr(),
      "Diseaese Name".tr(),
      "Flock Name".tr(),
      "Date".tr(),
      "BIRDS".tr(),
    ];

    for (int i = 0; i < vaccHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .value = TextCellValue(vaccHeaders[i]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }

    row++;

    for (var v in vaccinationReportList) {
      sheet.appendRow([
        TextCellValue(v.medicine_name),
        TextCellValue(v.disease_name),
        TextCellValue(v.f_name),
        TextCellValue(v.date),
        TextCellValue(v.birds),
      ]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .cellStyle = numberStyle;
      row++;
    }

    // === Auto-adjust column widths ===
    for (var table in excel.tables.keys) {
      var sheet = excel[table];
      for (int col = 0; col < sheet.maxColumns; col++) {
        double maxLength = 0;
        for (int row = 0; row < sheet.maxRows; row++) {
          var cellValue = sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
              .value;
          if (cellValue != null) {
            var text = cellValue.toString();
            if (text.length > maxLength) {
              maxLength = text.length.toDouble();
            }
          }
        }
        sheet.setColumnWidth(col, (maxLength * 1.2).clamp(12, 35));
      }
    }

    saveAndShareExcel(excel);
  }


  Future<void> saveAndShareExcel(Excel excel) async {
    final downloadsDir = Directory("/storage/emulated/0/Download");
    String formattedDate = DateFormat('dd_MMM_yyyy_HH_mm').format(DateTime.now());
    String filePath = "${downloadsDir.path}/health_report_$formattedDate.xlsx";

    final file = File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    Utils.showToast("Saved to Downloads: egg_report_$formattedDate.xlsx");

    // ✅ Share/Open the file safely
    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Health report exported successfully!",
    );
  }


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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Birds Health Report".tr(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        elevation: 8,
        automaticallyImplyLeading: true,

        actions: [
          if(!Platform.isIOS)

            InkWell(
              onTap: () {

                Utils.setupInvoiceInitials("Birds Health Report".tr(),pdf_formatted_date_filter);
                prepareListData();

                generateHealthReportExcel(Utils.vaccine_report_list.length.toString(), Utils.medication_report_list.length.toString(), Utils.medication_report_list, Utils.vaccine_report_list);

              },
              child: Container(
                width: 30,
                height: 30,
                margin: EdgeInsets.only(right: 10),
                child: Image.asset('assets/excel_icon.png'),
              ),
            ),
          InkWell(
            onTap: () {
              Utils.setupInvoiceInitials("Birds Health Report".tr(),pdf_formatted_date_filter);
              prepareListData();

              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>  PDFScreen(item: 4,)),
              );
            },
            child: Container(
              width: 22,
              height: 22,
              margin: EdgeInsets.only(right: 10),
              child: Image.asset('assets/pdf_icon.png'),
            ),
          )
        ],
      ),
      body: SafeArea(
        top: false,
         child:Container(
          width: widthScreen,
          height: heightScreen,
           color: Colors.white,
            child: SingleChildScrollViewWithStickyFirstWidget(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children:  [
              Utils.getDistanceBar(),

              /*ClipRRect(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0),bottomRight: Radius.circular(0)),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Utils.getThemeColorBlue(), //(x,y)
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        width: 50,
                        height: 50,
                        child: InkWell(
                          child: Icon(Icons.arrow_back,
                              color: Colors.white, size: 30),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Expanded(
                        child: Container(
                            margin: EdgeInsets.only(left: 5),
                            child: Text(
                              "Birds Health Report".tr(),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600),
                            )),
                      ),
                      if(!Platform.isIOS)

                        InkWell(
                        onTap: () {

                          Utils.setupInvoiceInitials("Birds Health Report".tr(),pdf_formatted_date_filter);
                          prepareListData();

                          generateHealthReportExcel(Utils.vaccine_report_list.length.toString(), Utils.medication_report_list.length.toString(), Utils.medication_report_list, Utils.vaccine_report_list);

                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          margin: EdgeInsets.only(right: 10),
                          child: Image.asset('assets/excel_icon.png'),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Utils.setupInvoiceInitials("Birds Health Report".tr(),pdf_formatted_date_filter);
                          prepareListData();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>  PDFScreen(item: 4,)),
                          );
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          margin: EdgeInsets.only(right: 10),
                          child: Image.asset('assets/pdf_icon.png'),
                        ),
                      )
                    ],
                  ),
                ),
              ),
*/
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 45,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(left: 10),
                      margin: EdgeInsets.only(left: 10,right: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Utils.getThemeColorBlue().withOpacity(0.1), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        /*border: Border.all(
                          color: Utils.getThemeColorBlue(),
                          width: 1.2,
                        ),*/
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: getDropDownList(),
                    ),
                  ),
                 InkWell(
                    onTap: () {
                      openDatePicker();
                    },
                    borderRadius: BorderRadius.circular(8), // Adds ripple effect with rounded edges
                    child: Container(
                      height: 45,
                      margin: EdgeInsets.only(right: 10, top: 10, bottom: 10),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Utils.getThemeColorBlue().withOpacity(0.1), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                       /* border: Border.all(
                          color: Utils.getThemeColorBlue(),
                          width: 1.2,
                        ),*/
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, color: Utils.getThemeColorBlue(), size: 18),
                          SizedBox(width: 8),
                          Text(
                            date_filter_name.tr(),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_drop_down, color: Utils.getThemeColorBlue(), size: 20),
                        ],
                      ),
                    ),
                  )
                ],
              ),

              Container(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    SizedBox(height: 12),

                    // Health Chart Container
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Text(
                            date_filter_name.tr(),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),

                          // Chart Widget
                          SfCartesianChart(
                            primaryXAxis: CategoryAxis(),
                            zoomPanBehavior: _zoomPanBehavior,
                            legend: Legend(isVisible: true, position: LegendPosition.bottom),
                            tooltipBehavior: TooltipBehavior(enable: true),
                            series: <CartesianSeries<Health_Chart_Item, String>>[
                              ColumnSeries(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                color: Colors.orange,
                                name: 'Medication'.tr(),
                                dataSource: medlist,
                                xValueMapper: (Health_Chart_Item collItem, _) => collItem.date,
                                yValueMapper: (Health_Chart_Item collItem, _) => collItem.total,
                              ),
                              ColumnSeries(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                                color: Colors.deepOrange,
                                name: 'Vaccination'.tr(),
                                dataSource: vaclist,
                                xValueMapper: (Health_Chart_Item collItem, _) => collItem.date,
                                yValueMapper: (Health_Chart_Item collItem, _) => collItem.total,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Section
                            Text("Summary & Analytics".tr(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue())),
                            SizedBox(height: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildSummaryBox('Vaccination'.tr(), vac_count, Colors.green, Icons.vaccines),
                                _buildSummaryBox('Medication'.tr(), med_count, Colors.red, Icons.medical_services),
                                _buildSummaryBox('TOTAL'.tr(), total_health_count, Utils.getThemeColorBlue(), Icons.calculate, isBold: true),
                              ],
                            ),
                            SizedBox(height: 16),
                            Divider(thickness: 1.5),

                            // Flock Records Section
                            Text('By Flock Name'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Column(
                              children: groupedList.map((group) {
                                int vaccinationCount = group.records.where((r) => r.type == "Vaccination").length;
                                int medicationCount = group.records.where((r) => r.type == "Medication").length;

                                // Group diseases with their respective medicines and type
                                Map<String, List<Map<String, String>>> diseaseDetails = {};

                                for (var record in group.records) {
                                  if (record.disease.isNotEmpty) {
                                    if (!diseaseDetails.containsKey(record.disease)) {
                                      diseaseDetails[record.disease] = [];
                                    }
                                    diseaseDetails[record.disease]!.add({
                                      "type": record.type.tr(),      // Vaccination or Medication
                                      "medicine": record.medicine.tr()
                                    });
                                  }
                                }

                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 3,
                                  margin: EdgeInsets.symmetric(vertical: 6),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Flock Name
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              group.flockName,
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                            ),
                                            Row(
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.vaccines, color: Colors.green, size: 20),
                                                    SizedBox(width: 4),
                                                    Text("$vaccinationCount", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.green)),
                                                  ],
                                                ),
                                                SizedBox(width: 6),
                                                Row(
                                                  children: [
                                                    Icon(Icons.medical_services, color: Colors.red, size: 20),
                                                    SizedBox(width: 4),
                                                    Text("$medicationCount", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: 10),

                                        // Disease and Medicines List
                                        if (diseaseDetails.isNotEmpty) ...[
                                          Divider(),
                                          Text("Disease".tr()+" & "+ "TREATMENT".tr(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                                          SizedBox(height: 6),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: diseaseDetails.entries.map((entry) {
                                              return Padding(
                                                padding: EdgeInsets.symmetric(vertical: 4),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Icon(Icons.coronavirus, color: Colors.orange, size: 18),
                                                        SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            "Disease".tr()+" : "+ "${entry.key}".tr(),  // Disease Name with label
                                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(height: 4),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: entry.value.map((detail) {
                                                        return Padding(
                                                          padding: EdgeInsets.only(left: 26), // Indent under disease name
                                                          child: Row(
                                                            children: [
                                                              Text(
                                                                "[${detail['type']}]".tr(), // Show type: Vaccination or Medication
                                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blue),
                                                              ),
                                                              SizedBox(width: 6),
                                                              Expanded(
                                                                child: Text(
                                                                  detail['medicine']!.tr(), // Medicine Name
                                                                  style: TextStyle(fontSize: 14, color: Colors.black87),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),



                          ],
                        ),
                      ),
                    ),

                    _buildTopItemsGrid("Top Diseases".tr(), topDiseases, Icons.warning_amber_rounded, Colors.orange),
                    SizedBox(height: 12),
                    _buildTopItemsGrid("Top Medicine".tr(), topMedicines, Icons.medication, Colors.purple),
                  ],
                ),
              )

            ]
      ),),),),);
  }

  Widget _buildTopItemsGrid<T>(String title, List<T> items, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with Icon
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                SizedBox(width: 10),
                Text(
                  title.tr(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Dynamic Staggered Grid using Wrap
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items.map((item) {
                String name;
                int count;

                if (item is TopDisease) {
                  name = item.disease;
                  count = item.count;
                } else if (item is TopMedicine) {
                  name = item.medicine;
                  count = item.count;
                } else {
                  return SizedBox(); // Invalid type
                }

                return Container(
                  width: 150, // Set width dynamically
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    /*border: Border.all(color: color, width: 1),*/
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_hospital, color: color, size: 20),
                      SizedBox(height: 6),
                      Text(
                        name.tr(),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "($count)",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSummaryBox(String title, int count, Color color, IconData icon, {bool isBold = false}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between elements
          children: [
            // Left Section: Icon + Title
            Row(
              children: [
                Icon(icon, color: color, size: 30), // Icon
                SizedBox(width: 10),
                Text(
                  title.tr(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ],
            ),

            // Right Section: Count Value
            Text(
              "$count",
              style: TextStyle(
                fontSize: 22,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //FILTER WORK
  List<Flock> flocks = [];
  String _purposeselectedValue = "";
  List<String> _purposeList = [];
  void getList() async {

    await DatabaseHelper.instance.database;

    flocks = await DatabaseHelper.getFlocks();

    flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1, flock_new: 1));

    for(int i=0;i<flocks.length;i++){
      _purposeList.add(flocks.elementAt(i).f_name);
    }

    _purposeselectedValue = _purposeList[0];

    setState(() {

    });

  }

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
            getAllData();

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
      height: filterList.length * 55, // Change as per your requirement
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

              Navigator.pop(bcontext);
              getData(date_filter_name);

            },
            child: ListTile(
              title: Text(filterList.elementAt(index).tr()),
            ),
          );
        },
      ),
    );
  }

  List<String> filterList = ['TODAY','YESTERDAY','THIS_MONTH', 'LAST_MONTH','LAST3_MONTHS', 'LAST6_MONTHS','THIS_YEAR',
    'LAST_YEAR','ALL_TIME','DATE_RANGE'];

  String date_filter_name = 'THIS_MONTH';
  String pdf_formatted_date_filter = 'THIS_MONTH';
  String str_date='',end_date='';
  void getData(String filter){
    int index = 0;

    if (filter == 'TODAY'){
      index = 0;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = 'TODAY'.tr()+" ("+Utils.getFormattedDate(str_date)+")";

      getAllData();
    }
    else if (filter == 'YESTERDAY'){
      index = 1;
      DateTime today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day -1);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(today);
      end_date = inputFormat.format(today);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = "YESTERDAY".tr() + " ("+Utils.getFormattedDate(str_date)+")";
      getAllData();
    }
    else if (filter == 'THIS_MONTH'){
      index = 2;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month + 1).subtract(Duration(days: 1));

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'THIS_MONTH'.tr()+" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST_MONTH'){
      index = 3;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -1, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month  -1,30);


      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'LAST_MONTH'.tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST3_MONTHS'){
      index = 4;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -2, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "LAST3_MONTHS".tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST6_MONTHS'){
      index = 5;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month -5, 1);

      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = "LAST6_MONTHS".tr()+" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'THIS_YEAR'){
      index = 6;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year, DateTime.now().month,DateTime.now().day);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);

      pdf_formatted_date_filter = 'THIS_YEAR'.tr()+ " ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'LAST_YEAR'){
      index = 7;
      DateTime firstDayCurrentMonth = DateTime.utc(DateTime.now().year-1,1,1);
      DateTime lastDayCurrentMonth = DateTime.utc(DateTime.now().year-1, 12,31);

      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date = inputFormat.format(firstDayCurrentMonth);
      end_date = inputFormat.format(lastDayCurrentMonth);
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'LAST_YEAR'.tr() +" ("+Utils.getFormattedDate(str_date)+"-"+Utils.getFormattedDate(end_date)+")";
      getAllData();
    }else if (filter == 'ALL_TIME'){
      index = 8;
      var inputFormat = DateFormat('yyyy-MM-dd');
      str_date ="1950-01-01";
      end_date = inputFormat.format(DateTime.now());;
      print(str_date+" "+end_date);


      pdf_formatted_date_filter = 'ALL_TIME';
      getAllData();
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
      date_filter_name = Utils.getFormattedDate(str_date) +" | "+Utils.getFormattedDate(end_date);
      print(str_date+" "+end_date);
      getAllData();

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

  void prepareListData() {

    Utils.TOTAL_MEDICATIONS = med_count.toString();
    Utils.TOTAL_VACCINATIONS = vac_count.toString();

    Utils.medication_report_list.clear();
    Utils.vaccine_report_list.clear();
    for(int i=0;i<list.length;i++){

      Vaccination_Medication vaccination_medication = list.elementAt(i);
      if(vaccination_medication.type == 'Medication'){
        Utils.medication_report_list.add(Health_Report_Item(f_name: vaccination_medication.f_name.tr(), date: Utils.getFormattedDate(vaccination_medication.date), medicine_name: vaccination_medication.medicine.tr(), disease_name: vaccination_medication.disease.tr(), birds: vaccination_medication.bird_count.toString()));
      }else{
        Utils.vaccine_report_list.add(Health_Report_Item(f_name: vaccination_medication.f_name.tr(), date: Utils.getFormattedDate(vaccination_medication.date), medicine_name: vaccination_medication.medicine.tr(), disease_name: vaccination_medication.disease.tr(), birds: vaccination_medication.bird_count.toString()));

      }
    }

  }



  List<TopDisease> getTopDiseases(List<Vaccination_Medication> records) {
  Map<String, int> diseaseCount = {};

  for (var record in records) {
  diseaseCount[record.disease] = (diseaseCount[record.disease] ?? 0) + 1;
  }

  // Convert to List<TopDisease> and sort
  List<TopDisease> sortedDiseases = diseaseCount.entries
      .map((entry) => TopDisease(disease: entry.key, count: entry.value))
      .toList()
  ..sort((a, b) => b.count.compareTo(a.count));

  return sortedDiseases.length > 5 ? sortedDiseases.take(5).toList() : sortedDiseases;
  }

  List<TopMedicine> getTopMedicines(List<Vaccination_Medication> records) {
  Map<String, int> medicineCount = {};

  for (var record in records) {
  medicineCount[record.medicine] = (medicineCount[record.medicine] ?? 0) + 1;
  }

  // Convert to List<TopMedicine> and sort
  List<TopMedicine> sortedMedicines = medicineCount.entries
      .map((entry) => TopMedicine(medicine: entry.key, count: entry.value))
      .toList()
  ..sort((a, b) => b.count.compareTo(a.count));

  return sortedMedicines.length > 5 ? sortedMedicines.take(5).toList() : sortedMedicines;
  }


}

class VaccinationGrouped {
  final String flockName;
  final List<Vaccination_Medication> records;

  VaccinationGrouped({required this.flockName, required this.records});
}

class TopDisease {
  String disease;
  int count;

  TopDisease({required this.disease, required this.count});
}

class TopMedicine {
  String medicine;
  int count;

  TopMedicine({required this.medicine, required this.count});
}

