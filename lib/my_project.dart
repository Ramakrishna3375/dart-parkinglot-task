import 'dart:io';
import 'dart:math' as math;

import 'admin.dart';
import 'database/location_service.dart';
import 'models/floor.dart';
import 'models/parking_spot.dart';
import 'models/parking_ticket.dart';
import 'models/pricing_model.dart';
import 'models/vehicle.dart';
import 'patterns/factory_pattern.dart';
import 'patterns/singleton_pattern.dart';

Future<void> main() async {
  final pricing = MinutePricingModel(ratePerMinute: 5);
  final lot = ParkingLot.getInstance(
    name: 'City Lot',
    totalCapacity: 60,
    pricingModel: pricing,
  );

  final floor1 = Floor('Floor1');
  lot.addFloor(floor1);
  final floor2 = Floor('Floor2');
  lot.addFloor(floor2);
  final floor3 = Floor('Floor3');
  lot.addFloor(floor3);
  final floor4 = Floor('Floor4');
  lot.addFloor(floor4);
  for (var spot in [
    ParkingSpotFactory.create(SpotType.TwoWheeler, 'F11'),
    ParkingSpotFactory.create(SpotType.FourWheeler, 'F12'),
    ParkingSpotFactory.create(SpotType.Truck, 'F13'),
  ]) { spot.registerObserver(floor1); lot.addSpot('Floor1', spot); }
  for (var spot in [
    ParkingSpotFactory.create(SpotType.TwoWheeler, 'F21'),
    ParkingSpotFactory.create(SpotType.FourWheeler, 'F22'),
    ParkingSpotFactory.create(SpotType.Truck, 'F23'),
  ]) { spot.registerObserver(floor2); lot.addSpot('Floor2', spot); }
  for (var spot in [
    ParkingSpotFactory.create(SpotType.TwoWheeler, 'F31'),
    ParkingSpotFactory.create(SpotType.FourWheeler, 'F32'),
    ParkingSpotFactory.create(SpotType.Truck, 'F33'),
  ]) { spot.registerObserver(floor3); lot.addSpot('Floor3', spot); }
  for (var spot in [
    ParkingSpotFactory.create(SpotType.TwoWheeler, 'F41'),
    ParkingSpotFactory.create(SpotType.FourWheeler, 'F42'),
    ParkingSpotFactory.create(SpotType.Truck, 'F43'),
  ]) { spot.registerObserver(floor4); lot.addSpot('Floor4', spot); }

  final locationService = _buildLocationService();
  await _initializeLocationService(locationService);

  int ticketCounter = 1;
  final attendants = <String>[];

  while (true) {
    print('\n--- Parking Lot Menu ---');
    print('1. Park Vehicle');
    print('2. Exit Vehicle');
    print('3. Show All Spots');
    print('4. Show Pricing');
    print('5. Admin Mode');
    print('6. Locate City by Coordinates');
    print('7. Quit');
    stdout.write('Select option: ');
    final opt = stdin.readLineSync()?.trim();
    if (opt == '1') {
      stdout.write('Enter vehicle number: ');
      final vnum = stdin.readLineSync() ?? '';
      
      double? lat;
      double? lon;
      String? cityName;
      
      // Retry loop for coordinate input
      while (true) {
        stdout.write('Enter latitude: ');
        final latStr = stdin.readLineSync()?.trim() ?? '';
        lat = double.tryParse(latStr);
        stdout.write('Enter longitude: ');
        final lonStr = stdin.readLineSync()?.trim() ?? '';
        lon = double.tryParse(lonStr);
        
        if (lat == null || lon == null) {
          print('Error: Invalid coordinates. Please enter numeric latitude and longitude.');
          continue;
        }
        
        // Validate coordinate ranges
        if (lat < -90 || lat > 90) {
          print('Error: Latitude must be between -90 and 90. Please enter again.');
          continue;
        }
        
        if (lon < -180 || lon > 180) {
          print('Error: Longitude must be between -180 and 180. Please enter again.');
          continue;
        }
        
        // Get city name from coordinates
        try {
          cityName = await _getCityNameFromCoordinates(locationService, lat, lon);
          if (cityName != null) {
            print('Location: $cityName');
            break;
          } else {
            print('Error: No city found for the entered coordinates. Please enter valid latitude and longitude that match a city in the database.');
            continue;
          }
        } catch (e) {
          print('Error: Failed to lookup location: $e. Please enter coordinates again.');
          continue;
        }
      }
      
      print('Types: 1.Two-wheeler 2.Four-wheeler 3.Truck');
      stdout.write('Enter vehicle type (1-3): ');
      final t = int.tryParse(stdin.readLineSync() ?? '') ?? 1;
      VehicleType vtype;
      SpotType stype;
      if (t == 1) {
        vtype = VehicleType.Motorcycle;
        stype = SpotType.TwoWheeler;
      } else if (t == 2) {
        vtype = VehicleType.Car;
        stype = SpotType.FourWheeler;
      } else {
        vtype = VehicleType.Truck;
        stype = SpotType.Truck;
      }
      final vehicle = VehicleFactory.create(vtype, vnum);
      print('Available Spots:');
      final avail = <ParkingSpot>[];
      for (var floor in lot.floors) {
        for (var spot in floor.spots) {
          if (!spot.isOccupied && spot.type == stype) {
            print('Spot: ${spot.id} (${spot.type} on ${floor.id})');
            avail.add(spot);
          }
        }
      }
      if (avail.isEmpty) {
        print('No available compatible spots for this vehicle type.');
        continue;
      }
      stdout.write('Enter spot id to book: ');
      final spotid = stdin.readLineSync()?.trim();
      ParkingSpot selected;
      try {
        selected = avail.firstWhere((spot) => spot.id == spotid, orElse: () => throw Exception('Invalid or incompatible spot selection.'));
      } catch (e) {
        print('Invalid or incompatible spot selection.');
        continue;
      }
      
      selected.park(vehicle);
      final ticketId = 'T${ticketCounter++}';
      final ticket = ParkingTicket(ticketId, DateTime.now(), vehicle);
      lot.activeTickets[ticketId] = ticket;
      print('Ticket issued: id=${ticket.id} Entry=${ticket.entryTime} Spot=${selected.id} Location=$cityName ($lat, $lon)');
    } else if (opt == '2') {
      stdout.write('Enter ticket id: ');
      final tid = stdin.readLineSync()?.trim();
      var ticket = lot.activeTickets[tid];
      if (ticket == null) {
        print('Ticket not found!');
        continue;
      }
      ticket.exitTime = DateTime.now();
      final duration = ticket.exitTime!.difference(ticket.entryTime);
      final minutes = duration.inMinutes == 0 ? 1 : duration.inMinutes;
      final fee = lot.pricingModel.calculateFee(minutes);
      ticket.isPaid = false;
      while (true) {
        print('Vehicle ${ticket.vehicle.licensePlate} parked for $minutes minute(s), amount owed: Rs.${fee.toStringAsFixed(2)}');
        stdout.write('Pay amount: Rs.');
        final paidStr = stdin.readLineSync() ?? '0';
        final paid = double.tryParse(paidStr) ?? 0.0;
        if (paid < fee) {
          print('Insufficient payment. Please pay at least Rs.${fee.toStringAsFixed(2)}');
        } else {
          print('Payment received: Rs.${paid.toStringAsFixed(2)}. Change: Rs.${(paid-fee).toStringAsFixed(2)}');
          ticket.isPaid = true;
          break;
        }
      }
      for (var floor in lot.floors) {
        for (var spot in floor.spots) {
          if (spot.currentVehicle?.licensePlate == ticket.vehicle.licensePlate) {
            spot.free();
            print('Vehicle ${ticket.vehicle.licensePlate} exited from spot ${spot.id}.');
          }
        }
      }
      lot.activeTickets.remove(tid);
    } else if (opt == '3') {
      for (var floor in lot.floors) {
        print('Floor: ${floor.id}');
        for (var spot in floor.spots) {
          print('Spot ${spot.id} [${spot.type}] - ${spot.isOccupied ? 'OCCUPIED by ${spot.currentVehicle!.licensePlate}' : 'FREE'}');
        }
      }
    } else if (opt == '4') {
      print('Current per minute rate: Rs.${pricing.ratePerMinute.toStringAsFixed(2)}');
    } else if (opt == '5') {
      adminLoop(lot, pricing, attendants);
    } else if (opt == '6') {
      await _handleLocationLookup(locationService);
    } else if (opt == '7') {
      break;
    } else {
      print('Invalid option.');
    }
  }
  print('Exiting Parking Lot App.');
  await locationService.disconnect();
}

Future<String?> _getCityNameFromCoordinates(LocationService service, double lat, double lon) async {
  if (!service.isConnected) {
    try {
      await service.connect();
    } catch (e) {
      throw Exception('Unable to connect to location service: $e');
    }
  }

  try {
    final locations = await service.getAllLocations();
    if (locations.isEmpty) {
      return null;
    }

    // Look for exact match of latitude and longitude
    final exactMatches = locations.where(
      (location) => location.latitude == lat && location.longitude == lon,
    ).toList();

    if (exactMatches.isEmpty) {
      return null; // No exact match found
    }

    return exactMatches.first.city;
  } catch (e) {
    throw Exception('Failed to fetch locations: $e');
  }
}

Future<void> _handleLocationLookup(LocationService service) async {
  if (!service.isConnected) {
    try {
      await service.connect();
    } catch (e) {
      print('Unable to connect to location service: $e');
      return;
    }
  }

  stdout.write('Enter latitude: ');
  final lat = double.tryParse(stdin.readLineSync()?.trim() ?? '');
  stdout.write('Enter longitude: ');
  final lon = double.tryParse(stdin.readLineSync()?.trim() ?? '');
  if (lat == null || lon == null) {
    print('Invalid coordinates. Please enter numeric latitude and longitude.');
    return;
  }

  try {
    final locations = await service.getAllLocations();
    if (locations.isEmpty) {
      print('No locations found in the database.');
      return;
    }

    final locationDistances = locations
        .map((location) => (
              location: location,
              distanceKm:
                  _calculateDistanceKm(lat, lon, location.latitude, location.longitude),
            ))
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    final nearest = locationDistances.first;
    print('Nearest city: ${nearest.location.city} '
        '(${nearest.location.latitude}, ${nearest.location.longitude}) '
        '- Distance: ${nearest.distanceKm.toStringAsFixed(2)} km');

    final exactMatch = locationDistances.where((entry) {
      return _isClose(entry.location.latitude, lat) &&
          _isClose(entry.location.longitude, lon);
    }).toList();

    if (exactMatch.isNotEmpty) {
      print('Exact match found for the provided coordinates: '
          '${exactMatch.first.location.city}.');
    }

    print('\nClosest locations:');
    for (final entry in locationDistances.take(5)) {
      final loc = entry.location;
      print('- ${loc.city.padRight(12)} | '
          'Lat: ${loc.latitude.toStringAsFixed(2)} | '
          'Lon: ${loc.longitude.toStringAsFixed(2)} | '
          'Distance: ${entry.distanceKm.toStringAsFixed(2)} km');
    }
  } catch (e) {
    print('Failed to fetch locations: $e');
  }
}

LocationService _buildLocationService() {
  final env = Platform.environment;
  final host = env['LOCATION_DB_HOST'] ?? 'localhost';
  final port = int.tryParse(env['LOCATION_DB_PORT'] ?? '5432') ?? 5432;
  final user = env['LOCATION_DB_USER'] ?? 'postgres';
  final password = env['LOCATION_DB_PASSWORD'] ?? '12345677';
  final database = env['LOCATION_DB_NAME'] ?? 'postgres';

  return LocationService(
    host: host,
    port: port,
    user: user,
    password: password,
    database: database,
  );
}

Future<void> _initializeLocationService(LocationService service) async {
  try {
    await service.connect();
  } catch (e) {
    print(
      'Warning: Could not connect to the location service on startup. '
      'Location lookups will retry when requested. ($e)',
    );
  }
}

double _calculateDistanceKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadiusKm = 6371.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.pow(math.sin(dLon / 2), 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double degrees) => degrees * (math.pi / 180);

bool _isClose(double a, double b, [double tolerance = 0.01]) =>
    (a - b).abs() <= tolerance;
