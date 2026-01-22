import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poultary/model/sub_category_item.dart';
import 'package:poultary/model/vaccine_stock_history.dart';
import 'package:poultary/model/vaccine_stock_summary.dart';
import 'package:poultary/stock/vaccine_stock_details.dart';

import '../database/databse_helper.dart';
import '../model/medicine_stock_history.dart';
import '../model/medicine_stock_summary.dart';
import '../model/stock_expense.dart';
import '../model/transaction_item.dart';
import '../multiuser/model/vaccinestockfb.dart';
import '../multiuser/utils/FirebaseUtils.dart';
import '../multiuser/utils/RefreshMixin.dart';
import '../multiuser/utils/SyncStatus.dart';
import '../utils/fb_analytics.dart';
import '../utils/utils.dart';
import 'medicine_stock_details.dart';

class VaccineStockScreen extends StatefulWidget {
  int id;

  VaccineStockScreen({Key? key, required this.id}) : super(key: key);


  @override
  _MedicineStockScreenState createState() => _MedicineStockScreenState();
}

class _MedicineStockScreenState extends State<VaccineStockScreen> with RefreshMixin {

  @override
  void onRefreshEvent(String event) {
    try {
      if (event == FireBaseUtils.VACCINE_STOCK_HISTORY)
      {
        fetchStockSummary();
      }
    }
    catch(ex){
      print(ex);
    }
  }

  List<VaccineStockSummary>? _stockSummary = [];
  late BannerAd _bannerAd;
  double _heightBanner = 0;
  bool _isBannerAdReady = false;
  @override
  void initState() {
    super.initState();
    createTables();
    if(Utils.isShowAdd){
      _loadBannerAd();
    }

    AnalyticsUtil.logScreenView(screenName: "vaccine_screen");
  }
  @override
  void dispose() {
    try{
      _bannerAd.dispose();
    }catch(ex){

    }
    super.dispose();
  }
  _loadBannerAd(){
    // TODO: Initialize _bannerAd
    _bannerAd = BannerAd(
      adUnitId: Utils.bannerAdUnitId,

      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _heightBanner = 60;
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _heightBanner = 0;
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }
  void createTables() async {
    await DatabaseHelper.instance.database;
    fetchStockSummary();
  }

  void fetchStockSummary() async {
    List<VaccineStockSummary> updatedStock = await DatabaseHelper.getVaccineStockSummary();

    for (var newItem in updatedStock) {
      if (!_stockSummary!.any((item) => item.vaccineName == newItem.vaccineName && item.unit == newItem.unit)) {
        int newIndex = _stockSummary!.length;
        _stockSummary!.add(newItem);
        _listKey.currentState?.insertItem(newIndex);
      }
    }

    setState(() {});
  }


  void _showAddStockDialog() async {
    bool? stockAdded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddMedicineStockBottomSheet(
        onStockAdded: () {},
        id: widget.id,
      ),
    );

    if (stockAdded == true) {
      List<VaccineStockSummary> updatedStock = await DatabaseHelper.getVaccineStockSummary();

      // Find new items and insert them into AnimatedList
      for (var newItem in updatedStock) {
        if (!_stockSummary!.any((item) => item.vaccineName == newItem.vaccineName && item.unit == newItem.unit)) {
          int newIndex = _stockSummary!.length;
          _stockSummary!.add(newItem);
          _listKey.currentState?.insertItem(newIndex);  // Animate insertion
        }
      }

      setState(() {});  // Update UI
    }
  }


  Widget _buildStockItem(VaccineStockSummary stock, int index, Animation<double> animation) {
    double progress = stock.totalStock > 0 ? stock.usedStock / stock.totalStock : 0.0;
    double usedWidth = progress.clamp(0.0, 1.0);
    double remainingWidth = (1 - progress).clamp(0.0, 1.0);
    bool isLowStock = stock.availableStock <= (stock.totalStock * 0.2);

    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        elevation: 6,
        shadowColor: Colors.black26,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      stock.vaccineName.tr() +" (${stock.unit})",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[600], size: 20),
                ],
              ),

              SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Stock".tr()+": ${stock.totalStock} ${stock.unit}", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      SizedBox(height: 4),
                      Text("Used Stock".tr()+": ${stock.usedStock} ${stock.unit}", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    ],
                  ),
                ],
              ),

              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLowStock ? Colors.red : Colors.green.shade700,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.medical_services, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        "Available".tr()+": ${stock.availableStock} ${stock.unit}",
                        style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              if (isLowStock)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 800),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.redAccent, blurRadius: 8, spreadRadius: 2)],
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        "⚠️"+ "LOW STOCK",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                      ),
                    ],
                  ),
                ),

              LayoutBuilder(
                builder: (context, constraints) {
                  double totalWidth = constraints.maxWidth;

                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 18,
                        width: totalWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[300],
                        ),
                      ),

                      AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        width: totalWidth * usedWidth,
                        height: 18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                          gradient: LinearGradient(
                            colors: [Colors.orangeAccent, Colors.red],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),

                      Positioned(
                        left: totalWidth * usedWidth,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          width: totalWidth * remainingWidth,
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
                            gradient: LinearGradient(
                              colors: isLowStock ? [Colors.red, Colors.orange] : [Colors.lightGreen, Colors.green],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: (totalWidth * usedWidth > 10 ? totalWidth * usedWidth - 10 : 0),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: Center(
                            child: Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(0.0), // Round bottom-left corner
            bottomRight: Radius.circular(0.0), // Round bottom-right corner
          ),
          child: AppBar(
            title: Text(
              "Vaccine Stock Summary".tr(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.blue, // Customize the color
            elevation: 8, // Gives it a more elevated appearance
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context); // Navigates back
              },
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Container(
          child: Column(children: [
             if(_isBannerAdReady)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                      height: 60.0,
                      width: Utils.WIDTH_SCREEN,
                      child: AdWidget(ad: _bannerAd)
                  ),
                ),

            _stockSummary!.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "No vaccine stock available!".tr(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  SizedBox(height: 5),
                  Text("Add stock to see details.".tr(), style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            )
                :
            Expanded(child:
            AnimatedList(
              key: _listKey,
              initialItemCount: _stockSummary!.length,
              itemBuilder: (context, index, animation) {
                return InkWell(
                  onTap: () async {
                    List<VaccineStockHistory> history = await DatabaseHelper.fetchVaccineStockHistory(_stockSummary![index].vaccineName, _stockSummary![index].unit);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VaccineStockDetailScreen(stock: _stockSummary![index], stockHistory: history),
                      ),
                    );
                    fetchStockSummary();
                  },
                  child: _buildStockItem(_stockSummary![index], index, animation),
                );
              },
            ),
            ),
              ],),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_health")){
            Utils.showMissingPermissionDialog(context, "add_health");
            return;
          }

          _showAddStockDialog();
        },
        child: Icon(Icons.add),
      ),

    );
  }
}

// Medicine Stock Bottom Sheet
class AddMedicineStockBottomSheet extends StatefulWidget {
  final VoidCallback onStockAdded;
  int id;
  AddMedicineStockBottomSheet({required this.onStockAdded, required this.id});

  @override
  _AddMedicineStockBottomSheetState createState() => _AddMedicineStockBottomSheetState();
}

class _AddMedicineStockBottomSheetState extends State<AddMedicineStockBottomSheet> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _otherSourceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String? _selectedMedicine;
  String? _selectedUnit;
  List<SubItem> _subItems = [];
  List<String> _medicineList = [];
  String? _selectedSource;

  @override
  void initState() {
    super.initState();
    _loadMedicineItems();
  }

  void _loadMedicineItems() async {
    _subItems = await DatabaseHelper.getSubCategoryList(widget.id);
    for(int i=0;i<_subItems.length;i++){
      _medicineList.add(_subItems[i].name!);
    }
    setState(() {});
  }

  /// Open date picker
  DateTime _selectedDate = DateTime.now(); // Default to today

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022), // Set a reasonable range
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _saveStock() async {
    if (_selectedMedicine == null || _quantityController.text.isEmpty
        || _selectedUnit == null || _selectedSource == null ) {
      isRequired = true;
      setState(() {

      });
      return;
    }

    String finalSource = _selectedSource == "OTHER" ? _otherSourceController.text : _selectedSource!;
    double? amount = _selectedSource == "PURCHASED" && _amountController.text.isNotEmpty
        ? double.tryParse(_amountController.text)
        : null;

    VaccineStockHistory stock = VaccineStockHistory(
      quantity: double.parse(_quantityController.text),
      unit: _selectedUnit!,
      source: finalSource,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
       vaccineName: _selectedMedicine!, vaccineId: getMedicineIdbyName(),
        sync_id: Utils.getUniueId(),
        sync_status: SyncStatus.SYNCED,
        last_modified: Utils.getTimeStamp(),
        modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
        farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : ''
    );

    int? stock_item_id = await DatabaseHelper.insertVaccineStock(stock);
    widget.onStockAdded();


    VaccineStockFB vaccineStockFB = VaccineStockFB(stock: stock);

    if(!_amountController.text.isEmpty){
      TransactionItem transaction_item = TransactionItem(
          f_id: -1,
          date: DateFormat('yyyy-MM-dd').format(_selectedDate),
          sale_item: "",
          expense_item: "Vaccine Purchase",
          type: "Expense",
          amount: _amountController.text,
          payment_method: selectedPaymentMethod,
          payment_status: selectedStatus,
          sold_purchased_from: "Unknown",
          short_note: "$_selectedMedicine Purchase made on ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
          how_many: _quantityController.text,
          extra_cost: "",
          extra_cost_details: "",
          f_name: "Farm Wide",
          flock_update_id: '-1',
          sync_id: Utils.getUniueId(),
          sync_status: SyncStatus.SYNCED,
          last_modified: Utils.getTimeStamp(),
          modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
          farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '');

      int? transaction_id = await DatabaseHelper
          .insertNewTransaction(transaction_item);
      StockExpense stockExpense = StockExpense(stockItemId: stock_item_id!, transactionId: transaction_id!);
      await DatabaseHelper.insertStockJunction(stockExpense);

      vaccineStockFB.transaction = transaction_item;
    }

    if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_health")) {
      vaccineStockFB.sync_id = stock.sync_id;
      vaccineStockFB.sync_status = SyncStatus.SYNCED;
      vaccineStockFB.last_modified = Utils.getTimeStamp();
      vaccineStockFB.modified_by =  Utils.isMultiUSer ? Utils.currentUser!.email : '';
      vaccineStockFB.farm_id = Utils.isMultiUSer ? Utils.currentUser!.farmId : '';

      await FireBaseUtils.uploadVaccineStock(vaccineStockFB);
    }

    Navigator.pop(context, true);
  }

  bool isRequired = false;
  List<String> _sourceList = ["PURCHASED", "GIFT", "OTHER"];

  List<String> _unitList = ["Tab","Cap","mg","g","kg","Vial","ml","L","Dust","Drop","Dose","Strip","Packet","Piece","Dozen","Carton","Spoon","Cup","Biscuit"];

  String selectedPaymentMethod = "Cash";
  String selectedStatus = "CLEARED";

  int getMedicineIdbyName() {
    return _subItems.firstWhere((med) => med.name == _selectedMedicine).id!;
  }
  double widthScreen = 0;
  double heightScreen = 0;
  @override
  Widget build(BuildContext context)
  {

    double safeAreaHeight = MediaQuery.of(context).padding.top;
    double safeAreaHeightBottom = MediaQuery.of(context).padding.bottom;
    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height -
        (safeAreaHeight + safeAreaHeightBottom);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                "Add Vaccine Stock".tr(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 5),
      
              if (isRequired)
                Text(
                  "PROVIDE_ALL".tr(),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.red),
                ),
              SizedBox(height: 5),
      
              // Medicine Selection
              _buildDropdown(
                hintText: "Select Vaccine".tr(),
                value: _selectedMedicine,
                items: _medicineList,
                onChanged: (value) => setState(() => _selectedMedicine = value),
                icon: Icons.medication,
              ),
              SizedBox(height: 12),
      
              // Quantity and Unit in the same line
              _buildTextField(
                controller: _quantityController,
                label: "Quantity".tr(),
                icon: Icons.production_quantity_limits,
                keyboardType: TextInputType.number,
              ),
      
              SizedBox(height: 12),
      
              // Unit Selection (Tablets, mL, mg, etc.)
              _buildDropdown(
                hintText: "Select Unit".tr(),
                value: _selectedUnit,
                items: _unitList,
                onChanged: (value) {
                  _selectedUnit = value!;
                },
                icon: Icons.balance,
              ),
              SizedBox(height: 12),
              /// Date Picker
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Utils.getThemeColorBlue()),
                      SizedBox(width: 10),
                      Text(
                        Utils.getFormattedDate(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              // Source Selection
              _buildDropdown(
                hintText: "Select Source".tr(),
                value: _selectedSource,
                items: _sourceList,
                onChanged: (value) => setState(() {
                  _selectedSource = value;
                  _otherSourceController.clear(); // Reset other source input when changing selection
                  _amountController.clear(); // Reset amount when changing selection
                }),
                icon: Icons.storefront,
              ),
              SizedBox(height: 12),
      
              // Other Source Input (Only visible if "Other" is selected)
              if (_selectedSource == "OTHER")
                _buildTextField(
                  controller: _otherSourceController,
                  label: "Enter Other Source".tr(),
                  icon: Icons.create,
                ),
      
              // Purchase Amount Input (Only visible if "Purchased" is selected)
              if (_selectedSource == "PURCHASED")
                Column(
                  children: [
                    _buildTextField(
                      controller: _amountController,
                      label: "Amount".tr(),
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedPaymentMethod,
                      items: ["Cash", "Bank Transfer"].map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method.tr()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedPaymentMethod = value!;
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.payment),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      items: ["CLEARED", "UNCLEAR"].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.tr()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedStatus = value!;
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.verified),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 20),
      
              // Save Button
              Container(
                width: Utils.WIDTH_SCREEN - 20,
                child: ElevatedButton(
                  onPressed: _saveStock,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Utils.getThemeColorBlue(),
                    elevation: 4,
                  ),
                  child: Text("Add Stock".tr(), style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }

  /// Custom Dropdown Widget
  Widget _buildDropdown({
    required String hintText,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Utils.getThemeColorBlue()),
        ),
        hint: Text(hintText.tr(), style: TextStyle(color: Colors.black54)),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item.tr()));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  /// Custom TextField Widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color:  Utils.getThemeColorBlue()),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

}
