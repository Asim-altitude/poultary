import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'database/databse_helper.dart';
import 'home_screen.dart';
import 'model/category_item.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;


class BackupRestoreScreen extends StatefulWidget {
  @override
  _BackupRestoreScreenState createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
   // checkAutoBackupEnabled();
  }

  void checkAutoBackupEnabled() async {
    isAutoBackupEnabled = await SessionManager.isAutoOnlineBackup();
    if(isAutoBackupEnabled)
      uploadDatabaseToDrive();

    setState(() {

    });
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

                showRestoreOptionsDialog(context, () async {
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
                }, () {
                  restoreDatabaseFromDrive();
                });


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

  /// **Show Restore Options Dialog**
  void showRestoreOptionsDialog(BuildContext context, VoidCallback onLocalRestore, VoidCallback onDriveRestore) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Rounded top corners
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// **Header**
              Text(
                "Restore Database",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 8),
              Text(
                "Choose a restore method to recover your data.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              SizedBox(height: 16),

              /// **Restore from Local Storage**
              _buildRestoreOption(
                icon: MdiIcons.folderOpen,
                title: "Restore from Local Storage",
                subtitle: "Select a backup file stored on your device.",
                onTap: () {
                  Navigator.pop(context);
                  onLocalRestore(); // Call the Local Restore function
                },
              ),

              SizedBox(height: 12),

              /// **Restore from Google Drive**
              _buildRestoreOption(
                icon: MdiIcons.googleDrive,
                title: "Restore from Google Drive",
                subtitle: "Retrieve the latest backup from Google Drive.",
                onTap: () {
                  Navigator.pop(context);
                  onDriveRestore(); // Call the Google Drive Restore function
                },
              ),

              SizedBox(height: 12),

              /// **Cancel Button**
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel", style: TextStyle(fontSize: 16, color: Colors.redAccent)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// **Reusable Restore Option Widget**
  Widget _buildRestoreOption({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1.2),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            /// **Icon**
            CircleAvatar(
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              radius: 28,
              child: Icon(icon, color: Colors.blueAccent, size: 28),
            ),
            SizedBox(width: 12),

            /// **Title & Subtitle**
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ),

            /// **Forward Arrow**
            Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
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

  /// **Cloud Backup Card**
  bool isAutoBackupEnabled = false; // Cloud Backup Switch State

  /// **Cloud Backup Card**
  Widget _buildCloudBackupCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// **Header: Show Profile If Signed In, Else Show Default Cloud Backup Icon**
          InkWell(
            onTap: () {
              if (_googleSignIn.currentUser != null) {
                signOut().then((_) => signInWithGoogle()); // ✅ Switch Account
              } else {
                signInWithGoogle(); // ✅ Sign In
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                if (_googleSignIn.currentUser != null)
                /// **Show Profile Picture If Signed In**
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(_googleSignIn.currentUser!.photoUrl ?? ""),
                    backgroundColor: Colors.white,
                  )
                else
                /// **Show Default Upload Icon If Not Signed In**
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    radius: 30,
                    child: Icon(Icons.cloud_upload, color: Colors.white, size: 28),
                  ),
                SizedBox(width: 12),

                Expanded(
                  child: Text(
                    _googleSignIn.currentUser?.displayName ?? "Cloud Backup",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 10),

          /// **Description**
          Text(
            "Turn on cloud backup to enable manual backup to Google Drive.",
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          SizedBox(height: 10),

          /// **Enable/Disable Switch**
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Cloud Backup", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Switch(
                value: isAutoBackupEnabled,
                onChanged: (bool value) {
                  setState(() {
                    isAutoBackupEnabled = value;
                  });

                  SessionManager.setOnlineBackup(isAutoBackupEnabled);
                  if (isAutoBackupEnabled) {
                    signInWithGoogle();
                  } else {
                    signOut();
                  }
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.greenAccent,
              ),
            ],
          ),

          SizedBox(height: 10),

          /// **Backup Button (Only Visible When Cloud Backup is Enabled)**
          AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            child: isAutoBackupEnabled
                ? _buildBackupButton() // ✅ Show Backup Button when ON
                : SizedBox(), // Hide when OFF
          ),
        ],
      ),
    );
  }


  /// **Google Drive Backup Button**
  Widget _buildBackupButton() {
    return Container(
      margin: EdgeInsets.only(top: 10), // Add spacing above the button
      width: double.infinity, // Full-width button
      child: ElevatedButton(
        onPressed: uploadDatabaseToDrive, // ✅ Calls backup function
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16), // Bigger button
          backgroundColor: Colors.green, // Primary color
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6, // Smooth shadow effect
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload, size: 24, color: Colors.white), // ✅ Cloud icon
            SizedBox(width: 10), // Spacing between icon & text
            Text(
              "Backup to Google Drive",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  );

  Future<void> signInWithGoogle() async {
    try {
      await _googleSignIn.signIn();
      print("Signed in as: ${_googleSignIn.currentUser?.displayName}");
      Utils.showToast("Signed In as ${_googleSignIn.currentUser?.displayName}");
      setState(() {

      });
    } catch (error) {
      print("Google Sign-In Error: $error");


    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    Utils.showToast("Signed Out");
    print("User signed out");
  }

  Future<void> uploadDatabaseToDrive() async {
    if (_googleSignIn.currentUser == null) {
      print("User is not signed in.");
      iSUpload = true;
      isRestore = false;
      await signInWithGoogle();
      return;
    }

    final authHeaders = await _googleSignIn.currentUser!.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders!);
    final driveApi = drive.DriveApi(authenticateClient);

    File dbFile = await DatabaseHelper.getFilePathDB();
    if (!dbFile.existsSync()) {
      print("Database file not found!");
      return;
    }

    var fileMetadata = drive.File()
      ..name = "PoultryBackup_${DateTime.now().millisecondsSinceEpoch}.db"
      ..parents = ["root"]; // ✅ Store in the user's main Google Drive (Visible)

    try {
      await driveApi.files.create(
        fileMetadata,
        uploadMedia: drive.Media(dbFile.openRead(), dbFile.lengthSync()),
      );

      print("✅ Database backup uploaded to Google Drive (User-Visible).");
      Utils.showToast("✅ Backup Successfull");
    } catch (e) {
      print("❌ Error uploading database: $e");
      Utils.showToast("❌ Could not Backup ");
    }
  }

  Future<drive.File?> getLatestBackup(drive.DriveApi driveApi) async {
    drive.FileList fileList = await driveApi.files.list(
      q: "name contains 'PoultryBackup_'",
      orderBy: "createdTime desc",
    );

    return fileList.files?.isNotEmpty == true ? fileList.files!.first : null;
  }

  bool iSUpload = false;
  bool isRestore = false;

  Future<void> restoreDatabaseFromDrive() async {
    if (_googleSignIn.currentUser == null) {
      print("User is not signed in.");
      iSUpload = false;
      isRestore = true;
      await signInWithGoogle();
      return;
    }

    final authHeaders = await _googleSignIn.currentUser!.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders);
    final driveApi = drive.DriveApi(authenticateClient);

    try {
      // **Fetch the latest backup file from Google Drive**
      drive.FileList fileList = await driveApi.files.list(
        q: "name contains 'PoultryBackup_'", // ✅ Looks for backup files
        orderBy: "createdTime desc", // ✅ Gets the latest backup first
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        print("❌ No backups found in Google Drive.");
        return;
      }

      drive.File latestBackup = fileList.files!.first; // ✅ Pick the latest backup
      print("📥 Restoring from: ${latestBackup.name}");

      // **Download the backup file**
      var mediaStream = await driveApi.files.get(
        latestBackup.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      if (mediaStream is! drive.Media) {
        print("❌ Error: Downloaded media is invalid.");
        return;
      }

      File dbFile = await DatabaseHelper.getFilePathDB(); // ✅ Local database path
      IOSink sink = dbFile.openWrite();

      mediaStream.stream.listen(
            (data) {
          sink.add(data);
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          print("✅ Database restored successfully!");
          Utils.showToast("✅ Database restored successfully!");
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeScreen()), // ✅ Replace with your Home Screen
                (Route<dynamic> route) => false, // ✅ Removes all previous screens
          );
        },
        onError: (error) {
          print("❌ Error restoring database: $error");
        },
      );
    } catch (e) {
      print("❌ Exception during restore: $e");
    }
  }

}

/// **GoogleAuthClient: Authenticated HTTP Client for Google Drive API**
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
