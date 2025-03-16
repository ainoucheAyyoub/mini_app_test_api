import 'package:flutter/material.dart';
import 'package:mini_projet/modules/events.dart';
import 'package:mini_projet/services/envents_services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EventsService eventsService = EventsService();
  List<Events> events = [];
  bool isLoading = false;
  String? errorMessage;

  DateTime? _fromDate; //   to store the start date
  DateTime? _toDate; //  to store the end date

  @override
  void initState() {
    super.initState();
    loadEventsFromLocalStorage();
    _loadFilterDates(); // used to load the selected dates
  }

  Future<void> loadEventsFromLocalStorage() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final storedEventsJson = prefs.getString('events');

    if (storedEventsJson != null) {
      try {
        final List<dynamic> decodedData = jsonDecode(storedEventsJson);
        events = decodedData.map((json) => Events.fromJson(json)).toList();
        //
        setState(() {
          isLoading = false;
          _filterEvents(); // pra filtrer les données
        });
      } catch (e) {
        setState(() {
          isLoading = false;
          errorMessage = 'problem fetching data';
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadFilterDates() async {
    final prefs = await SharedPreferences.getInstance();
    final fromDateMillis = prefs.getInt('fromDate');
    final toDateMillis = prefs.getInt('toDate');

    setState(() {
      _fromDate =
          fromDateMillis != null
              ? DateTime.fromMillisecondsSinceEpoch(fromDateMillis)
              : null;
      _toDate =
          toDateMillis != null
              ? DateTime.fromMillisecondsSinceEpoch(toDateMillis)
              : null;
      _filterEvents(); //     for filter the data
    });
  }

  Future<void> _saveFilterDates() async {
    final prefs = await SharedPreferences.getInstance();
    if (_fromDate != null) {
      await prefs.setInt('fromDate', _fromDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('fromDate');
    }
    if (_toDate != null) {
      await prefs.setInt('toDate', _toDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('toDate');
    }
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != _fromDate) {
      setState(() {
        _fromDate = picked;
        // if the end date is set and the new start date is after the end date, swap them
        if (_toDate != null && _fromDate!.isAfter(_toDate!)) {
          final temp = _fromDate;
          _fromDate = _toDate;
          _toDate = temp;
        }
        _filterEvents(); //     for filter the data
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != _toDate) {
      setState(() {
        _toDate = picked;
        //if the start date is set and the new end date is before the start date, swap them
        if (_fromDate != null && _toDate!.isBefore(_fromDate!)) {
          final temp = _toDate;
          _toDate = _fromDate;
          _fromDate = temp;
        }
        _filterEvents(); //     for filter the data
      });
    }
  }

  void _filterEvents() {
    setState(() {
      events =
          events.where((event) {
            final eventDate = event.date;
            if (_fromDate == null && _toDate == null) {
              return true; // no filter
            } else if (_fromDate != null && _toDate != null) {
              return eventDate != null &&
                  (eventDate.isAtSameMomentAs(_fromDate!) ||
                      eventDate.isAfter(_fromDate!)) &&
                  (eventDate.isAtSameMomentAs(_toDate!) ||
                      eventDate.isBefore(_toDate!));
            } else if (_fromDate != null) {
              return eventDate != null &&
                  (eventDate.isAtSameMomentAs(_fromDate!) ||
                      eventDate.isAfter(_fromDate!));
            } else if (_toDate != null) {
              return eventDate != null &&
                  (eventDate.isAtSameMomentAs(_toDate!) ||
                      eventDate.isBefore(_toDate!));
            }
            return false;
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SmartAgri Radio')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(onPressed: fetchEvents, child: Text(' bring data')),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () => _selectFromDate(context),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _fromDate == null
                          ? '  choose the start date'
                          : 'Start: ${_fromDate!.day}-${_fromDate!.month}-${_fromDate!.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _selectToDate(context),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _toDate == null
                          ? '  choose the end date'
                          : 'End: ${_toDate!.day}-${_toDate!.month}-${_toDate!.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (isLoading)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              )
            else if (errorMessage != null)
              Text(errorMessage!, style: TextStyle(color: Colors.red))
            else
              Column(
                children: [
                  Text(' Success number : ${_countStatus(Type.SUCCESS)}'),
                  Text(' numbers of errors: ${_countStatus(Type.ERROR)}'),
                  Text(' numbers WARNING : ${_countStatus(Type.WARNING)}'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _saveFilterDates(); //save the selected dates
                      _filterEvents(); //     practical application of the filter
                    },
                    child: Text(' View Events'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchEvents() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final List<Events>? fetchedEvents = await eventsService.getEvents();

    setState(() {
      isLoading = false;
      if (fetchedEvents != null && fetchedEvents.isNotEmpty) {
        events = fetchedEvents;
        _saveEventsToLocalStorage(
          fetchedEvents,
        ); //Save the data in the Local Storage
        _filterEvents(); //practical application of the filter
      } else {
        errorMessage = 'problem fetching data';
      }
    });
  }

  Future<void> _saveEventsToLocalStorage(List<Events> events) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = jsonEncode(events.map((e) => e.toJson()).toList());
    await prefs.setString('events', eventsJson);
  }

  int _countStatus(Type status) {
    return events
        .where((event) => event.type != null && event.type == status)
        .length;
  }
}
