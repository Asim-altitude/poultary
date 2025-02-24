import 'package:flutter/material.dart';
import 'package:poultary/database/databse_helper.dart';
import '../model/custom_category.dart';
import '../utils/utils.dart';
import 'all_custom_data_screen.dart';
import 'custom_flock_category.dart';

class AllCategoryScreen extends StatefulWidget {
  @override
  _AllCategoryScreenState createState() => _AllCategoryScreenState();
}

class _AllCategoryScreenState extends State<AllCategoryScreen> {

  @override
  void initState() {
    super.initState();
    getAllCategories();
  }

  List<CustomCategory> categories = [];
  Future<void> getAllCategories() async {
    categories = (await DatabaseHelper.getCustomCategories())!;
    await DatabaseHelper.createCategoriesDataTable();

    setState(() {});
  }

  Future<void> _createCategory(CustomCategory? item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomCategoryScreen(customCategory: item,)),
    );
    getAllCategories();
  }

  void _showOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.remove_red_eye_outlined, size: 30,),
              title: Text('View Category Data', style: TextStyle(fontWeight: FontWeight.bold),),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CategoryDataListScreen(customCategory: categories.elementAt(index),)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editCategory(index);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(context,index);
              },
            ),
            ListTile(
              leading: Icon(Icons.block),
              title: Text(categories[index].enabled == 1 ? 'Disable' : 'Enable'),
              onTap: () {
                Navigator.pop(context);
                _toggleCategoryStatus(index);
              },
            ),
          ],
        );
      },
    );
  }

  void _editCategory(int index) {
    // Implement edit functionality
    _createCategory(categories[index]);
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context,int index) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text(
            "If you delete this category then you will lose all the data in this category. Continue?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      _deleteCategory(index);
    }
  }


  Future<void> _deleteCategory(int index) async {
    await DatabaseHelper.deleteCategory(categories.elementAt(index).id!);
    setState(() {
      categories.removeAt(index);
    });
  }

  Future<void> _toggleCategoryStatus(int index) async {
    categories[index].enabled = categories[index].enabled == 1? 0:1;
    await DatabaseHelper.updateCategory(categories[index]);
    setState(() {

    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Custom Categories')),
      body: categories.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category, size: 80, color: Colors.grey),
            SizedBox(height: 10),
            Text("No categories found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Utils.getThemeColorBlue(), // Change to your desired color
                foregroundColor: Colors.white, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),),
              onPressed: () => _createCategory(null),
              child: Text('Create New Category', style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      )
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.0,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return InkWell(
              onTap:(){
                _showOptions(index);
              },
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                color: categories.elementAt(index).enabled == 1 ? Colors.white : Colors.grey[300],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(category.icon, size: 45, color: Utils.getThemeColorBlue()),
                      SizedBox(height: 5),
                      Text(
                        category.name,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${category.cat_type}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '${category.itemtype}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: category.itemtype=="Collection"? Colors.green: Colors.red),
                      ),

                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: !categories.isEmpty? Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () => _createCategory(null),
          style: ElevatedButton.styleFrom(
            backgroundColor: Utils.getThemeColorBlue(),
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Create New Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ) : null,
    );
  }
}
