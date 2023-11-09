import 'package:cell_calendar/cell_calendar.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class CalendarAdm extends StatefulWidget {
  final String userId;

  CalendarAdm({required this.userId, Key? key}) : super(key: key);
  @override
  _CalendarAdmState createState() => _CalendarAdmState();
}

class _CalendarAdmState extends State<CalendarAdm> {
  List<Appointment> appointments = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => _loadEvents());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      List<Map<String, dynamic>> trips = await _getTripsForUser();

      List<Event> events = [];

      for (var trip in trips) {
        Color background = const Color(0xFFFFFFFF);
        DateTime startDate = trip['startDate'];
        DateTime endDate = trip['endDate'];
        String description = trip['requester'];
        if(trip['tripType'] == 'Folga') {
          background = const Color(0xFFF6FF00);
        } else if(trip['tripType'] == 'Férias') {
          background = const Color(0xFF0F8644);
        } else {
          background = Colors.lightBlue;
        }

        events.add(Event(startDate, endDate, description,background));
      }

      setState(() {
        appointments = getAppointments(events);
      });

      print('Events loaded: $appointments');
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getTripsForUser() async {
    try {
      var db = await mongo.Db.create(
          'mongodb+srv://josewlds:omcapps@cluster0.bnxdvmv.mongodb.net/omcapps?retryWrites=true&w=majority');
      await db.open();

      var trips = await db
          .collection('trips')
          .find()
          .toList();

      await db.close();

      return trips;
    } catch (e) {
      print('Error fetching trips: $e');
      throw e;
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

  List<Appointment> getAppointments(List<Event> events) {
    List<Appointment> meetings = [];

    for (Event event in events) {
      meetings.add(Appointment(
        startTime: event.startDate,
        endTime: event.endDate,
        subject: event.description,
        color: event.background,
        isAllDay: false,
      ));
    }

    return meetings;
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
                  horizontal: 16.0,
                  vertical: 16.0 ,
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
        SfCalendar(
          view: CalendarView.week,
          firstDayOfWeek: 6,
          dataSource: MeetingDataSource(appointments),
          timeSlotViewSettings: TimeSlotViewSettings(
            timeTextStyle: TextStyle(fontSize: 0),
          ),
        //  appointmentTextStyle: TextStyle(fontSize: 16),
        ),
      ],
    );
  }



}

class Event {
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final Color background;

  Event(this.startDate, this.endDate, this.description,this.background);
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
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
  bool _isRequesterLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = DateTime.now();
    _selectedEndDate = DateTime.now();
    _selectedTripType = 'Selecione o tipo da ausência';
    _description = '';
    _requester = '';
    _loadRequesterName();
  }

  Future<void> _loadRequesterName() async {
    String? requester = await getUserName(widget.userId);
    _requester = requester ?? '';
    setState(() {
      _isRequesterLoaded = true;
    });
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
              controller: _isRequesterLoaded ? TextEditingController(text: _requester) : null,
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
                ...<String>['Selecione o tipo da ausência','Férias', 'Folga', 'Médico']
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
              onPressed: (_isSaving || _selectedTripType == 'Selecione o tipo da ausência' || _requester.isEmpty || _description.isEmpty)
                  ? null
                  : () async {
                setState(() {
                  _isSaving = true;
                });
                // User user = await getUserById(widget.userId);
                await _saveDataToDatabase(widget.userId);
                await sendEmail(
                  name: _requester,
                  email: "jose.wls.dev@gmail.com",
                  subject: 'Solicitação de ausência OMC GROUP',
                  message: 'This is a test message.',
                );

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
            )

          ],
        ),
      ),
    );
  }

  Future sendEmail({
    required String name,
    required String email,
    required String subject,
    required String message,

  }) async {

    final serviceId = 'service_k1srwdp';
    final templateId = 'template_67o9g3h';
    final userId = 'GVt4sKmkIYM8g7vEY';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'Content-type':'application/json'
      },body: json.encode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id':userId,
      'template_params': {
        'user_name':name,
        'user_email':email,
        'user_subject': subject,
        'user_message': message
      }
    }),
    );
    print(response.body);
  }





  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime initialDate = isStartDate ? _selectedStartDate : _selectedEndDate;
    DateTime currentDate = DateTime.now();

    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(currentDate) ? currentDate : initialDate,
      firstDate: currentDate,
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
