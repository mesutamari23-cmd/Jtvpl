import 'dart:convert';
import 'package:http/http.dart' as http;

class XtreamService {
  final String baseUrl;
  final String username;
  final String password;

  XtreamService({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  String get cleanedUrl {
    String url = baseUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    return url;
  }

  Future<bool> authenticate() async {
    final url = Uri.parse('$cleanedUrl/player_api.php?username=$username&password=$password');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['user_info'] != null && data['user_info']['auth'] != 0;
      }
    } catch (e) {
      print('Authentication failed: $e');
    }
    return false;
  }

  Future<List<dynamic>> getLiveCategories() async {
    final url = Uri.parse('$cleanedUrl/player_api.php?username=$username&password=$password&action=get_live_categories');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error getting categories: $e');
    }
    return [];
  }

  Future<List<dynamic>> getLiveStreams({String? categoryId}) async {
    String urlStr = '$cleanedUrl/player_api.php?username=$username&password=$password&action=get_live_streams';
    if (categoryId != null && categoryId.isNotEmpty) {
      urlStr += '&category_id=$categoryId';
    }
    try {
      final response = await http.get(Uri.parse(urlStr));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error getting live streams: $e');
    }
    return [];
  }

  String buildStreamUrl(dynamic streamId, {String ext = 'm3u8'}) {
    return '$cleanedUrl/live/$username/$password/$streamId.$ext';
  }
}
