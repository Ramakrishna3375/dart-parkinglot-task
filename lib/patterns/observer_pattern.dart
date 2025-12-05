class ParkingSpotNotification {
  final String spotId;
  final bool isOccupied;
  final String? vehiclePlate;

  ParkingSpotNotification({
    required this.spotId,
    required this.isOccupied,
    this.vehiclePlate,
  });
}

abstract class ParkingSpotObserver {
  void onParkingSpotStatusChanged(ParkingSpotNotification notification);
}

class DisplayBoard {
  void show(String floorId, int freeSpots, int totalSpots) {
    print('DisplayBoard ($floorId): $freeSpots/$totalSpots spots free');
  }
}
