import 'package:flutter/material.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title\n(module en cours de restauration)',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
