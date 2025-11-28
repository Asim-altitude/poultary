import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poultary/database/databse_helper.dart';
import 'package:poultary/utils/utils.dart';
import 'model/flock.dart';
import 'model/recurrence_type.dart';
import 'model/schedule_notification.dart';

class FlockNotificationScreen extends StatefulWidget {
  List<ScheduledNotification> allNotifications;
   FlockNotificationScreen({
    Key? key,required this.allNotifications }) : super(key: key);

  @override
  State<FlockNotificationScreen> createState() => _FlockNotificationScreenState();
}

class _FlockNotificationScreenState extends State<FlockNotificationScreen> {
   List<ScheduledNotification> upcomingNotifications = [];

  void filterNotifications() {
    final now = DateTime.now();

    upcomingNotifications = widget.allNotifications
        .where((notification) => notification.scheduledAt.isAfter(now) || notification.scheduledAt.isAtSameMomentAs(now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)); // earliest first

    print("TIME ${upcomingNotifications.elementAt(0).scheduledAt}");

   // Utils().checkScheduledNotifications();

  }

  @override
  void initState() {
    super.initState();
    filterNotifications();
  }


  Widget _buildCustomNotificationCard({
    required String title,
    required String description,
    required DateTime scheduledAt,
    required RecurrenceType recurrence,
    required VoidCallback onDelete,
  }) {
    final now = DateTime.now().toLocal();
    final daysRemaining = scheduledAt.difference(DateTime(now.year, now.month, now.day)).inDays;
    final recurrenceText = recurrence.name[0].toUpperCase() + recurrence.name.substring(1);
    final scheduledDateText = Utils.getFormattedDate(DateFormat("yyyy MM dd - HH:mm a").format(scheduledAt));

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expanded content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(description.tr()),
                  const SizedBox(height: 6),
                  Text("Scheduled on".tr()+": $scheduledDateText",
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("Repeat".tr()+": "+recurrenceText.tr(),
                      style: const TextStyle(fontSize: 12, color: Colors.blue)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Trailing controls
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "In".tr()+" $daysRemaining}"+"days".tr(),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: onDelete,
                  tooltip: 'DELETE'.tr(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Flock Notifications".tr(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
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
        padding: EdgeInsets.all(10),
        child:  Expanded(
          child: InkWell(
            onTap: () => {
              _showAddCustomNotificationDialog()
            },
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: 55,
              margin: EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Utils.getThemeColorBlue(), Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notification_add_outlined, color: Colors.amber, size: 28),
                  SizedBox(width: 6),
                  Text(
                    'New Notification'.tr(),
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),

      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(10),
          child: Column(
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_active, color: Colors.amber, size: 25,),
                  SizedBox(width: 5,),
                  Text('Scheduled Notifications'.tr(), style: TextStyle(fontSize: 16, color: Utils.getThemeColorBlue(), fontWeight: FontWeight.bold),),
                  Text(" (${upcomingNotifications.length.toString()})", style: TextStyle(fontSize: 16, color: Utils.getThemeColorBlue(), fontWeight: FontWeight.normal),),

                ],
              ),

              ListView(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                children: [

                    const SizedBox(height: 8),
                    ...List.generate(upcomingNotifications.length, (index) {
                      final c = upcomingNotifications[index];
                      return _buildCustomNotificationCard(
                        title: c.title,
                        description: c.description,
                        onDelete: () {
                         showDeleteConfirmation(context,c.id);
                        }, scheduledAt: c.scheduledAt, recurrence: c.recurrence,
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
              ),
            ],
          ),
        ),
      ),);
  }

  showDeleteConfirmation(BuildContext context, int id) {

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("CANCEL".tr()),
      onPressed:  () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("DONE".tr()),
      onPressed:  () async {

        await Utils().cancelAndRemoveNotification(id);
        widget.allNotifications = await DatabaseHelper.getScheduledNotificationsByFlockId(Utils.selected_flock!.f_id);
        filterNotifications();
        setState(() {
          
        });
        Navigator.pop(context);

      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("CONFIRMATION".tr()),
      content: Container(
          padding: EdgeInsets.all(10),
          child: Text('Are you sure to delete this scheduled notification?'.tr())
      ),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );



  }


  void _showAddCustomNotificationDialog() {
    final _titleController = TextEditingController();
    final _descController = TextEditingController();
    RecurrenceType _selectedRecurrence = RecurrenceType.once;
    DateTime? _selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Create Notification'.tr(),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Set a custom reminder for your flock'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Title Field
                Text('Title'.tr(), style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Deworming Reminder'.tr(),
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Description Field
                Text('Description'.tr(), style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Give oral dewormer to all chicks'.tr(),
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                // Pick Date Field
                Text('Choose date'.tr(), style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );

                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: 8, minute: 0), // Default to 8:00 AM
                      );

                      if (pickedTime != null) {
                        final DateTime combined = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        print("SELECTED DATETIME $combined");

                        setModalState(() {
                          _selectedDate = combined;
                        });
                      }
                    }
                  },

                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null
                              ? 'Choose date'.tr()
                              : DateFormat.yMMMMd().format(_selectedDate!),
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate == null ? Colors.grey : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Recurrence Field
                Text('Recurrence'.tr(), style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                DropdownButtonFormField<RecurrenceType>(
                  value: _selectedRecurrence,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.repeat),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setModalState(() {
                        _selectedRecurrence = value;
                      });
                    }
                  },
                  items: RecurrenceType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text((type.name[0].toUpperCase() + type.name.substring(1)).tr()),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label:  Text('Add Notification'.tr()),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Utils.getThemeColorBlue(),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      if (_selectedDate == null) {
                        Utils.showToast('Please select a date.'.tr());
                        return;
                      }

                      final newNotification = ScheduledNotification(
                        id: DateTime.now().millisecondsSinceEpoch,
                        birdType: Utils.selected_flock!.icon.split(".")[0].replaceAll("assets/", ""),
                        flockId: Utils.selected_flock!.f_id,
                        title: _titleController.text.trim(),
                        description: _descController.text.trim(),
                        scheduledAt: _selectedDate!,
                        recurrence: _selectedRecurrence, );

                      List<ScheduledNotification> list = Utils().generateRecurringNotifications(birdType: newNotification.birdType, flockId: newNotification.flockId, title: newNotification.title, description: newNotification.description, startDate: newNotification.scheduledAt, recurrence: newNotification.recurrence);

                      saveAndScheduleNotifications(list);


                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> saveAndScheduleNotifications(List<ScheduledNotification> finalNotifications) async {

    int index = widget.allNotifications.length+1;
    for (ScheduledNotification notification in finalNotifications) {
      // 1. Save to local DB
      notification.id = int.parse(notification.flockId.toString()+index.toString());
      int? id = await DatabaseHelper.insertNotification(notification);

      print("NOTIFICATION_ID ${notification.id}");
      // 2. Schedule system notification
      await Utils.scheduleNotification(
        id: notification.id,
        title: notification.title + "(${Utils.selected_flock!.f_name})",
        body: notification.description,
        scheduledDate: notification.scheduledAt,
        payload: '${notification.flockId}_${notification.birdType}',);

      index++;
      print("SCHEDULED_" +notification.title+" "+notification.description+" "+notification.scheduledAt.toIso8601String()+" "+notification.recurrence.toString());

    }
    print("ALL_DONE");

    widget.allNotifications = await DatabaseHelper.getScheduledNotificationsByFlockId(Utils.selected_flock!.f_id);
    filterNotifications();
    setState(() {

    });
  }


}
