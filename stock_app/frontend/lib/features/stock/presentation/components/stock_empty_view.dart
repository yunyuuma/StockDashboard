import 'package:flutter/material.dart';

class StockEmptyView extends StatelessWidget {
  const StockEmptyView({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
        ),
      ),
    );
  }
}