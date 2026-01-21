import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/multiuser/classes/AuthGate.dart';
import 'package:poultary/multiuser/classes/farm_welcome_screen.dart';
import 'package:poultary/multiuser/model/farm_plan.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/utils/session_manager.dart';
import '../../model/custom_category.dart';
import '../../model/custom_category_data.dart';
import '../../model/feed_ingridient.dart';
import '../../model/feed_item.dart';
import '../../model/flock_detail.dart';
import '../../model/med_vac_item.dart';
import '../../model/sub_category_item.dart';
import '../../utils/fb_analytics.dart';
import '../../utils/utils.dart';
import '../api/server_apis.dart';
import '../model/birds_modification.dart';
import '../model/egg_record.dart';
import '../model/feedbatchfb.dart';
import '../model/feedstockfb.dart';
import '../model/financeItem.dart';
import '../model/flockfb.dart';
import '../model/medicinestockfb.dart';
import '../model/role.dart';
import '../model/sync_queue.dart';
import '../model/user.dart';
import '../model/vaccinestockfb.dart';
import '../utils/SyncStatus.dart';
import 'AccessExpiredWidget.dart';
import 'all_roles_screen.dart';
import 'all_users_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'backup_restore.dart';


class AdminProfileScreen extends StatefulWidget {
  final MultiUser users;
  const AdminProfileScreen({Key? key, required this.users}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreen();
}

class _AdminProfileScreen extends State<AdminProfileScreen> {

  List<String> availableRoles = [];

  Future<List<String>> loadRolesByFarm(String farmId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('roles')
        .where('farm_id', isEqualTo: farmId)
        .get();

    return querySnapshot.docs
        .map((doc) => Role.fromJson(doc.data()).name)
        .toList();
  }

  Future<void> fetchRoles() async {

    String farmID = Utils.currentUser!.farmId;
    availableRoles = await loadRolesByFarm(farmID);
    setState(() {
    });
  }

  bool isUploading = false;
  Future<void> handleLogout(BuildContext context) async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Optionally: clear local user session (if you store it in SQLite or SharedPreferences)
      // Example if using SQLite:

      await Utils.logoutUser();
      // Navigate to login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AuthGate(isStart: true)),
            (route) => false,
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Logout Failed"),
          content: Text(e.toString()),
        ),
      );
    }
  }


  Future<void> showEditBottomSheet() {
    final nameController = TextEditingController(text: adminUser!.name);
    String selectedRole = adminUser!.role;
    bool isActive = adminUser!.active; // assuming 1 = active, 0 = inactive
    XFile? selectedImage; // picked image file
    String? imageUrl = adminUser!.image; // existing image


    Future<void> pickImage(Function setModalState) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // reduce size for faster upload
      );

      if (pickedFile != null) {
        setModalState(() {
          selectedImage = pickedFile; // your XFile? variable
        });
      }
    }


    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Wrap(
              children: [
                Center(
                  child: Text(
                    "Edit User".tr(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                // Profile Picture
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: selectedImage != null
                            ? FileImage(File(selectedImage!.path))
                            : (imageUrl != null && imageUrl!.isNotEmpty)
                            ? NetworkImage(Utils.ProxyAPI+imageUrl!) as ImageProvider
                            : null, // No image when we want to show the icon
                        child: (selectedImage == null && (imageUrl == null || imageUrl!.isEmpty))
                            ? Icon(Icons.person, size: 50, color: Colors.blue)
                            : null,
                        backgroundColor: Colors.blue.shade100,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () {
                            pickImage(setModalState);
                          },
                          child: CircleAvatar(
                            backgroundColor: Colors.indigo,
                            radius: 18,
                            child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Name".tr(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),


                SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.save_alt, color: Colors.white),
                    label: Text(
                      "SAVE".tr(),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {

                      try {
                        Utils.showLoading();
                        String userId = adminUser!.email
                            .split('@')
                            .first;

                        File file = await Utils.convertToJPGFileIfRequiredWithCompression(File(selectedImage!.path));


                        final bytes = await file.readAsBytes();
                        final base64Image = 'data:image/jpeg;base64,${base64Encode(
                            bytes)}';
                        imageUrl = await FlockImageUploader()
                            .uploadProfilePicture(
                            userId: userId, base64Image: base64Image);


                        final updatedUser = MultiUser(
                          name: nameController.text.trim(),
                          email: adminUser!.email,
                          role: "Admin",
                          image: imageUrl!,
                          password: adminUser!.password,
                          farmId: adminUser!.farmId,
                          createdAt: adminUser!.createdAt,
                          active: isActive,
                        );

                        await updateUserInFirestore(updatedUser);

                        try{
                          await DatabaseHelper.updateUser(updatedUser);
                        }catch(e){
                          print(e);
                        }

                        setState(() {
                          adminUser = updatedUser;
                        });

                        Utils.hideLoading();
                      }
                      catch(ex){
                        Utils.showError();
                        print(ex);
                      }

                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }


  Future<void> updateUserInFirestore(MultiUser user) async {
    final query = await FirebaseFirestore.instance
        .collection(FireBaseUtils.USERS)
        .where('email', isEqualTo: user.email)
        .where('farm_id', isEqualTo: user.farmId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final docId = query.docs.first.id;
      await FirebaseFirestore.instance.collection(FireBaseUtils.USERS)
          .doc(docId)
          .update({
        'name': user.name,
        'image' : user.image,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await SessionManager.saveUserToPrefs(user);
      Utils.currentUser!.name = user.name;
      Utils.currentUser!.image = user.image;

    }
  }



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init();
    getSyncQueueList();
    fetchRoles();
    AnalyticsUtil.logScreenView(screenName: "admin_screen");

  }

  FarmPlan? farmPlan = null;
  MultiUser? adminUser = null;
  Future<void> init() async {

    adminUser = widget.users;

    farmPlan = await SessionManager.getFarmPlan();
    latestBackupTime = await SessionManager.getLastBackupTime();

    if(farmPlan!= null) {
      if (farmPlan!.isActive)
        await checkAndBackupIfNeeded(adminUser!.farmId);
    }
    else
    {
      farmPlan = FarmPlan(farmId: Utils.currentUser!.farmId, adminEmail: Utils.currentUser!.email, planName: "Premium", planType: "planType", planStartDate: DateTime.now().subtract(Duration(days: 2)), planExpiryDate: DateTime.now().subtract(Duration(days: 2)), userCapacity: 0);
    }

    setState(() {

    });

  }

  DateTime? lastBackupDate = null, latestBackupTime;
  /// Function to check if a backup already exists today, and if not, perform it
  Future<void> checkAndBackupIfNeeded(String farmId) async {
    final docRef = FirebaseFirestore.instance.collection(FireBaseUtils.DB_BACKUP).doc(farmId);
    final docSnapshot = await docRef.get(const GetOptions(source: Source.server));

    bool shouldBackup = true;

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      final Timestamp? lastTimestamp = data?['timestamp'];

      if (lastTimestamp != null) {
        lastBackupDate = lastTimestamp.toDate();
        final DateTime now = DateTime.now();

        if(latestBackupTime == null)
          latestBackupTime = lastBackupDate;

// Compare difference in full days between now and lastBackupDate
        final Duration difference = now.difference(lastBackupDate!);
        if (difference.inDays < 3) {
          shouldBackup = false;
          print("Backup done recently. Next backup allowed after ${3 - difference.inDays} day(s).");
        } else {
          shouldBackup = true;
        }

        print("Last Backup: ${DateFormat('yyyy-MM-dd').format(lastBackupDate!)}");
        print("Today: ${DateFormat('yyyy-MM-dd').format(now)}");

        setState(() {

        });
      }
    }

    if (shouldBackup) {
      setState(() {
        isUploading = true;
      });
      await FlockImageUploader().uploadDatabaseFile(farmId);

    }
  }

  /// Function to check if a backup already exists today, and if not, perform it
  Future<void> shouldDoBackup(String farmId) async {

    if (Utils.shouldBackup) {
      setState(() {
        isUploading = true;
      });
      await FlockImageUploader().uploadDatabaseFile(farmId);
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('admin_profile'.tr()),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.blue.shade50,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Avatar + Name/Details
                    InkWell(
                      onTap: () {
                        showEditBottomSheet();
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage: (adminUser!.image != null && adminUser!.image!.isNotEmpty)
                                    ? NetworkImage(Utils.ProxyAPI+adminUser!.image!)
                                    : null,
                                child: (adminUser!.image == null || adminUser!.image!.isEmpty)
                                    ? Icon(Icons.person, size: 35, color: Colors.blue)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    // Open image picker
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Icon(Icons.edit, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adminUser!.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  adminUser!.email,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                                Text(
                                  adminUser!.farmId,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                ),
                                SizedBox(height: 6),
                                Chip(
                                  label: Text("admin".tr()),
                                  backgroundColor: Colors.blue.shade100,
                                  labelStyle: TextStyle(color: Colors.blue.shade900, fontSize: 12),
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Backup Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () async {
                          setState(() {
                            isUploading = true;
                          });
                          await FlockImageUploader().uploadDatabaseFile(Utils.currentUser!.farmId);
                          latestBackupTime = await SessionManager.getLastBackupTime();
                          setState(() {

                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.backup, color: Colors.white, size: 18),
                                  SizedBox(width: 5),
                                  Text(
                                    " "+'BACKUP'.tr()+" ",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            latestBackupTime != null? Text('Last Backup'.tr()+" ${DateFormat('dd MMM yyyy HH:MM a').format(latestBackupTime!)}", style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.normal),) : Text('Last Backup'.tr()+" Unknown", style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.normal),)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Utils.isMultiUSer ? SizedBox.shrink() : AccessExpiredCard(
                onUpgrade: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FarmWelcomeScreen(multiUser: adminUser!, isStart: false,)),
                  );

                  init();
                },
              ),

              const SizedBox(height: 10),
              Visibility(
                visible: (pendingRecords == null || pendingRecords!.length==0) ? false : true,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: (pendingRecords == null || pendingRecords!.length==0)
                        ? null
                        : () {
                      try {
                       // getFlocksFromFirebase(Utils.currentUser!.farmId, synclastSyncTime);
                        sendPendingChangesToServer();
                      } catch (ex) {
                        print(ex);
                      }
                    },
                    icon: const Icon(Icons.sync),
                    label: pendingRecords == null
                        ?  Text("Send Changes".tr())
                        : Text("Send Changes".tr()+" (${pendingRecords!.length})"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              isUploading
                  ? Column(
                children: [
                  Text('backing_up_db'.tr(), style: TextStyle(color: Colors.grey)),
                  ValueListenableBuilder<double>(
                    valueListenable: uploadProgress,
                    builder: (context, value, _) {
                      if ((value * 100) == 100) {
                        Future.delayed(Duration(seconds: 6), () {
                          lastBackupDate = DateTime.now();

                          if (mounted) {
                            setState(() {
                              isUploading = false;
                            });
                          }
                        });
                      }
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LinearProgressIndicator(value: value),
                          SizedBox(height: 10),
                          Text("upload_progress".tr(args: [(value * 100).toStringAsFixed(0)])),
                        ],
                      );
                    },
                  ),
                ],
              )
                  : SizedBox.shrink(),

              SizedBox(height: 30),

              _AdminActionCard(
                icon: Icons.group,
                label: 'manage_users'.tr(),
                color: Colors.indigo,
                onTap: () async {
                  if (!farmPlan!.isActive) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FarmWelcomeScreen(multiUser: adminUser!, isStart: false,)),
                    );
                  } else {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AllUsersScreen()),
                    );
                    shouldDoBackup(adminUser!.farmId);
                  }
                },
              ),
              _AdminActionCard(
                icon: Icons.security,
                label: 'manage_roles'.tr(),
                color: Colors.green,
                onTap: () async {
                  if (!farmPlan!.isActive) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FarmWelcomeScreen(multiUser: adminUser!, isStart: false,)),
                    );
                  } else {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AllRolesScreen()),
                    );
                    shouldDoBackup(adminUser!.farmId);
                  }
                },
              ),
              /*_AdminActionCard(
                icon: Icons.sync,
                label: 'view_sync_info'.tr(),
                color: Colors.yellow,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SyncScreen()),
                  );
                },
              ),*/
              _AdminActionCard(
                icon: Icons.monetization_on,
                label: 'premium_plan'.tr(),
                color: Colors.orange,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FarmWelcomeScreen(multiUser: adminUser!, isStart: false,)),
                  );
                },
              ),
              _AdminActionCard(
                icon: Icons.logout,
                label: 'logout'.tr(),
                color: Colors.red,
                onTap: () {
                  showLogoutConfirmationDialog(context, () {
                    handleLogout(context);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String latestBackupUrl = "";

  Future<void> restoreData() async {
    try {
      latestBackupUrl = await getLatestBackupUrlFromFirestore(adminUser!.farmId);
      if (latestBackupUrl != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BackupFoundScreen(isAdmin: true, user: adminUser!,)),
        );
      }else{
        Utils.showToast("NOT_FOUND".tr());
      }

      setState(() {

      });
    }
    catch(ex){
      print(ex);
    }
  }

  Future<String> getLatestBackupUrlFromFirestore(String farmId) async {
    final doc = await FirebaseFirestore.instance.collection(FireBaseUtils.DB_BACKUP).doc(farmId).get();
    return doc.data()?['last_backup_url'] ?? '';
  }



  Future<void> showLogoutConfirmationDialog(BuildContext context, VoidCallback onConfirmLogout) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout_title'.tr()), // "Logout"
        content: Text('logout_message'.tr()), // "Are you sure you want to logout?"
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('CANCEL'.tr()), // "Cancel"
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              onConfirmLogout(); // Perform logout action
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text('logout'.tr()), // "Logout"
          ),
        ],
      ),
    );
  }


  List<SyncQueue>? pendingRecords = [];
  void sendPendingChangesToServer() async {
    if (pendingRecords == null || pendingRecords!.isEmpty) return;

    for (final record in pendingRecords!) {
      try {
        final model = record.toModel();

        print("MODEL ${record.type} ${record.operationType}");
        if (model is FlockFB) {
          switch (record.operationType) {
            case 'add':
            // TODO: addFlockToFirestore(model);

              FireBaseUtils.uploadFlock(model);
              break;
            case 'update':
            // TODO: updateFlockInFirestore(model);
              FireBaseUtils.updateFlock(model.flock);
              break;
            case 'delete':
            // TODO: deleteFlockFromFirestore(model.sync_id);
              model.flock.sync_status = SyncStatus.DELETED;
              FireBaseUtils.updateFlock(model.flock);
              break;
          }
        } else if (model is Feeding) {
          switch (record.operationType) {
            case 'add':
            // TODO: addFeeding(model);
              FireBaseUtils.uploadFeedingRecord(model);
              break;
            case 'update':
            // TODO: updateFeeding(model);
              FireBaseUtils.updateFeedingRecord(model);

              break;
            case 'delete':
            // TODO: deleteFeeding(model.sync_id);
              model.sync_status = SyncStatus.DELETED;
              FireBaseUtils.updateFeedingRecord(model);
              break;
          }
        } else if (model is Vaccination_Medication) {
          switch (record.operationType) {
            case 'add':
            // TODO: addHealthRecord(model);
              FireBaseUtils.uploadHealthRecord(model);
              break;
            case 'update':
            // TODO: updateHealthRecord(model);
              FireBaseUtils.updateHealthRecord(model);
              break;
            case 'delete':
            // TODO: deleteHealthRecord(model.sync_id);
              FireBaseUtils.deleteHealthRecord(model);
              break;
          }
        } else if (model is BirdsModification) {
          switch (record.operationType) {
            case 'add':
            // TODO: addBirdModification(model);
              FireBaseUtils.uploadBirdsDetails(model);
              break;
            case 'update':
            // TODO: updateBirdModification(model);
              FireBaseUtils.updateBirdsDetails(model);
              break;
            case 'delete':
            // TODO: deleteBirdModification(model.sync_id);
              FireBaseUtils.deleteBirdsDetails(model);
              break;
          }
        } else if (model is EggRecord) {
          switch (record.operationType) {
            case 'add':
            // TODO: addEggRecord(model);
              FireBaseUtils.uploadEggRecord(model);
              break;
            case 'update':
            // TODO: updateEggRecord(model);
              FireBaseUtils.updateEggRecord(model);
              break;
            case 'delete':
            // TODO: deleteEggRecord(model.sync_id);
              FireBaseUtils.deleteEggRecord(model);
              break;
          }
        } else if (model is FinanceItem) {
          switch (record.operationType) {
            case 'add':
            // TODO: addFinanceItem(model);
              FireBaseUtils.uploadExpenseRecord(model);
              break;
            case 'update':
            // TODO: updateFinanceItem(model);
              FireBaseUtils.updateExpenseRecord(model);
              break;
            case 'delete':
            // TODO: deleteFinanceItem(model.sync_id);
              FireBaseUtils.deleteFinanceRecord(model);
              break;
          }
        } else if (model is Flock_Detail) {
          switch (record.operationType) {
            case 'add':
            // TODO: addFlockDetail(model);
              break;
            case 'update':
            // TODO: updateFlockDetail(model);
              break;
            case 'delete':
            // TODO: deleteFlockDetail(model.sync_id);
              break;
          }
        } else if (model is CustomCategory) {
          switch (record.operationType) {
            case 'add':
            // TODO: addCustomCategory(model);
              FireBaseUtils.addCustomCategory(model);
              break;
            case 'update':
            // TODO: updateCustomCategory(model);
              FireBaseUtils.updateCustomCategory(model);
              break;
            case 'delete':
            // TODO: deleteCustomCategory(model.sync_id);
              model.sync_status = SyncStatus.DELETED;
              FireBaseUtils.updateCustomCategory(model);
              break;
          }
        } else if (model is CustomCategoryData) {
          switch (record.operationType) {
            case 'add':
            // TODO: addCustomCategoryData(model);
              FireBaseUtils.addCustomCategoryData(model);
              break;
            case 'update':
            // TODO: updateCustomCategoryData(model);
              FireBaseUtils.updateCustomCategoryData(model);
              break;
            case 'delete':
            // TODO: deleteCustomCategoryData(model.sync_id) model.sync_status = SyncStatus.DELETED;
              model.sync_status = SyncStatus.DELETED;
              FireBaseUtils.updateCustomCategoryData(model);
              break;
          }
        } else if (model is FeedStockFB) {
          switch (record.operationType) {
            case 'add':
            // TODO: addFeedStock(model);
              FireBaseUtils.uploadFeedStockHistory(model);
              break;
            case 'update':
            // TODO: updateFeedStock(model);
              break;
            case 'delete':
            // TODO: deleteFeedStock(model.feedStock.sync_id);
              model.sync_status = SyncStatus.DELETED;
              FireBaseUtils.updateFeedStockHistory(model);

              break;
          }
        } else if (model is MedicineStockFB) {
          switch (record.operationType) {
            case 'add':
            // TODO: addMedicineStock(model);
              FireBaseUtils.uploadMedicineStock(model);
              break;
            case 'update':
            // TODO: updateMedicineStock(model);
              FireBaseUtils.updateMedicineStock(model);
              break;
            case 'delete':
            // TODO: deleteMedicineStock(model.medicineStock.sync_id);
              model.sync_status = SyncStatus.DELETED;
              FireBaseUtils.updateMedicineStock(model);
              break;
          }
        } else if (model is VaccineStockFB) {
          switch (record.operationType) {
            case 'add':
            // TODO: addVaccineStock(model);
              FireBaseUtils.uploadVaccineStock(model);

              break;
            case 'update':
            // TODO: updateVaccineStock(model);
              FireBaseUtils.updateVaccineStock(model);

              break;
            case 'delete':
            // TODO: deleteVaccineStock(model.vaccineStock.sync_id);
              model.sync_status = SyncStatus.DELETED;
              FireBaseUtils.updateVaccineStock(model);

              break;
          }
        } else if (model is FeedIngredient) {
          switch (record.operationType) {
            case 'add':
            // TODO: addFeedIngredient(model);
              FireBaseUtils.addFeedIngredient(model);
              break;
            case 'update':
            // TODO: updateFeedIngredient(model);
              FireBaseUtils.updateFeedIngredient(model);
              break;
            case 'delete':
            // TODO: deleteFeedIngredient(model.sync_id);
              model.sync_status  = SyncStatus.DELETED;
              FireBaseUtils.updateFeedIngredient(model);
              break;
          }
        } else if (model is FeedBatchFB) {
          switch (record.operationType) {
            case 'add':
            // TODO: addFeedBatch(model);
              FireBaseUtils.addFeedBatch(model);

              break;
            case 'update':
            // TODO: updateFeedBatch(model);
              FireBaseUtils.updateFeedBatch(model);
              break;
            case 'delete':
            // TODO: deleteFeedBatch(model.feedbatch.sync_id);
              model.sync_status = SyncStatus.DELETED;
              FireBaseUtils.updateFeedBatch(model);
              break;
          }
        } else if (model is SubItem) {
          switch (record.operationType) {
            case 'add':
            // TODO: addFeedBatch(model);
              FireBaseUtils.addSubCategory(model);

              break;
            case 'update':
            // TODO: updateFeedBatch(model);
              FireBaseUtils.updateSubCategory(model);
              break;
            case 'delete':
            // TODO: deleteFeedBatch(model.feedbatch.sync_id);
              model.syncStatus = SyncStatus.DELETED;
              FireBaseUtils.updateSubCategory(model);
              break;
          }
        } else {
          print("⚠️ Unknown model type for sync: ${record.type}");
        }

        print("SYNC SUCCESS ${record.type} ${record.operationType}");
        // ✅ If success, remove from queue
        await DatabaseHelper.deleteSyncQueueRecord(record.id!);

      } catch (e, stacktrace) {
        print('❌ Sync failed for ${record.type} (${record.syncId}): ${record.payload} $e');

        int retryCunt = record.retryCount++;
        await DatabaseHelper.updateSyncQueueError(
          id: record.id!,
          error: e.toString(), retryCount: retryCunt,
        );
      }
    }

    await getSyncQueueList();
  }

  Future<void> getSyncQueueList() async {
    try {
      pendingRecords = await DatabaseHelper.getAllSyncQueueItems(Utils.currentUser!.email);

      setState(() {

      });
    }
    catch(ex){
      print(ex);
    }
  }



}

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }




}
