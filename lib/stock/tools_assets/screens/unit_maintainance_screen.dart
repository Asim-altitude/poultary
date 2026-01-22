import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';

import '../../../database/databse_helper.dart';
import '../../../model/transaction_item.dart';
import '../../../multiuser/model/unit_maintenance_fb.dart';
import '../../../multiuser/utils/SyncStatus.dart';
import '../../../utils/utils.dart';
import '../model/tool_asset_maintenance.dart';
import '../model/tool_asset_unit.dart';

class AssetMaintenanceScreen extends StatefulWidget {
  final ToolAssetUnit unit;

  const AssetMaintenanceScreen({super.key, required this.unit});

  @override
  State<AssetMaintenanceScreen> createState() =>
      _AssetMaintenanceScreenState();
}

class _AssetMaintenanceScreenState extends State<AssetMaintenanceScreen> {
  List<ToolAssetMaintenance> logs = [];
  bool loading = true;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    logs = await DatabaseHelper.getMaintenanceByUnit(widget.unit.id!);
    setState(() => loading = false);
    if(Utils.isShowAdd && logs.length>0){
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Maintenance".tr()+" • ${widget.unit.assetCode ?? 'Unit'.tr()}",
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : logs.isEmpty
          ? _emptyState()
          : Stack(children: [
        ListView.builder(
          padding: const EdgeInsets.only(left: 12,right: 12,top: 60),
          itemCount: logs.length,
          itemBuilder: (_, i) => _maintenanceCard(logs[i]),
        ),
        if(_isBannerAdReady)   Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Container(
            height: 60,
            color: Colors.white,
            child:
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                      height: 60.0,
                      width: Utils.WIDTH_SCREEN,
                      child: AdWidget(ad: _bannerAd)
                  ),
                ), // your banner here
          ),
        ),
      ],),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => {
          if(Utils.isMultiUSer && !Utils.hasFeaturePermission("add_stock")){
            Utils.showMissingPermissionDialog(context, "add_stock")
            }
          else
            {
              _showAddMaintenanceDialog()
            }
        },
        icon: const Icon(Icons.build),
        label:  Text("Add Maintenance".tr()),
      ),
    );
  }


  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.engineering, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
           Text(
            "No maintenance records yet".tr(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            "All maintenance history will appear here".tr(),
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }


  Widget _maintenanceCard(ToolAssetMaintenance m) {
    final Color statusColor =
    m.status == "Completed" ? Colors.green : Colors.orange;

    return Dismissible(
      key: ValueKey(m.id),
      direction: DismissDirection.endToStart,

      // ---------- CONFIRM BEFORE DELETE ----------
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title:  Text("Delete".tr()),
            content:  Text(
                "RU_SURE".tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child:  Text("CANCEL".tr()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child:  Text("Delete".tr()),
              ),
            ],
          ),
        );
      },

      // ---------- DELETE ACTION ----------
      onDismissed: (_) async {

        if(Utils.isMultiUSer && !Utils.hasFeaturePermission("delete_stock")){
          Utils.showMissingPermissionDialog(context, "delete_stock");
          return;
        }

        TransactionItem? trItem = await DatabaseHelper.getSingleTransaction(m.trId.toString());
        await DatabaseHelper.deleteMaintenanceLog(m.id!);

        AssetUnitMaintenanceFBModel assetUnitMaintenanceFBModel = AssetUnitMaintenanceFBModel(maintenance: m);
        assetUnitMaintenanceFBModel.transaction = trItem!;
        if(Utils.isMultiUSer && Utils.hasFeaturePermission("delete_stock")){
          await FireBaseUtils.deleteAssetUnitMaintenanceStockTransRecord(assetUnitMaintenanceFBModel);
        }

        _loadLogs(); // reload list
      },

      // ---------- BACKGROUND ----------
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- HEADER ----------
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings, color: Colors.blue),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      m.maintenanceType.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      m.status.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ---------- DESCRIPTION ----------
              if (m.description != null)
                Text(
                  m.description!,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

              const SizedBox(height: 8),

              Row(
                children: [
                  _infoChip(Icons.calendar_today, m.maintenanceDate),
                  const SizedBox(width: 8),
                  _infoChip(
                    Icons.currency_exchange,
                    "Cost".tr()+": ${m.cost.toStringAsFixed(2)}",
                  ),
                ],
              ),

              if (m.nextDueDate != null) ...[
                const SizedBox(height: 8),
                _infoChip(Icons.alarm, "Next".tr()+": ${m.nextDueDate}"),
              ],


              if (m.status == "Pending") ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    label:  Text(
                      "Mark as Completed".tr(),
                      style: TextStyle(color: Colors.green),
                    ),
                    onPressed: () async {
                      await DatabaseHelper.updateMaintenanceStatus(
                        m.id!,
                        "Completed",
                        DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      );
                      _loadLogs();
                    },
                  ),
                ),
              ],

            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }



  void _showAddMaintenanceDialog() {
    final typeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final byCtrl = TextEditingController();
    final List<String> maintenanceTypes = [
      "Routine",
      "Repair",
      "Replacement",
      "Inspection",
      "Calibration",
      "Other"
    ];

    String selectedType = maintenanceTypes[0];
    final otherTypeCtrl = TextEditingController();

    String status = "Completed";
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Drag Indicator
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // Title
                    Center(
                      child: Text(
                        "Add Maintenance".tr(),
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Input Fields
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Maintenance Type".tr(),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),

                        Wrap(
                          spacing: 8,
                          children: maintenanceTypes.map((type) {
                            final isSelected = selectedType == type;
                            return ChoiceChip(
                              label: Text(type.tr()),
                              selected: isSelected,
                              selectedColor: Colors.blue.shade600,
                              backgroundColor: Colors.grey.shade200,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  selectedType = type;
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 12),

                        // Show input field if "Other" is selected
                        if (selectedType == "Other")
                          TextField(
                            controller: otherTypeCtrl,
                            decoration: InputDecoration(
                              labelText: "Specify Maintenance Type".tr(),
                              prefixIcon: const Icon(Icons.edit),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                      ],
                    ),

                    _field(costCtrl, "Cost", Icons.currency_exchange, type: TextInputType.number),
                    _field(byCtrl, "Performed By", Icons.person),
                    _field(descCtrl, "Description (optional)", Icons.notes, lines: 2),
                    const SizedBox(height: 16),

                    // STATUS SELECTION
                    Text(
                      "Status".tr(),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ["Completed", "Pending"].map((s) {
                        final selected = status == s;
                        return ChoiceChip(
                          label: Text(
                            s.tr(),
                            style: TextStyle(
                                color: selected ? Colors.white : Colors.black87),
                          ),
                          selected: selected,
                          selectedColor: s == "Completed"
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                          backgroundColor: Colors.grey.shade200,
                          onSelected: (_) => setState(() => status = s),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // DATE PICKER
                    Text(
                      "Maintenance Date".tr(),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(date) ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            date = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Colors.grey, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              date,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          backgroundColor: Colors.blue.shade600,
                        ),
                        onPressed: () async {

                          AssetUnitMaintenanceFBModel unitMaintenanceFB;

                          final maintenanceTypeToSave = selectedType == "Other"
                              ? otherTypeCtrl.text.trim()
                              : selectedType;

                          if (maintenanceTypeToSave.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Please specify maintenance type".tr())
                                ));
                            return;
                          }

                          var maintenance_cost = costCtrl.text;

                          print(widget.unit.toMap());
                          TransactionItem trItem = TransactionItem(f_id: -1, date: date, f_name: "Farm Wide", sale_item: "", expense_item:  widget.unit.assetCode!+" "+"Maintenance", type: "Expense", amount: maintenance_cost, payment_method: "Cash", payment_status: "CLEARED", sold_purchased_from: byCtrl.text.trim().isEmpty ? "Unknown" : byCtrl.text.trim(), short_note: widget.unit.assetCode!+" "+"Maintenance cost", how_many: "1", extra_cost: "extra_cost", extra_cost_details: "extra_cost_details", flock_update_id: "-1", unitPrice: double.tryParse(maintenance_cost) ?? 0);
                          int? trId = await DatabaseHelper.insertNewTransaction(trItem);

                          var maintenance = ToolAssetMaintenance(
                            assetUnitId: widget.unit.id!,
                            maintenanceType: maintenanceTypeToSave,
                            description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                            cost: double.tryParse(costCtrl.text) ?? 0,
                            performedBy: byCtrl.text.trim().isEmpty ? null : byCtrl.text.trim(),
                            maintenanceDate: date,
                            status: status,
                            createdAt: DateTime.now().toIso8601String(),
                            trId: trId,
                            asset_sync_id: widget.unit.sync_id,
                            sync_id: Utils.getUniueId(),
                            sync_status: SyncStatus.SYNCED,
                            last_modified: Utils.getTimeStamp(),
                            modified_by: Utils.currentUser == null ? '' : Utils.currentUser!.email,
                            farm_id: Utils.currentUser == null ? '' : Utils.currentUser!.farmId,
                          );
                          await DatabaseHelper.insertMaintenanceLog(
                            maintenance,
                          );

                          unitMaintenanceFB = AssetUnitMaintenanceFBModel(maintenance: maintenance);
                          unitMaintenanceFB.transaction = trItem;

                          if(Utils.isMultiUSer && Utils.hasFeaturePermission("add_stock")){
                            await FireBaseUtils.uploadAssetUnitMaintenanceStockRecord(unitMaintenanceFB);
                          }

                          Navigator.pop(context);
                          _loadLogs();
                        },
                        child:  Text(
                          "Save Maintenance".tr(),
                          style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

// Reusable input field
  Widget _field(TextEditingController c, String label, IconData icon,
      {int lines = 1, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: lines,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label.tr(),
          prefixIcon: Icon(icon, color: Colors.grey.shade700),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }




}