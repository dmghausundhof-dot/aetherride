import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reproduces Tourenkarten / empty-Ort sheet patterns that previously fed
/// BoxConstraints(w=Infinity) / InfiniteSize into ListView children.
void main() {
  testWidgets('tour card rows layout under expanded AnimatedSwitcher',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
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
                                  mainAxisSize: MainAxisSize.min,
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
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final rich = Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'leicht',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                              const TextSpan(
                                                text: '  ·  Asphalt  ·  ↑40 m',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        );
                                        return Row(
                                          children: [
                                            const Icon(Icons.circle, size: 10),
                                            const SizedBox(width: 6),
                                            if (constraints.maxWidth.isFinite)
                                              Expanded(child: rich)
                                            else
                                              rich,
                                          ],
                                        );
                                      },
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton(
                                            style: FilledButton.styleFrom(
                                              minimumSize: const Size(0, 44),
                                            ),
                                            onPressed: () {},
                                            child: const Text('Losfahren'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: const Size(0, 44),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          onPressed: () {},
                                          child: const Text('Mehr'),
                                        ),
                                      ],
                                    ),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(0, 36),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            onPressed: () {},
                                            child: const Text('Vorschau'),
                                          ),
                                          const SizedBox(width: 4),
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              minimumSize: const Size(0, 36),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                            onPressed: () {},
                                            child: const Text('Von hier'),
                                          ),
                                        ],
                                      ),
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

  testWidgets('empty Ort picker + Demo chips stay bounded in ListView',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 520,
            child: ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Noch keine ~60-Min-Touren hier.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text('Wähle eine Demo-Stadt oder änder den Ort.'),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () {},
                            icon: const Icon(Icons.search),
                            label: const Text('Ort ändern'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Demo-Städte'),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: const [
                            ActionChip(label: Text('Berlin')),
                            ActionChip(label: Text('Heidelberg')),
                            ActionChip(label: Text('Mannheim')),
                            ActionChip(label: Text('München')),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Route selbst planen'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Noch keine ~60-Min-Touren hier.'), findsOneWidget);
    expect(find.text('Demo-Städte'), findsOneWidget);
    expect(find.text('Heidelberg'), findsOneWidget);
  });
}
