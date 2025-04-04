import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poultary/sticky.dart';
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
import 'package:google_mobile_ads/google_mobile_ads.dart';


class BackupRestoreScreen extends StatefulWidget {
  @override
  _BackupRestoreScreenState createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  RewardedAd? _rewardedAd;
  bool _isAdDisplayed = false;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkAutoBackupEnabled();
    Utils.setupAds();
    if(Utils.isShowAdd){
      _loadRewardedAd();
    }

  }
  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: Utils.rewardedAdUnitId, // Replace with your AdMob Rewarded Ad Unit ID
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          setState(() {
            _rewardedAd = ad;
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load rewarded ad: $error');
        },
      ),
    );
  }
  // Show Rewarded Ad
  void _showRewardedAd() {
    if (_rewardedAd == null) {
      print('Rewarded Ad not loaded yet');
      Utils.showInterstitial();
      return;
    }

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        print('User earned reward: ${reward.amount} ${reward.type}');
        // Grant the reward (e.g., unlock content, give in-app currency)
      },
    );

    // Dispose and reload the ad after it's used
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _loadRewardedAd();
      },
    );

    _rewardedAd = null;
  }

  void checkAutoBackupEnabled() async {
    isAutoBackupEnabled = await SessionManager.isAutoOnlineBackup();
    /*if(isAutoBackupEnabled)
      uploadDatabaseToDrive();*/
    if(isAutoBackupEnabled){
     signInWithGoogle();
    }
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

        child:SingleChildScrollViewWithStickyFirstWidget(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Utils.getDistanceBar(),

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

               /* await DatabaseHelper.importDataBaseFile(context);
                try
                {
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
                }*/

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

            /// **Automatic Cloud Backup - Card Option**
            SizedBox(height: 20),
            _buildCloudBackupCard(),
          ],
        ),
      ),),
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
                "RESTORE".tr(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 8),
              Text(
                "Choose a restore method to recover your data.".tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              SizedBox(height: 16),

              /// **Restore from Local Storage**
              _buildRestoreOption(
                icon: MdiIcons.folderOpen,
                title: "Restore from Local Storage".tr(),
                subtitle: "Select a backup file stored on your device.".tr(),
                onTap: () {
                  Navigator.pop(context);
                  onLocalRestore(); // Call the Local Restore function
                },
              ),

              SizedBox(height: 12),

              /// **Restore from Google Drive**
              _buildRestoreOption(
                icon: MdiIcons.googleDrive,
                title: "Restore from Google Drive".tr(),
                subtitle: "Retrieve the latest backup from Google Drive.".tr(),
                onTap: () {
                  Navigator.pop(context);
                  onDriveRestore(); // Call the Google Drive Restore function
                },
              ),

              SizedBox(height: 12),

              /// **Cancel Button**
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("CANCEL".tr(), style: TextStyle(fontSize: 16, color: Colors.redAccent)),
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
                    _googleSignIn.currentUser?.displayName ?? "Cloud Backup".tr(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 10),

          /// **Description**
          Text(
            "Turn on cloud backup to enable manual backup to Google Drive.".tr(),
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          SizedBox(height: 10),

          /// **Enable/Disable Switch**
          Container(
            margin: EdgeInsets.only(left: 5, right: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isAutoBackupEnabled? "Account Connected".tr():"Sign In".tr(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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
          ),

          SizedBox(height: 5),

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
        child: backingUp? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 5), // Spacing between icon & text
            Text(
              "Backup In Progress...".tr(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        )  : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload, size: 24, color: Colors.white), // ✅ Cloud icon
            SizedBox(width: 10), // Spacing between icon & text
            Text(
              "Backup to Google Drive".tr(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
      print("Signed in as".tr()+": ${_googleSignIn.currentUser?.displayName}");
      Utils.showToast("Signed in as".tr()+ " ${_googleSignIn.currentUser?.displayName}");
      setState(() {

      });
    } catch (error) {
      print("Google Sign-In Error: $error");

    }
  }

  String getTodayBackupFileName() {
    final now = DateTime.now();
    return 'PoultryBackup_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}.db';
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    Utils.showToast("Signed Out".tr());
    print("User signed out");
  }

  bool backingUp = false;

  Future<void> uploadDatabaseToDrive() async {

    if(!_isAdDisplayed){
      _showRewardedAd();
      _isAdDisplayed = true;
      setState(() {

      });
    }

    if (_googleSignIn.currentUser == null) {
      print("User is not signed in.");
      iSUpload = true;
      isRestore = false;
      await signInWithGoogle();
      return;
    }

    setState(() {
      backingUp = true;
    });

    final authHeaders = await _googleSignIn.currentUser!.authHeaders;
    final authenticateClient = GoogleAuthClient(authHeaders!);
    final driveApi = drive.DriveApi(authenticateClient);

    File dbFile = await DatabaseHelper.getFilePathDB();
    if (!dbFile.existsSync()) {
      print("Database file not found!");
      Utils.showToast("❌ Database file not found!".tr());
      setState(() {
        backingUp = false;
      });
      return;
    }

    final fileName = getTodayBackupFileName(); // e.g., backup_2025_04_04.db
    final media = drive.Media(dbFile.openRead(), dbFile.lengthSync());

    // Check if today's backup already exists
    final existingFileId = await _getDriveFileIdByName(fileName, driveApi);

    var fileMetadata = drive.File()
      ..name = fileName
      ..parents = ["root"];

    try {
      if (existingFileId != null) {
        // ✅ Don't set parents when updating
        var updateMetadata = drive.File()..name = fileName;

        await driveApi.files.update(updateMetadata, existingFileId, uploadMedia: media);
        print("✅ Existing backup updated.");
        Utils.showToast("✅ Backup Updated Successfully".tr());
      } else {
        // ✅ Set parents only when creating
        var fileMetadata = drive.File()
          ..name = fileName
          ..parents = ["root"];

        await driveApi.files.create(fileMetadata, uploadMedia: media);
        print("✅ New database backup uploaded.");
        Utils.showToast("✅ Backup Created Successfully".tr());
      }
    }
    catch (e) {
      print("❌ Error uploading database: $e");
      Utils.showToast("❌ Could not Backup".tr());
    } finally {
      setState(() {
        backingUp = false;
      });
    }
  }
  Future<String?> _getDriveFileIdByName(String fileName, drive.DriveApi driveApi) async {
    try {
      final query = "name = '$fileName' and trashed = false";
      final result = await driveApi.files.list(q: query, spaces: 'drive');

      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      }
    } catch (e) {
      print("❌ Error while checking for existing file: $e");
    }
    return null;
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
      // Fetch the last 5 PoultryBackup files from Drive
      drive.FileList fileList = await driveApi.files.list(
        q: "name contains 'PoultryBackup_' and trashed = false",
        orderBy: "createdTime desc",
        $fields: "files(id,name,createdTime)",
        pageSize: 5,
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        print("❌ No backups found.");
        Utils.showToast("❌ No backups found.".tr());
        return;
      }

      // Show bottom dialog for selection
      showBackupSelectionDialog(context, fileList.files!, (drive.File selectedFile) {
        _downloadAndRestoreBackup(selectedFile, driveApi);
      });

    } catch (e) {
      print("❌ Error fetching backups: $e");
    }
  }

  void showBackupSelectionDialog(
      BuildContext context,
      List<drive.File> files,
      Function(drive.File) onSelect,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "RESTORE".tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Select a backup file from the list below".tr(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: files.length,
                      separatorBuilder: (_, __) => Divider(),
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final isLatest = index == 0;
                        final createdTime = file.createdTime ?? DateTime.now();
                        final formattedDate =
                            "${createdTime.day.toString().padLeft(2, '0')}-${createdTime.month.toString().padLeft(2, '0')}-${createdTime.year}";

                        return ListTile(
                          leading: Icon(Icons.backup, color: Colors.blueAccent),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name ?? "Unknown".tr(),
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Utils.getThemeColorBlue()),
                              ),
                              if (isLatest)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    "Recommended".tr(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text("Created on".tr()+" $formattedDate"),
                          onTap: () {
                            Navigator.of(context).pop();
                            onSelect(file);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }




  void _downloadAndRestoreBackup(drive.File backupFile, drive.DriveApi driveApi) async {
    try {
      print("📥 Restoring from: ${backupFile.name}");

      var mediaStream = await driveApi.files.get(
        backupFile.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      if (mediaStream is! drive.Media) {
        print("❌ Invalid download stream.");
        return;
      }

      File dbFile = await DatabaseHelper.getFilePathDB();
      IOSink sink = dbFile.openWrite();

      mediaStream.stream.listen(
            (data) {
          sink.add(data);
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          print("✅ Database restored from ${backupFile.name}");
          Utils.showToast("✅ Restored from".tr() +"${backupFile.name}");
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
          );
        },
        onError: (error) {
          print("❌ Error restoring: $error");
        },
      );
    } catch (e) {
      print("❌ Exception: $e");
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
