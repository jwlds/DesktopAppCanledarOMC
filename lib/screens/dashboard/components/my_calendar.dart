import 'package:flutter/material.dart';
import 'package:clean_calendar/clean_calendar.dart';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:desktop_window/desktop_window.dart';
import 'dart:async';
import 'package:clean_calendar/clean_calendar.dart';
import 'package:omc_sis_calendar/controllers/MenuAppController.dart';
import 'package:omc_sis_calendar/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

import '../../../constants.dart';


class Event {
  final DateTime date;
  final String description;
  final Map<String, dynamic> trip;

  Event(this.date, this.description, this.trip);
}

class MyCalendarWidget extends StatefulWidget {
  final String userId;

  MyCalendarWidget({required this.userId, Key? key}) : super(key: key);

  @override
  _MyCalendarWidgetState createState() => _MyCalendarWidgetState();
}

final GlobalKey<_MyCalendarWidgetState> calendarKey = GlobalKey<_MyCalendarWidgetState>();

class _MyCalendarWidgetState extends State<MyCalendarWidget> {
  late List<Event> _events = [];
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
    return Column(
      children: [
      Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: defaultPadding * 1.5,
              vertical: defaultPadding / (Responsive.isMobile(context) ? 2 : 1),
            ),
          ),
          onPressed: () {
            _openAddModal(context, widget.userId);
          },
          icon: Icon(Icons.add),
          label: Text("Solicitação"),
        ),
      ],
      ),
        SizedBox(height: 16),
    CleanCalendar(
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
    )
      ],
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

  void _openAddModal(BuildContext context,String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Solicitação'),
          content:AddModal(userId: userId, loadEvents: _loadEvents),
        );
      },
    );
  }
}

class Header extends StatelessWidget {
  final String userId;
  const Header({
    Key? key,
    required this.userId
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        if (!Responsive.isDesktop(context))
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: context.read<MenuAppController>().controlMenu,
          ),
        if (!Responsive.isMobile(context))
          Text(
            "Dashboard",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        if (!Responsive.isMobile(context))
          Spacer(flex: Responsive.isDesktop(context) ? 2 : 1),
        ProfileCard(userId: userId,)
      ],
    );
  }
}



class AddModal extends StatefulWidget {
  final String userId;
  final Function loadEvents;

  AddModal({required this.userId, required this.loadEvents});

  @override
  _AddModalState createState() => _AddModalState();
}

class _AddModalState extends State<AddModal> {
  bool _isSaving = false;
  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;
  late String _selectedTripType;
  late String _description;
  late String _requester;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = DateTime.now();
    _selectedEndDate = DateTime.now();
    _selectedTripType = 'ferias';
    _description = '';
    _requester = '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      padding: const EdgeInsets.all(4.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _requester = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Solicitante',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            DropdownButton<String>(
              value: _selectedTripType,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTripType = newValue!;
                });
              },
              items: [
                ...<String>['Selecione o motivo da ausência', 'ferias', 'trabalho', 'medico']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: TextStyle(fontSize: 16)),
                  );
                }).toList(),
              ],
              hint: Text('Motivo da ausência', style: TextStyle(fontSize: 18)),
              isExpanded: true,
            ),
            SizedBox(height: 16),
            Text('Data de saída', style: TextStyle(fontSize: 18)),
            InkWell(
              onTap: () => _selectDate(context, true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedStartDate.toLocal()}'.split(' ')[0],
                      style: TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text('Data de retorno', style: TextStyle(fontSize: 18)),
            InkWell(
              onTap: () => _selectDate(context, false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedEndDate.toLocal()}'.split(' ')[0],
                      style: TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              onChanged: (value) {
                setState(() {
                  _description = value;
                });
              },
              maxLines: 5,  // Defina o número desejado de linhas
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                setState(() {
                  _isSaving = true;
                });

                await _saveDataToDatabase(widget.userId);

                setState(() {
                  _isSaving = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Dados salvos com sucesso!'),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.blue[900],
                minimumSize: Size(800, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : const Text(
                'Salvar',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _selectedStartDate : _selectedEndDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = selectedDate;
        } else {
          _selectedEndDate = selectedDate;
        }
      });
    }
  }

  Future<void> _saveDataToDatabase(String id) async {
    String userId = id;

    var db = await mongo.Db.create(
        'mongodb+srv://josewlds:omcapps@cluster0.bnxdvmv.mongodb.net/omcapps?retryWrites=true&w=majority');
    await db.open();

    await db.collection('trips').insert({
      'createdAt': DateTime.now(),
      'userId': userId,
      'requester': _requester,
      'tripType': _selectedTripType,
      'startDate': _selectedStartDate.toUtc(),
      'endDate': _selectedEndDate.toUtc(),
      'description': _description,
      'status': "Pendente"
    });

    await db.close();

    widget.loadEvents();
  }
}





Future<String?> getUserName(String userId) async {


  var db = await mongo.Db.create(
    'mongodb+srv://josewlds:omcapps@cluster0.bnxdvmv.mongodb.net/omcapps?retryWrites=true&w=majority',
  );

  await db.open();

  var user = await db.collection('users').findOne(mongo.where.eq('_id', mongo.ObjectId.parse(userId)));

  await db.close();

  if (user != null && user['name'] != null) {
    print('Nome do usuário encontrado: ${user['name']}');
    return user['name'];
  } else {
    print('Usuário não encontrado ou não possui nome');
    return null;
  }
}


class ProfileCard extends StatelessWidget {
  final String userId;

  const ProfileCard({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getUserName(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Erro ao obter o nome do usuário');
        } else {
          String? userName = snapshot.data;

          return Container(
            margin: EdgeInsets.only(left: defaultPadding),
            padding: EdgeInsets.symmetric(
              horizontal: defaultPadding,
              vertical: defaultPadding / 2,
            ),
            decoration: BoxDecoration(
              color: secondaryColor,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/profile_pic.png',
                  height: 38,
                ),
                if (!Responsive.isMobile(context))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: defaultPadding / 2),
                    child: Text(userName ?? 'Nome do usuário não encontrado'),
                  ),
                Icon(Icons.keyboard_arrow_down),
              ],
            ),
          );
        }
      },
    );
  }
}


