import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId =
      "test_user_123"; // В майбутньому замінити на FirebaseAuth.instance.currentUser!.uid

  // Отримати список автомобілів користувача
  Stream<List<Car>> streamCars() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Car.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  // Додати новий автомобіль
  Future<void> addCar(Car car) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .add(car.toJson());
  }

  // Отримати журнал ТО для конкретного авто
  Stream<List<ServiceLog>> streamLogs(String carId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .collection('logs')
        .orderBy('dateAtChange', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ServiceLog.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  // Додати запис про ремонт/заміну деталі
  Future<void> addLog(String carId, ServiceLog log) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .collection('logs')
        .add(log.toJson());
  }

  // Оновити пробіг автомобіля
  Future<void> updateCarOdometer(String carId, int newOdometer) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .update({'currentOdometer': newOdometer});
  }

  // Видалити автомобіль
  Future<void> deleteCar(String carId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .delete();
  }

  // Отримати нагадування для конкретного авто
  Stream<List<MaintenanceReminder>> streamReminders(String carId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .collection('reminders')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MaintenanceReminder.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  // Додати нагадування
  Future<void> addReminder(MaintenanceReminder reminder) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(reminder.carId)
        .collection('reminders')
        .add(reminder.toJson());
  }

  // Оновити нагадування
  Future<void> updateReminder(String carId, String reminderId, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .collection('reminders')
        .doc(reminderId)
        .update(data);
  }

  // Видалити нагадування
  Future<void> deleteReminder(String carId, String reminderId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('cars')
        .doc(carId)
        .collection('reminders')
        .doc(reminderId)
        .delete();
  }
}
