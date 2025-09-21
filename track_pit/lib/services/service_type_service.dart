import 'package:track_pit/core/db/database_helper.dart';
import 'package:track_pit/models/service_type.dart';

class ServiceTypeService {
  static Future<List<ServiceType>> getServiceTypes() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('service_types');
    return result.map((map) => ServiceType.fromMap(map)).toList();
  }

  static Future<ServiceType?> getServiceType(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'service_types',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return ServiceType.fromMap(result.first);
    }
    return null;
  }
}
