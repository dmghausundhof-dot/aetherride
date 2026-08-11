import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reproduces the Tourenkarten Row pattern (Expanded + badge Flexible) inside
/// an AnimatedSwitcher with StackFit.expand — the sheet layout that previously
/// fed BoxConstraints(w=Infinity) into list cards.
void main() {
  testWidgets('tour card rows layout under expanded AnimatedSwitcher',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 420,
            child: AnimatedSwitcher(
              duration: Duration.zero,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: Column(
                key: const ValueKey('panel-discover'),
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        for (var i = 0; i < 8; i++)
                          Card(
                            child: SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        const Text('⟲'),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Tempelhofer Feld Feierabend $i '
                                            'mit sehr langem Titel',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              'Region · Seed',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton(
                                            onPressed: () {},
                                            child: const Text('Losfahren'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          onPressed: () {},
                                          child: const Text('Mehr'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Tempelhofer'), findsWidgets);
  });
}
