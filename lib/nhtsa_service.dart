import 'dart:convert';
import 'package:http/http.dart' as http;

class NHTSAService {
  static const String _baseUrl = 'https://vpic.nhtsa.dot.gov/api/vehicles';

  Future<Map<String, dynamic>?> decodeVin(String vin) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/DecodeVin/$vin?format=json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['Results'] as List;

        if (results.isEmpty) return null;

        final Map<String, dynamic> vehicleInfo = {};
        for (var item in results) {
          final variable = item['Variable'] as String;
          final value = item['Value'] as String;
          vehicleInfo[variable] = value;
        }

        return vehicleInfo;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String? extractMake(Map<String, dynamic> vehicleInfo) {
    return vehicleInfo['Make'];
  }

  String? extractModel(Map<String, dynamic> vehicleInfo) {
    return vehicleInfo['Model'];
  }

  int? extractYear(Map<String, dynamic> vehicleInfo) {
    final year = vehicleInfo['Model Year'];
    return year != null ? int.tryParse(year) : null;
  }
}
