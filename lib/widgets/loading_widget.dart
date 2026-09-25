import 'package:flutter/material.dart';

class GroceryLoadingWidget extends StatelessWidget {
  const GroceryLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0D4828),
      ),
    );
  }
}
