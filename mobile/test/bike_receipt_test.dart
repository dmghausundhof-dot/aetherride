import 'package:aetherride_mobile/domain/garage/bike_receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Beleg-Zusammenfassung zeigt Händler, Betrag und bleibt nach JSON sichtbar', () {
    final r = BikeReceipt(
      id: '1',
      bikeId: 'b1',
      kind: BikeReceiptKind.parts,
      createdAt: DateTime.utc(2026, 8, 19),
      merchant: 'Decathlon',
      amountEur: 42,
      title: 'Kette 11s',
      photoPath: '/tmp/x.jpg',
    );
    expect(r.summary, contains('Decathlon'));
    expect(r.summary, contains('42'));
    expect(r.hasPhoto, isTrue);
    expect(r.hasFacts, isTrue);
    final round = BikeReceipt.fromJson(r.toJson());
    expect(round.merchant, 'Decathlon');
    expect(round.kind, BikeReceiptKind.parts);
    expect(round.photoPath, '/tmp/x.jpg');
  });

  test('leerer Scan lässt Felder leer — Nutzer tippt nach', () {
    final hint = ReceiptScanHint.fromJson({'scanned': false, 'reason': 'no_key'});
    expect(hint.scanned, isFalse);
    expect(hint.reason, ReceiptScanReason.noKey);
    expect(hint.merchant, isNull);
    expect(hint.amountEur, isNull);
    expect(receiptScanMessage(hint.reason), contains('Vision-Schlüssel'));
  });

  test('erfolgreicher Scan füllt Händler und Betrag', () {
    final hint = ReceiptScanHint.fromJson({
      'scanned': true,
      'reason': 'ok',
      'merchant': 'Radwerk',
      'amountEur': 120,
      'kind': 'workshop',
      'items': ['Inspektion'],
    });
    expect(hint.scanned, isTrue);
    expect(hint.merchant, 'Radwerk');
    expect(hint.amountEur, 120);
    expect(receiptScanMessage(hint.reason), contains('vorausgefüllt'));
  });
}
