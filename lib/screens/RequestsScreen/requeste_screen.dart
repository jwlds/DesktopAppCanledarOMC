import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:intl/intl.dart';
import 'dart:async';

class Requests extends StatelessWidget {
  final String userId;

  Requests({required this.userId});

  Future<List<Map<String, dynamic>>> _getTripsForUser(String userId) async {
    var db = await mongo.Db.create(
      'mongodb+srv://josewlds:omcapps@cluster0.bnxdvmv.mongodb.net/omcapps?retryWrites=true&w=majority',
    );
    await db.open();

    var trips = await db
        .collection('trips')
        .find()
        .toList();

    await db.close();

    return trips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitações'),
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

            return Container(
              width: double.infinity,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Colaborador')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Data de Saída')),
                  DataColumn(label: Text('Data de Retorno')),
                  DataColumn(label: Text('Deduzido')),
                  DataColumn(label: Text('Tipo')),
                ],
                rows: trips
                    .map(
                      (trip) => DataRow(
                    cells: [
                      DataCell(Text(trip['requester'])),
                      DataCell(
                        Row(
                          children: [
                            _buildStatusIndicator(trip['status']),
                            SizedBox(width: 8),
                            Text(trip['status']),
                          ],
                        ),
                      ),
                      DataCell(Text(DateFormat('dd/MM/yyyy').format(trip['startDate'].toLocal()))),
                      DataCell(Text(DateFormat('dd/MM/yyyy').format(trip['endDate'].toLocal()))),
                      DataCell(
                        Text('${_calculateDaysDifference(trip['startDate'], trip['endDate'])} dias'),
                      ),
                      DataCell(Text(trip['tripType'])),
                    ],
                    onSelectChanged: (selected) {
                      if (selected!) {
                        _showTripDetailsModal(context, trip);
                      }
                    },
                  ),
                )
                    .toList(),
              ),
            );

          }
        },
      ),
    );
  }

  int _calculateDaysDifference(DateTime startDate, DateTime endDate) {
    final difference = endDate.difference(startDate);
    return difference.inDays;
  }


  Widget _buildStatusIndicator(String? status) {
    Color color;
    switch (status?.toLowerCase()) {
      case 'pendente':
        color = Colors.orange;
        break;
      case 'aprovado':
        color = Colors.green;
        break;
      case 'recusado':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
        break;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
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
                Text('Colaborador: ${trip['requester']}'),
                Text('Tipo: ${trip['tripType']}'),
                Text('Data de Saída: $formattedStartDate'),
                Text('Data de Retorno: $formattedEndDate'),
                Text('Dias ausentes: ${_calculateDaysDifference(trip['startDate'], trip['endDate'])} dias'),
                Text('Descrição: ${trip['description']}'),
                Text('Status: ${trip['status']}'),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        updateTripStatus(trip['_id'].$oid.toString(), 'Aprovado');
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(primary: Colors.green),
                      child: Text('Aprovar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        updateTripStatus(trip['_id'].$oid.toString(), 'Recusado');
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(primary: Colors.red),
                      child: Text('Rejeitar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> updateTripStatus(String tripId, String newStatus) async {
    try {
      var db = await mongo.Db.create(
        'mongodb+srv://josewlds:omcapps@cluster0.bnxdvmv.mongodb.net/omcapps?retryWrites=true&w=majority',
      );
      await db.open();




      await db.collection('trips').update(
        mongo.where.eq('_id', mongo.ObjectId.parse(tripId)),
        mongo.modify.set('status', newStatus),
      );

      await db.close();
    } catch (e) {
      print('Error updating trip status: $e');
      throw e;
    }
  }

}
