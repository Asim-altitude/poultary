import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:poultary/multiuser/classes/AuthGate.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/utils/session_manager.dart';
import '../api/server_apis.dart';
import '../model/user.dart';
import 'all_roles_screen.dart';
import 'all_users_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


class AdminProfileScreen extends StatefulWidget {
  final List<MultiUser> users;
  const AdminProfileScreen({Key? key, required this.users}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreen();
}

class _AdminProfileScreen extends State<AdminProfileScreen> {


  bool isUploading = false;
  Future<void> handleLogout(BuildContext context) async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Optionally: clear local user session (if you store it in SQLite or SharedPreferences)
      // Example if using SQLite:
      await SessionManager.setBoolValue(SessionManager.loggedIn, false);
      await SessionManager.setBoolValue(SessionManager.isAdmin, false);
      await SessionManager.clearUserObject();

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init();

  }

  MultiUser? adminUser = null;
  Future<void> init() async{
    adminUser = widget.users.firstWhere(
          (user) => user.role.toLowerCase() == 'admin',
      orElse: () => MultiUser(
        name: 'Unknown',
        email: 'N/A',
        password: '',
        role: 'Admin',
        farmId: '',
        active: true,
        createdAt: '',
      ),
    );

    await checkAndBackupIfNeeded(adminUser!.farmId);
  }

  /// Function to check if a backup already exists today, and if not, perform it
  Future<void> checkAndBackupIfNeeded(String farmId) async {
    final docRef = FirebaseFirestore.instance.collection(FireBaseUtils.DB_BACKUP).doc(farmId);
    final docSnapshot = await docRef.get();

    bool shouldBackup = true;

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      final Timestamp? lastTimestamp = data?['timestamp'];

      if (lastTimestamp != null) {
        final DateTime lastBackupDate = lastTimestamp.toDate();
        final DateTime now = DateTime.now();

// Compare difference in full days between now and lastBackupDate
        final Duration difference = now.difference(lastBackupDate);
        if (difference.inDays < 7) {
          shouldBackup = false;
          print("Backup done recently. Next backup allowed after ${7 - difference.inDays} day(s).");
        } else {
          shouldBackup = true;
        }

        print("Last Backup: ${DateFormat('yyyy-MM-dd').format(lastBackupDate)}");
        print("Today: ${DateFormat('yyyy-MM-dd').format(now)}");

      }
    }

    if (shouldBackup) {
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
        title: Text('Admin Profile'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.blue.shade50,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.blue.shade700,
                      child: Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(adminUser!.name,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(adminUser!.email, style: TextStyle(color: Colors.grey[700])),
                          Text(adminUser!.farmId, style: TextStyle(color: Colors.grey[700])),
                          SizedBox(height: 4),
                          Chip(
                            label: Text("Admin"),
                            backgroundColor: Colors.blue.shade100,
                            labelStyle: TextStyle(color: Colors.blue.shade900),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              isUploading
                  ? Column(
                children: [
                  Text(
                    'Backing up database...',
                    style: TextStyle(color: Colors.grey),
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: uploadProgress,
                    builder: (context, value, _) {
                      if ((value * 100) == 100) {
                        // Hide after a short delay to let user see "100%"
                        Future.delayed(Duration(seconds: 6), () {
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
                          Text("Upload Progress: ${(value * 100).toStringAsFixed(0)}%"),
                        ],
                      );
                    },
                  ),
                ],
              )
                  : SizedBox.shrink(),

              SizedBox(height: 30),

              // Admin Actions
              _AdminActionCard(
                icon: Icons.group,
                label: 'Manage Users',
                color: Colors.indigo,
                onTap: () {
                  // Navigate to Users screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AllUsersScreen()),
                  );
                },
              ),
              _AdminActionCard(
                icon: Icons.security,
                label: 'Manage Roles',
                color: Colors.green,
                onTap: () {
                  // Navigate to Roles screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AllRolesScreen()),
                  );
                },
              ),
              _AdminActionCard(
                icon: Icons.restore,
                label: 'Restore Data',
                color: Colors.orange,
                onTap: () {
                  // Settings logic
                },
              ),
              _AdminActionCard(
                icon: Icons.logout,
                label: 'Logout',
                color: Colors.red,
                onTap: () {
                  // Logout logic
                  handleLogout(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
