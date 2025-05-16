import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poultary/sale_contractor_profile.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/sale_contractor.dart';

class SaleContractorScreen extends StatefulWidget {
  @override
  _SaleContractorScreenState createState() => _SaleContractorScreenState();
}

class _SaleContractorScreenState extends State<SaleContractorScreen> {
  List<SaleContractor> contractors = [];
  List<SaleContractor> filteredContractors = []; // To store filtered contractors
  final TextEditingController searchController = TextEditingController();

  final List<String> contractorTypes = ['Eggs', 'Meat', 'Manure', 'Other'];

  @override
  void initState() {
    super.initState();
    getAllContractors();
    // Listen for search changes
  }

  Future<void> getAllContractors() async {
    contractors = await DatabaseHelper.getContractors();
    setState(() {
      filteredContractors = contractors; // Set the filtered contractors to all initially
    });
    searchController.addListener(_filterContractors);
  }

  void _filterContractors() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredContractors = contractors.where((contractor) {
        return contractor.name.toLowerCase().contains(query) ||
            contractor.type.toLowerCase().contains(query);
      }).toList();
    });
  }
  double widthScreen = 0;
  double heightScreen = 0;

  @override
  Widget build(BuildContext context) {
    double safeAreaHeight = MediaQuery.of(context).padding.top;
    double safeAreaHeightBottom = MediaQuery.of(context).padding.bottom;

    widthScreen =
        MediaQuery.of(context).size.width; // because of default padding
    heightScreen = MediaQuery.of(context).size.height;
    Utils.WIDTH_SCREEN = widthScreen;
    Utils.HEIGHT_SCREEN = MediaQuery.of(context).size.height -
        (safeAreaHeight + safeAreaHeightBottom);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title:  Text('Sale Contractors'.tr()),
          foregroundColor: Colors.white,
          backgroundColor: Utils.getThemeColorBlue(),
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: widthScreen - 20,
                margin: EdgeInsets.only(top: 10),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or type...'.tr(),
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.blue),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            // ListView displaying contractors
            Expanded(
              child: filteredContractors.isEmpty
                  ? Center(
                child: Text(
                  'No Sale Contractor Added'.tr(),
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ) : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filteredContractors.length,
                itemBuilder: (context, index) {
                  final contractor = filteredContractors[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    margin: const EdgeInsets.symmetric(
                        vertical: 4, horizontal: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade100,
                              Colors.white
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ListTile for name and type
                            ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 5, horizontal: 16),
                              title: Text(
                                contractor.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                'Type'.tr()+': ${contractor.type.tr()}',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onTap: () async {
                                // Navigate to contractor details if needed
                               await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>  ContractorProfileScreen(contractor: contractor,)),
                                );

                               getAllContractors();
                              },
                            ),
                            // Divider for separation

                            // Phone and Email row

                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddContractorDialog(context),
          label: Text("Add".tr()),
          icon: Icon(Icons.add),
          foregroundColor: Colors.white,
          backgroundColor: Utils.getThemeColorBlue(),
        ),
      ),
    );
  }


  void _showAddContractorDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = contractorTypes[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Add Sale Contractor'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Enter Name'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: contractorTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type.tr()));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) selectedType = val;
                  },
                  decoration: InputDecoration(
                    labelText: 'Type'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Address'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () async {
                    // Create a new SaleContractor object
                    SaleContractor contractor = SaleContractor(
                      name: nameController.text,
                      type: selectedType,
                      address: addressController.text,
                      phone: phoneController.text,
                      email: emailController.text,
                      notes: notesController.text,
                    );

                    // Insert into the database
                    await DatabaseHelper.insertSaleContractor(contractor);
                    getAllContractors();
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.save, color: Colors.white,),
                  label: Text("SAVE".tr(), style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Utils.getThemeColorBlue(),
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
