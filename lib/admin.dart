import 'dart:io';
import 'patterns/singleton_pattern.dart';
import 'models/pricing_model.dart';
import 'patterns/factory_pattern.dart';
import 'models/floor.dart';
import 'models/parking_spot.dart';

void adminLoop(ParkingLot lot, MinutePricingModel pricing, List<String> attendants) {
  while (true) {
    print('\n--- ADMIN MODE ---');
    print('1. Add Floor');
    print('2. Remove Floor');
    print('3. Add Spot');
    print('4. Remove Spot');
    print('5. Add Attendant');
    print('6. Remove Attendant');
    print('7. Change per minute rate');
    print('8. List Attendants');
    print('9. Back to Main');
    stdout.write('Admin option: ');
    final cmd = stdin.readLineSync()?.trim();

    if (cmd == '1') { // Add Floor
      stdout.write('Floor name/id: ');
      final id = stdin.readLineSync();
      if (id == null || id.isEmpty) {
        print('Floor id cannot be empty.');
        continue;
      }
      try {
        lot.addFloor(Floor(id));
        print('Floor $id added.');
      } catch (e) {
        print('Error adding floor: $e');
      }
    } else if (cmd == '2') { // Remove Floor
      stdout.write('Floor name to remove: ');
      final id = stdin.readLineSync();
      lot.floors.removeWhere((f) => f.id == id);
      print('Floor $id removed.');
    } else if (cmd == '3') { // Add Spot
      stdout.write('Floor id to add spot to: ');
      final fid = stdin.readLineSync();
      final matchingFloors = lot.floors.where((f) => f.id == fid).toList();
      if (matchingFloors.isEmpty) {
        print('Floor not found.');
        continue;
      }
      final floor = matchingFloors.first;
      print('Spot types: 1.Two-wheeler 2.Four-wheeler 3.Truck');
      stdout.write('Type number: ');
      final n = int.tryParse(stdin.readLineSync() ?? '') ?? 1;
      stdout.write('Spot id: ');
      final sid = stdin.readLineSync() ?? '';
      SpotType spotType;
      if (n == 1) {
        spotType = SpotType.TwoWheeler;
      } else if (n == 2) {
        spotType = SpotType.FourWheeler;
      } else if (n == 3) {
        spotType = SpotType.Truck;
      } else {
        print('Invalid type.');
        continue;
      }
      final spot = ParkingSpotFactory.create(spotType, sid);
      spot.registerObserver(floor);
      lot.addSpot(fid!, spot);
      print('Added spot $sid');
    } else if (cmd == '4') { // Remove Spot
      stdout.write('Spot id to remove: ');
      final sid = stdin.readLineSync();
      for (var floor in lot.floors) {
        floor.spots.removeWhere((s) => s.id == sid);
      }
      print('Spot $sid removed.');
    } else if (cmd == '5') { // Add Attendant
      stdout.write('Enter attendant name: ');
      final name = stdin.readLineSync();
      if (name != null && name.isNotEmpty) {
        attendants.add(name);
        print('Attendant $name added.');
      }
    } else if (cmd == '6') { // Remove Attendant
      stdout.write('Enter attendant name to remove: ');
      final name = stdin.readLineSync();
      attendants.removeWhere((a) => a == name);
      print('Attendant $name removed.');
    } else if (cmd == '7') { // Change pricing
      stdout.write('Enter new per minute rate: ');
      final n = double.tryParse(stdin.readLineSync() ?? '5') ?? 5;
      pricing.ratePerMinute = n;
      print('Pricing updated to Rs.$n per minute.');
    } else if (cmd == '8') {
      print('All attendants:');
      attendants.forEach(print);
    } else if (cmd == '9') {
      break;
    } else {
      print('Invalid admin command.');
    }
  }
}
