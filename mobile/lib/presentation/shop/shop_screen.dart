import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Passende Teile für dein Bike — Kompat-Urteile aus der Garage, '
              'Kauf beim Partner. Die vollständige Shop-Erfahrung läuft aktuell '
              'in der Web-App (Slot-Filter, Merkliste, Anlass-Empfehlungen).',
            ),
          ],
        ),
      ),
    );
  }
}
