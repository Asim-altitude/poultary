import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:poultary/multiuser/api/server_apis.dart';

import '../../database/databse_helper.dart';
import '../../utils/utils.dart';
import '../model/role.dart';
import '../model/user.dart';
import '../model/user_logs.dart';
import '../utils/FirebaseUtils.dart';

class UserEditScreen extends StatefulWidget {
  MultiUser user;

  UserEditScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  List<String> availableRoles = [];

  @override
  void initState() {
    super.initState();
    fetchRoles();
  }

  String imageUrl = '';
  UserLog? userLog = null;


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
    XFile? selectedImage; // picked image file
    String? imageUrl = widget.user.image; // existing image


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
                            ? NetworkImage(imageUrl!) as ImageProvider
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

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    enabled: false,
                    controller: TextEditingController(text: widget.user.email),
                    decoration: InputDecoration(
                      labelText: "Email".tr(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: "Role".tr(),
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
                  title: Text("Active".tr()),
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
                        String userId = widget.user.email
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
                          email: widget.user.email,
                          role: selectedRole,
                          image: imageUrl!,
                          password: widget.user.password,
                          farmId: widget.user.farmId,
                          createdAt: widget.user.createdAt,
                          active: isActive,
                        );

                        await updateUserInFirestore(updatedUser);

                        try{
                          await DatabaseHelper.updateUser(updatedUser);
                        }catch(e){
                          print(e);
                        }

                        setState(() {
                          widget.user = updatedUser;
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
        'role': user.role,
        'image' : user.image,
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
                  backgroundImage: (widget.user.image != null && widget.user.image!.isNotEmpty)
                      ? NetworkImage(widget.user.image!)
                      : null,
                  child: (widget.user.image == null || widget.user.image!.isEmpty)
                      ? Icon(Icons.person, size: 40, color: Colors.blue)
                      : null,
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
                InkWell(
                  onTap: () {
                    Utils.shareSubUserCredentials(name: widget.user.name, email: widget.user.email, password: widget.user.password, farmID: widget.user.farmId);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 20, color: Colors.blue,),
                      const SizedBox(width: 8),
                      Text('Share Credentials', style: TextStyle(fontSize: 14, color: Colors.black, ),)
                    ],

                  ),
                ),
                Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoTile("Last Sign In", userLog==null? "Unknown": userLog!.lastSigned.toString()),
                   // _infoTile("Records Modified", userLog==null? "NO" : userLog!.dataChanges),
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
