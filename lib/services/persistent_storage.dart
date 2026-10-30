import 'persistent_storage_stub.dart'
    if (dart.library.html) 'persistent_storage_web.dart';

Future<Map<String, dynamic>?> fetchFromLocalBackend() => fetchFromLocalBackendPlatform();

Future<void> saveToLocalBackend(Map<String, dynamic> data) => saveToLocalBackendPlatform(data);

