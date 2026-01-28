import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:poultary/database/databse_helper.dart';
import '../utils/utils.dart';
import 'task_calendar_screen.dart';

class AddEditTaskScreen extends StatefulWidget {
  final DateTime selectedDate;
  final LivestockTask? existingTask;
  final Function(LivestockTask) onSave;

  const AddEditTaskScreen({
    Key? key,
    required this.selectedDate,
    this.existingTask,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _taskController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _userInputController;
  
  TaskType _selectedTaskType = TaskType.feeding;
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<String> _selectedUsers = [];
  final _dbService = DatabaseHelper.instance;
  List<String> _availableUsers = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    
    _userInputController = TextEditingController();
    
    if (widget.existingTask != null) {
      _titleController = TextEditingController(text: widget.existingTask!.title);
      _descriptionController = TextEditingController(text: widget.existingTask!.description);
      _notesController = TextEditingController(text: widget.existingTask!.notes ?? '');
      _selectedTaskType = widget.existingTask!.taskType;
      _selectedTime = widget.existingTask!.time;
      _selectedUsers = List.from(widget.existingTask!.assignedUsers);
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _notesController = TextEditingController();
    }
    
   // _loadAvailableUsers();
  }
  
 /* Future<void> _loadAvailableUsers() async {
    try {
      final users = await _dbService.getAllUsers(activeOnly: true);
      setState(() {
        _availableUsers = users.map((u) => u['name'] as String).toList();
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
    }
  }*/

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _userInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTask != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'edit_task'.tr() : 'add_new_task'.tr()),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: Text(
              'save'.tr(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Task Type Selection
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'task_type'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TaskType.values.map((type) {
                        return ChoiceChip(
                          label: Text(_getTaskTypeName(type)),
                          avatar: Icon(
                            _getTaskTypeIcon(type),
                            size: 18,
                            color: _selectedTaskType == type
                                ? Colors.white
                                : _getTaskTypeColor(type),
                          ),
                          selected: _selectedTaskType == type,
                          selectedColor: _getTaskTypeColor(type),
                          onSelected: (selected) {
                            setState(() {
                              _selectedTaskType = type;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 10),

            
            // Task Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'task_title_required'.tr(),
                hintText: 'task_title_hint'.tr(),
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'please_enter_task_title'.tr();
                }
                return null;
              },
            ),
            
            SizedBox(height: 10),
            
            // Task Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'description_required'.tr(),
                hintText: 'enter_task_details'.tr(),
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'please_enter_description'.tr();
                }
                return null;
              },
            ),
            
            SizedBox(height: 10),
            
            // Date and Time
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'schedule'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.calendar_today, color: Colors.blue[700]),
                            title: Text('date'.tr()),
                            subtitle: Text(
                              '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.access_time, color: Colors.blue[700]),
                            title: Text('time'.tr()),
                            subtitle: Text(_selectedTime.format(context)),
                            onTap: _selectTime,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 10),
            
            // Assign Users
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'assign_to'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                       /*if(Utils.isMultiUSer)
                         TextButton.icon(
                          onPressed: _showUserSelectionDialog,
                          icon: Icon(Icons.add),
                          label: Text('add_users'.tr()),
                        ),*/
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    // Text input for adding new user
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _userInputController,
                            decoration: InputDecoration(
                              hintText: 'enter_user_name'.tr(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final userName = _userInputController.text.trim();
                            if (userName.isNotEmpty && !_selectedUsers.contains(userName)) {
                              setState(() {
                                _selectedUsers.add(userName);
                                _userInputController.clear();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 12),
                    
                    if (_selectedUsers.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'no_users_assigned'.tr(),
                          style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedUsers.map((user) {
                          return Chip(
                            avatar: CircleAvatar(
                              child: Text(user[0]),
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                            ),
                            label: Text(user),
                            deleteIcon: Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _selectedUsers.remove(user);
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Notes (Optional)
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'additional_notes_optional'.tr(),
                hintText: 'add_additional_information'.tr(),
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            /*// Repeat Options (Future Enhancement)
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.repeat, color: Colors.grey[600]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'repeat_task'.tr(),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'coming_soon_recurring_tasks'.tr(),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: false,
                      onChanged: null, // Disabled for now
                    ),
                  ],
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _showUserSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('select_users'.tr()),
              content: _isLoadingUsers
                  ? Center(child: CircularProgressIndicator())
                  : Container(
                      width: double.maxFinite,
                      child: _availableUsers.isEmpty
                          ? Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'no_users_available_add_manually'.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _availableUsers.length,
                              itemBuilder: (context, index) {
                                final user = _availableUsers[index];
                                final isSelected = _selectedUsers.contains(user);
                                
                                return CheckboxListTile(
                                  title: Text(user),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        if (!_selectedUsers.contains(user)) {
                                          _selectedUsers.add(user);
                                        }
                                      } else {
                                        _selectedUsers.remove(user);
                                      }
                                    });
                                    setState(() {}); // Update parent widget
                                  },
                                );
                              },
                            ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('done'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final task = LivestockTask(
        id: widget.existingTask?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        time: _selectedTime,
        taskType: _selectedTaskType,
        assignedUsers: _selectedUsers,
        completed: widget.existingTask?.completed ?? false,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      
      widget.onSave(task);
      Navigator.pop(context);
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
        return Colors.white;
      case TaskType.egg_collection:
        // TODO: Handle this case.
        return Colors.green;
      case TaskType.packing:
        // TODO: Handle this case.
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
