import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../data/event_repository.dart';

class NewEventPage extends StatefulWidget {
  final EventModel? event; // If null, it's a new event

  const NewEventPage({Key? key, this.event}) : super(key: key);

  @override
  State<NewEventPage> createState() => _NewEventPageState();
}

class _NewEventPageState extends State<NewEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController     = TextEditingController();
  final _durationController = TextEditingController();

  String?   _selectedCategory;
  DateTime? _startDate;
  DateTime? _deadline;

  final _repo = EventRepository();

  bool get _isNew    => widget.event == null;
  bool get _isFixed  => !_isNew && widget.event!.type == EventType.fixed;
  
  bool get _isDeadline =>
      !_isNew && !(widget.event!.deadline == null);

  @override
  void initState() {
    super.initState();
    if (_isNew) {
      // new: no dates chosen initially
      _selectedCategory   = null;
      _startDate          = null;
      _deadline           = null;
      _durationController.text = '60'; // default duration in minutes
    } else {
      // editing existing
      final e = widget.event!;
      _nameController.text     = e.name;
      _selectedCategory        = e.category;
      _startDate               = e.startDate;
      _deadline                = e.deadline;
      _durationController.text = e.duration.inMinutes.toString();
    }
  }

  Future<void> _pickDateTime(
      DateTime? initial,
      void Function(DateTime) onConfirm,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
    );
    if (time == null) return;
    onConfirm(DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    final isEditing = !_isNew;

    // basic validation
    if (_nameController.text.isEmpty) {
      _showError('Please enter a name');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Please choose Home or Work');
      return;
    }

    // duration
    final minutes = int.tryParse(_durationController.text);
    if (minutes == null || minutes <= 0) {
      _showError('Enter a valid duration in minutes');
      return;
    }
    final duration = Duration(minutes: minutes);

    // date rules
    if (_isNew) {
      // must choose exactly one of start or deadline
      if (_startDate == null && _deadline == null) {
        _showError('Please choose either a start date or a deadline');
        return;
      }
      if (_startDate != null && _deadline != null) {
        _showError('Only one of start or deadline can be set');
        return;
      }
    } else {
      // editing fixed: cannot set a deadline
      if (_isFixed && _deadline != null) {
        _showError('You cannot set a deadline on a fixed-date event');
        return;
      }
      // editing deadline: no restriction—both can be set
    }

    // determine type
    final type = _isNew
        ? (_startDate != null ? EventType.fixed : EventType.deadline)
        : widget.event!.type!;

    final event = EventModel(
      id:        widget.event?.id,
      name:      _nameController.text,
      category:  _selectedCategory!,
      type:      type,
      startDate: _startDate,
      deadline:  _deadline,
      duration:  duration,
      subtasks:  widget.event?.subtasks,
      priority:  _isNew ? null : null,
      // widget.event?.priority,
    );

    if (isEditing) {
      await _repo.updateEvent(event);
    } else {
      await _repo.addEvent(event);
    }

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Event updated successfully' : 'Event added successfully',
          ),
        ),
      );
    }
  }

  Future<void> _delete() async {
    if (_isNew) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _repo.deleteEvent(widget.event!.id!);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = !_isNew;

    // which pickers to show?
    final showStart    = _isNew ? (_deadline == null) : true;
    final showDeadline = _isNew ? (_startDate == null) : _isDeadline;
    print('is deadline: ${_isDeadline}');
    if(!_isNew){
    print(widget.event!.type);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Event' : 'Add Event'),
        actions: isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _delete,
                )
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),

              // Category dropdown (fixed list)
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'home', child: Text('Home')),
                  DropdownMenuItem(value: 'work', child: Text('Work')),
                ],
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 20),

              // Start picker
              if (showStart)
                Row(
                  children: [
                    const Text('Start:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () => _pickDateTime(
                          _startDate,
                          (dt) => setState(() => _startDate = dt),
                        ),
                        child: Text(
                          _startDate == null
                              ? 'Choose start'
                              : DateFormat.yMd().add_jm().format(_startDate!),
                        ),
                      ),
                    ),
                    if (_startDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _startDate = null),
                      ),
                  ],
                ),

              // Deadline picker
              if (showDeadline)
                Row(
                  children: [
                    const Text('Deadline:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () => _pickDateTime(
                          _deadline,
                          (dt) => setState(() => _deadline = dt),
                        ),
                        child: Text(
                          _deadline == null
                              ? 'Choose deadline'
                              : DateFormat.yMd().add_jm().format(_deadline!),
                        ),
                      ),
                    ),
                    if (_deadline != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _deadline = null),
                      ),
                  ],
                ),

              const SizedBox(height: 20),

              // Duration input
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                    labelText: 'Duration (minutes)'),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? 'Update' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
