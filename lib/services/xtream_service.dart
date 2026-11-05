
import 'dart:convert';
import 'package:http/http.dart' as http;

class XtreamService {
  final String baseUrl;
  final String username;
  final String password;

  XtreamService({
    required String baseUrl,
    required this.username,
    required this.password,
  }) : baseUrl = baseUrl.trim().replaceAll(
          RegExp(r'/+$'),
          '',
        );

  Uri get apiUri => Uri.parse('$baseUrl/player_api.php');

  Future<dynamic> _getApi(
    Map<String, String> parameters,
  ) async {
    final uri = apiUri.replace(
      queryParameters: {
        'username': username,
        'password': password,
        ...parameters,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    ).timeout(
      const Duration(seconds: 25),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'خطأ في السيرفر: HTTP ${response.statusCode}',
      );
    }

    return jsonDecode(
      utf8.decode(response.bodyBytes),
    );
  }

  Future<Map<String, dynamic>> login() async {
    final data = await _getApi({});

    if (data is! Map || data['user_info'] is! Map) {
      throw Exception('استجابة تسجيل الدخول غير صحيحة');
    }

    final info = Map<String, dynamic>.from(
      data['user_info'],
    );

    if (info['auth'].toString() != '1') {
      throw Exception('بيانات الدخول غير صحيحة');
    }

    final status = info['status']
        ?.toString()
        .toLowerCase();

    if (status != 'active' && status != 'trial') {
      throw Exception('الاشتراك غير نشط');
    }

    return info;
  }

  Future<List<dynamic>> getLiveCategories() async {
    final data = await _getApi({
      'action': 'get_live_categories',
    });

    return data is List ? data : [];
  }

  Future<List<dynamic>> getLiveStreams({
    String? categoryId,
  }) async {
    final parameters = <String, String>{
      'action': 'get_live_streams',
    };

    if (categoryId != null && categoryId.isNotEmpty) {
      parameters['category_id'] = categoryId;
    }

    final data = await _getApi(parameters);

    return data is List ? data : [];
  }

  String getLiveUrl(dynamic streamId) {
    return '$baseUrl/live/'
        '${Uri.encodeComponent(username)}/'
        '${Uri.encodeComponent(password)}/'
        '${Uri.encodeComponent(streamId.toString())}.ts';
  }
}
