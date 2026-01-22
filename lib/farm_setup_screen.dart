import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:currency_picker/currency_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:poultary/sticky.dart';
import 'package:poultary/utils/session_manager.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/bird_item.dart';
import 'model/egg_item.dart';
import 'model/farm_item.dart';
import 'model/flock.dart';
import 'model/flock_image.dart';

class FarmSetupScreen extends StatefulWidget {
  const FarmSetupScreen({Key? key}) : super(key: key);

  @override
  _FarmSetupScreen createState() => _FarmSetupScreen();
}

String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

class _FarmSetupScreen extends State<FarmSetupScreen>
    with SingleTickerProviderStateMixin {
  double widthScreen = 0;
  double heightScreen = 0;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;



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
  String _purposeselectedValue = "";
  String _reductionReasonValue = "";


  int chosen_index = 0;

  @override
  void initState() {
    super.initState();

    getInfo();
    if(Utils.isShowAdd){
      _loadBannerAd();
    }

  }

  FarmSetup? farmSetup = null;
  void getInfo() async {

    await DatabaseHelper.instance.database;
    selectedUnit = await SessionManager.getUnit();
    Utils.selected_unit = selectedUnit;
    List<FarmSetup> list = await DatabaseHelper.getFarmInfo();
    farmSetup = list.elementAt(0);

    if(farmSetup!.image.toLowerCase().contains("asset")){
      modified = 0;
    }else{
      modified = 1;
    }

    locationController.text = farmSetup!.location;
    nameController.text = farmSetup!.name;
    date = farmSetup!.date;

    selectedCurrency = farmSetup!.currency;

    if(date.toLowerCase().contains("date")){
      var now = DateTime.now();
      var formatter = DateFormat('yyyy-MM-dd');
      date = formatter.format(now);
      print("Select Date");
    }

    setState(() {

    });

  }

  int modified = 0;

  String selectedCurrency = "\$";
  String date = "Choose date";
  final locationController = TextEditingController();
  final nameController = TextEditingController();
  String selectedUnit = 'KG';

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
        title: Text(
          "FARM_SETUP".tr(),
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
      bottomNavigationBar: Container(
        height: 60,
        margin: EdgeInsets.only(bottom: 15),
        child: ElevatedButton(
          onPressed: () {
            // Your button action here
            if (checkValidation())
            {
              if(!nameController.text.isEmpty) {
                farmSetup!.name = nameController.text;
              }
              Utils.selected_unit = selectedUnit;
              farmSetup!.date = date;
              farmSetup!.modified = 1;
              DatabaseHelper.updateFarmSetup(farmSetup);

              Utils.showToast("SUCCESSFUL".tr());
              // Save logic here
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PROVIDE_ALL".tr())));
            }
          },
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Utils.getThemeColorBlue()],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              alignment: Alignment.center,
              child: Text(
                "SAVE".tr(), // Replace with your button label
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          width: widthScreen,
          height: heightScreen,
          color: Utils.getScreenBackground(),
          child: Column(children: [
             if(_isBannerAdReady)
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                      height: 60.0,
                      width: Utils.WIDTH_SCREEN,
                      child: AdWidget(ad: _bannerAd)
                  ),
                ),

            Expanded(child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🖼 Image Picker with Overlay
                        Center(
                          child: InkWell(
                            onTap: selectImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade400),
                                    image: modified == 1 ? DecorationImage(
                                        image: MemoryImage(Base64Decoder().convert(farmSetup!.image)),
                                        fit: BoxFit.cover)
                                        : DecorationImage(
                                        image: AssetImage('assets/farm_icon.png'),
                                        fit: BoxFit.contain),
                                  ),
                                ),
                                // Overlay Icon & Text
                                Positioned(
                                  bottom: 10,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.camera_alt, color: Colors.white, size: 12),
                                        SizedBox(width: 6),
                                        Text("Tap to change".tr(), style: TextStyle(color: Colors.white, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 30),

                        // 📝 Farm Name
                        _buildCardField(
                          icon: Icons.home,
                          label: "FARM_NAME".tr(),
                          child: TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: "Enter farm name".tr(),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        _buildCardField(
                          icon: Icons.attach_money,
                          label: "CURRENCY".tr(),
                          onTap: chooseCurrency, // 👈 pass tap handler here
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedCurrency ?? "Select Currency".tr(),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 📅 Date Picker
                        _buildCardField(
                          icon: Icons.calendar_today,
                          label: "Farm Setup Date".tr(),
                          onTap: pickDate,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                date ?? "Select Date".tr(),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.calendar_month),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ⚖️ Select Unit
                        Text("Select Unit".tr(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Container(
                          height: 60,
                          width: widthScreen,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedUnit,
                              icon: const Icon(Icons.arrow_drop_down),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedUnit = newValue!;
                                });
                              },
                              items: <String>['KG', 'lbs'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value.tr(), style: const TextStyle(fontSize: 16)),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),)
          ],),
        ),
      ),
    );
  }

  Widget _buildCardField({
    required IconData icon,
    required String label,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap, // 👈 Whole card becomes tappable if onTap is provided
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }
  /*if (checkValidation()) {
  // Save logic here
  Navigator.pop(context);
  } else {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PROVIDE_ALL".tr())));
  }*/

  // 🔹 Function to Build Text Input Fields
  Widget _buildInputField({required String label, required TextEditingController controller, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint.tr(),
              hintStyle: TextStyle(color: Colors.grey.shade500),
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  // 🔹 Function to Build Dropdown Selection Fields
  Widget _buildDropdownField({required String label, required String value, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value.tr(), style: TextStyle(fontSize: 16, color: Colors.black)),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
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

    if(date.toLowerCase().contains("date")){
      valid = false;
      print("Select Date");
    }

    if(nameController.text.length == 0){
      valid = false;
      print("No name");
    }



    return valid;

  }


  final ImagePicker imagePicker = ImagePicker();
  List<XFile>? imageFileList = [];

  void selectImage() async {
    final XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);
    cropImage(image);
  }

  void cropImage(XFile? imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile!.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
      ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Utils.getThemeColorBlue(),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        ),
      ],
    );
    File file = await Utils.convertToJPGFileIfRequiredWithCompression(File(croppedFile!.path));

    final bytes = File(file!.path).readAsBytesSync();
    String base64Image =  base64Encode(bytes);
    farmSetup!.image = base64Image;
    modified = 1;
    setState((){});
  }

  Future<void> chooseCurrency() async {
    final allCurrencies = CurrencyService().getAll(); // Get built-in currencies
    final extraCurrencies = Utils.getMissingCurrency(); // Get missing currencies

    // Merge lists while ensuring no duplicate codes
    final Map<String, Currency> mergedMap = {
      for (var currency in allCurrencies) currency.code: currency, // Add existing currencies
      for (var currency in extraCurrencies) currency.code: currency, // Override with missing currencies
    };

    final List<Currency> mergedList = mergedMap.values.toList(); // Convert map back to list

    // 📌 Print all merged currencies
    print("✅ Merged Currency List:");
    for (var currency in mergedList) {
      print("${currency.code} - ${currency.name} (${currency.symbol})");
    }

    Currency? selected = await showCurrencyListDialog(context, mergedList);

    // Show dialog and wait for result
  //  Currency? selected = await showCurrencyListDialog(context, mergedList);

    if (selected != null) {
      print("Selected: ${selected.name} (${selected.code})");
      selectedCurrency = selected.symbol;
      DatabaseHelper.updateCurrency(selectedCurrency);
      Utils.currency = selectedCurrency;
      setState(() {}); // UI update happens after selection
      Utils.showToast("SUCCESSFUL".tr());
    }

   /* showCurrencyPicker(
      context: context,
      showFlag: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      onSelect: (Currency currency) {
        print("Selected: ${currency.name} (${currency.code})");
        selectedCurrency = currency.symbol;
        DatabaseHelper.updateCurrency(selectedCurrency);
        Utils.currency = selectedCurrency;
        setState(() {});
        Utils.showToast("SUCCESSFUL".tr());
      },
      currencyFilter: mergedList.map((c) => c.code).toList(), // Ensure IRR & others are included
    );*/
  }



}




class CustomCurrencyService extends CurrencyService {
  @override
  List<Currency> getAll() {
    final allCurrencies = super.getAll();

    // Ensure IRR is not duplicated
    if (!allCurrencies.any((c) => c.code == "IRR")) {
      allCurrencies.add(Currency(
        code: "IRR",
        name: "Iranian Rial",
        symbol: "﷼",
        flag: "IR",  // Ensure this matches the internal flag system
        decimalDigits: 0,
        number: 364,
        namePlural: "Iranian Rials",
        thousandsSeparator: ",",
        decimalSeparator: ".",
        spaceBetweenAmountAndSymbol: true,
        symbolOnLeft: false,
      ));
    }

    return allCurrencies;
  }
}


Future<Currency?> showCurrencyListDialog(BuildContext context, List<Currency> currencies) async {
  return await showDialog<Currency>(
    context: context,
    builder: (BuildContext context) {
      return _CurrencyPickerDialog(currencies: currencies);
    },
  );
}

class _CurrencyPickerDialog extends StatefulWidget {
  final List<Currency> currencies;
  const _CurrencyPickerDialog({Key? key, required this.currencies}) : super(key: key);

  @override
  State<_CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<_CurrencyPickerDialog> {
  late TextEditingController _searchController;
  late List<Currency> _filteredCurrencies;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredCurrencies = widget.currencies;
  }

  void _filterCurrencies(String query) {
    setState(() {
      _filteredCurrencies = widget.currencies
          .where((currency) =>
      currency.name.toLowerCase().contains(query.toLowerCase()) ||
          currency.code.toLowerCase().contains(query.toLowerCase()) ||
          currency.symbol.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        children: [
          const Text("Select Currency"),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search currency...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: _filterCurrencies,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: _filteredCurrencies.length,
          itemBuilder: (context, index) {
            final currency = _filteredCurrencies[index];
            return ListTile(
              leading: CircleAvatar(child: Text(currency.code.substring(0, 2))),
              title: Text("${currency.name} (${currency.code})"),
              subtitle: Text(currency.symbol),
              onTap: () => Navigator.pop(context, currency),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Close"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

