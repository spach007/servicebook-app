import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models.dart';
import 'firebase_service.dart';
import 'vin_scanner.dart';
import 'gemini_service.dart';
import 'nhtsa_service.dart';
import 'reminders_screen.dart';
import 'statistics_screen.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  runApp(const CarApp());
}

class CarApp extends StatelessWidget {
  const CarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebase = FirebaseService();
  final GeminiService _gemini = GeminiService();
  final NHTSAService _nhtsa = NHTSAService();
  String? _selectedCarId;

  void _scanVinAndAddCar() async {
    final String? vin = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VinScannerScreen()),
    );
    if (vin != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отримання даних про автомобіль...')),
      );

      final vehicleInfo = await _nhtsa.decodeVin(vin);
      final make = vehicleInfo != null ? _nhtsa.extractMake(vehicleInfo) ?? 'Невідомо' : 'Невідомо';
      final model = vehicleInfo != null ? _nhtsa.extractModel(vehicleInfo) ?? 'Невідомо' : 'Невідомо';
      final year = vehicleInfo != null ? _nhtsa.extractYear(vehicleInfo) ?? DateTime.now().year : DateTime.now().year;

      final newCar = Car(
        id: '',
        vin: vin,
        make: make,
        model: model,
        year: year,
        currentOdometer: 0,
        lastServiceDate: DateTime.now(),
      );
      await _firebase.addCar(newCar);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Додано: $make $model ($year)')),
        );
      }
    }
  }

  void _showOdometerDialog(String carId, int currentOdometer) async {
    final controller = TextEditingController(text: currentOdometer.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Оновити пробіг'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Поточний пробіг (км)',
            hintText: 'Введіть поточний пробіг',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              final newOdometer = int.tryParse(controller.text);
              if (newOdometer != null && newOdometer >= currentOdometer) {
                Navigator.pop(context, newOdometer);
              }
            },
            child: const Text('Оновити'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _firebase.updateCarOdometer(carId, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Пробіг оновлено: $result км')),
        );
      }
    }
  }

  void _scanReceiptAndAddLog(String carId, int currentOdometer) async {
    final controller = TextEditingController(text: currentOdometer.toString());

    final newOdometer = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поточний пробіг'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Пробіг на момент обслуговування (км)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, currentOdometer),
            child: const Text('Використати поточний'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= currentOdometer) {
                Navigator.pop(context, value);
              } else {
                Navigator.pop(context, currentOdometer);
              }
            },
            child: const Text('Підтвердити'),
          ),
        ],
      ),
    );

    final odometerAtChange = newOdometer ?? currentOdometer;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ШІ аналізує чек...')),
      );
    }
    Uint8List bytes = await image.readAsBytes();

    final result = await _gemini.analyzeReceipt(bytes);
    if (result != null) {
      final log = ServiceLog(
        id: '',
        partName: result['partName'] ?? 'Ремонт СТО',
        odometerAtChange: odometerAtChange,
        dateAtChange: DateTime.now(),
        cost: double.tryParse(result['cost'].toString()) ?? 0.0,
      );
      await _firebase.addLog(carId, log);
      await _firebase.updateCarOdometer(carId, odometerAtChange);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Додано: ${log.partName} на суму ${log.cost} ₴'),
          ),
        );
      }
    }
  }

  void _deleteCar(String carId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видалити автомобіль?'),
        content: const Text('Ця дія видалить всі дані про цей автомобіль.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firebase.deleteCar(carId);
      setState(() {
        _selectedCarId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Розумне ТО автомобіля'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _scanVinAndAddCar,
            tooltip: 'Додати автомобіль',
          ),
        ],
      ),
      body: StreamBuilder<List<Car>>(
        stream: _firebase.streamCars(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cars = snapshot.data!;

          if (cars.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.directions_car, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Натисніть на іконку камери вгорі,\nщоб відсканувати VIN та додати перше авто.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final selectedCar = _selectedCarId != null
              ? cars.firstWhere((car) => car.id == _selectedCarId)
              : cars.first;

          return Column(
            children: [
              // Car selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue.shade50,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Car>(
                    isExpanded: true,
                    value: selectedCar,
                    items: cars.map((car) {
                      return DropdownMenuItem<Car>(
                        value: car,
                        child: Text('${car.make} ${car.model} (${car.year})'),
                      );
                    }).toList(),
                    onChanged: (car) {
                      setState(() {
                        _selectedCarId = car?.id;
                      });
                    },
                  ),
                ),
              ),
              const Divider(),

              // Car details
              ListTile(
                title: Text('${selectedCar.make} ${selectedCar.model}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VIN: ${selectedCar.vin}'),
                    Text('Пробіг: ${selectedCar.currentOdometer} км'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showOdometerDialog(
                        selectedCar.id,
                        selectedCar.currentOdometer,
                      ),
                      tooltip: 'Оновити пробіг',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCar(selectedCar.id),
                      tooltip: 'Видалити автомобіль',
                    ),
                  ],
                ),
                tileColor: Colors.blue.shade50,
              ),
              const Divider(),

              // Quick actions
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickActionButton(
                      icon: Icons.notifications,
                      label: 'Нагадування',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RemindersScreen(
                              carId: selectedCar.id,
                              currentOdometer: selectedCar.currentOdometer,
                            ),
                          ),
                        );
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.bar_chart,
                      label: 'Статистика',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StatisticsScreen(carId: selectedCar.id),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Service logs
              Expanded(
                child: StreamBuilder<List<ServiceLog>>(
                  stream: _firebase.streamLogs(selectedCar.id),
                  builder: (context, logSnapshot) {
                    if (!logSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final logs = logSnapshot.data!;
                    if (logs.isEmpty) {
                      return const Center(
                        child: Text('Немає записів про обслуговування'),
                      );
                    }
                    return ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, i) => Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(logs[i].partName),
                          subtitle: Text(
                            '${logs[i].dateAtChange.day}.${logs[i].dateAtChange.month}.${logs[i].dateAtChange.year} • ${logs[i].odometerAtChange} км',
                          ),
                          trailing: Text(
                            '${logs[i].cost.toStringAsFixed(2)} ₴',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<Car>>(
        stream: _firebase.streamCars(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox();
          }
          final cars = snapshot.data!;
          final selectedCar = _selectedCarId != null
              ? cars.firstWhere((car) => car.id == _selectedCarId)
              : cars.first;

          return FloatingActionButton.extended(
            icon: const Icon(Icons.receipt_long),
            label: const Text('Скан чека з СТО'),
            onPressed: () => _scanReceiptAndAddLog(
              selectedCar.id,
              selectedCar.currentOdometer,
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
