import '../models/parking_spot.dart';
import '../models/vehicle.dart';

class ParkingSpotFactory {
  static ParkingSpot create(SpotType type, String id) {
    switch (type) {
      case SpotType.TwoWheeler:
        return TwoWheelerSpot(id);
      case SpotType.FourWheeler:
        return FourWheelerSpot(id);
      case SpotType.Truck:
        return TruckSpot(id);
    }
  }
}

class VehicleFactory {
  static Vehicle create(VehicleType type, String licensePlate) {
    return Vehicle(licensePlate, type);
  }
}
