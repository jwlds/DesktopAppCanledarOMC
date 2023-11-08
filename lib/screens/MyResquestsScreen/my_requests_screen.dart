import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:intl/intl.dart';
import 'dart:async';

class MyRequests extends StatelessWidget {
  final String userId;

  MyRequests({required this.userId});

  Future<List<Map<String, dynamic>>> _getTripsForUser(String userId) async {
    var db = await mongo.Db.create(
      'mongodb+srv://josewlds:omcapps@cluster0.bnxdvmv.mongodb.net/omcapps?retryWrites=true&w=majority',
    );
    await db.open();

    var trips = await db
        .collection('trips')
        .find(mongo.where.eq('userId', userId))
        .toList();

    await db.close();

    return trips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Requests'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getTripsForUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar viagens: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Nenhuma viagem encontrada.'),
            );
          } else {
            List<Map<String, dynamic>> trips = snapshot.data!;

            return ListView.builder(
              itemCount: trips.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      'Tipo de Viagem: ${trips[index]['tripType']}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data de Saída: ${trips[index]['startDate']}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Data de Retorno: ${trips[index]['endDate']}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Origem: ${trips[index]['origin']} | Destino: ${trips[index]['destination']}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    onTap: () => _showTripDetailsModal(context, trips[index]),
                  ),
                );
              },
            );

          }
        },
      ),
    );
  }

  void _showTripDetailsModal(BuildContext context, Map<String, dynamic> trip) {
    String formattedStartDate = DateFormat('dd/MM/yyyy').format(trip['startDate'].toLocal());
    String formattedEndDate = DateFormat('dd/MM/yyyy').format(trip['endDate'].toLocal());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalhes da Viagem'),
          content: Container(
            width: 300.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Tipo de Viagem: ${trip['tripType']}'),
                Text('Data de Saída: $formattedStartDate'),
                Text('Data de Retorno: $formattedEndDate'),
                Text('Descrição: ${trip['description']}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
