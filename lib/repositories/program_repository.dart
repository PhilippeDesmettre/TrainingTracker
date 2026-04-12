import '../core/database/database_helper.dart';
import '../models/program.dart';

class ProgramRepository {
  const ProgramRepository(this._db);
  final DatabaseHelper _db;

  Future<List<Program>> getAll() async {
    final db = await _db.db;
    final rows = await db.query('programs', orderBy: 'created_at DESC');
    return rows.map(Program.fromMap).toList();
  }

  Future<Program?> getById(String id) async {
    final db = await _db.db;
    final rows = await db.query('programs', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Program.fromMap(rows.first);
  }

  Future<void> insert(Program program) async {
    final db = await _db.db;
    await db.insert('programs', program.toMap());
  }

  Future<void> update(Program program) async {
    final db = await _db.db;
    await db.update('programs', program.toMap(), where: 'id = ?', whereArgs: [program.id]);
  }

  Future<void> delete(String id) async {
    final db = await _db.db;
    await db.delete('programs', where: 'id = ?', whereArgs: [id]);
  }
}
