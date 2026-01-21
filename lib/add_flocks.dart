import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:poultary/multiuser/utils/FirebaseUtils.dart';
import 'package:poultary/multiuser/utils/SyncManager.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/suggested_notifcations.dart';
import 'package:poultary/utils/fb_analytics.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/bird_item.dart';
import 'model/flock.dart';
import 'model/flock_detail.dart';
import 'model/flock_image.dart';
import 'model/notification_suggestions.dart';
import 'model/recurrence_type.dart';
import 'model/schedule_notification.dart';
import 'model/sub_category_item.dart';
import 'model/transaction_item.dart';
import 'multiuser/api/server_apis.dart';
import 'multiuser/model/flockfb.dart';
import 'multiuser/model/user.dart';
import 'multiuser/utils/SyncStatus.dart';

class ADDFlockScreen extends StatefulWidget {
  const ADDFlockScreen({Key? key}) : super(key: key);

  @override
  _ADDFlockScreen createState() => _ADDFlockScreen();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _ADDFlockScreen extends State<ADDFlockScreen>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;
  int activeStep = 0;

  @override
  void dispose() {
    try{
      _myNativeAd.dispose();
    }catch(ex){

    }
    super.dispose();
  }

  String _purposeselectedValue = "";
  String _acqusitionselectedValue = "";

  List<String> _purposeList = [
    'EGG',
    'MEAT',
    'EGG_MEAT',
    'OTHER',
  ];

  List<String> acqusitionList = [
    'PURCHASED',
    'HATCHED',
    'GIFT',
    'OTHER',
  ];


  List<Bird> birds = [];

  int chosen_index = 0;

  final amountController = TextEditingController();
  final personController = TextEditingController();

  late NativeAd _myNativeAd;
  bool _isNativeAdLoaded = false;
  @override
  void initState() {
    super.initState();

    _purposeselectedValue = _purposeList[1];
    _acqusitionselectedValue = acqusitionList[1];
    birdcountController.text = '10';

    getList();
    getBirds();
    Utils.showInterstitial();
    if(Utils.isShowAdd){
      _loadNativeAds();
    }

    AnalyticsUtil.logScreenView(screenName: "add_flocks");
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


  List<Flock> flocks = [];
  bool no_flock = true;
  void getList() async {

    DateTime dateTime = DateTime.now();

    date = DateFormat('yyyy-MM-dd').format(dateTime);

    await DatabaseHelper.instance.database;
    flocks = await DatabaseHelper.getFlocks();

    if(flocks.length == 0)
    {
      no_flock = true;
      print("NO_FLOCKS".tr());
    }

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

    setState(() {

    });

  }

  bool isPurchase = false;
  List<SubItem> _paymentMethodList = [];
  List<String>  _visiblePaymentMethodList = [];
  final List<ScheduledNotification> customNotifications = [];

  List<SuggestedNotification> suggestedNotifications = [];

  void getSuggestedNotifications() {
    Utils utils = new Utils();
    suggestedNotifications = utils.getSuggestedNotifications(birdType: birds[chosen_index].name, ageInDays: Utils.getAgeIndays(date));
    setState(() {

    });
  }

  void _showAddCustomNotificationDialog() {
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
    RecurrenceType _selectedRecurrence = RecurrenceType.once;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Custom Notification', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              decoration: InputDecoration(labelText: 'Description'),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<RecurrenceType>(
              value: _selectedRecurrence,
              onChanged: (RecurrenceType? value) {
                if (value != null) {
                  _selectedRecurrence = value;
                }
              },
              items: RecurrenceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                );
              }).toList(),
              decoration: InputDecoration(labelText: 'Recurrence'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text('Save'),
              onPressed: () {
                final newNotification = ScheduledNotification(
                  id: DateTime.now().millisecondsSinceEpoch,
                  birdType: birds[chosen_index].name,
                  flockId: -1,
                  title: _titleController.text.trim(),
                  description: _descController.text.trim(),
                  scheduledAt: DateTime.now().add(Duration(days: 1)), // Default to tomorrow
                  recurrence: _selectedRecurrence,
                );
                setState(() {
                  customNotifications.add(newNotification);
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void getBirds() async {

    await DatabaseHelper.instance.database;
    birds = await DatabaseHelper.getBirds();
    for (int i = 0; i< birds.length;i++) {
      print(birds.elementAt(i).name);
      print(birds.elementAt(i).image);
      print(birds.elementAt(i).id);
    }

    birds.add(Bird(id: 100, image: "assets/other.jpg", name: 'Other'));

    nameController.text = birds.elementAt(chosen_index).name + " FLock ${flocks.length + 1}";

    setState(() {

    });

  }

  Flock? currentFlock = null;

  bool _validate = false;

  String date = "Choose date";
  final nameController = TextEditingController();
  final birdcountController = TextEditingController();
  final notesController = TextEditingController();

  bool imagesAdded = false;


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
    child:
    return Scaffold(
      appBar: AppBar(
        title: Text(""), // your title
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // go back
          },
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar:
        Container(
          margin: EdgeInsets.all(15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Show Previous Button only if activeStep > 0
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
                        borderRadius: BorderRadius.circular(30), // More rounded
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
                          Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                          SizedBox(width: 5),
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

              // Next or Finish Button
              Expanded(
                child: GestureDetector(
                  onTap: () async {

                    if(saving_images)
                      return;

                    bool validate = checkValidation();

                    if (activeStep == 0) {
                      if (nameController.text.isNotEmpty && birdcountController.text.isNotEmpty) {
                        setState(() {
                          activeStep++;
                        });
                      } else {
                        Utils.showToast("PROVIDE_ALL");
                      }
                    } else if (activeStep == 1) {
                      if (!checkValidationOption()) {
                        Utils.showToast("PROVIDE_ALL");
                      } else {
                        notesController.text = "${nameController.text} Added on ${Utils.getFormattedDate(date)} with ${birdcountController.text} BIRDS";
                        setState(() {
                          activeStep++;
                        });
                      }
                    } else if (activeStep == 2) {
                      if (validate) {
                        print("Saving Data...");
                        await DatabaseHelper.instance.database;
                        Flock flock = Flock(
                          f_id: 1,
                          f_name: nameController.text,
                          bird_count: int.parse(birdcountController.text),
                          purpose: _purposeselectedValue,
                          acqusition_type: _acqusitionselectedValue,
                          acqusition_date: date,
                          notes: notesController.text,
                          icon: birds.elementAt(chosen_index).image,
                          active_bird_count: int.parse(birdcountController.text),
                          active: 1,
                          flock_new: 1,
                          sync_id: Utils.getUniueId(),
                          sync_status: SyncStatus.SYNCED,
                          last_modified: Utils.getTimeStamp(),
                          modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                          farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : ''

                        );

                        int? id = await DatabaseHelper.insertFlock(flock);

                        print("FLOCK_ID $id");
                        SyncManager().addModifiedId(flock.f_name);

                        /*// SET FLOCK ONLINE
                        if(Utils.isMultiUSer) {
                          flock.f_id = id!;
                          bool synced = await FireBaseUtils.uploadFlock(flock);
                          if (!synced) {
                            flock.sync_status = SyncStatus.PENDING;
                            await DatabaseHelper.updateFlockInfo(flock);
                          }
                        }
          */
                        if (isPurchase) {
                          TransactionItem transaction = TransactionItem(
                            flock_update_id: "-1",
                            f_id: id!,
                            date: date,
                            expense_item: "Flock Purchase".tr(),
                            type: "Expense",
                            amount: amountController.text,
                            payment_method: payment_method,
                            payment_status: payment_status,
                            sold_purchased_from: personController.text,
                            short_note: notesController.text,
                            how_many: birdcountController.text,
                            f_name: nameController.text, sale_item: '', extra_cost: '', extra_cost_details: '',
                            sync_id: Utils.getUniueId(),
                            sync_status: SyncStatus.SYNCED,
                            last_modified: Utils.getTimeStamp(),
                            modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                            farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
                            f_sync_id: flock.sync_id

                          );

                          int? tr_id = await DatabaseHelper.insertNewTransaction(transaction);

                          Flock_Detail flockDetail = Flock_Detail(
                            f_id: id,
                            item_type: 'Addition',
                            item_count: int.parse(birdcountController.text),
                            acqusition_type: _acqusitionselectedValue,
                            acqusition_date: date,
                            short_note: notesController.text,
                            f_name: nameController.text,
                            transaction_id: tr_id!.toString(), reason: '',

                              sync_id: Utils.getUniueId(),
                              sync_status: SyncStatus.SYNCED,
                              last_modified: Utils.getTimeStamp(),
                              modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                              farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
                              f_sync_id: flock.sync_id
                          );
                          int? flock_detail_id = await DatabaseHelper.insertFlockDetail(flockDetail);

                          await DatabaseHelper.updateLinkedTransaction(tr_id.toString(), flock_detail_id.toString());

                          if(Utils.isMultiUSer) {
                            FlockFB flockFB = FlockFB(flock: flock,
                                transaction: transaction,
                                flockDetail: flockDetail);

                            flockFB.farm_id = Utils.currentUser!.farmId;
                            flockFB.modified_by = Utils.currentUser!.email;

                           await FireBaseUtils.uploadFlock(flockFB);


                          }

                        }
                        else {
                          Flock_Detail flockDetail = Flock_Detail(
                            f_id: id!,
                            item_type: 'Addition',
                            item_count: int.parse(birdcountController.text),
                            acqusition_type: _acqusitionselectedValue,
                            acqusition_date: date,
                            short_note: notesController.text,
                            f_name: nameController.text,
                            transaction_id: "-1", reason: '',
                              sync_id: Utils.getUniueId(),
                              sync_status: SyncStatus.SYNCED,
                              last_modified: Utils.getTimeStamp(),
                              modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                              farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',
                              f_sync_id: flock.sync_id
                          );
                          await DatabaseHelper.insertFlockDetail(flockDetail);

                          if(Utils.isMultiUSer) {
                            FlockFB flockFB = FlockFB(flock: flock, flockDetail: flockDetail);
                            flockFB.farm_id = Utils.currentUser!.farmId;
                            flockFB.modified_by = Utils.currentUser!.email;

                            await FireBaseUtils.uploadFlock(flockFB);
                          }

                        }

                        if (base64Images.isNotEmpty) {
                          await insertFlockImages(id, flock.sync_id);
                        } else {
                          Utils.showToast("FLOCK_CREATED");
                          Navigator.pop(context);
                          gotoNotificationsScreen(id);
                        }

                        AnalyticsUtil.logAddFlock();
                      } else {
                        Utils.showToast("PROVIDE_ALL");
                      }
                    }
                  },
                  child: Container(
                    height: 55,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: activeStep == 2
                            ? [Utils.getThemeColorBlue(), Colors.greenAccent] // Finish Button
                            : [Utils.getThemeColorBlue(), Colors.blueAccent], // Next Button
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30), // More rounded
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
                          activeStep == 2 ? "Finish".tr() : "Next".tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          activeStep == 2 ? Icons.check_circle : Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      body: SafeArea(
        top: false,
        child: Container(
          width: widthScreen,
          height: heightScreen,
          color: Utils.getScreenBackground(),
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
                  Visibility(
                    visible: false,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0),bottomRight: Radius.circular(0)),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Utils.getThemeColorBlue(), //(x,y)
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              width: 50,
                              height: 50,
                              child: InkWell(
                                child: Icon(Icons.arrow_back,
                                    color: Utils.getThemeColorBlue(), size: 30),
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            Container(
                                margin: EdgeInsets.only(left: 10),
                                child: Text(
                                  "NEW_FLOCK".tr(),
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                )),

                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16,),
                  EasyStepper(
                    activeStep: activeStep,
                    activeStepTextColor: Colors.blue.shade900,
                    finishedStepTextColor: Utils.getThemeColorBlue(),
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
                        customStep: _buildStepIcon(Icons.info, 0),
                        title: 'Flock Name'.tr(),
                      ),
                      EasyStep(
                        customStep: _buildStepIcon(Icons.payment, 1),
                        title: 'INCOME_EXPENSE'.tr(),
                      ),
                      EasyStep(
                        customStep: _buildStepIcon(Icons.image, 2),
                        title: 'IMAGES'.tr(),
                      ),
                    ],
                    onStepReached: (index) => setState(() => activeStep = index),
                  ),


                  activeStep == 0?
                  Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        // Title
                        Container(
                          margin: EdgeInsets.only(left: 10, top: 0, bottom: 8),
                          child: Text(
                            "BIRD_TYPES".tr(),
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: Utils.getThemeColorBlue(),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Bird Type Selection
                        Container(
                          height: 200,
                          width: widthScreen,
                          margin: EdgeInsets.only(left: 15),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: birds.length,
                            itemBuilder: (BuildContext context, int index) {
                              bool isSelected = index == chosen_index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    chosen_index = index;
                                    nameController.text = birds[index].name.tr() + " Flock".tr() + "${flocks.length + 1}";
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 300),
                                  margin: EdgeInsets.symmetric(horizontal: 8),
                                  padding: EdgeInsets.all(10),
                                  width: 130,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.blue[100] : Colors.white,
                                    borderRadius: BorderRadius.circular(15),

                                    border: Border.all(
                                      color: isSelected ? Colors.blue : Colors.grey,
                                      width: isSelected ? 3 : 1,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      // Tick icon on the top-right corner
                                      if (isSelected)
                                        Positioned(
                                          child: Icon(Icons.check_circle, color: Colors.blue, size: 28),
                                        ),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset(birds[index].image.replaceAll("jpeg", "png"), height: 90, width: 90, fit: BoxFit.contain),
                                          SizedBox(height: 10),
                                          Text(
                                            birds[index].name.tr(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 20),

                        // Flock Name Input
                        Container(
                            margin: EdgeInsets.only(left: 15, right: 15),
                            child: _buildInputField("FLOCK_NAME".tr(), nameController, Icons.edit)),

                        SizedBox(height: 15),

                        // Number of Birds & Purpose Selection
                        Container(
                          margin: EdgeInsets.only(left: 15, right: 15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildInputField("NUMBER_BIRDS".tr(), birdcountController, Icons.numbers, width: 150, keyboardType: TextInputType.number, inputFormat: "number"),
                              SizedBox(width: 10),
                              Expanded(
                                child: _buildDropdownField("PURPOSE1".tr(), _purposeList, _purposeselectedValue, (value) {
                                  setState(() {
                                    _purposeselectedValue = value!;
                                  });
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ):SizedBox(width: 1,),

                  activeStep==1?
                  Container(
                    margin: EdgeInsets.only(left: 15,right: 15,bottom: 15),
                    child: Column(
                      children: [
                        // Section Title
                        Text(
                          "Financial Info".tr(),
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: Utils.getThemeColorBlue(),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 20),

                        // Acquisition Dropdown (Always Enabled)
                        _buildSectionLabel("ACQUSITION".tr()),
                        _buildDropdownField("ACQUSITION".tr(), acqusitionList, _acqusitionselectedValue, (value) {
                          setState(() {
                            _acqusitionselectedValue = value!;
                            isPurchase = (_acqusitionselectedValue == "PURCHASED"); // Enable when PURCHASED is selected

                          });
                        }),

                        SizedBox(height: 15),

                        // Disable all other UI components when isPurchase is false
                        AbsorbPointer(
                          absorbing: !isPurchase, // Disables interaction when isPurchase is false
                          child: Opacity(
                            opacity: isPurchase ? 1.0 : 0.5, // Visually indicate the UI is disabled
                            child: Column(
                              children: [
                                // Expense Amount
                                _buildSectionLabel("EXPENSE_AMOUNT".tr()),
                                _buildInputField("EXPENSE_AMOUNT".tr(), amountController, Icons.attach_money, keyboardType: TextInputType.number, inputFormat: "float"),

                                SizedBox(height: 15),

                                // Payment Method & Payment Status (Row)
                                Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionLabel("Payment Method".tr()),
                                        _buildDropdownField("Payment Method".tr(), _visiblePaymentMethodList, payment_method, width: 200, (value) {
                                          setState(() {
                                            payment_method = value!;
                                          });
                                        }),
                                      ],
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildSectionLabel("Payment Status".tr()),
                                          _buildDropdownField("Payment Status".tr(), paymentStatusList, payment_status, (value) {
                                            setState(() {
                                              payment_status = value!;
                                            });
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 15),

                                // Paid To
                                _buildSectionLabel("PAID_TO1".tr()),
                                _buildInputField("PAID_TO_HINT".tr(), personController, Icons.person),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      :SizedBox(width: 1,),


                  activeStep==2?
                  Stack(
                    children: [
                      IgnorePointer(
                        ignoring: saving_images, // disables child when true
                        child: Opacity(
                          opacity: saving_images ? 0.5 : 1.0, // optional visual feedback
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  "Flock Images and Description".tr(),
                                  style: TextStyle(
                                    color: Utils.getThemeColorBlue(),
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 25),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionLabel("DATE".tr()),
                                    GestureDetector(
                                      onTap: () {
                                        pickDate();
                                      },
                                      child: _buildDatePicker(Utils.getFormattedDate(date)),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionLabel("FLOCK_IMAGES".tr()),
                                    _buildImagePicker(),
                                  ],
                                ),
                              ),
                              SizedBox(height: 30),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionLabel("FLOCK_DESC".tr()),
                                    _buildInputField(
                                      "NOTES_HINT".tr(),
                                      notesController,
                                      Icons.notes,
                                      keyboardType: TextInputType.multiline,
                                      height: 100,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Optional loading spinner when saving
                      if (saving_images)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black45,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  ) : SizedBox(width: 1,),

                ],
              ),
            ),)
          ],)
        ),
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
        double height = 70,
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

  Widget _buildImagePicker() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),

      ),
      child: Column(
        children: [
          imagesAdded
              ? GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Three images per row
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: imageFileList!.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  // Image
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: FileImage(File(imageFileList![index].path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Delete Button (Positioned on Image)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          imageFileList!.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              );
            },
          )
              : Container(
            height: 80,
            alignment: Alignment.center,
            child: Text("NO_IMAGES".tr(), style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),

          SizedBox(height: 10),
          imageFileList!.length < 5? Text('Add 1-5 images', style: TextStyle(color: Colors.grey, ),) : SizedBox(width: 1,),
          // Add Images Button (Modern Floating Button)
          Visibility(
            visible: imageFileList!.length < 5? true : false,
            child: GestureDetector(
              onTap: () {
                selectImages();
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 2,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, color: Colors.white),
                    SizedBox(width: 8),
                    Text("IMAGES".tr(), style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
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


  // Section Title Label
  Widget _buildSectionLabel(String text) {
    return Container(
      alignment: Alignment.topLeft,
      margin: EdgeInsets.only(left: 10, bottom: 5),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  void isFinanceInfo(){
    for(int i=0;i<acqusitionList.length;i++){
      if(_acqusitionselectedValue == acqusitionList[i]){
        if(i == 0){
          isPurchase = true;
        }else{
          isPurchase = false;
        }
      }
    }
    setState(() {

    });
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



  Widget getAcqusitionDropDownList() {
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
            isFinanceInfo();
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
  Widget getDropDownList() {
    return Container(
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration.collapsed(hintText: ''),
        isDense: true,
        value: _purposeselectedValue,
        elevation: 16,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() {
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




    List<XFile>? imageFileList = [];

    void selectImages() async {
      final ImagePicker imagePicker = ImagePicker();
      final List<XFile>? selectedImages = await imagePicker.pickMultiImage();

      if (selectedImages != null && selectedImages.isNotEmpty) {
        int remainingSlots = 5 - imageFileList!.length;

        final imagesToAdd = selectedImages.take(remainingSlots).toList();
        imageFileList!.addAll(imagesToAdd);


        print("Image List Length:" + imageFileList!.length.toString());

        saveImagesDB();

        imagesAdded = true;

        setState((){});
      }

    }


  void pickDate() async{

     DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        //DateTime.now() - not to allow to choose before today.
        lastDate: DateTime.now());

    if (pickedDate != null) {
      print(pickedDate); //pickedDate output format => 2021-03-10 00:00:00.000
      String formattedDate =
      DateFormat('yyyy-MM-dd').format(pickedDate);
      print(formattedDate);
      notesController.text = nameController.text +" "+"Added on".tr()+" "+Utils.getFormattedDate(formattedDate) +" "+"with".tr() +" "+ birdcountController.text + " " + "BIRDS".tr();
      //formatted date output using intl package =>  2021-03-16
      setState(() {
        date =
            formattedDate; //set output date to TextField value.
      });
    } else {}
  }

  bool checkValidationOption(){

    bool valid = true;

    if(_acqusitionselectedValue.toLowerCase().contains("ACQUSITION_TYPE".tr()) ||
        _acqusitionselectedValue.toLowerCase().contains("ACQUSITION_TYPE"))
    {
      valid = false;
      print("Select Acqusition Type");
    }

    if(isPurchase){
      if(amountController.text.isEmpty)
        valid = false;

      if(personController.text.isEmpty)
        valid = false;

    }


    return valid;
  }

  bool checkValidation() {
    bool valid = true;

    if(date.toLowerCase().contains("date")){
      valid = false;
      print("Select Date");
    }

    if(birdcountController.text.isEmpty){
      valid = false;
      print("Select Bird Count");
    }

    if(nameController.text.isEmpty){
      valid = false;
      print("Select Flock Name");
    }

    return valid;

  }

  List<String> base64Images = [];
  
  void saveImagesDB() async {

        base64Images.clear();

        File file;
      for (int i=0;i<imageFileList!.length;i++) {

        file = await Utils.convertToJPGFileIfRequiredWithCompression(File(imageFileList!.elementAt(i).path));
        final bytes = File(file.path).readAsBytesSync();
        String base64Image =  base64Encode(bytes);
        base64Images.add(base64Image);

        print("img_pan : $base64Image");
        
      }
  }

  bool saving_images = false;
  Future<void> insertFlockImages(int f_id, String? id) async {

    if(Utils.isMultiUSer){
      try {

        setState(() {
          saving_images = true;
        });
        MultiUser? user = await SessionManager.getUserFromPrefs();
        List<String> imageUrls = await FlockImageUploader().uploadFlockImages(
            farmId: user!.farmId, base64Images: base64Images);

        await FireBaseUtils.saveFlockImagesToFirestore(
          farmId: user.farmId,
          flockId: id!,
          imageUrls: imageUrls,
          uploadedBy: user.email,
        );

        setState(() {
          saving_images = false;
        });

        if (base64Images.length > 0) {
          for (int i = 0; i < base64Images.length; i++) {
            Flock_Image image = Flock_Image(
                f_id: f_id, image: base64Images.elementAt(i),
                sync_id: Utils.getUniueId(),
                sync_status: SyncStatus.SYNCED,
                last_modified: Utils.getTimeStamp(),
                modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
                farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : '',


            );
            DatabaseHelper.insertFlockImages(image);
          }

          print("Images Inserted");
          Utils.showToast("FLOCK_CREATED");
          Navigator.pop(context);
          gotoNotificationsScreen(f_id);
        }

      }
      catch(ex){
        setState(() {
          saving_images = false;
        });
        Utils.showToast(ex.toString());
        print(ex);
      }
    } else {
      if (base64Images.length > 0) {
        for (int i = 0; i < base64Images.length; i++) {
          Flock_Image image = Flock_Image(
              f_id: f_id, image: base64Images.elementAt(i),
              sync_id: Utils.getUniueId(),
              sync_status: SyncStatus.SYNCED,
              last_modified: Utils.getTimeStamp(),
              modified_by: Utils.isMultiUSer ? Utils.currentUser!.email : '',
              farm_id: Utils.isMultiUSer ? Utils.currentUser!.farmId : ''
          );

          DatabaseHelper.insertFlockImages(image);
        }

        print("Images Inserted");
        Utils.showToast("FLOCK_CREATED");
        Navigator.pop(context);
        gotoNotificationsScreen(f_id);
      }
    }

  }

  void gotoNotificationsScreen(int f_id) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SuggestedNotificationScreen(birdType: birds[chosen_index].name, flockId: f_id, flockAgeInDays: Utils.getAgeIndays(date),)));
  }


}
