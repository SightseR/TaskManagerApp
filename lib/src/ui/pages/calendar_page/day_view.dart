import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sfcal;
import '../../../models/event_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/event_repository.dart';
import '../new_event_page.dart';
import '../../../bloc/calendar/calendar_bloc.dart';
import '../../../bloc/calendar/calendar_event.dart';
import '../../../widgets/event_list_tile.dart';

class DayView extends StatefulWidget {
  final List<EventModel> assignedEvents;
  final List<EventModel> unassignedEvents;
  final DateTime date;
  DayView({
    super.key,
    required this.assignedEvents,
    required this.unassignedEvents,
    DateTime? date,
  })  : date = date ?? DateTime.now();

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  final GlobalKey _calendarKey = GlobalKey();
  bool _showList = false;
  bool _dragging = false;
  late DateTime _selectedDate;
  late List<EventModel> _unassignedEvents;
  late List<EventModel> _assignedEvents;

  @override
  void initState() {
    super.initState();
    _assignedEvents = List<EventModel>.from(widget.assignedEvents);
    _unassignedEvents = List<EventModel>.from(widget.unassignedEvents);
    _selectedDate = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );
    _updateSelectedEvents();
  }

  void _updateSelectedEvents() {
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay =
        startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    _assignedEvents = _assignedEvents.where((e) {
      return e.startDate!.add(e.duration).isAfter(startOfDay) &&
             e.startDate!.isBefore(endOfDay);
    }).toList();
    setState(() {});
  }

  Color _getColorForPriority(int? priority) {
    switch (priority) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orangeAccent;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double startHour = _assignedEvents.isEmpty
        ? 6
        : math.min(
            6,
            _assignedEvents
                .map((e) => e.startDate!.hour + e.startDate!.minute / 60)
                .reduce(math.min)
                .floorToDouble(),
          );

    final double endHour = _assignedEvents.isEmpty
        ? 20
        : math.max(
            20,
            _assignedEvents
                .map((e) => e.startDate!.add(e.duration).hour +
                            e.startDate!.add(e.duration).minute / 60)
                .reduce(math.max)
                .ceilToDouble(),
          );

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final visibleHours = endHour - startHour + 5;
              final cellHeight = constraints.maxHeight / visibleHours;

              return Stack(
                children: [
                  sfcal.SfCalendar(
                    key: _calendarKey,
                    view: sfcal.CalendarView.day,
                    initialDisplayDate: _selectedDate,
                    dataSource: _DataSource(
                      _assignedEvents.map((e) {
                        return sfcal.Appointment(
                          startTime: e.startDate!,
                          endTime: e.startDate!.add(e.duration),
                          subject: e.name,
                          notes: e.id.toString(),
                          color: _getColorForPriority(e.priority),
                        );
                      }).toList(),
                    ),
                    allowDragAndDrop: false,
                    allowAppointmentResize: false,
                    allowViewNavigation: false,
                    timeSlotViewSettings: sfcal.TimeSlotViewSettings(
                      startHour: startHour,
                      endHour: endHour,
                      timeIntervalHeight: cellHeight,
                    ),
                    firstDayOfWeek: DateTime.monday,
                    onTap: (details) {
                      if (!_dragging && details.date != null) {
                        setState(() {
                          _selectedDate = DateTime(
                            details.date!.year,
                            details.date!.month,
                            details.date!.day,
                          );
                          _updateSelectedEvents();
                          _showList = !_showList;
                        });
                      }
                    },
                    onLongPress: (sfcal.CalendarLongPressDetails details) async {
                      if (details.appointments != null &&
                          details.appointments!.isNotEmpty) {
                        final tapped = details.appointments!.first;
                        final id = int.tryParse(tapped.notes ?? '');
                        if (id != null) {
                          final repo = EventRepository();
                          final events = await repo.getAssignedEvents();
                          final event = events.firstWhere((e) => e.id == id);
                          final refresh = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NewEventPage(event: event),
                            ),
                          );
                          if (refresh == true && context.mounted) {
                            context.read<CalendarBloc>().add(LoadEvents());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Changes applied')),
                            );
                          }
                        }
                      }
                    },
                  ),
                  Positioned.fill(
                    child: DragTarget<EventModel>(
                      onWillAcceptWithDetails: (_) => true,
                      onAcceptWithDetails: (details) async {
                        setState(() => _dragging = false);
                        final event = details.data;
                        final global = details.offset;
                        final box = _calendarKey.currentContext!.findRenderObject()
                            as RenderBox;
                        final local = box.globalToLocal(global);

                        final hourOffset = local.dy / cellHeight;
                        final totalHour = startHour + hourOffset - 2;
                        final int h = totalHour.floor();
                        final int m = ((totalHour - h) * 60).round();
                        final calculated = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          h,
                          m - m % 15,
                        );

                        final updated = EventModel(
                          id: event.id,
                          name: event.name,
                          startDate: calculated,
                          duration: event.duration,
                          deadline: event.deadline,
                          category: event.category,
                          priority: event.priority,
                          type: event.type,
                          subtasks: event.subtasks,
                        );

                        final idx = _unassignedEvents.indexWhere((e) => e.id == updated.id);
                        if (idx != -1) {
                          _unassignedEvents.removeAt(idx);
                        } else {
                          _assignedEvents.add(updated);
                        }

                        setState(() {});
                        await EventRepository().updateEvent(updated);
                        context.read<CalendarBloc>().add(LoadEvents());
                        _updateSelectedEvents();
                      },
                      builder: (ctx, cand, rej) => _dragging
                          ? Container(color: Colors.transparent)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (_showList) ...[
          const VerticalDivider(width: 1),
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: _unassignedEvents.length,
              itemBuilder: (context, index) {
                final ev = _unassignedEvents[index];
                return Draggable<EventModel>(
                  data: ev,
                  onDragStarted: () => setState(() => _dragging = true),
                  onDragEnd: (_) => setState(() => _dragging = false),
                  feedback: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                      maxHeight: 100,
                    ),
                    child: Material(
                      elevation: 4,
                      child: EventListTile(event: ev),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: EventListTile(event: ev),
                  ),
                  child: EventListTile(event: ev),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _DataSource extends sfcal.CalendarDataSource {
  _DataSource(List<sfcal.Appointment> source) {
    appointments = source;
  }
}
