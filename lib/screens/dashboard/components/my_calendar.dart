import 'package:flutter/material.dart';
import 'package:clean_calendar/clean_calendar.dart';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:desktop_window/desktop_window.dart';
import 'dart:async';
import 'package:clean_calendar/clean_calendar.dart';


class Event {
  final DateTime date;
  final String description;
  final Map<String, dynamic> trip;

  Event(this.date, this.description, this.trip);
}

class MyCalendarWidget extends StatefulWidget {
  final String userId;

  MyCalendarWidget({required this.userId});

  @override
  _MyCalendarWidgetState createState() => _MyCalendarWidgetState();
}

class _MyCalendarWidgetState extends State<MyCalendarWidget> {
  late List<Event> _events;
  late DateTime? _rangeStart;
  late DateTime? _rangeEnd;
  late StreamController<List<Event>> _eventsController;

  @override
  void initState() {
    super.initState();
    _eventsController = StreamController<List<Event>>();
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return CleanCalendar(
      datesForStreaks: _generateTripDates(),
      currentDateProperties: DatesProperties(
        //data atuais
        datesDecoration: DatesDecoration(
          datesBorderRadius: 1000,
          datesBackgroundColor: Colors.lightBlue.shade100,
          datesBorderColor: Colors.blue,
          datesTextColor: Colors.black,
        ),
      ),
      weekdaysSymbol: const Weekdays(
        sunday: "dom",
        monday: "seg",
        tuesday: "ter",
        wednesday: "qua",
        thursday: "qui",
        friday: "sex",
        saturday: "sab",
      ),
      monthsSymbol: const Months(
        january: "Janeiro",
        february: "Fevereiro",
        march: "Março",
        april: "Abril",
        may: "Maio",
        june: "Junho",
        july: "Julho",
        august: "Agosto",
        september: "Setembro",
        october: "Outubro",
        november: "Novembro",
        december: "Dezembro",
      ),
      streakDatesProperties: DatesProperties(
        // trips days
        datesDecoration: DatesDecoration(
          datesBorderRadius: 1000,
          datesBackgroundColor: Colors.blue,
          datesBorderColor: Colors.blue,
          datesTextColor: Colors.white,
        ),
      ),
      leadingTrailingDatesProperties: DatesProperties(
        datesDecoration: DatesDecoration(
          datesBorderRadius: 1000,
        ),
      ),
    );
  }

  List<DateTime> _generateTripDates() {
    List<DateTime> tripDates = [];

    for (Event event in _events) {
      DateTime startDate = event.trip['startDate'];
      DateTime endDate = event.trip['endDate'];

      for (DateTime date = startDate;
      date.isBefore(endDate.add(Duration(days: 1)));
      date = date.add(Duration(days: 1))) {
        tripDates.add(date);
      }
    }

    return tripDates;
  }

  Future<List<Map<String, dynamic>>> _getTripsForUser(String userId) async {
    try {
      var db = await mongo.Db.create(
          'mongodb+srv://josewlds:omcapps@cluster0.bnxdvmv.mongodb.net/omcapps?retryWrites=true&w=majority');
      await db.open();

      var trips = await db
          .collection('trips')
          .find(mongo.where.eq('userId', userId))
          .toList();

      await db.close();

      return trips;
    } catch (e) {
      print('Error fetching trips: $e');
      throw e;
    }
  }

  Future<void> _loadEvents() async {
    try {
      List<Map<String, dynamic>> trips = await _getTripsForUser(widget.userId);
      List<Event> events = [];

      DateTime? earliestDate;
      DateTime? latestDate;

      for (var trip in trips) {
        DateTime startDate = trip['startDate'];
        DateTime endDate = trip['endDate'];

        if (earliestDate == null || startDate.isBefore(earliestDate)) {
          earliestDate = startDate;
        }

        if (latestDate == null || endDate.isAfter(latestDate)) {
          latestDate = endDate;
        }

        String description = trip['description'];

        for (DateTime date = startDate;
        date.isBefore(endDate.add(Duration(days: 1)));
        date = date.add(Duration(days: 1))) {
          events.add(Event(date, description, trip));
        }
      }

      setState(() {
        _events = events;
        _rangeStart = earliestDate;
        _rangeEnd = latestDate;
      });

      _eventsController.add(events);

      print('Events loaded: $_events');
    } catch (e) {
      print('Error loading events: $e');
    }
  }
}

