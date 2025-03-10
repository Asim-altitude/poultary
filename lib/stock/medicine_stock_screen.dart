import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/model/sub_category_item.dart';

import '../database/databse_helper.dart';
import '../model/medicine_stock_history.dart';
import '../model/medicine_stock_summary.dart';
import '../model/transaction_item.dart';
import '../utils/utils.dart';
import 'medicine_stock_details.dart';

class MedicineStockScreen extends StatefulWidget {
  int id;

  MedicineStockScreen({Key? key, required this.id}) : super(key: key);


  @override
  _MedicineStockScreenState createState() => _MedicineStockScreenState();
}

class _MedicineStockScreenState extends State<MedicineStockScreen> {
  List<MedicineStockSummary>? _stockSummary = [];
  List<String> uniqueMedicineNames = [];

  @override
  void initState() {
    super.initState();
    createTables();
  }

  void createTables() async {
    await DatabaseHelper.instance.database;
    await DatabaseHelper.createMedicineStockHistoryTable();
    fetchStockSummary();
  }

  void fetchStockSummary() async {
    List<MedicineStockSummary> updatedStock = await DatabaseHelper.getMedicineStockSummary();

    for (var newItem in updatedStock) {
      if (!_stockSummary!.any((item) => item.medicineName == newItem.medicineName && item.unit == newItem.unit)) {
        int newIndex = _stockSummary!.length;
        _stockSummary!.add(newItem);
        _listKey.currentState?.insertItem(newIndex);
      }
    }

    uniqueMedicineNames = updatedStock.map((e) => e.medicineName).toSet().toList();
    setState(() {});
  }

  void _showAddStockDialog() async {
    bool? stockAdded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddMedicineStockBottomSheet(onStockAdded: () {}, id: widget.id,),
    );

    if (stockAdded == true) {
      List<MedicineStockSummary> updatedStock = await DatabaseHelper.getMedicineStockSummary();

      for (var newItem in updatedStock) {
        if (!_stockSummary!.any((item) => item.medicineName == newItem.medicineName && item.unit == newItem.unit)) {
          int newIndex = _stockSummary!.length;
          _stockSummary!.add(newItem);
          _listKey.currentState?.insertItem(newIndex);
        }
      }
      setState(() {});
    }
  }

  Widget _buildStockItem(MedicineStockSummary stock, int index, Animation<double> animation) {
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
                      stock.medicineName +" (${stock.unit})",
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
                      Text("Total Stock: ${stock.totalStock} ${stock.unit}", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      SizedBox(height: 4),
                      Text("Used Stock: ${stock.usedStock} ${stock.unit}", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
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
                        "Available: ${stock.availableStock} ${stock.unit}",
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
                        "⚠️ LOW STOCK",
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
            bottomLeft: Radius.circular(20.0), // Round bottom-left corner
            bottomRight: Radius.circular(20.0), // Round bottom-right corner
          ),
          child: AppBar(
            title: Text(
              "Medicine Stock Summary",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Utils.getThemeColorBlue(), // Customize the color
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
      body: _stockSummary!.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "No medicine stock available!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: 5),
            Text("Add stock to see details.", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      )
          : AnimatedList(
        key: _listKey,
        initialItemCount: _stockSummary!.length,
        itemBuilder: (context, index, animation) {
          return InkWell(
            onTap: () async {
              List<MedicineStockHistory> history = await DatabaseHelper.fetchMedicineStockHistory(_stockSummary![index].medicineName, _stockSummary![index].unit);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MedicineStockDetailScreen(stock: _stockSummary![index], stockHistory: history),
                ),
              );
              fetchStockSummary();
            },
            child: _buildStockItem(_stockSummary![index], index, animation),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStockDialog,
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

    String finalSource = _selectedSource == "Other" ? _otherSourceController.text : _selectedSource!;
    double? amount = _selectedSource == "Purchased" && _amountController.text.isNotEmpty
        ? double.tryParse(_amountController.text)
        : null;

    MedicineStockHistory stock = MedicineStockHistory(
      quantity: double.parse(_quantityController.text),
      unit: _selectedUnit!,
      source: finalSource,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      medicineId: getMedicineIdbyName(), medicineName: _selectedMedicine!,

    );

    await DatabaseHelper.insertMedicineStock(stock);
    widget.onStockAdded();

    if(!_amountController.text.isEmpty){
      TransactionItem transaction_item = TransactionItem(
          f_id: -1,
          date: DateFormat('yyyy-MM-dd').format(_selectedDate),
          sale_item: "",
          expense_item: "Medicine Purchase",
          type: "Expense",
          amount: _amountController.text,
          payment_method: "Cash",
          payment_status: "Cleared",
          sold_purchased_from: "Market",
          short_note: "$_selectedMedicine Purchase made on ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
          how_many: _quantityController.text,
          extra_cost: "",
          extra_cost_details: "",
          f_name: "Farm Wide",
          flock_update_id: '-1');
      int? id = await DatabaseHelper
          .insertNewTransaction(transaction_item);
    }
    Navigator.pop(context, true);
  }

  bool isRequired = false;
  List<String> _sourceList = ["Purchased", "Gift", "Other"];
  List<String> _unitList = ["Tab","Cap","mg","g","kg","Vial","ml","L","Dust"];


  int getMedicineIdbyName() {
    return _subItems.firstWhere((med) => med.name == _selectedMedicine).id!;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              "Add Medicine Stock",
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
              hintText: "Select Medicine",
              value: _selectedMedicine,
              items: _medicineList,
              onChanged: (value) => setState(() => _selectedMedicine = value),
              icon: Icons.medication,
            ),
            SizedBox(height: 12),

            // Quantity and Unit in the same line
            _buildTextField(
              controller: _quantityController,
              label: "Quantity",
              icon: Icons.production_quantity_limits,
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 12),

            // Unit Selection (Tablets, mL, mg, etc.)
            _buildDropdown(
              hintText: "Select Unit",
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
              hintText: "Select Source",
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
            if (_selectedSource == "Other")
              _buildTextField(
                controller: _otherSourceController,
                label: "Enter Other Source",
                icon: Icons.create,
              ),

            // Purchase Amount Input (Only visible if "Purchased" is selected)
            if (_selectedSource == "Purchased")
              _buildTextField(
                controller: _amountController,
                label: "Enter Purchase Amount",
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
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
                child: Text("Add Stock", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
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
        hint: Text(hintText, style: TextStyle(color: Colors.black54)),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
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
