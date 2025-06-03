import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../database/databse_helper.dart';
import '../model/role.dart';
import '../model/user.dart';
import '../model/user_logs.dart';
import '../utils/FirebaseUtils.dart';

class UserEditScreen extends StatefulWidget {
  final MultiUser user;

  const UserEditScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  List<String> availableRoles = [];

  @override
  void initState() {
    super.initState();
    loadRoles();
  }

  UserLog? userLog = null;
  Future<void> loadRoles() async {
    List<Role> roles = await DatabaseHelper.getAllRoles();
    userLog = await fetchUserLogs(widget.user.farmId);

    setState(() {
      availableRoles = roles.map((role) => role.name).toList();
    });
  }



  Future<void> deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete User"),
        content: Text("Are you sure you want to delete this user?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.deleteUser(widget.user.email);
      final query = await FirebaseFirestore.instance
          .collection(FireBaseUtils.USERS)
          .where('email', isEqualTo: widget.user.email)
          .where('farm_id', isEqualTo: widget.user.farmId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await FirebaseFirestore.instance.collection(FireBaseUtils.USERS).doc(query.docs.first.id).delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User deleted")));
      Navigator.pop(context);
    }
  }

  Future<void> showEditBottomSheet() {
    final nameController = TextEditingController(text: widget.user.name);
    String selectedRole = widget.user.role;
    bool isActive = widget.user.active; // assuming 1 = active, 0 = inactive

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
                    "Edit User",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    enabled: false,
                    controller: TextEditingController(text: widget.user.email),
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: "Role",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: availableRoles.map((role) {
                      return DropdownMenuItem(value: role, child: Text(role));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedRole = val);
                    },
                  ),
                ),

                SwitchListTile(
                  title: Text("Active"),
                  value: isActive,
                  onChanged: (value) {
                    setModalState(() {
                      isActive = value;
                    });
                  },
                ),

                SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.save_alt, color: Colors.white),
                    label: Text(
                      "Save Changes",
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
                      final updatedUser = MultiUser(
                        name: nameController.text.trim(),
                        email: widget.user.email,
                        role: selectedRole,
                        password: widget.user.password,
                        farmId: widget.user.farmId,
                        createdAt: widget.user.createdAt,
                        active: isActive,
                      );

                      await DatabaseHelper.updateUser(updatedUser);
                      await updateUserInFirestore(updatedUser);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("User updated successfully")),
                      );

                      setState(() {
                        widget.user.name = updatedUser.name;
                        widget.user.role = updatedUser.role;
                        widget.user.active = updatedUser.active;
                      });

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
      await FirebaseFirestore.instance.collection(FireBaseUtils.USERS).doc(docId).update({
        'name': user.name,
        'role': user.role,
        'active': user.active ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Widget _infoTile(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget buildProfileCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(widget.user.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Icon(widget.user.active ? Icons.check_circle : Icons.block, color: widget.user.active ? Colors.green : Colors.red),
                  ],
                ),
                Text(widget.user.email, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Chip(label: Text(widget.user.role), backgroundColor: Colors.indigo.shade100),
                const SizedBox(height: 16),
                Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoTile("Last Sign In", userLog==null? "Unknown": userLog!.lastSigned.toString()),
                    _infoTile("Records Modified", userLog==null? "NO" : userLog!.dataChanges),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: showEditBottomSheet,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: deleteUser,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<UserLog?> fetchUserLogs(String farmId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('user_log')
        .doc(widget.user.farmId+"_"+widget.user.email)
        .get(const GetOptions(source: Source.server));

    print("LOG ${snapshot.data()}");
    if (snapshot.data()!.isEmpty) return null;
    return UserLog.fromFirestore(snapshot);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: buildProfileCard(),
      ),
    );
  }
}
