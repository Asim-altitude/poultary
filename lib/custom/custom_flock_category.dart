import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/model/custom_category.dart';

import '../utils/utils.dart';

class CustomCategoryScreen extends StatefulWidget {
  CustomCategory? customCategory;
  CustomCategoryScreen({Key? key, required this.customCategory}) : super(key: key);

  @override
  _CustomCategoryScreenState createState() => _CustomCategoryScreenState();
}

class _CustomCategoryScreenState extends State<CustomCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shortNoteController = TextEditingController();

  bool isEdit = false;
  String _selectedType = 'Consumption';
  String? _selectedCategoryType;
  String? _selectedUnit;
  IconData? _selectedIcon = Icons.android;

  List<String> categoryTypes = ['Water Usage', 'Vitamin Usage','Manure',"Supplements"];
  List<String> units = ['kg', 'lbs', 'litre', 'grams', 'ml', 'pieces'];
  List<IconData> availableIcons = [
    Icons.access_alarm,
    Icons.accessibility,
    Icons.account_balance,
    Icons.account_circle,
    Icons.add_a_photo,
    Icons.airplanemode_active,
    Icons.alarm,
    Icons.all_inclusive,
    Icons.anchor,
    Icons.android,
    Icons.apartment,
    Icons.architecture,
    Icons.attach_money,
    Icons.audiotrack,
    Icons.auto_awesome,
    Icons.backup,
    Icons.bakery_dining,
    Icons.battery_charging_full,
    Icons.beach_access,
    Icons.biotech,
    Icons.bolt,
    Icons.book,
    Icons.brush,
    Icons.bubble_chart,
    Icons.build,
    Icons.bungalow,
    Icons.business,
    Icons.cabin,
    Icons.cake,
    Icons.calculate,
    Icons.camera,
    Icons.campaign,
    Icons.car_repair,
    Icons.cast,
    Icons.category,
    Icons.cell_tower,
    Icons.chair,
    Icons.check_circle,
    Icons.clean_hands,
    Icons.cloud,
    Icons.code,
    Icons.commute,
    Icons.construction,
    Icons.coronavirus,
    Icons.credit_card,
    Icons.cruelty_free,
    Icons.dashboard,
    Icons.data_saver_off,
    Icons.delete,
    Icons.directions_bike,
    Icons.directions_boat,
    Icons.directions_bus,
    Icons.directions_car,
    Icons.directions_railway,
    Icons.directions_walk,
    Icons.diversity_1,
    Icons.dns,
    Icons.document_scanner,
    Icons.donut_large,
    Icons.download,
    Icons.eco,
    Icons.electric_bike,
    Icons.electric_car,
    Icons.electric_rickshaw,
    Icons.electric_scooter,
    Icons.electrical_services,
    Icons.elevator,
    Icons.email,
    Icons.emoji_emotions,
    Icons.engineering,
    Icons.explore,
    Icons.extension,
    Icons.factory,
    Icons.fastfood,
    Icons.favorite,
    Icons.fitness_center,
    Icons.flag,
    Icons.flash_on,
    Icons.flight,
    Icons.food_bank,
    Icons.forest,
    Icons.format_paint,
    Icons.foundation,
    Icons.free_breakfast,
    Icons.front_hand,
    Icons.gavel,
    Icons.gesture,
    Icons.grass,
    Icons.groups,
    Icons.handyman,
    Icons.healing,
    Icons.health_and_safety,
    Icons.hiking,
    Icons.home,
    Icons.hotel,
    Icons.hourglass_bottom,
    Icons.icecream,
    Icons.import_contacts,
    Icons.info,
    Icons.insights,
    Icons.inventory,
    Icons.iron,
    Icons.kitchen,
    Icons.label,
    Icons.landscape,
    Icons.language,
    Icons.laptop,
    Icons.leaderboard,
    Icons.library_books,
    Icons.local_activity,
    Icons.local_bar,
    Icons.local_cafe,
    Icons.local_dining,
    Icons.local_drink,
    Icons.local_florist,
    Icons.local_gas_station,
    Icons.local_grocery_store,
    Icons.local_hospital,
    Icons.local_laundry_service,
    Icons.local_library,
    Icons.local_mall,
    Icons.local_movies,
    Icons.local_offer,
    Icons.local_parking,
    Icons.local_pharmacy,
    Icons.local_police,
    Icons.local_post_office,
    Icons.local_shipping,
    Icons.local_taxi,
    Icons.lock,
    Icons.luggage,
    Icons.lunch_dining,
    Icons.maps_home_work,
    Icons.masks,
    Icons.military_tech,
    Icons.monetization_on,
    Icons.motorcycle,
    Icons.museum,
    Icons.music_note,
    Icons.nature,
    Icons.nature_people,
    Icons.nightlife,
    Icons.no_drinks,
    Icons.no_food,
    Icons.no_meals,
    Icons.no_transfer,
    Icons.park,
    Icons.pedal_bike,
    Icons.person,
    Icons.pets,
    Icons.phone,
    Icons.photo_camera,
    Icons.plumbing,
    Icons.precision_manufacturing,
    Icons.public,
    Icons.push_pin,
    Icons.ramen_dining,
    Icons.recycling,
    Icons.restaurant,
    Icons.rice_bowl,
    Icons.rocket_launch,
    Icons.room_service,
    Icons.router,
    Icons.safety_divider,
    Icons.sanitizer,
    Icons.satellite,
    Icons.savings,
    Icons.science,
    Icons.scuba_diving,
    Icons.security,
    Icons.self_improvement,
    Icons.shield,
    Icons.shopping_cart,
    Icons.sledding,
    Icons.snowboarding,
    Icons.snowmobile,
    Icons.solar_power,
    Icons.soup_kitchen,
    Icons.spa,
    Icons.speed,
    Icons.sports_basketball,
    Icons.sports_cricket,
    Icons.sports_esports,
    Icons.sports_football,
    Icons.sports_golf,
    Icons.sports_handball,
    Icons.sports_hockey,
    Icons.sports_kabaddi,
    Icons.sports_mma,
    Icons.sports_motorsports,
    Icons.sports_rugby,
    Icons.sports_soccer,
    Icons.sports_tennis,
    Icons.sports_volleyball,
    Icons.stairs,
    Icons.store,
    Icons.storefront,
    Icons.storm,
    Icons.surfing,
    Icons.tapas,
    Icons.theater_comedy,
    Icons.thermostat,
    Icons.tornado,
    Icons.toys,
    Icons.traffic,
    Icons.train,
    Icons.tram,
    Icons.transgender,
    Icons.travel_explore,
    Icons.trending_up,
    Icons.tsunami,
    Icons.umbrella,
    Icons.unarchive,
    Icons.vaccines,
    Icons.villa,
    Icons.visibility,
    Icons.volcano,
    Icons.wallet_travel,
    Icons.wash,
    Icons.water,
    Icons.water_drop,
    Icons.waterfall_chart,
    Icons.wb_sunny,
    Icons.weekend,
    Icons.wine_bar,
    Icons.yard,
  ];

  Future<void> _createCategory() async {
    if (_nameController.text.isEmpty || _selectedCategoryType == null ||
        _selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PROVIDE_ALL'.tr())),
      );
      return;
    }
    if(isEdit){
      widget.customCategory?.icon = _selectedIcon!;
      widget.customCategory?.name = _nameController.text;
      widget.customCategory?.cat_type = _selectedCategoryType!;
      widget.customCategory?.itemtype = _selectedType;
      widget.customCategory?.unit = _selectedUnit!;

     await DatabaseHelper.updateCategory(widget.customCategory!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SUCCESSFUL'.tr())),
      );
      Navigator.pop(context);

    } else {

      await DatabaseHelper.insertCustomCategory(CustomCategory(
          name: _nameController.text,
          itemtype: _selectedType,
          cat_type: _selectedCategoryType!,
          unit: _selectedUnit!,
          enabled: 1,
          icon: _selectedIcon!));

      // Display success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SUCCESSFUL'.tr())),
      );

      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if(widget.customCategory != null){
      isEdit = true;
      _selectedCategoryType = widget.customCategory!.cat_type;
      _selectedType = widget.customCategory!.itemtype;
      _selectedUnit = widget.customCategory!.unit;
      _selectedIcon = widget.customCategory!.icon;
      _nameController.text = widget.customCategory!.name;

      if(!checkIfContains(units,widget.customCategory!.unit)){
        units.add(_selectedUnit!);
      }

      if(!checkIfContains(categoryTypes,widget.customCategory!.cat_type)){
        categoryTypes.add(_selectedCategoryType!);
      }
    }

  }

  void _chooseIcon() {
    TextEditingController _searchController = new TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          constraints: BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
             /* TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search icon...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (query) => setState(() {}),
              ),
              SizedBox(height: 10),*/
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: availableIcons.where((icon) => icon.toString().toLowerCase().contains(_searchController.text.toLowerCase())).length,
                  itemBuilder: (context, index) {
                    var filteredIcons = availableIcons.where((icon) => icon.toString().toLowerCase().contains(_searchController.text.toLowerCase())).toList();
                    return IconButton(
                      icon: Icon(filteredIcons[index], size: 30),
                      onPressed: () {
                        setState(() => _selectedIcon = filteredIcons[index]);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(isEdit?'Edit Category'.tr():'Create Category'.tr(), style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Utils.getThemeColorBlue(),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on tap
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(_selectedIcon ?? Icons.category, size: 50, color: Utils.getThemeColorBlue()),
                        onPressed: _chooseIcon,
                      ),
                      Text('Tap to change icon'.tr(), style: GoogleFonts.lato(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Category Name'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                SizedBox(height: 20),
                Text('Category Type'.tr(), style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = 'Consumption'),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _selectedType == 'Consumption' ? Utils.getThemeColorBlue() : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Consumption'.tr(),
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _selectedType == 'Consumption' ? Colors.white : Colors.black,
                              )),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = 'Collection'),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _selectedType == 'Collection' ? Utils.getThemeColorBlue() : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Collection'.tr(),
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _selectedType == 'Collection' ? Colors.white : Colors.black,
                              )),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategoryType,
                        hint: Text('Select Type'.tr()),
                        onChanged: (value) => setState(() => _selectedCategoryType = value),
                        items: categoryTypes.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        )).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    FloatingActionButton(
                      mini: true,
                      onPressed: _addCategoryType,
                      child: Icon(Icons.add, color: Colors.white),
                      backgroundColor: Utils.getThemeColorBlue(),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedUnit,
                        hint: Text('Select Unit'.tr()),
                        onChanged: (value) => setState(() => _selectedUnit = value),
                        items: units.map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        )).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    FloatingActionButton(
                      mini: true,
                      onPressed: _addUnit,
                      child: Icon(Icons.add, color: Colors.white),
                      backgroundColor: Utils.getThemeColorBlue(),
                    ),
                  ],
                ),

                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _createCategory(),
                    child: Text(isEdit?'Update'.tr():'Finish'.tr(), style: GoogleFonts.lato(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Utils.getThemeColorBlue(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

  }


  void _addCategoryType() {
    TextEditingController _newCategoryTypeController = new TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Category Type'),
        content: TextField(
          controller: _newCategoryTypeController,
          decoration: InputDecoration(hintText: 'Enter category type'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              String newCategory = _newCategoryTypeController.text.trim();
              if (newCategory.isNotEmpty) {
                if (!categoryTypes.contains(newCategory)) {
                  _selectedCategoryType = newCategory;
                  setState(() => categoryTypes.add(newCategory));
                  _newCategoryTypeController.clear();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Category type already exists')),
                  );
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addUnit() {
    TextEditingController _newUnitController = new TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Unit'),
        content: TextField(
          controller: _newUnitController,
          decoration: InputDecoration(hintText: 'Enter unit name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              String newUnit = _newUnitController.text.trim();
              if (newUnit.isNotEmpty) {
                if (!units.contains(newUnit)) {
                  _selectedUnit = newUnit;
                  setState(() => units.add(newUnit));
                  _newUnitController.clear();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Unit already exists')),
                  );
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  bool checkIfContains(List<String> list ,String unit) {
    bool contains = false;
    for(int i=0;i<list.length;i++){
      if(unit == list[i])
        {
          contains = true;
          break;
        }
    }

    return contains;
  }

}
