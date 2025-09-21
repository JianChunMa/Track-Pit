import 'package:track_pit/core/db/database_helper.dart';
import 'package:track_pit/models/workshop.dart';

class WorkshopService {
  static Future<List<Workshop>> getWorkshops() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('workshops');
    return result.map((map) => Workshop.fromMap(map)).toList();
  }

  static Future<Workshop?> getWorkshop(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'workshops',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Workshop.fromMap(result.first);
    }
    return null;
  }
}
