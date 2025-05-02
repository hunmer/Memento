import 'package:flutter/material.dart';

class FixedSymbolWidget extends StatelessWidget {
  final String symbol;

  const FixedSymbolWidget({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Text(
        symbol,
        style: TextStyle(
          fontSize: 12,
          color: Colors.amber.shade800,
        ),
      ),
    );
  }
}