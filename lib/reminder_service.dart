import 'models.dart';
import 'notification_service.dart';

class ReminderService {
  final NotificationService notifications = NotificationService();

  Future<void> scheduleReminder(MaintenanceReminder reminder, int currentOdometer) async {
    await notifications.initialize();

    DateTime? nextDueDate;
    String dueReason = '';

    // Calculate based on odometer
    if (reminder.odometerInterval > 0) {
      final kmUntilDue = reminder.odometerInterval - (currentOdometer - reminder.lastOdometer);
      if (kmUntilDue <= 0) {
        nextDueDate = DateTime.now();
        dueReason = 'Пробіг перевищено';
      } else {
        // Estimate based on average usage (assume 1000 km/month if no historical data)
        final monthsUntilDue = kmUntilDue / 1000;
        nextDueDate = DateTime.now().add(Duration(days: (monthsUntilDue * 30).round()));
        dueReason = 'Через $kmUntilDue км';
      }
    }

    // Calculate based on time (use whichever is sooner)
    if (reminder.monthInterval > 0) {
      final timeDueDate = reminder.lastServiceDate.add(Duration(days: reminder.monthInterval * 30));
      if (nextDueDate == null || timeDueDate.isBefore(nextDueDate)) {
        nextDueDate = timeDueDate;
        dueReason = reminder.odometerInterval > 0
            ? 'Час та пробіг'
            : 'Час обслуговування';
      }
    }

    if (nextDueDate != null) {
      final notificationId = reminder.id.hashCode;
      await notifications.scheduleMaintenanceReminder(
        id: notificationId,
        title: 'Нагадування: ${reminder.partName}',
        body: 'Потрібно обслуговування. $dueReason',
        scheduledDate: nextDueDate,
      );
    }
  }

  Future<void> cancelReminder(String reminderId) async {
    final notificationId = reminderId.hashCode;
    await notifications.cancelNotification(notificationId);
  }

  // Predefined common maintenance reminders
  List<MaintenanceReminder> getDefaultReminders(String carId, int currentOdometer) {
    return [
      MaintenanceReminder(
        id: '',
        carId: carId,
        partName: 'Заміна оливи',
        odometerInterval: 10000,
        monthInterval: 6,
        lastOdometer: currentOdometer,
        lastServiceDate: DateTime.now(),
      ),
      MaintenanceReminder(
        id: '',
        carId: carId,
        partName: 'Ротація шин',
        odometerInterval: 15000,
        monthInterval: 12,
        lastOdometer: currentOdometer,
        lastServiceDate: DateTime.now(),
      ),
      MaintenanceReminder(
        id: '',
        carId: carId,
        partName: 'Заміна гальмівної рідини',
        odometerInterval: 40000,
        monthInterval: 24,
        lastOdometer: currentOdometer,
        lastServiceDate: DateTime.now(),
      ),
      MaintenanceReminder(
        id: '',
        carId: carId,
        partName: 'Заміна повітряного фільтра',
        odometerInterval: 20000,
        monthInterval: 12,
        lastOdometer: currentOdometer,
        lastServiceDate: DateTime.now(),
      ),
      MaintenanceReminder(
        id: '',
        carId: carId,
        partName: 'Заміна свічок запалювання',
        odometerInterval: 60000,
        monthInterval: 36,
        lastOdometer: currentOdometer,
        lastServiceDate: DateTime.now(),
      ),
    ];
  }
}
