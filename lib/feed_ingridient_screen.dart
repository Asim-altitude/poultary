import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/multiuser/utils/SyncStatus.dart';
import 'package:poultary/utils/utils.dart';
import 'package:sqflite/sqflite.dart';
import 'model/feed_ingridient.dart';
import 'multiuser/utils/RefreshMixin.dart';

class FeedIngredientScreen extends StatefulWidget {


  const FeedIngredientScreen({Key? key}) : super(key: key);

  @override
  State<FeedIngredientScreen> createState() => _FeedIngredientScreenState();
}

class _FeedIngredientScreenState extends State<FeedIngredientScreen> with RefreshMixin {
  List<FeedIngredient> ingredients = [];

  @override
  void onRefreshEvent(String event) {
    try {
      if (event == FireBaseUtils.FEED_INGRIDIENT) {
        _loadIngredients();
      }
    }
    catch(ex){
      print(ex);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    ingredients = (await DatabaseHelper.getAllIngredients())!;
    for(int i=0;i<ingredients.length;i++){
      print(ingredients.elementAt(i).toLocalFBJson());
    }
    setState(() {

    });
  }

  Future<void> _showIngredientDialog({FeedIngredient? ingredient}) async {

    if(Utils.isMultiUSer && !Utils.hasFeaturePermission("edit_feed"))
    {
      Utils.showMissingPermissionDialog(context, "edit_feed");
      return;
    }

    final nameController = TextEditingController(text: ingredient?.name ?? '');
    final priceController = TextEditingController(
        text: ingredient != null ? ingredient.pricePerKg.toString() : '');
    final unitController = TextEditingController(text: ingredient?.unit ?? Utils.selected_unit);

    final isEditing = ingredient != null;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isEditing ? Icons.edit : Icons.add, color: Utils.getThemeColorBlue()),
            const SizedBox(width: 8),
            Text(
              isEditing ? 'Edit Ingredient'.tr() : 'New Ingredient'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Ingredient Name'.tr(),
                  prefixIcon: Icon(Icons.label_important, color: Utils.getThemeColorBlue()),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'Price'.tr()+'per'.tr()+' ${Utils.selected_unit.tr()}',
                  prefixIcon: Icon(Icons.attach_money, color: Utils.getThemeColorBlue()),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text('CANCEL'.tr()),
          ),
          ElevatedButton.icon(
            icon: Icon(isEditing ? Icons.update : Icons.add, color: Colors.white,),
            label: Text(isEditing ? 'Update'.tr() : 'SAVE'.tr(), style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(
              backgroundColor: Utils.getThemeColorBlue(),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text.trim()) ?? 0;
              final unit = unitController.text.trim();

              FeedIngredient? feedIngredient;
              if (name.isNotEmpty && price > 0) {
                if (isEditing) {
                  feedIngredient = FeedIngredient(name: name, pricePerKg: price, unit:  Utils.selected_unit,

                  sync_id: ingredient.sync_id, sync_status: SyncStatus.UPDATED);
                  feedIngredient.id = ingredient.id;
                  feedIngredient.farm_id = Utils.isMultiUSer? Utils.currentUser!.farmId :'';
                  feedIngredient.modified_by = Utils.isMultiUSer? Utils.currentUser!.email :'';

                  await DatabaseHelper.updateIngredientByObject(feedIngredient);
                  if(Utils.isMultiUSer && Utils.hasFeaturePermission("update_stock")){
                    await FireBaseUtils.updateFeedIngredient(feedIngredient);
                  }
                } else {
                    feedIngredient = FeedIngredient(name: name, pricePerKg: price, unit:  Utils.selected_unit);

                    int? id = await DatabaseHelper.insertIngredient(name, price, unit: Utils.selected_unit);
                    FeedIngredient? newItem = await DatabaseHelper.getIngredientById(id!);
                    feedIngredient.sync_id = newItem!.sync_id;
                    feedIngredient.sync_status = SyncStatus.SYNCED;
                    feedIngredient.farm_id = Utils.isMultiUSer? Utils.currentUser!.farmId :'';
                    feedIngredient.modified_by = Utils.isMultiUSer? Utils.currentUser!.email :'';

                  if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_stock")){
                    await FireBaseUtils.addFeedIngredient(feedIngredient);
                  }
                }
                Navigator.pop(context);
                _loadIngredients();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteIngredient(int id) async {
    if(Utils.isMultiUSer && !Utils.hasFeaturePermission("delete_feed"))
    {
      Utils.showMissingPermissionDialog(context, "delete_feed");
      return;

    }

    await DatabaseHelper.deleteIngredient(id);//.delete('ingredients', where: 'id = ?', whereArgs: [id]);
    _loadIngredients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feed Ingredients'.tr()), backgroundColor: Utils.getThemeColorBlue(), foregroundColor: Colors.white,),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(10),
        color: Colors.white,
        child: Expanded(
          child: InkWell(
            onTap: () => {

              if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_feed"))
                {
                  Utils.showMissingPermissionDialog(context, "add_feed")

                }else{

                _showIngredientDialog()
              }

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
                    'New Ingredient'.tr(),
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ingredients.isEmpty
          ? Center(child: Text('No ingredients yet.'.tr()))
          : ListView.builder(
        itemCount: ingredients.length,
        itemBuilder: (_, index) {
          final ingredient = ingredients[index];
         return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Ingredient info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ingredient.name} (${ingredient.unit.tr()})',
                          style:  TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Utils.getThemeColorBlue(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Utils.currency+' ${ingredient.pricePerKg.toStringAsFixed(2)} '+'per'.tr()+' ${ingredient.unit}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () => _showIngredientDialog(ingredient: ingredient),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteIngredient(ingredient.id!),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

        },
      ),

    );
  }
}
