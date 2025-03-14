import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/utils/utils.dart';

import '../model/feed_stock_history.dart';
import '../model/feed_stock_summary.dart';


class StockDetailScreen extends StatelessWidget {
  final FeedStockSummary stock;
  final List<FeedStockHistory> stockHistory;

  StockDetailScreen({required this.stock, required this.stockHistory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Stock Details")),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // **Stock Summary Section**
            _buildStockItem(stock, 0, kAlwaysCompleteAnimation),

            SizedBox(height: 16),

            // **Stock History Title**
            Container(
                margin: EdgeInsets.only(left: 10),
                child: Text("Stock History".tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),

            SizedBox(height: 8),

            // **Stock History List**
            Expanded(
              child: Container(
                margin: EdgeInsets.all(10),
                child: ListView.builder(
                  itemCount: stockHistory.length,
                  itemBuilder: (context, index) {
                    final entry = stockHistory[index];

                    return Dismissible(
                      key: Key(entry.id.toString()), // Use a unique key for each item
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart, // Swipe left to delete
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Delete Entry".tr()),
                            content: Text("Are you sure you want to delete this stock entry?".tr()),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("CANCEL".tr())),
                              TextButton(
                                onPressed: () async{
                                 // _deleteStock(entry.id);
                                   DatabaseHelper.deleteFeedStock(entry.id!);
                                   Navigator.of(context).pop(true);
                                },
                                child: Text("DELETE".tr(), style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        DatabaseHelper.deleteFeedStock(entry.id!);

                        // Delete the item from the database
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        margin: EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            entry.source == 'PURCHASED' ? Icons.add_shopping_cart : Icons.sync_alt,
                            color: entry.source == 'PURCHASED' ? Colors.green : Colors.orange,
                          ),
                          title: Text(
                            "${entry.quantity} ${entry.unit} from ${entry.source}",
                            style: TextStyle(fontSize: 16),
                          ),
                          subtitle: Text("DATE".tr()+": ${Utils.getFormattedDate(entry.date)}"),

                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

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
                        "Total Stock".tr()+": ${stock.totalStock}",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Used Stock".tr()+": ${stock.usedStock}",
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
                              "Available".tr()+": ${stock.availableStock}",
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
                        "⚠️" +"LOW STOCK".tr(),
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

}
