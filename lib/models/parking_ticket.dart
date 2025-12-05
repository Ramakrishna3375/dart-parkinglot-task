import 'vehicle.dart';

class ParkingTicket {
  final String id;
  DateTime entryTime;
  DateTime? exitTime;
  final Vehicle vehicle;
  bool isPaid = false;

  ParkingTicket(this.id, this.entryTime, this.vehicle);
}
