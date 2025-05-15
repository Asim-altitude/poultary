import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/home_screen.dart';
import 'package:poultary/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auto_feed_management.dart';
import 'database/databse_helper.dart';
import 'model/feed_item.dart';

class AutoFeedSyncScreen extends StatefulWidget {
  @override
  _AutoFeedSyncScreenState createState() => _AutoFeedSyncScreenState();
}

class _AutoFeedSyncScreenState extends State<AutoFeedSyncScreen> {
  bool isAutoFeedEnabled = false;
  DateTime? lastSyncDate;
  List<AutomaticFeedSetting> automaticFeedSettings = [];
  List<Feeding> pendingFeedRecords = [];  // Tracks pending feeding records

  @override
  void initState() {
    super.initState();
    _checkAutoFeedSettings();
  }

  Future<DateTime?> getLastSyncDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? dateString = prefs.getString('lastSyncDate');
    if (dateString != null) {
      return DateTime.parse(dateString); // Convert ISO 8601 string to DateTime
    }
    return null; // No sync date found
  }

  // Check if automatic feed management is enabled and retrieve last sync date
  Future<void> _checkAutoFeedSettings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      isAutoFeedEnabled = prefs.getBool('isAutoFeedEnabled') ?? false;
      lastSyncDate = await getLastSyncDate();
      print('LAST_SYNC $lastSyncDate');

      // Load the feed settings from SharedPreferences
     await _loadFeedSettings();

      // If auto feed is enabled, sync the feeding records
      if (isAutoFeedEnabled) {
       await _syncFeedingRecords();
      } else {
        // Skip to the next screen if auto feed is not enabled
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );// Adjust this as needed
      }
    }
    catch(ex){
      print(ex);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  // Load feed settings from SharedPreferences
  Future<void> _loadFeedSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? settingsJson = prefs.getString('flockSettings');
    print("SETTINGS $settingsJson");
    if (settingsJson != null) {
      List<AutomaticFeedSetting> savedSettings = (json.decode(settingsJson) as List)
          .map((e) => AutomaticFeedSetting.fromJson(e))
          .toList();

      setState(() {
        automaticFeedSettings = savedSettings;
      });
      print("SETTINGS $automaticFeedSettings");
    }
  }

  String _getDayName(int index) {
    List<String> days = [
      "Mon",
      "Tues",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun",
    ];
    return days[index];
  }

  // Sync feeding records and track pending records
  Future<void> _syncFeedingRecords() async {
    try {
      // Ensure lastSyncDate is not null; default to 30 days ago if missing
      DateTime currentDate = DateTime.now();
      currentDate = DateTime(currentDate.year, currentDate.month, currentDate.day); // Truncate to midnight
      DateTime startSyncDate = lastSyncDate ?? currentDate.subtract(const Duration(days: 5));
      startSyncDate = DateTime(startSyncDate.year, startSyncDate.month, startSyncDate.day); // Truncate to midnight

      print("LAST_SYNC: $startSyncDate");
      print("CURRENT: $currentDate");

      // Iterate over all AutomaticFeedSettings
      for (var setting in automaticFeedSettings) {
        // Iterate from lastSyncDate to currentDate
        for (DateTime date = startSyncDate.add(const Duration(days: 1));
        !date.isAfter(currentDate); // Inclusive condition
        date = date.add(const Duration(days: 1))) {

          // Get the day of the week (Monday = 1, Sunday = 7)
          int weekday = date.weekday - 1; // Adjust to 0-based index

          if (setting.isTwiceADay) {
            // Generate two feeding records if Twice a Day is enabled
            FeedSetting? morningFeedSetting = setting.morningFeedSettings.firstWhereOrNull(
                  (fs) => fs.day == _getDayName(weekday),
            );

            FeedSetting? eveningFeedSetting = setting.eveningFeedSettings.firstWhereOrNull(
                  (fs) => fs.day == _getDayName(weekday),
            );

            if (morningFeedSetting != null) {
              String formattedDate = DateFormat('yyyy-MM-dd').format(date);
              Feeding morningFeeding = Feeding(
                f_id: setting.id,
                f_name: setting.name,
                feed_name: morningFeedSetting.feedName,
                quantity: morningFeedSetting.dailyRequirement,
                date: formattedDate,
                short_note: 'Automatically added morning feed for $formattedDate',
              );
              print("Morning Feeding: F_ID ${morningFeeding.f_id}, date ${morningFeeding.date}, qty ${morningFeeding.quantity}, f_name ${morningFeeding.f_name}");
              setState(() {
                pendingFeedRecords.add(morningFeeding);
              });
            }

            if (eveningFeedSetting != null) {
              String formattedDate = DateFormat('yyyy-MM-dd').format(date);
              Feeding eveningFeeding = Feeding(
                f_id: setting.id,
                f_name: setting.name,
                feed_name: eveningFeedSetting.feedName,
                quantity: eveningFeedSetting.dailyRequirement,
                date: formattedDate,
                short_note: 'Automatically added evening feed for $formattedDate',
              );
              print("Evening Feeding: F_ID ${eveningFeeding.f_id}, date ${eveningFeeding.date}, qty ${eveningFeeding.quantity}, f_name ${eveningFeeding.f_name}");
              setState(() {
                pendingFeedRecords.add(eveningFeeding);
              });
            }
          } else {
            // Generate a single feeding record if Twice a Day is off (Once a Day)
            FeedSetting? feedSetting = setting.feedSettings.firstWhereOrNull(
                  (fs) => fs.day == _getDayName(weekday),
            );

            if (feedSetting != null) {
              String formattedDate = DateFormat('yyyy-MM-dd').format(date);
              Feeding newFeeding = Feeding(
                f_id: setting.id,
                f_name: setting.name,
                feed_name: feedSetting.feedName,
                quantity: feedSetting.dailyRequirement,
                date: formattedDate,
                short_note: 'Automatically added feed for $formattedDate',
              );
              print("Once a Day Feeding: F_ID ${newFeeding.f_id}, date ${newFeeding.date}, qty ${newFeeding.quantity}, f_name ${newFeeding.f_name}");
              setState(() {
                pendingFeedRecords.add(newFeeding);
              });
            }
          }
        }
      }

      // If no pending records are created, navigate to the HomeScreen
      if (pendingFeedRecords.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      print('Error syncing feeding records: $e');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  // Save all pending feed records to the database
  Future<void> _savePendingRecords() async {
    await DatabaseHelper.instance.database;

    for (var feeding in pendingFeedRecords) {
      print("Feeding Record $feeding");
      await DatabaseHelper.insertNewFeeding(feeding);
    }

    // Clear the pending records list after saving
    setState(() {
      pendingFeedRecords.clear();
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime now = DateTime.now();
    print("LAST_SYNC $now");
    await prefs.setString('lastSyncDate', now.toIso8601String());

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pending feed records saved successfully!'.tr())),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // Edit feed record (feed name or quantity)
  void _editFeedRecord(int index) async {
    TextEditingController feedNameController =
    TextEditingController(text: pendingFeedRecords[index].feed_name);
    TextEditingController quantityController =
    TextEditingController(text: pendingFeedRecords[index].quantity);

    // Show a dialog to edit feed name and quantity
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Feed Record'.tr()),
          content: Column(
            children: [
              TextField(
                controller: feedNameController,
                decoration: InputDecoration(labelText: 'Feed Name'.tr()),
              ),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity'.tr()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  pendingFeedRecords[index].feed_name =
                      feedNameController.text;
                  pendingFeedRecords[index].quantity =
                      quantityController.text;
                });
                Navigator.of(context).pop();
              },
              child: Text('SAVE'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('CANCEL'.tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20.0), // Round bottom-left corner
            bottomRight: Radius.circular(20.0), // Round bottom-right corner
          ),
          child: AppBar(
            title: Text(
              "Auto Feed Sync".tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Utils.getThemeColorBlue(), // Customize the color
            elevation: 8, // Gives it a more elevated appearance
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context); // Navigates back
              },
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: pendingFeedRecords.isEmpty
                  ?  Center(child: Text('No Records'.tr()))
                  : ListView.builder(
                itemCount: pendingFeedRecords.length,
                itemBuilder: (context, index) {
                  Feeding record = pendingFeedRecords[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${record.f_name.tr()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      _editFeedRecord(index);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _deleteFeedRecord(index);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '${record.feed_name?.tr()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text("Quantity".tr()+": ${record.quantity}"+Utils.selected_unit.tr()),
                          const SizedBox(height: 8),
                          Text("DATE".tr()+": ${Utils.getFormattedDate(record.date!)}"),
                          const SizedBox(height: 8),
                          Text(
                            '${record.short_note}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                     _showSkipWarningDialog();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      side: BorderSide(color: Utils.getThemeColorBlue(), width: 2.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child:  Text(
                      'Skip'.tr(),
                      style: TextStyle(fontSize: 16.0, color: Utils.getThemeColorBlue()),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                // Save Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _savePendingRecords();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      backgroundColor: Utils.getThemeColorBlue(),
                      elevation: 4.0,
                    ),
                    child: Text(
                      'SAVE'.tr(),
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _showSkipWarningDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Text(
                'Warning: Manual Entry Required'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
               Text(
                'manual_feed_msg'.tr(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey, // Optional: Warning color
                    ),
                    child:  Text('CANCEL'.tr(), style: TextStyle(color: Colors.white),),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      _skipAction(); // Call the skip function
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Utils.getThemeColorBlue(), // Optional: Success color
                    ),
                    child:  Text('Skip Anyway'.tr(), style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _skipAction() {
    // Add the logic for skipping here
    print("User chose to skip. Proceed with skipping...");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _deleteFeedRecord(int index) {
    setState(() {
      pendingFeedRecords.removeAt(index);
    });
  }

}
