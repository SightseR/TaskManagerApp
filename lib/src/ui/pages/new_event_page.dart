import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../data/event_repository.dart';

class NewEventPage extends StatefulWidget {
  final EventModel? event; // If null, it's a new event

  const NewEventPage({super.key, this.event});

  @override
  State<NewEventPage> createState() => _NewEventPageState();
}

class _NewEventPageState extends State<NewEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  late DateTime _start;
  late DateTime _end;
  final _repo = EventRepository();

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _start = widget.event!.start;
      _end = widget.event!.end;
    } else {
      _start = DateTime.now();
      _end = _start.add(const Duration(hours: 1));
    }
  }

  Future<void> _pickDateTime(DateTime initial, void Function(DateTime) onConfirm) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    onConfirm(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;

  final event = EventModel(
    id: widget.event?.id,
    title: _titleController.text,
    start: _start,
    end: _end,
  );

  if (widget.event == null) {
    await _repo.addEvent(event);
  } else {
    await _repo.updateEvent(event);
  }

  if (mounted) {
    Navigator.pop(context, true); // return to previous screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.event == null
            ? 'Event added successfully'
            : 'Event updated successfully'),
      ),
    );
  }
}


  Future<void> _delete() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Event'),
      content: const Text('Are you sure you want to delete this event?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm == true && widget.event != null) {
    await _repo.deleteEvent(widget.event!.id!);
    if (mounted) {
      Navigator.pop(context, true); // return to previous screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Start: '),
                  TextButton(
                    onPressed: () => _pickDateTime(_start, (dt) => setState(() => _start = dt)),
                    child: Text(DateFormat.yMd().add_jm().format(_start)),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('End:   '),
                  TextButton(
                    onPressed: () => _pickDateTime(_end, (dt) => setState(() => _end = dt)),
                    child: Text(DateFormat.yMd().add_jm().format(_end)),
                  ),
                ],
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