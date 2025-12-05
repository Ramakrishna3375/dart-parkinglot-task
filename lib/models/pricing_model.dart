abstract class PricingModel {
  double calculateFee(int minutesParked);
}

class MinutePricingModel extends PricingModel {
  double ratePerMinute;
  MinutePricingModel({this.ratePerMinute = 5});

  @override
  double calculateFee(int minutesParked) {
    return minutesParked * ratePerMinute;
  }
}
