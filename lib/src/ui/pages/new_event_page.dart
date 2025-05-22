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
  final _nameController = TextEditingController();

  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _deadline;

  static const _defaultDuration = Duration(hours: 1);
  final _repo = EventRepository();

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      // Editing: prefill fields
      _nameController.text = widget.event!.name;
      _selectedCategory = widget.event!.category;
      _startDate = widget.event!.startDate;
      _deadline = widget.event!.deadline;
    } else {
      // New event: start with no date chosen
      _selectedCategory = null;
      _startDate = null;
      _deadline = null;
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
      initialTime:
          TimeOfDay.fromDateTime(initial ?? DateTime.now()),
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
    final isEditing = widget.event != null;
    final originallyDeadline =
        isEditing && widget.event!.deadline != null && widget.event!.startDate == null;

    // Validation
    if (_nameController.text.isEmpty) {
      _showError('Please enter a name');
      return;
    }
    if (_selectedCategory == null) {
      _showError('Please choose a category');
      return;
    }
    // If this is not an existing deadline event, require exactly one of start/deadline
    if (!originallyDeadline) {
      if (_startDate == null && _deadline == null) {
        _showError('Please set either a start date or a deadline');
        return;
      }
      if (_startDate != null && _deadline != null) {
        _showError('Please choose only one: start OR deadline');
        return;
      }
    }

    // Determine type
    final type = originallyDeadline
        ? EventType.deadline
        : (_startDate != null ? EventType.fixed : EventType.deadline);

    // Determine duration
    final duration = isEditing
        ? widget.event!.duration
        : _defaultDuration;

    final event = EventModel(
      id:        widget.event?.id,
      name:      _nameController.text,
      category:  _selectedCategory!,
      type:      type,
      startDate: _startDate,
      deadline:  type == EventType.deadline ? _deadline : null,
      duration:  duration,
      subtasks:  widget.event?.subtasks,
      priority:  1,
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
    if (widget.event == null) return;
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
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
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
    final isEditing = widget.event != null;
    final originallyDeadline =
        isEditing && widget.event!.deadline != null && widget.event!.startDate == null;

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
        child: Column(
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

            // START picker: show if either no deadline chosen, or editing an existing deadline event
            if (_deadline == null || originallyDeadline)
              Row(
                children: [
                  const Text('Start:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _pickDateTime(
                          _startDate, (dt) => setState(() => _startDate = dt)),
                      child: Text(_startDate == null
                          ? 'Choose start'
                          : DateFormat.yMd().add_jm().format(_startDate!)),
                    ),
                  ),
                  if (_startDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _startDate = null),
                    ),
                ],
              ),

            // DEADLINE picker: show if no start chosen
            if (_startDate == null)
              Row(
                children: [
                  const Text('Deadline:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _pickDateTime(
                          _deadline, (dt) => setState(() => _deadline = dt)),
                      child: Text(_deadline == null
                          ? 'Choose deadline'
                          : DateFormat.yMd().add_jm().format(_deadline!)),
                    ),
                  ),
                  if (_deadline != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _deadline = null),
                    ),
                ],
              ),

            const SizedBox(height: 30),

            // Save button
            ElevatedButton(
              onPressed: _save,
              child: Text(isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
