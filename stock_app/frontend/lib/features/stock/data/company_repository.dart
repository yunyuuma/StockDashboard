import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../domain/company.dart';

class CompanyRepository {

  static List<Company>? _cache;

  Future<List<Company>> fetchAll() async {

    if (_cache != null) return _cache!;

    final csv = await rootBundle.loadString("assets/tse_prime.csv");

    List<List<dynamic>> rows = const CsvToListConverter().convert(csv);

    final companies = <Company>[];

    for (int i = 1; i < rows.length; i++) {

      final r = rows[i];

      companies.add(
        Company(
          code: r[0].toString(),
          name: r[1].toString(),
          kana: r[2].toString(),
          market: r[3].toString(),
          industry: r[4].toString(),

          price: 0,
          changePct: 0,
          marketCap: 0,
          volume: 0,
          favorite: false, 
        ),
      );
    }

    _cache = companies;

    return companies;
  }
}