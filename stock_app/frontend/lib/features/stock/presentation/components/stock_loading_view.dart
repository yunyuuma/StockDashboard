import 'package:flutter/material.dart';

class StockLoadingView extends StatelessWidget {
  const StockLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}