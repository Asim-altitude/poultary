import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:language_picker/languages.dart';
import 'package:language_picker/languages.g.dart';
import 'package:poultary/add_reduce_flock.dart';
import 'package:poultary/daily_feed.dart';
import 'package:poultary/egg_collection.dart';
import 'package:poultary/multiuser/model/role_permissions.dart';
import 'package:poultary/multiuser/model/user.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/settings_screen.dart';
import 'package:poultary/transactions_screen.dart';
import '../../database/databse_helper.dart';
import '../../medication_vaccination.dart';
import '../../model/custom_category.dart';
import '../../model/custom_category_data.dart';
import '../../model/feed_ingridient.dart';
import '../../model/feed_item.dart';
import '../../model/flock.dart';
import '../../model/flock_detail.dart';
import '../../model/flock_image.dart';
import '../../model/med_vac_item.dart';
import '../../model/sub_category_item.dart';
import '../../new_reporting_Screen.dart';
import '../../stock/main_inventory_screen.dart';
import '../../utils/session_manager.dart';
import '../../utils/utils.dart';
import '../api/server_apis.dart';
import '../model/birds_modification.dart';
import '../model/egg_record.dart';
import '../model/feedbatchfb.dart';
import '../model/feedstockfb.dart';
import '../model/financeItem.dart';
import '../model/flockfb.dart';
import '../model/medicinestockfb.dart';
import '../model/sync_queue.dart';
import '../model/vaccinestockfb.dart';
import '../utils/RefreshEventBus.dart';
import '../utils/SyncManager.dart';
import '../utils/SyncStatus.dart';
import 'AuthGate.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io' as io;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'NetworkAcceessNotifier.dart';
import 'all_flocks_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  final String name;
  final String email;
  final String role;

  const WorkerDashboardScreen({
    Key? key,
    required this.name,
    required this.email,
    required this.role,
  }) : super(key: key);

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  final List<String> modules = [
    "Flocks",
    "Eggs",
    "Birds",
    "Finance",
    "Feed",
    "Health",
    "Stock",
    "Reports",
    "Settings",
  ];

  final Map<String, String> modulePermissionMap = {
    "Flocks": "view_flocks",
    "Eggs": "view_eggs",
    "Birds": "view_birds",
    "Finance": "view_transaction",
    "Feed": "view_feed",
    "Health": "view_health",
    "Stock": "view_stock",
    "Reports": "view_reports",
    "Settings": "view_settings",
  };

  ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  final _networkNotifier = NetworkSnackNotifier();


  final supportedLanguages = [
    Languages.english,
    Languages.arabic,
    Languages.russian,
    Languages.persian,
    Languages.german,
    Languages.japanese,
    Languages.korean,
    Languages.portuguese,
    Languages.turkish,
    Languages.french,
    Languages.italian,
    Languages.indonesian,
    Languages.hindi,
    Languages.spanish,
    Languages.chineseSimplified,
    Languages.ukrainian,
    Languages.polish,
    Languages.bengali,
    Languages.telugu,
    Languages.tamil,
    Languages.greek
  ];
  double widthScreen = 0;
  double heightScreen = 0;
  late Language _selectedCupertinoLanguage;
  bool isGetLanguage = false;
  getLanguage() async {
    _selectedCupertinoLanguage = await Utils.getSelectedLanguage();
    setState(() {
      isGetLanguage = true;

    });

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


  bool changes_made = true;
  Future<void> postUserLog(String farmId, String email) async {
    final firestore = FirebaseFirestore.instance;
    final docId = '${farmId}_$email';

    final logRef = firestore.collection('user_log').doc(docId);
    final doc = await logRef.get();

    String dataChanges = "no";

    if (doc.exists) {
      final lastSigned = (doc.data()?['last_signed'] as Timestamp).toDate();

       // implement this
      if (changes_made) {
        dataChanges = "yes";
      }
    } else {
      dataChanges = "yes"; // First login, assume fresh data
    }

    await logRef.set({
      'farm_id': farmId,
      'email': email,
      'last_signed': FieldValue.serverTimestamp(),
      'data_changes': dataChanges,
    });
  }

  void logout() async {

    await FirebaseAuth.instance.signOut();

    await Utils.logoutUser();
    // Navigate to login screen
    Navigator.pushAndRemoveUntil(context,
      MaterialPageRoute(builder: (_) => AuthGate(isStart: true)),
          (route) => false,);
  }

  Future<void> fetchAndInitializeDatabaseWithProgress(String farmId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool initialized = prefs.getBool('db_initialized_$farmId') ?? false;

    if (initialized) {
      print("Database already initialized for farm $farmId");
      setupDataListners();
      postUserLog(user!.farmId, user!.email);

      return;
    }

    downloadingDB = true;
    try {
      final latestBackupUrl = await getLatestBackupUrlFromFirestore(farmId);

      print("BACKUP_URL $latestBackupUrl");
      final uri = Uri.parse(latestBackupUrl);
      final client = http.Client();
      final request = http.Request('GET', uri);
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception("Failed to download DB file");
      }

      // Prepare file path
      final dbDir = await getDatabasesPath();
      final dbPath = p.join(dbDir, 'poultry.db');
      final file = io.File(dbPath);
      final sink = file.openWrite();

      final contentLength = response.contentLength ?? 0;
      int bytesReceived = 0;

      // Listen to stream and write to file while updating progress
      await response.stream.listen(
            (chunk) {
          bytesReceived += chunk.length;
          sink.add(chunk);
          if (contentLength > 0) {
            downloadProgress.value = bytesReceived / contentLength;
          }
        },
        onDone: () async {
          await sink.close();
          await prefs.setBool('db_initialized_$farmId', true);
          downloadProgress.value = 1.0;
          print("Database download complete.");
          downloadingDB = false;
        },
        onError: (e) {
          isUSerActive = false;
          isErrorOccured = true;
          setState(() {

          });
          sink.close();
          throw Exception("Download failed: $e");
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("Error during DB download: $e");
      isUSerActive = false;
      isErrorOccured = true;
      setState(() {

      });
      rethrow;
    }
  }

  Future<String> getLatestBackupUrlFromFirestore(String farmId) async {
    final doc = await FirebaseFirestore.instance.collection(FireBaseUtils.DB_BACKUP).doc(farmId).get();
    return doc.data()?['last_backup_url'] ?? '';
  }

  RoleWithPermissions? rolePerms = null;
  bool isUSerActive = true;
  bool isErrorOccured = false;
  MultiUser? user = null;
  Future<void> loadLatestUser() async {
    user = await SessionManager.getUserFromPrefs();
    final snapshot = await FirebaseFirestore.instance
        .collection(FireBaseUtils.USERS)
        .where('email', isEqualTo: widget.email)
        .where('farm_id', isEqualTo: user!.farmId)
        .limit(1)
        .get();

    final doc = snapshot.docs.first;
    Utils.currentUser = MultiUser.fromMap(doc.data());

    Utils.isUSerActive = snapshot.docs.first.data()['active']! == 1? true : false;
   // print("isUSerActive $isUSerActive");
    final querySnapshot = await FirebaseFirestore.instance
        .collection('roles_permissions')
        .doc(user!.farmId+"_"+user!.role)
        .get();

    if (querySnapshot.exists) {
      final data = querySnapshot.data();
      rolePerms =  RoleWithPermissions.fromMap(data!);
      Utils.rolePerms = rolePerms;// return as a list
     // print("PERMS ${rolePerms!.toMap()}");
    }

    startUserActiveListener();
    startRolePermissionListener();

    fetchAndInitializeDatabaseWithProgress(user!.farmId);

    setState(() {

    });
  }

  StreamSubscription? userActiveSub;

  void startUserActiveListener() {
    userActiveSub = FirebaseFirestore.instance
        .collection(FireBaseUtils.USERS)
        .where('email', isEqualTo: user!.email)
        .where('farm_id', isEqualTo: user!.farmId)
        .limit(1)
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final docData = querySnapshot.docs.first.data();

        Utils.currentUser = MultiUser.fromMap(docData);

        Utils.isUSerActive = (docData['active'] ?? 0) == 1;
        print("👤 User active status updated: ${Utils.isUSerActive}");

        // Optionally notify UI
       // RefreshEventBus().emit("USER_ACTIVE_UPDATED");
      } else {
        print("⚠️ No user document found for this email+farmId");
      }
    });
  }

  void stopUserActiveListener() {
    userActiveSub?.cancel();
    userActiveSub = null;
  }

  Future<void> showEditBottomSheet() async {
    final nameController = TextEditingController(text: Utils.currentUser!.name);
    String selectedRole = Utils.currentUser!.role;
    bool isActive = Utils.currentUser!.active; // assuming 1 = active, 0 = inactive
    XFile? selectedImage; // picked image file
    String? imageUrl = Utils.currentUser!.image; // existing image


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


    final updated = await showModalBottomSheet<MultiUser>(
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
                            ? FileImage(io.File(selectedImage!.path))
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
                        String userId = Utils.currentUser!.email
                            .split('@')
                            .first;


                        if(selectedImage != null) {
                          io.File file = await Utils
                              .convertToJPGFileIfRequiredWithCompression(
                              io.File(selectedImage!.path));

                          final bytes = await file.readAsBytes();
                          final base64Image = 'data:image/jpeg;base64,${base64Encode(
                              bytes)}';
                          imageUrl = await FlockImageUploader()
                              .uploadProfilePicture(
                              userId: userId, base64Image: base64Image);
                        }

                        final updatedUser = MultiUser(
                          name: nameController.text.trim(),
                          email: Utils.currentUser!.email,
                          role: selectedRole,
                          image: imageUrl!,
                          password: "",
                          farmId: Utils.currentUser!.farmId,
                          createdAt: Utils.currentUser!.createdAt,
                          active: isActive,
                        );

                        await updateUserInFirestore(updatedUser);

                        try{
                          await DatabaseHelper.updateUser(updatedUser);
                        }catch(e){
                          print(e);
                        }

                        refreshState(updatedUser);

                        Utils.hideLoading();

                        Navigator.pop(context, updatedUser);
                      }
                      catch(ex){
                        Utils.showError();
                        Navigator.pop(context, null);
                        print(ex);
                      }

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


    if (updated != null) {
      setState(() {
        Utils.currentUser = updated;
      });
    }
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



  void startRolePermissionListener() {
    FirebaseFirestore.instance
        .collection('roles_permissions')
        .doc("${user!.farmId}_${user!.role}")
        .snapshots()
        .listen((docSnapshot) {
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          rolePerms = RoleWithPermissions.fromMap(data);
          Utils.rolePerms = rolePerms;

          print("🔄 Role permissions updated: ${rolePerms!.toMap()}");

          // Notify other parts of app if needed
         // RefreshEventBus().emit("ROLE_PERMISSIONS_UPDATED");

          setState(() {

          });
        }
      } else {
        print("⚠️ No permissions found for this role");
      }
    });
  }



  bool downloadingDB = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    getSyncQueueList();
    loadLatestUser();
    getLanguage();


    WidgetsBinding.instance.addPostFrameCallback((_) {
      _networkNotifier.initialize(context);

    });

  }

  Future<void> initSettings() async {
    await Utils.generateDatabaseTables();

    try {
      List<String> tables = Utils.getTAllables(); // Add your actual table names

      for (final table in tables) {
        await DatabaseHelper.instance.addSyncColumnsToTable(table);
        await DatabaseHelper.instance.assignSyncIds(table);
      }

      await SessionManager.setBoolValue(SessionManager.table_created, true);
      print('TABLE CREATION DONE');
    }
    catch(ex){
      print(ex);
    }
  }

  Future<void> getSyncQueueList() async {
    await initSettings();
    try {
      pendingRecords = await DatabaseHelper.getAllSyncQueueItems(Utils.currentUser!.email);

      setState(() {

      });
    }
    catch(ex){
      print(ex);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Worker Dashboard".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          // Language Selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Container(
                        color: Colors.white,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: supportedLanguages.length,
                          itemBuilder: (context, index) {
                            final language = supportedLanguages[index];
                            return ListTile(
                              title: Text("${language.name} (${language.isoCode})"),
                              onTap: () {
                                setState(() {
                                  _selectedCupertinoLanguage = language;
                                });
                                Utils.setSelectedLanguage(language, context);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      _selectedCupertinoLanguage.name.toLowerCase().startsWith("chinese")
                          ? "zh"
                          : _selectedCupertinoLanguage.isoCode,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: () {
                showLogoutConfirmationDialog(context, () {
                  logout();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children:  [
                    Icon(Icons.logout, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text("logout".tr(), style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),
        body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 16),
            downloadingDB? ValueListenableBuilder<double>(
              valueListenable: downloadProgress,
              builder: (context, value, _) {
                if (value == 1.0) return SizedBox(); // Hide when complete
                return Column(
                  children: [
                    Text("Downloading database...".tr()),
                    LinearProgressIndicator(value: value),
                    SizedBox(height: 8),
                    Text("Progress:".tr()+" ${(value * 100).toStringAsFixed(0)}%"),
                  ],
                );
              },
            ) : SizedBox.shrink(),
            const SizedBox(height: 16),
            (isErrorOccured)? Text('Error Occurred. Logout and Login again.'.tr(), style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),) : SizedBox.shrink(),
            _buildModuleGrid(),
          ],
        ),
      ),
    );
  }


  void refreshState(MultiUser updated) {
    setState(() {
      Utils.currentUser = updated;
    });
  }

  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            // Header Section with Gradient Background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: (Utils.currentUser!.image != null &&
                            Utils.currentUser!.image!.isNotEmpty)
                            ? NetworkImage(Utils.ProxyAPI+Utils.currentUser!.image!)
                            : null,
                        child: (Utils.currentUser!.image == null ||
                            Utils.currentUser!.image!.isEmpty)
                            ? Icon(Icons.person, size: 40, color: Colors.blue)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            showEditBottomSheet();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.email,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.role,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 5,
                                  backgroundColor: isUSerActive ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isUSerActive ? 'Active'.tr() : 'Disabled'.tr(),
                                  style: TextStyle(
                                    color: isUSerActive ? Colors.greenAccent : Colors.redAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action Button Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Visibility(
                visible: (pendingRecords != null && pendingRecords!.isNotEmpty),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      try {
                        getFlocksFromFirebase(Utils.currentUser!.farmId, synclastSyncTime);
                        sendPendingChangesToServer();
                      } catch (ex) {
                        print(ex);
                      }
                    },
                    icon: const Icon(Icons.sync),
                    label: Text(
                      pendingRecords == null
                          ? "Send Changes".tr()
                          : "Send Changes".tr() + " (${pendingRecords!.length})",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
        children: modules.map((module) {
          bool hasPermission = rolePerms?.permissions.contains(modulePermissionMap[module]) ?? false;
          bool isDisabled = !isUSerActive || !hasPermission;

          IconData moduleIcon = _getModuleIcon(module); // Map module to icon

          return GestureDetector(
            onTap: () {
              if (!isUSerActive) {
                _showBlockedMessage("Your access is blocked by Admin".tr());
                return;
              }
              if (!hasPermission) {
                _showBlockedMessage("You do not have permission to access".tr() + " $module");
                return;
              }
              _navigateToModule(module);
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isDisabled ? 0.4 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: isDisabled ? null : () => _navigateToModule(module),
                    splashColor: Colors.white24,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Icon(moduleIcon, color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            module.tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Helper function to map module names to icons
  IconData _getModuleIcon(String module) {
    switch (module.toLowerCase()) {
      case "flocks":
        return Icons.pets;
      case "eggs":
        return Icons.egg;
      case "birds":
        return Icons.air;
      case "finance":
        return Icons.attach_money;
      case "feed":
        return Icons.local_dining;
      case "health":
        return Icons.healing;
      case "stock":
        return Icons.inventory;
      case "reports":
        return Icons.bar_chart;
      case "settings":
        return Icons.settings;
      default:
        return Icons.apps;
    }
  }

  /// Helper function to navigate to the respective screen
  void _navigateToModule(String module) {
    if (module.toLowerCase() == "flocks") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AllFlocksScreen()));
    } else if (module.toLowerCase() == "eggs") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => EggCollectionScreen()));
    } else if (module.toLowerCase() == "birds") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AddReduceFlockScreen()));
    } else if (module.toLowerCase() == "finance") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionsScreen()));
    } else if (module.toLowerCase() == "feed") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => DailyFeedScreen()));
    } else if (module.toLowerCase() == "health") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MedicationVaccinationScreen()));
    } else if (module.toLowerCase() == "stock") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ManageInventoryScreen()));
    } else if (module.toLowerCase() == "reports") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ReportListScreen(showBack: true,)));
    } else if (module.toLowerCase() == "settings") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(showBack: true,)));
    }
  }

  void _showBlockedMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.tr())),
    );
  }

  Future<void> setupDataListners() async {

    final docRef = FirebaseFirestore.instance.collection(FireBaseUtils.DB_BACKUP)
        .doc(Utils.currentUser!.farmId);
    final docSnapshot = await docRef.get();
    final DateTime lastBackupDate;
    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      final Timestamp? lastTimestamp = data?['timestamp'];

      print("DB BACKUP "+lastTimestamp.toString());
      if (lastTimestamp != null) {
        lastBackupDate = lastTimestamp.toDate();
        synclastSyncTime = lastBackupDate;
        getFlocksFromFirebase(Utils.currentUser!.farmId, lastBackupDate);

      }
    }
  }

  DateTime? synclastSyncTime = null;
  Future<void> getFlocksFromFirebase(String farmId, DateTime? lastSyncTime) async {


    final lastTime = await SessionManager.getLastSyncTime(FireBaseUtils.FLOCKS);

    try {
      Query query = FirebaseFirestore.instance
          .collection(FireBaseUtils.FLOCKS)
          .where('farm_id', isEqualTo: farmId);

      if (lastTime != null) {
        query = query.where(
          'last_modified',
          isGreaterThan: Timestamp.fromDate(lastTime),
        );
      }else{
        query = query.where(
          'last_modified',
          isGreaterThan: Timestamp.fromDate(lastSyncTime!),
        );
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print("📭 No flocks found for farm: $farmId");
        // ✅ Start image/follow-up listeners anyway
        SyncManager().startAllListeners(farmId, lastSyncTime);
        return;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        FlockFB? flockFB = FlockFB.fromJson(data);
        print("📥 Syncing FLOCK: ${flockFB.flock.f_name}");

        if (flockFB.last_modified!.isAfter(lastSyncTime!)) {
          lastSyncTime = flockFB.last_modified;
        }

        bool isAlreadyAdded = await DatabaseHelper.checkFlockBySyncID(flockFB.flock.sync_id!);
        if (isAlreadyAdded) {
          if (flockFB.flock.sync_status == SyncStatus.UPDATED || flockFB.flock.sync_status == SyncStatus.SYNCED) {
            await DatabaseHelper.updateFlockInfoBySyncID(flockFB.flock);
            Flock? flock = await DatabaseHelper.getFlockBySyncId(flockFB.flock.sync_id!);
            await listenToFlockImages(flock!, flock.farm_id ?? "");
          } else if (flockFB.flock.sync_status == SyncStatus.DELETED) {
            Flock? flock = await DatabaseHelper.getFlockBySyncId(flockFB.flock.sync_id!);

            await DatabaseHelper.deleteFlockAndRelatedInfoSyncID(flockFB.flock.sync_id!, flock!.f_id);
          }
        } else {
          if (flockFB.flock.sync_status != SyncStatus.DELETED) {
            int? f_id = await DatabaseHelper.insertFlock(flockFB.flock);

            if (flockFB.transaction != null) {
              flockFB.transaction!.f_id = f_id!;
              int? tr_id = await DatabaseHelper.insertNewTransaction(flockFB.transaction!);
              flockFB.flockDetail!.transaction_id = tr_id.toString();
              flockFB.flockDetail!.f_id = f_id;
              int? f_detail_id = await DatabaseHelper.insertFlockDetail(flockFB.flockDetail!);
              await DatabaseHelper.updateLinkedTransaction(tr_id!.toString(), f_detail_id!.toString());
            } else {
              flockFB.flockDetail!.transaction_id = "-1";
              flockFB.flockDetail!.f_id = f_id!;
              await DatabaseHelper.insertFlockDetail(flockFB.flockDetail!);
            }

            Flock? insertedFlock = await DatabaseHelper.getFlockBySyncId(flockFB.flock.sync_id!);
            await listenToFlockImages(insertedFlock!, flockFB.flock.farm_id ?? "");
          }
        }
      }

      SessionManager.setLastSyncTime(FireBaseUtils.FLOCKS, lastSyncTime!);

      // ✅ Start real-time sync listener after initial fetch
      SyncManager().startAllListeners(farmId, lastSyncTime);

    } catch (e) {
      print("❌ Error in getFlocksFromFirebase: $e");
      SyncManager().startAllListeners(farmId, lastSyncTime);

    }
  }

  Future<void> listenToFlockImages(Flock flock, String farmId) async {
    final query = FirebaseFirestore.instance
        .collection(FireBaseUtils.FLOCK_IMAGES)
        .where('farm_id', isEqualTo: farmId)
        .where('f_sync_id', isEqualTo: flock.sync_id); // Use correct field name

    final snapshot = await query.get();

    if(!snapshot.docs.isEmpty){
      List<Flock_Image> images = await DatabaseHelper.getFlockImage(flock.f_id);
      for(var image in images) {
        int result =  await DatabaseHelper.deleteItem("Flock_Image", image.id!);
        print("DELETED $result");
      }
    }

    print("DOC LENGTH ${snapshot.docs.length} Flock ${flock.f_name}");

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final List<dynamic>? imageUrls = data['image_urls'];

      if (imageUrls != null && imageUrls.isNotEmpty) {
        List<String> urls = imageUrls.cast<String>();

        print("🖼️ Flock Image URLs: $urls");
        if (imageUrls != null) {
          for (String url in urls) {
            print("DOWNLOADING URL $url");
            final base64 = await FlockImageUploader().downloadImageAsBase64(url);

            if (base64 != null) {
              Flock_Image image = Flock_Image(
                  f_id: flock.f_id, image: base64,
                  sync_id: Utils.getUniueId(),
                  sync_status: SyncStatus.SYNCED,
                  last_modified: flock.last_modified,
                  modified_by: flock.modified_by,
                  farm_id: flock.farm_id);

              await DatabaseHelper.insertFlockImages(image);
              print("SAVED URL $url for Flock ${flock.f_name}");
            }
          }
        }

        // TODO: Save URLs to SQLite or use them as needed
      } else {
        print("⚠️ No images found for flock: ${data['f_sync_id']}");
      }
    }
  }

 /* void listenToFlocks(String farmId, DateTime? lastSyncTime) async {

    SyncManager().stopAllListening();
    // 🔹 Real-time listener (new changes only)
    SyncManager().startFockListening(farmId, lastSyncTime);
    SyncManager().startFinanceListening(farmId, lastSyncTime);
    SyncManager().startBirdModificationListening(farmId, lastSyncTime);
    SyncManager().startEggRecordListening(farmId, lastSyncTime);
    SyncManager().startFeedingListening(farmId, lastSyncTime);
    SyncManager().startCustomCategoryListening(farmId, lastSyncTime);
    SyncManager().startFeedIngredientListening(farmId, lastSyncTime);
    SyncManager().startHealthListening(farmId, lastSyncTime);
    SyncManager().startCustomCategoryDataListening(farmId, lastSyncTime);
    SyncManager().startFeedBatchFBListening(farmId, lastSyncTime);
    SyncManager().startFeedStockFBListening(farmId, lastSyncTime);
    SyncManager().startMedicineStockFBListening(farmId, lastSyncTime);
    SyncManager().startVaccineStockFBListening(farmId, lastSyncTime);

  }
*/

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
}
