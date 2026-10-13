import 'package:flutter/material.dart';
import 'models.dart';
import 'firebase_service.dart';
import 'reminder_service.dart';

class RemindersScreen extends StatefulWidget {
  final String carId;
  final int currentOdometer;

  const RemindersScreen({
    super.key,
    required this.carId,
    required this.currentOdometer,
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final FirebaseService _firebase = FirebaseService();
  final ReminderService _reminderService = ReminderService();

  @override
  void initState() {
    super.initState();
    _reminderService.notifications.requestPermissions();
  }

  void _addDefaultReminders() async {
    final defaults = _reminderService.getDefaultReminders(
      widget.carId,
      widget.currentOdometer,
    );

    for (var reminder in defaults) {
      await _firebase.addReminder(reminder);
      await _reminderService.scheduleReminder(reminder, widget.currentOdometer);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Додано стандартні нагадування')),
    );
  }

  void _showAddReminderDialog() {
    final partNameController = TextEditingController();
    final odometerController = TextEditingController();
    final monthController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Додати нагадування'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: partNameController,
              decoration: const InputDecoration(
                labelText: 'Назва деталі/послуги',
                hintText: 'Наприклад: Заміна оливи',
              ),
            ),
            TextField(
              controller: odometerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Інтервал по пробігу (км)',
                hintText: '0 якщо не використовується',
              ),
            ),
            TextField(
              controller: monthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Інтервал по часу (місяців)',
                hintText: '0 якщо не використовується',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              final partName = partNameController.text.trim();
              final odometerInterval = int.tryParse(odometerController.text) ?? 0;
              final monthInterval = int.tryParse(monthController.text) ?? 0;

              if (partName.isEmpty || (odometerInterval == 0 && monthInterval == 0)) {
                return;
              }

              final reminder = MaintenanceReminder(
                id: '',
                carId: widget.carId,
                partName: partName,
                odometerInterval: odometerInterval,
                monthInterval: monthInterval,
                lastOdometer: widget.currentOdometer,
                lastServiceDate: DateTime.now(),
              );

              _firebase.addReminder(reminder).then((_) {
                _reminderService.scheduleReminder(reminder, widget.currentOdometer);
              });

              Navigator.pop(dialogContext);
            },
            child: const Text('Додати'),
          ),
        ],
      ),
    );
  }

  void _deleteReminder(String reminderId) async {
    await _firebase.deleteReminder(widget.carId, reminderId);
    await _reminderService.cancelReminder(reminderId);
  }

  int _calculateDaysUntilDue(MaintenanceReminder reminder) {
    DateTime? nextDueDate;

    if (reminder.odometerInterval > 0) {
      final kmUntilDue = reminder.odometerInterval -
          (widget.currentOdometer - reminder.lastOdometer);
      if (kmUntilDue <= 0) {
        return 0;
      }
      final monthsUntilDue = kmUntilDue / 1000;
      nextDueDate = DateTime.now().add(Duration(days: (monthsUntilDue * 30).round()));
    }

    if (reminder.monthInterval > 0) {
      final timeDueDate = reminder.lastServiceDate.add(Duration(days: reminder.monthInterval * 30));
      if (nextDueDate == null || timeDueDate.isBefore(nextDueDate)) {
        nextDueDate = timeDueDate;
      }
    }

    if (nextDueDate != null) {
      return nextDueDate.difference(DateTime.now()).inDays;
    }
    return 999;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Нагадування про ТО'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: _addDefaultReminders,
            tooltip: 'Додати стандартні нагадування',
          ),
        ],
      ),
      body: StreamBuilder<List<MaintenanceReminder>>(
        stream: _firebase.streamReminders(widget.carId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reminders = snapshot.data!;

          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Немає нагадувань'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addDefaultReminders,
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('Додати стандартні нагадування'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              final daysUntilDue = _calculateDaysUntilDue(reminder);
              final isOverdue = daysUntilDue <= 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    isOverdue ? Icons.warning : Icons.event,
                    color: isOverdue ? Colors.red : Colors.blue,
                  ),
                  title: Text(reminder.partName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reminder.odometerInterval > 0)
                        Text('Кожні ${reminder.odometerInterval} км'),
                      if (reminder.monthInterval > 0)
                        Text('Кожні ${reminder.monthInterval} місяців'),
                      Text(
                        isOverdue
                            ? 'Термін минув!'
                            : 'Через $daysUntilDue днів',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteReminder(reminder.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
