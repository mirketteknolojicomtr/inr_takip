/// `sqflite` tabanlı kalıcı repository implementasyonları.
///
/// `repositories.dart`'taki soyut arayüzleri (InMemory* ile birebir aynı
/// sözleşme) implemente eder -- DI'da tek satır değişikliğiyle geçiş
/// yapılabilir (bkz. ARCHITECTURE.md "Temiz kod kararları").
///
/// Var olan modellerin zaten yazılmış `toJson()`/`fromJson()` metotlarını
/// kullanır; her satır bir JSON blob + sorgulanabilir `date` sütunu olarak
/// saklanır. Tam tip-güvenli bir şema (drift + build_runner kod üretimi)
/// yerine bu, daha az taşınabilir kod gerektiren pragmatik bir seçim;
/// model sayısı/sorgu karmaşıklığı arttıkça drift'e geçiş
/// değerlendirilebilir.
library;

import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/inr_entry.dart';
import '../models/patient_profile.dart';
import '../models/vitamin_k_log.dart';
import 'repositories.dart';

/// Tek, paylaşılan sqlite bağlantısı. Her repository (ve arka plan
/// izolatlarındaki WorkManager görevleri) aynı fiziksel dosyayı açar --
/// bu yüzden persistent'tir: InMemory* aksine izolat/process yeniden
/// başlasa da veri kalır.
class AppDatabase {
  static Database? _instance;

  static Future<Database> open() async {
    final existing = _instance;
    if (existing != null) return existing;

    final dbPath = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dbPath, 'inr_takip.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE inr_entries (
            id TEXT PRIMARY KEY,
            date INTEGER NOT NULL,
            json TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE vitamin_k_logs (
            id TEXT PRIMARY KEY,
            date INTEGER NOT NULL,
            json TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE patient_profile (
            id INTEGER PRIMARY KEY CHECK (id = 0),
            json TEXT NOT NULL
          )
        ''');
      },
    );
    _instance = db;
    return db;
  }
}

class SqfliteInrRepository implements InrRepository {
  final Future<Database> _dbFuture;
  final _controller = StreamController<List<InrEntry>>.broadcast();

  SqfliteInrRepository([Future<Database>? database])
      : _dbFuture = database ?? AppDatabase.open();

  Future<void> _emit() async {
    if (_controller.hasListener) _controller.add(await getEntries());
  }

  @override
  Future<List<InrEntry>> getEntries({DateTime? from, DateTime? to}) async {
    final db = await _dbFuture;
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('date >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      where.add('date <= ?');
      args.add(to.millisecondsSinceEpoch);
    }
    final rows = await db.query(
      'inr_entries',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'date ASC',
    );
    return rows.map(_decode).toList();
  }

  @override
  Future<InrEntry?> getLatest() async {
    final db = await _dbFuture;
    final rows = await db.query('inr_entries', orderBy: 'date DESC', limit: 1);
    return rows.isEmpty ? null : _decode(rows.first);
  }

  @override
  Future<void> upsert(InrEntry entry) async {
    final db = await _dbFuture;
    await db.insert(
      'inr_entries',
      {
        'id': entry.id,
        'date': entry.date.millisecondsSinceEpoch,
        'json': jsonEncode(entry.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _emit();
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbFuture;
    await db.delete('inr_entries', where: 'id = ?', whereArgs: [id]);
    await _emit();
  }

  @override
  Stream<List<InrEntry>> watchEntries() async* {
    yield await getEntries();
    yield* _controller.stream;
  }

  InrEntry _decode(Map<String, Object?> row) =>
      InrEntry.fromJson(jsonDecode(row['json'] as String) as Map<String, dynamic>);
}

class SqfliteVitaminKRepository implements VitaminKRepository {
  final Future<Database> _dbFuture;
  final _controller = StreamController<List<VitaminKLog>>.broadcast();

  SqfliteVitaminKRepository([Future<Database>? database])
      : _dbFuture = database ?? AppDatabase.open();

  Future<void> _emit() async {
    if (_controller.hasListener) _controller.add(await getLogs());
  }

  @override
  Future<List<VitaminKLog>> getLogs({DateTime? from, DateTime? to}) async {
    final db = await _dbFuture;
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('date >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      where.add('date <= ?');
      args.add(to.millisecondsSinceEpoch);
    }
    final rows = await db.query(
      'vitamin_k_logs',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'date ASC',
    );
    return rows
        .map((r) =>
            VitaminKLog.fromJson(jsonDecode(r['json'] as String) as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> upsert(VitaminKLog log) async {
    final db = await _dbFuture;
    await db.insert(
      'vitamin_k_logs',
      {
        'id': log.id,
        'date': log.date.millisecondsSinceEpoch,
        'json': jsonEncode(log.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _emit();
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbFuture;
    await db.delete('vitamin_k_logs', where: 'id = ?', whereArgs: [id]);
    await _emit();
  }

  @override
  Stream<List<VitaminKLog>> watchLogs() async* {
    yield await getLogs();
    yield* _controller.stream;
  }
}

class SqfliteProfileRepository implements ProfileRepository {
  final Future<Database> _dbFuture;

  SqfliteProfileRepository([Future<Database>? database])
      : _dbFuture = database ?? AppDatabase.open();

  @override
  Future<PatientProfile?> getProfile() async {
    final db = await _dbFuture;
    final rows = await db.query('patient_profile', where: 'id = 0', limit: 1);
    if (rows.isEmpty) return null;
    return PatientProfile.fromJson(
        jsonDecode(rows.first['json'] as String) as Map<String, dynamic>);
  }

  @override
  Future<void> saveProfile(PatientProfile profile) async {
    final db = await _dbFuture;
    await db.insert(
      'patient_profile',
      {'id': 0, 'json': jsonEncode(profile.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
