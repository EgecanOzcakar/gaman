/// Whether the signed-in account's data is up to date with the server.
enum SyncStatus {
  /// No cloud backup — data lives only on this device.
  localOnly,

  /// Everything is on the server.
  synced,

  /// Local changes are on their way to the server.
  syncing,

  /// No connection — changes are queued locally.
  offline,
}

/// Maps Firestore snapshot metadata to a [SyncStatus].
SyncStatus statusFromMetadata(
    ({bool hasPendingWrites, bool isFromCache}) m) {
  if (m.hasPendingWrites) return SyncStatus.syncing;
  if (m.isFromCache) return SyncStatus.offline;
  return SyncStatus.synced;
}
