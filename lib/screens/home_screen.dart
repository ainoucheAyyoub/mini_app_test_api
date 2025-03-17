import 'dart:io';

import 'package:dio/dio.dart';
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
  DateTime? _toDate; //    to store the end date

  int _successCount = 0;
  int _errorCount = 0;
  int _warningCount = 0;
  int _totalEvents = 0;

  @override
  void initState() {
    super.initState();
    _loadCountsFromLocalStorage(); // Load counts first
    loadEventsFromLocalStorage();
    _loadFilterDates(); // used to load the selected dates
  }

  Future<void> _loadCountsFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _successCount = prefs.getInt('successCount') ?? 0;
      _errorCount = prefs.getInt('errorCount') ?? 0;
      _warningCount = prefs.getInt('warningCount') ?? 0;
      _totalEvents = prefs.getInt('totalEvents') ?? 0;
    });
  }

  Future<void> _saveCountsToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('successCount', _successCount);
    await prefs.setInt('errorCount', _errorCount);
    await prefs.setInt('warningCount', _warningCount);
    await prefs.setInt('totalEvents', _totalEvents);
  }

  Future<void> loadEventsFromLocalStorage() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final storedEventsJson = prefs.getString('events');
    //print(' storedEventsJson  $storedEventsJson');

    if (storedEventsJson != null) {
      try {
        final List<dynamic> decodedData = jsonDecode(storedEventsJson);
        events = decodedData.map((json) => Events.fromJson(json)).toList();
        _totalEvents = events.length;
        _successCount = _countStatus(Type.SUCCESS);
        _errorCount = _countStatus(Type.ERROR);
        _warningCount = _countStatus(Type.WARNING);
        _saveCountsToLocalStorage(); // Save counts after loading from local storage

        setState(() {
          isLoading = false;
          _filterEvents(); // pra filtrer les données
        });
        //print('     : ${events.length} ');
      } catch (e) {
        setState(() {
          isLoading = false;
          errorMessage = 'problem fetching data';
        });
        // print(' JSON: $e');
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
        if (_toDate != null && _fromDate!.isAfter(_toDate!)) {
          final temp = _fromDate;
          _fromDate = _toDate;
          _toDate = temp;
        }
        _saveFilterDates();
        _filterEvents();
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
        if (_fromDate != null && _toDate!.isBefore(_fromDate!)) {
          final temp = _toDate;
          _toDate = _fromDate;
          _fromDate = temp;
        }
        _saveFilterDates();
        _filterEvents();
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
      _totalEvents = events.length;
      _successCount = _countStatus(Type.SUCCESS);
      _errorCount = _countStatus(Type.ERROR);
      _warningCount = _countStatus(Type.WARNING);
    });
  }

  @override
  Widget build(BuildContext context) {
    /*print(
      'Building HomeScreen - isLoading: $isLoading, errorMessage: $errorMessage, events length: ${events.length}',
    ); */

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
                          ? '   choose the start date'
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
                          ? '   choose the end date'
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
                  Text(' Success number : $_successCount'),
                  Text(' numbers of errors: $_errorCount'),
                  Text(' numbers WARNING : $_warningCount'),
                  Text(' Total Events: $_totalEvents'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _saveFilterDates(); //save the selected dates
                      _filterEvents(); //     practical application of the filter
                      setState(() {}); // Force a rebuild of the UI
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
      isLoading = false;
      errorMessage = null;
    });

    try {
      final List<Events>? fetchedEvents = await eventsService.getEvents();

      if (fetchedEvents != null && fetchedEvents.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final storedEventsJson = prefs.getString('events');
        List<Events> localEvents = [];
        if (storedEventsJson != null) {
          final List<dynamic> decodedData = jsonDecode(storedEventsJson);
          localEvents =
              decodedData.map((json) => Events.fromJson(json)).toList();
        }

        int newSuccessCount = 0;
        int newErrorCount = 0;
        int newWarningCount = 0;
        int newTotalEvents = 0;
        List<Events> newEventsToAdd = [];

        // فلترة الأحداث الجديدة على حساب التاريخ
        List<Events> filteredFetchedEvents =
            fetchedEvents.where((event) {
              final eventDate = event.date;
              if (_fromDate == null && _toDate == null) return true;
              if (_fromDate != null && _toDate != null) {
                return eventDate != null &&
                    (eventDate.isAtSameMomentAs(_fromDate!) ||
                        eventDate.isAfter(_fromDate!)) &&
                    (eventDate.isAtSameMomentAs(_toDate!) ||
                        eventDate.isBefore(_toDate!));
              }
              if (_fromDate != null)
                return eventDate != null &&
                    (eventDate.isAtSameMomentAs(_fromDate!) ||
                        eventDate.isAfter(_fromDate!));
              if (_toDate != null)
                return eventDate != null &&
                    (eventDate.isAtSameMomentAs(_toDate!) ||
                        eventDate.isBefore(_toDate!));
              return false;
            }).toList();

        for (var newEvent in filteredFetchedEvents) {
          bool exists = localEvents.any(
            (localEvent) => localEvent.id == newEvent.id,
          );
          if (!exists) {
            newEventsToAdd.add(newEvent);
            newTotalEvents++;
            if (newEvent.type == Type.SUCCESS) newSuccessCount++;
            if (newEvent.type == Type.ERROR) newErrorCount++;
            if (newEvent.type == Type.WARNING) newWarningCount++;
          }
        }

        localEvents.addAll(newEventsToAdd);
        _saveEventsToLocalStorage(localEvents);

        setState(() {
          isLoading = false;
          events = localEvents;
          _successCount += newSuccessCount;
          _errorCount += newErrorCount;
          _warningCount += newWarningCount;
          _totalEvents += newTotalEvents;
          _saveCountsToLocalStorage();
        });
      } else if (_totalEvents == 0 && errorMessage == null) {
        errorMessage = 'problem fetching data';
      }
    } on DioException catch (e) {
      setState(() {
        isLoading = false;
        if (e.type == DioExceptionType.connectionError) {
          print('  ');
        } else {
          errorMessage = 'problem fetching data';
        }
      });
    } on SocketException catch (e) {
      setState(() {
        isLoading = false;
        print('SocketException وقع: $e');
        //     errorMessage
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'An unexpected error occurred';
      });
    }
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
