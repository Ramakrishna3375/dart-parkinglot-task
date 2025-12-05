import '../patterns/observer_pattern.dart';
import 'vehicle.dart';

enum SpotType { TwoWheeler, FourWheeler, Truck }

abstract class ParkingSpot {
  final String id;
  final SpotType type;
  bool isOccupied;
  Vehicle? currentVehicle;
  final List<ParkingSpotObserver> observers = [];

  ParkingSpot(this.id, this.type) : isOccupied = false;

  void registerObserver(ParkingSpotObserver observer) => observers.add(observer);

  void _notifyObservers() {
    final notification = ParkingSpotNotification(
      spotId: id,
      isOccupied: isOccupied,
      vehiclePlate: currentVehicle?.licensePlate,
    );
    for (final observer in observers) {
      observer.onParkingSpotStatusChanged(notification);
    }
  }

  void park(Vehicle vehicle) {
    isOccupied = true;
    currentVehicle = vehicle;
    _notifyObservers();
  }

  void free() {
    isOccupied = false;
    currentVehicle = null;
    _notifyObservers();
  }
}

class TwoWheelerSpot extends ParkingSpot {
  TwoWheelerSpot(String id) : super(id, SpotType.TwoWheeler);
}

class FourWheelerSpot extends ParkingSpot {
  FourWheelerSpot(String id) : super(id, SpotType.FourWheeler);
}

class TruckSpot extends ParkingSpot {
  TruckSpot(String id) : super(id, SpotType.Truck);
}
