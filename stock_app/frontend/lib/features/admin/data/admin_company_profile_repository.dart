import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../stock/domain/app_session.dart';
import '../domain/company_profile_admin.dart';

class AdminCompanyProfileRepository {
  AdminCompanyProfileRepository({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  static const String baseUrl = 'http://127.0.0.1:8080';

  Map<String, String> get _headers {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (AppSession.token != null && AppSession.token!.isNotEmpty)
        'Authorization': 'Bearer ${AppSession.token}',
    };
  }

  Future<List<CompanyProfileAdmin>> fetchProfiles() async {
    final uri = Uri.parse('$baseUrl/api/admin/company-profiles');

    final res = await _client.get(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception(
        'company profiles fetch failed: status=${res.statusCode}, body=${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! List) {
      throw Exception('company profiles response invalid: $decoded');
    }

    return decoded
        .map<CompanyProfileAdmin>(
          (e) => CompanyProfileAdmin.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<CompanyProfileAdmin> fetchProfile(String stockCode) async {
    final uri = Uri.parse('$baseUrl/api/admin/company-profiles/$stockCode');

    final res = await _client.get(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception(
        'company profile fetch failed: status=${res.statusCode}, body=${res.body}',
      );
    }

    return CompanyProfileAdmin.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<CompanyProfileAdmin> createProfile({
    required String stockCode,
    required String website,
    required String description,
    required String mapQuery,
    required String trendsKeyword,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/company-profiles');

    final res = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'stockCode': stockCode,
        'website': website,
        'description': description,
        'mapQuery': mapQuery,
        'trendsKeyword': trendsKeyword,
      }),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
        'company profile create failed: status=${res.statusCode}, body=${res.body}',
      );
    }

    return CompanyProfileAdmin.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<CompanyProfileAdmin> updateProfile({
    required String stockCode,
    required String website,
    required String description,
    required String mapQuery,
    required String trendsKeyword,
  }) async {
    final uri = Uri.parse('$baseUrl/api/admin/company-profiles/$stockCode');

    final res = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode({
        'website': website,
        'description': description,
        'mapQuery': mapQuery,
        'trendsKeyword': trendsKeyword,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(
        'company profile update failed: status=${res.statusCode}, body=${res.body}',
      );
    }

    return CompanyProfileAdmin.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<void> autoFillWithStructuredData(String stockCode) async {
    final uri = Uri.parse(
      '$baseUrl/api/admin/company-profiles/$stockCode/autofill-structured-data',
    );

    final res = await _client.post(uri, headers: _headers);

    if (res.statusCode != 200) {
      throw Exception(
        'company profile structured data autofill failed: status=${res.statusCode}, body=${res.body}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}