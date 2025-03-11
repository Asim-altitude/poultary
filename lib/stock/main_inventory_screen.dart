import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/category_item.dart';
import 'package:poultary/stock/vaccine_stock_screen.dart';
import 'package:poultary/utils/utils.dart';

import '../stock/stock_screen.dart';
import 'egg_stock_screen.dart';
import 'medicine_stock_screen.dart';

class ManageInventoryScreen extends StatefulWidget {
  @override
  _ManageInventoryScreenState createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen> {


  @override
  void initState() {
    super.initState();
    // Initialize any necessary data or perform setup tasks here

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0),
          ),
          child: AppBar(
            title: Text(
              "Manage Inventory".tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Utils.getThemeColorBlue(),
            elevation: 8,
            automaticallyImplyLeading: false,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildInventoryItem(
              icon: Icons.fastfood,
              title: "Feed Stock".tr(),
              description: "Manage available feed quantity and types".tr(),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeedStockScreen(),
                  ),
                );
              },
            ),
            _buildInventoryItem(
              icon: Icons.egg,
              title: "Egg Stock".tr(),
              description: "Manage collected eggs and storage".tr(),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EggStockScreen(),
                  ),
                );
              },
            ),
            _buildInventoryItem(
              icon: Icons.medical_services,
              title: "Medicine Stock".tr(),
              description: "Track medicines and expiration dates".tr(),
              onTap: () async {
                CategoryItem item = CategoryItem(id: null, name: "Medicine");
                int? medicineCategoryID = await DatabaseHelper.addCategoryIfNotExists(item);

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicineStockScreen(id: medicineCategoryID!,),
                  ),
                );
              },
            ),
            _buildInventoryItem(
              icon: Icons.vaccines,
              title: "Vaccine Stock".tr(),
              description: "Manage vaccination schedules and stock".tr(),
              onTap: () async {
                CategoryItem item = CategoryItem(id: null, name: "Vaccine");
                int? vaccineCategoryID = await DatabaseHelper.addCategoryIfNotExists(item);

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VaccineStockScreen(id: vaccineCategoryID!,),
                  ),
                );
              },
            ),
          /*  _buildInventoryItem(
              icon: Icons.water_drop,
              title: "Water Stock",
              description: "Monitor water consumption and storage",
              onTap: () {},
            ),
            _buildInventoryItem(
              icon: Icons.layers,
              title: "Bedding Material Stock",
              description: "Monitor bedding materials for poultry",
              onTap: () {},
            ),
            _buildInventoryItem(
              icon: Icons.build,
              title: "Equipment Stock",
              description: "Track poultry farm tools and equipment",
              onTap: () {},
            ),
            _buildInventoryItem(
              icon: Icons.local_gas_station,
              title: "Fuel & Energy Stock",
              description: "Track gas, diesel, and electricity usage",
              onTap: () {},
            ),
            _buildInventoryItem(
              icon: Icons.cleaning_services,
              title: "Cleaning & Disinfection Stock",
              description: "Monitor sanitizers, disinfectants, and detergents",
              onTap: () {},
            ),
            _buildInventoryItem(
              icon: Icons.inventory,
              title: "Packaging & Storage Materials",
              description: "Track egg trays, cartons, and feed bags",
              onTap: () {},
            ),*/
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryItem({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        leading: Icon(icon, size: 30, color: Utils.getThemeColorBlue()),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          description,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
        onTap: onTap,
      ),
    );
  }


}

