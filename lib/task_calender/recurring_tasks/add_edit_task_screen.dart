import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:poultary/database/databse_helper.dart';
import '../../utils/utils.dart';
import 'task_calendar_screen.dart';
import 'notification_service.dart';

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

class _AddEditTaskScreenState extends State<AddEditTaskScreen> with SingleTickerProviderStateMixin
{
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _userInputController;
  late TabController _tabController;
  
  TaskType _selectedTaskType = TaskType.feeding;
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<String> _selectedUsers = [];
  final _dbService = DatabaseHelper.instance;
  List<String> _availableUsers = [];
  bool _isLoadingUsers = true;
  
  // Recurring task fields
  bool _isRecurring = false;
  RecurrenceType _recurrenceType = RecurrenceType.daily;
  int _recurrenceInterval = 1;
  DateTime? _recurrenceEndDate;
  bool _wasRecurring = false; // Track if task was originally recurring
  
  // Notification fields
  bool _enableNotification = false;
  int _notificationMinutesBefore = 30;

  late NativeAd _myNativeAd;
  bool _isNativeAdLoaded = false;
  _loadNativeAds(){
    _myNativeAd = NativeAd(
      adUnitId: Utils.NativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small, // or medium
        mainBackgroundColor: Colors.white,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.blue,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          size: 14,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          size: 12,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) => setState(() => _isNativeAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Native ad failed: $error');
        },
      ),
    );


    _myNativeAd.load();

  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _userInputController = TextEditingController();
    
    if (widget.existingTask != null) {
      _titleController = TextEditingController(text: widget.existingTask!.title);
      _descriptionController = TextEditingController(text: widget.existingTask!.description);
      _notesController = TextEditingController(text: widget.existingTask!.notes ?? '');
      _selectedTaskType = widget.existingTask!.taskType;
      _selectedTime = widget.existingTask!.time;
      _selectedUsers = List.from(widget.existingTask!.assignedUsers);
      
      // Load recurring task data if available
      if (widget.existingTask!.recurrencePattern != null) {
        _isRecurring = true;
        _wasRecurring = true;
        _recurrenceType = widget.existingTask!.recurrencePattern!.type;
        _recurrenceInterval = widget.existingTask!.recurrencePattern!.interval;
        _recurrenceEndDate = widget.existingTask!.recurrencePattern!.endDate;
      }
      
      // Load notification data
      _enableNotification = widget.existingTask!.enableNotification;
      _notificationMinutesBefore = widget.existingTask!.notificationMinutesBefore ?? 30;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _notesController = TextEditingController();
    }

    if(Utils.isShowAdd){
      _loadNativeAds();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _userInputController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTask != null;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          isEditing ? 'edit_task'.tr() : 'add_new_task'.tr(),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _saveTask,
            icon: Icon(Icons.check, color: Colors.white, size: 20),
            label: Text(
              'save'.tr(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_isNativeAdLoaded)
              Container(
                height: 90,
                margin: const EdgeInsets.only(bottom: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AdWidget(ad: _myNativeAd),
              ),
            // Tab Bar
              Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue[700],
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue[700],
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    icon: Icon(Icons.info_outline, size: 20),
                    text: 'basic'.tr(),
                  ),
                  Tab(
                    icon: Icon(Icons.repeat, size: 20),
                    text: 'repeat'.tr(),
                  ),
                  Tab(
                    icon: Icon(Icons.notifications_outlined, size: 20),
                    text: 'reminder'.tr(),
                  ),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(),
                  _buildRecurringTab(),
                  _buildNotificationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 1: BASIC INFO ====================
  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Type Section
          _buildSectionHeader('task_type'.tr(), Icons.category),
          SizedBox(height: 12),
          _buildTaskTypeSelector(),
          
          SizedBox(height: 24),
          
          // Task Title
          _buildSectionHeader('task_details'.tr(), Icons.edit_note),
          SizedBox(height: 12),
          _buildTextField(
            controller: _titleController,
            label: 'task_title_required'.tr(),
            hint: 'task_title_hint'.tr(),
            icon: Icons.title,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'please_enter_task_title'.tr();
              }
              return null;
            },
          ),
          
          SizedBox(height: 16),
          
          // Task Description
          _buildTextField(
            controller: _descriptionController,
            label: 'description_required'.tr(),
            hint: 'enter_task_details'.tr(),
            icon: Icons.description,
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'please_enter_description'.tr();
              }
              return null;
            },
          ),
          
          SizedBox(height: 24),
          
          // Schedule Section
          _buildSectionHeader('schedule'.tr(), Icons.schedule),
          SizedBox(height: 12),
          _buildScheduleCard(),
          
          SizedBox(height: 24),
          
          // Assign Users Section
          _buildSectionHeader('assign_to'.tr(), Icons.people),
          SizedBox(height: 12),
          _buildAssignUsersCard(),
          
          SizedBox(height: 24),
          
          // Notes Section
          _buildSectionHeader('additional_notes_optional'.tr(), Icons.note_alt),
          SizedBox(height: 12),
          _buildTextField(
            controller: _notesController,
            label: 'notes'.tr(),
            hint: 'add_additional_information'.tr(),
            icon: Icons.note,
            maxLines: 4,
          ),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==================== TAB 2: RECURRING ====================
  Widget _buildRecurringTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enable Recurring Switch
          _buildFeatureCard(
            icon: Icons.repeat,
            title: 'repeat_task'.tr(),
            subtitle: _isRecurring 
                ? _getRecurrenceSummary()
                : 'set_recurring_schedule'.tr(),
            value: _isRecurring,
            onChanged: (value) {
              setState(() {
                _isRecurring = value;
              });
            },
            color: Colors.blue,
          ),
          
          if (_isRecurring) ...[
            SizedBox(height: 24),
            
            // Recurrence Pattern Card
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'repeat_frequency'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Frequency Selector
                  Row(
                    children: RecurrenceType.values.map((type) {
                      final isSelected = _recurrenceType == type;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: _buildFrequencyChip(
                            label: _getRecurrenceTypeName(type),
                            icon: _getRecurrenceIcon(type),
                            isSelected: isSelected,
                            onTap: () {
                              setState(() => _recurrenceType = type);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 20),
                  
                  // Interval Selector
                  Text(
                    'repeat_every'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _recurrenceInterval,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            borderRadius: BorderRadius.circular(12),
                            items: List.generate(30, (index) => index + 1)
                                .map((num) => DropdownMenuItem(
                                      value: num,
                                      child: Text(
                                        num.toString(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _recurrenceInterval = value!);
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        _getIntervalUnit(_recurrenceType, _recurrenceInterval),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 20),
                  
                  // End Date
                  Text(
                    'end_date_optional'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  InkWell(
                    onTap: _selectEndDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event, color: Colors.blue[700]),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _recurrenceEndDate != null
                                  ? '${_recurrenceEndDate!.day}/${_recurrenceEndDate!.month}/${_recurrenceEndDate!.year}'
                                  : 'no_end_date'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                color: _recurrenceEndDate != null 
                                    ? Colors.blue[900]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_recurrenceEndDate != null)
                            IconButton(
                              icon: Icon(Icons.clear, size: 20, color: Colors.grey[600]),
                              onPressed: () {
                                setState(() => _recurrenceEndDate = null);
                              },
                            ),
                          Icon(Icons.chevron_right, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Summary Box
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getRecurrenceSummary(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[900],
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (widget.existingTask != null && _wasRecurring && !_isRecurring) ...[
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Turning off repeat will keep this task but remove future occurrences.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== TAB 3: NOTIFICATION ====================
  Widget _buildNotificationTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enable Notification Switch
          _buildFeatureCard(
            icon: Icons.notifications_active,
            title: 'notification'.tr(),
            subtitle: _enableNotification
                ? 'notification_summary'.tr(args: [_getNotificationLabel(_notificationMinutesBefore)])
                : 'enable_task_reminder'.tr(),
            value: _enableNotification,
            onChanged: (value) {
              setState(() {
                _enableNotification = value;
              });
            },
            color: Colors.orange,
          ),
          
          if (_enableNotification) ...[
            SizedBox(height: 24),
            
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'notify_before'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Time Options
                  ...{
                    5: {'label': '5 ${'minutes'.tr()}', 'icon': Icons.notifications},
                    15: {'label': '15 ${'minutes'.tr()}', 'icon': Icons.notifications},
                    30: {'label': '30 ${'minutes'.tr()}', 'icon': Icons.notifications_active},
                    60: {'label': '1 ${'hour'.tr()}', 'icon': Icons.schedule},
                    120: {'label': '2 ${'hours'.tr()}', 'icon': Icons.access_time},
                    1440: {'label': '1 ${'day'.tr()}', 'icon': Icons.today},
                  }.entries.map((entry) {
                    final minutes = entry.key;
                    final data = entry.value;
                    final isSelected = _notificationMinutesBefore == minutes;
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() => _notificationMinutesBefore = minutes);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.orange[50] : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.orange[400]! : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.orange[100] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  data['icon'] as IconData,
                                  color: isSelected ? Colors.orange[700] : Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  data['label'] as String,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.orange[900] : Colors.grey[700],
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: Colors.orange[700]),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Preview Box
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[50]!, Colors.orange[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.orange[700], size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'notification_preview'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _getNotificationPreview(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== UI COMPONENTS ====================
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue[700], size: 20),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildTaskTypeSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
        children: TaskType.values.map((type) {
          final isSelected = _selectedTaskType == type;
          final color = _getTaskTypeColor(type);
          
          return InkWell(
            onTap: () {
              setState(() => _selectedTaskType = type);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getTaskTypeIcon(type),
                    color: isSelected ? color : Colors.grey[600],
                    size: 28,
                  ),
                  SizedBox(height: 8),
                  Text(
                    _getTaskTypeName(type),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? color : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {}, // Date is fixed based on selected day
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue[700], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'date'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[300],
          ),
          SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: _selectTime,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blue[700], size: 20),
                      SizedBox(width: 8),
                      Text(
                        'time'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _selectedTime.format(context),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignUsersCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userInputController,
                  decoration: InputDecoration(
                    hintText: 'enter_user_name'.tr(),
                    prefixIcon: Icon(Icons.person_add, color: Colors.blue[700]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (value) => _addUser(),
                ),
              ),
              SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[700]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _addUser,
                  icon: Icon(Icons.add, color: Colors.white),
                  padding: EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          
          if (_selectedUsers.isNotEmpty) ...[
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedUsers.map((user) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[50]!, Colors.blue[100]!],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue[700],
                        child: Text(
                          user[0].toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        user,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                        ),
                      ),
                      SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() => _selectedUsers.remove(user));
                        },
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            SizedBox(height: 16),
            Center(
              child: Text(
                'no_users_assigned'.tr(),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required MaterialColor color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: value 
                          ? [color[400]!, color[600]!]
                          : [Colors.grey[300]!, Colors.grey[400]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: value ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ] : [],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: color[700],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFrequencyChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [Colors.blue[500]!, Colors.blue[700]!])
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ] : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  
  void _addUser() {
    final userName = _userInputController.text.trim();
    if (userName.isNotEmpty && !_selectedUsers.contains(userName)) {
      setState(() {
        _selectedUsers.add(userName);
        _userInputController.clear();
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.grey[800]!,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? widget.selectedDate.add(Duration(days: 30)),
      firstDate: widget.selectedDate.add(Duration(days: 1)),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.grey[800]!,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _recurrenceEndDate = picked;
      });
    }
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: CircularProgressIndicator(),
          ),
        ),
      );

      try {
        RecurrencePattern? recurrencePattern;
        
        if (_isRecurring) {
          recurrencePattern = RecurrencePattern(
            type: _recurrenceType,
            interval: _recurrenceInterval,
            endDate: _recurrenceEndDate,
          );
        }
        
        final task = LivestockTask(
          id: widget.existingTask?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          time: _selectedTime,
          taskType: _selectedTaskType,
          assignedUsers: _selectedUsers,
          completed: widget.existingTask?.completed ?? false,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          recurrencePattern: recurrencePattern,
          enableNotification: _enableNotification,
          notificationMinutesBefore: _enableNotification ? _notificationMinutesBefore : null,
        );
        
        // Handle recurring changes if editing
        if (widget.existingTask != null && _wasRecurring && !_isRecurring) {
          // User turned off recurring - delete future instances
          await _deleteFutureRecurringInstances(widget.existingTask!.id);
        } else if (widget.existingTask != null && _wasRecurring && _isRecurring) {
          // User changed recurring pattern - delete and recreate
          await _deleteFutureRecurringInstances(widget.existingTask!.id);
          await _createRecurringTasks(task);
        } else if (_isRecurring && widget.existingTask == null) {
          // New recurring task
          await _createRecurringTasks(task);
        } else {
          // Cancel old notification if exists
          if (widget.existingTask != null && widget.existingTask!.enableNotification) {
            await NotificationService.instance.cancelTaskNotification(widget.existingTask!.id);
          }

          // Schedule new notification if enabled
          if (_enableNotification && _notificationMinutesBefore != null) {
            await _scheduleTaskNotification(task, widget.selectedDate);
          }
          // Single task or editing single task
          widget.onSave(task);

        }
        
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close form
      } catch (e) {
        Navigator.pop(context); // Close loading
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_saving_task'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _deleteFutureRecurringInstances(String parentId) async {
    // Delete all tasks with IDs starting with this parent ID except the current one
    // This should be implemented in your DatabaseHelper
    // For now, we'll just show a message
    print('Deleting future instances of task: $parentId');
  }
  
  Future<void> _createRecurringTasks(LivestockTask task) async {
    try {
      final taskDates = _calculateRecurringDates(
        startDate: widget.selectedDate,
        pattern: task.recurrencePattern!,
      );
      
      for (final date in taskDates) {
        final recurringTask = task.copyWith(
          id: '${task.id}_${date.millisecondsSinceEpoch}',
        );
        await _dbService.createTask(recurringTask, date);
        
        if (recurringTask.enableNotification && recurringTask.notificationMinutesBefore != null) {
          await _scheduleTaskNotification(recurringTask, date);
        }
      }
      
      widget.onSave(task);
    } catch (e) {
      throw e;
    }
  }
  
  Future<void> _scheduleTaskNotification(LivestockTask task, DateTime taskDate) async {
    try {
      final taskDateTime = DateTime(
        taskDate.year,
        taskDate.month,
        taskDate.day,
        task.time.hour,
        task.time.minute,
      );

      // Calculate notification time
      final notificationTime = taskDateTime.subtract(Duration(minutes: task.notificationMinutesBefore!));
      int notification_time = ((notificationTime.millisecondsSinceEpoch -
          DateTime.now().millisecondsSinceEpoch) / 1000).round();
      Utils.showNotification(
          Utils.generateNotificationId(task.id), task.title,
          task.description, notification_time);

     /*  await NotificationService.instance.scheduleTaskNotification(
        taskId: task.id,
        title: task.title,
        description: task.description,
        taskDateTime: taskDateTime,
        minutesBefore: task.notificationMinutesBefore!,
      );
*/
       print("Notification Scheduled ${taskDateTime.year} ${taskDateTime.month} ${taskDateTime.day}");
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }
  
  List<DateTime> _calculateRecurringDates({
    required DateTime startDate,
    required RecurrencePattern pattern,
  }) {
    List<DateTime> dates = [startDate];
    DateTime currentDate = startDate;
    
    int maxOccurrences = 365;
    int count = 0;
    
    while (count < maxOccurrences) {
      DateTime nextDate;
      
      switch (pattern.type) {
        case RecurrenceType.daily:
          nextDate = currentDate.add(Duration(days: pattern.interval));
          break;
        case RecurrenceType.weekly:
          nextDate = currentDate.add(Duration(days: 7 * pattern.interval));
          break;
        case RecurrenceType.monthly:
          nextDate = DateTime(
            currentDate.year,
            currentDate.month + pattern.interval,
            currentDate.day,
          );
          break;
      }
      
      if (pattern.endDate != null && nextDate.isAfter(pattern.endDate!)) {
        break;
      }
      
      if (nextDate.isAfter(startDate.add(Duration(days: 730)))) {
        break;
      }
      
      dates.add(nextDate);
      currentDate = nextDate;
      count++;
    }
    
    return dates;
  }
  
  String _getRecurrenceTypeName(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return 'daily'.tr();
      case RecurrenceType.weekly:
        return 'weekly'.tr();
      case RecurrenceType.monthly:
        return 'monthly'.tr();
    }
  }
  
  IconData _getRecurrenceIcon(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.daily:
        return Icons.today;
      case RecurrenceType.weekly:
        return Icons.date_range;
      case RecurrenceType.monthly:
        return Icons.calendar_month;
    }
  }
  
  String _getIntervalUnit(RecurrenceType type, int interval) {
    switch (type) {
      case RecurrenceType.daily:
        return interval == 1 ? 'day'.tr() : 'days'.tr();
      case RecurrenceType.weekly:
        return interval == 1 ? 'week'.tr() : 'weeks'.tr();
      case RecurrenceType.monthly:
        return interval == 1 ? 'month'.tr() : 'months'.tr();
    }
  }
  
  String _getRecurrenceSummary() {
    String summary = 'repeats_every'.tr() + ' ';
    
    if (_recurrenceInterval == 1) {
      switch (_recurrenceType) {
        case RecurrenceType.daily:
          summary += 'day_lowercase'.tr();
          break;
        case RecurrenceType.weekly:
          summary += 'week_lowercase'.tr();
          break;
        case RecurrenceType.monthly:
          summary += 'month_lowercase'.tr();
          break;
      }
    } else {
      summary += '$_recurrenceInterval ${_getIntervalUnit(_recurrenceType, _recurrenceInterval)}';
    }
    
    if (_recurrenceEndDate != null) {
      summary += ' ${'until'.tr()} ${_recurrenceEndDate!.day}/${_recurrenceEndDate!.month}/${_recurrenceEndDate!.year}';
    } else {
      summary += ' (${'no_end_date'.tr()})';
    }
    
    return summary;
  }
  
  String _getNotificationLabel(int minutes) {
    if (minutes < 60) {
      return '$minutes ${'minutes'.tr()}';
    } else if (minutes == 60) {
      return '1 ${'hour'.tr()}';
    } else if (minutes == 120) {
      return '2 ${'hours'.tr()}';
    } else if (minutes == 1440) {
      return '1 ${'day'.tr()}';
    } else {
      final hours = minutes ~/ 60;
      return '$hours ${'hours'.tr()}';
    }
  }
  
  String _getNotificationPreview() {
    final taskTime = TimeOfDay(hour: _selectedTime.hour, minute: _selectedTime.minute);
    final taskDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      taskTime.hour,
      taskTime.minute,
    );
    
    final notificationTime = taskDateTime.subtract(Duration(minutes: _notificationMinutesBefore));
    final timeFormat = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: notificationTime.hour, minute: notificationTime.minute),
    );
    
    return 'You\'ll be reminded at $timeFormat';
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
        return 'Medication'.tr();
      case TaskType.egg_collection:
        return 'EGG_COLLECTION'.tr();
      case TaskType.packing:
        return 'Packaging'.tr();
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
        return Colors.brown;
      case TaskType.egg_collection:
        return Colors.green;
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
        return Icons.medical_information;
      case TaskType.egg_collection:
        return Icons.egg;
      case TaskType.packing:
        return Icons.backpack;
    }
  }
}


