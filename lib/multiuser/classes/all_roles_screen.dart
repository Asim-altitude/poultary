import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/multiuser/model/user.dart';
import '../../utils/utils.dart';
import '../model/permission.dart';
import '../model/role.dart';
import '../model/role_permissions.dart';


class AllRolesScreen extends StatefulWidget {
  const AllRolesScreen({Key? key}) : super(key: key);

  @override
  State<AllRolesScreen> createState() => _AllRolesScreenState();
}

class _AllRolesScreenState extends State<AllRolesScreen> {
  List<Role> roles = [];

  @override
  void initState() {
    super.initState();
    fetchRoles();
  }

  String farmID = "";
  List<MultiUser> users = [];
  Future<void> fetchRoles() async {

    farmID = Utils.currentUser!.farmId;
    roles = await loadRolesByFarm(farmID);
    setState(() {
      roles;
    });
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


  void showAddRoleDialog() async {
    final TextEditingController roleNameController = TextEditingController();
    final TextEditingController searchController = TextEditingController();

    List<Permission> allPermissions = await DatabaseHelper.getAllPermissions();
    List<Permission> displayedPermissions = List.from(allPermissions);
    List<Permission> selectedPermissions = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 40),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              void filterPermissions(String query) {
                final filtered = allPermissions
                    .where((perm) =>
                perm.name.toLowerCase().contains(query.toLowerCase()) &&
                    !selectedPermissions.contains(perm))
                    .toList();
                setModalState(() {
                  displayedPermissions = filtered;
                });
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Create New Role".tr(), style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    TextField(
                      controller: roleNameController,
                      decoration: InputDecoration(labelText: 'Role Name'.tr()),
                    ),
                    const SizedBox(height: 20),

                    // Search box
                    TextField(
                      controller: searchController,
                      onChanged: filterPermissions,
                      decoration: InputDecoration(
                        labelText: "Search Permissions".tr(),
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Tap a permission to select it:".tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),

                    // All permissions list (horizontal)
                    Container(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: displayedPermissions.length,
                        itemBuilder: (context, index) {
                          final p = displayedPermissions[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ActionChip(
                              label: Text(p.name),
                              onPressed: () {
                                setModalState(() {
                                  selectedPermissions.add(p);
                                  allPermissions.remove(p);
                                  filterPermissions(searchController.text);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Selected Permissions:".tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),

                    // Selected permissions list (vertical scrollable)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: selectedPermissions.isEmpty
                          ? Center(child: Text("No permissions selected".tr()))
                          : ListView.builder(
                        itemCount: selectedPermissions.length,
                        itemBuilder: (context, index) {
                          final p = selectedPermissions[index];
                          return ListTile(
                            title: Text(p.name),
                            subtitle: Text(p.description ?? ''),
                            trailing: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                setModalState(() {
                                  selectedPermissions.remove(p);
                                  allPermissions.add(p);
                                  filterPermissions(searchController.text);
                                });
                              },

                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final roleName = roleNameController.text.trim();
                        if (roleName.isEmpty || selectedPermissions.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Please enter role name and select permissions".tr())),
                          );
                          return;
                        }

                        final roleId = await DatabaseHelper.insertRole(Role(name: roleName));
                        final permissionIds = selectedPermissions.map((p) => p.id!).toList();
                        await DatabaseHelper.assignPermissionsToRole(roleId!, permissionIds);
                        await uploadRoleToFirebase(farmID,Role(name: roleName, id: roleId));
                        await uploadRoleWithPermissionsToFirestore(farmID,roleName,selectedPermissions.map((p) => p.name).toList());
                        Utils.shouldBackup = true;
                        Navigator.pop(context);
                        fetchRoles();
                      },
                      child: Text("Create Role".tr()),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );

  }

  Future<void> uploadRoleWithPermissionsToFirestore(
      String farmId, String roleName, List<String> permissionNames) async {
    final roleData = RoleWithPermissions(
      role: roleName,
      farmId: farmId,
      permissions: permissionNames,
    );


    await FirebaseFirestore.instance
        .collection('roles_permissions')
        .doc('${farmId}_$roleName') // Unique per farm
        .set(roleData.toMap());
  }

  Future<void> uploadRoleToFirebase(String farmId, Role role) async{
    await FirebaseFirestore.instance
        .collection('roles')
        .doc('${farmId}_${role.name}') // Unique per farm
        .set({
      'role':role.name,
      'id':role.id,
      'farm_id':farmId
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Roles Management".tr()),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: showAddRoleDialog,
          )
        ],
      ),
      body: ListView.builder(
        itemCount: roles.length,
        itemBuilder: (context, index) {
          final role = roles[index];
          return Card(
            child: ListTile(
              title: Text(role.name),
              trailing: Icon(Icons.edit),
              onTap: () {
                showEditRoleDialog(role);
              },

            ),
          );
        },
      ),
    );
  }

  void showEditRoleDialog(Role role) async {
    final TextEditingController roleNameController = TextEditingController(text: role.name);
    final TextEditingController searchController = TextEditingController();

    List<Permission> allPermissions = await DatabaseHelper.getAllPermissions();
    List<Permission> selectedPermissions = await DatabaseHelper.getPermissionsForRole(role.id!);

    allPermissions.removeWhere((perm) => selectedPermissions.any((sp) => sp.id == perm.id));
    List<Permission> displayedPermissions = List.from(allPermissions);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 40),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              void filterPermissions(String query) {
                final filtered = allPermissions
                    .where((perm) =>
                perm.name.toLowerCase().contains(query.toLowerCase()) &&
                    !selectedPermissions.contains(perm))
                    .toList();
                setModalState(() {
                  displayedPermissions = filtered;
                });
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Edit Role".tr(), style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    TextField(
                      controller: roleNameController,
                      decoration: InputDecoration(labelText: "Role Name".tr()),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: searchController,
                      onChanged: filterPermissions,
                      decoration: InputDecoration(
                        labelText: "Search Permissions".tr(),
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Tap a permission to select it:".tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: displayedPermissions.length,
                        itemBuilder: (context, index) {
                          final p = displayedPermissions[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ActionChip(
                              label: Text(p.name),
                              onPressed: () {
                                setModalState(() {
                                  selectedPermissions.add(p);
                                  allPermissions.remove(p);
                                  filterPermissions(searchController.text);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Selected Permissions:".tr(), style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: selectedPermissions.isEmpty
                          ? Center(child: Text("No permissions selected".tr()))
                          : ListView.builder(
                        itemCount: selectedPermissions.length,
                        itemBuilder: (context, index) {
                          final p = selectedPermissions[index];
                          return ListTile(
                            title: Text(p.name),
                            subtitle: Text(p.description ?? ''),
                            trailing: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                setModalState(() {
                                  selectedPermissions.remove(p);
                                  allPermissions.add(p);
                                  filterPermissions(searchController.text);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.delete),
                          label: Text("DELETE".tr()),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () async {
                            await DatabaseHelper.deleteRole(role.id!);
                            await FirebaseFirestore.instance
                                .collection('roles_permissions')
                                .doc('${farmID}_${role.name}')
                                .delete();
                            await FirebaseFirestore.instance
                                .collection('roles')
                                .doc('${farmID}_${role.name}')
                                .delete();
                            Navigator.pop(context);
                            fetchRoles();
                          },
                        ),
                        ElevatedButton(
                          child: Text("Update Role".tr()),
                          onPressed: () async {
                            final updatedRoleName = roleNameController.text.trim();
                            if (updatedRoleName.isEmpty || selectedPermissions.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Enter role name and select permissions'.tr())),
                              );
                              return;
                            }

                            await DatabaseHelper.updateRole(Role(name: updatedRoleName, id: role.id));
                            final permissionIds = selectedPermissions.map((p) => p.id!).toList();
                            await DatabaseHelper.assignPermissionsToRole(role.id!, permissionIds);
                            await uploadRoleToFirebase(farmID, Role(name: updatedRoleName, id: role.id));
                            await uploadRoleWithPermissionsToFirestore(
                              farmID,
                              updatedRoleName,
                              selectedPermissions.map((p) => p.name).toList(),
                            );
                            Navigator.pop(context);
                            fetchRoles();
                          },
                        )
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }


}
