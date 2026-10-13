class Car {
  final String id;
  final String vin;
  final String make;
  final String model;
  final int year;
  final int currentOdometer;
  final DateTime? lastServiceDate;

  Car({
    required this.id,
    required this.vin,
    required this.make,
    required this.model,
    required this.year,
    required this.currentOdometer,
    this.lastServiceDate,
  });

  factory Car.fromJson(Map<String, dynamic> json, String docId) => Car(
    id: docId,
    vin: json['vin'] ?? '',
    make: json['make'] ?? '',
    model: json['model'] ?? '',
    year: json['year'] ?? 2000,
    currentOdometer: json['currentOdometer'] ?? 0,
    lastServiceDate: json['lastServiceDate'] != null
        ? DateTime.parse(json['lastServiceDate'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'vin': vin,
    'make': make,
    'model': model,
    'year': year,
    'currentOdometer': currentOdometer,
    'lastServiceDate': lastServiceDate?.toIso8601String(),
  };
}

class ServiceLog {
  final String id;
  final String partName;
  final int odometerAtChange;
  final DateTime dateAtChange;
  final double cost;

  ServiceLog({
    required this.id,
    required this.partName,
    required this.odometerAtChange,
    required this.dateAtChange,
    required this.cost,
  });

  factory ServiceLog.fromJson(Map<String, dynamic> json, String docId) =>
      ServiceLog(
        id: docId,
        partName: json['partName'] ?? '',
        odometerAtChange: json['odometerAtChange'] ?? 0,
        dateAtChange: DateTime.parse(json['dateAtChange']),
        cost: (json['cost'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'partName': partName,
    'odometerAtChange': odometerAtChange,
    'dateAtChange': dateAtChange.toIso8601String(),
    'cost': cost,
  };
}

class MaintenanceReminder {
  final String id;
  final String carId;
  final String partName;
  final int odometerInterval;
  final int monthInterval;
  final int lastOdometer;
  final DateTime lastServiceDate;
  final bool isActive;

  MaintenanceReminder({
    required this.id,
    required this.carId,
    required this.partName,
    required this.odometerInterval,
    required this.monthInterval,
    required this.lastOdometer,
    required this.lastServiceDate,
    this.isActive = true,
  });

  factory MaintenanceReminder.fromJson(Map<String, dynamic> json, String docId) =>
      MaintenanceReminder(
        id: docId,
        carId: json['carId'] ?? '',
        partName: json['partName'] ?? '',
        odometerInterval: json['odometerInterval'] ?? 0,
        monthInterval: json['monthInterval'] ?? 0,
        lastOdometer: json['lastOdometer'] ?? 0,
        lastServiceDate: DateTime.parse(json['lastServiceDate']),
        isActive: json['isActive'] ?? true,
      );

  Map<String, dynamic> toJson() => {
    'carId': carId,
    'partName': partName,
    'odometerInterval': odometerInterval,
    'monthInterval': monthInterval,
    'lastOdometer': lastOdometer,
    'lastServiceDate': lastServiceDate.toIso8601String(),
    'isActive': isActive,
  };
}
