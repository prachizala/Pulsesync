import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

class ApiClient {
  String baseUrl;
  String? _authToken;

  ApiClient({this.baseUrl = AppConstants.defaultBaseUrl});

  void setBaseUrl(String url) {
    baseUrl = url;
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/access-token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _authToken = data['access_token'] as String;
      return data;
    } else {
      throw Exception('Login failed: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>> pushSync(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sync/push'),
      headers: _headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Sync push failed: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>> pullSync(DateTime? since) async {
    final queryParams = since != null ? {'since': since.toUtc().toIso8601String()} : <String, String>{};
    final uri = Uri.parse('$baseUrl/sync/pull').replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Sync pull failed: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<dynamic>> fetchNearestResponders(int incidentId, {double maxDistanceKm = 50.0}) async {
    final uri = Uri.parse('$baseUrl/sync/incidents/$incidentId/nearest-responders')
        .replace(queryParameters: {'max_distance_km': maxDistanceKm.toString()});

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Fetch nearest responders failed: ${response.statusCode}');
    }
  }
}
