import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/stock/stock_screen.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/utils.dart';

import 'feed_ingridient_screen.dart';
import 'model/feed_batch.dart';
import 'model/feed_batch_item.dart';
import 'model/feed_ingridient.dart';
import 'multiuser/model/feedbatchfb.dart';
import 'multiuser/model/ingridientfb.dart';
import 'multiuser/utils/RefreshMixin.dart';
import 'multiuser/utils/SyncStatus.dart';

class FeedBatchScreen extends StatefulWidget {
  const FeedBatchScreen({super.key});

  @override
  State<FeedBatchScreen> createState() => _FeedBatchScreenState();
}

class _FeedBatchScreenState extends State<FeedBatchScreen> with RefreshMixin {

  @override
  void onRefreshEvent(String event) {
    try {
      if (event == FireBaseUtils.FEED_BATCH) {
        _loadBatches();
      }
    }
    catch(ex){
      print(ex);
    }
  }

  List<FeedBatch> _batches = [];
   BannerAd? _bannerAd;
  double _heightBanner = 0;
  bool _isBannerAdReady = false;
  @override
  void initState() {
    super.initState();
    _loadBatches();
    if(Utils.isShowAdd){
      _loadBannerAd();
    }


    AnalyticsUtil.logScreenView(screenName: "feed_batch_screen");
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

  Future<void> _loadBatches() async {
    final list = await DatabaseHelper.getAllBatches();
    setState(() => _batches = list);
  }

  void _openCreateBatchDialog(FeedBatch? batch) {

    if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_feed"))
    {
      Utils.showMissingPermissionDialog(context, "add_feed");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CreateFeedBatchBottomDialog(onSaved: () {
        Navigator.pop(context);
        _loadBatches();
      }, batch: batch,),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text('Feed Batches'.tr()), backgroundColor: Colors.blue, foregroundColor: Colors.white,),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => {
    
                  _openCreateBatchDialog(null)
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: 55,
                  margin: EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Utils.getThemeColorBlue(), Colors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_sharp, color: Colors.white, size: 28),
                      SizedBox(width: 6),
                      Text(
                        'New Batch'.tr(),
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => {
                Navigator.push(
                context,
                MaterialPageRoute(
                builder: (context) =>  FeedIngredientScreen()),
                )
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: 55,
                  margin: EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade500, Colors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ingredients'.tr(),
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
    
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 28),
    
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _batches.isEmpty
          ?  Center(child: Text('No feed batches created yet.'.tr()))
          : SingleChildScrollView(
            child: SafeArea(
              child: Column(
                children:
                [
                  Utils.showBannerAd(_bannerAd, _isBannerAdReady),
                  
                  Container(
                    margin: EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Text('View available stock for feed batches'.tr(), style: TextStyle(color: Colors.black),),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>  FeedStockScreen()),
                  
                            );
                          },
                          child: Container(
                            child: Text('View Stock'.tr(), style: TextStyle(color: Colors.black, fontSize: 16, fontWeight:  FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    child: ListView.builder(
                            itemCount: _batches.length,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                    final batch = _batches[index];
                             return Card(
                               margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(16),
                               ),
                               elevation: 4,
                               child: Padding(
                                 padding: const EdgeInsets.all(16),
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     /// Header with name and actions
                                     Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text(
                                           batch.name,
                                           style:  TextStyle(
                                             fontSize: 20,
                                             fontWeight: FontWeight.bold,
                                             color: Utils.getThemeColorBlue(),
                                           ),
                                         ),
                                         Row(
                                           children: [
                                             IconButton(
                                               icon: const Icon(Icons.edit_note, color: Colors.blueAccent),
                                               onPressed: () {
                                                 if(Utils.isMultiUSer && !Utils.hasFeaturePermission("edit_feed"))
                                                 {
                                                   Utils.showMissingPermissionDialog(context, "edit_feed");
                                                   return;
                                                 }
                  
                                                 _openCreateBatchDialog(batch);
                                               },
                                             ),
                                             IconButton(
                                               icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                                               onPressed: () {
                                                 if(Utils.isMultiUSer && !Utils.hasFeaturePermission("delete_feed"))
                                                 {
                                                   Utils.showMissingPermissionDialog(context, "delete_feed");
                                                   return;
                                                 }
                  
                                                 _confirmDeleteBatch(batch.id!, batch.transaction_id);
                                               },
                                             ),
                                           ],
                                         ),
                                       ],
                                     ),
                  
                                     const SizedBox(height: 8),
                  
                                     /// Weight and Price
                                     Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text('Weight'.tr()+': ${batch.totalWeight.toStringAsFixed(2)} ${Utils.selected_unit.tr()}',
                                             style: const TextStyle(fontSize: 15, color: Colors.black87)),
                                         Text(Utils.currency.tr()+' ${batch.totalPrice.toStringAsFixed(2)}',
                                             style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                       ],
                                     ),
                  
                                     const SizedBox(height: 12),
                  
                                     /// Ingredients title
                                      Text(
                                       "Ingredients".tr(),
                                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
                                     ),
                                     const SizedBox(height: 6),
                  
                                     /// Ingredient chips
                                     Wrap(
                                       spacing: 8,
                                       runSpacing: 4,
                                       children: batch.ingredients.map((ing) {
                                         return Chip(
                                           label: Text('${ing.ingredientName} - ${ing.quantity.toStringAsFixed(2)} ${Utils.selected_unit.tr()}'),
                                           backgroundColor: Colors.grey.shade100,
                                           labelStyle: const TextStyle(color: Colors.black87),
                                         );
                                       }).toList(),
                                     ),
                                   ],
                                 ),
                               ),
                             );
                  
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
    
    );
  }

  Future<void> _confirmDeleteBatch(int batchId, int transactionId) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:  Text("Delete Feed Batch".tr()),
          content:  Text("Are you sure you want to delete this batch? This action cannot be undone.".tr()),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User cancels the deletion
              },
              child:  Text("CANCEL".tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirms the deletion
              },
              child:  Text("DELETE".tr()),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      FeedBatch? feedbatch = await DatabaseHelper.getFeedBatchById(batchId);
      FeedBatchFB feedBatchFB = FeedBatchFB(feedbatch!);

      await DatabaseHelper.deleteItem("Transactions", transactionId);
      await _deleteBatch(batchId);

      if(Utils.isMultiUSer && Utils.hasFeaturePermission("delete_feed")){
        feedBatchFB.modified_by = Utils.currentUser!.email;
        feedBatchFB.last_modified = Utils.getTimeStamp();
        feedBatchFB.farm_id = Utils.currentUser!.farmId;
        feedBatchFB.sync_status = SyncStatus.DELETED;

        await FireBaseUtils.updateFeedBatch(feedBatchFB);
      }

      _loadBatches();

    }
  }

  Future<void> _deleteBatch(int batchId) async {
    // Delete the batch from the database

    await DatabaseHelper.deleteBatch(batchId);

    // Optionally, delete the associated batch items
    await DatabaseHelper.deleteItemsByBatchId(batchId);

  }

}

class CreateFeedBatchBottomDialog extends StatefulWidget {
  final VoidCallback onSaved;
  FeedBatch? batch;
  CreateFeedBatchBottomDialog({super.key, required this.onSaved, required this.batch});

  @override
  State<CreateFeedBatchBottomDialog> createState() =>
      _CreateFeedBatchBottomDialogState();
}

class _CreateFeedBatchBottomDialogState
    extends State<CreateFeedBatchBottomDialog> {
  final TextEditingController _nameController = TextEditingController();
  List<FeedIngredient> _ingredients = [];
  Map<int, TextEditingController> _qtyControllers = {};
  Set<int> _selectedIngredientIds = {};

  double _totalWeight = 0;
  double _totalPrice = 0;
  int? _editingBatchId;
  int? transaction_id;

  @override
  void initState() {
    super.initState();
    if (widget.batch != null) {
      _loadBatchForEditing();
    }
    _loadIngredients();
  }

  // Pre-fill data for editing batch
  void _loadBatchForEditing() {
    setState(() {
      _editingBatchId = widget.batch?.id;
      _nameController.text = widget.batch!.name;
      transaction_id = widget.batch!.transaction_id;
      for (var item in widget.batch!.ingredients) {
        _selectedIngredientIds.add(item.ingredientId);
        _qtyControllers[item.ingredientId] = TextEditingController(text: item.quantity.toString());
      }
      _calculateTotals();
    });
  }

  void _loadIngredients() async {
    List<FeedIngredient>? list = await DatabaseHelper.getAllIngredients();
    list ??= [];

    setState(() {
      _ingredients = list!;
      for (var ing in list) {
        if (_qtyControllers[ing.id!] == null) {
          _qtyControllers[ing.id!] = TextEditingController();
        }
      }
    });
  }

  void _calculateTotals() {
    double weight = 0;
    double price = 0;


    for (var ing in _ingredients) {
      if (_selectedIngredientIds.contains(ing.id)) {
        final qty = double.tryParse(_qtyControllers[ing.id!]!.text) ?? 0;
        weight += qty;
        price += qty * ing.pricePerKg;
      }
    }


    setState(() {
      _totalWeight = weight;
      _totalPrice = price;
    });

  }

  bool isSaving = false;
  Future<void> _saveBatch() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedIngredientIds.isEmpty) return;

    isSaving = true;
    // Recalculate totals before saving the batch
    _calculateTotals();
    TransactionItem? transactionItem;
    if(transaction_id!= null) {
      transactionItem = await DatabaseHelper.getSingleTransaction(transaction_id.toString());
      transactionItem!.amount = _totalPrice.toString();
      transactionItem.how_many = _totalWeight.toString();
      transactionItem.sync_status = SyncStatus.SYNCED;
      transactionItem.modified_by = Utils.isMultiUSer ? Utils.currentUser!.email : '';
      transactionItem.last_modified = Utils.getTimeStamp();

      await DatabaseHelper.updateTransaction(transactionItem);

    } else {
      transactionItem = TransactionItem(f_id: -1,
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          f_name: "Farm Wide",
          sale_item: "sale_item",
          expense_item: "$name (Feed Batch)",
          type: "Expense",
          amount: _totalPrice.toString(),
          payment_method: "Cash",
          payment_status: "CLEARED",
          sold_purchased_from: "Feed Supplier",
          short_note: "new $name  (Feed Batch) created on "+DateFormat('yyyy-MM-dd').format(DateTime.now()),
          how_many: _totalWeight.toString(),
          extra_cost: "extra_cost",
          extra_cost_details: "extra_cost_details",
          flock_update_id: "-1",
          sync_id: Utils.getUniueId(),
          sync_status: SyncStatus.SYNCED,
          last_modified: Utils.getTimeStamp(),
          modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
          farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',);

      transaction_id = await DatabaseHelper.insertNewTransaction(transactionItem);
    }

    FeedBatchFB feedbatchfb;
    FeedBatch? fbatch = null;
    if(_editingBatchId!= null) {
      fbatch = await DatabaseHelper.getBatchById(_editingBatchId!);
    }

    final batch = FeedBatch(
      id: _editingBatchId, // Include batch ID if editing
      name: name,
      totalWeight: _totalWeight,
      totalPrice: _totalPrice,
      transaction_id: transaction_id!,
      sync_id: fbatch!= null? fbatch.sync_id : Utils.getUniueId(),
      sync_status: fbatch!= null? SyncStatus.UPDATED : SyncStatus.SYNCED,
      last_modified: Utils.getTimeStamp(),
      modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
      farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
    );

    feedbatchfb = FeedBatchFB(batch);
    feedbatchfb.transaction = transactionItem;

    int? batchId;
    if (_editingBatchId != null) {
      // Update existing batch
      batchId = _editingBatchId;
      await DatabaseHelper.updateBatch(batch); // Ensure `updateBatch` method exists
    } else {
      // Insert a new batch
      batchId = await DatabaseHelper.insertBatch(batch);
    }

    // Clear existing items if editing an existing batch
    if (_editingBatchId != null) {
      await DatabaseHelper.deleteItemsByBatchId(_editingBatchId!);
    }

    feedbatchfb.ingredientList = [];
    // Insert new batch items
    for (var ing in _ingredients) {
      if (_selectedIngredientIds.contains(ing.id)) {
        final qty = double.tryParse(_qtyControllers[ing.id!]!.text) ?? 0;
        if (qty > 0) {
          await DatabaseHelper.insertBatchItem(FeedBatchItem(
            batchId: batchId!, // Use the batchId from the insert or update
            ingredientId: ing.id!,
            quantity: qty,
          ));

          FeedIngredient? feedIngredient = await DatabaseHelper.getIngredientById(ing.id!);
          IngredientFB ingredientFb = IngredientFB(feedIngredient!.sync_id!, qty);
          ingredientFb.ingredient = feedIngredient;
          feedbatchfb.ingredientList!.add(ingredientFb);

        }
      }
    }

    widget.onSaved();

    if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_feed")) {
      feedbatchfb.farm_id = Utils.currentUser!.farmId;
      feedbatchfb.last_modified = Utils.getTimeStamp();
      feedbatchfb.modified_by = Utils.currentUser!.email;

      if (_editingBatchId == null) {
        feedbatchfb.sync_status = SyncStatus.SYNCED;
        await FireBaseUtils.addFeedBatch(feedbatchfb);
      } else {
        feedbatchfb.sync_status = SyncStatus.UPDATED;
        await FireBaseUtils.updateFeedBatch(feedbatchfb);
      }
    }

    isSaving = false;

  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16), // Increased padding for a more spacious layout
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.batch == null ? "Create New Feed Batch".tr() : "Edit Feed Batch".tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20, // Increased font size for the title
                    color: Colors.blueGrey, // Light color for the title
                  ),
                ),
                const SizedBox(height: 20),
                // Batch Name Input Field
                TextField(
                  controller: _nameController,
                  readOnly: widget.batch != null? true : false,
                  decoration:  InputDecoration(
                    labelText: "Batch Name".tr(),
                    labelStyle: TextStyle(color: Colors.blueGrey), // Color for label text
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue), // Highlighted border color
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey), // Default border color
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Ingredients Selection Title
                 Text(
                  'Select Ingredients'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey, // Color to match the title style
                  ),
                ),
                const SizedBox(height: 8),
                // Ingredients List or No Ingredients Message
                _ingredients.isEmpty
                    ? Column(
                  children: [
                     Center(child: Text('No ingredients found.'.tr())),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>  FeedIngredientScreen()),
      
                        );
      
                      },
                      child:  Text("New Ingredient".tr()),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(45), backgroundColor: Colors.blue, // Primary color for button
                      ),
                    ),
                  ],
                )
                    : Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to add a new ingredient screen
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>  FeedIngredientScreen()),
      
                            );
      
                          },
                          child:  Text("New Ingredient".tr(), style: TextStyle(color: Colors.white),),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(45), backgroundColor: Utils.getThemeColorBlue(), // Primary color for button
                          ),
                        ),
                        ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _ingredients.length,
                                        itemBuilder: (_, index) {
                        final ing = _ingredients[index];
                        final isSelected = _selectedIngredientIds.contains(ing.id);
      
                        return Card(
                          elevation: 5, // Added shadow for the cards
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Rounded corners for the card
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedIngredientIds.add(ing.id!);
                                  } else {
                                    _selectedIngredientIds.remove(ing.id!);
                                    _qtyControllers[ing.id!]!.text = '';
                                  }
                                });
                                _calculateTotals();
                              },
                            ),
                            title: Text(
                              ing.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Price'.tr()+': ${Utils.currency} ${ing.pricePerKg.toStringAsFixed(2)}' +"per".tr() +' ${Utils.selected_unit.tr()}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 120,
                                  height: 40,
                                  child: TextField(
                                    controller: _qtyControllers[ing.id!]!,
                                    enabled: isSelected,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Qty'.tr()+' (${Utils.selected_unit.tr()})',
                                      labelStyle: TextStyle(color: Colors.blueGrey),
                                      border: OutlineInputBorder(),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Colors.blue),
                                      ),
                                    ),
                                    onChanged: (_) => _calculateTotals(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                                        },
                                      ),
                      ],
                    ),
                const SizedBox(height: 10),
                // Total Weight and Price Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weight'.tr()+': ${_totalWeight.toStringAsFixed(2)} ${Utils.selected_unit.tr()}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Price'.tr()+': '+Utils.currency+'. ${_totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Save Button
                ElevatedButton.icon(
                  onPressed: _saveBatch,
                  icon: const Icon(Icons.save, color: Colors.white,),
                  label:  Text("SAVE".tr(), style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50), backgroundColor: Utils.getThemeColorBlue(), // Green color for the button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded corners for button
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

