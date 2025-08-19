import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/sale_contractor.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:poultary/utils/utils.dart';

import 'package:intl/intl.dart';

import 'multiuser/utils/FirebaseUtils.dart';
import 'multiuser/utils/RefreshMixin.dart';
import 'multiuser/utils/SyncStatus.dart';

class ContractorProfileScreen extends StatefulWidget {
  final SaleContractor contractor;

  const ContractorProfileScreen({Key? key, required this.contractor}) : super(key: key);

  @override
  _ContractorProfileScreenState createState() => _ContractorProfileScreenState();
}

class _ContractorProfileScreenState extends State<ContractorProfileScreen> with RefreshMixin {

  @override
  void onRefreshEvent(String event) async {
    try {
      if (event == FireBaseUtils.SALE_CONTRACTOR) {
        SaleContractor? saleContractor = await DatabaseHelper.getSaleContractorBySyncId(widget.contractor.sync_id!);
        if(saleContractor == null){
          Utils.showToast("Contractor deleted".tr());
          Navigator.pop(context);
        }else{
          contractor = widget.contractor;
          fetchAdditionalData();
        }
      }
    }
    catch(ex){
      print(ex);
    }
  }

  bool isLoading = true;
  late SaleContractor contractor;
  num pendingAmount = 0, saleAmount = 0, clearedAmount = 0;
  List<TransactionItem> transactions = [];

  @override
  void initState() {
    super.initState();
    contractor = widget.contractor;
    fetchAdditionalData();
  }

  Future<void> fetchAdditionalData() async {
    transactions = await DatabaseHelper.getTransactionsForContractor(widget.contractor.name);
    for (var transaction in transactions) {
      saleAmount += num.parse(transaction.amount);

      if (transaction.payment_status.toUpperCase() == 'CLEARED') {
        clearedAmount += num.parse(transaction.amount);
      } else {
        pendingAmount += num.parse(transaction.amount);
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
  Widget _saleSummaryCard({required String title, required String value, Color? color}) {
    return Container(
      height: 110,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(title.tr(), style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color ?? Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard({required String title, required String value, Color? color}) {
    return Container(
      height: 100,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(title.tr(), style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double widthScreen = 0;
  double heightScreen = 0;
  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency(name: Utils.currency);
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
        title: Text('${contractor.name}'),
        backgroundColor: Utils.getThemeColorBlue(),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contractor Info Card (same as before)
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTapDown: (details) {
                          showMemberMenu(details.globalPosition);
                        },
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Image.asset("assets/options.png", width: 30, height: 20, color: Colors.black),
                        ),
                      ),
                      Text(contractor.name,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text('Type'.tr()+': ${contractor.type}', style: TextStyle(color: Colors.grey[700])),
                      SizedBox(height: 5),
                      Text('${contractor.address}', style: TextStyle(color: Colors.grey[700])),
                      SizedBox(height: 10),
                      _infoRow(Icons.phone, contractor.phone ?? 'Not Available'.tr()),
                      _infoRow(Icons.email, contractor.email ?? 'Not Available'.tr()),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Balance Summary
              Text("Balance Summary".tr(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _balanceRow('Sale Amount', formatter.format(saleAmount), Colors.teal),
                      SizedBox(height: 12),
                      _balanceRow('Cleared Amount', formatter.format(clearedAmount), Colors.green),
                      SizedBox(height: 12),
                      _balanceRow('Pending Amount', formatter.format(pendingAmount), Colors.orange),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Transaction History
              Text("Transaction History".tr(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              SizedBox(height: 10),

              transactions.isEmpty
                  ? Center(child: Text("No transactions found".tr()))
                  : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.receipt, color: Colors.white),
                      ),
                      title: Text(Utils.currency+'${tx.amount}', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(Utils.getFormattedDate(tx.date),
                              style: TextStyle(fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Items'.tr()+': ${tx.how_many} ${tx.sale_item.tr()}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18),
                      onTap: () {
                        // Detail page
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        )
        ,
      ),
    );
  }

  Widget _balanceRow(String title, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Text(
          '$value',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }


  void showMemberMenu(Offset offset) async {
    double left = offset.dx;
    double top = offset.dy;
    await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(left, top, 0, 0),
      color: Colors.white,
      items: [
        PopupMenuItem(
          value: 2,
          child: Text(
            "EDIT_RECORD".tr(),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Text(
            "DELETE_RECORD".tr(),
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ),


      ],
      elevation: 8.0,
    ).then((value) async{
      if (value != null) {
        if(value == 2){
          _showContractorDialog(context,isEdit: true);
        }
        else if(value == 1){
          _confirmDelete(context);
        }else {
          print(value);
        }
      }
    });
  }


  final List<String> contractorTypes = ['Eggs', 'Meat', 'Manure', 'Other'];

  void _showContractorDialog(BuildContext context, {bool isEdit = false}) {
    final nameController = TextEditingController(text: isEdit ? contractor.name : '');
    final phoneController = TextEditingController(text: isEdit ? contractor.phone : '');
    final emailController = TextEditingController(text: isEdit ? contractor.email : '');
    final addressController = TextEditingController(text: isEdit ? contractor.address : '');
    final notesController = TextEditingController(text: isEdit ? contractor.notes : '');
    String selectedType = isEdit ? contractor.type : contractorTypes[0];

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
                Text(
                  isEdit ? 'Update'.tr() : 'New Sale Contractor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
                    return DropdownMenuItem(value: type, child: Text(type));
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
                    final updatedContractor = SaleContractor(
                      id: isEdit ? contractor.id : null,
                      name: nameController.text,
                      type: selectedType,
                      address: addressController.text,
                      phone: phoneController.text,
                      email: emailController.text,
                      notes: notesController.text,
                      sync_id: contractor.sync_id,
                      sync_status: SyncStatus.UPDATED,
                      farm_id: Utils.isMultiUSer? Utils.currentUser!.farmId : '',
                      modified_by: Utils.isMultiUSer? Utils.currentUser!.email : '',
                      last_modified: Utils.getTimeStamp()
                    );

                    if (isEdit) {
                      await DatabaseHelper.updateSaleContractor(updatedContractor);

                      if(Utils.isMultiUSer && Utils.hasFeaturePermission("edit_contractors")){
                        await FireBaseUtils.updateSaleContractor(updatedContractor);
                      }

                      setState(() => contractor = updatedContractor);
                    } else {
                      await DatabaseHelper.insertSaleContractor(updatedContractor);

                      if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_contractors")){
                        updatedContractor.sync_status = SyncStatus.SYNCED;
                        updatedContractor.sync_id = Utils.getUniueId();
                        updatedContractor.last_modified = Utils.getTimeStamp();
                        await FireBaseUtils.addSaleContractor(updatedContractor);
                      }

                    }

                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.save, color: Colors.white),
                  label: Text(isEdit ? 'Update'.tr() : 'SAVE'.tr(), style: TextStyle(color: Colors.white)),
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


  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('DELETE'.tr()),
        content: Text('Are you sure you want to delete this contractor?'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.deleteSaleContractor(contractor.id!);


              if(Utils.isMultiUSer && Utils.hasFeaturePermission("delete_contractors")){
                contractor.sync_status = SyncStatus.DELETED;
                contractor.last_modified = Utils.getTimeStamp();
                await FireBaseUtils.updateSaleContractor(contractor);
              }

              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close profile screen
            },
            child: Text('DELETE'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,

            ),
          ),
        ],
      ),
    );
  }


}
