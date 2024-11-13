import 'package:easy_localization/easy_localization.dart';
import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:poultary/model/flock_detail.dart';
import 'package:poultary/model/transaction_item.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/utils.dart';
import 'database/databse_helper.dart';
import 'model/flock.dart';
import 'model/sub_category_item.dart';

class NewBirdsCollection extends StatefulWidget {

  bool isCollection;
  Flock_Detail? flock_detail;
  NewBirdsCollection({Key? key, required this.isCollection, this.flock_detail}) : super(key: key);

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

  @override
  void dispose() {
    super.dispose();
  }

  String _purposeselectedValue = "";
  String _reductionReasonValue = "";
  String _acqusitionselectedValue = "";

  List<String> _purposeList = [];
  List<String> _reductionReasons = [
    'SOLD'.tr(),'PERSONAL_USE'.tr(),'MORTALITY'.tr(),'LOST'.tr(),'OTHER'.tr()];

  List<String> acqusitionList = [
    'PURCHASED'.tr(),
    'HATCHED'.tr(),
    'GIFT'.tr(),
    'OTHER'.tr(),
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

      _reductionReasons = [_reductionReasonValue.tr()];
      acqusitionList = [_acqusitionselectedValue.tr()];



    }else{
      _reductionReasonValue = _reductionReasons[1];
      _acqusitionselectedValue = acqusitionList[1];
      totalBirdsController.text = "5";
    }

    getList();
    Utils.showInterstitial();
    Utils.setupAds();

  }

  List<SubItem> _paymentMethodList = [];
  List<String>  _visiblePaymentMethodList = [];
  int activeStep = 0;

  List<Flock> flocks = [];
  void getList() async {

    _paymentMethodList = await DatabaseHelper.getSubCategoryList(5);

    for(int i=0;i<_paymentMethodList.length;i++){
      _visiblePaymentMethodList.add(_paymentMethodList.elementAt(i).name!);
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
        flocks.add(Flock(f_id: widget.flock_detail!.f_id,f_name: widget.flock_detail!.f_name, bird_count: singleflock!.bird_count,purpose: '',acqusition_date: '',acqusition_type: '',notes: '',icon: '', active_bird_count: singleflock!.active_bird_count, active: 1));
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
        _purposeList.add(flocks.elementAt(i).f_name);
      }

      _purposeselectedValue = Utils.selected_flock!.f_name;//Utils.SELECTED_FLOCK;

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
    return SafeArea(
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: Container(
            width: widthScreen,
            height: heightScreen,
            color: Utils.getScreenBackground(),
            child: SingleChildScrollViewWithStickyFirstWidget(
              child: Column(
                children: [
                  Utils.getDistanceBar(),

                  ClipRRect(
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0),bottomRight: Radius.circular(0)),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: isCollection ? Utils.getScreenBackground() : Utils.getScreenBackground(), //(x,y)
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
                               "",
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              )),

                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20,),
                  EasyStepper(
                    activeStep: activeStep,
                    activeStepTextColor: Utils.getThemeColorBlue(),
                    finishedStepTextColor: Utils.getThemeColorBlue(),
                    internalPadding: 30,
                    showLoadingAnimation: false,
                    stepRadius: 12,
                    showStepBorder: true,
                    steps: [
                      EasyStep(
                        customStep: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 7,
                            backgroundColor:
                            activeStep >= 0 ? Utils.getThemeColorBlue() : Colors.grey,
                          ),
                        ),
                        title: 'Step 1',
                      ),
                      EasyStep(
                        customStep: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 7,
                            backgroundColor:
                            activeStep >= 1 ? Utils.getThemeColorBlue() : Colors.grey,
                          ),
                        ),
                        title: 'Step 2',

                      ),

                    ],
                    onStepReached: (index) =>
                        setState(() => activeStep = index),
                  ),

                  Container(
                    alignment: Alignment.center,
                    height: !is_transaction ? heightScreen-250 : heightScreen - 134,

                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            child: Text(
                              isCollection? isEdit? "EDIT".tr() +" "+ 'Addition'.tr() : 'ADD_BIRDS'.tr() :isEdit? "EDIT".tr() +" "+ "Reduction".tr() :'REDUCE_BIRDS'.tr(),
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                  color: Utils.getThemeColorBlue(),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          activeStep == 0?   Container(
                            child: Column(
                              children: [

                                SizedBox(height: 30,width: widthScreen),
                                Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('CHOOSE_FLOCK_1'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                                Container(
                                  width: widthScreen,
                                  height: 70,
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.all(10),
                                  margin: EdgeInsets.only(left: 20, right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withAlpha(70),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(20.0)),
                                    border: Border.all(
                                      color:  Colors.grey,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: getDropDownList(),
                                ),

                                SizedBox(height: 10,width: widthScreen),

                                !isCollection? SizedBox(height: 10,width: widthScreen): SizedBox(height: 0,width: widthScreen),
                                !isCollection? Container(
                                  child: Column(
                                    children: [
                                      Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('REDUCTIONS_1'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
                                      Container(
                                        width: widthScreen,
                                        height: 70,
                                        alignment: Alignment.centerRight,
                                        padding: EdgeInsets.all(10),
                                        margin: EdgeInsets.only(left: 20, right: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withAlpha(70),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20.0)),
                                          border: Border.all(
                                            color:  Colors.grey,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: getReductionList(),
                                      ),
                                    ],
                                  ),
                                ):SizedBox(height: 0, width: widthScreen),
                               isCollection? Container(
                                  child: Column(
                                    children: [
                                      Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('ACQUSITION'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
                                      Container(
                                        width: widthScreen,
                                        height: 70,
                                        alignment: Alignment.centerRight,
                                        padding: EdgeInsets.all(10),
                                        margin: EdgeInsets.only(left: 20, right: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withAlpha(70),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20.0)),
                                          border: Border.all(
                                            color:  Colors.grey,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: getAcqusitionList(),
                                      ),
                                    ],
                                  ),
                                ):SizedBox(height: 0,width: widthScreen),
                               is_transaction && !isEdit? Container(alignment: Alignment.center,child: Text(isCollection?'Auto_expense'.tr():'Auto_Income'.tr(), style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w200),)):SizedBox(width: 1,),

                               SizedBox(height: 10,width: widthScreen),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                        child: Column(
                                          children: [
                                            Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('BIRDS_COUNT'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                                            Container(
                                              height: 70,
                                              padding: EdgeInsets.all(0),
                                              margin: EdgeInsets.only(left: 20, right: 10),
                                              decoration: BoxDecoration(
                                                  color: Colors.grey.withAlpha(70),
                                                  borderRadius:
                                                  BorderRadius.all(Radius.circular(20))),
                                              child: Container(
                                                child: SizedBox(
                                                  width: widthScreen,
                                                  height: 60,
                                                  child: TextFormField(
                                                    maxLines: null,
                                                    expands: true,
                                                    controller: totalBirdsController,
                                                    keyboardType: TextInputType.number,
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter.allow(RegExp(r"[0-9]")),
                                                      TextInputFormatter.withFunction((oldValue, newValue) {
                                                        final text = newValue.text;
                                                        return text.isEmpty
                                                            ? newValue
                                                            : double.tryParse(text) == null
                                                            ? oldValue
                                                            : newValue;
                                                      }),
                                                    ],
                                                    textInputAction: TextInputAction.next,
                                                    decoration:  InputDecoration(
                                                      fillColor: Colors.grey,
                                                      focusColor: Colors.grey,
                                                      border: OutlineInputBorder(
                                                          borderRadius:
                                                          BorderRadius.all(Radius.circular(20))),
                                                      hintText: 'BIRDS_COUNT'.tr(),
                                                      hintStyle: TextStyle(
                                                          color: Colors.grey, fontSize: 16),
                                                      labelStyle: TextStyle(
                                                          color: Colors.black, fontSize: 16),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )) ,
                                  is_transaction ? Expanded(
                                        child: Column(
                                          children: [
                                            Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 5,bottom: 5),child: Text(!isCollection?'SALE_AMOUNT'.tr():'EXPENSE_AMOUNT'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
                                            Container(
                                              height: 70,
                                              padding: EdgeInsets.all(0),
                                              margin: EdgeInsets.only( right: 20),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withAlpha(70),
                                                borderRadius: const BorderRadius.all(
                                                    Radius.circular(20.0)),

                                              ),
                                              child: Container(
                                                child: SizedBox(
                                                  width: widthScreen,
                                                  height: 60,
                                                  child: TextFormField(
                                                    maxLines: null,
                                                    expands: true,
                                                    controller: amountController,
                                                    keyboardType: TextInputType.number,
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
                                                      TextInputFormatter.withFunction((oldValue, newValue) {
                                                        final text = newValue.text;
                                                        return text.isEmpty
                                                            ? newValue
                                                            : double.tryParse(text) == null
                                                            ? oldValue
                                                            : newValue;
                                                      }),
                                                    ],
                                                    textInputAction: TextInputAction.next,
                                                    decoration:  InputDecoration(
                                                      border: OutlineInputBorder(
                                                          borderRadius:
                                                          BorderRadius.all(Radius.circular(20))),
                                                      hintText: !isCollection?'SALE_AMOUNT'.tr():'EXPENSE_AMOUNT'.tr(),
                                                      hintStyle: TextStyle(
                                                          color: Colors.grey, fontSize: 14),
                                                      labelStyle: TextStyle(
                                                          color: Colors.black, fontSize: 16),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )) : SizedBox(width: 1,),

                                  ],
                                ),
                                SizedBox(height: 10,width: widthScreen),

                                is_transaction? Column(
                                  children: [
                                    Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text(isCollection?'PAID_TO1'.tr():'SOLD_TO'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                                    Container(
                                      width: widthScreen,
                                      height: 70,
                                      padding: EdgeInsets.all(0),
                                      margin: EdgeInsets.only(left: 20, right: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withAlpha(70),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(20.0)),

                                      ),
                                      child: Container(
                                        child: SizedBox(
                                          width: widthScreen,
                                          height: 60,
                                          child: TextFormField(
                                            maxLines: null,
                                            expands: true,
                                            controller: personController,
                                            textInputAction: TextInputAction.next,
                                            decoration:  InputDecoration(
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                  BorderRadius.all(Radius.circular(20))),
                                              hintText: isCollection?'PAID_TO_HINT'.tr():'SOLD_TO_HINT'.tr(),
                                              hintStyle: TextStyle(
                                                  color: Colors.grey, fontSize: 16),
                                              labelStyle: TextStyle(
                                                  color: Colors.black, fontSize: 16),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ) : SizedBox(width: 1,),

                              ],
                            ),
                          ) : SizedBox(width: 1,),
                          activeStep == 1?   Container(
                            child: Column(
                              children: [
                                Container(
                                    margin: EdgeInsets.only(left: 20),
                                    child: Text(max_hint, style: TextStyle(color: Colors.red, fontSize: 14),)),

                                is_transaction? Column(
                                  children: [
                                    SizedBox(height: 20,width: widthScreen),
                                    Column(
                                      children: [
                                        Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Payment Method'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                                        Container(
                                          width: widthScreen,
                                          height: 70,
                                          alignment: Alignment.centerRight,
                                          padding: EdgeInsets.all(10),
                                          margin: EdgeInsets.only(left: 20, right: 20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withAlpha(70),
                                            borderRadius: const BorderRadius.all(
                                                Radius.circular(20.0)),
                                            border: Border.all(
                                              color:  Colors.grey,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: getPaymentMethodList(),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 10,width: widthScreen),
                                    Column(
                                      children: [
                                        Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('Payment Status'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),

                                        Container(
                                          width: widthScreen,
                                          height: 70,
                                          alignment: Alignment.centerRight,
                                          padding: EdgeInsets.all(10),
                                          margin: EdgeInsets.only(left: 20, right: 20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withAlpha(70),
                                            borderRadius: const BorderRadius.all(
                                                Radius.circular(20.0)),
                                            border: Border.all(
                                              color:  Colors.grey,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: getPaymentStatusList(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ) : SizedBox(width: 1,),
                                SizedBox(height: 10,width: widthScreen),


                                Column(
                                  children: [
                                    Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('DATE'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
                                    Container(
                                      width: widthScreen,
                                      height: 70,
                                      margin: EdgeInsets.only(left: 20, right: 20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withAlpha(70),
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(20.0)),
                                        border: Border.all(
                                          color:  Colors.grey,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          pickDate();
                                        },
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          padding: EdgeInsets.only(left: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,

                                          ),
                                          child: Text(Utils.getFormattedDate(date), style: TextStyle(
                                              color: Colors.black, fontSize: 16),),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 10,width: widthScreen),
                                Column(
                                  children: [
                                    Container(alignment: Alignment.topLeft, margin: EdgeInsets.only(left: 25,bottom: 5),child: Text('DESCRIPTION_1'.tr(), style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),)),
                                    Container(
                                      width: widthScreen,
                                      height: 100,
                                      margin: EdgeInsets.only(left: 20, right: 20),
                                      decoration: BoxDecoration(
                                          color: Colors.grey.withAlpha(70),
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(10))),
                                      child: Container(
                                        child: SizedBox(
                                          width: widthScreen,
                                          height: 100,
                                          child: TextFormField(
                                            maxLines: 2,
                                            controller: notesController,
                                            keyboardType: TextInputType.multiline,
                                            textAlign: TextAlign.start,
                                            textInputAction: TextInputAction.done,
                                            decoration:  InputDecoration(
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                  BorderRadius.all(Radius.circular(10))),
                                              hintText: 'NOTES_HINT'.tr(),
                                              hintStyle: TextStyle(
                                                  color: Colors.black, fontSize: 16),
                                              labelStyle: TextStyle(
                                                  color: Colors.black, fontSize: 16),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ) : SizedBox(width: 1,),
                          SizedBox(height: 10,width: widthScreen),
                          InkWell(
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
                          )

                        ]),
                  ),
                ],
              ),
            ),
          ),
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
              value,
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
              value,
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
              value,
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

    if(date.toLowerCase().contains("Choose date".tr())){
      valid = false;
      print("Select Date");
    }


    if(isCollection) {
      if (_acqusitionselectedValue.contains("ACQUSITION_TYPE".tr())) {
        valid = false;
        print("Select Acqusition Type");
      }
    }

    if(!isCollection) {
      if (_reductionReasonValue.contains("REDUCTION_REASON".tr())) {
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
  String payment_method = "Cash".tr();
  String payment_status = "CLEARED".tr();
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

  List<String> paymentStatusList = ['CLEARED'.tr(),'UNCLEAR'.tr(),'RECONCILED'.tr()];

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
              value,
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
              expense_item: "Bird Purchase".tr(),
              type: "Expense",
              amount: amountController.text,
              payment_method: payment_method,
              payment_status: payment_status,
              sold_purchased_from: personController.text,
              short_note: notesController.text,
              how_many: totalBirdsController.text,
              extra_cost: "",
              extra_cost_details: "",
              f_name: _purposeselectedValue);
          transaction_item.id =
              transactionItem!.id;
          int? id = await DatabaseHelper
              .updateTransaction(transaction_item);
          return id;
        }
        else {
          await DatabaseHelper.instance.database;
          TransactionItem transaction_item = TransactionItem(
              flock_update_id: "-1",
              f_id: getFlockID(),
              date: date,
              sale_item: "",
              expense_item: "Bird Purchase".tr(),
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
              f_name: _purposeselectedValue);
          int? id = await DatabaseHelper
              .insertNewTransaction(transaction_item);
          return id;
        }
      }else{
        if(isEdit){
          await DatabaseHelper.instance.database;
          TransactionItem transaction_item = TransactionItem(
              flock_update_id: widget.flock_detail!.f_detail_id.toString(),
              f_id: getFlockID(),
              date: date,
              sale_item: "Bird Sale".tr(),
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
              f_name: _purposeselectedValue);

          transaction_item.id = transactionItem!.id;

          int? id = await DatabaseHelper.updateTransaction(transaction_item);
          return id;
             }
        else {
          print("Everything Okay");
          await DatabaseHelper.instance.database;
          TransactionItem transaction_item = TransactionItem(
              flock_update_id: "-1",
              f_id: getFlockID(),
              date: date,
              sale_item: "Bird Sale".tr(),
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
              f_name: _purposeselectedValue);
          int? id = await DatabaseHelper.insertNewTransaction(transaction_item);
          return id;
        }
      }
    }else{
      if(transactionItem!=null){
        DatabaseHelper.deleteItem("Transactions", int.parse(transactionItem!.id.toString()));
        return -1;
      }else{
        return -1;
      }

    }

  }

}
