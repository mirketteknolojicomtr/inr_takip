/// Repository katmanı.
/// UI ve servisler yalnızca soyut arayüzlere bağımlıdır (Dependency Inversion).
/// Böylece InMemory -> SQLite (drift/sqflite) -> Uzak API geçişi
/// tek satır DI değişikliğiyle yapılabilir.
library;

import 'dart:async';

import '../models/inr_entry.dart';
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

abstract interface class ProfileRepository {
  Future<PatientProfile?> getProfile();
  Future<void> saveProfile(PatientProfile profile);
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

class InMemoryProfileRepository implements ProfileRepository {
  PatientProfile? _profile;

  @override
  Future<PatientProfile?> getProfile() async => _profile;

  @override
  Future<void> saveProfile(PatientProfile profile) async =>
      _profile = profile;
}
