import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LiveCategory {
  final String id, name;
  LiveCategory(this.id, this.name);
}

class LiveChannel {
  final String id, name, icon, categoryId;
  LiveChannel(this.id, this.name, this.icon, this.categoryId);
}

class XtreamService {
  final String baseUrl, username, password;
  XtreamService(String url, this.username, this.password)
      : baseUrl = normalize(url);

  static String normalize(String url) {
    var u = url.trim();
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  Uri _api([String? action, Map<String, String>? extra]) {
    final b = Uri.parse(baseUrl);
    return b.replace(
      path: '${b.path}/player_api.php',
      queryParameters: {
        'username': username,
        'password': password,
        if (action != null) 'action': action,
        ...?extra,
      },
    );
  }

  Future<dynamic> _get(Uri uri) async {
    final r = await http.get(uri).timeout(const Duration(seconds: 25));
    if (r.statusCode != 200) {
      throw Exception('خطأ من السيرفر (${r.statusCode})');
    }
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  Future<Map<String, dynamic>> login() async {
    final d = await _get(_api());
    final info = (d is Map) ? d['user_info'] : null;
    if (info == null || '${info['auth']}' != '1') {
      throw Exception('بيانات الدخول غير صحيحة');
    }
    if ('${info['status']}' != 'Active') {
      throw Exception('الاشتراك غير فعّال (${info['status']})');
    }
    return Map<String, dynamic>.from(d);
  }

  Future<List<LiveCategory>> liveCategories() async {
    final d = await _get(_api('get_live_categories'));
    return (d as List)
        .map((e) => LiveCategory('${e['category_id']}', '${e['category_name']}'))
        .toList();
  }

  Future<List<LiveChannel>> liveStreams(String categoryId) async {
    final d = await _get(_api('get_live_streams', {'category_id': categoryId}));
    return (d as List)
        .map((e) => LiveChannel('${e['stream_id']}', '${e['name']}',
            '${e['stream_icon'] ?? ''}', '${e['category_id']}'))
        .toList();
  }

  String liveUrl(String streamId) =>
      '$baseUrl/live/${Uri.encodeComponent(username)}/${Uri.encodeComponent(password)}/$streamId.ts';

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('url', baseUrl);
    await p.setString('user', username);
    await p.setString('pass', password);
  }

  static Future<XtreamService?> saved() async {
    final p = await SharedPreferences.getInstance();
    final u = p.getString('url'), n = p.getString('user'), w = p.getString('pass');
    if (u == null || n == null || w == null) return null;
    return XtreamService(u, n, w);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }
}
