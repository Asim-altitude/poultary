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
      DateTime startSyncDate = lastSyncDate ?? currentDate.subtract(const Duration(days: 30));
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

          // Find the feed setting for the specific day
          FeedSetting? feedSetting = setting.feedSettings.firstWhereOrNull(
                (fs) => fs.day == _getDayName(weekday),
          );

          if (feedSetting != null) {
            // Proceed with adding the feeding record
            String formattedDate = DateFormat('yyyy-MM-dd').format(date);
            Feeding newFeeding = Feeding(
              f_id: setting.id,
              f_name: setting.name,
              feed_name: feedSetting.feedName,
              quantity: feedSetting.dailyRequirement,
              date: formattedDate,
              short_note: 'Automatically added feed for $formattedDate',
            );
            print("F_ID ${newFeeding.f_id} date ${newFeeding.date} qty ${newFeeding.quantity} f_name ${newFeeding.f_name}");
            // Add the new feeding record
            setState(() {
              pendingFeedRecords.add(newFeeding);
            });
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
      SnackBar(content: Text('Pending feed records saved successfully!')),
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
          title: Text('Edit Feed Record'),
          content: Column(
            children: [
              TextField(
                controller: feedNameController,
                decoration: InputDecoration(labelText: 'Feed Name'),
              ),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
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
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Feed Sync'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: pendingFeedRecords.isEmpty
                  ? const Center(child: Text('No Records'))
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
                                '${record.feed_name}',
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
                            '${record.f_name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Quantity: ${record.quantity} kg'),
                          const SizedBox(height: 8),
                          Text('Date: ${Utils.getFormattedDate(record.date!)}'),
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      side: BorderSide(color: Theme.of(context).primaryColor, width: 2.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(fontSize: 16.0),
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
                      backgroundColor: Theme.of(context).primaryColor,
                      elevation: 4.0,
                    ),
                    child: const Text(
                      'Save',
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

  void _deleteFeedRecord(int index) {
    setState(() {
      pendingFeedRecords.removeAt(index);
    });
  }

}
