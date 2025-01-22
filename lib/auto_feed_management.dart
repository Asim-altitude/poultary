import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:poultary/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/databse_helper.dart';
import 'model/flock.dart';
import 'model/sub_category_item.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AutomaticFeedManagementScreen extends StatefulWidget {
  @override
  _AutomaticFeedManagementScreenState createState() => _AutomaticFeedManagementScreenState();
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();


class _AutomaticFeedManagementScreenState extends State<AutomaticFeedManagementScreen> {
  bool isAutoFeedEnabled = false;
  List<AutomaticFeedSetting> automaticFeedFlocks = [];
  List<String> _feedList = [];
  List<Flock> flocks = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> initNotificationsSettings() async {

    try {
      WidgetsFlutterBinding.ensureInitialized();

      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings(
          '@mipmap/ic_launcher'); // Replace with your app icon
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      tz.initializeTimeZones();
    }
    catch(ex){
      print(ex);
    }
  }

  Future<void> _initializeData() async {
    await DatabaseHelper.instance.database;
    _feedList = await _fetchFeedList();
    flocks = await DatabaseHelper.getFlocks();
    print("FLOCKS ${flocks.length}");
    await _loadFlockSettings();
    await initNotificationsSettings();
  }

  Future<List<String>> _fetchFeedList() async {
    List<SubItem> subItemList = await DatabaseHelper.getSubCategoryList(3);
    List<String> feedList = ["Not Specified"];
    feedList.addAll(subItemList.map((item) => item.name ?? "Unknown"));
    return feedList;
  }

  Future<void> _loadFlockSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? flocksJson = prefs.getString('flockSettings');

    if (flocksJson != null) {
      List<AutomaticFeedSetting> savedSettings = (json.decode(flocksJson) as List)
          .map((e) => AutomaticFeedSetting.fromJson(e))
          .toList();

      // Sync saved settings with current flocks
      setState(() {
        automaticFeedFlocks = flocks.map((flock) {
          AutomaticFeedSetting? savedSetting = savedSettings.firstWhere(
                (setting) => setting.id == flock.f_id,
            orElse: () => AutomaticFeedSetting(
              id: flock.f_id,
              name: flock.f_name,
              feedSettings: _generateDefaultFeedSettings(),
            ),
          );

          return AutomaticFeedSetting(
            id: flock.f_id,
            name: flock.f_name,
            feedSettings: savedSetting.feedSettings,
          );
        }).toList();
      });
    } else {
      // Initialize feed settings for each flock if no saved settings found
      setState(() {
        automaticFeedFlocks = flocks.map((flock) => AutomaticFeedSetting(
          id: flock.f_id,
          name: flock.f_name,
          feedSettings: _generateDefaultFeedSettings(), // Define your default feed settings function
        )).toList();
      });
    }

    // Load the isAutoFeedEnabled state
    setState(() {
      isAutoFeedEnabled = prefs.getBool('isAutoFeedEnabled') ?? false;
      String? savedDate = prefs.getString("lastSyncDate");
      print('SAVED_DATE $savedDate');

      if (savedDate != null) {
        _startingDate = DateTime.parse(savedDate); // Parse the string to DateTime
      }

    });
  }

  Future<void> _saveFlockSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String flocksJson = json.encode(automaticFeedFlocks.map((e) => e.toJson()).toList());
    // Save the isAutoFeedEnabled state
    await prefs.setBool('isAutoFeedEnabled', isAutoFeedEnabled);
    await prefs.setString('flockSettings', flocksJson);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved successfully!')),
    );

  }

  List<FeedSetting> _generateDefaultFeedSettings() {
    List<String> days = ["Mon", "Tues", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days.map((day) => FeedSetting(day: day, feedName: "Not Specified", dailyRequirement: "1")).toList();
  }

  DateTime? _startingDate; // Track the selected starting date


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Utils.getThemeColorBlue(),
        title: Text(
          'Automatic Feed Management',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Toggle Switch
          SwitchListTile(
            title: Text(
              'Turn On/Off',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            value: isAutoFeedEnabled,
            activeColor: Utils.getThemeColorBlue(),
            onChanged: (value) async {
              setState(() {
                isAutoFeedEnabled = value;
              });
              _saveFlockSettings();

              /*if (isAutoFeedEnabled) {
                await requestNotificationPermissions();
                await scheduleDailyNotification();
              } else {
                await flutterLocalNotificationsPlugin.cancel(1);
                // Cancels auto-feed notification with ID 1
              }*/
            },
          ),

          // Show Starting Date Picker if isAutoFeedEnabled is true
          if (isAutoFeedEnabled)
            Column(
              children: [
                Text(
                  "Automatic Daily Feed Records will be generated.",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0,top: 8),
                  child: Row(
                    children: [
                      Text(
                        "Last Sync:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _startingDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _startingDate = pickedDate;
                              });
                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.setString('lastSyncDate', pickedDate.toIso8601String());

                            }
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              _startingDate != null
                                  ? "${_startingDate!.day}-${_startingDate!.month}-${_startingDate!.year}"
                                  : "Select Date",
                              style: TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          // Flock List
          Expanded(
            child: ListView.builder(
              itemCount: automaticFeedFlocks.length,
              itemBuilder: (context, index) {
                final flock = automaticFeedFlocks[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  elevation: 3,
                  child: ExpansionTile(
                    title: Text(
                      flock.name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Utils.getThemeColorBlue()),
                    ),
                    subtitle: Text(
                      "Expand to customize feed",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey),
                    ),
                    children: [
                      // Labels Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                'Day',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Feed',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Qty (kg)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Dynamic Feed Settings List
                      ...flock.feedSettings.map((setting) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              // Day Column
                              Expanded(
                                flex: 1,
                                child: Text(
                                  setting.day,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ),
                              // Feed Dropdown
                              Expanded(
                                flex: 3,
                                child: Container(
                                  height: 48,
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: setting.feedName,
                                      isExpanded: true,
                                      icon: Icon(Icons.arrow_drop_down, color: Utils.getThemeColorBlue()),
                                      items: _feedList.map((feed) {
                                        return DropdownMenuItem(
                                          value: feed,
                                          child: Text(
                                            feed,
                                            style: TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis, // Handle long text
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: isAutoFeedEnabled
                                          ? (value) {
                                        setState(() {
                                          setting.feedName = value!;
                                        });
                                      }
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              // Qty Text Field
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 48,
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Qty',
                                      border: InputBorder.none,
                                    ),
                                    controller: TextEditingController.fromValue(
                                      TextEditingValue(
                                        text: setting.dailyRequirement,
                                        selection: TextSelection.collapsed(offset: setting.dailyRequirement.length),
                                      ),
                                    ),
                                    onChanged: isAutoFeedEnabled
                                        ? (value) {
                                      setState(() {
                                        setting.dailyRequirement = value;
                                      });
                                    }
                                        : null,
                                    enabled: isAutoFeedEnabled,
                                    style: TextStyle(fontSize: 16),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(3),
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
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
          onPressed: () {
            if(isAutoFeedEnabled){
              _saveFlockSettings();
            }
          },
          style: ElevatedButton.styleFrom(
            elevation: 5,
            backgroundColor: isAutoFeedEnabled ? Utils.getThemeColorBlue() : Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.save,
                color: isAutoFeedEnabled ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Save Settings',
                style: TextStyle(
                  color: isAutoFeedEnabled ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  /// Schedules daily notifications
  Future<void> scheduleDailyNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'auto_feed_channel',
      'Auto Feed Notifications',
      channelDescription: 'Notifications for automatic feed management',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'New Feed Records Ready',
      'New feed records are Ready. Check them now!',
      _nextInstanceOfTime(8, 0),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> requestNotificationPermissions() async {
    if (await Permission.notification.isGranted) {
      print('Notification permissions already granted');
      return;
    }

    final PermissionStatus status = await Permission.notification.request();
    if (status.isGranted) {
      print('Notification permissions granted');
    } else {
      print('Notification permissions denied');
    }
  }

}

class AutomaticFeedSetting {
  final int id; // Add flock ID
  final String name;
  final List<FeedSetting> feedSettings;

  AutomaticFeedSetting({required this.id, required this.name, required this.feedSettings});

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'feedSettings': feedSettings.map((e) => e.toJson()).toList(),
  };

  // Create from JSON
  factory AutomaticFeedSetting.fromJson(Map<String, dynamic> json) => AutomaticFeedSetting(
    id: json['id'] ?? 0, // Handle null ID gracefully
    name: json['name'],
    feedSettings: (json['feedSettings'] as List)
        .map((e) => FeedSetting.fromJson(e))
        .toList(),
  );
}


class FeedSetting {
  final String day;
  String feedName;
  String dailyRequirement;

  FeedSetting({
    required this.day,
    required this.feedName,
    required this.dailyRequirement,
  });

  Map<String, dynamic> toJson() => {
    'day': day,
    'feedName': feedName,
    'dailyRequirement': dailyRequirement,
  };

  factory FeedSetting.fromJson(Map<String, dynamic> json) => FeedSetting(
    day: json['day'],
    feedName: json['feedName'],
    dailyRequirement: json['dailyRequirement'],
  );

}
