// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

Future<Map<String, dynamic>?> fetchFromLocalBackendPlatform() async {
  try {
    final response = await html.HttpRequest.getString('/api/storage');
    if (response.trim().isNotEmpty) {
      final dynamic decoded = jsonDecode(response);
      if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
        return decoded;
      }
    }
  } catch (_) {
    // Falls back seamlessly to SharedPreferences
  }
  return null;
}

Future<void> saveToLocalBackendPlatform(Map<String, dynamic> data) async {
  try {
    final jsonStr = jsonEncode(data);
    await html.HttpRequest.request(
      '/api/storage',
      method: 'POST',
      sendData: jsonStr,
      requestHeaders: {'Content-Type': 'application/json; charset=UTF-8'},
    );
  } catch (_) {
    // Ignore fallback
  }
}

