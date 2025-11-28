import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/finance_report_item.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:poultary/pdf/pdf_screen.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'model/finance_chart_data.dart';
import 'model/finance_summary_flock.dart';
import 'model/flock.dart';

class FinanceReportsScreen extends StatefulWidget {
  const FinanceReportsScreen({Key? key}) : super(key: key);

  @override
  _FinanceReportsScreen createState() => _FinanceReportsScreen();
}
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _FinanceReportsScreen extends State<FinanceReportsScreen> with SingleTickerProviderStateMixin{

  double widthScreen = 0;
  double heightScreen = 0;

  @override
  void dispose() {
    super.dispose();

  }

  List<_SalesData> data = [];

  List<_SalesData> data1 = [];

  late ZoomPanBehavior _zoomPanBehavior;

  int _reports_filter = 2;
  void getFilters() async {

    _reports_filter = (await SessionManager.getReportFilter())!;
    date_filter_name = filterList.elementAt(_reports_filter);
    getData(date_filter_name);
  }

  @override
  void initState() {
    super.initState();
     try
     {
       date_filter_name = "THIS_MONTH";
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
     catch(ex){
       print(ex);
     }
    Utils.setupAds();

  }

  List<TransactionItem> list = [];
  List<Finance_Chart_Item> incomeChartData = [];
  List<Finance_Chart_Item> expenseChartData = [];
  List<String> flock_name = [];

  num gross_income = 0;
  num total_expense = 0;
  num net_income = 0;

  void clearValues(){

     gross_income = 0;
     total_expense = 0;
     net_income = 0;
     list = [];

  }

  List<FlockIncomeExpense> flockFinanceList = [];
  void getAllData() async{

    await DatabaseHelper.instance.database;

    clearValues();

    gross_income = await DatabaseHelper.getTransactionsTotal(f_id, "Income", str_date, end_date);
    total_expense = await DatabaseHelper.getTransactionsTotal(f_id, "Expense", str_date, end_date);

    print(gross_income);
    print(total_expense);
    print(net_income);

    net_income = gross_income - total_expense;

    gross_income = num.parse(gross_income.toStringAsFixed(2));
    total_expense = num.parse(total_expense.toStringAsFixed(2));
    net_income = num.parse(net_income.toStringAsFixed(2));

    getFilteredEggsCollections(str_date, end_date);

    setState(() {

    });

  }

  void getFilteredEggsCollections(String st,String end) async {

    await DatabaseHelper.instance.database;

    List<String> dates = [];
    List<Intl> amount = [];
    double tamount = 0;
    int added = -1;
    flockFinanceList = (await DatabaseHelper.getFlockWiseIncomeExpense(st, end))!;
    if(f_id != -1) {
      List<FlockIncomeExpense> singleFlockList = [];
     for(int i=0;i<flockFinanceList.length;i++){
       if(flockFinanceList.elementAt(i).fId == f_id)
         singleFlockList.add(flockFinanceList.elementAt(i));
     }
      Utils.flockfinanceList = singleFlockList;
    }
    else
    {
      Utils.flockfinanceList = flockFinanceList;
    }

    list = await DatabaseHelper.getReportFilteredTransactions(f_id,"All",st,end);
    incomeChartData = await DatabaseHelper.getFinanceChartData(f_id,st, end,"Income");
    expenseChartData = await DatabaseHelper.getFinanceChartData(f_id,st, end,"Expense");

    topIncomeItems = (await DatabaseHelper.getTopIncomeItems(f_id,st,end))!;
    topExpenseItems = (await DatabaseHelper.getTopExpenseItems(f_id,st,end))!;

    Utils.incomeItems = topIncomeItems;
    Utils.expenseItems = topExpenseItems;

    for(int j=0;j<expenseChartData.length;j++){
      expenseChartData.elementAt(j).date = Utils.getFormattedDate(expenseChartData.elementAt(j).date).substring(0,Utils.getFormattedDate(expenseChartData.elementAt(j).date).length-4);
    }

    for(int i=0;i<incomeChartData.length;i++){
      incomeChartData.elementAt(i).date = Utils.getFormattedDate(incomeChartData.elementAt(i).date).substring(0,Utils.getFormattedDate(incomeChartData.elementAt(i).date).length-4);
    }

/*

    for(int i=0;i<list.length;i++){

      if(list.elementAt(i).type == "Income"){

        added = isDateAdded(data, getShortDate(list.elementAt(i).date));
        if(added == -1){
          data.add(new _SalesData(getShortDate(list.elementAt(i).date), double.parse(list.elementAt(i).amount)));

        }else{
          double amt =  data.elementAt(added).sales;
          amt = amt + double.parse(list.elementAt(i).amount);
          data.removeAt(added);
          data.add(new _SalesData(getShortDate(list.elementAt(i).date), amt));

        }
      }
     */
/* else{
        data1.add(new _SalesData(getShortDate(list.elementAt(i).date), double.parse(list.elementAt(i).amount)));
        data.add(new _SalesData(getShortDate(list.elementAt(i).date), 0));
       *//*
*/
/* if(isDateAdded(data, getShortDate(list.elementAt(i).date)) == -1){
          data.add(new _SalesData(getShortDate(list.elementAt(i).date), 0));
        }*//*
*/
/*
      }*//*


    }


    for(int j =0;j<data.length;j++){
      print("INCOME $j "+data.elementAt(j).sales.toString());
      //print("EXPENSE "+data1.elementAt(j).year);
    }
*/

   /* setState(() {

    });*/

    setState(() {

    });

  }

  String getShortDate(String tdate){
    
    print(tdate);
    int l = tdate.characters.length;
    String sdate = Utils.getFormattedDate(tdate).substring(0,l-4);

     print(sdate);
     return sdate;
  }

  int isDateAdded(List<_SalesData> dlist, String tdate){
    int t = -1;
    for(int i=0;i<dlist.length;i++){
      if(dlist.elementAt(i).year == tdate){
        t = i;
        break;
      }
    }

    return t;
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

    return SafeArea(child: Scaffold(
      body:SafeArea(
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

              ClipRRect(
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
                              "Financial Report".tr(),
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

                          Utils.setupInvoiceInitials("Financial Report".tr(),pdf_formatted_date_filter);
                          prepareListData();
                          generateFinanceSummaryExcel(Utils.flockfinanceList!, Utils.incomeItems!, Utils.expenseItems!);

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
                          Utils.setupInvoiceInitials("Financial Report".tr(),pdf_formatted_date_filter);
                          prepareListData();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>  PDFScreen(item: 3,)),
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
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 45,
                      margin: EdgeInsets.only(right: 10, top: 10, bottom: 10),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Utils.getThemeColorBlue().withOpacity(0.1), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),

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
                  ),
                ]
              ),

              Container(
                color: Colors.white,
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [

                    SizedBox(height: 10),
                    // Income vs Expense chart
                    SfCartesianChart(
                      primaryXAxis: CategoryAxis(),
                      zoomPanBehavior: _zoomPanBehavior,
                      title: ChartTitle(text: date_filter_name.tr()),
                      legend: Legend(isVisible: true, position: LegendPosition.bottom),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <CartesianSeries<Finance_Chart_Item, String>>[
                        ColumnSeries(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Colors.green,
                          name: 'Income'.tr(),
                          dataSource: incomeChartData,
                          xValueMapper: (Finance_Chart_Item incomeItem, _) => incomeItem.date,
                          yValueMapper: (Finance_Chart_Item incomeItem, _) => incomeItem.amount,
                        ),
                        ColumnSeries(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          color: Colors.red,
                          name: 'Expense'.tr(),
                          dataSource: expenseChartData,
                          xValueMapper: (Finance_Chart_Item expenseItem, _) => expenseItem.date,
                          yValueMapper: (Finance_Chart_Item expenseItem, _) => expenseItem.amount,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Financial Summary
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Overall Summary
                            Text(
                              "Summary & Analytics".tr(),
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            SizedBox(height: 12),

                            _buildSummaryRow(Icons.arrow_upward, 'GROSS_INCOME'.tr(), gross_income, Colors.green),
                            Divider(thickness: 1.2),
                            _buildSummaryRow(Icons.arrow_downward, 'TOTAL_EXPENSE'.tr(), -total_expense, Colors.red),
                            Divider(thickness: 1.2),
                            _buildSummaryRow(Icons.account_balance_wallet, 'NET_INCOME'.tr(), net_income, Utils.getThemeColorBlue(), fontSize: 20),

                            SizedBox(height: 10),

                           if(f_id==-1)
                             Column(
                              children: flockFinanceList.map((flock) => _buildFlockRow(flock)).toList(),
                            ),
                            SizedBox(height: 10),

                            // 📊 Top Income Items
                            Text(
                              'Top Income Sources'.tr(),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            SizedBox(height: 8),
                            Column(
                              children: topIncomeItems.map((item) => _buildItemRow(item, Colors.green)).toList(),
                            ),

                            SizedBox(height: 15),

                            // 📉 Top Expense Items
                            Text(
                              'Top Expenses'.tr(),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                            ),
                            SizedBox(height: 8),
                            Column(
                              children: topExpenseItems.map((item) => _buildItemRow(item, Colors.red)).toList(),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ]
      ),),),),),);
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

  // 🔹 Item Row UI (for Income & Expense)
  Widget _buildItemRow(FinancialItem item, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.symmetric(vertical: 6),
      color: Colors.grey[100],
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(item.icon, color: color, size: 22),
                SizedBox(width: 8),
                Text(
                  item.name.tr(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
            Text(
              Utils.currency + item.amount.toStringAsFixed(2),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // 🔸 Summary Row UI
  Widget _buildSummaryRow(IconData icon, String label, num amount, Color color, {double fontSize = 16}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 22),
            SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black)),
          ],
        ),
        Text(
          Utils.currency + amount.toStringAsFixed(2),
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  // 🔸 Flock-wise Row UI
  Widget _buildFlockRow(FlockIncomeExpense flock) {
    double netProfit = flock.totalIncome - flock.totalExpense;
    double profitMargin = flock.totalIncome == 0 ? 0 : (netProfit / flock.totalIncome) * 100;
    bool isProfitable = netProfit >= 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🐔 Flock Name & Growth Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  flock.fName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Row(
                  children: [
                    Icon(
                      isProfitable ? Icons.trending_up : Icons.trending_down,
                      color: isProfitable ? Colors.green : Colors.red,
                      size: 22,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '${profitMargin.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isProfitable ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),

            // 🔹 Income & Expense Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFlockDetail(Icons.arrow_upward, 'Income', flock.totalIncome, Colors.green),
                _buildFlockDetail(Icons.arrow_downward, 'Expense', flock.totalExpense, Colors.red),
                _buildFlockDetail(Icons.account_balance_wallet, 'NET_INCOME', netProfit, isProfitable ? Colors.blue : Colors.red),
              ],
            ),

            SizedBox(height: 10),

            // 📊 Profitability Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (profitMargin.clamp(0, 100)) / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(isProfitable ? Colors.green : Colors.red),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Flock Detail (Income, Expense, Net Profit)
  Widget _buildFlockDetail(IconData icon, String label, double amount, Color color) {
    return Column(
      children: [

        SizedBox(height: 4),
        Text(
          label.tr(),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54),
        ),
        SizedBox(height: 4),
        Text(
          '${Utils.currency}${amount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
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

  // 📝 Example Data
  List<FinancialItem> topIncomeItems = [
  ];

  List<FinancialItem> topExpenseItems = [
  ];


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

      pdf_formatted_date_filter = 'ALL_TIME'.tr();
      getAllData();
    }else if (filter == 'DATE_RANGE'){
      _pickDateRange();
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

    Utils.TOTAL_INCOME = gross_income.toString();
    Utils.TOTAL_EXPENSE = total_expense.toString();
    Utils.NET_INCOME = net_income.toString();

    Utils.finance_report_list.clear();

    print("LIST ${list.length}");

    for(int i=0;i<list.length;i++){

      print("$i ${list.elementAt(i).f_name}");
      TransactionItem transactionItem = list.elementAt(i);
      Utils.finance_report_list.add(Finance_Report_Item(f_name: transactionItem.f_name, date: Utils.getFormattedDate(transactionItem.date), salePurchaseItem: transactionItem.type == 'Income'? transactionItem.sale_item : transactionItem.expense_item, income:  transactionItem.type == 'Income'? transactionItem.amount : '0', expense:  transactionItem.type == 'Income'? '0' : transactionItem.amount));

    }

  }


  Future<void> saveAndShareExcel(Excel excel) async {
    final downloadsDir = Directory("/storage/emulated/0/Download");
    String formattedDate = DateFormat('dd_MMM_yyyy_HH_mm').format(DateTime.now());
    String filePath = "${downloadsDir.path}/financial_report_$formattedDate.xlsx";

    final file = File(filePath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    Utils.showToast("Saved to Downloads: financial_report_$formattedDate.xlsx");

    // ✅ Share/Open the file safely
    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Finance report exported successfully!",
    );
  }


  Future<void> generateFinanceSummaryExcel(
      List<FlockIncomeExpense> flockIncomeExpenseList,
      List<FinancialItem> topIncomeSources,
      List<FinancialItem> topExpenses,
      ) async
  {
    var excel = Excel.createExcel();
    var sheet = excel['Financial Report'.tr()];

    // ==== Define Styles ====
    var titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.fromHexString("#1F4E78"), // dark blue title
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    var sectionTitleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.fromHexString("#BDD7EE"), // section blue
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    var headerStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.black,
      backgroundColorHex: ExcelColor.fromHexString("#B7DEE8"), // light blue header
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
        .value = TextCellValue("Financial Report".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = titleStyle;

    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));

    row += 2;

    // ==== Overall Summary ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("SUMMARY".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));

    row++;

    List<String> summaryHeaders = [
      "GROSS_INCOME".tr()+"(${Utils.currency})",
      "GROSS_EXPENSE".tr()+"(${Utils.currency})",
      "NET_INCOME".tr()+"(${Utils.currency})",
    ];
    for (int i = 0; i < summaryHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .value = TextCellValue(summaryHeaders[i]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }

    row++;

    sheet.appendRow([
      TextCellValue(Utils.TOTAL_INCOME),
      TextCellValue(Utils.TOTAL_EXPENSE),
      TextCellValue(Utils.NET_INCOME),
    ]);

    row += 2;

    // ==== Income & Expense by Flock ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("By Flock".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));

    row++;

    List<String> flockHeaders = [
      "Flock Name".tr(),
      "GROSS_INCOME".tr()+"(${Utils.currency})",
      "GROSS_EXPENSE".tr()+"(${Utils.currency})",
      "NET_INCOME".tr()+"(${Utils.currency})",
    ];
    for (int i = 0; i < flockHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .value = TextCellValue(flockHeaders[i]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }

    row++;

    for (var f in flockIncomeExpenseList) {
      double netIncome = f.totalIncome - f.totalExpense;
      sheet.appendRow([
        TextCellValue(f.fName),
        DoubleCellValue(f.totalIncome),
        DoubleCellValue(f.totalExpense),
        DoubleCellValue(netIncome),
      ]);

      for (int i = 1; i < 4; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
            .cellStyle = numberStyle;
      }
      row++;
    }

    row += 2;

    // ==== Top Income Sources ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("Top Income Sources".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));

    row++;

    List<String> incomeHeaders = ["Item Name".tr(), "Amount".tr()+"(${Utils.currency})"];
    for (int i = 0; i < incomeHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .value = TextCellValue(incomeHeaders[i]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }

    row++;

    for (var inc in topIncomeSources) {
      sheet.appendRow([
        TextCellValue(inc.name.tr()),
        DoubleCellValue(inc.amount),
      ]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .cellStyle = numberStyle;
      row++;
    }

    row += 2;

    // ==== Top Expenses ====
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue("Top Expenses".tr());
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = sectionTitleStyle;
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));

    row++;

    List<String> expenseHeaders = ["Item Name".tr(), "Amount".tr()+"(${Utils.currency})"];
    for (int i = 0; i < expenseHeaders.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .value = TextCellValue(expenseHeaders[i]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
          .cellStyle = headerStyle;
    }

    row++;

    for (var exp in topExpenses) {
      sheet.appendRow([
        TextCellValue(exp.name.tr()),
        DoubleCellValue(exp.amount),
      ]);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .cellStyle = numberStyle;
      row++;
    }

    // === Auto-adjust column widths (same logic as egg report) ===
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





}

class _SalesData {
  _SalesData(this.year, this.sales);

   String year;
   double sales;
}

// 🔹 Model Class for Financial Item
class FinancialItem {
  final String name;
  final double amount;
  final IconData icon;

  FinancialItem({required this.name, required this.amount, required this.icon});
}



