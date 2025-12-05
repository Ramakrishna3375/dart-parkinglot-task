import 'package:postgres/postgres.dart';

class LocationDetails {
  final String city;
  final double longitude;
  final double latitude;

  LocationDetails({
    required this.city,
    required this.longitude,
    required this.latitude,
  });

  @override
  String toString() {
    return 'LocationDetails(city: $city, coordinates: ($latitude, $longitude))';
  }
}

class LocationService {
  PostgreSQLConnection? _connection;
  bool _isConnected = false;

  // Database connection parameters
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;

  LocationService({
    required this.host,
    this.port = 5432,
    required this.user,
    required this.password,
    required this.database,
  });

  /// Connect to the PostgreSQL database
  Future<void> connect() async {
    try {
      _connection = PostgreSQLConnection(
        host,
        port,
        database,
        username: user,
        password: password,
      );

      await _connection!.open();
      _isConnected = true;
      print('Successfully connected to database: $database');
    } catch (e) {
      _isConnected = false;
      print('Error connecting to database: $e');
      rethrow;
    }
  }

  /// Disconnect from the database
  Future<void> disconnect() async {
    if (_isConnected && _connection != null) {
      await _connection!.close();
      _isConnected = false;
      print('Disconnected from database');
    }
  }

  /// Get all location details
  Future<List<LocationDetails>> getAllLocations() async {
    if (!_isConnected || _connection == null) {
      throw Exception('Not connected to database. Call connect() first.');
    }

    try {
      final results = await _connection!.query(
        'SELECT city, longitude, latitude FROM location ORDER BY city',
      );

      return results.map((row) {
        return LocationDetails(
          city: row[0] as String,
          longitude: (row[1] as num).toDouble(),
          latitude: (row[2] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      print('Error fetching all locations: $e');
      rethrow;
    }
  }

  /// Check if connected to database
  bool get isConnected => _isConnected;
}

