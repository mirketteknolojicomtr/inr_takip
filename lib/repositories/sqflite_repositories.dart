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
import '../models/medication.dart';
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
      version: 4,
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
        await _createMedicationTables(db);
        await _createDeletionTable(db);
        await _createSettingsTable(db);
      },
      // v1 -> v2: ilaç planı (doz + sıklık) ve alım kayıtları eklendi.
      // v2 -> v3: bulut senkronu için silme defteri (tombstone) eklendi.
      // v3 -> v4: cihaz tercihleri (dil) için anahtar-değer tablosu.
      // Mevcut kullanıcıların verisi her iki adımda da olduğu gibi korunur.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createMedicationTables(db);
        if (oldVersion < 3) await _createDeletionTable(db);
        if (oldVersion < 4) await _createSettingsTable(db);
      },
    );
    _instance = db;
    return db;
  }

  /// Hesap silindiğinde cihazdaki kişisel kayıtları temizler. Dil tercihi
  /// (app_settings) kişisel veri değildir; giriş ekranı aynı dilde açılır.
  static Future<void> clearUserData() async {
    final db = await open();
    await db.transaction((txn) async {
      for (final table in const [
        'inr_entries',
        'vitamin_k_logs',
        'patient_profile',
        'medications',
        'dose_intakes',
        'deleted_records',
      ]) {
        await txn.delete(table);
      }
    });
  }

  static Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createDeletionTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS deleted_records (
        collection TEXT NOT NULL,
        id TEXT NOT NULL,
        deleted_at INTEGER NOT NULL,
        PRIMARY KEY (collection, id)
      )
    ''');
  }

  static Future<void> _createMedicationTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medications (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        is_anticoagulant INTEGER NOT NULL DEFAULT 0,
        json TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS dose_intakes (
        id TEXT PRIMARY KEY,
        medication_id TEXT NOT NULL,
        scheduled_at INTEGER NOT NULL,
        json TEXT NOT NULL
      )
    ''');
    // Bir dozun "alındı" işaretini tekilleştirir: aynı ilaç + aynı
    // planlanan an için tek kayıt (çift dokunuşta mükerrer kayıt olmaz).
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_dose_intake_slot
        ON dose_intakes (medication_id, scheduled_at)
    ''');
  }
}

/// Silme defterinin sqflite implementasyonu. Repository'lerle aynı
/// veritabanı dosyasını kullanır: silme ile mezar taşı aynı işlemde
/// (transaction) yazıldığı için ikisi hiçbir zaman ayrışmaz.
class SqfliteDeletionLog implements DeletionLog {
  final Future<Database> _dbFuture;

  SqfliteDeletionLog([Future<Database>? database])
      : _dbFuture = database ?? AppDatabase.open();

  @override
  Future<Set<String>> pending(String collection) async {
    final db = await _dbFuture;
    final rows = await db.query(
      'deleted_records',
      columns: ['id'],
      where: 'collection = ?',
      whereArgs: [collection],
    );
    return rows.map((r) => r['id'] as String).toSet();
  }

  @override
  Future<void> record(String collection, String id) async {
    final db = await _dbFuture;
    await _recordIn(db, collection, id);
  }

  @override
  Future<void> clear(String collection, Iterable<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _dbFuture;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      'deleted_records',
      where: 'collection = ? AND id IN ($placeholders)',
      whereArgs: [collection, ...ids],
    );
  }

  /// Repository'lerin kendi işlemleri içinden çağırabilmesi için.
  static Future<void> _recordIn(
    DatabaseExecutor db,
    String collection,
    String id,
  ) {
    return db.insert(
      'deleted_records',
      {
        'collection': collection,
        'id': id,
        'deleted_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

/// Bulut koleksiyon adları — mezar taşı kaydı ile
/// `FirestoreCloudGateway` aynı adı kullanmalıdır.
class SyncCollections {
  static const inrEntries = 'inr_entries';
  static const medications = 'medications';
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
    await db.transaction((txn) async {
      await txn.delete('inr_entries', where: 'id = ?', whereArgs: [id]);
      // Silme buluta da yansımalı; aksi hâlde sonraki senkronda geri gelir
      // (bkz. repositories.dart DeletionLog).
      await SqfliteDeletionLog._recordIn(
          txn, SyncCollections.inrEntries, id);
    });
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


class SqfliteMedicationRepository implements MedicationRepository {
  final Future<Database> _dbFuture;
  final _controller = StreamController<List<Medication>>.broadcast();

  SqfliteMedicationRepository([Future<Database>? database])
      : _dbFuture = database ?? AppDatabase.open();

  Future<void> _emit() async {
    if (_controller.hasListener) _controller.add(await getAll());
  }

  @override
  Future<List<Medication>> getAll() async {
    final db = await _dbFuture;
    final rows = await db.query(
      'medications',
      // Antikoagülan (ana ilaç) her zaman listenin başında.
      orderBy: 'is_anticoagulant DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(_decode).toList();
  }

  @override
  Future<Medication?> getById(String id) async {
    final db = await _dbFuture;
    final rows =
        await db.query('medications', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _decode(rows.first);
  }

  @override
  Future<void> upsert(Medication medication) async {
    final db = await _dbFuture;
    await db.insert(
      'medications',
      {
        'id': medication.id,
        'name': medication.name,
        'is_anticoagulant': medication.isAnticoagulant ? 1 : 0,
        'json': jsonEncode(medication.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _emit();
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbFuture;
    await db.transaction((txn) async {
      await txn.delete('medications', where: 'id = ?', whereArgs: [id]);
      // İlaç silinince ona ait alım kayıtları da anlamsızlaşır.
      await txn
          .delete('dose_intakes', where: 'medication_id = ?', whereArgs: [id]);
      await SqfliteDeletionLog._recordIn(
          txn, SyncCollections.medications, id);
    });
    await _emit();
  }

  @override
  Stream<List<Medication>> watchAll() async* {
    yield await getAll();
    yield* _controller.stream;
  }

  Medication _decode(Map<String, Object?> row) => Medication.fromJson(
      jsonDecode(row['json'] as String) as Map<String, dynamic>);
}

class SqfliteDoseIntakeRepository implements DoseIntakeRepository {
  final Future<Database> _dbFuture;
  final _controller = StreamController<List<DoseIntake>>.broadcast();

  SqfliteDoseIntakeRepository([Future<Database>? database])
      : _dbFuture = database ?? AppDatabase.open();

  Future<void> _emit() async {
    if (_controller.hasListener) _controller.add(await getIntakes());
  }

  @override
  Future<List<DoseIntake>> getIntakes({DateTime? from, DateTime? to}) async {
    final db = await _dbFuture;
    final where = <String>[];
    final args = <Object?>[];
    if (from != null) {
      where.add('scheduled_at >= ?');
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      where.add('scheduled_at <= ?');
      args.add(to.millisecondsSinceEpoch);
    }
    final rows = await db.query(
      'dose_intakes',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(_decode).toList();
  }

  @override
  Future<DoseIntake?> findFor(
      String medicationId, DateTime scheduledAt) async {
    final db = await _dbFuture;
    final rows = await db.query(
      'dose_intakes',
      where: 'medication_id = ? AND scheduled_at = ?',
      whereArgs: [medicationId, scheduledAt.millisecondsSinceEpoch],
      limit: 1,
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  @override
  Future<void> upsert(DoseIntake intake) async {
    final db = await _dbFuture;
    await db.insert(
      'dose_intakes',
      {
        'id': intake.id,
        'medication_id': intake.medicationId,
        'scheduled_at': intake.scheduledAt.millisecondsSinceEpoch,
        'json': jsonEncode(intake.toJson()),
      },
      // Aynı (ilaç, planlanan an) için tekrar işaretleme, mükerrer satır
      // değil güncelleme üretir -- bkz. idx_dose_intake_slot.
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _emit();
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbFuture;
    await db.delete('dose_intakes', where: 'id = ?', whereArgs: [id]);
    await _emit();
  }

  @override
  Stream<List<DoseIntake>> watchIntakes() async* {
    yield await getIntakes();
    yield* _controller.stream;
  }

  DoseIntake _decode(Map<String, Object?> row) => DoseIntake.fromJson(
      jsonDecode(row['json'] as String) as Map<String, dynamic>);
}
