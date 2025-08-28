import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:poultary/multiuser/classes/user_worker_profile.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:sqflite/sqflite.dart';

import '../../database/databse_helper.dart';
import '../../utils/session_manager.dart';
import '../../utils/utils.dart';
import '../model/farm_plan.dart';
import '../model/permission.dart';
import '../model/role.dart';
import '../model/user.dart';
import 'all_roles_screen.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({Key? key}) : super(key: key);

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  List<MultiUser> users = [];

  @override
  void initState() {
    super.initState();
    createTables();
    loadUsers();

  }

  Future<void> createTables() async {
    await DatabaseHelper.createMultiUserTables();
    List<Permission> allPerms = await fetchGeneralPermissionsFromFirestore();
    for(int i=0;i<allPerms.length;i++){
      await DatabaseHelper.insertPermissionIfNotExists(allPerms[i]);
    }
  }

  Future<List<Permission>> fetchGeneralPermissionsFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('permissions').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Permission(
        id: null,
        name: data['name'],
        description: data['description'],
      );
    }).toList();
  }

  /*Future<void> seedPermissionsToFirestore() async {
    final modules = [
      'flocks', 'eggs', 'birds', 'transaction', 'feed',
      'health', 'custom_category', 'stock', 'reports', 'settings'
    ];

    final actions = ['view', 'add', 'edit', 'delete'];
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    for (var module in modules) {
      for (var action in actions) {
        final docRef = firestore.collection('permissions').doc();
        batch.set(docRef, {
          'name': '$action'+'_'+'$module',
          'description': 'Can $action $module',
        });
      }
    }

    await batch.commit();
    print('Permissions seeded successfully to Firestore');
  }
*/



  Future<List<MultiUser>> loadUsersByFarm(String farmId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('farm_id', isEqualTo: farmId)
        .get();

    return querySnapshot.docs
        .map((doc) => MultiUser.fromMap(doc.data()))
        .where((user) => user.role.toLowerCase() != 'admin')
        .toList();
  }


  late FarmPlan? farmPlan;
  String farmID = "";
  Future<void> loadUsers() async {
   // final fetchedUsers = await DatabaseHelper.getAllNonAdminUsers();
// your method
    farmID = Utils.currentUser!.farmId;
    users = await loadUsersByFarm(farmID);
    farmPlan = await SessionManager.getFarmPlan();
    print(farmPlan!.toJson());
    setState(() => users );
  }

  void showUserLimitFull() {
    Utils.showToast("Maximum users created".tr()+" ${farmPlan!.userCapacity}. "+"Contact Support for assistance.".tr());
  }

  void showAddUserDialog() {
    // Navigate or show bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddUserBottomSheet(onUserAdded: loadUsers, farmID: farmID,),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("All Users".tr()),
        backgroundColor: Utils.getThemeColorBlue(),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade100,
      body: users.isEmpty
          ? Center(child: Text("No users found".tr()))
          : ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: ListTile(
              leading: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.shade100,
                backgroundImage: (user.image != null && user.image!.isNotEmpty)
                    ? NetworkImage(user.image!)
                    : null,
                child: (user.image == null || user.image!.isEmpty)
                    ? Icon(Icons.person, size: 40, color: Colors.blue)
                    : null,
              ),
              title: Text(user.name, style: theme.textTheme.titleMedium),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email, style: TextStyle(color: Colors.grey[700])),
                  Text("Role:".tr()+" ${user.role}", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              trailing: Icon(user.active ? Icons.check_circle : Icons.block, color: user.active ? Colors.green : Colors.red),
              onTap: () async {
                // Maybe show user details
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserEditScreen(user: user,)),
                );
                loadUsers();
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (farmPlan!.isActive && farmPlan!.userCapacity > users.length)?  showAddUserDialog : showUserLimitFull,
        icon: Icon(Icons.person_add),
        label: Text("Add New User".tr()),
        backgroundColor: Utils.getThemeColorBlue(),
        foregroundColor: Colors.white,
      ),
    );
  }

}

class AddUserBottomSheet extends StatefulWidget {
  final VoidCallback onUserAdded;
  String farmID = "";
  AddUserBottomSheet({required this.onUserAdded, required this.farmID, Key? key}) : super(key: key);

  @override
  State<AddUserBottomSheet> createState() => _AddUserBottomSheetState();
}

class _AddUserBottomSheetState extends State<AddUserBottomSheet> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();

  String? selectedRole;


  List<Role> roles = [];

  @override
  void initState() {
    super.initState();
    loadRoles();
  }

  Future<List<Role>> loadRolesByFarm(String farmId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('roles')
        .where('farm_id', isEqualTo: farmId)
        .get();

    return querySnapshot.docs
        .map((doc) => Role.fromJson(doc.data()))
        .toList();
  }

  Future<void> loadRoles() async {
     roles = await loadRolesByFarm(Utils.currentUser!.farmId);
     setState(() {

     });
  }

  /*void handleSave() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PROVIDE_ALL".tr())));
      return;
    }

    final user = MultiUser(
      name: nameController.text,
      email: emailController.text,
      role: selectedRole!,
      image: '',
      createdAt: DateTime.now().toIso8601String(),
      password: passController.text, // Optional: set if needed
      farmId: widget.farmID,   // Optional: set if needed
    );

    // 1. Save to local database
    try{
      await DatabaseHelper.insertUser(user);
    }
    catch(e){
      print(e);
    }


    Utils.shouldBackup = true;
    // 2. Save to Firestore
    try {
      await FirebaseFirestore.instance.collection(FireBaseUtils.USERS).add({
        'name': user.name,
        'email': user.email,
        'role': user.role,
        'active': 1,
        'image':'',
        'created_at': user.createdAt,
        'farm_id': user.farmId,
        'password': user.password, // if storing password in Firestore, hash it ideally
      });
    } catch (e) {
      debugPrint("Error saving user to Firestore: $e");
    }

    widget.onUserAdded();
    Navigator.pop(context);
  }
*/
  void handleSave() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || selectedRole == null || passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PROVIDE_ALL".tr())),
      );
      return;
    }

    final user = MultiUser(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      role: selectedRole!,
      image: '',
      createdAt: DateTime.now().toIso8601String(),
      password: passController.text.trim(),
      farmId: widget.farmID,
    );

    try {
      // --- Step 1: Create Auth user in Secondary App ---
      final FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final UserCredential newUserCred = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );

      final String newUid = newUserCred.user!.uid;

      // --- Step 2: Save to Firestore ---
      await FirebaseFirestore.instance.collection(FireBaseUtils.USERS).doc(newUid).set({
        'uid': newUid,
        'name': user.name,
        'email': user.email,
        'role': user.role,
        'active': 1,
        'image': '',
        'created_at': user.createdAt,
        'farm_id': user.farmId,
        'password': "", // ⚠️ Ideally hash before saving
      });

      // --- Step 3: Save to Local DB ---
      try {
        await DatabaseHelper.insertUser(user);
      } catch (dbError) {
        debugPrint("Local DB error: $dbError");
      }

      // Cleanup: sign out secondary app so it doesn’t affect admin
      await FirebaseAuth.instanceFor(app: secondaryApp).signOut();
      await secondaryApp.delete();

      Utils.shouldBackup = true;


      widget.onUserAdded();
      Navigator.pop(context);

    } on FirebaseAuthException catch (authError) {
      // Handle Firebase Auth errors (email already in use, weak password, etc.)
      debugPrint("FirebaseAuth error: $authError");


      Utils.showToast("Error: ${authError.message}");
    } catch (e) {
      debugPrint("General error creating user: $e");

      Utils.showToast("Error: Something went wrong");

    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Add New User".tr(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextField(controller: nameController, decoration: InputDecoration(labelText: "Name".tr())),
          TextField(controller: emailController, decoration: InputDecoration(labelText: "Email".tr())),
          TextField(controller: passController, decoration: InputDecoration(labelText: "Password".tr())),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(labelText: 'Select Role'.tr()),
                  items: roles.map((role) {
                    return DropdownMenuItem(value: role.name, child: Text(role.name));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedRole = val),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, color: Colors.blue),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AllRolesScreen(),
                  ));

                  loadRoles();
                },
              )
            ],
          ),
          SizedBox(height: 20),
         /* ElevatedButton.icon(
            onPressed: handleSave,
            icon: Icon(Icons.save),
            label: Text("SAVE".tr()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          ),
          */
          buildSaveButton(context)
        ],
      ),
    );
  }

  Widget buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.teal,
              Colors.teal.shade700,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: handleSave,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    "SAVE".tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
