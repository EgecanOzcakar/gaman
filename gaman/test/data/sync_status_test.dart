import 'package:flutter_test/flutter_test.dart';
import 'package:gaman/data/sync_status.dart';

void main() {
  test('pending writes → syncing', () {
    expect(
      statusFromMetadata((hasPendingWrites: true, isFromCache: true)),
      SyncStatus.syncing,
    );
  });

  test('from cache, no pending writes → offline', () {
    expect(
      statusFromMetadata((hasPendingWrites: false, isFromCache: true)),
      SyncStatus.offline,
    );
  });

  test('server snapshot → synced', () {
    expect(
      statusFromMetadata((hasPendingWrites: false, isFromCache: false)),
      SyncStatus.synced,
    );
  });
}
