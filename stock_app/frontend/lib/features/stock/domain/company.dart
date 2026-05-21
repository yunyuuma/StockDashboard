class Company {
  final String code;
  final String name;
  final String kana;
  final String market;
  final String industry;
  final double price;
  final double changePct;
  final double marketCap;
  final double volume;
  final bool favorite;

  const Company({
    required this.code,
    required this.name,
    required this.kana,
    required this.market,
    required this.industry,
    required this.price,
    required this.changePct,
    required this.marketCap,
    required this.volume,
    required this.favorite,
  });

  Company copyWith({
    String? code,
    String? name,
    String? kana,
    String? market,
    String? industry,
    double? price,
    double? changePct,
    double? marketCap,
    double? volume,
    bool? favorite,
  }) {
    return Company(
      code: code ?? this.code,
      name: name ?? this.name,
      kana: kana ?? this.kana,
      market: market ?? this.market,
      industry: industry ?? this.industry,
      price: price ?? this.price,
      changePct: changePct ?? this.changePct,
      marketCap: marketCap ?? this.marketCap,
      volume: volume ?? this.volume,
      favorite: favorite ?? this.favorite,
    );
  }
}