import '../services/auth_service.dart';

class CarHireBooking {
  const CarHireBooking({
    required this.id,
    required this.reference,
    required this.status,
    required this.pickupDate,
    required this.returnDate,
    required this.pickupLocation,
    required this.passengers,
    required this.hireType,
    required this.pricePerDay,
    required this.numberOfDays,
    required this.estimatedTotal,
    required this.currency,
    this.pickupTime,
    this.returnTime,
    this.dropoffLocation,
    this.specialRequests,
    this.operatorNotes,
    this.createdAt,
    this.vehicle,
    this.operator,
    this.tourist,
  });

  final int id;
  final String reference;
  final String status;

  final DateTime pickupDate;
  final String? pickupTime;
  final DateTime returnDate;
  final String? returnTime;

  final String pickupLocation;
  final String? dropoffLocation;

  final int passengers;
  final String hireType;

  final double pricePerDay;
  final int numberOfDays;
  final double estimatedTotal;
  final String currency;

  final String? specialRequests;
  final String? operatorNotes;
  final DateTime? createdAt;

  final CarHireBookingVehicle? vehicle;
  final CarHireBookingParty? operator;
  final CarHireBookingParty? tourist;

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  String get hireTypeLabel =>
      hireType == 'self_drive' ? 'Self Drive' : 'With Driver';

  factory CarHireBooking.fromJson(Map<String, dynamic> json) {
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int integer(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    DateTime date(dynamic value) =>
        DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.now();

    DateTime? optionalDate(dynamic value) =>
        DateTime.tryParse(value?.toString() ?? '');

    Map<String, dynamic>? map(dynamic value) {
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final vehicleJson = map(json['vehicle']);
    final operatorJson = map(json['operator']);
    final touristJson = map(json['tourist']);

    return CarHireBooking(
      id: integer(json['id']),
      reference: json['reference']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      pickupDate: date(json['pickup_date']),
      pickupTime: json['pickup_time']?.toString(),
      returnDate: date(json['return_date']),
      returnTime: json['return_time']?.toString(),
      pickupLocation: json['pickup_location']?.toString() ?? '',
      dropoffLocation: json['dropoff_location']?.toString(),
      passengers: integer(json['passengers']),
      hireType: json['hire_type']?.toString() ?? 'with_driver',
      pricePerDay: number(json['price_per_day']),
      numberOfDays: integer(json['number_of_days']),
      estimatedTotal: number(json['estimated_total']),
      currency: json['currency']?.toString() ?? 'USD',
      specialRequests: json['special_requests']?.toString(),
      operatorNotes: json['operator_notes']?.toString(),
      createdAt: optionalDate(json['created_at']),
      vehicle: vehicleJson == null
          ? null
          : CarHireBookingVehicle.fromJson(vehicleJson),
      operator: operatorJson == null
          ? null
          : CarHireBookingParty.fromJson(operatorJson),
      tourist: touristJson == null
          ? null
          : CarHireBookingParty.fromJson(touristJson),
    );
  }
}

class CarHireBookingVehicle {
  const CarHireBookingVehicle({
    required this.id,
    required this.name,
    required this.image,
    this.seats,
    this.transmission,
    this.fuelType,
  });

  final int id;
  final String name;
  final String image;
  final int? seats;
  final String? transmission;
  final String? fuelType;

  String get imageUrl => AuthService.storageUrl(image);

  factory CarHireBookingVehicle.fromJson(Map<String, dynamic> json) {
    int integer(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return CarHireBookingVehicle(
      id: integer(json['id']),
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      seats: json['seats'] == null ? null : integer(json['seats']),
      transmission: json['transmission']?.toString(),
      fuelType: json['fuel_type']?.toString(),
    );
  }
}

class CarHireBookingParty {
  const CarHireBookingParty({
    required this.id,
    required this.name,
    this.logo = '',
  });

  final int id;
  final String name;
  final String logo;

  String get logoUrl => AuthService.storageUrl(logo);

  factory CarHireBookingParty.fromJson(Map<String, dynamic> json) {
    int integer(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return CarHireBookingParty(
      id: integer(json['id']),
      name: json['name']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
    );
  }
}
