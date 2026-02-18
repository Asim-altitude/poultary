import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:poultary/model/flock_detail.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/ui/flock_ui_list.dart';
import 'package:poultary/utils/utils.dart';
import 'database/databse_helper.dart';
import 'model/flock.dart';
import 'model/sub_category_item.dart';
import 'multiuser/model/birds_modification.dart';
import 'multiuser/model/financeItem.dart';
import 'multiuser/utils/FirebaseUtils.dart';
import 'multiuser/utils/SyncStatus.dart';

class NewBirdsCollection extends StatefulWidget {

  bool isCollection;
  Flock_Detail? flock_detail;
  String? reason;
  NewBirdsCollection({Key? key, required this.isCollection, this.flock_detail, this.reason}) : super(key: key);

  @override
  _NewBirdsCollection createState() => _NewBirdsCollection(this.isCollection);
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _NewBirdsCollection extends State<NewBirdsCollection>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;

   bool isCollection;
  _NewBirdsCollection(this.isCollection);

  late NativeAd _myNativeAd;
  bool _isNativeAdLoaded = false;
  @override
  void dispose() {
    super.dispose();
    try{
      _myNativeAd.dispose();
    }catch(ex){

    }
  }

  String _purposeselectedValue = "";
  String _reductionReasonValue = "";
  String _acqusitionselectedValue = "";

  List<String> _purposeList = [];
  List<String> _reductionReasons = [
    'SOLD','PERSONAL_USE','MORTALITY','CULLING','LOST','OTHER'];

  List<String> acqusitionList = [
    'PURCHASED',
    'HATCHED',
    'GIFT',
    'OTHER',
  ];
  int chosen_index = 0;

  int active_bird_count = 0;

  String max_hint = "";
  bool isEdit = false, is_transaction = false;

  void isTransaction(){

    if(isCollection){
      for(int i=0;i<acqusitionList.length;i++){
        if(_acqusitionselectedValue == acqusitionList[i]){
          if(i == 0){
            is_transaction = true;
          }else{
            is_transaction = false;
          }
        }
      }
    }else{
      for(int i=0;i<_reductionReasons.length;i++){
        if(_reductionReasonValue == _reductionReasons[i]){
          if(i == 0){
            is_transaction = true;
          }else{
            is_transaction = false;
          }
        }
      }
    }


    setState(() {

    });

  }

  TransactionItem? transactionItem = null;
  @override
  void initState() {
    super.initState();

    if(widget.flock_detail != null)
    {
      isEdit = true;
      notesController.text = widget.flock_detail!.short_note;
      totalBirdsController.text = "${widget.flock_detail?.item_count}";
      date = widget.flock_detail!.acqusition_date;
      _acqusitionselectedValue = widget.flock_detail!.acqusition_type;
      _reductionReasonValue = widget.flock_detail!.reason;
      _purposeselectedValue = widget.flock_detail!.f_name;

      _reductionReasons = [_reductionReasonValue];
      acqusitionList = [_acqusitionselectedValue];


    }else{
      _reductionReasonValue = widget.reason == null? _reductionReasons[1] : widget.reason!;
      _acqusitionselectedValue = acqusitionList[1];
      totalBirdsController.text = "5";
    }

    getList();
    Utils.showInterstitial();
    if(Utils.isShowAdd){
      _loadNativeAds();
    }
    AnalyticsUtil.logScreenView(screenName: "add_birds");
  }
  _loadNativeAds(){
    _myNativeAd = NativeAd(
      adUnitId: Utils.NativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small, // or medium
        mainBackgroundColor: Colors.white,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.blue,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) => setState(() => _isNativeAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Native ad failed: $error');
        },
      ),
    );


    _myNativeAd.load();

  }

  List<SubItem> _paymentMethodList = [];
  List<String>  _visiblePaymentMethodList = [];
  int activeStep = 0;

  List<Flock> flocks = [];
  void getList() async {

    _paymentMethodList = await DatabaseHelper.getSubCategoryList(5);

    if(_paymentMethodList.length > 0) {
      for (int i = 0; i < _paymentMethodList.length; i++) {
        _visiblePaymentMethodList.add(_paymentMethodList
            .elementAt(i)
            .name!);
      }
    }else{
      _visiblePaymentMethodList.add("Cash");
    }

    payment_method = _visiblePaymentMethodList[0];

    if(isEdit){

      if(widget.flock_detail != null){
        if(widget.flock_detail!.transaction_id != "-1") {
          transactionItem = await DatabaseHelper.
          getSingleTransaction(widget.flock_detail!.transaction_id);

          if (transactionItem != null) {
            is_transaction = true;
            amountController.text = transactionItem!.amount;
            personController.text = transactionItem!.sold_purchased_from;
            payment_method = transactionItem!.payment_method;
            payment_status = transactionItem!.payment_status;

          }

        }
        else{

        }

        print("loading single flock");
        Flock? singleflock = await DatabaseHelper.getSingleFlock(widget.flock_detail!.f_id);
        print(singleflock);
        print("adding flock");
        flocks.add(singleflock!);
       // flocks.add(Flock(f_id: widget.flock_detail!.f_id,f_name: widget.flock_detail!.f_name, bird_count: singleflock!.bird_count,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: singleflock.active_bird_count, active: 1, flock_new: singleflock.flock_new));
        print(flocks);
        _purposeList.add(flocks.elementAt(0).f_name);

      }
    }else{
      DateTime dateTime = DateTime.now();
      date = DateFormat('yyyy-MM-dd').format(dateTime);
      await DatabaseHelper.instance.database;

      flocks = await DatabaseHelper.getFlocks();
      // flocks.insert(0,Flock(f_id: -1,f_name: 'Farm Wide'.tr(),bird_count: 0,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: 0, active: 1));
      for(int i=0;i<flocks.length;i++){
        print("BIRDS FLOCKS ${flocks.elementAt(i).toJson()}");
        _purposeList.add(flocks.elementAt(i).f_name);
      }

      _purposeselectedValue = Utils.selected_flock!.f_name;//Utils.SELECTED_FLOCK;
      if(_purposeselectedValue == "Farm Wide")
        _purposeselectedValue = _purposeList[0];
      payment_method = _visiblePaymentMethodList[0];

    }

    setState(()
    { });

  }

  Flock? currentFlock = null;
  bool _validate = false;
  String date = "Choose date";
  final nameController = TextEditingController();
  final totalBirdsController = TextEditingController();
  final notesController = TextEditingController();
  final amountController = TextEditingController();
  final personController = TextEditingController();
  bool imagesAdded = false;
  int good_eggs = 0;
  int bad_eggs = 0;

  Widget _buildStepper() {
    return  Container(
      color: Utils.getThemeColorBlue(),
      child: EasyStepper(
        activeStep: activeStep,
        activeStepTextColor: Colors.white,
        finishedStepTextColor: Colors.white30,
        internalPadding: 20, // Reduce padding for better spacing
        stepShape: StepShape.circle,
        stepBorderRadius: 20,
        borderThickness: 3, // Balanced progress line thickness
        showLoadingAnimation: false,
        stepRadius: 15, // Reduced step size to fit screen
        showStepBorder: false,
        lineStyle: LineStyle(
          lineLength: 50,
          lineType: LineType.normal,
          defaultLineColor: Colors.grey.shade300,
          activeLineColor: Colors.blueAccent,
          finishedLineColor: Utils.getThemeColorBlue(),
        ),
        steps: [
          EasyStep(
            customStep: _buildStepIcon(Icons.add_box_rounded, 0),
            title: 'BIRDS'.tr(),
          ),
          EasyStep(
            customStep: _buildStepIcon(Icons.date_range, 1),
            title: 'DATE'.tr(),
          ),

        ],
        onStepReached: (index) => setState(() => activeStep = index),
      ),
    );
  }


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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: AppBar(
          backgroundColor: Utils.getThemeColorBlue(),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (activeStep > 0) {
                setState(() => activeStep--);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          automaticallyImplyLeading: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(30),
            child: _buildStepper(),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
           child: Container(
            margin: EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous Button (Only if activeStep > 0)
                if (activeStep > 0)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          activeStep--;
                        });
                      },
                      child: Container(
                        height: 55,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(30), // Rounded design
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        margin: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22), // Left arrow
                            SizedBox(width: 8),
                            Text(
                              "Previous".tr(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Next or Confirm Button
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      activeStep++;
                      if(activeStep==1){

                        if(is_transaction) {
                          if (totalBirdsController.text.isEmpty
                              || amountController.text.isEmpty
                              || personController.text.isEmpty
                              || int.parse(totalBirdsController.text) == 0
                          ) {
                            activeStep--;
                            Utils.showToast("PROVIDE_ALL");
                          }
                        }else{
                          if (totalBirdsController.text.isEmpty
                              || int.parse(totalBirdsController.text) == 0) {
                            activeStep--;
                            Utils.showToast("PROVIDE_ALL");
                          }
                        }

                      }

                      if(activeStep == 2) {
                        bool validate = checkValidation();

                        if (validate) {
                          print("Everything Okay");
                          await DatabaseHelper.instance.database;

                          if (isCollection)
                          {
                            if (isEdit)
                            {

                              int? transaction_id = await createTransaction();

                              int active_birds = getFlockActiveBirds();
                              active_birds = active_birds -
                                  widget.flock_detail!.item_count;
                              active_birds = active_birds +
                                  int.parse(totalBirdsController.text);
                              print(active_birds);

                              DatabaseHelper.updateFlockBirds(
                                  active_birds, getFlockID());


                              widget.flock_detail?.item_count =
                                  int.parse(totalBirdsController.text);
                              widget.flock_detail?.acqusition_type =
                                  _acqusitionselectedValue;
                              widget.flock_detail?.acqusition_date =
                                  date;
                              widget.flock_detail?.short_note =
                                  notesController.text;
                              widget.flock_detail?.f_id = getFlockID();
                              widget.flock_detail?.sync_status = SyncStatus.UPDATED;
                              widget.flock_detail?.modified_by = Utils.isMultiUSer? Utils.currentUser!.email : '';
                              widget.flock_detail?.last_modified = Utils.getTimeStamp();
                              widget.flock_detail?.f_sync_id = getFlockSyncID();

                              await DatabaseHelper.updateFlock(widget.flock_detail);
                              await DatabaseHelper.updateLinkedTransaction(widget.flock_detail!.transaction_id, widget.flock_detail!.f_detail_id.toString());
                              Utils.showToast("SUCCESSFUL");

                              if(Utils.isMultiUSer) {
                                BirdsModification? birdsmodify = null;
                                if(transaction_id != -1) {
                                  TransactionItem? transaction = await DatabaseHelper.getSingleTransaction(transaction_id!.toString());
                                   /*birdsmodify = BirdsModification(
                                      flockDetail: widget.flock_detail!,
                                      transaction: transaction);*/

                                  transaction!.f_sync_id = getFlockSyncID();
                                  transaction.sync_status = SyncStatus.UPDATED;

                                  FinanceItem financeItem = FinanceItem(transaction: transaction);
                                   financeItem.flockDetails = [];
                                   financeItem.flockDetails!.add(widget.flock_detail!);
                                   financeItem.sync_id = transaction.sync_id;
                                   financeItem.sync_status = SyncStatus.UPDATED;
                                   financeItem.last_modified = Utils.getTimeStamp();
                                   financeItem.modified_by =  Utils.isMultiUSer ? Utils.currentUser!.email : '';
                                   financeItem.farm_id = Utils.isMultiUSer ? Utils.currentUser!.farmId : '';

                                   await FireBaseUtils.updateExpenseRecord(financeItem);

                                  /*birdsmodify.farm_id = Utils.currentUser!.farmId;
                                  birdsmodify.modified_by = Utils.currentUser!.email;*/
                                }
                                else{
                                  birdsmodify = BirdsModification(
                                      flockDetail: widget.flock_detail!);
                                  birdsmodify.farm_id = Utils.currentUser!.farmId;
                                  birdsmodify.modified_by = Utils.currentUser!.email;

                                  bool synced = await FireBaseUtils.uploadBirdsDetails(birdsmodify);

                                }

                                 // UPDATE FLOCK
                                Flock? flock = await DatabaseHelper.getSingleFlock(widget.flock_detail!.f_id);
                                flock!.active_bird_count = active_birds;
                                flock.farm_id = Utils.currentUser!.farmId;
                                flock.last_modified = Utils.getTimeStamp();
                                flock.modified_by = Utils.currentUser!.email;
                                FireBaseUtils.updateFlock(flock);

                              }

                              Navigator.pop(context);

                            }
                            else {

                              int? transaction_id = await createTransaction();

                              int active_birds = getFlockActiveBirds();
                              active_birds = active_birds +
                                  int.parse(totalBirdsController.text);
                              print(active_birds);

                              DatabaseHelper.updateFlockBirds(
                                  active_birds, getFlockID());

                              Flock_Detail flock_detail = Flock_Detail(
                                  f_id: getFlockID(),
                                  item_type: isCollection
                                      ? 'Addition'
                                      : 'Reduction',
                                  item_count: int.parse(
                                      totalBirdsController.text),
                                  acqusition_type: _acqusitionselectedValue,
                                  acqusition_date: date,
                                  reason: _reductionReasonValue,
                                  short_note: notesController.text,
                                  f_name: _purposeselectedValue,
                                  transaction_id: transaction_id.toString(),
                                  sync_id: Utils.getUniueId(),
                                  sync_status: SyncStatus.SYNCED,
                                  last_modified: Utils.getTimeStamp(),
                                  modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                                  farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
                                  f_sync_id: getFlockSyncID()
                              );
                              int? flock_detail_id = await DatabaseHelper
                                  .insertFlockDetail(flock_detail);
                              await DatabaseHelper.updateLinkedTransaction(transaction_id.toString(), flock_detail_id.toString());


                              /*if(Utils.isMultiUSer) {
                                BirdsModification? birdsmodify = null;
                                if(transaction_id != "-1") {
                                  print("TRANSACTION");
                                  TransactionItem? transaction = await DatabaseHelper
                                      .getSingleTransaction(
                                      transaction_id!.toString());
                                  birdsmodify = BirdsModification(
                                      flockDetail: flock_detail,
                                      transaction: transaction);

                                  birdsmodify.farm_id = Utils.currentUser!.farmId;
                                  birdsmodify.modified_by = Utils.currentUser!.email;
                                }else{
                                  print("NO TRANSACTION");
                                  birdsmodify = BirdsModification(
                                      flockDetail: flock_detail);

                                  birdsmodify.farm_id = Utils.currentUser!.farmId;
                                  birdsmodify.modified_by = Utils.currentUser!.email;
                                }

                                bool synced = await FireBaseUtils.uploadBirdsDetails(birdsmodify);
                                if(!synced){
                                  //SAVE FOR LATER SYNC
                                }

                                // UPDATE FLOCK
                                Flock? flock = getSelectedFlock();
                                flock!.active_bird_count = active_birds;
                                FireBaseUtils.updateFlock(flock);


                              }
              */
                              if(Utils.isMultiUSer) {
                                BirdsModification? birdsmodify = null;
                                if(transaction_id != -1) {
                                  TransactionItem? transaction = await DatabaseHelper.getSingleTransaction(transaction_id!.toString());
                                  /*birdsmodify = BirdsModification(
                                      flockDetail: widget.flock_detail!,
                                      transaction: transaction);*/

                                  transaction!.f_sync_id = getFlockSyncID();
                                  transaction.sync_status = SyncStatus.SYNCED;
                                  FinanceItem financeItem = FinanceItem(transaction: transaction);
                                  financeItem.flockDetails = [];
                                  financeItem.flockDetails!.add(flock_detail);
                                  financeItem.sync_id = transaction.sync_id;
                                  financeItem.sync_status = SyncStatus.SYNCED;
                                  financeItem.last_modified = Utils.getTimeStamp();
                                  financeItem.modified_by =  Utils.isMultiUSer ? Utils.currentUser!.email : '';
                                  financeItem.farm_id = Utils.isMultiUSer ? Utils.currentUser!.farmId : '';

                                  await FireBaseUtils.uploadExpenseRecord(financeItem);

                                  /*birdsmodify.farm_id = Utils.currentUser!.farmId;
                                  birdsmodify.modified_by = Utils.currentUser!.email;*/
                                }
                                else{
                                  birdsmodify = BirdsModification(
                                      flockDetail: flock_detail);
                                  birdsmodify.farm_id = Utils.currentUser!.farmId;
                                  birdsmodify.modified_by = Utils.currentUser!.email;

                                  bool synced = await FireBaseUtils.uploadBirdsDetails(birdsmodify);

                                }

                                // UPDATE FLOCK
                                Flock? flock = await DatabaseHelper.getSingleFlock(flock_detail.f_id);
                                flock!.active_bird_count = active_birds;
                                flock.farm_id = Utils.currentUser!.farmId;
                                flock.last_modified = Utils.getTimeStamp();
                                flock.modified_by = Utils.currentUser!.email;
                                FireBaseUtils.updateFlock(flock);
                                Utils.showToast("SUCCESSFUL");

                                Navigator.pop(context);

                              } else {
                                Utils.showToast("SUCCESSFUL");

                                Navigator.pop(context);
                              }

                             /* if(Utils.isMultiUSer) {
                                flock_detail.f_detail_id = flock_detail_id;
                                bool synced = await FireBaseUtils.uploadFlockDetails(flock_detail);
                                if(!synced)
                                {
                                  flock_detail.sync_status = SyncStatus.PENDING;
                                  await DatabaseHelper.updateFlock(flock_detail);
                                }
                              }*/

                            }
                          }
                          else {
                            if (isEdit)
                            {

                              int? transaction_id = await createTransaction();

                              int active_birds = getFlockActiveBirds();
                              active_birds = active_birds + widget.flock_detail!.item_count;
                              if (int.parse(totalBirdsController.text) <=
                                  active_birds) {

                                active_birds = active_birds -
                                    int.parse(
                                        totalBirdsController.text);
                                print(active_birds);

                                DatabaseHelper.updateFlockBirds(
                                    active_birds, getFlockID());

                                widget.flock_detail?.item_count =
                                    int.parse(
                                        totalBirdsController.text);
                                widget.flock_detail?.reason =
                                    _reductionReasonValue;
                                widget.flock_detail?.acqusition_date =
                                    date;
                                widget.flock_detail?.short_note =
                                    notesController.text;
                                widget.flock_detail?.f_id =
                                    getFlockID();
                                widget.flock_detail?.sync_status = SyncStatus.UPDATED;
                                widget.flock_detail?.modified_by = Utils.isMultiUSer? Utils.currentUser!.email:'';
                                widget.flock_detail?.last_modified = Utils.getTimeStamp();
                                widget.flock_detail?.f_sync_id = getFlockSyncID();

                                await DatabaseHelper.updateFlock(
                                    widget.flock_detail);
                                await DatabaseHelper.updateLinkedTransaction(widget.flock_detail!.transaction_id, widget.flock_detail!.f_detail_id.toString());

                                Utils.showToast("SUCCESSFUL");

                                if(Utils.isMultiUSer) {
                                  BirdsModification? birdsmodify = null;
                                  if(transaction_id != -1) {
                                    TransactionItem? transaction = await DatabaseHelper.getSingleTransaction(transaction_id!.toString());
                                    /*birdsmodify = BirdsModification(
                                      flockDetail: widget.flock_detail!,
                                      transaction: transaction);*/

                                    transaction!.f_sync_id = getFlockSyncID();
                                    transaction.sync_status = SyncStatus.UPDATED;

                                    FinanceItem financeItem = FinanceItem(transaction: transaction!);
                                    financeItem.flockDetails = [];
                                    financeItem.flockDetails!.add(widget.flock_detail!);
                                    financeItem.sync_id = transaction.sync_id;
                                    financeItem.sync_status = SyncStatus.UPDATED;
                                    financeItem.last_modified = Utils.getTimeStamp();
                                    financeItem.modified_by =  Utils.isMultiUSer ? Utils.currentUser!.email : '';
                                    financeItem.farm_id = Utils.isMultiUSer ? Utils.currentUser!.farmId : '';

                                    await FireBaseUtils.updateExpenseRecord(financeItem);

                                    /*birdsmodify.farm_id = Utils.currentUser!.farmId;
                                  birdsmodify.modified_by = Utils.currentUser!.email;*/
                                  }
                                  else{
                                    birdsmodify = BirdsModification(
                                        flockDetail: widget.flock_detail!);
                                    birdsmodify.farm_id = Utils.currentUser!.farmId;
                                    birdsmodify.modified_by = Utils.currentUser!.email;

                                    bool synced = await FireBaseUtils.uploadBirdsDetails(birdsmodify);

                                  }

                                  // UPDATE FLOCK
                                  Flock? flock = await DatabaseHelper.getSingleFlock(widget.flock_detail!.f_id);
                                  flock!.active_bird_count = active_birds;
                                  flock.farm_id = Utils.currentUser!.farmId;
                                  flock.last_modified = Utils.getTimeStamp();
                                  flock.modified_by = Utils.currentUser!.email;
                                  FireBaseUtils.updateFlock(flock);

                                }
                                /* if(Utils.isMultiUSer) {
                                  bool synced = await FireBaseUtils.uploadFlockDetails(widget.flock_detail!);
                                  if(!synced)
                                  {
                                    widget.flock_detail!.sync_status = SyncStatus.PENDING;
                                    await DatabaseHelper.updateFlock(widget.flock_detail!);
                                  }
                                }*/

                                Navigator.pop(context);
                              }else{
                                activeStep--;
                                max_hint =
                                    "CANNOT_REDUCE".tr() +
                                        "$active_birds";
                                Utils.showToast(max_hint);
                                setState(() {

                                });
                              }
                            }
                            else {

                              int? transaction_id = await createTransaction();

                              int active_birds = getFlockActiveBirds();

                              if (int.parse(totalBirdsController.text) <=
                                  active_birds) {
                                active_birds = active_birds -
                                    int.parse(totalBirdsController.text);
                                print(active_birds);

                                DatabaseHelper.updateFlockBirds(
                                    active_birds, getFlockID());

                                Flock_Detail flock_detail = Flock_Detail(
                                    f_id: getFlockID(),
                                    item_type: isCollection
                                        ? 'Addition'
                                        : 'Reduction',
                                    item_count: int.parse(
                                        totalBirdsController.text),
                                    acqusition_type: _acqusitionselectedValue,
                                    acqusition_date: date,
                                    reason: _reductionReasonValue,
                                    short_note: notesController.text,
                                    f_name: _purposeselectedValue,
                                    transaction_id: transaction_id.toString(),
                                    sync_id: Utils.getUniueId(),
                                    sync_status: SyncStatus.SYNCED,
                                    last_modified: Utils.getTimeStamp(),
                                    modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                                    farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
                                    f_sync_id: getFlockSyncID()
                                );
                                int? flock_detail_id = await DatabaseHelper
                                    .insertFlockDetail(flock_detail);
                                await DatabaseHelper.updateLinkedTransaction(transaction_id.toString(), flock_detail_id.toString());

                                Utils.showToast("SUCCESSFUL");


                                if(Utils.isMultiUSer) {
                                  BirdsModification? birdsmodify = null;
                                  if(transaction_id != -1) {
                                    TransactionItem? transaction = await DatabaseHelper.getSingleTransaction(transaction_id!.toString());
                                    /*birdsmodify = BirdsModification(
                                      flockDetail: widget.flock_detail!,
                                      transaction: transaction);*/
                                    transaction!.f_sync_id = getFlockSyncID();
                                    transaction.sync_status = SyncStatus.SYNCED;

                                    FinanceItem financeItem = FinanceItem(transaction: transaction!);
                                    financeItem.flockDetails = [];
                                    financeItem.flockDetails!.add(flock_detail);
                                    financeItem.sync_id = transaction.sync_id;
                                    financeItem.sync_status = SyncStatus.SYNCED;
                                    financeItem.last_modified = Utils.getTimeStamp();
                                    financeItem.modified_by =  Utils.isMultiUSer ? Utils.currentUser!.email : '';
                                    financeItem.farm_id = Utils.isMultiUSer ? Utils.currentUser!.farmId : '';

                                    await FireBaseUtils.uploadExpenseRecord(financeItem);

                                    /*birdsmodify.farm_id = Utils.currentUser!.farmId;
                                  birdsmodify.modified_by = Utils.currentUser!.email;*/
                                  }
                                  else{
                                    birdsmodify = BirdsModification(
                                        flockDetail: flock_detail);
                                    birdsmodify.farm_id = Utils.currentUser!.farmId;
                                    birdsmodify.modified_by = Utils.currentUser!.email;

                                    bool synced = await FireBaseUtils.uploadBirdsDetails(birdsmodify);

                                  }

                                  // UPDATE FLOCK
                                  Flock? flock = await DatabaseHelper.getSingleFlock(flock_detail.f_id);
                                  flock!.active_bird_count = active_birds;
                                  flock.farm_id = Utils.currentUser!.farmId;
                                  flock.last_modified = Utils.getTimeStamp();
                                  flock.modified_by = Utils.currentUser!.email;
                                  FireBaseUtils.updateFlock(flock);

                                }

                                /* if(Utils.isMultiUSer) {
                                  flock_detail.f_detail_id = flock_detail_id;
                                  bool synced = await FireBaseUtils.uploadFlockDetails(flock_detail);
                                  if(!synced)
                                  {
                                    flock_detail.sync_status = SyncStatus.PENDING;
                                    await DatabaseHelper.updateFlock(flock_detail);
                                  }
                                }*/

                                AnalyticsUtil.logAddBirds(quantity: totalBirdsController.text, event: isCollection? _acqusitionselectedValue : _reductionReasonValue );
                                Navigator.pop(context);
                              } else {
                                activeStep--;
                                max_hint =
                                    "CANNOT_REDUCE".tr() +
                                        "$active_birds";
                                Utils.showToast(max_hint);

                                setState(() {

                                });
                              }
                            }
                          }
                        } else {
                          activeStep--;
                          Utils.showToast("PROVIDE_ALL");
                        }
                      }
                      setState(() {

                      });
                    },
                    child: Container(
                      height: 55,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: activeStep == 1
                              ? [Utils.getThemeColorBlue(), Colors.greenAccent] // Confirm Button
                              : [Utils.getThemeColorBlue(), Colors.blueAccent], // Next Button
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            activeStep == 1 ? "CONFIRM".tr() : "NEXT".tr(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 22), // Right arrow
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      body: SafeArea(
        top: false,
        child: Container(
          width: widthScreen,
          height: heightScreen,
          color: Colors.white,
          child: Column(children: [
            if (_isNativeAdLoaded && _myNativeAd != null)
              Container(
                height: 90,
                margin: const EdgeInsets.only(bottom: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AdWidget(ad: _myNativeAd),
              ),

            Expanded(child: SingleChildScrollView(
              child: Column(
                children: [
                 // SizedBox(height: 10,),

                  Container(
                    // height: !is_transaction ? heightScreen-250 : heightScreen - 134,
                    child: Column(
                        children: [

                          activeStep == 0?   Container(
                           // margin: EdgeInsets.only(left: 15,right: 15,bottom: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                           /*   borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: Offset(0, 5),
                                ),
                              ],*/
                            ),
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 20),
                                Center(
                                  child: Container(
                                    child: Text(
                                      isCollection? isEdit? "EDIT".tr() +" "+ 'Addition'.tr() : 'ADD_BIRDS'.tr() :isEdit? "EDIT".tr() +" "+ "Reduction".tr() :'REDUCE_BIRDS'.tr(),
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          color: Utils.getThemeColorBlue(),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                // Choose Flock
                                _buildSectionLabel("CHOOSE_FLOCK_1".tr()),
                                /*_buildDropdownField("CHOOSE_FLOCK_1".tr(),_purposeList,_purposeselectedValue, (value) {
                                  _purposeselectedValue = value!;
                                }),*/
                                FlockHorizontalList(
                                  flocks: flocks,
                                  selectedFlockId: _purposeselectedValue,
                                  onSelect: (flock) {
                                    setState(() {
                                      _purposeselectedValue = flock.f_name;
                                    });
                                  },
                                ),

                                SizedBox(height: 15),

                                // Reductions or Acquisitions (Based on isCollection)
                                if (!isCollection) ...[
                                  _buildSectionLabel("REDUCTIONS_1".tr()),
                                  _buildDropdownField("REDUCTIONS_1".tr(), _reductionReasons, _reductionReasonValue, (value) {
                                    setState(() {
                                      _reductionReasonValue = value!;
                                      is_transaction = (_reductionReasonValue == "SOLD");
                                    });
                                  }),
                                ] else ...[
                                  /*  _buildSectionLabel("ACQUSITION".tr()),
                                _buildHorizontalList(acqusitionList, "ACQUSITION".tr(),  (value) {
                                  setState(() {
                                    _acqusitionselectedValue = value;
                                    is_transaction = (_acqusitionselectedValue == "PURCHASED"); // Enable when PURCHASED is selected

                                  });
                                },),*/
                                  _buildSectionLabel("ACQUSITION".tr()),
                                  _buildDropdownField("ACQUSITION".tr(),acqusitionList, _acqusitionselectedValue, (value) {
                                    setState(() {
                                      _acqusitionselectedValue = value!;
                                      is_transaction = (_acqusitionselectedValue == "PURCHASED"); // Enable when PURCHASED is selected

                                    });
                                  }),
                                ],



                                // Auto Transaction Label
                                if (is_transaction && !isEdit)
                                  Center(
                                    child: Text(
                                      isCollection ? 'Auto_expense'.tr() : 'Auto_Income'.tr(),
                                      style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                SizedBox(height: 15),
                                // Birds Count & Sale/Expense Amount
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildSectionLabel("BIRDS_COUNT".tr()),
                                          _buildInputField("BIRDS_COUNT".tr(), totalBirdsController, Icons.numbers, keyboardType: TextInputType.number, inputFormat: "number"),
                                        ],
                                      ),
                                    ),
                                    if (is_transaction)
                                      SizedBox(width: 10),
                                    if (is_transaction)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildSectionLabel(!isCollection ? "SALE_AMOUNT".tr() : "EXPENSE_AMOUNT".tr()),
                                            _buildInputField(!isCollection ? "SALE_AMOUNT".tr() : "EXPENSE_AMOUNT".tr(), amountController, keyboardType: TextInputType.number, Icons.attach_money,inputFormat: "float"),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),

                                SizedBox(height: 15),

                                // Paid To / Sold To Field
                                if (is_transaction)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionLabel(isCollection ? "PAID_TO1".tr() : "SOLD_TO".tr()),
                                      _buildInputField(isCollection ? "PAID_TO_HINT".tr() : "SOLD_TO_HINT".tr(), personController, Icons.person),
                                    ],
                                  ),
                              ],
                            ),) : SizedBox(width: 1,),
                          activeStep == 1?
                          Container(
                           // margin: EdgeInsets.only(left: 15,right: 15,bottom: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                             /* borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: Offset(0, 5),
                                ),
                              ],*/
                            ),
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 10),
                                Center(
                                  child: Container(
                                    child: Text(
                                      isCollection? isEdit? "EDIT".tr() +" "+ 'Addition'.tr() : 'ADD_BIRDS'.tr() :isEdit? "EDIT".tr() +" "+ "Reduction".tr() :'REDUCE_BIRDS'.tr(),
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          color: Utils.getThemeColorBlue(),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                // Max Hint Warning
                                if (max_hint.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(left: 5, bottom: 10),
                                    child: Text(
                                      max_hint,
                                      style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ),

                                // Payment Method & Payment Status (Only if is_transaction is true)
                                if (is_transaction) ...[
                                  SizedBox(height: 15),
                                  _buildSectionLabel("Payment Method".tr()),
                                  _buildDropdownField("Payment Method".tr(),_visiblePaymentMethodList, payment_method, (value) {
                                    setState(() {
                                      payment_method = value!;
                                    });
                                  }),

                                  SizedBox(height: 15),
                                  _buildSectionLabel("Payment Status".tr()),
                                  _buildDropdownField("Payment Status".tr(),paymentStatusList, payment_status,(value) {
                                    setState(() {
                                      payment_status = value!;
                                    });
                                  }),
                                ],

                                SizedBox(height: 15),

                                // Date Picker
                                _buildSectionLabel("DATE".tr()),
                                GestureDetector(
                                  onTap: () {
                                    pickDate();
                                  },
                                  child: _buildDatePicker(Utils.getFormattedDate(date)),
                                ),

                                SizedBox(height: 15),

                                // Description Input
                                _buildSectionLabel("DESCRIPTION_1".tr()),
                                _buildInputField("NOTES_HINT".tr(), notesController, Icons.notes, keyboardType: TextInputType.multiline, height: 100),
                              ],
                            ),
                          ) : SizedBox(width: 1,),
                          SizedBox(height: 10,width: widthScreen),
                          /*InkWell(
                          onTap: () async {

                            activeStep++;
                            if(activeStep==1){

                             if(is_transaction) {
                               if (totalBirdsController.text.isEmpty
                                   || amountController.text.isEmpty
                                   || personController.text.isEmpty
                                   || int.parse(totalBirdsController.text) == 0
                               ) {
                                 activeStep--;
                                 Utils.showToast("PROVIDE_ALL".tr());
                               }
                             }else{
                               if (totalBirdsController.text.isEmpty
                               || int.parse(totalBirdsController.text) == 0) {
                                 activeStep--;
                                 Utils.showToast("PROVIDE_ALL".tr());
                               }
                             }

                            }

                            if(activeStep == 2) {
                              bool validate = checkValidation();

                              if (validate) {
                                print("Everything Okay");
                                await DatabaseHelper.instance.database;

                                if (isCollection) {
                                  if (isEdit) {

                                    int? transaction_id = await createTransaction();

                                    int active_birds = getFlockActiveBirds();
                                    active_birds = active_birds -
                                        widget.flock_detail!.item_count;
                                    active_birds = active_birds +
                                        int.parse(totalBirdsController.text);
                                    print(active_birds);

                                    DatabaseHelper.updateFlockBirds(
                                        active_birds, getFlockID());

                                    widget.flock_detail?.item_count =
                                        int.parse(totalBirdsController.text);
                                    widget.flock_detail?.acqusition_type =
                                        _acqusitionselectedValue;
                                    widget.flock_detail?.acqusition_date =
                                        date;
                                    widget.flock_detail?.short_note =
                                        notesController.text;
                                    widget.flock_detail?.f_id = getFlockID();

                                    await DatabaseHelper.updateFlock(widget.flock_detail);
                                    await DatabaseHelper.updateLinkedTransaction(widget.flock_detail!.transaction_id, widget.flock_detail!.f_detail_id.toString());
                                    Utils.showToast("SUCCESSFUL".tr());
                                    Navigator.pop(context);
                                  }
                                  else {

                                    int? transaction_id = await createTransaction();

                                    int active_birds = getFlockActiveBirds();
                                    active_birds = active_birds +
                                        int.parse(totalBirdsController.text);
                                    print(active_birds);

                                    DatabaseHelper.updateFlockBirds(
                                        active_birds, getFlockID());

                                    int? flock_detail_id = await DatabaseHelper
                                        .insertFlockDetail(Flock_Detail(
                                        f_id: getFlockID(),
                                        item_type: isCollection
                                            ? 'Addition'
                                            : 'Reduction',
                                        item_count: int.parse(
                                            totalBirdsController.text),
                                        acqusition_type: _acqusitionselectedValue,
                                        acqusition_date: date,
                                        reason: _reductionReasonValue,
                                        short_note: notesController.text,
                                        f_name: _purposeselectedValue,
                                        transaction_id: transaction_id.toString()

                                    ));
                                    await DatabaseHelper.updateLinkedTransaction(transaction_id.toString(), flock_detail_id.toString());
                                    Utils.showToast("SUCCESSFUL".tr());

                                    Navigator.pop(context);
                                  }
                                } else {
                                  if (isEdit) {

                                    int? transaction_id = await createTransaction();

                                    int active_birds = getFlockActiveBirds();
                                    active_birds = active_birds + widget.flock_detail!.item_count;
                                    if (int.parse(totalBirdsController.text) <
                                        active_birds) {

                                      active_birds = active_birds -
                                          int.parse(
                                              totalBirdsController.text);
                                      print(active_birds);

                                      DatabaseHelper.updateFlockBirds(
                                          active_birds, getFlockID());

                                      widget.flock_detail?.item_count =
                                          int.parse(
                                              totalBirdsController.text);
                                      widget.flock_detail?.reason =
                                          _reductionReasonValue;
                                      widget.flock_detail?.acqusition_date =
                                          date;
                                      widget.flock_detail?.short_note =
                                          notesController.text;
                                      widget.flock_detail?.f_id =
                                          getFlockID();

                                      await DatabaseHelper.updateFlock(
                                          widget.flock_detail);
                                      await DatabaseHelper.updateLinkedTransaction(widget.flock_detail!.transaction_id, widget.flock_detail!.f_detail_id.toString());

                                      Utils.showToast("SUCCESSFUL".tr());
                                      Navigator.pop(context);
                                    }else{
                                      activeStep--;
                                      max_hint =
                                          "CANNOT_REDUCE".tr() +
                                              "$active_birds";
                                      Utils.showToast(max_hint);
                                      setState(() {

                                      });
                                    }
                                  } else {

                                    int? transaction_id = await createTransaction();

                                    int active_birds = getFlockActiveBirds();

                                    if (int.parse(totalBirdsController.text) <
                                        active_birds) {
                                      active_birds = active_birds -
                                          int.parse(
                                              totalBirdsController.text);
                                      print(active_birds);

                                      DatabaseHelper.updateFlockBirds(
                                          active_birds, getFlockID());

                                      int? flock_detail_id = await DatabaseHelper
                                          .insertFlockDetail(Flock_Detail(
                                          f_id: getFlockID(),
                                          item_type: isCollection
                                              ? 'Addition'
                                              : 'Reduction',
                                          item_count: int.parse(
                                              totalBirdsController.text),
                                          acqusition_type: _acqusitionselectedValue,
                                          acqusition_date: date,
                                          reason: _reductionReasonValue,
                                          short_note: notesController.text,
                                          f_name: _purposeselectedValue,
                                          transaction_id: transaction_id.toString()

                                      ));
                                      await DatabaseHelper.updateLinkedTransaction(transaction_id.toString(), flock_detail_id.toString());

                                      Utils.showToast("SUCCESSFUL".tr());
                                      Navigator.pop(context);
                                    } else {
                                      activeStep--;
                                      max_hint =
                                          "CANNOT_REDUCE".tr() +
                                              "$active_birds";
                                      Utils.showToast(max_hint);

                                      setState(() {

                                      });
                                    }
                                  }
                                }
                              } else {
                                activeStep--;
                                Utils.showToast("PROVIDE_ALL".tr());
                              }
                            }
                            setState(() {

                            });

                          },
                          child: Container(
                            width: widthScreen,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Utils.getThemeColorBlue(),
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0)),
                              border: Border.all(
                                color:  Utils.getThemeColorBlue(),
                                width: 2.0,
                              ),
                            ),
                            margin: EdgeInsets.all( 20),
                            child: Text(
                              activeStep==0?"NEXT".tr():"CONFIRM".tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        )*/

                        ]),
                  ),
                ],
              ),
            ))
          ],),
        ),
      ),
    );
  }

  Widget _buildStepIcon(IconData icon, int step) {
    bool isActive = activeStep == step; // Current step
    bool isFinished = activeStep > step; // Completed steps

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFinished
            ? Utils.getThemeColorBlue() // Completed step
            : isActive
            ? Utils.getThemeColorBlue() // Current step
            : Colors.grey.shade400, // Upcoming step
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            spreadRadius: 1,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isFinished ? Icons.check : icon, // ✅ Show tick if step is done
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }


  Widget _buildHorizontalList(
      List<String> items,
      String selectedValue,
      Function(String) onSelected, {
        List<IconData>? icons, // Optional icons for items
      }) {
    return Container(
      height: 55,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedValue == items[index];
          return GestureDetector(
            onTap: () {
              onSelected(items[index]);
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300), // Smooth transition
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              margin: EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : LinearGradient(
                  colors: [Colors.grey.shade200, Colors.grey.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  )
                ]
                    : [],
                border: Border.all(
                  color: isSelected ? Colors.blue.shade800 : Colors.grey.shade400,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icons != null) ...[
                    Icon(
                      icons[index],
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                  ],
                  Text(
                    items[index].tr(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5, left: 5),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDatePicker(String dateText) {
    return Container(
      width: double.infinity,
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),

      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(dateText, style: TextStyle(color: Colors.black, fontSize: 16)),
          Icon(Icons.calendar_today, color: Colors.blue.shade700, size: 22),
        ],
      ),
    );
  }


  Widget _buildInputField(
      String label,
      TextEditingController controller,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
        double width = double.infinity,
        double height = 70,
        String? inputFormat, // Optional input format (numbers, float, or default)
      }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300, width: 1.5), // Matches dropdown border
      ),
      child: Row(
        children: [
          // Icon Box (Consistent with Dropdown Style)

          // Text Field
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: _getInputFormatters(inputFormat),
              style: TextStyle(fontSize: 17, color: Colors.black),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                hintText: label,
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                border: InputBorder.none, // Remove inner border
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextInputFormatter> _getInputFormatters(String? formatType) {
    if (formatType == "number") {
      return [FilteringTextInputFormatter.allow(RegExp(r"^[0-9]*$"))]; // Only integers
    } else if (formatType == "float") {
      return [FilteringTextInputFormatter.allow(RegExp(r"^[0-9]*\.?[0-9]*$"))]; // Allows decimals
    }
    return []; // Default: No restrictions
  }


// Custom Dropdown Field (Matches Input Field)
  Widget _buildDropdownField(
      String label,
      List<String> items,
      String selectedValue,
      Function(String?) onChanged, {
        double width = double.infinity,
        double height = 75,
      }) {
    return Container(
      width: width,
      height: height, // Matches input field
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300, width: 1.5), // Same border as input field

      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          icon: Padding(
            padding: EdgeInsets.only(right: 15),
            child: Icon(Icons.arrow_drop_down_circle, color: Colors.blue, size: 28),
          ),
          isExpanded: true,
          style: TextStyle(fontSize: 16, color: Colors.black),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: Text(value.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }


  Widget getDropDownList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _purposeselectedValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState((){
            _purposeselectedValue = newValue!;

          });
        },
        items: _purposeList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value.tr(),
              textAlign: TextAlign.right,
              style: new TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget getReductionList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _reductionReasonValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _reductionReasonValue = newValue!;
            if(!isEdit)
            isTransaction();
          });
        },
        items: _reductionReasons.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value.tr(),
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget getAcqusitionList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _acqusitionselectedValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            _acqusitionselectedValue = newValue!;
            if(!isEdit)
            isTransaction();
          });
        },
        items: acqusitionList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value.tr(),
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void pickDate() async{

     DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime.now());

    if (pickedDate != null) {
      print(
          pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate =
      DateFormat('yyyy-MM-dd').format(pickedDate);
      print(
          formattedDate); //formatted date output using intl package =>  2021-03-16
      setState(() {
        date =
            formattedDate; //set output date to TextField value.
      });
    } else {}
  }

  bool checkValidation() {
    bool valid = true;

    if(date.toLowerCase().contains("Choose date".tr()) ||
        date.toLowerCase().contains("Choose date")){
      valid = false;
      print("Select Date");
    }


    if(isCollection) {
      if (_acqusitionselectedValue.contains("ACQUSITION_TYPE".tr()) ||
          _acqusitionselectedValue.contains("ACQUSITION_TYPE")) {
        valid = false;
        print("Select Acqusition Type");
      }
    }

    if(!isCollection) {
      if (_reductionReasonValue.contains("REDUCTION_REASON".tr()) ||
          _reductionReasonValue.contains("REDUCTION_REASON")) {
        valid = false;
        print("Select Reduction reason");
      }
    }

    if(totalBirdsController.text.length <=0){
      valid = false;
      print("add birds count");
    }


    return valid;

  }
  String payment_method = "Cash";
  String payment_status = "CLEARED";
  Widget getPaymentMethodList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ""),
        isDense: true,
        value: payment_method,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            payment_method = newValue!;

          });
        },
        items: _visiblePaymentMethodList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value.tr(),
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<String> paymentStatusList = ['CLEARED','UNCLEAR','RECONCILED'];

  Widget getPaymentStatusList() {
    return Container(
      width: widthScreen,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: payment_status,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
            payment_status = newValue!;

          });
        },
        items: paymentStatusList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value.tr(),
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Flock? getSelectedFlock() {

    Flock? flock = null;
    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue.toLowerCase() == flocks.elementAt(i).f_name.toLowerCase()){
        flock = flocks.elementAt(i);
        break;
      }
    }

    return flock;
  }

  int getFlockID() {

    int selected_id = -1;
    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue.toLowerCase() == flocks.elementAt(i).f_name.toLowerCase()){
        selected_id = flocks.elementAt(i).f_id;
        break;
      }
    }

    return selected_id;
  }

  String? getFlockSyncID() {

    String? selected_id = "unknown";
    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue.toLowerCase() == flocks.elementAt(i).f_name.toLowerCase()){
        selected_id = flocks.elementAt(i).sync_id;
        break;
      }
    }

    print("FLOCK_SELECTED $selected_id");
    return selected_id;
  }

  int getFlockActiveBirds() {

    int? selected_id = -1;
    for(int i=0;i<flocks.length;i++){
      if(_purposeselectedValue.toLowerCase() == flocks.elementAt(i).f_name.toLowerCase()){
        selected_id = flocks.elementAt(i).active_bird_count;
        break;
      }
    }

    return selected_id!;
  }

  Future<int?> createTransaction() async {

    if(is_transaction){
      if(isCollection) {
        if (isEdit) {
          await DatabaseHelper.instance.database;
          TransactionItem transaction_item = TransactionItem(
              flock_update_id: widget.flock_detail!.f_detail_id.toString(),
              f_id: getFlockID(),
              date: date,
              sale_item: "",
              expense_item: "Bird Purchase",
              type: "Expense",
              amount: amountController.text,
              payment_method: payment_method,
              payment_status: payment_status,
              sold_purchased_from: personController.text,
              short_note: notesController.text,
              how_many: totalBirdsController.text,
              extra_cost: "",
              extra_cost_details: "",
              f_name: _purposeselectedValue,
              sync_id: transactionItem!.sync_id,
              sync_status: SyncStatus.UPDATED,
              last_modified: Utils.getTimeStamp(),
              modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
              farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
              f_sync_id: getFlockSyncID()
          );
          transaction_item.id =
              transactionItem!.id;
          int? id = await DatabaseHelper
              .updateTransaction(transaction_item);

          /*if(Utils.isMultiUSer) {
            bool synced = await FireBaseUtils.uploadTransactions(
                transaction_item);
            if (!synced) {
              transaction_item!.sync_status = SyncStatus.PENDING;
              await DatabaseHelper.updateTransaction(transaction_item!);
            }
          }*/

          return transactionItem!.id;
        }
        else {
          await DatabaseHelper.instance.database;
          TransactionItem transaction_item = TransactionItem(
              flock_update_id: "-1",
              f_id: getFlockID(),
              date: date,
              sale_item: "",
              expense_item: "Bird Purchase",
              type: "Expense",
              amount: amountController.text,
              payment_method: payment_method,
              payment_status: payment_status,
              sold_purchased_from: personController
                  .text,
              short_note: notesController.text,
              how_many: totalBirdsController.text,
              extra_cost: "",
              extra_cost_details: "",
              f_name: _purposeselectedValue,
              sync_id: Utils.getUniueId(),
              sync_status: SyncStatus.SYNCED,
              last_modified: Utils.getTimeStamp(),
              modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
              farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
              f_sync_id: getFlockSyncID()
          );
          int? id = await DatabaseHelper
              .insertNewTransaction(transaction_item);

          /*if(Utils.isMultiUSer) {
            bool synced = await FireBaseUtils.uploadTransactions(
                transaction_item);
            if (!synced) {
              transaction_item!.sync_status = SyncStatus.PENDING;
              await DatabaseHelper.updateTransaction(transaction_item!);
            }
          }*/
          return id;
        }
      }
      else{
        if(isEdit){
          await DatabaseHelper.instance.database;
          TransactionItem transaction_item = TransactionItem(
              flock_update_id: widget.flock_detail!.f_detail_id.toString(),
              f_id: getFlockID(),
              date: date,
              sale_item: "Bird Sale",
              expense_item: "",
              type: "Income",
              amount: amountController.text,
              payment_method: payment_method,
              payment_status: payment_status,
              sold_purchased_from: personController
                  .text,
              short_note: notesController.text,
              how_many: totalBirdsController.text,
              extra_cost: "",
              extra_cost_details: "",
              f_name: _purposeselectedValue,
              sync_id: transactionItem!.sync_id,
              sync_status: SyncStatus.UPDATED,
              last_modified: Utils.getTimeStamp(),
              modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
              farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
              f_sync_id: getFlockSyncID()

          );

          transaction_item.id = transactionItem!.id;

          int? id = await DatabaseHelper.updateTransaction(transaction_item);


         /* if(Utils.isMultiUSer) {
            bool synced = await FireBaseUtils.uploadTransactions(
                transaction_item);
            if (!synced) {
              transaction_item!.sync_status = SyncStatus.PENDING;
              await DatabaseHelper.updateTransaction(transaction_item!);
            }
          }*/

          return transactionItem!.id;
             }
        else {
          print("Everything Okay");
          await DatabaseHelper.instance.database;
          TransactionItem transaction_item = TransactionItem(
              flock_update_id: "-1",
              f_id: getFlockID(),
              date: date,
              sale_item: "Bird Sale",
              expense_item: "",
              type: "Income",
              amount: amountController.text,
              payment_method: payment_method,
              payment_status: payment_status,
              sold_purchased_from: personController.text,
              short_note: notesController.text,
              how_many: totalBirdsController.text,
              extra_cost: "",
              extra_cost_details: "",
              f_name: _purposeselectedValue,
              sync_id: Utils.getUniueId(),
              sync_status: SyncStatus.SYNCED,
              last_modified: Utils.getTimeStamp(),
              modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
              farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
              f_sync_id: getFlockSyncID()
          );
          int? id = await DatabaseHelper.insertNewTransaction(transaction_item);

         /* if(Utils.isMultiUSer) {
            bool synced = await FireBaseUtils.uploadTransactions(
                transaction_item);
            if (!synced) {
              transaction_item!.sync_status = SyncStatus.PENDING;
              await DatabaseHelper.updateTransaction(transaction_item!);
            }
          }*/

          return id;
        }
      }
    } else {
      if(transactionItem!=null)
      {
        DatabaseHelper.deleteItem("Transactions", int.parse(transactionItem!.id.toString()));
        /*if(Utils.isMultiUSer) {
          transactionItem!.sync_status = SyncStatus.DELETED;
          bool synced = await FireBaseUtils.uploadTransactions(transactionItem!);

        }*/
        return -1;
      }else {
        return -1;
      }

    }

  }

}
