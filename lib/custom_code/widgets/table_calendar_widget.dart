// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:table_calendar/table_calendar.dart';

class TableCalendarWidget extends StatefulWidget {
  const TableCalendarWidget({
    super.key,
    this.width,
    this.height,
    required this.rebuildpage,
    required this.listEvents,
    required this.listblock,
  });

  final double? width;
  final double? height;
  final Future Function() rebuildpage;
  final List<EventssStruct> listEvents;
  final List<DateTime> listblock;

  @override
  _TableCalendarWidgetState createState() => _TableCalendarWidgetState();
}

class _TableCalendarWidgetState extends State<TableCalendarWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  TextEditingController _eventControlller = TextEditingController();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> events = {};
  late final ValueNotifier<List<Event>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    List<Event> eventsForDay = <Event>[];
    for (int i = 0; i < widget.listEvents.length; i++) {
      final eevent = widget.listEvents[i];
      if (isSameDay(day, eevent.dayy!)) {
        eventsForDay.add(Event(
          title: eevent.title,
          date: eevent.dayy!,
        ));
      }
    }
    return eventsForDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          TableCalendar<Event>(
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            firstDay: DateTime.utc(2010, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            startingDayOfWeek: StartingDayOfWeek.monday,
            focusedDay: _focusedDay,
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            calendarFormat: _calendarFormat,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
            ),
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            enabledDayPredicate: (day) {
              for (var blockedDay in widget.listblock) {
                if (isSameDay(day, blockedDay)) {
                  return false;
                }
              }
              return true;
            },
          ),
          SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: () async {
                          FFAppState().titlee = value[index].title;
                          FFAppState().dayyy = value[index].date;
                          await widget.rebuildpage();
                        },
                        title: Text(value[index].title),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Event {
  final String title;
  final DateTime date;

  Event({required this.title, required this.date});
}
