import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/task_calender/task_details_share.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/databse_helper.dart';
import 'add_edit_task_screen.dart';

// Main Task Calendar Screen
class TaskCalendarScreen extends StatefulWidget {
  const TaskCalendarScreen({Key? key}) : super(key: key);

  @override
  State<TaskCalendarScreen> createState() => _TaskCalendarScreenState();
}

class _TaskCalendarScreenState extends State<TaskCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<LivestockTask>> _tasks = {};
  final _dbService = DatabaseHelper.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    
    try {
      // Load tasks for current month
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      
      final groupedTasks = await _dbService.getTasksGroupedByDate(
        startDate: firstDay,
        endDate: lastDay,
      );
      
      setState(() {
        _tasks = groupedTasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_loading_tasks'.tr())),
        );
      }
    }
  }

  List<LivestockTask> _getTasksForDay(DateTime day) {
    return _tasks[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('task_calendar'.tr()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
       /* actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],*/
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar Widget
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                    _loadTasks(); // Reload tasks when month changes
                  },
                  eventLoader: _getTasksForDay,
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blue[300],
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.blue[700],
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Task List for Selected Day
                Expanded(
                  child: _buildTaskList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(),
        backgroundColor: Colors.blue[700],
        child: Icon(Icons.add, color: Colors.white,),
      ),
    );
  }

  Widget _buildTaskList() {
    final tasks = _getTasksForDay(_selectedDay!);
    
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'no_tasks_scheduled'.tr(),
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(LivestockTask task) {
    final timeStr = task.time.format(context);
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTaskTypeColor(task.taskType),
          child: Icon(
            _getTaskTypeIcon(task.taskType),
            color: Colors.white,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(timeStr),
              ],
            ),
            if (task.assignedUsers.isNotEmpty) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.assignedUsers.join(', '),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('edit'.tr()),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => Future.delayed(
                Duration.zero,
                () => _showEditTaskDialog(task),
              ),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('share'.tr()),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => Future.delayed(
                Duration.zero,
                () => _showShareOptions(task),
              ),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.check_circle),
                title: Text(task.completed ? 'mark_incomplete'.tr() : 'mark_complete'.tr()),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => _toggleTaskCompletion(task),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('delete'.tr(), style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => _deleteTask(task),
            ),
          ],
        ),
        onTap: () => _showTaskDetails(task),
      ),
    );
  }

  void _showAddTaskDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTaskScreen(
          selectedDate: _selectedDay!,
          onSave: (task) async {
            try {
              await _dbService.createTask(task, _selectedDay!);
              await _loadTasks(); // Reload tasks from database
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('task_created_successfully'.tr()),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('error_creating_task'.tr()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _showEditTaskDialog(LivestockTask task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTaskScreen(
          selectedDate: _selectedDay!,
          existingTask: task,
          onSave: (updatedTask) async {
            try {
              await _dbService.updateTask(updatedTask, _selectedDay!);
              await _loadTasks(); // Reload tasks from database
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('task_updated_successfully'.tr()),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('error_updating_task'.tr()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _showTaskDetails(LivestockTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TaskDetailsSheet(task: task),
    );
  }

  void _showShareOptions(LivestockTask task) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ShareOptionsSheet(
        task: task,
        selectedDate: _selectedDay!,
      ),
    );
  }

  Future<void> _toggleTaskCompletion(LivestockTask task) async {
    try {
      await _dbService.toggleTaskCompletion(task.id);
      await _loadTasks(); // Reload tasks from database
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              task.completed ? 'task_reopened'.tr() : 'task_completed'.tr(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_updating_task'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTask(LivestockTask task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_delete'.tr()),
        content: Text('delete_task_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('delete'.tr(), style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await _dbService.deleteTask(task.id);
        await _loadTasks(); // Reload tasks from database
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('task_deleted'.tr())),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('error_deleting_task'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showFilterOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('filter_tasks'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: Text('feeding'.tr()),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: Text('health_check'.tr()),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: Text('vaccination'.tr()),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: Text('breeding'.tr()),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('apply'.tr()),
          ),
        ],
      ),
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
        return Colors.brown;
      case TaskType.egg_collection:
        // TODO: Handle this case.
        return Colors.white;
      case TaskType.packing:
        return Colors.yellow;

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
}

// Task Model
class LivestockTask {
  final String id;
  final String title;
  final String description;
  final TimeOfDay time;
  final TaskType taskType;
  final List<String> assignedUsers;
  final bool completed;
  final String? notes;

  LivestockTask({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.taskType,
    required this.assignedUsers,
    this.completed = false,
    this.notes,
  });

  LivestockTask copyWith({
    String? id,
    String? title,
    String? description,
    TimeOfDay? time,
    TaskType? taskType,
    List<String>? assignedUsers,
    bool? completed,
    String? notes,
  }) {
    return LivestockTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      taskType: taskType ?? this.taskType,
      assignedUsers: assignedUsers ?? this.assignedUsers,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'time': '${time.hour}:${time.minute}',
      'taskType': taskType.toString(),
      'assignedUsers': assignedUsers,
      'completed': completed,
      'notes': notes,
    };
  }
}

enum TaskType {
  feeding,
  healthCheck,
  vaccination,
  medication,
  egg_collection,
  packing,
  breeding,
  cleaning,
  other,
}
