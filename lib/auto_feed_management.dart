import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
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
    List<String> feedList = ["Not Specified".tr()];
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

      setState(() {
        automaticFeedFlocks = flocks.map((flock) {
          AutomaticFeedSetting? savedSetting = savedSettings.firstWhere(
                (setting) => setting.id == flock.f_id,
            orElse: () => AutomaticFeedSetting(
              id: flock.f_id,
              name: flock.f_name,
              feedSettings: _generateDefaultFeedSettings(),
              morningFeedSettings: [], // Initialize for backward compatibility
              eveningFeedSettings: [], // Initialize for backward compatibility
            ),
          );

          return AutomaticFeedSetting(
            id: flock.f_id,
            name: flock.f_name,
            isTwiceADay: savedSetting.isTwiceADay,
            feedSettings: savedSetting.feedSettings,
            morningFeedSettings: savedSetting.morningFeedSettings.isEmpty
                ? _generateDefaultFeedSettings()
                : savedSetting.morningFeedSettings, // Populate default if empty
            eveningFeedSettings: savedSetting.eveningFeedSettings.isEmpty
                ? _generateDefaultFeedSettings()
                : savedSetting.eveningFeedSettings, // Populate default if empty
          );
        }).toList();
      });
    } else {
      setState(() {
        automaticFeedFlocks = flocks.map((flock) => AutomaticFeedSetting(
          id: flock.f_id,
          name: flock.f_name,
          feedSettings: _generateDefaultFeedSettings(),
          morningFeedSettings: [], // Initialize as empty list
          eveningFeedSettings: [], // Initialize as empty list
        )).toList();
      });
    }

    // Load the isAutoFeedEnabled state
    setState(() {
      isAutoFeedEnabled = prefs.getBool('isAutoFeedEnabled') ?? false;
      String? savedDate = prefs.getString("lastSyncDate");
      print('SAVED_DATE $savedDate');

      if (savedDate != null) {
        _startingDate = DateTime.parse(savedDate);
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
      SnackBar(content: Text('Settings saved successfully!'.tr())),
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
          'Automatic Feed Management'.tr(),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Toggle Switch
          SwitchListTile(
            title: Text(
              'Turn On/Off'.tr(),
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
                  "Automatic Daily Feed Records will be generated.".tr(),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0,top: 8),
                  child: Row(
                    children: [
                      Text(
                        "Last Sync:".tr(),
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
                                  : "Select Date".tr(),
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
                      "Expand to customize feed".tr(),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.grey),
                    ),
                    children: [
                      // Toggle Between Once and Twice a Day
                      SwitchListTile(
                        title: Text("Enable Twice a Day Feed".tr()),
                        value: flock.isTwiceADay,
                        onChanged: isAutoFeedEnabled
                            ? (value) {
                          setState(() {
                            flock.isTwiceADay = value;

                            // Initialize morning and evening feed settings if switching to Twice a Day
                            if (value) {
                              flock.morningFeedSettings ??= List.from(flock.feedSettings);
                              flock.eveningFeedSettings ??= _generateDefaultFeedSettings();
                            }
                          });
                        }
                            : null,
                      ),
                      // Show Tab View for Morning and Evening Feed Settings if Twice a Day is Enabled
                      if (flock.isTwiceADay)
                        DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              TabBar(
                                labelColor: Utils.getThemeColorBlue(),
                                unselectedLabelColor: Colors.grey,
                                indicatorColor: Utils.getThemeColorBlue(),
                                tabs: [
                                  Tab(text: "Morning Feed".tr()),
                                  Tab(text: "Evening Feed".tr()),
                                ],
                              ),
                              Container(
                                height: 420, // Adjust the height as needed
                                child: TabBarView(
                                  children: [
                                    // Morning Feed Settings
                                    Column(
                                      children: [
                                        _buildGlobalFeedControl(
                                          context,
                                          "Morning".tr(),
                                          flock.morningFeedSettings,
                                              (feedName, qty) {
                                            setState(() {
                                              flock.morningFeedSettings.forEach((setting) {
                                                setting.feedName = feedName.tr();
                                                setting.dailyRequirement = qty;
                                              });
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: flock.morningFeedSettings.length ?? 0,
                                            itemBuilder: (context, index) {
                                              final setting = flock.morningFeedSettings[index];
                                              return _buildFeedSettingRow(setting);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Evening Feed Settings
                                    Column(
                                      children: [
                                        _buildGlobalFeedControl(
                                          context,
                                          "Evening".tr(),
                                          flock.eveningFeedSettings,
                                              (feedName, qty) {
                                            setState(() {
                                              flock.eveningFeedSettings.forEach((setting) {
                                                setting.feedName = feedName.tr();
                                                setting.dailyRequirement = qty;
                                              });
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: flock.eveningFeedSettings.length ?? 0,
                                            itemBuilder: (context, index) {
                                              final setting = flock.eveningFeedSettings[index];
                                              return _buildFeedSettingRow(setting);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                      // Single Feed Setting for Once a Day
                        Column(
                          children: [
                            _buildGlobalFeedControlForOnceADay(context, "Daily", automaticFeedFlocks.single.feedSettings,
                                  (feedName, qty) {
                              setState(() {
                                automaticFeedFlocks.single.feedSettings.forEach((setting) {
                                  setting.feedName = feedName;
                                  setting.dailyRequirement = qty;
                                });
                              });
                            },),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: flock.feedSettings.length,
                              itemBuilder: (context, index) {
                                final setting = flock.feedSettings[index];
                                return _buildFeedSettingRow(setting);
                              },
                            ),
                          ],
                        ),
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
                'Save Settings'.tr(),
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

  Widget _buildGlobalFeedControl(
      BuildContext context,
      String title,
      List<FeedSetting> feedSettings,
      Function(String feedName, String qty) onApply,
      ) {
    TextEditingController feedNameController = TextEditingController();
    TextEditingController qtyController = TextEditingController();

    return Card(
      margin: EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              "Set".tr()+" $title"+ "Feed for All Days".tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Utils.getThemeColorBlue(),
              ),
            ),
            SizedBox(height: 12),
            // Feed Name & Quantity Fields in Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Feed Name Dropdown
                Expanded(
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
                        value: feedSettings.isNotEmpty ? feedSettings[0].feedName : null,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Utils.getThemeColorBlue()),
                        items: _feedList
                            .map((feed) => DropdownMenuItem(
                          value: feed,
                          child: Text(
                            feed,
                            style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          feedNameController.text = value ?? "";
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Quantity Input
                Container(
                  height: 48,
                  width: 80, // Narrow width for quantity
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: qtyController,
                    decoration: InputDecoration(
                      hintText: 'Qty'.tr(),
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(3),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                SizedBox(width: 12),
                // Apply Button
                ElevatedButton(
                  onPressed: () {
                    if (feedNameController.text.isEmpty || qtyController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please enter both Feed and Quantity".tr())),
                      );
                    } else {
                      // Apply the settings
                      onApply(feedNameController.text, qtyController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Applied to all days successfully!".tr())),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Apply".tr(),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalFeedControlForOnceADay(
      BuildContext context,
      String title,
      List<FeedSetting> feedSettings,
      Function(String feedName, String qty) onApply,
      ) {
    TextEditingController feedNameController = TextEditingController();
    TextEditingController qtyController = TextEditingController();

    return Card(
      margin: EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              "Set".tr()+ " $title"+"Feed for All Days".tr(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Utils.getThemeColorBlue(),
              ),
            ),
            SizedBox(height: 12),
            // Feed Name & Quantity Fields in Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Feed Name Dropdown
                Expanded(
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
                        value: feedSettings.isNotEmpty ? feedSettings[0].feedName : null,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: Utils.getThemeColorBlue()),
                        items: _feedList
                            .map((feed) => DropdownMenuItem(
                          value: feed,
                          child: Text(
                            feed,
                            style: TextStyle(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                            .toList(),
                        onChanged: (value) {
                          feedNameController.text = value ?? "";
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Quantity Input
                Container(
                  height: 48,
                  width: 80, // Narrow width for quantity
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: qtyController,
                    decoration: InputDecoration(
                      hintText: 'Qty'.tr(),
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(3),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                SizedBox(width: 12),
                // Apply Button
                ElevatedButton(
                  onPressed: () {
                    if (feedNameController.text.isEmpty || qtyController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please enter both Feed and Quantity".tr())),
                      );
                    } else {
                      // Apply the settings
                      onApply(feedNameController.text, qtyController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Applied to all days successfully!".tr())),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Apply".tr(),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }




  Widget _buildFeedSettingRow(FeedSetting setting) {
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
                        overflow: TextOverflow.ellipsis,
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
                  hintText: 'Qty'.tr(),
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
  int id;
  String name;
  bool isTwiceADay; // New property
  List<FeedSetting> feedSettings;
  List<FeedSetting> morningFeedSettings; // Morning feeds for Twice a Day
  List<FeedSetting> eveningFeedSettings; // Evening feeds for Twice a Day

  AutomaticFeedSetting({
    required this.id,
    required this.name,
    this.isTwiceADay = false,
    this.feedSettings = const [],
    this.morningFeedSettings = const [],
    this.eveningFeedSettings = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isTwiceADay': isTwiceADay,
    'feedSettings': feedSettings.map((e) => e.toJson()).toList(),
    'morningFeedSettings': morningFeedSettings.map((e) => e.toJson()).toList(),
    'eveningFeedSettings': eveningFeedSettings.map((e) => e.toJson()).toList(),
  };

  factory AutomaticFeedSetting.fromJson(Map<String, dynamic> json) {
    return AutomaticFeedSetting(
      id: json['id'],
      name: json['name'],
      isTwiceADay: json['isTwiceADay'] ?? false,
      feedSettings: (json['feedSettings'] as List)
          .map((e) => FeedSetting.fromJson(e))
          .toList(),
      morningFeedSettings: (json['morningFeedSettings'] as List?)
          ?.map((e) => FeedSetting.fromJson(e))
          .toList() ??
          [], // Initialize as empty list if not present
      eveningFeedSettings: (json['eveningFeedSettings'] as List?)
          ?.map((e) => FeedSetting.fromJson(e))
          .toList() ??
          [], // Initialize as empty list if not present
    );
  }

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
