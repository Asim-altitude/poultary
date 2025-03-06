import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:poultary/stock_details_screen.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/feed_stock_history.dart';
import 'model/feed_stock_summary.dart';
import 'model/sub_category_item.dart';

class FeedStockScreen extends StatefulWidget {
  @override
  _FeedStockScreenState createState() => _FeedStockScreenState();
}

class _FeedStockScreenState extends State<FeedStockScreen> {
  List<FeedStockSummary>? _stockSummary = [];
  @override
  void initState() {
    super.initState();
    createTables();

  }

  void createTables() async {
    await DatabaseHelper.instance.database;

    await DatabaseHelper.createFeedStockHistoryTable();
    fetchStockSummary();
  }
   // Nullable variable

  Future<void> fetchStockSummary() async {
    _stockSummary = await DatabaseHelper.getFeedStockSummary();
    setState(() {}); // Update UI after fetching data
  }


  void _showAddStockDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddStockBottomSheet(onStockAdded: fetchStockSummary),
    );
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
                      stock.feedName,
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
                      Text(
                        "Total Stock: ${stock.totalStock}",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Used Stock: ${stock.usedStock}",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),

                  // Available Stock Badge (Now Adjusts Dynamically)
                  Flexible(
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
                              "Available: ${stock.availableStock}",
                              style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis, // Prevents overflow
                              softWrap: true, // Allows wrapping
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                        "⚠️ LOW STOCK",
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
      appBar: AppBar(title: Text("Feed Stock Summary")),
      body: _stockSummary!.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "No feed stock available!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: 5),
            Text("Add stock to see feed details.", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      )
          : AnimatedList(
        key: _listKey,
        initialItemCount: _stockSummary!.length,
        itemBuilder: (context, index, animation) {
          return InkWell(
              onTap: () async {
                List<FeedStockHistory> history = await DatabaseHelper.fetchStockHistory(_stockSummary!.elementAt(index).feedName);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StockDetailScreen(
                      stock: _stockSummary!.elementAt(index),
                      stockHistory: history, // Fetch history
                    ),
                  ),
                );

              },
              child: _buildStockItem(_stockSummary![index], index, animation));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStockDialog,
        child: Icon(Icons.add, size: 28, color: Colors.white),
        backgroundColor: Utils.getThemeColorBlue(),
        shape: CircleBorder(), // Ensures a perfect circle
        elevation: 6, // Adds a slight shadow effect
      ),

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
  String? _selectedUnit;
  String? _selectedSource;
  List<String> _feedList = [];
  List<String> _unitList = ["kg"];
  List<String> _sourceList = ["Purchased", "Gift", "Harvest", "Other"];
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

  void _saveStock() async {
    if (_selectedFeed == null || _selectedUnit == null || _quantityController.text.isEmpty || _selectedSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("All fields are required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String finalSource = _selectedSource == "Other" ? _otherSourceController.text : _selectedSource!;
    double? amount = _selectedSource == "Purchased" && _amountController.text.isNotEmpty
        ? double.tryParse(_amountController.text)
        : null;

    FeedStockHistory stock = FeedStockHistory(
      feedId: getFeedIdbyName(),
      quantity: double.parse(_quantityController.text),
      unit: _selectedUnit!,
      source: finalSource,
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      feed_name: _selectedFeed!,
    );

    await DatabaseHelper.insertFeedStock(stock);
    widget.onStockAdded();
    Navigator.pop(context);
  }

  int getFeedIdbyName() {
    return feeds.firstWhere((feed) => feed.name == _selectedFeed).id!;
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
              "Add Feed Stock",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 16),

            // Feed Selection
            _buildDropdown(
              hintText: "Select Feed",
              value: _selectedFeed,
              items: _feedList,
              onChanged: (value) => setState(() => _selectedFeed = value),
              icon: Icons.grain,
            ),
            SizedBox(height: 12),

            // Quantity Input
            _buildTextField(
              controller: _quantityController,
              label: "Quantity",
              icon: Icons.production_quantity_limits,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),

            // Unit Selection
            _buildDropdown(
              hintText: "Select Unit",
              value: _selectedUnit,
              items: _unitList,
              onChanged: (value) => setState(() => _selectedUnit = value),
              icon: Icons.scale,
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
            ElevatedButton(
              onPressed: _saveStock,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: Colors.green.shade600,
                elevation: 4,
              ),
              child: Text("Save Stock", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.green),
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
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }
}
