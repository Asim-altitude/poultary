import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'task_calendar_screen.dart';

// Task Details Bottom Sheet
class TaskDetailsSheet extends StatelessWidget {
  final LivestockTask task;

  const TaskDetailsSheet({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(20),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Task Type Badge
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getTaskTypeColor(task.taskType),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getTaskTypeIcon(task.taskType),
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          _getTaskTypeName(task.taskType),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  if (task.completed)
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                ],
              ),
              
              SizedBox(height: 16),
              
              // Task Title
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 20),
              
              // Time
              _buildInfoRow(
                Icons.access_time,
                'Time',
                task.time.format(context),
              ),
              
              SizedBox(height: 16),
              
              // Description
              _buildInfoSection(
                Icons.description,
                'Description',
                task.description,
              ),
              
              SizedBox(height: 16),
              
              // Assigned Users
              if (task.assignedUsers.isNotEmpty) ...[
                _buildAssignedUsers(task.assignedUsers),
                SizedBox(height: 16),
              ],
              
              // Notes
              if (task.notes != null && task.notes!.isNotEmpty) ...[
                _buildInfoSection(
                  Icons.note,
                  'Notes',
                  task.notes!,
                ),
                SizedBox(height: 16),
              ],
              
              // Action Buttons
              SizedBox(height: 8),
              /*Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Edit functionality
                      },
                      icon: Icon(Icons.edit),
                      label: Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Share functionality
                      },
                      icon: Icon(Icons.share),
                      label: Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),*/
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(IconData icon, String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildAssignedUsers(List<String> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, color: Colors.grey[600], size: 20),
            SizedBox(width: 8),
            Text(
              'Assigned To',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: users.map((user) {
            return Chip(
              avatar: CircleAvatar(
                child: Text(user[0]),
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              label: Text(user),
              backgroundColor: Colors.green[50],
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getTaskTypeColor(TaskType type) {
    switch (type) {
      case TaskType.feeding:
        return Colors.orange;
      case TaskType.healthCheck:
        return Colors.blue;
      case TaskType.vaccination:
        return Colors.red;
      case TaskType.breeding:
        return Colors.purple;
      case TaskType.cleaning:
        return Colors.teal;
      case TaskType.other:
        return Colors.grey;
      case TaskType.medication:
        // TODO: Handle this case.
        return Colors.green;
      case TaskType.egg_collection:
        // TODO: Handle this case.
        return Colors.yellow;
      case TaskType.packing:
        // TODO: Handle this case.
        return Colors.amber;

    }
  }

  IconData _getTaskTypeIcon(TaskType type) {
    switch (type) {
      case TaskType.feeding:
        return Icons.restaurant;
      case TaskType.healthCheck:
        return Icons.health_and_safety;
      case TaskType.vaccination:
        return Icons.vaccines;
      case TaskType.breeding:
        return Icons.favorite;
      case TaskType.cleaning:
        return Icons.cleaning_services;
      case TaskType.other:
        return Icons.task;
      case TaskType.medication:
      // TODO: Handle this case.
        return Icons.medical_information;
      case TaskType.egg_collection:
      // TODO: Handle this case.
        return Icons.egg;
      case TaskType.packing:
      // TODO: Handle this case.
        return Icons.backpack;

    }
  }

  String _getTaskTypeName(TaskType type) {
    switch (type) {
      case TaskType.feeding:
        return 'feeding'.tr();
      case TaskType.healthCheck:
        return 'health_check'.tr();
      case TaskType.vaccination:
        return 'vaccination'.tr();
      case TaskType.breeding:
        return 'breeding'.tr();
      case TaskType.cleaning:
        return 'cleaning'.tr();
      case TaskType.other:
        return 'other'.tr();
      case TaskType.medication:
      // TODO: Handle this case.
        return 'Medication'.tr();
      case TaskType.egg_collection:
      // TODO: Handle this case.
        return 'EGG_COLLECTION'.tr();
      case TaskType.packing:
        return 'Packaging'.tr();
    // TODO: Handle this case.

    }
  }

}

// Share Options Bottom Sheet
class ShareOptionsSheet extends StatelessWidget {
  final LivestockTask task;
  final DateTime selectedDate;

  const ShareOptionsSheet({
    Key? key,
    required this.task,
    required this.selectedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Task',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          
        /*  // WhatsApp Share
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[600],
              child: Icon(Icons.message, color: Colors.white),
            ),
            title: Text('Share via WhatsApp'),
            subtitle: Text('Send task to team members'),
            onTap: () {
              _shareViaWhatsApp(context);
            },
          ),
          
          Divider(),*/
          
          // General Share
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[600],
              child: Icon(Icons.share, color: Colors.white),
            ),
            title: Text('Share via Other Apps'),
            subtitle: Text('SMS, Email, Telegram, etc.'),
            onTap: () {
              _shareViaOtherApps(context);
            },
          ),
          
        /*  Divider(),
          
          // Copy to Clipboard
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[600],
              child: Icon(Icons.content_copy, color: Colors.white),
            ),
            title: Text('Copy Task Details'),
            subtitle: Text('Copy to clipboard'),
            onTap: () {
              _copyToClipboard(context);
            },
          ),*/
          
          SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatTaskMessage() {
    final dateStr = '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}';
    final timeStr = '${task.time.hour.toString().padLeft(2, '0')}:${task.time.minute.toString().padLeft(2, '0')}';
    
    String message = '''
🐔 * Easy Poultry Task Reminder*

📋 *Task:* ${task.title}
📝 *Description:* ${task.description}
📅 *Date:* $dateStr
🕐 *Time:* $timeStr
''';

    if (task.assignedUsers.isNotEmpty) {
      message += '👥 *Assigned to:* ${task.assignedUsers.join(', ')}\n';
    }

    if (task.notes != null && task.notes!.isNotEmpty) {
      message += '📌 *Notes:* ${task.notes}\n';
    }

    message += '\n✅ Please complete this task on time!';
    
    return message;
  }

  void _shareViaWhatsApp(BuildContext context) async {
    final message = _formatTaskMessage();
    
    // Option 1: Share to WhatsApp (opens chat selector)
    final whatsappUrl = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(message)}'
    );
    
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WhatsApp is not installed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening WhatsApp'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareViaOtherApps(BuildContext context) async {
    final message = _formatTaskMessage();
    
    try
    {
      await Share.share(
        message,
        subject: 'Easy Poultry Task: ${task.title}',
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing task'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyToClipboard(BuildContext context) {
    final message = _formatTaskMessage();
    
    // Copy to clipboard (you'll need to import clipboard package)
    // Clipboard.setData(ClipboardData(text: message));
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task details copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// WhatsApp Direct Share Function (Alternative approach)
Future<void> shareTaskViaWhatsAppDirect({
  required String phoneNumber,
  required LivestockTask task,
  required DateTime date,
}) async
{
  final dateStr = '${date.day}/${date.month}/${date.year}';
  final timeStr = '${task.time.hour.toString().padLeft(2, '0')}:${task.time.minute.toString().padLeft(2, '0')}';

  final message = '''
🐔 Easy Poultry Task Reminder

Task: ${task.title}
Description: ${task.description}
Date: $dateStr
Time: $timeStr
Assigned to: ${task.assignedUsers.join(', ')}

Please complete this task on time!
  ''';
  
  // Remove any non-numeric characters from phone number
  final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  
  // Create WhatsApp URL with specific phone number
  final whatsappUrl = Uri.parse(
    'https://wa.me/$cleanedPhone?text=${Uri.encodeComponent(message)}'
  );
  
  if (await canLaunchUrl(whatsappUrl)) {
    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch WhatsApp';
  }
}
