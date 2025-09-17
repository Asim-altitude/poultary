import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poultary/model/egg_income.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:sqflite/sqflite.dart';

import '../database/databse_helper.dart';
import '../model/egg_item.dart';
import '../utils/utils.dart';

class EggStockScreen extends StatefulWidget {
  @override
  _EggStockScreenState createState() => _EggStockScreenState();
}

class _EggStockScreenState extends State<EggStockScreen> {
  late Future<Map<String, int>> stockSummary;
   List<Eggs> stockHistory = [];
   BannerAd? _bannerAd;
  double _heightBanner = 0;
  bool _isBannerAdReady = false;

  int pageCount = 0;

  @override
  void initState() {
    super.initState();
    stockSummary = getEggStockSummary();
     getEggStockHistory(page: pageCount);
    if(Utils.isShowAdd){
      _loadBannerAd();
    }
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

    _bannerAd?.load();
  }

  @override
  void dispose() {
    try{
      _bannerAd?.dispose();
    }catch(ex){

    }
    super.dispose();
  }

  Future<Map<String, int>> getEggStockSummary() async {
     return await DatabaseHelper.getEggStockSummary();
  }

  void getEggStockHistory({int page = 0, int pageSize = 2000}) async {
    stockHistory = await DatabaseHelper.getStockHistoryPaginated(page: page, pageSize: pageSize);
    var eggSales = await DatabaseHelper.getEggSaleTransactions();

    int reduced_eggs = 0;
    for(int i=0;i<eggSales.length;i++){
      TransactionItem item = eggSales[i];
      EggTransaction? eggTransaction = await DatabaseHelper.getEggsByTransactionItemId(item.id!);
      if(eggTransaction == null) {
        reduced_eggs += int.parse(item.how_many);
        Eggs eggs = Eggs(f_id: item.f_id!,
            f_name: item.f_name,
            image: "image",
            good_eggs: int.parse(item.how_many),
            bad_eggs: 0,
            egg_color: "white",
            total_eggs: int.parse(item.how_many),
            date: item.date,
            short_note: item.short_note,
            isCollection: 0,
            reduction_reason: "Sold");
        stockHistory.add(eggs);
      }
    }

    var map = await stockSummary;
    int? available = map['availableStock'];
    int? totalUsed = map['totalUsed'];
    int? totalCollected = map['totalCollected'];

    totalUsed = totalUsed! + reduced_eggs;
    available = totalCollected! - totalUsed;

    // ✅ Update your map dynamically
    map = {
      'totalCollected': totalCollected,
      'totalUsed': totalUsed,
      'availableStock': available
    };

    stockSummary = Future.value(map);
    // ✅ Sort by date (newest first)
    stockHistory.sort((a, b) {
      // Convert string to DateTime if needed
      final dateA = DateTime.parse(a.date!);
      final dateB = DateTime.parse(b.date!);
      return dateB.compareTo(dateA); // descending order
    });
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Egg Stock".tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
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
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child:
        Column(children: [
          Utils.showBannerAd(_bannerAd, _isBannerAdReady),
          Expanded(child: SingleChildScrollView(
   child:Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [

       FutureBuilder<Map<String, int>>(
         future: stockSummary,
         builder: (context, snapshot) {
           if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

           final data = snapshot.data!;
           return _buildStockSummary(data['totalCollected']!, data['totalUsed']!, data['availableStock']!);
         },
       ),
       SizedBox(height: 16),
       Container(
         margin: EdgeInsets.only(left: 10),
         child: Row(
           children: [
             Text("Stock History".tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             Text(" (${stockHistory.length}) ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
           ],
         ),
       ),
       SizedBox(height: 8),
       Container(
         margin: EdgeInsets.all(10),
         child: ListView.builder(
           shrinkWrap: true,
           physics: NeverScrollableScrollPhysics(),

           itemCount: stockHistory.length,
           itemBuilder: (context, index) {
             final entry = stockHistory[index];

             return Dismissible(
               key: Key(entry.id.toString()),
               background: Container(
                 color: Colors.red,
                 alignment: Alignment.centerRight,
                 padding: EdgeInsets.only(right: 20),
                 child: Icon(Icons.delete, color: Colors.white),
               ),
               direction: DismissDirection.endToStart,
               confirmDismiss: (direction) async {
                 return await showDialog(
                   context: context,
                   builder: (context) => AlertDialog(
                     title: Text("Delete Entry".tr()),
                     content: Text("Are you sure you want to delete this stock entry?".tr()),
                     actions: [
                       TextButton(
                         onPressed: () => Navigator.of(context).pop(false),
                         child: Text("CANCEL".tr()),
                       ),
                       TextButton(
                         onPressed: () {
                           DatabaseHelper.deleteItem("Eggs",entry.id!);
                           Navigator.of(context).pop(true);
                         },
                         child: Text("DELETE".tr(), style: TextStyle(color: Colors.red)),
                       ),
                     ],
                   ),
                 );
               },
               child: Card(
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 elevation: 3,
                 margin: EdgeInsets.symmetric(vertical: 6),
                 child: ListTile(
                   leading: Icon(Icons.egg, color: entry.isCollection == 1? Colors.green : Colors.orange),
                   title: Text(
                     entry.isCollection == 1? "${entry.total_eggs} "+ "eggs collected".tr() : "${entry.total_eggs} "+ "Reduced Eggs".tr(),
                     style: TextStyle(fontSize: 16),
                   ),
                   subtitle: Text("DATE".tr()+": ${Utils.getFormattedDate(entry.date!)}"),
                 ),
               ),
             );
           },
         ),
       ),

     ],
   ),))
          ,
        ],),
      ),
    );
  }

  Widget _buildStockSummary(int total, int used, int available) {
    double progress = total > 0 ? used / total : 0.0;
    double usedWidth = progress.clamp(0.0, 1.0);
    double remainingWidth = (1 - progress).clamp(0.0, 1.0);
    bool isLowStock = available <= (total * 0.2);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      elevation: 6,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Egg Stock Summary".tr(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Stock Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.egg, color:  Colors.green),
                        SizedBox(width: 10,),
                        Text("Total Eggs".tr()+": $total", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.egg, color:  Colors.orange),
                        SizedBox(width: 10,),
                        Text("Used Eggs".tr()+": $used", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      ],
                    ),
                  ],
                ),

                // Available Stock Badge

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
                    Icon(Icons.inventory_2_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "Available".tr()+": $available",
                        style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // Low Stock Warning
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

            // Progress Bar
            LayoutBuilder(
              builder: (context, constraints) {
                double totalWidth = constraints.maxWidth;

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Background Bar
                    Container(
                      height: 18,
                      width: totalWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[300],
                      ),
                    ),

                    // Used Stock Bar
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

                    // Remaining Stock Bar
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

                    // Circular Indicator for Used Stock
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

                    // Circular Indicator for Available Stock
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
    );
  }


}
