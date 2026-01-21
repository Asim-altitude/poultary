import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/multiuser/utils/SyncStatus.dart';
import 'package:poultary/sale_contractor_profile.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/sale_contractor.dart';
import 'model/transaction_item.dart';
import 'multiuser/utils/RefreshMixin.dart';

class SaleContractorScreen extends StatefulWidget {
  @override
  _SaleContractorScreenState createState() => _SaleContractorScreenState();
}

class _SaleContractorScreenState extends State<SaleContractorScreen> with RefreshMixin {
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  @override
  void onRefreshEvent(String event) {
    try {
      if (event == FireBaseUtils.SALE_CONTRACTOR) {
        getAllContractors();
      }
    }
    catch(ex){
      print(ex);
    }
  }

  List<SaleContractor> contractors = [];
  List<SaleContractor> filteredContractors = []; // To store filtered contractors
  final TextEditingController searchController = TextEditingController();

  final List<String> contractorTypes = ['Eggs', 'Meat', 'Manure', 'Other'];

  @override
  void initState() {
    super.initState();
    getAllContractors();
    // Listen for search changes

    AnalyticsUtil.logScreenView(screenName: "sale_contractor_screen");
    if(Utils.isShowAdd){
      _loadBannerAd();
    }
  }
  _loadBannerAd(){
    // TODO: Initialize _bannerAd
    _bannerAd = BannerAd(
      adUnitId: Utils.bannerAdUnitId,
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }



  @override
  void dispose() {
    try{
      _bannerAd.dispose();
    }catch(ex){

    }
    super.dispose();
  }

  Future<void> getAllContractors() async {
    contractors = await DatabaseHelper.getContractors();
    for(int i=0;i<contractors.length;i++)
    {
      await fetchAdditionalData(contractors[i].name, i);
    }
    contractors.sort((a, b) => (b.pendingAmount ?? 0).compareTo(a.pendingAmount ?? 0));

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sale Contractors".tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue, // Customize the color
        elevation: 8, // Gives it a more elevated appearance
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigates back
          },
        ),
      ),

      body: Column(
        children: [
          // Search bar
          Utils.showBannerAd(_bannerAd, _isBannerAdReady),
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade100, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top section: Name + Type
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 16,
                            ),
                            title: Text(
                              contractor.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              'Type'.tr() + ': ${contractor.type.tr()}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onTap: () async {
                              try {
                                if (Utils.isMultiUSer &&
                                    Utils.currentUser!.role.toLowerCase() != "admin") {
                                  Utils.showMissingPermissionDialog(context, "Admin");
                                  return;
                                }
                              } catch (ex) {
                                print(ex);
                              }
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ContractorProfileScreen(
                                    contractor: contractor,
                                  ),
                                ),
                              );
                              getAllContractors();
                            },
                          ),

                          const Divider(height: 1),

                          // Sale & Pending Amount Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Sale Amount
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Sale Amount".tr(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "${Utils.currency}${contractor.saleAmount ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                // Pending Amount
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Pending Amount".tr(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "${Utils.currency}${contractor.pendingAmount ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
    );
  }


  List<TransactionItem> transactions = [];
  Future<void> fetchAdditionalData(String name, int index) async {
    num saleAmount = 0, clearedAmount = 0, pendingAmount = 0;
    transactions = await DatabaseHelper.getTransactionsForContractor(name);
    for (var transaction in transactions) {
      saleAmount += num.parse(transaction.amount);

      if (transaction.payment_status.toUpperCase() == 'CLEARED') {
        clearedAmount += num.parse(transaction.amount);
      } else {
        pendingAmount += num.parse(transaction.amount);
      }
    }

    contractors.elementAt(index).saleAmount = saleAmount;
    contractors.elementAt(index).clearedAmount = clearedAmount;
    contractors.elementAt(index).pendingAmount = pendingAmount;


    setState(() {

    });
  }

  void _showAddContractorDialog(BuildContext context) {
    try {
      if (Utils.isMultiUSer &&
          Utils.currentUser!.role.toLowerCase() != "admin") {
        Utils.showMissingPermissionDialog(context, "Admin");
        return;
      }
    } catch (ex) {
      print(ex);
    }

    final nameController = TextEditingController();
    final otherController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = contractorTypes[0];

    bool isOther = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
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
                      Text('Add Sale Contractor'.tr(),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Enter Name'.tr(),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: selectedType,
                        items: contractorTypes.map((type) {
                          return DropdownMenuItem(
                              value: type, child: Text(type.tr()));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            selectedType = val;
                            setModalState(() {
                              isOther = val.toLowerCase() == "other";
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Type'.tr(),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (isOther)
                        Column(
                          children: [
                            TextField(
                              controller: otherController,
                              decoration: InputDecoration(
                                labelText: 'Enter Type'.tr(),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),

                      TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone'.tr(),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email'.tr(),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: addressController,
                        decoration: InputDecoration(
                          labelText: 'Address'.tr(),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: 'Notes'.tr(),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: () async {
                          // Create a new SaleContractor object
                          SaleContractor contractor = SaleContractor(
                            name: nameController.text,
                            type: isOther
                                ? otherController.text
                                : selectedType,
                            address: addressController.text,
                            phone: phoneController.text,
                            email: emailController.text,
                            notes: notesController.text,
                            sync_id: Utils.getUniueId(),
                            sync_status: SyncStatus.SYNCED,
                            last_modified: Utils.getTimeStamp(),
                            farm_id: Utils.isMultiUSer
                                ? Utils.currentUser!.farmId
                                : '',
                            modified_by: Utils.isMultiUSer
                                ? Utils.currentUser!.email
                                : '',
                          );

                          // Insert into the database
                          await DatabaseHelper.insertSaleContractor(contractor);

                          if (Utils.isMultiUSer &&
                              Utils.hasFeaturePermission("add_contractors")) {
                            await FireBaseUtils.addSaleContractor(contractor);
                          }

                          getAllContractors();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: Text("SAVE".tr(),
                            style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Utils.getThemeColorBlue(),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

}
