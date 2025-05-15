import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poultary/feed_batch_screen.dart';
import 'package:poultary/stock/stock_details_screen.dart';
import 'package:poultary/utils/utils.dart';
import '../database/databse_helper.dart';
import '../model/feed_stock_history.dart';
import '../model/feed_stock_summary.dart';
import '../model/stock_expense.dart';
import '../model/sub_category_item.dart';
import '../model/transaction_item.dart';

class FeedStockScreen extends StatefulWidget {
  @override
  _FeedStockScreenState createState() => _FeedStockScreenState();
}

class _FeedStockScreenState extends State<FeedStockScreen> {
  List<FeedStockSummary>? _stockSummary = [], _batchSummary = [];
  @override
  void initState() {
    super.initState();
    createTables();

  }

  void createTables() async {
    await DatabaseHelper.instance.database;
    fetchStockSummary();
  }
   // Nullable variable

  Future<void> fetchStockSummary() async {
    _stockSummary = await DatabaseHelper.getFeedStockSummary();
    _batchSummary = await DatabaseHelper.getFeedBatchStockSummary();

    for(int i=0;i<_batchSummary!.length;i++){
      _stockSummary?.add(_batchSummary![i]);
    }
    setState(() {}); // Update UI after fetching data
  }

  bool checkIfBatch(String name){
    bool exists = false;
    for(int i=0;i<_batchSummary!.length;i++){
      if(_batchSummary![i].feedName==name){
        exists = true;
        break;
      }
    }

    return exists;
  }

  void _showAddStockDialog() async {
    bool? stockAdded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddStockBottomSheet(onStockAdded: () {  },),
    );

    if (stockAdded == true) {
      // Explicitly refresh stock summary
      _stockSummary = await DatabaseHelper.getFeedStockSummary();
      setState(() {}); // Force UI update
    }
  }

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  Widget _buildStockItem(FeedStockSummary stock, int index, Animation<double> animation) {
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
              // Feed Name & Arrow Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      stock.feedName.tr(),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[600], size: 20),
                ],
              ),

              SizedBox(height: 10),

              // Stock Details Section (Total Stock & Used Stock in separate rows)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Total Stock".tr()+": ",
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                          Text(
                            " ${stock.totalStock}",
                            style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            Utils.selected_unit.tr(),
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "Used Stock".tr()+": ",
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                          Text(
                            " ${stock.usedStock}",
                            style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            Utils.selected_unit.tr(),
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Available Stock Badge (Now Adjusts Dynamically)
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
                    mainAxisSize: MainAxisSize.min, // Ensures dynamic width
                    children: [
                      Icon(Icons.inventory_2_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          "Available".tr()+": ${stock.availableStock}"+Utils.selected_unit.tr(),
                          style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis, // Prevents overflow
                          softWrap: true, // Allows wrapping
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 12),

              // LOW STOCK Warning (Now Centers Properly)
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
                        "⚠️"+ "LOW STOCK".tr(),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                      ),
                    ],
                  ),
                ),

              // **Enhanced Progress Bar** (Now Responsive)
              LayoutBuilder(
                builder: (context, constraints) {
                  double totalWidth = constraints.maxWidth;

                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Background Bar (Grey)
                      Container(
                        height: 18,
                        width: totalWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[300],
                        ),
                      ),

                      // Used Feed Bar (Red/Orange Gradient)
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

                      // Remaining Feed Bar (Green Gradient)
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

                      // **Circular Indicator for Used Stock**
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

                      // **Circular Indicator for Available Stock**
                      Positioned(
                        right: 0,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isLowStock ? Colors.red.shade700 : Colors.green.shade700,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: Center(
                            child: Icon(isLowStock ? Icons.warning_amber_rounded : Icons.check, size: 16, color: Colors.white),
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
              "Feed Stock Summary".tr(),
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
              "No feed stock available!".tr(),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: 5),
            Text("Add stock to see feed details.".tr(), style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      )
          : AnimatedList(
        key: _listKey,
        initialItemCount: _stockSummary!.length,
        itemBuilder: (context, index, animation) {
            return InkWell(
                onTap: () async {

                  if(checkIfBatch(_stockSummary![index].feedName)){
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FeedBatchScreen(),
                      ),
                    );
                  }else {
                    List<FeedStockHistory> history = await DatabaseHelper
                        .fetchStockHistory(
                        _stockSummary!.elementAt(index).feedName);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StockDetailScreen(
                              stock: _stockSummary!.elementAt(index),
                              stockHistory: history, // Fetch history
                            ),
                      ),
                    );

                    fetchStockSummary();
                  }
                },
                child: _buildStockItem(
                    _stockSummary![index], index, animation));

        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showFeedOptionsBottomSheet(context);
        },
        child: Icon(Icons.add, size: 28, color: Colors.white),
        backgroundColor: Utils.getThemeColorBlue(),
        shape: CircleBorder(), // Ensures a perfect circle
        elevation: 6, // Adds a slight shadow effect
      ),

    );
  }

  void showFeedOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Choose an Option".tr(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.inventory_2_rounded, color: Colors.green),
                title: Text("Add Feed Stock".tr(), style: TextStyle(fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate or call your function
                  _showAddStockDialog();
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.add_box_rounded, color: Colors.blue),
                title: Text("New Feed Batch".tr(), style: TextStyle(fontSize: 16)),
                onTap: () async {
                  Navigator.pop(context);
                  // Navigate or call your function
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FeedBatchScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

}




class AddStockBottomSheet extends StatefulWidget {
  final VoidCallback onStockAdded;
  AddStockBottomSheet({required this.onStockAdded});

  @override
  _AddStockBottomSheetState createState() => _AddStockBottomSheetState();
}
class _AddStockBottomSheetState extends State<AddStockBottomSheet> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _otherSourceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _selectedFeed;
  String? _selectedUnit = "KG";
  String? _selectedSource;
  DateTime _selectedDate = DateTime.now(); // Default to today
  List<String> _feedList = [];
  List<String> _unitList = ["kg"];
  List<String> _sourceList = ["PURCHASED", "GIFT", "OTHER"];
  List<SubItem> feeds = [];

  @override
  void initState() {
    super.initState();
    _loadFeedItems();
  }

  void _loadFeedItems() async {
    feeds = await DatabaseHelper.getSubCategoryList(3);
    setState(() {
      _feedList = feeds.map((feed) => feed.name.toString()).toList();
    });
  }

  /// Open date picker

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
    if (_selectedFeed == null || _quantityController.text.isEmpty || _selectedSource == null) {
      setState(() {
        isRequired = true;
      });
      return;
    }

    String finalSource = _selectedSource == "OTHER" ? _otherSourceController.text : _selectedSource!;
    double? amount = _selectedSource == "PURCHASED" && _amountController.text.isNotEmpty
        ? double.tryParse(_amountController.text)
        : null;

    FeedStockHistory stock = FeedStockHistory(
      feedId: getFeedIdbyName(),
      quantity: double.parse(_quantityController.text),
      unit: Utils.selected_unit,
      source: finalSource,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate), // Use selected date
      feed_name: _selectedFeed!,
    );

   int? stock_item_id =  await DatabaseHelper.insertFeedStock(stock);

    if(!_amountController.text.isEmpty){
      TransactionItem transaction_item = TransactionItem(
          f_id: -1,
          date: DateFormat('yyyy-MM-dd').format(_selectedDate),
          sale_item: "",
          expense_item: "Feed Purchase",
          type: "Expense",
          amount: _amountController.text,
          payment_method: "Cash",
          payment_status: "CLEARED",
          sold_purchased_from: "Unknown",
          short_note: "$_selectedFeed Purchase made on ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
          how_many: _quantityController.text,
          extra_cost: "",
          extra_cost_details: "",
          f_name: "Farm Wide",
          flock_update_id: '-1');

      int? transaction_id = await DatabaseHelper.insertNewTransaction(transaction_item);
      StockExpense stockExpense = StockExpense(stockItemId: stock_item_id!, transactionId: transaction_id!);
      await DatabaseHelper.insertStockJunction(stockExpense);
    }
    Navigator.pop(context, true);
  }

  int getFeedIdbyName() {
    return feeds.firstWhere((feed) => feed.name == _selectedFeed).id!;
  }

  bool isRequired = false;

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
            Text(
              "Add Feed Stock".tr(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 5),

            if (isRequired)
              Text(
                "PROVIDE_ALL".tr(),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.red),
              ),
            SizedBox(height: 5),

            _buildDropdown(
              hintText: "Choose Feed".tr(),
              value: _selectedFeed,
              items: _feedList,
              onChanged: (value) => setState(() => _selectedFeed = value),
              icon: Icons.grain,
            ),
            SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _quantityController,
                    label: "Quantity".tr(),
                    icon: Icons.production_quantity_limits,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Text(
                    Utils.selected_unit.tr(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black87),
                  ),
                ),
              ],
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

            _buildDropdown(
              hintText: "Select Source".tr(),
              value: _selectedSource,
              items: _sourceList,
              onChanged: (value) => setState(() {
                _selectedSource = value;
                _otherSourceController.clear();
                _amountController.clear();
              }),
              icon: Icons.storefront,
            ),
            SizedBox(height: 12),

            if (_selectedSource == "OTHER")
              _buildTextField(
                controller: _otherSourceController,
                label: "Enter Other Source".tr(),
                icon: Icons.create,
              ),

            if (_selectedSource == "PURCHASED")
              _buildTextField(
                controller: _amountController,
                label: "Amount".tr(),
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
            SizedBox(height: 20),

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
    );
  }
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

