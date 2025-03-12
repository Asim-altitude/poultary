import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:poultary/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

import 'database/databse_helper.dart';
import 'model/category_item.dart';

class BackupRestoreScreen extends StatefulWidget {
  @override
  _BackupRestoreScreenState createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {



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
              "BACK_UP_RESTORE_MESSAGE".tr(),
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

      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            SizedBox(height: 10),

            /// **Backup Database Button**
            _buildBackupRestoreTile(
              title: "BACKUP".tr(),
              subtitle: "Save a copy of your data securely".tr(),
              icon: Icons.backup,
              color: Colors.green,
              onTap: () {
                // Perform Backup Action
                shareFiles();
              },
            ),

            /// **Restore Database Button**
            _buildBackupRestoreTile(
              title: "RESTORE".tr(),
              subtitle: "Restore data from a previous backup".tr(),
              icon: Icons.restore,
              color: Colors.orange,
              onTap: () async {
                // Perform Restore Action
                await DatabaseHelper.importDataBaseFile(context);
                try {
                  await DatabaseHelper.addEggColorColumn();
                  await DatabaseHelper.addFlockInfoColumn();
                  await DatabaseHelper.addQuantityColumnMedicine();
                  await DatabaseHelper.addUnitColumnMedicine();
                  await DatabaseHelper.createFeedStockHistoryTable();
                  await DatabaseHelper.createMedicineStockHistoryTable();
                  await DatabaseHelper.createVaccineStockHistoryTable();
                  await addNewColumn();
                  await addMissingCategories();
                }
                catch(ex){
                  print(ex);
                }
              },
            ),

            /*/// **Automatic Cloud Backup - Card Option**
            SizedBox(height: 20),
            _buildCloudBackupCard(),*/
          ],
        ),
      ),
    );
  }
  shareFiles() async {
    File newPath = await DatabaseHelper.getFilePathDB();
    XFile file = new XFile(newPath.path);

    final result = await Share.shareXFiles([file], text: 'BACKUP'.tr());

    if (result.status == ShareResultStatus.success) {
      print('Backup completed');
    }
  }
  /// **Reusable Backup/Restore Tile**
  Widget _buildBackupRestoreTile({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          radius: 30,
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.black54)),
        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  bool isAutoBackupEnabled = false;
  /// **Cloud Backup Card**
  Widget _buildCloudBackupCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// **Title & Icon**
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                radius: 30,
                child: Icon(MdiIcons.cloudSync, color: Colors.white, size: 28),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Automatic Cloud Backup",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          /// **Description**
          Text(
            "Enable automatic cloud backup to secure your data effortlessly.",
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          SizedBox(height: 10),

          /// **Enable/Disable Switch**
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cloud Backup", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Switch(
                value: isAutoBackupEnabled, // You can replace this with a state variable
                onChanged: (bool value) {
                  // Toggle cloud backup state
                  setState(() {
                    isAutoBackupEnabled = value;
                  });

                },
                activeColor: Colors.white,
                activeTrackColor: Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
  Future<void> addMissingCategories() async{

    //Medicine Category
    CategoryItem categoryItem = CategoryItem(id: null, name: "Medicine");
    CategoryItem categoryItem1 = CategoryItem(id: null, name: "Vaccine");

    List<String> commonMedicines = [
      "Amprolium",
      "Tylosin",
      "Doxycycline",
      "Enrofloxacin",
      "Neomycin",
      "Sulfaquinoxaline",
      "Furazolidone",
      "Flubendazole",
      "Ivermectin",
      "Gentamycin",
      "Ketoprofen",
      "Multivitamins",
      "Lincomycin",
      "Oxytetracycline",
      "Copper Sulfate",
      "Probiotics",
    ];

    List<String> commonVaccines = [
      "Newcastle",
      "Gumboro",
      "Marek’s",
      "Fowl Pox",
      "Avian Influenza",
      "Salmonella",
      "Bronchitis",
      "Fowl Cholera",
      "Mycoplasma",
      "EDS",
      "Coryza",
      "Reovirus",
      "E. coli",
      "Coccidiosis",
    ];
    int? medicineCategoryID = await DatabaseHelper.addCategoryIfNotExists(categoryItem);

    for(int i=0;i<commonMedicines.length;i++){
      await DatabaseHelper.addSubcategoryIfNotExists(medicineCategoryID!, commonMedicines[i]);
      print(commonMedicines[i]);
    }

    int? vaccineCategoryID  = await DatabaseHelper.addCategoryIfNotExists(categoryItem1);

    for(int i=0;i<commonVaccines.length;i++){
      await DatabaseHelper.addSubcategoryIfNotExists(vaccineCategoryID!, commonVaccines[i]);
      print(commonVaccines[i]);
    }

  }


  Future<void> addNewColumn() async {
    try{
      int c = await DatabaseHelper.addColumnInFlockDetail();
      print("Column Info $c");
    }catch(ex){
      print(ex);
    }

    try{
      int c = await DatabaseHelper.addColumnInFTransactions();
      print("Column Info $c");
    }catch(ex){
      print(ex);
    }

    try{
      int? c = await DatabaseHelper.updateLinkedFlocketailNullValue();
      print("Flock Details Update Info $c");

      int? t = await DatabaseHelper.updateLinkedTransactionNullValue();
      print("Transactions Update Info $t");
    }catch(ex){
      print(ex);
    }
  }


}
