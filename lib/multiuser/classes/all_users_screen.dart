import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:poultary/multiuser/classes/user_worker_profile.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:sqflite/sqflite.dart';

import '../../database/databse_helper.dart';
import '../../utils/utils.dart';
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
  String farmID = "";
  Future<void> loadUsers() async {
    final fetchedUsers = await DatabaseHelper.getAllNonAdminUsers(); // your method
    farmID = fetchedUsers[0].farmId;
    setState(() => users = fetchedUsers);
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
        title: Text("All Users"),
        backgroundColor: Utils.getThemeColorBlue(),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade100,
      body: users.isEmpty
          ? Center(child: Text("No users found"))
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
                backgroundColor: Colors.blue.shade400,
                child: Text(user.name[0].toUpperCase(), style: TextStyle(color: Colors.white)),
              ),
              title: Text(user.name, style: theme.textTheme.titleMedium),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email, style: TextStyle(color: Colors.grey[700])),
                  Text("Role: ${user.role}", style: TextStyle(color: Colors.grey[600])),
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
        onPressed: showAddUserDialog,
        icon: Icon(Icons.person_add),
        label: Text("Add User"),
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
  String? selectedRole;


  List<Role> roles = [];

  @override
  void initState() {
    super.initState();
    loadRoles();
  }

  Future<void> loadRoles() async {
     roles = await DatabaseHelper.getAllRoles();
     setState(() {

     });
  }

  void handleSave() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fill all fields")));
      return;
    }

    final user = MultiUser(
      name: nameController.text,
      email: emailController.text,
      role: selectedRole!,
      createdAt: DateTime.now().toIso8601String(),
      password: '', // Optional: set if needed
      farmId: widget.farmID,   // Optional: set if needed
    );

    // 1. Save to local database
    await DatabaseHelper.insertUser(user);

    // 2. Save to Firestore
    try {
      await FirebaseFirestore.instance.collection(FireBaseUtils.USERS).add({
        'name': user.name,
        'email': user.email,
        'role': user.role,
        'active': 1,
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


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Add New User", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
          TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(labelText: 'Select Role'),
                  items: roles.map((role) {
                    return DropdownMenuItem(value: role.name, child: Text(role.name));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedRole = val),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, color: Colors.blue),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AllRolesScreen(),
                  ));
                },
              )
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: handleSave,
            icon: Icon(Icons.save),
            label: Text("Save"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          ),
        ],
      ),
    );
  }
}
