import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
import '../../new_reporting_Screen.dart';
import '../../stock/main_inventory_screen.dart';
import '../../utils/session_manager.dart';
import 'AuthGate.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

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
    "Flocks": "flocks.view",
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
    await SessionManager.setBoolValue(SessionManager.loggedIn, false);
    await SessionManager.setBoolValue(SessionManager.isAdmin, false);
    await SessionManager.clearUserObject();

    // Navigate to login screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => AuthGate(isStart: true)),
          (route) => false,
    );
  }



  Future<void> fetchAndInitializeDatabaseWithProgress(String farmId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool initialized = prefs.getBool('db_initialized_$farmId') ?? false;

    if (initialized) {
      print("Database already initialized for farm $farmId");
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
      final file = File(dbPath);
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
          sink.close();
          throw Exception("Download failed: $e");
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("Error during DB download: $e");
      rethrow;
    }
  }

  Future<String> getLatestBackupUrlFromFirestore(String farmId) async {
    final doc = await FirebaseFirestore.instance.collection(FireBaseUtils.DB_BACKUP).doc(farmId).get();
    return doc.data()?['last_backup_url'] ?? '';
  }


  RoleWithPermissions? rolePerms = null;
  bool isUSerActive = true;
  Future<void> loadLatestUser() async {
    MultiUser? user = await SessionManager.getUserFromPrefs();
    final snapshot = await FirebaseFirestore.instance
        .collection(FireBaseUtils.USERS)
        .where('email', isEqualTo: widget.email)
        .where('farm_id', isEqualTo: user!.farmId)
        .limit(1)
        .get();

    isUSerActive = snapshot.docs.first.data()['active']! == 1? true : false;
    print("isUSerActive $isUSerActive");
    final querySnapshot = await FirebaseFirestore.instance
        .collection('roles_permissions')
        .doc(user.farmId+"_"+user.role)
        .get();

    if (querySnapshot.exists) {
      final data = querySnapshot.data();
      rolePerms =  RoleWithPermissions.fromMap(data!); // return as a list
      print("PERMS ${rolePerms!.toMap()}");
    }


    postUserLog(user.farmId, user.email);

    fetchAndInitializeDatabaseWithProgress(user.farmId);

    setState(() {

    });
  }

  bool downloadingDB = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadLatestUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Worker Dashboard"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
            tooltip: "Logout",
          )
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
                    Text("Downloading database..."),
                    LinearProgressIndicator(value: value),
                    SizedBox(height: 8),
                    Text("Progress: ${(value * 100).toStringAsFixed(0)}%"),
                  ],
                );
              },
            ) : SizedBox.shrink(),
            const SizedBox(height: 16),
            _buildModuleGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade200,
                child: Text(
                  widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.email, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(isUSerActive? 'Active':'Disabled', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(widget.role),
                      backgroundColor: Colors.blue.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.2,
        children: modules.map((module) {
          bool hasPermission = rolePerms?.permissions.contains(modulePermissionMap[module]) ?? false;

          bool isDisabled = !isUSerActive || !hasPermission;

          return GestureDetector(
            onTap: () {
              if (!isUSerActive) {
                _showBlockedMessage("Your access is blocked by Admin");
                return;
              }

              if (!hasPermission) {
                _showBlockedMessage("You do not have permission to access $module");
                return;
              }

              if(module.toLowerCase() == "flocks"){
                /*Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AllRolesScreen()),
                );*/
              }else if(module.toLowerCase() == "eggs"){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EggCollectionScreen()),
                );
              }else if(module.toLowerCase() == "birds"){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddReduceFlockScreen()),
                );
              }else if(module.toLowerCase() == "finance"){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TransactionsScreen()),
                );
              }else if(module.toLowerCase() == "feed"){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DailyFeedScreen()),
                );
              }else if(module.toLowerCase() == "health"){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MedicationVaccinationScreen()),
                );
              }else if(module.toLowerCase() == "stock"){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManageInventoryScreen()),
                );
              }else if(module.toLowerCase() == "reports"){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReportListScreen()),
                );
              }else if(module.toLowerCase() == "settings"){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              }


              // Navigate to module screen
              // Navigator.push(...);
            },
            child: Opacity(
              opacity: isDisabled ? 0.4 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      module,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showBlockedMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

}
