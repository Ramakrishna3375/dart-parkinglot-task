import '../patterns/observer_pattern.dart';
import 'parking_spot.dart';

class Floor implements ParkingSpotObserver {
  final String id;
  final List<ParkingSpot> spots = [];
  final DisplayBoard displayBoard = DisplayBoard();

  Floor(this.id);

  @override
  void onParkingSpotStatusChanged(ParkingSpotNotification notification) {
    final total = spots.length;
    final free = spots.where((s) => !s.isOccupied).length;
    displayBoard.show(id, free, total);
  }
}
