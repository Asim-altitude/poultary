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
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:poultary/sticky.dart';
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



  @override
  void dispose() {
    super.dispose();

  }

  String _purposeselectedValue = "";
  String _reductionReasonValue = "";


  int chosen_index = 0;

  @override
  void initState() {
    super.initState();

    getInfo();
    Utils.setupAds();

  }

  FarmSetup? farmSetup = null;
  void getInfo() async {

    await DatabaseHelper.instance.database;
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
        bottomNavigationBar: Container(
          height: 60,
          margin: EdgeInsets.all(15),
          child: ElevatedButton(
            onPressed: () {
              // Your button action here
              if (checkValidation())
              {
                if(!nameController.text.isEmpty) {
                  farmSetup!.name = nameController.text;
                }

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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
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
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Utils.getThemeColorBlue().withOpacity(0.9), Utils.getThemeColorBlue()],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: Row(
                        children: [
                          /// Back Button
                          InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.15),
                              ),
                              child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                            ),
                          ),

                          /// Title
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 12),
                              child: Text(
                                "FARM_SETUP".tr(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),


                        ],
                      ),
                    ),
                  ),
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
                                  width: 160,
                                  height: 160,
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
                                        Icon(Icons.camera_alt, color: Colors.white, size: 15),
                                        SizedBox(width: 6),
                                        Text("Tap to change".tr(), style: TextStyle(color: Colors.white, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                    
                        // 📝 Farm Name Input Field
                        _buildInputField(label: "FARM_NAME", controller: nameController, hint: "Enter farm name"),
                    
                        // 💰 Currency Selection
                        _buildDropdownField(label: "CURRENCY", value: selectedCurrency, onTap: chooseCurrency),
                    
                        // 📅 Date Picker
                        _buildDropdownField(label: "Farm Setup Date", value: date, onTap: pickDate),
                        
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
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
    final bytes = File(croppedFile!.path).readAsBytesSync();
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

