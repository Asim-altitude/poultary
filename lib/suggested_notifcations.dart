import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/utils/utils.dart';

import 'database/databse_helper.dart';
import 'model/flock.dart';
import 'model/notification_suggestions.dart';
import 'model/recurrence_type.dart';
import 'model/schedule_notification.dart';

class SuggestedNotificationScreen extends StatefulWidget {
  final String birdType;
  final int flockId;
  final int flockAgeInDays;

  const SuggestedNotificationScreen({
    Key? key,
    required this.birdType,
    required this.flockId,
    required this.flockAgeInDays,
  }) : super(key: key);

  @override
  State<SuggestedNotificationScreen> createState() => _SuggestedNotificationScreenState();
}

class _SuggestedNotificationScreenState extends State<SuggestedNotificationScreen> {
  final List<ScheduledNotification> customNotifications = [], finalNotifications = [];
   List<SuggestedNotification> suggestions = [];

  @override
  void initState() {
    super.initState();
    suggestions = getSuggestedNotifications();
    getflock();
  }

  Flock? flock = null;
  Future<void> getflock() async{
    flock = await DatabaseHelper.getSingleFlock(widget.flockId);
  }

  Future<void> saveFinalNotifications () async {
    for(int i=0;i<suggestions.length;i++){

      ScheduledNotification notification = new ScheduledNotification(id: -1, birdType: widget.birdType, flockId: widget.flockId, title: suggestions[i].title, description: suggestions[i].description, scheduledAt: getTriggerDateFromNow(suggestions[i].triggerDay), recurrence: RecurrenceType.once);
      finalNotifications.add(notification);
    }

    for(int j=0;j<customNotifications.length;j++)
    {
      List<ScheduledNotification> customList =
      Utils().generateRecurringNotifications(birdType: widget.birdType, flockId: widget.flockId, title: customNotifications[j].title, description: customNotifications[j].description, startDate: customNotifications[j].scheduledAt, recurrence: customNotifications[j].recurrence);

      finalNotifications.addAll(customList);
    }

    saveAndScheduleNotifications(finalNotifications);

  }

  Future<void> saveAndScheduleNotifications(List<ScheduledNotification> finalNotifications) async {

    int index = 1;
    for (ScheduledNotification notification in finalNotifications) {
      // 1. Save to local DB
      notification.id = int.parse(notification.flockId.toString()+index.toString());
      int? id = await DatabaseHelper.insertNotification(notification);

      print("NOTIFICATION_ID ${notification.id}");
      // 2. Schedule system notification
      await Utils.scheduleNotification(
        id: notification.id,
        title: notification.title + "(${flock!.f_name})",
        body: notification.description,
        scheduledDate: notification.scheduledAt,
        payload: '${notification.flockId}_${notification.birdType}',
      );

      index++;
      print("SCHEDULED_" +notification.title+" "+notification.description+" "+notification.scheduledAt.toIso8601String()+" "+notification.recurrence.toString());

    }
    print("ALL_DONE");

    Navigator.pop(context);
  }


  List<SuggestedNotification> getSuggestedNotifications() {
    return Utils().getSuggestedNotifications(
      birdType: widget.birdType,
      ageInDays: widget.flockAgeInDays,
    );
  }

  DateTime getTriggerDateFromNow(int triggerDay) {
    final now = DateTime.now().toLocal();
    final triggerDate = now.add(Duration(days: triggerDay));
    return DateTime(triggerDate.year, triggerDate.month, triggerDate.day, 6); // 6 AM
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
                              ? 'Choose date'
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
                      child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
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
                        birdType: widget.birdType,
                        flockId: widget.flockId,
                        title: _titleController.text.trim(),
                        description: _descController.text.trim(),
                        scheduledAt: _selectedDate!,
                        recurrence: _selectedRecurrence, );

                      setState(() {
                        customNotifications.add(newNotification);
                      });

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


  void _scheduleAndSaveToDatabase() {
    final combined = [
      ...suggestions.map((s) => ScheduledNotification(
        id: DateTime.now().millisecondsSinceEpoch + s.triggerDay,
        birdType: widget.birdType,
        flockId: widget.flockId,
        title: s.title,
        description: s.description,
        scheduledAt: DateTime.now().add(Duration(days: s.triggerDay)),
        recurrence: RecurrenceType.once,
      )),
      ...customNotifications
    ];

    // TODO: Save combined list to database
    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Notifications scheduled and saved.'.tr())),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String description,
    required String trailingText,
    required VoidCallback onDelete,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description.tr()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(trailingText.tr(), style: const TextStyle(fontSize: 12)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomNotificationCard({
    required String title,
    required String description,
    required DateTime scheduledAt,
    required RecurrenceType recurrence,
    required VoidCallback onDelete,
  }) {
    final now = DateTime.now();
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(description),
                  const SizedBox(height: 6),
                  Text("Scheduled on".tr()+": $scheduledDateText",
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("Recurrence".tr()+": $recurrenceText",
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
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "In".tr()+" $daysRemaining "+'days'.tr(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: onDelete,
                  tooltip: 'DELETE'.tr(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return
      
      Scaffold(
      appBar: AppBar(
        title:  Text('Flock Notifications'.tr()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: Container(
      color: Colors.white,
      padding: EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
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
                    Icon(Icons.notification_add_outlined, color: Colors.white, size: 28),
                    SizedBox(width: 6),
                    Text(
                      'Custom'.tr(),
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => {
                // SCHEDULE DATABASE
                 showConfirmNotificationDialog(context: context, title: "Flock Notifications", description: "You can disable them later in flock details screen", onConfirm: () {
                  //SAVED
                  saveFinalNotifications();
                })
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: 55,
                margin: EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade500, Colors.blue],
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
                    Icon(Icons.schedule, color: Colors.white, size: 24),
                    SizedBox(width: 5,),
                    Text(
                      'Schedule'.tr(),
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
          ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (suggestions.isNotEmpty) ...[
              Row(
                children:  [
                  Icon(Icons.lightbulb_outline, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('Suggested Notifications'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(suggestions.length, (index) {
                final s = suggestions[index];
                return _buildNotificationCard(
                  title: s.title,
                  description: s.description,
                  trailingText: 'day'.tr()+' ${s.triggerDay}',
                  onDelete: () {
                    setState(() => suggestions.removeAt(index));
                  },
                );
              }),
              const SizedBox(height: 24),
            ],
            if (customNotifications.isNotEmpty) ...[
              Row(
                children:  [
                  Icon(Icons.notifications_active, color: Utils.getThemeColorBlue()),
                  SizedBox(width: 8),
                  Text('Custom Notifications'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(customNotifications.length, (index) {
                final c = customNotifications[index];
                return _buildCustomNotificationCard(
                  title: c.title,
                  description: c.description,
                  onDelete: () {
                    setState(() => customNotifications.removeAt(index));
                  }, scheduledAt: c.scheduledAt, recurrence: c.recurrence,
                );
              }),
              const SizedBox(height: 24),
            ],

          ],
        ),
      ),
          );
  }


  Future<void> showConfirmNotificationDialog({
    required BuildContext context,
    required String title,
    required String description,
    required VoidCallback onConfirm,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Icon(
                Icons.notifications_active,
                size: 48,
                color: Utils.getThemeColorBlue(),
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm Notifications'.tr(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to schedule these notification?'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$title', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('$description'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child:  Text('CANCEL'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();

                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Utils.getThemeColorBlue(),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child:  Text('CONFIRM'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



}
