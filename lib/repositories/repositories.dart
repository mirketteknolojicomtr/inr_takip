/// Repository katmanı.
/// UI ve servisler yalnızca soyut arayüzlere bağımlıdır (Dependency Inversion).
/// Böylece InMemory -> SQLite (drift/sqflite) -> Uzak API geçişi
/// tek satır DI değişikliğiyle yapılabilir.
library;

import 'dart:async';

import '../models/inr_entry.dart';
import '../models/medication.dart';
import '../models/vitamin_k_log.dart';
import '../models/patient_profile.dart';

// ---------------------------------------------------------------------------
// Soyut arayüzler
// ---------------------------------------------------------------------------

abstract interface class InrRepository {
  Future<List<InrEntry>> getEntries({DateTime? from, DateTime? to});
  Future<InrEntry?> getLatest();
  Future<void> upsert(InrEntry entry);
  Future<void> delete(String id);

  /// Reaktif UI için: her değişiklikte güncel liste yayınlanır.
  Stream<List<InrEntry>> watchEntries();
}

abstract interface class VitaminKRepository {
  Future<List<VitaminKLog>> getLogs({DateTime? from, DateTime? to});
  Future<void> upsert(VitaminKLog log);
  Future<void> delete(String id);
  Stream<List<VitaminKLog>> watchLogs();
}

/// Silinen kayıtların "mezar taşı" (tombstone) defteri.
///
/// Bulut senkronu için zorunludur: yerelde silinen bir kayıt buluttan da
/// silinmezse, bir sonraki çekmede geri gelir ("hortlar"). Yerelin
/// yokluğundan silmeyi çıkarsamak mümkün değildir — başka bir cihazın yeni
/// eklediği kayıt da yerelde yoktur; ikisi ancak açık bir silme kaydıyla
/// ayırt edilir.
///
/// [collection] değeri buluttaki koleksiyon adıyla aynıdır
/// (`inr_entries`, `medications`).
abstract interface class DeletionLog {
  /// Henüz buluta işlenmemiş silmeler.
  Future<Set<String>> pending(String collection);

  /// Yerel silme sırasında çağrılır.
  Future<void> record(String collection, String id);

  /// Bulutta başarıyla silindikten sonra defterden düşülür.
  Future<void> clear(String collection, Iterable<String> ids);
}

abstract interface class ProfileRepository {
  Future<PatientProfile?> getProfile();
  Future<void> saveProfile(PatientProfile profile);
}

abstract interface class MedicationRepository {
  Future<List<Medication>> getAll();
  Future<Medication?> getById(String id);
  Future<void> upsert(Medication medication);
  Future<void> delete(String id);
  Stream<List<Medication>> watchAll();
}

abstract interface class DoseIntakeRepository {
  /// [from] - [to] arasında (planlanan zamana göre) kayıtlar.
  Future<List<DoseIntake>> getIntakes({DateTime? from, DateTime? to});

  /// Belirli bir planlanan doz için kayıt (yoksa null).
  Future<DoseIntake?> findFor(String medicationId, DateTime scheduledAt);

  Future<void> upsert(DoseIntake intake);
  Future<void> delete(String id);
  Stream<List<DoseIntake>> watchIntakes();
}

// ---------------------------------------------------------------------------
// In-memory implementasyon (test ve prototip için).
// Kalıcı depolamada aynı arayüzü drift/sqflite ile implemente edin.
// ---------------------------------------------------------------------------

class InMemoryInrRepository implements InrRepository {
  final _entries = <String, InrEntry>{};
  final _controller = StreamController<List<InrEntry>>.broadcast();

  List<InrEntry> get _sorted =>
      _entries.values.toList()..sort((a, b) => a.date.compareTo(b.date));

  void _emit() => _controller.add(_sorted);

  @override
  Future<List<InrEntry>> getEntries({DateTime? from, DateTime? to}) async {
    return _sorted.where((e) {
      if (from != null && e.date.isBefore(from)) return false;
      if (to != null && e.date.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Future<InrEntry?> getLatest() async =>
      _sorted.isEmpty ? null : _sorted.last;

  @override
  Future<void> upsert(InrEntry entry) async {
    _entries[entry.id] = entry;
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _entries.remove(id);
    _emit();
  }

  @override
  Stream<List<InrEntry>> watchEntries() async* {
    yield _sorted;
    yield* _controller.stream;
  }
}

class InMemoryVitaminKRepository implements VitaminKRepository {
  final _logs = <String, VitaminKLog>{};
  final _controller = StreamController<List<VitaminKLog>>.broadcast();

  List<VitaminKLog> get _sorted =>
      _logs.values.toList()..sort((a, b) => a.date.compareTo(b.date));

  void _emit() => _controller.add(_sorted);

  @override
  Future<List<VitaminKLog>> getLogs({DateTime? from, DateTime? to}) async {
    return _sorted.where((l) {
      if (from != null && l.date.isBefore(from)) return false;
      if (to != null && l.date.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> upsert(VitaminKLog log) async {
    _logs[log.id] = log;
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _logs.remove(id);
    _emit();
  }

  @override
  Stream<List<VitaminKLog>> watchLogs() async* {
    yield _sorted;
    yield* _controller.stream;
  }
}

class InMemoryDeletionLog implements DeletionLog {
  final _byCollection = <String, Set<String>>{};

  @override
  Future<Set<String>> pending(String collection) async =>
      {...?_byCollection[collection]};

  @override
  Future<void> record(String collection, String id) async =>
      _byCollection.putIfAbsent(collection, () => <String>{}).add(id);

  @override
  Future<void> clear(String collection, Iterable<String> ids) async =>
      _byCollection[collection]?.removeAll(ids);
}

class InMemoryProfileRepository implements ProfileRepository {
  PatientProfile? _profile;

  @override
  Future<PatientProfile?> getProfile() async => _profile;

  @override
  Future<void> saveProfile(PatientProfile profile) async =>
      _profile = profile;
}


class InMemoryMedicationRepository implements MedicationRepository {
  final _items = <String, Medication>{};
  final _controller = StreamController<List<Medication>>.broadcast();

  List<Medication> get _sorted => _items.values.toList()
    ..sort((a, b) {
      // Antikoagülan her zaman en üstte -- ana ilaç odakta kalsın.
      if (a.isAnticoagulant != b.isAnticoagulant) {
        return a.isAnticoagulant ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

  void _emit() => _controller.add(_sorted);

  @override
  Future<List<Medication>> getAll() async => _sorted;

  @override
  Future<Medication?> getById(String id) async => _items[id];

  @override
  Future<void> upsert(Medication medication) async {
    _items[medication.id] = medication;
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
    _emit();
  }

  @override
  Stream<List<Medication>> watchAll() async* {
    yield _sorted;
    yield* _controller.stream;
  }
}

class InMemoryDoseIntakeRepository implements DoseIntakeRepository {
  final _items = <String, DoseIntake>{};
  final _controller = StreamController<List<DoseIntake>>.broadcast();

  List<DoseIntake> get _sorted => _items.values.toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  void _emit() => _controller.add(_sorted);

  @override
  Future<List<DoseIntake>> getIntakes({DateTime? from, DateTime? to}) async {
    return _sorted.where((i) {
      if (from != null && i.scheduledAt.isBefore(from)) return false;
      if (to != null && i.scheduledAt.isAfter(to)) return false;
      return true;
    }).toList();
  }

  @override
  Future<DoseIntake?> findFor(
      String medicationId, DateTime scheduledAt) async {
    for (final intake in _items.values) {
      if (intake.medicationId == medicationId &&
          intake.scheduledAt.isAtSameMomentAs(scheduledAt)) {
        return intake;
      }
    }
    return null;
  }

  @override
  Future<void> upsert(DoseIntake intake) async {
    _items[intake.id] = intake;
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
    _emit();
  }

  @override
  Stream<List<DoseIntake>> watchIntakes() async* {
    yield _sorted;
    yield* _controller.stream;
  }
}
