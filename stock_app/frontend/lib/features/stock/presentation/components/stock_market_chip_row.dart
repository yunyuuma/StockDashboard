import 'package:flutter/material.dart';

class StockMarketChipRow extends StatelessWidget {
  const StockMarketChipRow({
    super.key,
    required this.markets,
    required this.selectedMarket,
    required this.onSelected,
  });

  final List<String> markets;
  final String? selectedMarket;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (markets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: const Text('すべて'),
                selected: selectedMarket == null,
                onSelected: (_) => onSelected(null),
              ),
            ),
            ...markets.map(
              (market) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(market),
                  selected: selectedMarket == market,
                  onSelected: (_) => onSelected(market),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}