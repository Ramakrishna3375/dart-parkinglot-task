import '../models/floor.dart';
import '../models/parking_ticket.dart';
import '../models/parking_spot.dart';
import '../models/pricing_model.dart';

class ParkingLot {
  static ParkingLot? _instance;
  final String name;
  int totalCapacity;
  final List<Floor> floors = [];
  late PricingModel pricingModel;
  final Map<String, ParkingTicket> activeTickets = {};

  ParkingLot._internal(this.name, this.totalCapacity, this.pricingModel);

  static ParkingLot getInstance({
    String name = 'City Lot',
    int totalCapacity = 60,
    required PricingModel pricingModel,
  }) {
    _instance ??= ParkingLot._internal(name, totalCapacity, pricingModel);
    return _instance!;
  }

  void addFloor(Floor floor) => floors.add(floor);

  void addSpot(String floorId, ParkingSpot spot) {
    final floor = floors.firstWhere(
      (f) => f.id == floorId,
      orElse: () => throw Exception('Floor not found'),
    );
    floor.spots.add(spot);
  }
}
