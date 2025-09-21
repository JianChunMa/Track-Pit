import 'package:track_pit/core/db/database_helper.dart';

class CarModelService {
  static const String _carsPath = 'assets/images/cars/';
  static const String _fallback = 'assets/images/car_icon.png';

  static Future<String> getImagePathForModel(String modelName) async {
    final db = await DatabaseHelper.instance.database;

    final res = await db.query(
      'car_models',
      where: 'LOWER(name) = ?',
      whereArgs: [modelName.toLowerCase()],
      limit: 1,
    );

    if (res.isNotEmpty) {
      final filename = res.first['image_file'] as String?;
      if (filename != null && filename.isNotEmpty) {
        return '$_carsPath$filename';
      }
    }

    final likeRes = await db.query(
      'car_models',
      where: 'LOWER(name) LIKE ?',
      whereArgs: ['%${modelName.toLowerCase()}%'],
      limit: 1,
    );

    if (likeRes.isNotEmpty) {
      final filename = likeRes.first['image_file'] as String?;
      if (filename != null && filename.isNotEmpty) {
        return '$_carsPath$filename';
      }
    }

    return _fallback;
  }

  static Future<List<String>> getAllModelNames() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('car_models', orderBy: 'name ASC');
    return rows.map((r) => r['name'] as String).toList();
  }
}
