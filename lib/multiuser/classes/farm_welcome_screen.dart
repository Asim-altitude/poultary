import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:poultary/auto_add_feed_screen.dart';
import 'package:poultary/home_screen.dart';
import 'package:poultary/multiuser/classes/backup_restore.dart';
import 'package:poultary/multiuser/model/user.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../consume_store.dart';
import '../../settings_screen.dart';
import '../../utils/session_manager.dart';
import '../../utils/utils.dart';
import '../model/farm_plan.dart';
import '../utils/FirebaseUtils.dart';
import '../utils/plan_state.dart';
import 'WorkerDashboard.dart';

class FarmWelcomeScreen extends StatefulWidget {
  MultiUser multiUser;
  bool isStart;

   FarmWelcomeScreen({
    super.key,
    required this.multiUser,
     required this.isStart
  });

  @override
  State<FarmWelcomeScreen> createState() => _FarmWelcomeScreenState();
}

class _FarmWelcomeScreenState extends State<FarmWelcomeScreen> {
  PlanStatus _planStatus = PlanStatus.notStarted;
  DateTime? _startDate;
  DateTime? _expiryDate;
  bool loading = true;

  bool initialized = false;
  FarmPlan? _farmPlan;

  @override
  void initState() {
    loadInAppData();
    beforeInit();
    super.initState();
    _loadBackupInfo();
    _loadPlanInfo();
   // Utils.setupAds();
  }

  Future<void> _loadBackupInfo() async {
    try {
      initialized = await SessionManager.getBool('db_initialized_${widget.multiUser.farmId}') ?? false;
    } catch (ex) {
      print(ex);
    }
  }

  Future<void> _loadPlanInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FireBaseUtils.MULTIUSER_PLAN)
          .doc(widget.multiUser.farmId)
          .get();

      if (!doc.exists || doc.data() == null) {
        setState(() {
          _planStatus = PlanStatus.notStarted;
          loading = false;
        });
        return;
      }

      final data = doc.data()!;

      FarmPlan farmPlan = FarmPlan.fromJson(data);
      _farmPlan = farmPlan;
      print(_farmPlan!.toJson());

      if(!farmPlan.isActive){
        Utils.isMultiUSer = false;
      }

      await SessionManager.saveFarmPlan(farmPlan);

      setState(() {
        _farmPlan = farmPlan;
        _startDate = farmPlan.planStartDate;
        _expiryDate = farmPlan.planExpiryDate;
        _planStatus = farmPlan.isActive ? PlanStatus.active : PlanStatus.expired;
        loading = false;
      });

    } catch (e) {
      setState(() {
        _planStatus = PlanStatus.notStarted;
        loading = false;
      });

      print('Error loading plan info: $e');

    }
  }

  bool isTrial() {

    bool isTrial = false;
    print("CHECKING");
    if(_farmPlan!.planType.toLowerCase() == "trial"){
      isTrial = true;
      print("TRIAL");
    }
    print("DONE");
    return isTrial;

  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0, // removes the shadow
        scrolledUnderElevation: 0, // removes shadow when scrolling (Flutter 3.7+)
        surfaceTintColor: Colors.transparent, // removes Material3 tint
        backgroundColor: const Color(0xFFF5F9FF), // Customize the color

      ),
      backgroundColor: const Color(0xFFF5F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            child: Column(
              children: [
                const SizedBox(height: 100),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: (Utils.currentUser!.image != null && Utils.currentUser!.image.isNotEmpty)
                      ? NetworkImage(Utils.ProxyAPI+Utils.currentUser!.image)
                      : null,
                  child: (Utils.currentUser!.image == null || Utils.currentUser!.image.isEmpty)
                      ? Image.asset("assets/farm_icon.png", width: 120, height: 120,)
                      : null,),

                /* Text(
                  "Easy Poultry Manager".tr(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),*/
                const SizedBox(height: 8),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Welcome,".tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ), Text(
                        " ${widget.multiUser.name}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Role:".tr()+" ${widget.multiUser.role}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Farm ID:".tr()+" ${widget.multiUser.farmId}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ),

                SizedBox(height: 5,),

                const SizedBox(height: 24),
                (_planStatus == PlanStatus.expired
                    || _planStatus == PlanStatus.notStarted || !widget.isStart) ? _buildPlanCard() : SizedBox.shrink(),
               // const SizedBox(height: 24),
                SizedBox(height: 10),
                /// Continue  Button
                if (_planStatus == PlanStatus.active)
                  _buildPrimaryButton(
                    label: "Continue to App",
                    icon: Icons.arrow_forward,
                    color: Colors.blue.shade700,
                    onPressed: _navigateToNextScreen,)
                else if (widget.multiUser.role.toLowerCase() == 'admin')
                  Container(
                    margin: EdgeInsets.only(left: 20, right: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),

                        /*// Trial Button (highlighted)
                        if (_planStatus == PlanStatus.notStarted)
                          _buildPrimaryButton(
                            label: "Activate 7-Day Trial",
                            icon: Icons.flash_on,
                            color: Colors.deepOrange,
                            onPressed: () {
                              if (_planStatus == PlanStatus.notStarted) {
                                _handlePlanUpgrade("Trial");
                              } else {
                                _showPremiumDialog(context);
                              }
                            },
                          ),*/

                       // const SizedBox(height: 12),

                        // Upgrade Button
                        _buildPrimaryButton(
                          label: (_planStatus == PlanStatus.notStarted && !Utils.isShowAdd)
                              ? "Create Plan"
                              : "Upgrade to Premium",
                          icon: Icons.workspace_premium,
                          color: Colors.green.shade600,
                          onPressed: () {
                            if(Utils.isShowAdd)
                                print("TRUE");
                              else
                                print("FALSE");

                            if ((_planStatus == PlanStatus.notStarted || isTrial()) && !Utils.isShowAdd)
                            {
                              _handlePlanUpgrade("Premium", "Basic");
                            }
                            else
                            {
                              _showPremiumDialog(context);
                            }
                          },
                        ),

                        const SizedBox(height: 12),

                        // Offline Button (only for Admin at start)
                        if (widget.multiUser.role.toLowerCase() == 'admin' && widget.isStart)
                          _buildPrimaryButton(
                            label: "Continue in Offline Mode",
                            icon: Icons.offline_pin,
                            color: Colors.grey.shade700,
                            onPressed: () async {
                              Utils.isMultiUSer = false;
                              bool isConfirmed =
                              await SessionManager.getBool(SessionManager.offlineConfirmation);
                              if (!isConfirmed) {
                                showOfflineModeDialog(context, (value) {
                                  SessionManager.setBoolValue(
                                      SessionManager.offlineConfirmation, value);
                                });
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => HomeScreen()),
                                );
                              }
                            },
                          ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "⚠️ Please contact your Admin or Farm Manager to upgrade the plan.".tr(),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: initializingSync
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : Icon(icon),
      label: Text(label.tr()),
      onPressed: initializingSync ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );

  }

  bool initializingSync = false;


  void _navigateToNextScreen() async {

    await SessionManager.saveFarmPlan(_farmPlan!);

    if(!widget.isStart) {
      Utils.isShowAdd = false;
      Utils.isMultiUSer = true;
      Navigator.pop(context);
      return;
    }

   /* setState(() {
      initializingSync = true;
    });

    await _initializeSync();

    setState(() {
      initializingSync = false;
    });*/
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isAutoFeedEnabled = prefs.getBool('isAutoFeedEnabled') ?? false;

    Utils.isShowAdd = false;
    Utils.isMultiUSer = true;
    Utils.isTrialActive = isTrial();
    Utils.setupAds();
    if (initialized) {
      if (widget.multiUser.role.toLowerCase() == 'admin') {
        if(isAutoFeedEnabled){
          Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) =>
                AutoFeedSyncScreen(),)
            , (route) => false,);
        }else
        {
          Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) =>
                HomeScreen(),)
            , (route) => false,);
        }
       /* Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );*/
      } else {
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) =>
              WorkerDashboardScreen(
                name: widget.multiUser.name,
                email: widget.multiUser.email,
                role: widget.multiUser.role,
              ),)
          ,(route) => false,);

       /* Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WorkerDashboardScreen(
              name: widget.multiUser.name,
              email: widget.multiUser.email,
              role: widget.multiUser.role,
            ),
          ),
        );*/
      }
    } else {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) =>
            BackupFoundScreen(
              isAdmin: widget.multiUser.role.toLowerCase() == 'admin',
              user: widget.multiUser,
            ),)
        ,(route) => false,);

     /* Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BackupFoundScreen(
            isAdmin: widget.multiUser.role.toLowerCase() == 'admin',
            user: widget.multiUser,
          ),
        ),
      );*/
    }
  }

  Future<void> _handlePlanUpgrade(String type, String planName) async {
    DateTime planStartDate = DateTime.now();
    DateTime planExpiryDate = type.toLowerCase() == "trial"? DateTime(
      planStartDate.year,
      planStartDate.month,
      planStartDate.day + 7) : DateTime(
      planStartDate.year,
      planStartDate.month + 6,
      planStartDate.day,);

    FarmPlan farmPlan = FarmPlan(
      farmId: widget.multiUser.farmId,
      adminEmail: widget.multiUser.email,
      planName: planName,
      planType: type,
      planStartDate: planStartDate,
      planExpiryDate: planExpiryDate,
      userCapacity: type.toLowerCase() == "trial"? 2 : 10,);

    await FireBaseUtils.upgradeMultiUserPlan(farmPlan);
    _loadPlanInfo();
  }

  Widget _buildPlanCard() {
    String statusText;
    Color statusColor;

    if (_planStatus == PlanStatus.active && _farmPlan!.planType.toLowerCase()=="trial") {
      final daysLeft = _expiryDate!.difference(DateTime.now()).inDays;
      statusText =  "Trial Active".tr() + " - $daysLeft " + "day(s) left".tr();
      statusColor = Colors.orange.shade700;
    }else if (_planStatus == PlanStatus.active) {
      final daysLeft = _expiryDate!.difference(DateTime.now()).inDays;
      statusText = "✅" + "Active".tr() + " - $daysLeft " + "day(s) left".tr();
      statusColor = Colors.green.shade700;
    } else if (_planStatus == PlanStatus.expired) {
      statusText = "❌ Expired - Please upgrade".tr();
      statusColor = Colors.red.shade700;
    } else if (_planStatus == PlanStatus.notStarted) {
      statusText = "⚠️" + "No Plan Found - Please activate".tr();
      statusColor = Colors.orange.shade800;
    } else {
      statusText = "⚠️" + "No Plan Found - Please activate".tr();
      statusColor = Colors.orange.shade800;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            "📦"+"Your Farm Plan".tr(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_startDate != null)
            _buildPlanRow("Plan Started:", _formatDate(_startDate!)),
          const SizedBox(height: 8),
          if (_expiryDate != null)
            _buildPlanRow("Plan Expires:", _formatDate(_expiryDate!)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanRow(String label, String value) {
    return Row(
      children: [
        Text(
          label.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')} "
        "${_monthName(date.month)} ${date.year}";
  }

  String _monthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  loadInAppData(){
    _kProductIds.add(premiumPoultry);
  }
  beforeInit(){
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription =
        purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
          _listenToPurchaseUpdated(purchaseDetailsList);
        }, onDone: () {
          _subscription.cancel();
        }, onError: (Object error) {
          // handle error here.
        });
    initStoreInfo();
  }
  Future<void> consume(String id) async {
    await ConsumableStore.consume(id);
    final List<String> consumables = await ConsumableStore.load();
    setState(() {
      _consumables = consumables;
    });
  }

  void showPendingUI() {
    setState(() {
      _purchasePending = true;
    });
  }


  Future<void> deliverProduct(PurchaseDetails purchaseDetails) async {
    print("Payment successfull");


    // IMPORTANT!! Always verify purchase details before delivering the product.
    if (purchaseDetails.productID == premiumPoultry) {
      await ConsumableStore.save(purchaseDetails.purchaseID!);
      final List<String> consumables = await ConsumableStore.load();
      await SessionManager.setInApp(true);
      Utils.isShowAdd = false;
      Utils.setupAds();
      await _handlePlanUpgrade("Premium","Upgrade");
      setState(() {
        _purchasePending = false;
        _consumables = consumables;
      });
    } else {
      setState(() {
        _purchases.add(purchaseDetails);
        _purchasePending = false;
      });
    }
  }

  void handleError(IAPError error) {
    setState(() {
      _purchasePending = false;
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
    // IMPORTANT!! Always verify a purchase before delivering the product.
    // For the purpose of an example, we directly return true.
    return Future<bool>.value(true);
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    // handle invalid purchase here if  _verifyPurchase` failed.
  }



  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
          final bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            deliverProduct(purchaseDetails);
          } else {
            _handleInvalidPurchase(purchaseDetails);
            return;
          }
        }
        if (Platform.isAndroid) {
          if (!_kAutoConsume && purchaseDetails.productID == premiumPoultry) {
            final InAppPurchaseAndroidPlatformAddition androidAddition =
            _inAppPurchase.getPlatformAddition<
                InAppPurchaseAndroidPlatformAddition>();
            await androidAddition.consumePurchase(purchaseDetails);
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _products = <ProductDetails>[];
        _purchases = <PurchaseDetails>[];
        _notFoundIds = <String>[];
        _consumables = <String>[];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
      _inAppPurchase
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    final ProductDetailsResponse productDetailResponse =
    await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error!.message;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchases = <PurchaseDetails>[];
        _notFoundIds = productDetailResponse.notFoundIDs;
        _consumables = <String>[];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError = null;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _purchases = <PurchaseDetails>[];
        _notFoundIds = productDetailResponse.notFoundIDs;
        _consumables = <String>[];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    final List<String> consumables = await ConsumableStore.load();
    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _notFoundIds = productDetailResponse.notFoundIDs;
      _consumables = consumables;
      _purchasePending = false;
      _loading = false;
    });
  }

  String premiumPoultry = "premiumsubscriptionpoultry1";
  final bool _kAutoConsume = Platform.isIOS || true;
  List<String> _kProductIds = <String>[
  ];

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<String> _notFoundIds = <String>[];
  List<ProductDetails> _products = <ProductDetails>[];
  List<PurchaseDetails> _purchases = <PurchaseDetails>[];
  List<String> _consumables = <String>[];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _queryProductError;

  /*Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange.withOpacity(0.1),
            radius: 24,
            child: Icon(icon, size: 24, color: Colors.orange),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(description, style: TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
*/

  void _showPremiumDialog(BuildContext context) {
    int selectedPlan = 0; // 0 = Ads Removal, 1 = Premium Subscription

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FractionallySizedBox(
              heightFactor: 0.85,
              child: Column(
                children: [
                  /// **Header**
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue, Colors.green],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                    ),
                    child: Column(
                      children: [
                        Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Icon(Icons.cancel_outlined, size: 30, color: Colors.white))),

                        Icon(Icons.workspace_premium, size: 70, color: Colors.white),
                        SizedBox(height: 8),
                        Text(
                          "Upgrade Farm Plan".tr(),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Upgrade to unlock farm features".tr(),
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// Features Checklist
                  Expanded(
                    child: ListView(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      children: [
                        _buildFeatureItem(
                            "No Ads".tr(),
                            "Enjoy distraction-free experience".tr(),
                            included: true,
                            alwaysIncluded: true,
                            duration: "Lifetime"),
                        _buildFeatureItem(
                            "Priority Support".tr(),
                            "Get quick responses".tr(),
                            included: true,
                            alwaysIncluded: true,
                            duration: "Lifetime"),
                        _buildFeatureItem(
                            "Reports".tr(),
                            "Access detailed analytics".tr(),
                            included: true,
                            alwaysIncluded: true,
                            duration: "Lifetime"),
                        _buildFeatureItem(
                            "Cloud Sync".tr(),
                            "Access your data anywhere".tr(),
                            included: true,
                            alwaysIncluded: true,
                            duration: "6 months"),
                        _buildFeatureItem(
                            "Multi-User Access".tr(),
                            "Add multiple users".tr(),
                            included: true,
                            alwaysIncluded: true,
                            duration: "6 months"),
                        _buildFeatureItem(
                            "Role-Based Permissions".tr(),
                            "Control access levels".tr(),
                            included: true,
                            alwaysIncluded: true,
                            duration: "6 months"),

                        _buildFeatureItem(
                            "Other Features".tr(),
                            "All other features are completely free".tr(),
                            included: true,
                            alwaysIncluded: true,
                            duration: "Lifetime"),

                      ],
                    ),
                  ),

                  /// Plan Selection (Horizontal)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [

                        /*_buildPlanOption(
                          title: "Ads Removal".tr(),
                          price: _products.isNotEmpty ? _products[0].price : "Loading...",
                          duration: "Lifetime",
                          selected: selectedPlan == 0,
                          onTap: () => setState(() => selectedPlan = 0),
                        ),*/

                        /*const SizedBox(width: 8),
                        _buildPlanOption(
                          title: "Premium".tr(),
                          price: _products.isNotEmpty ? "${_products[0].price}" : "Loading...",
                          duration: "6 months",
                          selected: selectedPlan == 0,
                          onTap: () => setState(() => selectedPlan = 0),
                        ),*/
                      ],
                    ),
                  ),

                  /// Purchase Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00C853), Color(0xFF2196F3)], // Green to Blue
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28), // More round
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0, // Remove default elevation (handled by boxShadow)
                            backgroundColor: Colors.transparent, // Use gradient instead
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: () {
                            final product = _products.firstWhere((p) => p.id == premiumPoultry);
                            final purchaseParam = PurchaseParam(productDetails: product);
                            InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);

                            Navigator.pop(context);
                          },
                          child: Text(
                            "Upgrade ".tr()+"(${_products[0].price})",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Feature Row with check or cross + duration display
  Widget _buildFeatureItem(
      String title,
      String subtitle, {
        bool included = false,
        bool alwaysIncluded = false,
        String? duration, // <-- New optional parameter
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            included || alwaysIncluded ? Icons.check_circle : Icons.cancel,
            color: duration?.toLowerCase() == "lifetime" ? Colors.green :  Colors.green,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 10,),
                    if (duration != null) // Show duration if provided
                      Text(
                        "($duration)",
                        style:  TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: duration.toLowerCase() == "lifetime" ? Colors.green :  Colors.orange,),
                      ),
                  ],
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Horizontal Plan Option Card
  Widget _buildPlanOption(
      {required String title,
        required String price,
        required String duration,
        required bool selected,
        required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? Colors.blue : Colors.grey.shade300, width: 2),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: selected?  Colors.blue: Colors.grey),

              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                      selected ? FontWeight.bold : FontWeight.w500)),
              const SizedBox(height: 4),
              Text(price,
                  style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.blue : Colors.grey.shade700)),
              Text(duration,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.blue : Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }

  void showOfflineModeDialog(BuildContext context, void Function(bool dontShowAgain) onContinue) {
    bool dontShowAgain = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 50, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                "offline_mode_title".tr(), // "Offline Mode"
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "offline_mode_description".tr(), // Full message
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: dontShowAgain,
                    onChanged: (value) {
                      setState(() {
                        dontShowAgain = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text("dont_show_again".tr()), // "Don't show again"
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.arrow_forward_rounded),
                label: Text("continue_offline".tr()), // "Continue Offline"
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  Utils.isShowAdd = false;
                  Utils.isMultiUSer = false;
                  onContinue(dontShowAgain);
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  bool isAutoFeedEnabled = prefs.getBool('isAutoFeedEnabled') ?? false;

                  if(isAutoFeedEnabled){
                    Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (_) =>
                          AutoFeedSyncScreen(),)
                      , (route) => false,);
                  }else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => HomeScreen()),
                    );
                  }
                   // Pass checkbox state
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


}
