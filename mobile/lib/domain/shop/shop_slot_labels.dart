/// Browse-Chips — Spiegel `PARTS_BROWSE_SLOTS` plus gängige Slot-Keys.
String shopSlotLabel(String key) {
  const labels = <String, String>{
    'brake_pads': 'Beläge',
    'grips': 'Griffe',
    'fluid': 'Fluid',
    'chain': 'Kette',
    'tire': 'Reifen',
    'cassette': 'Kassette',
    'bar_tape': 'Lenkerband',
    'fork': 'Gabel',
    'suspension': 'Fahrwerk',
    'wheel': 'Laufräder',
    'drivetrain': 'Antrieb',
    'brake': 'Bremsen',
    'brakes': 'Bremsen',
    'rotor': 'Bremsscheibe',
  };
  return labels[key] ?? key.replaceAll('_', ' ');
}
