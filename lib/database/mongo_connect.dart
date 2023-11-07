class MongoConstants {
  static const String username = 'josewlds';
  static const String password = 'omcapps';
  static const String clusterUrl = 'cluster0.bnxdvmv.mongodb.net';
  static const String databaseName = 'omcapps';

  static String get connectionString => 'mongodb://$username:$password@$clusterUrl/$databaseName?retryWrites=true&w=majority';
}