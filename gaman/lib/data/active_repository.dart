import 'dart:async';

import '../services/auth_service.dart';
import 'models.dart';
import 'repository.dart';
import 'sync_status.dart';

/// The [Repository] the app talks to. Delegates to whichever backend belongs
/// to the current user and re-points every open `watch*` stream when that
/// changes (sign-in finishing in the background, sign-out, account switch),
/// so providers and screens never hold a stale uid.
class ActiveRepository implements Repository {
  ActiveRepository(this._current);

  /// Follows [auth]: builds a repository for each new uid via [build] (null
  /// uid = signed out) and calls [onSignedIn] after switching to a signed-in
  /// one, e.g. to migrate local data in the background.
  factory ActiveRepository.followAuth(
    AuthService auth, {
    required Repository Function(String? uid) build,
    void Function(Repository repo)? onSignedIn,
  }) {
    var uid = auth.uid;
    final active = ActiveRepository(build(uid));
    if (uid != null) onSignedIn?.call(active.current);
    auth.addListener(() {
      if (auth.uid == uid) return;
      uid = auth.uid;
      active.switchTo(build(uid));
      if (uid != null) onSignedIn?.call(active.current);
    });
    return active;
  }

  Repository _current;
  Repository get current => _current;
  final _changed = StreamController<Repository>.broadcast(sync: true);

  void switchTo(Repository next) {
    final old = _current;
    if (identical(old, next)) return;
    _current = next;
    _changed.add(next);
    old.dispose();
  }

  Stream<T> _follow<T>(Stream<T> Function(Repository r) watch) {
    late final StreamController<T> out;
    StreamSubscription<T>? inner;
    StreamSubscription<Repository>? outer;
    void attach(Repository r) {
      inner?.cancel();
      inner = watch(r).listen(out.add, onError: out.addError);
    }

    out = StreamController<T>(
      onListen: () {
        attach(_current);
        outer = _changed.stream.listen(attach);
      },
      onCancel: () async {
        await outer?.cancel();
        await inner?.cancel();
      },
    );
    return out.stream;
  }

  @override
  Stream<List<JournalEntry>> watchJournal() => _follow((r) => r.watchJournal());
  @override
  Future<void> upsertJournalEntry(JournalEntry entry) =>
      _current.upsertJournalEntry(entry);
  @override
  Future<void> deleteJournalEntry(String id) => _current.deleteJournalEntry(id);

  @override
  Stream<List<TodoTask>> watchTasks(DateTime day) =>
      _follow((r) => r.watchTasks(day));
  @override
  Future<void> saveTasks(DateTime day, List<TodoTask> tasks) =>
      _current.saveTasks(day, tasks);

  @override
  Stream<List<ActivityEvent>> watchActivity() =>
      _follow((r) => r.watchActivity());
  @override
  Future<void> addActivity(ActivityEvent event) => _current.addActivity(event);

  @override
  Stream<AppSettings> watchSettings() => _follow((r) => r.watchSettings());
  @override
  Future<void> saveSettings(AppSettings settings) =>
      _current.saveSettings(settings);

  @override
  Stream<SyncStatus> watchSyncStatus() => _follow((r) => r.watchSyncStatus());

  @override
  Future<Map<String, Object?>> exportData() => _current.exportData();

  @override
  Future<void> dispose() async {
    await _changed.close();
    await _current.dispose();
  }
}
