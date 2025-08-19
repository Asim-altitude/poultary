import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:poultary/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database/databse_helper.dart';
import 'model/flock.dart';

// Automatic Egg Collection Settings Model
class AutomaticEggCollectionSetting {
  int flockId;
  List<EggSetting> eggSettings;

  AutomaticEggCollectionSetting({
    required this.flockId,
    required this.eggSettings,
  });

  Map<String, dynamic> toJson() => {
    'flockId': flockId,
    'eggSettings': eggSettings.map((e) => e.toJson()).toList(),
  };

  factory AutomaticEggCollectionSetting.fromJson(Map<String, dynamic> json) {
    return AutomaticEggCollectionSetting(
      flockId: json['flockId'],
      eggSettings: (json['eggSettings'] as List)
          .map((e) => EggSetting.fromJson(e))
          .toList(),
    );
  }
}

class EggSetting {
  String day;
  int goodEggs;
  int badEggs;

  EggSetting({
    required this.day,
    required this.goodEggs,
    required this.badEggs,
  });

  Map<String, dynamic> toJson() => {
    'day': day,
    'goodEggs': goodEggs,
    'badEggs': badEggs,
  };

  factory EggSetting.fromJson(Map<String, dynamic> json) {
    return EggSetting(
      day: json['day'],
      goodEggs: json['goodEggs'],
      badEggs: json['badEggs'],
    );
  }
}

class AutomaticEggCollectionScreen extends StatefulWidget {
  @override
  _AutomaticEggCollectionScreenState createState() => _AutomaticEggCollectionScreenState();
}

class _AutomaticEggCollectionScreenState extends State<AutomaticEggCollectionScreen> {
  bool isAutoEggCollectionEnabled = false;
  List<AutomaticEggCollectionSetting> automaticEggSettings = [];
  List<Flock> flocks = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    flocks = await DatabaseHelper.getFlocks(); // Fetch flocks from the database
    await _loadEggCollectionSettings();
  }

  Future<void> _loadEggCollectionSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? settingsJson = prefs.getString('eggCollectionSettings');
    setState(() {
      isAutoEggCollectionEnabled = prefs.getBool('isAutoEggCollectionEnabled') ?? false;
    });
    if (settingsJson != null) {
      setState(() {
        automaticEggSettings = (json.decode(settingsJson) as List)
            .map((e) => AutomaticEggCollectionSetting.fromJson(e))
            .toList();
      });
    } else {
      // Initialize settings for each flock
      automaticEggSettings = flocks.map((flock) {
        return AutomaticEggCollectionSetting(
          flockId: flock.f_id,
          eggSettings: List.generate(7, (index) {
            return EggSetting(
              day: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index],
              goodEggs: 0,
              badEggs: 0,
            );
          }),
        );
      }).toList();
    }
  }

  Future<void> _saveEggCollectionSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String settingsJson = json.encode(automaticEggSettings.map((e) => e.toJson()).toList());
    await prefs.setString('eggCollectionSettings', settingsJson);
    await prefs.setBool('isAutoEggCollectionEnabled', isAutoEggCollectionEnabled);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Utils.getThemeColorBlue(),
          title: Text('Automatic Egg Collection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),),
        ),
        body: Column(
          children: [
            // Toggle Switch
            SwitchListTile(
              title: Text(
                'Turn On/Off',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              value: isAutoEggCollectionEnabled,
              activeColor: Utils.getThemeColorBlue(),
              onChanged: (value) {
                setState(() {
                  isAutoEggCollectionEnabled = value;
                });
                _saveEggCollectionSettings();
              },
            ),
            // Flock List
            Expanded(
              child: ListView.builder(
                itemCount: flocks.length,
                itemBuilder: (context, index) {
                  final flock = flocks[index];
                  final settings = automaticEggSettings.firstWhere((s) => s.flockId == flock.f_id);
      
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Card(
                      elevation: 5,
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('${flock.f_name}', style: TextStyle(fontWeight: FontWeight.bold,color: Utils.getThemeColorBlue())),
                          ),
                          // ExpansionTile for each flock's egg settings
                          ExpansionTile(
                            title: Text('Egg Collection'),
                            children: settings.eggSettings.map((setting) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                child: Row(
                                  children: [
                                    // Day Label
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        setting.day,
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    SizedBox(width: 8),
      
                                    // Good Eggs Field
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: TextField(
                                          decoration: InputDecoration(
                                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                            hintText: 'Good Eggs',
                                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                                            border: InputBorder.none,
                                          ),
                                          keyboardType: TextInputType.number,
                                          controller: TextEditingController.fromValue(
                                            TextEditingValue(
                                              text: setting.goodEggs.toString(),
                                              selection: TextSelection.collapsed(offset: setting.goodEggs.toString().length),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              setting.goodEggs = int.tryParse(value) ?? 0;
                                            });
                                          },
                                          enabled: isAutoEggCollectionEnabled,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
      
                                    // Bad Eggs Field
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: TextField(
                                          decoration: InputDecoration(
                                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                            hintText: 'Bad Eggs',
                                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                                            border: InputBorder.none,
                                          ),
                                          keyboardType: TextInputType.number,
                                          controller: TextEditingController.fromValue(
                                            TextEditingValue(
                                              text: setting.badEggs.toString(),
                                              selection: TextSelection.collapsed(offset: setting.badEggs.toString().length),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              setting.badEggs = int.tryParse(value) ?? 0;
                                            });
                                          },
                                          enabled: isAutoEggCollectionEnabled,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
      
                                    // Total Eggs Field (Read-Only)
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Total: ${setting.goodEggs + setting.badEggs}',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: isAutoEggCollectionEnabled ? _saveEggCollectionSettings : null,
            style: ElevatedButton.styleFrom(
              elevation: 5,
              backgroundColor: isAutoEggCollectionEnabled
                  ? Utils.getThemeColorBlue()
                  : Colors.grey.shade300,  // Button color based on state
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),  // Rounded corners
              ),
              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.save,
                  color: isAutoEggCollectionEnabled
                      ? Colors.white
                      : Colors.grey.shade600,  // Icon color based on state
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Save Settings',
                  style: TextStyle(
                    color: isAutoEggCollectionEnabled
                        ? Colors.white
                        : Colors.grey.shade600,  // Text color based on state
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      
      
      ),
    );
  }
}
