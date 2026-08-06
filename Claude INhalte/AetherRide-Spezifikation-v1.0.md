# AetherRide — Produkt-, Architektur- und Design-Spezifikation

**Version:** 1.0 (Baseline für Entwicklungsstart)
**Datum:** 06.08.2026
**Status:** Freigabereif, vorbehaltlich der in Kapitel 11 gelisteten offenen Punkte
**Zielgruppe des Dokuments:** Product, Design, Mobile Engineering, Backend Engineering, ML, QA, Legal

---

## 0. Dokumentkontrolle und Lesehinweise

### 0.1 Verbindlichkeitsstufen

Dieses Dokument verwendet RFC-2119-Terminologie in deutscher Entsprechung:

| Begriff | Bedeutung |
|---|---|
| **MUSS** | Zwingend. Abweichung ist ein Blocker-Defekt. |
| **SOLL** | Verbindlich, Abweichung nur mit dokumentierter Begründung und PM-Freigabe. |
| **KANN** | Optional, Umsetzung nach Kapazität. |
| **DARF NICHT** | Explizites Verbot. Verstoß ist ein Blocker-Defekt. |

Jede Anforderung trägt eine stabile ID (`F-*` Feature, `NFR-*` nicht-funktional, `DM-*` Datenmodell, `R-*` Risiko, `A-*` Annahme). IDs werden nie wiederverwendet.

### 0.2 Referenzgeräte

Alle Performance- und Batterieaussagen beziehen sich auf:
- **iOS-Referenz:** iPhone 13 (A15), iOS 17+
- **Android-Referenz:** Google Pixel 7 (Tensor G2), Android 13+
- **Android-Minimum:** Snapdragon 6-Klasse, 6 GB RAM, Android 10 (API 29)
- **iOS-Minimum:** iPhone XR, iOS 16

### 0.3 Terminologie (Auszug, vollständiges Glossar in Anhang C)

- **Setup** — Ein unveränderlicher (immutabler) Snapshot aller Einstellwerte eines Bikes zu einem Zeitpunkt.
- **Bracketing** — Strukturiertes Testverfahren: gezielte Verstellung eines einzelnen Parameters über den Bereich hinweg, um das Optimum einzugrenzen.
- **SAG** — Negativfederweg unter statischer Fahrerlast, in Prozent des Gesamthubs.
- **FNI** — Federweg-Nutzungs-Index (siehe 0.4.2). Ausdrücklich **keine** Millimeterangabe.
- **LDI** — Bosch Live Data Interface.

---

### 0.4 Realitätsabgleich: fünf Korrekturen am Ausgangsbriefing

Der Auftrag verlangt eine widerspruchsfreie Spezifikation ohne erfundene Hersteller-APIs und ohne nicht existierende Features. Fünf Punkte des Briefings sind in ihrer wörtlichen Fassung technisch, rechtlich oder physikalisch nicht umsetzbar. Sie werden hier korrigiert; **die korrigierte Fassung gilt im gesamten Dokument.**

#### 0.4.1 „Direkte Anbindung an Bosch und Shimano Motoren" — asymmetrisch, nicht symmetrisch

Die beiden Hersteller sind **nicht gleichwertig zugänglich**. Der Recherchestand (August 2026):

- **Bosch** betreibt mit dem **Live Data Interface (LDI)** eine dokumentierte, standardisierte BLE-Schnittstelle, die laut Bosch kostenfrei für Dritt-Apps und -Geräte nutzbar ist. Freigegebene Datenpunkte: Geschwindigkeit, Akku-Ladestand, Fahrerleistung, Trittfrequenz, Gesamtdistanz, Zeit, Lichtstatus, Umgebungshelligkeit, Lichtreserve-Modus, eBike-Lock-Status, Stillstandserkennung, Ladegerät verbunden, Diagnosewerkzeug verbunden. Erste Referenzintegration: Garmin Edge. Voraussetzung ist das Bosch *smart system*; ältere Bosch-Generationen (Active/Performance Line mit Intuvia/Nyon 1) sind **nicht** abgedeckt. Zusätzlich existieren eBike SDK und Cloud API, die sich jedoch an Fahrradhersteller (OEM) richten, nicht an unabhängige App-Anbieter.
  Quellen: `bosch-ebike.com/us/business/live-data-interface`, `bosch-ebike.com/en/company/industry-solutions/cloud-api-ebike-sdk`, Bosch-Presseinformation zum Live Data Interface (2026).
- **Shimano** bietet **keine** öffentlich dokumentierte, für Smartphone-Apps nutzbare Schnittstelle. Der Zugang zum proprietären Kommunikationsprofil läuft über ein **vertragsbasiertes Lizenzprogramm** („Connected Partners"); Dritt-Radcomputer binden Di2/STEPS über das **private ANT-Netzwerk** an (Ganganzeige, Akkustand, Einstellwerte). ANT ist auf modernen Smartphones faktisch nicht verfügbar (iOS gar nicht ohne externe Hardware, Android nur auf wenigen Geräten mit ANT-Radio).
  Quellen: `bike.shimano.com/technologies/details/shimano-connected-partners.html`, Shimano-Produktkommunikation zum Lizenzprogramm, Shimano-Newsroom zur Di2-Wireless-Funktionalität.

**Konsequenz (verbindlich):**

| | Bosch | Shimano |
|---|---|---|
| Live-Telemetrie lesen | **Ja**, via LDI (smart system), MVP-fähig | **Nein** ohne Lizenzvertrag |
| Assist-Modus **schreiben/steuern** | **Nein** — nicht Teil der offenen LDI-Datenpunkte | **Nein** |
| MVP-Umsetzung | LDI-Read-only | Manuelle Erfassung + Standard-BLE-Sensorik |
| Phase 2 | Cloud-API-Prüfung | Lizenzverhandlung (Gate G-3, Kap. 9) |

**F-EBK-000 (MUSS):** Die App **DARF NICHT** Motorsteuerung (Assist-Modus-Wechsel, Parameteränderung, Tuning) anbieten, solange kein schriftlicher Herstellervertrag vorliegt, der dies erlaubt. Reverse Engineering proprietärer Protokolle, Protokoll-Spoofing und jede Form von Schreibzugriff ohne Freigabe sind **verboten** — technisch, vertraglich und wegen EN 15194 / Produkthaftung.

Im Briefing genannte Features „Assist-Modi steuern" und „Motor-Profile pro Bike (schreibend)" werden zu **Nice-to-Have, Gate-abhängig** herabgestuft. „Assist-Modi speichern" wird zu einem *Logging*-Feature (Auslesen und Protokollieren des gefahrenen Modus, sofern der Hersteller ihn exponiert; bei Bosch LDI derzeit nicht in der freien Datenliste → Fallback: Ableitung aus Leistungs-/Geschwindigkeitssignatur mit Konfidenzangabe, klar als Schätzung gekennzeichnet).

#### 0.4.2 „Geschätzte Federweg-Nutzung" — Index statt Millimeter

Ein am Lenker montiertes Smartphone misst die Beschleunigung der **gefederten Masse**, nicht den Hub von Gabel oder Dämpfer. Eine Millimeterangabe wäre eine Erfindung. Zweifache Integration der Vertikalbeschleunigung liefert nur über kurze, hochpassgefilterte Fenster eine brauchbare *relative* Wegschätzung; absolute Werte driften.

**Korrigiert:** Es wird ein **Federweg-Nutzungs-Index (FNI, 0–100)** ausgegeben, normiert auf die eigene Historie desselben Bikes, plus ein separater, physikalisch belastbarer **Durchschlag-Verdachts-Detektor** (charakteristische Beschleunigungsspitze mit sehr kurzer Anstiegszeit). Die UI **DARF NICHT** Millimeter- oder Prozent-des-Federwegs-Angaben aus Sensordaten anzeigen. Freigabe des Features erst nach bestandener Validierungsstudie (Akzeptanzkriterien in 7.5).

#### 0.4.3 „Dark Mode als Default" **und** „Sunlight-Mode" — ein Zielkonflikt

Dunkle Oberflächen sind bei direkter Sonneneinstrahlung schlechter lesbar, weil die Displayleuchtdichte gegen die Umgebungsleuchtdichte anarbeiten muss und Reflexionen den Schwarzwert anheben. Ein „Sunlight-Mode" auf dunklem Grund ist ein Widerspruch.

**Korrigiert:** Dark bleibt Default für alle Screens. **Sunlight Mode ist ein separates, helles Hochkontrast-Theme**, das ausschließlich im Ride-Screen automatisch (Umgebungslichtsensor > 8.000 lx für > 4 s) oder manuell aktiviert wird. Es ist eine bewusste, begründete Ausnahme vom Dark-Default, kein Widerspruch. Details in 4.3.

#### 0.4.4 „Shop mit Versand" — Modellwahl statt Logistikaufbau

Eigene Lagerhaltung, Retourenlogistik, Produkthaftung und EU-Gewährleistung sind ein eigenständiges Unternehmen, kein App-Feature. Zudem verbietet Apple die Abwicklung physischer Waren über In-App-Purchase — Zahlungen laufen zwingend über einen externen Payment-Anbieter.

**Korrigiert:** MVP+1 startet als **kuratiertes Affiliate-/Partner-Modell** (Katalog + Kompatibilitätsprüfung in AetherRide, Checkout beim Partnerhändler), Phase 3 optional als **Marketplace mit Partner-Fulfillment** (Händler versendet, AetherRide ist Vermittler und Zahlungsabwickler). Eigenes Warenlager ist **out of scope**. Begründung und Ausbaustufen in 8.4.

#### 0.4.5 „Die erste wirklich intelligente All-in-One-App" — Claim nicht extern verwendbar

Superlativ-Werbeaussagen sind in Deutschland nach UWG angreifbar, wenn sie nicht belegbar sind. Der Satz bleibt als interne Vision zulässig, **DARF NICHT** in Store-Listing, Website oder In-App-Copy erscheinen. Zugelassene Positionierungsaussage siehe 1.3.

---

## 1. Executive Summary und Produktpositionierung

### 1.1 Kurzfassung

AetherRide verbindet drei Domänen, die heute in getrennten Apps liegen: **Tourenplanung/Navigation**, **Bike- und Setup-Verwaltung** und **fahrdatenbasierte Fahrwerksanalyse**. Der strukturelle Unterschied zu allen Wettbewerbern ist nicht ein einzelnes Feature, sondern die **Datenkopplung**: Die Garage ist die Fundamentaldatenbank, alles andere liest aus ihr und schreibt in sie zurück.

Konkret entsteht daraus eine Kette, die keine bestehende App schließt:

```
Garage (welches Bike, welche Gabel, welcher Dämpfer, welches Setup)
   ↓
Route (Routing-Profil und Vorschläge passend zu Bike + Fahrstil + Akku)
   ↓
Ride (Sensorik weiß, welches Fahrwerk sie beobachtet)
   ↓
Post-Ride (Empfehlung in Klicks und psi, nicht in Allgemeinplätzen)
   ↓
Setup-Historie (Bracketing belegt, ob es besser wurde)
   ↓
Shop (nur was nachweislich an dieses Bike passt)
   ↓
Garage (neues Teil verbaut → Kreis schließt sich)
```

Jede Empfehlung ist an ein konkretes Bauteil mit bekannten Spezifikationen gebunden. Genau das ist der Graben zum Wettbewerb — und zugleich der Grund, warum die **Komponenten-Datenbasis** das teuerste und risikoreichste Asset des Produkts ist (siehe R-04).

### 1.2 Wettbewerbsanalyse und Lücke

| Produkt | Stärke | Lücke, die AetherRide adressiert |
|---|---|---|
| Komoot | Tourenplanung, Community-Content, Offline | Kein Bike-/Komponentenmodell, keine Setup-Logik, keine Fahrwerksanalyse |
| Strava | Social, Segmente, Trainingsanalyse | Bike nur als Kilometerzähler; keine Setup-Dimension |
| Trailforks | Trail-Datenbank, Trail-Status, MTB-Fokus | Schwache Alltagsnavigation, kein Setup, kein Bike-Modell |
| Bosch eBike Flow | Tiefe Motorintegration | Nur Bosch, nur E-Bike, kein Fahrwerk, keine Multi-Bike-Garage |
| Shimano E-TUBE | Antriebskonfiguration | Nur Shimano, keine Navigation, kein Fahrwerk |
| ShockWiz / Suspension-Tools | Echte Fahrwerksmessung | Zusatzhardware nötig, kein Routing, keine Garage, meist nur Luftfahrwerk |
| Bike-Wartungs-Apps | Wartungshistorie | Keine Sensorik, keine Navigation, keine Kompatibilitätslogik |

**Die Lücke:** Niemand koppelt Hardware-Wissen mit Fahrdaten mit Navigation. Wer das Fahrwerk misst, kennt das Bike nicht. Wer das Bike kennt, misst nichts. Wer navigiert, tut beides nicht.

**Wichtige Ehrlichkeit gegenüber dem Team:** Die Fahrwerksmessung per Smartphone ist gegenüber dedizierter Federwegssensorik (Linearpotentiometer) prinzipiell schwächer. Der Vorteil ist nicht Präzision, sondern **Null-Zusatzkosten und Null-Montageaufwand** bei ausreichender Aussagekraft für Setup-*Richtungsentscheidungen*. Das Produktversprechen MUSS entsprechend formuliert sein („zeigt dir die Richtung"), nicht als Laborgenauigkeit.

### 1.3 Freigegebene Positionierungsaussage

> **AetherRide ist die Tourenapp, die dein Bike kennt.**
> Navigation, Fahrwerks-Setup und Komponenten in einem — weil jede Empfehlung nur so gut ist wie das Wissen darüber, was du fährst.

Zulässige Nebenclaims: „Setup-Empfehlungen auf Basis deiner eigenen Fahrdaten", „Kompatibilität nachvollziehbar geprüft", „Offline-fähig". Unzulässig: Superlative, Genauigkeitsversprechen in mm, Aussagen über Herstellerpartnerschaften vor Vertragsabschluss.

### 1.4 Geschäftsmodell

| Stufe | Umfang | Preis (Vorschlag, Markt DACH) |
|---|---|---|
| **Free** | 1 Bike, Ride-Tracking, Basis-Post-Ride, Routenplanung online, Wartungslog | 0 € |
| **Pro** | Unbegrenzte Bikes, Fahrwerksanalyse + FNI, Offline-Karten, Bracketing, KI-Coach, Reichweitenprognose | 6,99 €/Monat, 59,99 €/Jahr |
| **Shop** | Affiliate-Provision bzw. Marketplace-Take-Rate | 5–12 % (Affiliate), 8–15 % (Marketplace) |

Begründung der Paywall-Grenze: Die kostenpflichtigen Features sind genau jene mit hohen laufenden Grenzkosten (Kartenkacheln, LLM-Inferenz, Sensor-Storage) oder hohem Aufbauwert (Multi-Bike, Bracketing-Historie). Das Free-Tier MUSS eigenständig nützlich bleiben, sonst scheitert die Datenakquise für Heatmaps (siehe R-06).

### 1.5 Nordstern-Metrik und KPIs

**Nordstern:** *Anzahl Nutzer, die pro Monat mindestens eine Setup-Änderung auf Basis einer App-Empfehlung vornehmen und protokollieren.* Diese Metrik ist der einzige Beleg, dass die Kernthese trägt.

| KPI | Zielwert 12 Monate nach Launch |
|---|---|
| D30-Retention (Ride-Tracker) | ≥ 28 % |
| Anteil Nutzer mit ≥ 1 vollständig erfasstem Bike | ≥ 70 % der aktivierten Nutzer |
| Anteil Rides mit verwertbarer Fahrwerksanalyse | ≥ 45 % der MTB/Enduro-Rides |
| Angenommene Setup-Empfehlungen | ≥ 25 % der ausgespielten Empfehlungen |
| Free → Pro Konversion | ≥ 6 % |
| Crash-freie Sessions | ≥ 99,7 % |
| Kompatibilitäts-Fehlurteile (falsch „passt") | **0** kritische, < 0,5 % aller Prüfungen unklar-fehlklassifiziert |

Die letzte Zeile ist die härteste: Ein falsches „passt" bei einer sicherheitsrelevanten Komponente ist ein Produkt-Totalschaden. Die Engine antwortet im Zweifel mit „Daten unzureichend" (siehe 2.2).

---

## 2. Feature-Spezifikation

### 2.0 Priorisierungsschema

| Stufe | Bedeutung | Release |
|---|---|---|
| **P0** | Must-Have. Ohne dieses Feature ist das Produktversprechen nicht erfüllt. | MVP (v1.0) |
| **P1** | Must-Have für Marktreife, aber MVP kann ohne launchen. | v1.1–v1.3 |
| **P2** | Should-Have. Deutlicher Mehrwert, kein Kernversprechen. | Phase 2 |
| **P3** | Nice-to-Have. | Phase 3+ |
| **G** | Gate-abhängig: Umsetzung nur nach externem Ereignis (Vertrag, Studie). | Siehe Gate-ID |

---

### 2.1 Multi-Bike-Garage (Fundament)

Die Garage ist die einzige Quelle der Wahrheit für Bike-Daten. Kein anderes Modul hält eigene Bike-Attribute.

#### F-GAR-001 — Bike anlegen (P0, MUSS)
Nutzer legen beliebig viele Bikes an. Drei Erfassungswege, absteigend nach Aufwand für den Nutzer:

1. **Katalog-Auswahl** (Standardweg): Hersteller → Modell → Modelljahr → Ausstattungsvariante. Die App befüllt daraufhin die komplette Komponentenliste aus der OEM-Spezifikation vor.
2. **Basis-Anlage**: Kategorie (MTB Trail / All-Mountain / Enduro / Downhill / Gravel / Road / Urban / E-MTB / E-Trekking / Hiking-Profil ohne Bike) + Federweg + Laufradgröße. Komponenten werden schrittweise ergänzt.
3. **Import**: Übernahme aus vorhandener GPX-/FIT-Historie erzeugt ein Platzhalter-Bike ohne Komponenten.

**Akzeptanzkriterien:**
- Zeit bis zum ersten fahrbereiten Bike über Weg 1: ≤ 90 s (Median, unmoderierter Test, n ≥ 8).
- Ein Bike ist ohne jede Komponentenangabe nutzbar; Features, die Komponenten brauchen, zeigen einen expliziten „Fehlt: Gabelmodell"-Hinweis mit Direktlink statt einer Fehlermeldung.
- Ein Bike MUSS als „aktiv" markierbar sein; genau ein Bike ist zu jedem Zeitpunkt aktiv.

#### F-GAR-002 — Komponentenverwaltung (P0, MUSS)
Pflicht-Komponentenslots pro Bike-Typ. Jeder Slot referenziert entweder einen Katalog-Eintrag (`ComponentModel`) oder einen freien Texteintrag mit Warnhinweis, dass ohne Katalogbezug keine Kompatibilitätsprüfung und keine Setup-Empfehlung möglich ist.

Slots (MTB/E-MTB vollständig): Rahmen, Gabel, Dämpfer, Steuersatz, Vorbau, Lenker, Griffe, Sattelstütze (inkl. Dropper-Hub), Sattel, Laufradsatz (Vorderrad/Hinterrad getrennt: Nabe, Felge, Speichen), Reifen v/h (inkl. Insert), Kassette, Kette, Kurbel, Kettenblatt, Schaltwerk, Schalthebel, Innenlager, Bremsen v/h, Bremsscheiben v/h, Bremsbeläge v/h, Pedale, Motor, Akku, Display/Remote.
Gravel/Road zusätzlich: Umwerfer, Lenkerband. Hiking-Profil: keine Bike-Slots, stattdessen Ausrüstungsslots (Schuhe, Rucksack, Stöcke) — reduziert, nur für Wartungs-/Shop-Kontext.

**Regeln:**
- Jede Komponente MUSS ein `installed_at` und optional `removed_at` tragen. Komponentenwechsel erzeugt Historie, überschreibt nichts.
- Laufleistung pro Komponente wird automatisch aus den Rides des Bikes im Einbauzeitraum aggregiert (km, Höhenmeter, Fahrzeit, bei Bremsen zusätzlich Abfahrts-Höhenmeter).
- Eine Komponente MUSS zwischen Bikes verschiebbar sein (Laufradsatz, Pedale) unter Mitnahme ihrer Laufleistung.

#### F-GAR-003 — Kompatibilitäts-Engine (P0, MUSS)

Regelbasiert, deterministisch, vollständig erklärbar. **Kein ML im Entscheidungspfad.**

**Vier zulässige Urteile — mehr nicht:**

| Urteil | Bedeutung | UI-Farbe |
|---|---|---|
| `COMPATIBLE` | Alle relevanten Regeln erfüllt, alle benötigten Fakten vorhanden. | Grün |
| `CONDITIONAL` | Passt nur unter einer benannten Bedingung (z. B. „nur mit Adapter X", „nur bis Reifenbreite 2,4″"). | Orange |
| `INCOMPATIBLE` | Mindestens eine Regel ist verletzt. | Rot |
| `INSUFFICIENT_DATA` | Ein für die Entscheidung nötiges Attribut fehlt oder ist unbestätigt. | Grau |

**F-GAR-003.1 (MUSS):** Die Engine **DARF NICHT** raten. Fehlt ein Attribut, ist das Urteil `INSUFFICIENT_DATA` mit Angabe, *welches* Attribut fehlt und wie es beschafft werden kann. Ein `COMPATIBLE` ohne vollständige Faktenlage ist ein Blocker-Defekt.

**F-GAR-003.2 (MUSS):** Jedes Urteil liefert eine **Begründungskette**: ausgewertete Regel-ID, verglichene Attributwerte, Quelle jedes Attributs (OEM-Datenblatt / Herstellerangabe / redaktionell gepflegt / Nutzereingabe) inkl. Datum. Die UI zeigt diese Kette auf Antippen vollständig an.

**F-GAR-003.3 (MUSS):** Sicherheitsrelevante Kategorien (Bremsen, Gabel, Steuersatz, Lenker, Vorbau, Sattelstütze, Rahmen, Laufräder, Reifen) erhalten zusätzlich den Hinweis auf Montage durch eine Fachwerkstatt und die Herstellerangaben zu Drehmomenten. Drehmomentwerte werden **ausschließlich** aus Herstellerdokumenten übernommen, nie geschätzt oder interpoliert.

**Regelbeispiele (illustrativ, echte Standards):**

| Regel-ID | Prüfung |
|---|---|
| `RL-DRV-011` | Kassetten-Freilaufstandard vs. Nabe (HG / Micro Spline / XD / XDR) — exakte Gleichheit erforderlich |
| `RL-FRM-004` | Hinterbau-Einbaubreite und Achsstandard (135×10 QR, 142×12, 148×12 Boost, 157×12 SuperBoost) — exakte Gleichheit |
| `RL-SUS-007` | Dämpfer-Einbaulänge und Hub vs. Rahmenvorgabe (metrisch/imperial, Trunnion vs. Standard) inkl. Hardware-Breite und Buchsen-Durchmesser |
| `RL-SUS-012` | Gabel-Schaftrohr (1 1/8″ / tapered 1,5″) vs. Steuersatz-Standard (ZS44/ZS56, IS42/IS52, EC34) |
| `RL-BRK-003` | Bremssattel-Aufnahme (Post Mount, Flat Mount, IS) + Scheibendurchmesser → benötigter Adapter |
| `RL-BRK-008` | Bremsscheiben-Aufnahme (6-Loch vs. Center Lock) vs. Nabe |
| `RL-WHL-005` | Reifenbreite (ETRTO) vs. Felgen-Maulweite — Herstellerfreigabe bevorzugt, sonst Fallback-Tabelle → `CONDITIONAL` |
| `RL-WHL-009` | Reifen-Außenmaß vs. Rahmen-/Gabelfreigang laut Herstellerangabe → bei fehlender Angabe `INSUFFICIENT_DATA` |
| `RL-CKP-002` | Lenker-Klemmdurchmesser (31,8 / 35,0 mm) vs. Vorbau |
| `RL-SPT-006` | Sattelstützendurchmesser (27,2 / 30,9 / 31,6 / 34,9) + max. Einstecktiefe vs. Sitzrohrlänge → Dropper-Hub-Berechnung |
| `RL-BB-003` | Innenlager-Standard (BSA 68/73, T47, PF92, BB30, PF30) vs. Kurbelwelle |
| `RL-EBK-002` | Motor-Interface vs. Rahmenaufnahme; bei E-Bikes generell `INCOMPATIBLE` für Motortausch außerhalb OEM-Freigabe |

Die Regel-Syntax ist in 6.6 spezifiziert.

#### F-GAR-004 — Visuelle Bike-Darstellung (P1, SOLL)
Kein 3D-Rendering, kein fotorealistisches Modell. Stattdessen ein **schematisches SVG-Bike** pro Kategorie (8 Silhouetten: Hardtail, Fully-Trail, Fully-Enduro, Downhill, Gravel, Road, Urban, E-MTB) mit Hotspots auf den Komponentenslots. Zustandsfarbe pro Hotspot: gepflegt / Wartung fällig / Daten fehlen.

Begründung gegen 3D: Aufwand pro Bike-Modell wäre unbegrenzt, der Nutzen gegenüber einer Schemazeichnung mit Hotspots gering. Zusätzlich KANN der Nutzer ein eigenes Foto hinterlegen, das in Listen als Bike-Bild dient.

#### F-GAR-005 — Wartung (P0 Basis, P1 Prognose)
- **P0:** Manuelles Wartungslog (Datum, Komponente, Tätigkeit, Kosten, Werkstatt/Eigen, Notiz, Fotos).
- **P0:** Intervall-Erinnerungen auf Basis von km / Betriebsstunden / Kalendertagen, Default-Intervalle aus Herstellerangaben, vom Nutzer überschreibbar.
- **P1:** Belastungsgewichtete Prognose: Bremsbelagverschleiß skaliert mit Abfahrts-Höhenmetern und Bremsereignissen aus der Sensorik; Kettenverschleiß mit Fahrzeit unter Last und Nässe-Indikator (Wetter-API zum Ride-Zeitpunkt). Ausgabe immer als Spanne („Belagwechsel in 250–400 km"), nie als Punktwert.

---

### 2.2 Setup-Verwaltung und Bracketing

#### F-SET-001 — Setup als immutabler Snapshot (P0, MUSS)
Ein `Setup` ist unveränderlich. Jede Änderung erzeugt eine neue Version mit Referenz auf die Vorgängerversion. Das eliminiert die gesamte Konfliktklasse beim Offline-Sync (siehe 5.6) und ist Voraussetzung dafür, dass Fahrdaten dauerhaft einem exakten Einstellzustand zugeordnet bleiben.

Erfasste Werte (soweit für die verbaute Komponente definiert, aus deren Katalogeintrag abgeleitet):
- **Gabel:** Luftdruck (psi/bar), Token-Anzahl, Zugstufe (Klicks von geschlossen), Low-Speed-Druckstufe, High-Speed-Druckstufe, SAG (%), Federwegsnutzung-Referenz, Offset, Vorspannung (Stahlfeder), Federhärte
- **Dämpfer:** analog + Hebelverhältnis-Kontext, Volumen-Spacer, Piggyback-Druck
- **Reifen:** Druck v/h, Insert ja/nein, Modell, Casing, Compound
- **Cockpit:** Lenkerbreite/-rise/-roll, Bremshebelwinkel, Spacer unter Vorbau, Sattelhöhe/-versatz/-neigung
- **E-Bike:** gefahrener Assist-Modus (aus LDI/manuell), Akku-Kapazität

**MUSS:** Für jeden Wert wird der vom Hersteller freigegebene Bereich mitgeführt. Werte außerhalb sind eingebbar, werden aber rot markiert und **DÜRFEN NICHT** von der App empfohlen werden (harte Grenze in der Empfehlungs-Engine, siehe 7.4).

#### F-SET-002 — Setup-Vorlagen (P1, SOLL)
Vom Hersteller-Basissetup (Gewicht → Luftdruck-Empfehlungstabelle des Herstellers) und von Community-/Redaktions-Presets („Enduro-Rennen, nass", „Bikepark", „Marathon"). Presets **MÜSSEN** als Ausgangspunkt gekennzeichnet sein, nicht als Empfehlung.

#### F-SET-003 — Bracketing-Protokoll (P0, MUSS)
Der methodische Kern des Produkts und das stärkste Differenzierungsmerkmal.

Ablauf:
1. Nutzer wählt **einen** Parameter (z. B. Zugstufe Gabel) und einen Testbereich (z. B. 4 → 10 Klicks).
2. Die App wählt oder der Nutzer wählt ein **Referenzsegment** (0,5–3 km, wiederholt befahrbar). Die App erkennt Wiederholungen des Segments per Geometrie-Matching.
3. Pro Konfiguration **mindestens 2 Durchgänge** (MUSS). Die App zählt mit und fordert fehlende Durchgänge aktiv ein.
4. Auswertung vergleicht Konfigurationen anhand von Segmentzeit, Flow-Score, Impact-Härte, FNI und subjektivem Rating.
5. **MUSS:** Ein Unterschied wird nur dann als Verbesserung ausgewiesen, wenn er die **Lauf-zu-Lauf-Streuung derselben Konfiguration** übersteigt. Formal: Effekt gilt als belegt bei |Δ| > 1,5 × (gepoolte Standardabweichung der Wiederholungen) **und** n ≥ 2 pro Konfiguration. Andernfalls lautet die Ausgabe „kein belegbarer Unterschied" — das ist ein **gültiges und erwünschtes Ergebnis**, kein Fehlerfall.
6. Nur **ein** Parameter pro Bracketing-Serie (MUSS). Der Versuch, zwei Parameter gleichzeitig zu ändern, wird blockiert mit Erklärung.

**Akzeptanzkriterium:** In einem Blindtest mit identischem Setup in beiden „Konfigurationen" meldet die App in ≥ 90 % der Fälle „kein belegbarer Unterschied". Dieser Test ist Teil der Release-Regression.

#### F-SET-004 — Subjektives Feedback (P0, MUSS)
Nach jedem Ride (überspringbar, max. 3 Taps): Gesamtgefühl 1–5; danach optional gerichtete Fragen mit festen Antworten statt Freitext, z. B. „Front: zu weich / passt / zu hart", „Rückmeldung beim Anbremsen: taucht ab / neutral / hart", „Kleine Schläge: rau / passt / vage". Diese kategorialen Antworten sind maschinell nutzbar und werden mit den Sensorwerten desselben Rides gemeinsam ausgewertet (siehe 7.4).

---

### 2.3 Sensorik und Fahrwerksanalyse

#### F-SEN-001 — Erfassung (P0, MUSS)

| Sensor | Zielrate | Bemerkung |
|---|---|---|
| Accelerometer | 200 Hz | Bereich soweit verfügbar ±16 g; Sättigung MUSS erkannt und markiert werden |
| Gyroskop | 200 Hz | ±2000 °/s |
| Magnetometer | 25 Hz | nur für Heading-Stabilisierung |
| Barometer | so hoch wie plattformseitig verfügbar | iOS liefert relative Höhe nur ca. 1 Hz — Vertikalgeschwindigkeit aus Druck ist auf iOS entsprechend grob; Höhenprofil primär aus GNSS + DEM |
| GNSS | 1 Hz | iOS auf 1 Hz begrenzt; Android teils höher, aber nicht vorausgesetzt |

**MUSS:** Erfassung läuft nativ (iOS: CoreMotion mit Batch-Handler; Android: `SensorManager` mit `SensorDirectChannel` bzw. FIFO-Batching). Sample-für-Sample-Übergabe an die Flutter-Schicht ist **verboten** — Übergabe erfolgt in Blöcken von 1 s über einen nativen Ringpuffer.

#### F-SEN-002 — Montage-Erkennung und Kalibrierung (P0, MUSS)

Ohne bekannte Montageposition ist jede Fahrwerksaussage wertlos. Deshalb:

**Montagemodi:** `HANDLEBAR`, `STEM`, `POCKET`, `BACKPACK`, `BODY`, `UNKNOWN`.

- Erkennung automatisch über Orientierungsstabilität und Vibrationsspektrum (am Lenker dominiert ein charakteristisches Band > 15 Hz mit hoher Kohärenz; am Körper wird es durch Dämpfung stark unterdrückt).
- **MUSS:** Das Ergebnis wird dem Nutzer zur Bestätigung vorgelegt. Automatik allein genügt nicht.
- **MUSS:** Fahrwerksmetriken (FNI, Durchschlagsverdacht, Federungs-Aktivität) sind **ausschließlich** bei bestätigtem `HANDLEBAR` oder `STEM` **und** gültiger Kalibrierung verfügbar. In allen anderen Fällen zeigt die UI „Fahrwerksanalyse nicht verfügbar — Halterung am Lenker nötig" und blendet die Metriken aus. Sie **DARF NICHT** ausgegraut mit Platzhalterwerten dargestellt werden.

**Kalibrierungsablauf (einmalig pro Bike + Halterung, ca. 45 s):**
1. **Ausrichtung:** Bike aufrecht auf ebenem Grund, 5 s ruhig halten → Gravitationsvektor → Montage-Quaternion (Transformation Gerätesystem → Bike-System).
2. **Federungs-Antwortmessung:** Drei kräftige Kompressionen der Front, danach loslassen. Aus dem Ausschwingvorgang werden gedämpfte Eigenfrequenz `f_d` und über das logarithmische Dekrement das Dämpfungsmaß `ζ` geschätzt. Dies ist ein direkt gemessener, physikalisch belastbarer Wert und die Grundlage der Zugstufen-Empfehlung.
3. **SAG-Erfassung:** geführt per O-Ring-Ablesung, Eingabe in mm; optional kamerabasiert mit beiliegendem Referenzmarker bekannter Länge. **Nicht** aus Beschleunigungsdaten geschätzt.

Die Kalibrierung MUSS verfallen, wenn Halterung oder Fahrwerkskomponente wechselt.

#### F-SEN-003 — Live-Metriken (P0, MUSS)

| Metrik | Definition | Verfügbarkeit |
|---|---|---|
| Geschwindigkeit, Distanz, Höhe | GNSS + Barometer + DEM-Abgleich | immer |
| G-Kräfte | Beschleunigungsbetrag im Bike-System, getrennt nach Achsen, 1 s-Peak und RMS | immer |
| **Schräglage** | **Nicht** aus dem Gravitationsvektor allein — dieser zeigt beim Kurvenfahren die Resultierende aus Erd- und Zentrifugalbeschleunigung und unterschätzt die reale Schräglage systematisch. Berechnung stattdessen aus Fahrgeschwindigkeit und Gierrate: `θ = atan(v · ω_yaw / g)`, plausibilisiert gegen die fusionierte Lage. | ab 8 km/h |
| Impact-Erkennung | Beschleunigungsspitze über adaptivem Schwellwert + Ruck-Kriterium; Klassifikation in leicht/mittel/hart nach Energieinhalt | Lenker/Stem |
| Federungs-Aktivität | RMS der Vertikalbeschleunigung im Band 1–8 Hz (gefederte Masse) | Lenker/Stem |
| **FNI** (Federweg-Nutzungs-Index) | Bandbegrenzte doppelte Integration der Vertikalbeschleunigung über 2-s-Fenster, hochpassgefiltert bei 0,5 Hz, normiert auf die Verteilung des jeweiligen Bikes. Ausgabe 0–100 mit Konfidenz. | Lenker/Stem, nach Gate G-2 |
| Durchschlagsverdacht | Ereignisdetektor auf sehr steilflankige Verzögerungsspitze (Anstiegszeit < 10 ms) mit anschließender charakteristischer Signatur | Lenker/Stem, nach Gate G-2 |
| **Flow-Score** | Siehe unten | ab 3 min Fahrzeit |

#### F-SEN-004 — Flow-Score, offengelegt (P0, MUSS)

Der Flow-Score **DARF NICHT** eine intransparente Zahl sein. Er ist ein gewichteter Index aus vier offengelegten Teilwerten, jeder 0–100:

| Teilwert | Grundlage | Gewicht |
|---|---|---|
| Geschwindigkeitskonstanz | `100 · (1 − Variationskoeffizient der Geschwindigkeit)` im Segment | 0,30 |
| Laufruhe | invers zum RMS des Rucks im Band 2–12 Hz, normiert auf Terrainklasse | 0,30 |
| Bremsökonomie | invers zur Anzahl und Härte der Bremsereignisse pro km, terrainnormiert | 0,25 |
| Linienruhe | invers zur Varianz der Gierrate abzüglich des durch die Streckengeometrie erklärten Anteils | 0,15 |

**MUSS:** Die vier Teilwerte sind in der UI einzeln sichtbar. **MUSS:** Der Score ist nur innerhalb derselben Terrainklasse und nur gegen die eigene Historie vergleichbar; jede Darstellung, die einen Vergleich zwischen Nutzern nahelegt, ist untersagt (verhindert Wettbewerbsanreize auf öffentlichen Wegen — siehe R-09).

#### F-SEN-005 — Live-Hinweise während der Fahrt (P1, SOLL, eingeschränkt)
Während der Fahrt **DARF NICHT** zum Ablesen aufgefordert werden. Zulässig sind ausschließlich: kurze Sprachhinweise (max. 6 Wörter) bei sicherheitsrelevanten Ereignissen und bei erreichten Bracketing-Durchgängen („Durchgang 2 erfasst"). Detaillierte Setup-Hinweise erscheinen **erst im Stand** (Geschwindigkeit < 3 km/h für > 10 s) oder post-ride. Begründung: Bedienung und Ablesen während der Fahrt sind ein reales Unfallrisiko und in mehreren Jurisdiktionen reguliert.

#### F-SEN-006 — Datenhaltung (P0, MUSS)
Rohdaten werden als `int16`-Deltas mit Zeitbasis in 60-s-Chunks abgelegt, Zstandard-komprimiert. Zielgröße ≤ 4 MB/h. Aufbewahrung auf dem Gerät: 30 Tage rollierend (konfigurierbar); Upload nur bei WLAN und nur mit Einwilligung. Serverseitig werden standardmäßig **nur die abgeleiteten Kennwerte** gespeichert, Rohdaten nur bei aktiver Zustimmung für Modellverbesserung (Opt-in, Art. 6 Abs. 1 lit. a DSGVO, jederzeit widerrufbar).

---

### 2.4 Navigation und Routenplanung

#### F-NAV-001 — Sportartspezifisches Routing (P0, MUSS)
Sieben Profile mit je eigener Kostenfunktion: `MTB_TRAIL`, `MTB_ENDURO`, `GRAVEL`, `ROAD`, `EBIKE_TOUR`, `EMTB`, `HIKING`.

Bewertungsgrundlage ist ausschließlich vorhandenes OSM-Tagging: `highway`, `surface`, `smoothness`, `tracktype`, `mtb:scale`, `mtb:scale:uphill`, `sac_scale`, `trail_visibility`, `width`, `incline`, `access`/`bicycle`/`foot`, `bicycle=dismount`, `network`. Höhendaten aus Copernicus DEM GLO-30, ergänzt durch nationale offene Höhenmodelle höherer Auflösung, wo lizenzrechtlich zulässig.

**MUSS:** Wo Tagging fehlt, wird der Weg nicht „optimistisch" bewertet, sondern erhält eine Unsicherheitsmarkierung, und die Routenzusammenfassung weist den Anteil unsicherer Kilometer aus.

**F-NAV-001.1 (MUSS) — Wegerecht:** Die Zulässigkeit des Radfahrens auf Wegen ist regional unterschiedlich geregelt (Beispiel: Wegbreitenregelungen in einzelnen Bundesländern). Es MUSS eine separate, versionierte Regel-Ebene je Jurisdiktion geben, die Routing-Ergebnisse einschränkt oder mit Hinweis versieht. Der jeweils aktuelle Rechtsstand ist vor Release und danach halbjährlich juristisch zu prüfen (Verantwortung: Legal, siehe A-07). Die App **DARF NICHT** aktiv über gesperrte Wege routen.

#### F-NAV-002 — Offline (P0, MUSS)
- Kartenkacheln als **PMTiles**-Regionen (Vektor), gerendert mit MapLibre GL Native.
- Routing offline mit **Valhalla** — dieselbe Engine wie serverseitig, damit Online- und Offline-Ergebnisse identisch sind. Dies ist der Hauptgrund für die Engine-Wahl (Begründung in 5.4).
- Regionsdownload nach Kartenausschnitt oder Land/Bundesland. Zielgröße: 10.000 km² inkl. Routing-Kacheln und Höhendaten ≤ 350 MB.
- **MUSS:** Alle Kernfunktionen außer Shop, KI-Chat und Routenvorschlägen sind offline vollständig nutzbar.

#### F-NAV-003 — Turn-by-Turn-Sprachnavigation (P0, MUSS)
Manöverdaten aus Valhalla, Formulierung lokal, Ausgabe über System-TTS. Ansagen: 400 m / 150 m / 30 m vor dem Manöver (bei > 25 km/h zeitbasiert statt distanzbasiert). Zusätzlich Warnansagen für steile Abfahrten, Schwierigkeitswechsel (`mtb:scale`-Sprung) und Verlassen des Offline-Bereichs. Sprachen zum Launch: DE, EN. Audio-Ducking gegenüber Musik ist Pflicht; Ansagen über Bluetooth-Headset MÜSSEN unterstützt werden.

#### F-NAV-004 — Routenvorschläge (P1, SOLL)
Eingangsgrößen: aktives Bike (Kategorie, Federweg, E-Antrieb, Akkukapazität), Fahrstilprofil, verfügbare Zeit, Startpunkt, Wetterprognose, Historie, Restreichweite bei E-Bikes. Ausgabe: 3–5 Vorschläge mit Begründung („weil du Trails mit S1–S2 bevorzugst und 2,5 h Zeit hast; 780 hm, Rundkurs"). **MUSS:** Jeder Vorschlag nennt die drei stärksten Begründungsfaktoren.

#### F-NAV-005 — Heatmaps (P2)
Ausschließlich aus **eigenen** aggregierten Nutzerdaten. **MUSS:** Anzeige eines Wegsegments erst ab ≥ 5 verschiedenen Nutzern (k-Anonymität), Fang auf OSM-Geometrie, keine Zeitstempel, Ausschluss von Privatsphärenzonen und Start-/Endpunkten. Kaltstart wird offen kommuniziert; kein Zukauf fremder Heatmap-Daten ohne geklärte Lizenz.

#### F-NAV-006 — Trail View (P2)
Straßen-/Wegbilder aus **Mapillary** (offene Lizenz, Attribution Pflicht) plus nutzergenerierte Fotos mit Geobezug und Blickrichtung. **DARF NICHT** proprietäre Bilddienste einbetten, deren Nutzungsbedingungen dies untersagen.

#### F-NAV-007 — Höhenprofil und Oberflächenanalyse (P0, MUSS)
Interaktives Profil mit Steigungsfarbcodierung, darunter zwei Bänder: Oberfläche (`surface`) und technische Schwierigkeit (`mtb:scale` bzw. `sac_scale`). Antippen einer Profilstelle setzt den Kartenmarker. Datenlücken werden als Lücke dargestellt, **nicht** interpoliert kaschiert.

---

### 2.5 E-Bike-Integration

Aufbauend auf Korrektur 0.4.1. Vier klar getrennte Stufen, in der UI transparent gemacht.

#### F-EBK-001 — Stufe 0: Manuell (P0, MUSS)
Motor- und Akkumodell aus dem Katalog, Kapazität in Wh, Systemgeneration. Reichweitenprognose rein physikalisch (siehe F-EBK-004). Funktioniert mit jedem E-Bike jedes Herstellers und ist der garantierte Basispfad.

#### F-EBK-002 — Stufe 1: Bosch Live Data Interface (P0, MUSS, sofern LDI verfügbar)
Read-only-Anbindung an Bosch smart system über die dokumentierte BLE-Schnittstelle. Übernommene Größen entsprechend der Bosch-Freigabe: Geschwindigkeit, Akkuladestand, Fahrerleistung, Trittfrequenz, Gesamtdistanz, Fahrzeit, Lichtstatus, Lock-Status, Stillstand, Ladegerät verbunden.

**MUSS:**
- Verbindungsstatus und Systemgeneration sind in der UI sichtbar; bei nicht unterstützten Bosch-Generationen wird eindeutig auf Stufe 0 zurückgefallen mit Erklärung.
- Es findet **kein** Schreibzugriff statt.
- Vor Implementierung sind die aktuellen Bosch-Nutzungsbedingungen, Markenrichtlinien und ggf. Registrierungspflichten zu prüfen und einzuhalten (A-01).

#### F-EBK-003 — Stufe 1b: Standard-BLE-Sensorik (P0, MUSS)
Unabhängig vom Motorhersteller: Cycling Speed and Cadence (CSCS), Cycling Power (CPS), Heart Rate (HRS). Das ist die einzige herstellerunabhängige, offen standardisierte Datenquelle und deckt Shimano-Bikes zumindest teilweise ab, sofern das jeweilige System diese Profile bereitstellt.

#### F-EBK-004 — Reichweitenprognose (P0 Basismodell, P1 Selbstkalibrierung)
Physikbasiert, kein Blackbox-ML:

```
P_gesamt(v) = [ C_rr · m · g · cos(α)
              + ½ · ρ · C_d · A · (v + v_wind)²
              + m · g · sin(α)
              + m · a ] · v
P_motor = max(0, P_gesamt − P_fahrer) / η_antrieb, begrenzt auf P_nenn und v_cutoff
```

- `m` aus Fahrergewicht + Bike-Gewicht (Garage!) + Gepäck
- `C_rr` aus Reifenmodell und -druck (Garage!) und `surface`-Tag der Route
- `C_d·A` aus Sitzposition/Bike-Kategorie, kalibrierbar
- `α` aus dem Höhenprofil der geplanten Route
- `P_fahrer` aus historisch geschätzter Dauerleistung des Nutzers
- `η`, `P_nenn`, `v_cutoff` aus dem Motor-Katalogeintrag; `v_cutoff` MUSS der gesetzlichen Klasse folgen (25 km/h Pedelec / 45 km/h S-Pedelec)

**MUSS:** Ausgabe als Spanne mit Konfidenzband, nie als einzelne Kilometerzahl. Die Prognose wird pro Nutzer über abgeschlossene Rides nachkalibriert (Kalman-artige Anpassung von `C_rr`, `C_d·A`, `P_fahrer`).

Dies ist der Punkt, an dem die Garage messbar Wert liefert: Reifendruck und Reifenmodell verändern die Prognose signifikant — kein Wettbewerber hat diese Daten.

#### F-EBK-005 — Assist-Modus-Protokollierung (P2, Gate G-3)
Sofern und sobald ein Hersteller den aktiven Modus auslesbar macht: Protokollierung je Ride-Abschnitt und Auswertung im Post-Ride. Ohne diese Datenquelle: Schätzung aus Leistungs-/Geschwindigkeitssignatur, **zwingend** als Schätzung gekennzeichnet, oder manuelle Angabe. **Keine** Steuerung (F-EBK-000).

---

### 2.6 KI-System

#### F-AI-001 — Trennung von Entscheidung und Formulierung (P0, MUSS)

Die zentrale Architekturregel, die Rule 8 des Auftrags („jede Empfehlung muss auf realen Daten basieren") technisch durchsetzbar macht:

> **Ein Sprachmodell trifft in AetherRide keine Entscheidungen und erzeugt keine Zahlenwerte. Es formuliert ausschließlich Ergebnisse, die deterministische Engines geliefert haben.**

Umsetzung:
1. Regel-/Analyse-Engines erzeugen ein strukturiertes `RecommendationSet` mit expliziten Werten, Einheiten, Konfidenz und Quellen.
2. Das LLM erhält dieses Objekt plus Nutzerkontext und formuliert daraus Text.
3. Ein **Numeric-Guard** parst die LLM-Ausgabe, extrahiert alle Zahlen mit Einheit und vergleicht sie gegen die Whitelist aus Schritt 1. Nicht belegte Zahlen ⇒ Ausgabe wird verworfen und der deterministische Fallback-Text ausgegeben. **MUSS**, mit Metrik in der Observability (Zielrate verworfener Antworten < 2 %).

#### F-AI-002 — Rider-Profil (P1, SOLL)
Abgeleitete, erklärbare Merkmale statt undurchsichtiger Embeddings:
- Terrainpräferenz (Verteilung über `mtb:scale`, Steigungsklassen, Oberflächen)
- Fahrstil-Indikatoren: mittlere Bremsintensität vor Kurven, Anteil Zeit über 0,4 g Querbeschleunigung, Impact-Häufigkeit, Sprunghäufigkeit (Airtime-Erkennung über Freifallphasen)
- Ausdauerprofil: Leistungsdauer-Kurve, wo Leistungsdaten vorliegen; sonst Geschwindigkeits-Steigungs-Modell
- Präferenzen aus explizitem Feedback

**MUSS:** Jedes Profilmerkmal ist für den Nutzer einsehbar, erklärt und korrigierbar.

#### F-AI-003 — Post-Ride-Analyse (P0, MUSS)
Struktur: (1) Was ist passiert — Fakten. (2) Was fiel auf — max. 3 Beobachtungen. (3) Was du ändern kannst — **maximal eine** Setup-Empfehlung pro Ride.

Die Begrenzung auf eine Empfehlung ist bewusst: Mehrere gleichzeitige Änderungen machen jede Wirkungszuordnung unmöglich und widersprechen dem Bracketing-Prinzip.

Format einer Empfehlung (MUSS, alle Felder):
> **Zugstufe Gabel: 2 Klicks langsamer** (aktuell 6 von offen, empfohlen 8)
> *Warum:* Ausschwingmessung ergab ζ ≈ 0,21 — unterhalb des Zielbereichs für dein Enduro-Setup. Dazu 14 harte Impacts über 3,2 km Abfahrt und dein Feedback „Front zu rau".
> *Erwartete Wirkung:* ruhigere Front bei Schlagfolgen, etwas weniger Pop.
> *Grenzen:* Herstellerbereich 0–14 Klicks. *Konfidenz:* mittel.

#### F-AI-004 — Natürliche Sprachschnittstelle (P2)
Chat-Interface mit Werkzeugzugriff auf: Garage-Abfragen, Kompatibilitätsprüfung, Setup-Historie, Ride-Statistik, Routensuche, Produktsuche. **MUSS:** Antworten zu Kompatibilität und Setup kommen ausschließlich aus den Engine-Werkzeugen; das Modell **DARF NICHT** aus eigenem Wissen antworten. Bei fehlendem Werkzeugergebnis lautet die Antwort, dass die Daten fehlen.

**MUSS:** Keine Sprach-Chat-Bedienung während der Fahrt in v1.

---

### 2.7 Shop

#### F-SHP-001 — Katalog mit Kompatibilitätsfilter (P1, SOLL)
Jedes Produkt ist mit einem `ComponentModel` verknüpft und wird gegen das aktive Bike geprüft. Anzeige ausschließlich mit Kompatibilitätsurteil aus F-GAR-003.

**MUSS:** Produkte mit Urteil `INCOMPATIBLE` werden für das aktive Bike ausgeblendet oder unmissverständlich markiert. Produkte mit `INSUFFICIENT_DATA` werden mit Hinweis auf die fehlende Angabe gezeigt, **nicht** als passend beworben.

#### F-SHP-002 — Empfehlungen (P2)
Anlässe: Verschleißgrenze erreicht (aus Wartungsprognose), wiederkehrendes Setup-Problem, für das das Bauteil die Ursache ist (z. B. „Zugstufe am Anschlag und weiterhin zu schnell → Dämpferservice oder anderes Tune"), Saisonwechsel (Reifen). **MUSS:** Jede Produktempfehlung nennt den auslösenden Datenpunkt. Empfehlungen ohne Datenanlass sind untersagt.

#### F-SHP-003 — Checkout (P1/P3)
- **Phase MVP+1 (Affiliate):** Weiterleitung zum Partnerhändler; kein Zahlungsverkehr in der App.
- **Phase 3 (Marketplace):** Checkout in-app über Stripe. **MUSS:** Physische Waren laufen **nicht** über Apple IAP (Store-Regelverstoß). Pflichtangaben nach EU-Recht: Widerrufsbelehrung (14 Tage), Impressum, Versandkosten und Lieferzeit vor Kaufabschluss, Gewährleistung, GPSR-Herstellerangaben.

---

### 2.8 Wanderprofil

Wandern ist kein Nebenprodukt, aber auch kein zweites Vollprodukt.

**Enthalten (P0):** `HIKING`-Routingprofil mit `sac_scale`, Turn-by-Turn, Offline-Karten, Tracking, Höhenprofil, Ausrüstungsliste.
**Nicht enthalten:** Fahrwerksanalyse (offensichtlich), Bracketing, Kompatibilitäts-Engine.
**MUSS:** Der Wechsel in den Wandermodus blendet alle Bike-spezifischen UI-Elemente aus, statt sie leer anzuzeigen.

---

### 2.9 Konto, Sync, Datenschutz als Nutzerfunktion

| ID | Feature | Prio |
|---|---|---|
| F-ACC-001 | Registrierung per E-Mail, Apple Sign-in, Google Sign-in | P0 |
| F-ACC-002 | Vollständige lokale Nutzung ohne Konto für Tracking und Garage; Sync erfordert Konto | P0 |
| F-ACC-003 | Datenexport (GPX, FIT, JSON-Vollexport inkl. Garage und Setups) | P0, DSGVO Art. 20 |
| F-ACC-004 | Kontolöschung in-app, Wirkung ≤ 30 Tage, Bestätigung per E-Mail | P0, DSGVO Art. 17 |
| F-ACC-005 | Privatsphärenzonen: Radius um Adressen, in dem Tracks gekappt werden | P0 |
| F-ACC-006 | Granulare Einwilligungen: Rohdaten-Upload, Heatmap-Beitrag, Produktempfehlungen, Analytics — je einzeln, je widerrufbar | P0 |
| F-ACC-007 | Familien-/Mehrfahrer-Garage (ein Bike, mehrere Fahrer mit eigenen Setups) | P3 |

---

## 3. Informationsarchitektur und User Flows

### 3.1 Navigationsstruktur

Fünf Tabs, wie im Briefing vorgegeben. Der Ride-Tab ist zentral und hervorgehoben, weil er der einzige Tab mit einem Zustand ist („läuft gerade" vs. „bereit").

```
┌─────────────────────────────────────────────────────────────┐
│  Home        Garage       ●RIDE●       Discover      Shop    │
└─────────────────────────────────────────────────────────────┘

Home ──┬── Nächster Vorschlag (Route)
       ├── Aktives Bike + Setup-Fingerprint + Status
       ├── Letzter Ride (Zusammenfassung, Tap → Post-Ride)
       ├── Offene Empfehlung (max. 1)
       └── Wartung fällig (max. 2)

Garage ─┬── Bike-Liste (Karten, aktives Bike zuoberst)
        └── Bike-Detail ─┬── Übersicht (Schema + Hotspots)
                         ├── Komponenten ── Komponenten-Detail ──┬── Specs
                         │                                        ├── Laufleistung
                         │                                        ├── Kompatibilität prüfen
                         │                                        └── Ersetzen → Shop
                         ├── Setups ──┬── Aktuelles Setup (Editor)
                         │            ├── Historie (Zeitstrahl)
                         │            └── Bracketing ── Serie ── Auswertung
                         └── Wartung ─┬── Fällig
                                      └── Log

Ride ──┬── Bereit (Bike, Profil, Route optional, Halterungs-Check)
       ├── Live (Karte / Daten / Fahrwerk — 3 wischbare Ebenen)
       ├── Pausiert
       └── Beenden → Post-Ride ─┬── Zusammenfassung
                                ├── Fahrwerk
                                ├── Segmente
                                ├── Feedback (3 Taps)
                                └── Empfehlung (max. 1)

Discover ─┬── Vorschläge (KI, an aktives Bike gebunden)
          ├── Suche/Filter
          ├── Gespeicherte Routen
          └── Routen-Detail ── Planer (Wegpunkte, Profilwechsel, Offline laden)

Shop ──┬── Für dein <Bike> (Kompatibilitätsgefiltert)
       ├── Kategorien
       ├── Verschleiß-Anlässe
       └── Produkt-Detail (Kompatibilitätsurteil zuoberst)

Nicht in der Tab-Bar (über Avatar oben rechts erreichbar):
  Profil ─┬── Rider-Profil (KI, erklärt und korrigierbar)
          ├── Statistik
          ├── Einstellungen ─┬── Einheiten, Sprache, Ansagen
          │                  ├── Handschuh-Modus, Sunlight-Modus
          │                  ├── Sensorik (Rate, Speicher)
          │                  └── Geräte (BLE, LDI)
          └── Datenschutz ──┬── Einwilligungen (granular)
                            ├── Privatsphärenzonen
                            ├── Export
                            └── Konto löschen
```

**Regel (MUSS):** Das aktive Bike ist auf jedem Screen der ersten Ebene sichtbar (Bike-Chip in der Kopfzeile, tappbar zum Wechseln). Das ist die UI-Umsetzung des Prinzips „Bike immer sichtbar und zentral".

### 3.2 Kern-Flows

#### Flow A — Onboarding bis erster Ride (Ziel: < 4 Minuten)

```
Start
 │
 ├─ 1. Was fährst du?  [MTB/E-MTB/Gravel/Road/Wandern]        (1 Tap)
 ├─ 2. Bike anlegen    [Katalogsuche → Modell → Jahr]         (3–5 Taps)
 │      └─ ohne Treffer → Basis-Anlage (Kategorie+Federweg)
 ├─ 3. Gewicht + Fahrergewicht                                (1 Eingabe)
 │      → sofortiger Nutzen: Hersteller-Basisdruck wird angezeigt
 ├─ 4. Berechtigungen: Standort "immer" mit Primer            (Primer VOR Systemdialog)
 ├─ 5. [Optional] Halterung + Kalibrierung (45 s)             — überspringbar
 └─ 6. → Ride bereit
```

**MUSS:** Kein Konto-Zwang vor Schritt 6. Registrierung wird nach dem ersten abgeschlossenen Ride angeboten, mit konkretem Grund („damit deine Setups nicht verloren gehen").
**MUSS:** Berechtigungs-Primer erklärt *vor* dem Systemdialog, warum Hintergrundstandort nötig ist. Ein abgelehnter Systemdialog ist auf iOS praktisch endgültig.

#### Flow B — Ein Ride mit Fahrwerksanalyse

```
Ride-Tab
 │
 ├─ Bereit-Screen: aktives Bike ✓ | Profil ✓ | Halterung?
 │    └─ Halterungs-Check: "Handy am Lenker?" [Ja/Nein]
 │         ├─ Ja + kalibriert → Fahrwerksanalyse AN  ●
 │         ├─ Ja, nicht kalibriert → Kalibrierung anbieten (45 s / später)
 │         └─ Nein → Fahrwerksanalyse AUS, Hinweis, kein Platzhalter
 ├─ START (großer Button, 72 dp, unterer Bildschirmdrittel)
 ├─ Live: 3 wischbare Ebenen — Karte | Daten | Fahrwerk
 │    Auto-Lock nach 20 s, Aufwecken per Doppeltipp oder Handbewegung
 ├─ Automatische Pause bei v < 2 km/h für > 30 s (Schwelle konfigurierbar)
 └─ STOP (Bestätigung nötig, 2. Tap)
      └─ Verarbeitung on-device (Ziel < 8 s für 2 h Ride)
           └─ Post-Ride
```

#### Flow C — Setup ändern und belegen (Bracketing)

```
Garage → Bike → Setups → "Bracketing starten"
 │
 ├─ Parameter wählen (genau einer)          [z.B. Zugstufe Gabel]
 ├─ Bereich wählen                          [6 → 10 Klicks, Schritt 2]
 ├─ Referenzsegment wählen                  [Karte oder "Segment beim Fahren markieren"]
 ├─ Runde 1: Klicks auf 6 → 2 Durchgänge fahren
 │    App erkennt Segment-Wiederholung automatisch und zählt
 ├─ Runde 2: App fordert Verstellung auf → 2 Durchgänge
 ├─ Runde 3: …
 └─ Auswertung
      ├─ "Belegter Unterschied: 8 Klicks besser (Flow +7, Impacts −22 %)"
      └─ ODER "Kein belegbarer Unterschied — Streuung größer als Effekt"
           → gültiges Ergebnis, wird ebenso gespeichert
```

#### Flow D — Teil kaufen mit Kompatibilitätsprüfung

```
Auslöser: Wartungswarnung ODER Shop-Browsing ODER Komponenten-Detail
 │
 ├─ Produkt anzeigen → Engine prüft gegen aktives Bike
 │    ├─ COMPATIBLE        → grün, "Warum?" öffnet Begründungskette
 │    ├─ CONDITIONAL       → orange, Bedingung im Klartext + benötigter Adapter
 │    ├─ INCOMPATIBLE      → rot, verletzte Regel im Klartext
 │    └─ INSUFFICIENT_DATA → grau, "Uns fehlt: Freilauf-Standard deiner Nabe"
 │                            → CTA: Angabe ergänzen (dann sofortige Neuprüfung)
 └─ Kauf → nach Lieferung: "Verbaut?" → Komponententausch in Garage,
      alte Komponente wird archiviert, Laufleistung eingefroren
```

#### Flow E — Route planen und offline mitnehmen

```
Discover → Vorschlag ODER Planer
 ├─ Profil folgt automatisch dem aktiven Bike (überschreibbar)
 ├─ Wegpunkte setzen / Rundkurs mit Zielzeit oder -distanz
 ├─ Prüfung: Höhenprofil, Oberflächen-Band, Schwierigkeits-Band,
 │            Anteil ungetaggter Wege, bei E-Bike Reichweiten-Check
 ├─ Warnung bei gesperrten/unzulässigen Abschnitten (F-NAV-001.1)
 └─ "Offline mitnehmen" → Region + Route + Höhendaten laden (Größe wird vorab genannt)
```

#### Flow F — Fehlerpfad: Kalibrierung ungültig geworden

```
Nutzer tauscht Gabel in der Garage
 └─ System: Kalibrierung für dieses Bike wird invalidiert
      └─ Nächster Ride-Start: "Neue Gabel erkannt — Fahrwerksanalyse braucht
         eine neue Kalibrierung (45 s)."  [Jetzt / Später ohne Analyse]
```

---

## 4. Design-System und Screens

Der visuelle Rahmen ist im Briefing gesetzt (dunkles Grün-Schwarz, Orange-Akzent, hoher Kontrast) und wird exakt eingehalten. Innerhalb dieses Rahmens gibt es eine bewusste gestalterische Entscheidung, die das Produkt unverwechselbar macht — siehe 4.5, Setup-Fingerprint.

### 4.1 Farb-Token

Alle Werte sind Design-Token, keine Hardcodes. Kontrastwerte gegen `bg.base` in Klammern.

**Dark (Default)**

| Token | Hex | Verwendung |
|---|---|---|
| `bg.base` | `#060D0A` | App-Hintergrund, sehr dunkles Grün-Schwarz |
| `bg.surface` | `#0D1613` | Karten, Listenflächen |
| `bg.elevated` | `#16221E` | Sheets, Menüs, Dialoge |
| `bg.inset` | `#030807` | Eingabefelder, Diagrammflächen |
| `border.subtle` | `#1E2E29` | Trennlinien |
| `border.strong` | `#334741` | Fokus-Umrandungen, aktive Karten |
| `primary` | `#2D7A5F` | Deep Forest Green — Marke, Flächen, sekundäre Aktionen (3,8:1 — **nur für Flächen und UI-Elemente, nicht für Fließtext**) |
| `primary.hover` | `#35906F` | |
| `primary.pressed` | `#226249` | |
| `accent` | `#FF6B35` | Electric Trail Orange — primäre Aktion, Live-Zustand (6,9:1) |
| `accent.pressed` | `#E2551F` | |
| `text.primary` | `#F2F7F4` | (18,1:1) |
| `text.secondary` | `#A9BDB5` | (9,9:1) |
| `text.tertiary` | `#6E837C` | (4,9:1) — AA-konform, aber nur für Achsen- und Hilfsbeschriftung, nie für Fließtext im Ride-Screen |
| `text.onAccent` | `#0A1410` | Text auf Orange |
| `success` | `#3DDC97` | Kompatibel, im Zielbereich |
| `warning` | `#FFC857` | Bedingt, Wartung fällig |
| `danger` | `#FF4D4D` | Inkompatibel, außerhalb Herstellerbereich |
| `unknown` | `#7A8C86` | `INSUFFICIENT_DATA` — bewusst neutral, nicht rot |

**Regel (MUSS):** `accent` (Orange) bedeutet ausschließlich *aktive primäre Aktion* oder *laufende Aufzeichnung*. Es **DARF NICHT** als Warnfarbe verwendet werden — dafür existiert `warning`. Ohne diese Regel kollidieren „Los!" und „Achtung!" visuell.

**Datenvisualisierung** (nicht mit Semantikfarben mischen):
`viz.1 #5EC8D8` · `viz.2 #B08BE8` · `viz.3 #E8C15E` · `viz.4 #6FD98A` · `viz.5 #E87F9C` · `viz.6 #8FA3F0`

**Sunlight Mode** (hell, nur Ride-Screen, siehe 0.4.3)

| Token | Hex |
|---|---|
| `bg.base` | `#FFFFFF` |
| `bg.surface` | `#F1F4F2` |
| `text.primary` | `#05100C` (19,3:1) |
| `text.secondary` | `#3C4C46` |
| `accent` | `#B33F14` (5,8:1 — das helle `#FF6B35` erreicht auf Weiß nur 2,5:1 und ist unzulässig) |
| `primary` | `#14503A` |
| `border` | `#C9D6D0` |

**MUSS:** Beide Themes durchlaufen automatisierte Kontrastprüfung in CI. WCAG 2.2 AA (4,5:1 Text, 3:1 UI-Elemente) ist Mindeststandard; im Ride-Screen gilt AAA-Ziel (7:1) für alle Werte über 15 pt.

### 4.2 Typografie

**Inter Variable** wird auf beiden Plattformen mitgeliefert statt auf SF Pro / Roboto zurückzugreifen. Begründung: Ein Datenprodukt braucht identische Metriken auf beiden Plattformen, sonst brechen Zahlenkolonnen und Diagrammbeschriftungen unterschiedlich um. Für rohe Diagnose- und Klickwerte kommt **JetBrains Mono** zum Einsatz — begründet, weil Klickzahlen wie Instrumentenwerte gelesen werden und in Tabellen exakt untereinander stehen müssen.

**Alle Zahlen MÜSSEN mit `font-feature-settings: 'tnum' 1, 'cv05' 1` gesetzt werden** (Tabellenziffern, offenes „l"). Springende Ziffernbreiten in Live-Daten sind ein Blocker-Defekt.

| Rolle | Größe/Zeilenhöhe | Gewicht | Tracking |
|---|---|---|---|
| `data.xxl` | 64 / 60 | 700 | −2,0 % |
| `data.xl` | 44 / 44 | 700 | −1,5 % |
| `data.l` | 32 / 34 | 600 | −1,0 % |
| `display` | 34 / 40 | 700 | −1,5 % |
| `h1` | 28 / 34 | 700 | −1,0 % |
| `h2` | 22 / 28 | 600 | −0,5 % |
| `h3` | 18 / 24 | 600 | 0 |
| `body.l` | 17 / 24 | 400 | 0 |
| `body` | 15 / 22 | 400 | 0 |
| `label` | 13 / 16 | 600 | +4 % (Versalien) |
| `caption` | 13 / 18 | 400 | 0 |
| `mono` | 15 / 20 | 500 | 0 (JetBrains Mono) |

Dynamic Type / Schriftskalierung des Systems MUSS bis 200 % ohne Layoutbruch unterstützt werden; Live-Datenwerte skalieren dabei mit, aber nie über die verfügbare Kachelhöhe hinaus (dann Umbruch auf kompakteres Layout).

### 4.3 Raster, Form, Bewegung

- **Basisraster:** 4 dp. Abstände: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48 / 64.
- **Seitenrand:** 20 dp Standard, 16 dp bei Bildschirmbreite < 360 dp.
- **Radien:** 6 (Chips), 12 (Karten), 20 (Sheets), 999 (Pills). Keine gemischten Radien innerhalb einer Komponente.
- **Elevation im Dark Mode:** über Flächenstufen und 1-px-Ränder, **nicht** über Schatten — Schatten sind auf dunklem Grund praktisch unsichtbar und kosten nur Renderzeit. Im Sunlight Mode dagegen: `0 1px 2px rgba(0,0,0,.10)` / `0 4px 12px rgba(0,0,0,.12)`.
- **Bewegung:** 120 ms (Mikro), 220 ms (Standard), 360 ms (Sheet), Easing `cubic-bezier(.2,0,0,1)`. „Reduzierte Bewegung" MUSS respektiert werden. **Im Ride-Screen ist jede dekorative Animation deaktiviert** — es bewegen sich nur Werte und Karte.
- **Haptik:** Jeder Klick am Klick-Stepper löst eine leichte Impact-Haptik aus. Das ist die digitale Entsprechung des Rasterns am Dämpferrad und macht die Eingabe ohne Hinsehen kontrollierbar.

### 4.4 Outdoor-Regeln (verbindlich)

| Regel | Standard | Handschuh-Modus |
|---|---|---|
| Min. Touch-Target | 48 × 48 dp | **64 × 64 dp** |
| Min. Abstand zwischen Targets | 8 dp | **16 dp** |
| Min. Textgröße interaktiv | 15 pt | **17 pt** |
| Wischgesten | erlaubt | **durch Buttons ersetzt** (Handschuhe + Nässe machen Wischen unzuverlässig) |
| Long-Press als einzige Aktion | verboten | verboten |
| Bestätigung destruktiver Aktionen | ja | ja, mit vergrößertem Ziel |

**Einhandbedienung (MUSS):** Alle im Ride-Kontext benötigten Bedienelemente liegen im unteren Bildschirmdrittel. Der obere Bereich ist reine Anzeige. Der Halte-Daumen-Radius wird für beide Hände geprüft.

**Sunlight Mode (MUSS):** Aktivierung automatisch bei Umgebungshelligkeit > 8.000 lx über mehr als 4 s (Android: `TYPE_LIGHT`; iOS: kein direkter Zugriff auf den Umgebungslichtsensor → Ableitung über die vom System gesetzte Displayhelligkeit als Näherung, zusätzlich manueller Schalter). Wechsel mit 400-ms-Überblendung, nie hart. Im Sunlight Mode: alle Flächen weiß/hell, Linienstärken +1 px, Diagramme mit dickeren Linien und ohne Verläufe.

### 4.5 Signature-Komponente: Setup-Fingerprint

Die eine Komponente, an der man AetherRide wiedererkennt.

Der Setup-Fingerprint ist ein horizontaler, 12 dp hoher Streifen, der den kompletten Einstellzustand eines Bikes als Skalenband abbildet: pro einstellbarem Parameter ein schmaler Balken, dessen Marker auf der jeweiligen Skala zwischen „offen" und „zu" sitzt. Luftdrücke erscheinen als Füllstände, Klickpositionen als Rasterpunkte, Tokens als gezählte Segmente.

```
 Gabel   ├──●───────┤   ├████████░░┤   ├·····●··┤   ├◆◆◇┤
         Zugstufe       Druck 82 psi    LSC 5/12    2 Token
 Dämpfer ├────●─────┤   ├██████████┤   ├··●·····┤   ├◆◇◇┤
```

Warum das trägt:
- Es ist **funktional**: Zwei Setups lassen sich durch Übereinanderlegen zweier Fingerprints in einer Sekunde vergleichen — genau die Operation, die im Bracketing hunderte Male stattfindet.
- Es ist **subjektspezifisch**: Rasterpunkte, Füllstände und Tokens sind die tatsächliche Sprache der Fahrwerkseinstellung, nicht generische Balkendiagramme.
- Es **skaliert über die App**: klein in der Bike-Liste (Wiedererkennung), mittelgroß im Post-Ride („so warst du unterwegs"), groß im Bracketing-Vergleich (Diff-Ansicht mit hervorgehobenen Unterschieden).

Verwendungsregel (MUSS): Der Fingerprint ist immer klickbar und führt zum vollständigen Setup. Er **DARF NICHT** ohne Legende in einem Kontext auftauchen, in dem der Nutzer ihn zum ersten Mal sieht.

### 4.6 Komponentenbibliothek (Auszug)

| Komponente | Kernverhalten |
|---|---|
| `BikeChip` | Aktives Bike, Kopfzeile, tappbar → Bike-Wechsel-Sheet. Auf jedem Top-Level-Screen. |
| `ClickStepper` | −/+ Stepper für Klickwerte. 64 dp Ziele, Haptik pro Klick, Anzeige „6 von 14 (von offen)". Bei Erreichen des Herstellerlimits: harter Stopp + Erklärung. |
| `PressureField` | Numerisch, Einheit umschaltbar (psi/bar), Herstellerbereich als Skala darunter, Außerhalb-Markierung in `danger`. |
| `VerdictPill` | Vier Zustände aus F-GAR-003. Immer mit Textlabel, **nie nur Farbe** (Barrierefreiheit). |
| `EvidenceSheet` | Begründungskette: Regel, verglichene Werte, Quelle je Wert mit Datum. Von jedem Verdict und jeder Empfehlung erreichbar. |
| `MetricTile` | Live-Wert mit Label, Einheit, optional Sparkline. Drei Größen. Werte immer `tnum`. |
| `ConfidenceBadge` | hoch / mittel / niedrig, mit Tooltip „worauf beruht das?". Pflicht an jeder Schätzung. |
| `SetupFingerprint` | siehe 4.5, drei Größen, Diff-Modus. |
| `ElevationStrip` | Höhenprofil mit Steigungsfarbe, darunter Oberflächen- und Schwierigkeitsband. Datenlücken sichtbar. |
| `PermissionPrimer` | Vollbild-Erklärung vor jedem Systemdialog. |
| `EmptyState` | Immer mit genau einer Handlungsaufforderung. Kein Zierbild ohne Aussage. |

### 4.7 Screen-Spezifikationen

#### 4.7.1 Home

Zweck: In drei Sekunden beantworten — *Was ist mit meinem Bike, und was mache ich als Nächstes?*

```
┌──────────────────────────────────────┐
│ [🚲 Stumpjumper EVO ▾]        [◉]   │  BikeChip + Avatar
├──────────────────────────────────────┤
│  Guten Morgen, Jonas                 │  h2
│                                      │
│  ┌────────────────────────────────┐  │
│  │ HEUTE PASST                    │  │  label
│  │ Kaltenbronn Runde              │  │  h2
│  │ 34 km · 980 hm · 2:40 h        │  │  data.l, tnum
│  │ ▁▂▄▆█▆▄▂▁ Höhenprofil          │  │  ElevationStrip klein
│  │ Weil: S1–S2 Anteil hoch,       │  │  caption
│  │ trocken, passt in dein Fenster │  │
│  │              [Route ansehen →] │  │
│  └────────────────────────────────┘  │
│                                      │
│  DEIN BIKE                           │
│  ┌────────────────────────────────┐  │
│  │ Stumpjumper EVO   ●bereit      │  │
│  │ ├──●───┤ ├███████░┤ ├··●·┤     │  │  SetupFingerprint (S)
│  │ Setup „Trocken, verblockt"     │  │
│  │ seit 12 Tagen · 4 Rides        │  │
│  └────────────────────────────────┘  │
│                                      │
│  ⚠ Bremsbeläge hinten: 250–400 km   │  warning
│  💡 Eine offene Empfehlung           │  accent
├──────────────────────────────────────┤
│ Home  Garage  ●RIDE●  Discover  Shop │
└──────────────────────────────────────┘
```

**MUSS:** Maximal eine offene Empfehlung und maximal zwei Wartungshinweise. Alles darüber wandert in die jeweilige Sektion. Ein Dashboard, das alles zeigt, zeigt nichts.

#### 4.7.2 Garage — Bike-Detail

Vier Reiter: Übersicht · Komponenten · Setups · Wartung.

**Übersicht:** Schematisches SVG-Bike, Hotspots farbcodiert (gepflegt / Wartung fällig / Daten fehlen). Darunter Kennzahlen: Gesamtkilometer, Höhenmeter, Betriebsstunden, letzte Wartung, Anzahl Setups.
**Komponenten:** Gruppierte Liste nach Baugruppe. Jede Zeile: Slot, Modell, Laufleistung, Statuspunkt. Leere Slots erscheinen als eigene, klar unterscheidbare Zeile mit „Ergänzen" — ein leerer Slot ist eine Aufgabe, kein Fehler.
**Setups:** Aktuelles Setup groß mit Fingerprint, darunter Zeitstrahl der Versionen. Jede Version zeigt Änderungsdelta gegenüber der Vorgängerversion und, falls vorhanden, das Ergebnis der zugehörigen Rides.
**Wartung:** Fällige Aufgaben, dann Log als Zeitstrahl.

#### 4.7.3 Ride — Live

Drei horizontal wischbare Ebenen (im Handschuh-Modus zusätzlich über drei große Buttons erreichbar):

**Ebene 1 — Karte (Default):** Vollbildkarte, Nordung folgt Fahrtrichtung, Route in `accent`, unten eine 96 dp hohe Leiste mit drei Werten (Geschwindigkeit, Distanz, verbleibende Höhenmeter). Abbiegehinweis als Overlay oben, erscheint nur bei anstehendem Manöver.

**Ebene 2 — Daten:** 2 × 3 Kacheln, Werte frei konfigurierbar. Default: Geschwindigkeit (`data.xxl`), Distanz, Zeit, Höhenmeter, Ø-Geschwindigkeit, bei E-Bike: SOC und Restreichweite als Spanne.

**Ebene 3 — Fahrwerk:** Nur bei aktiver Analyse. Live-Federungsaktivität als 20-s-Verlaufsband, Impact-Zähler nach Härteklasse, FNI mit Konfidenz, Schräglage links/rechts als Spiegelbalken. Bei inaktiver Analyse zeigt die Ebene **nicht** leere Kacheln, sondern eine einzelne Erklärung mit Handlungsoption.

**MUSS:** Aufzeichnungszustand ist jederzeit ohne Lesen erkennbar — pulsierender `accent`-Punkt oben links, 1,4-s-Zyklus, plus dauerhafte System-Notification.
**MUSS:** Stopp erfordert zwei Interaktionen. Ein versehentlich beendeter Ride ist der schmerzhafteste vermeidbare Fehler dieser Produktklasse.

#### 4.7.4 Post-Ride

Reihenfolge ist bewusst: erst Fakten, dann Beobachtung, dann genau eine Handlung.

1. **Kopf:** Karte des Tracks, Distanz, Höhenmeter, Zeit, Bike + Setup-Fingerprint.
2. **Fahrwerk:** FNI-Verlauf über die Strecke, Impact-Histogramm, Federungsaktivität nach Abschnitt. Jede Kachel mit `ConfidenceBadge`.
3. **Segmente:** Erkannte Abschnitte mit Flow-Score und dessen vier Teilwerten.
4. **Feedback:** Drei Taps, wie F-SET-004.
5. **Empfehlung:** Genau eine Karte im Format aus F-AI-003, mit `EvidenceSheet`.

#### 4.7.5 Discover

Oben die Vorschlagskarten (an aktives Bike gebunden, Bike-Wechsel ändert die Liste sofort und sichtbar). Darunter Filter: Dauer, Höhenmeter, Schwierigkeit (`mtb:scale`/`sac_scale`), Oberfläche, Rundkurs ja/nein, Startpunkt. Jede Karte nennt drei Begründungsfaktoren. Route-Detail zeigt Profil, Bänder, Warnungen, Offline-Größe und — bei E-Bikes — die Reichweitenprognose als Spanne gegen die Routenanforderung.

#### 4.7.6 Shop

Erste Sektion immer „Für dein <Bikename>" mit bereits geprüften Produkten. Jede Produktkachel trägt die `VerdictPill`. Produkt-Detail: Urteil und Begründung **über** Bild und Preis — die Kompatibilitätsaussage ist hier die wichtigste Information, nicht das Marketing.

#### 4.7.7 KI-Profil

Kein Blackbox-Score. Der Screen zeigt die abgeleiteten Merkmale als lesbare Aussagen mit Datenbeleg und je einem Korrektur-Button:
> „Du bremst spät und kurz — 78. Perzentil deiner eigenen Historie. Basis: 42 Rides, 610 Kurven mit Bremsereignis." [Stimmt / Stimmt nicht]

Korrekturen fließen als gewichtete Beobachtungen in das Profil ein und sind im Änderungsprotokoll sichtbar.

---

## 5. Technische Architektur

### 5.1 Entscheidung Mobile: Flutter mit nativen Hot-Path-Modulen

Bewertet wurden drei Optionen. Gewichtung nach Projektrisiko, nicht nach Vorliebe.

| Kriterium | Gew. | Nativ (Swift+Kotlin) | Flutter + native Module | React Native |
|---|---|---|---|---|
| Screen-Durchsatz (die App hat ~40 Screens, davon ~30 reine CRUD/Listen) | 25 % | 2 | **5** | 4 |
| Hochfrequente Sensorik | 20 % | 5 | **4** (Modul ist ohnehin nativ) | 2 |
| BLE inkl. Hersteller-SDKs | 15 % | 5 | **4** (Platform Channel um natives SDK) | 3 |
| Offline-Karten + Offline-Routing (MapLibre GL Native, Valhalla via FFI) | 15 % | 5 | **4** | 2 |
| Hintergrundausführung, Batterie | 10 % | 5 | **4** | 2 |
| Teamgröße/Kosten bei 2 Mobile-Entwicklern | 10 % | 1 | **5** | 4 |
| Wearables (Phase 3, ohnehin nativ) | 5 % | 5 | 3 | 2 |
| **Gewichtete Summe** | | **3,70** | **4,35** | **3,00** |

**Entscheidung: Flutter (stable channel) für UI, Zustand und Geschäftslogik; native Module für alles Zeitkritische.**

Die tragende Begründung: Die zeitkritischen Teile müssen in *jedem* Szenario nativ geschrieben werden. Der Unterschied zwischen den Optionen liegt daher fast ausschließlich bei den ~30 CRUD-Screens — und dort gewinnt eine Codebasis deutlich. Der native Anteil beträgt geschätzt 15–20 % des Codes, trägt aber 80 % des technischen Risikos; dieser Anteil wird von den erfahrensten Entwicklern gebaut und separat getestet.

**Ausdrückliche Gegenanzeige (dokumentiert, damit die Entscheidung überprüfbar bleibt):** Verfügt das Team über je zwei erfahrene iOS- und Android-Entwickler *ohne* Flutter-Erfahrung, kehrt sich die Rechnung um. Die Entscheidung ist an Gate G-0 (Team-Setup) vor Sprint 1 zu bestätigen.

**Native Module (MUSS nativ):**

| Modul | iOS | Android |
|---|---|---|
| `sensor_core` | CoreMotion, Batch-Handler, Ringpuffer | `SensorManager` mit FIFO-Batching / `SensorDirectChannel` |
| `location_core` | CoreLocation, Significant-Change + Precise während Ride | FusedLocationProvider, Foreground Service mit `location`-Typ |
| `ble_core` | CoreBluetooth + Bosch-SDK-Wrapper | BluetoothLE + Bosch-SDK-Wrapper |
| `map_core` | MapLibre GL Native | MapLibre GL Native |
| `routing_core` | Valhalla via C++/FFI | Valhalla via C++/FFI (NDK) |
| `dsp_core` | Rust, geteilt über beide Plattformen (Filter, Fusion, Feature-Extraktion) | dito |

`dsp_core` in **Rust** ist eine bewusste Entscheidung: die Signalverarbeitung wird nur einmal geschrieben, ist einmal zu verifizieren und lässt sich auf dem Desktop gegen Referenzdaten testen — was bei der Validierungsstudie (7.5) unverzichtbar ist.

Datenübergabe Native → Dart erfolgt **ausschließlich blockweise** (1-s-Blöcke) über FFI mit gemeinsamem Speicher. Method Channels pro Sample sind untersagt.

### 5.2 Mobile Schichtung

```
┌──────────────────────────────────────────────────┐
│ Präsentation (Flutter Widgets, Design-Token)     │
├──────────────────────────────────────────────────┤
│ Zustand (Riverpod, unidirektional)               │
├──────────────────────────────────────────────────┤
│ Domäne (reines Dart: Setup-Regeln, Kompatibilität│
│         lokal, Empfehlungslogik, Einheiten)      │
├──────────────────────────────────────────────────┤
│ Repositories — Offline-First: lesen IMMER lokal  │
├──────────────────────────────────────────────────┤
│ Lokale Persistenz (Drift/SQLite) │ Sync-Engine   │
├──────────────────────────────────────────────────┤
│ Native Module (FFI / Platform Channels)          │
└──────────────────────────────────────────────────┘
```

**Offline-First-Regel (MUSS):** Kein Lesepfad in der UI geht jemals direkt ans Netz. Die UI liest ausschließlich aus der lokalen Datenbank; die Sync-Engine aktualisiert diese im Hintergrund. Ein Netzausfall ist damit kein Sonderfall im UI-Code, sondern unsichtbar.

### 5.3 Backend

Service-orientiert mit klar geschnittenen Bounded Contexts. **Bewusste Pragmatik:** Zum MVP werden die acht Kontexte in **vier** unabhängig deploybaren Einheiten ausgeliefert, nicht in acht. Grund: Bei erwarteten < 50k MAU im ersten Jahr erzeugt echte Feinkörnigkeit mehr Betriebsaufwand als Nutzen; die Kontextgrenzen bleiben im Code aber strikt (getrennte Schemata, keine Fremdschlüssel über Kontextgrenzen, Kommunikation nur über definierte Schnittstellen), sodass ein späteres Herauslösen ein Deployment-Schritt ist und kein Refactoring.

| Kontext | Verantwortung | MVP-Deployment |
|---|---|---|
| `identity` | Konten, Sessions, Einwilligungen, DSGVO-Prozesse | Einheit A |
| `garage` | Bikes, Komponenten, Setups, Wartung, Kompatibilitätsprüfung | Einheit A |
| `catalog` | Komponentenmodelle, Kompatibilitätsregeln, Produkte (leseintensiv, aggressiv gecacht) | Einheit A |
| `ride` | Ride-Ingest, Verarbeitung, Kennwerte, Segmente, Bracketing-Auswertung | Einheit B |
| `route` | Valhalla, Kachel-Auslieferung, Routenvorschläge, Heatmap-Aggregation | Einheit C |
| `intelligence` | Empfehlungs-Engine, LLM-Orchestrierung, Numeric-Guard, Rider-Profil | Einheit D |
| `commerce` | Katalog-Bestand, Bestellungen, Zahlungen (Phase 3) | ab Phase 3 |
| `notify` | Push, E-Mail, Erinnerungen | Einheit A |

**Technologien:**

| Belang | Wahl | Begründung |
|---|---|---|
| Sprache Backend | Kotlin (JVM) oder Go — **eine** davon, projektweit | Beide belastbar; Entscheidung an Team-Erfahrung, Gate G-0. Keine Mischsprachigkeit. |
| Primärdatenbank | PostgreSQL 16 | Relationale Integrität ist bei Kompatibilitätsregeln nicht verhandelbar |
| Zeitreihen | TimescaleDB-Hypertables für Ride-Kennwerte | Kompression und Zeitfenster-Aggregate |
| Rohsensordaten | S3-kompatibler Objektspeicher, EU-Region | Blobs gehören nicht in die Datenbank |
| Vektoren | `pgvector` in derselben Postgres-Instanz | Eine Datenbank weniger zu betreiben; Volumen rechtfertigt keine dedizierte Vektor-DB |
| Cache | Redis | Sessions, Katalog, Ratenbegrenzung |
| Ereignisse/Queue | MVP: Postgres-basierte Queue. Phase 2: Kafka-kompatibel | Kafka zum Start ist Overhead ohne Nutzen |
| Kartenkacheln | Planetiler → PMTiles auf Objektspeicher + CDN | Serverloses Ausliefern, gleiche Artefakte online wie offline |
| Routing | Valhalla, server- **und** clientseitig | Identische Ergebnisse online/offline |
| Observability | OpenTelemetry, Prometheus, Grafana, Sentry | |
| Hosting | EU-Region (Frankfurt), Auftragsverarbeitung vertraglich geregelt | DSGVO, siehe 7.7 |

**API:** REST/JSON nach OpenAPI 3.1 für Client-Verkehr, gRPC intern, WebSocket nur für Live-Sitzungen (Live-Tracking, Phase 2). Versionierung über URL-Präfix `/v1`. **MUSS:** Rückwärtskompatibilität für mindestens zwölf Monate — Nutzer aktualisieren Outdoor-Apps notorisch spät.

### 5.4 Warum Valhalla und nicht GraphHopper oder OSRM

| Anforderung | Valhalla | GraphHopper | OSRM |
|---|---|---|---|
| Offline auf dem Gerät (kachelbasiert, teilweise Regionen) | **ja, Kerndesign** | eingeschränkt | nein (benötigt Vollgraph im RAM) |
| Kosten pro Profil zur Laufzeit änderbar (dynamic costing) | **ja** | teilweise | nein (Vorberechnung) |
| Identische Engine Client und Server | **ja** | teilweise | nein |
| Sieben eigene Profile mit Zugriff auf `mtb:scale` etc. | **ja, über Costing-Erweiterung** | ja | schwierig |

Die Anforderung „Offline-Routing **und** identisches Online-Ergebnis **und** sieben eigene Profile" wird nur von Valhalla vollständig erfüllt. Das ist der Grund für die Wahl, nicht Performance.

### 5.5 Sensor-zu-Erkenntnis-Pfad (Systemsicht)

```
Sensor-HW ─200Hz─► natives sensor_core (Ringpuffer, Zeitstempelkorrektur)
                        │
                        ├─► dsp_core (Rust)
                        │     ├─ Kalibrierungstransformation ins Bike-System
                        │     ├─ Orientierungsfusion (Plattform-AHRS + eigene Plausibilisierung)
                        │     ├─ Filterbank (HP 0,5 Hz, Bänder 1–8 / 2–12 / >15 Hz)
                        │     ├─ Ereignisdetektoren (Impact, Durchschlagsverdacht, Airtime, Bremsen)
                        │     └─ Fenster-Features (2 s, 50 % Überlappung)
                        │            │
                        │            ├─► Live-Metriken ──► Ride-UI
                        │            └─► On-Device-Modell (TFLite/Core ML)
                        │                   Terrainklassifikation, Fahrsituation
                        │
                        └─► Chunk-Writer (int16-Delta, zstd, 60 s) ──► lokaler Speicher
                                                                          │
                        Ride-Ende ──► lokale Verarbeitung (< 8 s / 2 h) ──┤
                                                                          │
                                         Kennwerte + Ereignisse ──────────┴──► Upload (WLAN)
                                                                                  │
                                                            Rohdaten nur bei Opt-in ┘
```

**MUSS:** Alle Live-Metriken entstehen auf dem Gerät. Es gibt keinen Live-Metrik-Pfad, der Netz benötigt.

### 5.6 Offline-Sync-Protokoll

Der Konflikt-Raum wird durch Datenmodellierung minimiert, nicht durch clevere Merge-Algorithmen.

| Entität | Eigentümer | Konfliktstrategie |
|---|---|---|
| `Setup` | unveränderlich | **Keine Konflikte möglich.** Jede Änderung ist eine neue Version. |
| `Ride`, `SensorSession` | Client | Nach Finalisierung unveränderlich; Server nimmt an, korrigiert nie |
| `MaintenanceLog` | Client | Nur Anfügen |
| `Bike`, `BikeComponent` | geteilt | Feldweises Last-Write-Wins mit Server-Zeitstempel; bei echtem Konflikt zweier Geräte innerhalb von 5 s: Nutzerabfrage |
| `Product`, `ComponentModel`, `CompatibilityRule` | Server | Nur lesen auf dem Client |
| `RiderProfile` | Server | Server rechnet, Client zeigt an |

**Mechanik (MUSS):**
- IDs werden **auf dem Client** als UUIDv7 erzeugt. Offline-Anlage ist damit ohne Serverkontakt möglich und die Sortierreihenfolge bleibt zeitlich.
- Jede Mutation landet in einem lokalen, geordneten Operations-Log mit `operation_id`. Der Server ist idempotent gegenüber `operation_id` (Wiederholung nach Verbindungsabbruch verändert nichts).
- Delta-Sync über Cursor `since=<server_revision>`.
- Auslieferung des Operations-Logs bei Netzverfügbarkeit, mit exponentiellem Backoff; das Log überlebt App-Neustarts und Betriebssystem-Kills.
- **Zielwert:** Konfliktrate < 0,1 % der Mutationen; jede Nutzerabfrage wegen Konflikts wird als Defekt der Modellierung untersucht.

### 5.7 Nicht-funktionale Anforderungen (messbar)

| ID | Anforderung | Zielwert | Messmethode |
|---|---|---|---|
| NFR-01 | Kaltstart bis interaktiv | ≤ 2,0 s p95 (Referenzgeräte) | Firebase Performance / eigene Traces |
| NFR-02 | Ride-Screen Bildrate mit Karte + Sensorik + BLE | ≥ 58 fps p95, keine Frames > 32 ms | Instrumentierter Dauertest 2 h |
| NFR-03 | Akkuverbrauch, Display aus, Navigation + Sensorik 200 Hz + BLE | ≤ 9 %/h | Laborzyklus, 3 Wiederholungen |
| NFR-04 | Akkuverbrauch, Display an, 50 % Helligkeit | ≤ 22 %/h | dito |
| NFR-05 | Sample-Verlust Sensorik | < 0,5 % über 2 h | Zeitstempel-Lückenanalyse |
| NFR-06 | Post-Ride-Verarbeitung, 2-h-Ride | < 8 s | Referenzgeräte |
| NFR-07 | Speicherbedarf Rohdaten | ≤ 4 MB/h | Messung |
| NFR-08 | Offline-Region 10.000 km² inkl. Routing + Höhe | ≤ 350 MB | Messung |
| NFR-09 | API-Antwortzeit p95 | < 300 ms (Katalog < 120 ms) | APM |
| NFR-10 | Absturzfreie Sitzungen | ≥ 99,7 % | Sentry |
| NFR-11 | Ride-Datenverlust bei App-Kill oder Absturz | ≤ 60 s | Chaos-Test: Prozess-Kill während Aufzeichnung |
| NFR-12 | Barrierefreiheit | WCAG 2.2 AA vollständig, Screenreader-Bedienbarkeit aller Kern-Flows | manuelle Audits + `flutter_test` Semantics |
| NFR-13 | Schriftskalierung | bis 200 % ohne Layoutbruch | Snapshot-Tests |
| NFR-14 | Sync-Konflikte | < 0,1 % der Mutationen | Backend-Metrik |
| NFR-15 | Kaltstart in Offline-Region ohne Netz | volle Funktion außer Shop/KI | Flugmodus-Regression |

**Batterie-Maßnahmen (MUSS umgesetzt):** Sensor-FIFO-Batching statt Einzel-Callbacks; GNSS auf 1 Hz mit adaptiver Genauigkeit; Kartenrendering bei Displaysperre angehalten; kein Netzverkehr während der Fahrt außer bei aktivem Live-Tracking; BLE-Verbindungsintervall auf Motorseite maximal zulässig; Wake-Locks ausschließlich im Foreground Service; Verarbeitung in Blöcken statt kontinuierlich.

---

## 6. Datenmodelle

Schreibweise: `PK` Primärschlüssel, `FK` Fremdschlüssel, `NN` not null, `UQ` eindeutig. Alle IDs sind UUIDv7. Alle Zeitstempel sind `timestamptz` in UTC. Alle physikalischen Größen werden in **SI-Basiseinheiten** gespeichert und erst in der Darstellung umgerechnet — das ist keine Stilfrage, sondern die einzige Absicherung gegen psi/bar- und mm/inch-Fehler.

### 6.1 Übersicht der Beziehungen

```
User 1─────n Bike 1─────n BikeComponent n─────1 ComponentModel n──1 ComponentCategory
 │            │                                        │
 │            ├──n Setup 1──n SetupValue               ├──n ComponentAttribute (typisiert)
 │            │      │                                 └──n ProductVariant n──1 Product
 │            │      └──1 BracketingSeries 1──n BracketingRun
 │            ├──n MaintenanceTask / MaintenanceLog
 │            └──n Ride
 │                   ├──1 SensorSession 1──n SensorChunk (Objektspeicher)
 │                   ├──n RideSegment
 │                   ├──1 RideMetrics
 │                   └──n RideEvent
 ├──1 RiderProfile
 ├──n Recommendation ──► (Ride | Setup | Product | Route)
 ├──n ConsentRecord
 ├──n Device
 └──n Route

CompatibilityRule n──n ComponentCategory   (Regeln wirken zwischen Kategorien)
CompatibilityCheck ──► (BikeComponent | ComponentModel) × Ergebnis + Beleg
```

### 6.2 Kernentitäten

**DM-01 `user`**

| Feld | Typ | Constraints |
|---|---|---|
| `id` | uuid | PK |
| `email` | citext | UQ, NN (bei Konto) |
| `auth_provider` | enum(`email`,`apple`,`google`) | NN |
| `display_name` | text | |
| `locale`, `unit_system` | text, enum(`metric`,`imperial`) | NN |
| `rider_weight_kg` | numeric(5,2) | für SAG/Reichweite; Gesundheitsbezug → Art. 9 DSGVO beachten |
| `created_at`, `deleted_at` | timestamptz | Soft-Delete mit Hard-Delete-Job nach 30 Tagen |

**DM-02 `bike`**

| Feld | Typ | Bemerkung |
|---|---|---|
| `id`, `user_id` | uuid | PK, FK |
| `name` | text NN | |
| `category` | enum(`mtb_trail`,`mtb_am`,`mtb_enduro`,`dh`,`gravel`,`road`,`urban`,`emtb`,`etrekking`) | NN |
| `catalog_bike_id` | uuid | FK → `catalog_bike`, nullable bei Eigenanlage |
| `model_year` | int | |
| `travel_front_mm`, `travel_rear_mm` | int | |
| `wheel_size_front`, `wheel_size_rear` | enum(`27_5`,`29`,`700c`,`650b`) | Mullet wird explizit unterstützt |
| `total_weight_kg` | numeric(5,2) | für Reichweitenmodell |
| `is_active` | bool | genau eines je Nutzer, per partiellem UQ-Index erzwungen |
| `is_ebike` | bool | abgeleitet, materialisiert |
| `revision`, `updated_at` | int, timestamptz | Sync |

**DM-03 `component_model`** (Katalog, serverseitig)

| Feld | Typ | Bemerkung |
|---|---|---|
| `id` | uuid PK | |
| `category_id` | FK → `component_category` | z. B. `fork`, `rear_shock`, `cassette` |
| `manufacturer`, `model`, `variant`, `model_year` | text/int | UQ zusammengesetzt |
| `weight_g` | int | |
| `adjusters` | jsonb | Definition der einstellbaren Parameter (siehe unten) |
| `source`, `source_url`, `verified_at`, `verified_by` | text/timestamptz | **NN** — Provenienz ist Pflicht |
| `confidence` | enum(`oem`,`manufacturer_doc`,`editorial`,`community`) | NN |

`adjusters`-Beispiel für eine Gabel:
```json
{
  "air_pressure":  {"unit":"kPa","min":275,"max":827,"step":6.9},
  "rebound":       {"type":"clicks","total":18,"reference":"from_closed"},
  "lsc":           {"type":"clicks","total":12,"reference":"from_closed"},
  "hsc":           {"type":"clicks","total":5,"reference":"from_closed"},
  "tokens":        {"type":"count","min":0,"max":4},
  "travel_mm":     {"values":[140,150,160,170]}
}
```
Dieses Schema ist der Grund, warum die Setup-UI generisch gebaut werden kann: Die App weiß aus dem Katalog, welche Regler eine Komponente überhaupt besitzt und in welchen Grenzen.

**DM-04 `component_attribute`** — typisierte Schnittstellenmerkmale, Grundlage der Kompatibilitätsprüfung

| Feld | Typ |
|---|---|
| `component_model_id` | FK NN |
| `key` | text NN (z. B. `freehub_standard`, `rear_spacing`, `steerer_type`, `brake_mount`, `bb_standard`, `seatpost_diameter_mm`, `eye_to_eye_mm`, `stroke_mm`, `internal_rim_width_mm`) |
| `value_text` / `value_num` / `value_enum` | je nach Typ |
| `source`, `verified_at` | NN |
| UQ | (`component_model_id`, `key`) |

**MUSS:** Ein fehlender Eintrag bedeutet „unbekannt", **nicht** „nicht zutreffend". Für „nicht zutreffend" existiert der explizite Wert `n/a`. Diese Unterscheidung ist die Voraussetzung für `INSUFFICIENT_DATA`.

**DM-05 `bike_component`**

| Feld | Typ | Bemerkung |
|---|---|---|
| `id`, `bike_id` | uuid | |
| `slot` | enum(60 Werte) NN | z. B. `fork`, `rear_shock`, `tire_front` |
| `component_model_id` | uuid | nullable |
| `free_text` | text | nur wenn kein Katalogbezug; sperrt Kompatibilität und Setup-Automatik |
| `installed_at`, `removed_at` | timestamptz | Historie |
| `serial_number` | text | für Garantie/Diebstahl |
| `odometer_km_at_install`, `hours_at_install` | numeric | Basis der Laufleistung |
| UQ | (`bike_id`,`slot`) **where** `removed_at is null` |

**DM-06 `setup`** — unveränderlich

| Feld | Typ |
|---|---|
| `id`, `bike_id` | uuid |
| `version` | int NN, monoton je Bike |
| `parent_setup_id` | uuid, nullable |
| `label`, `conditions` | text, enum(`dry`,`wet`,`mixed`,`bikepark`,`race`) |
| `rider_weight_kg`, `gear_weight_kg` | numeric — Setups sind ohne Fahrergewicht nicht interpretierbar |
| `created_at`, `created_by` | timestamptz, enum(`user`,`template`,`recommendation`) |
| `is_current` | bool, genau eines je Bike |

**DM-07 `setup_value`**

| Feld | Typ |
|---|---|
| `setup_id`, `bike_component_id` | FK NN |
| `adjuster_key` | text NN (Schlüssel aus `component_model.adjusters`) |
| `value_num` | numeric NN, **SI-Einheit** |
| `unit` | text NN |
| `out_of_spec` | bool — außerhalb des Herstellerbereichs erfasst |
| UQ | (`setup_id`,`bike_component_id`,`adjuster_key`) |

**DM-08 `ride`**

| Feld | Typ |
|---|---|
| `id`, `user_id`, `bike_id`, `setup_id` | uuid — `setup_id` bindet den Ride an den exakten Einstellzustand |
| `activity_type` | enum(`mtb`,`enduro`,`gravel`,`road`,`emtb`,`hike`) |
| `started_at`, `ended_at`, `moving_seconds` | |
| `distance_m`, `ascent_m`, `descent_m` | numeric |
| `track` | `geography(LineString,4326)` — PostGIS, vereinfacht (Douglas-Peucker 2 m) |
| `track_raw_key` | text → Objektspeicher |
| `privacy_trimmed` | bool — Track wurde wegen Privatsphärenzone gekappt |
| `weather_snapshot` | jsonb |
| `finalized_at` | timestamptz — danach unveränderlich |

**DM-09 `sensor_session`**

| Feld | Typ |
|---|---|
| `id`, `ride_id` | uuid |
| `mount_mode` | enum(`handlebar`,`stem`,`pocket`,`backpack`,`body`,`unknown`) NN |
| `mount_confirmed_by_user` | bool NN |
| `calibration_id` | FK, nullable |
| `sample_rate_hz` | jsonb je Sensor |
| `clip_events` | int — Sättigungen des Beschleunigungssensors |
| `quality_score` | numeric 0–1 |
| `suspension_analysis_available` | bool — **abgeleitet und gespeichert**, damit später nachvollziehbar bleibt, warum Metriken fehlen |

**DM-10 `sensor_chunk`** (Metadaten in Postgres, Nutzlast im Objektspeicher)
`id`, `sensor_session_id`, `seq`, `t_start`, `t_end`, `object_key`, `bytes`, `codec` (`zstd`), `encoding` (`int16_delta`), `checksum`.

**DM-11 `ride_metrics`** (TimescaleDB-Hypertable, 1-s-Auflösung)
`ride_id`, `t`, `speed_mps`, `altitude_m`, `grade_pct`, `heading_deg`, `lean_deg`, `accel_rms_1_8hz`, `jerk_rms_2_12hz`, `fni`, `fni_confidence`, `power_w`, `cadence_rpm`, `hr_bpm`, `soc_pct`, `motor_power_w`.

**DM-12 `ride_event`**
`id`, `ride_id`, `t`, `type` (enum `impact_light|impact_medium|impact_hard|bottom_out_suspected|airtime|hard_brake|crash_suspected`), `magnitude`, `confidence`, `geom`.

**DM-13 `ride_segment`**
`id`, `ride_id`, `segment_ref_id` (nullable, für wiederkehrende Referenzsegmente), `t_start`, `t_end`, `terrain_class`, `flow_score`, `flow_sub_speed`, `flow_sub_smooth`, `flow_sub_brake`, `flow_sub_line`, `match_quality` (Geometrieübereinstimmung 0–1, für Bracketing entscheidend).

**DM-14 `compatibility_rule`** — siehe Syntax in 6.6
`id`, `code` (UQ, z. B. `RL-DRV-011`), `category_a`, `category_b`, `predicate` (jsonb), `verdict_on_pass`, `verdict_on_fail`, `condition_text_i18n`, `severity` (`safety_critical`|`functional`|`fitment`), `source_url`, `effective_from`, `version`, `author`, `reviewed_by`, `reviewed_at`.

**MUSS:** `reviewed_by` und `reviewed_at` sind Pflicht für alle Regeln mit `severity = safety_critical`. Eine solche Regel geht **nicht** ohne Zweitprüfung in Produktion.

**DM-15 `compatibility_check`** (Prüfprotokoll, für Nachvollziehbarkeit und Haftung)
`id`, `user_id`, `bike_id`, `candidate_component_model_id`, `verdict`, `evidence` (jsonb: Liste aus Regel-ID, verglichene Werte, Attributquellen), `rules_version`, `checked_at`.

**DM-16 `product` / `product_variant`**
`product`: `id`, `component_model_id` (nullable — Zubehör ohne Bike-Bezug), `title`, `brand`, `description_i18n`, `images`, `category_id`, `gpsr_manufacturer_info` (jsonb, EU-Pflicht), `status`.
`product_variant`: `id`, `product_id`, `sku` UQ, `attributes` (jsonb: Größe, Farbe, Länge), `price_cents`, `currency`, `vat_rate`, `stock_state`, `merchant_id`, `affiliate_url`, `lead_time_days`.

**DM-17 `recommendation`**
`id`, `user_id`, `type` (`setup`|`route`|`product`|`maintenance`|`technique`), `subject_ref` (polymorph), `payload` (jsonb — **die verbindlichen Zahlenwerte**), `evidence` (jsonb — auslösende Datenpunkte mit Ride-/Setup-Referenz), `confidence`, `engine_version`, `created_at`, `state` (`open`|`accepted`|`rejected`|`expired`), `user_feedback`.

**MUSS:** `payload` und `evidence` werden von den deterministischen Engines geschrieben, **nie** von einem Sprachmodell. Der generierte Text steht in einem separaten Feld `rendered_text` und ist jederzeit verwerfbar und neu erzeugbar.

**DM-18 `consent_record`**
`id`, `user_id`, `purpose` (enum: `raw_sensor_upload`, `heatmap_contribution`, `product_recommendations`, `analytics`, `health_data_processing`), `granted`, `granted_at`, `revoked_at`, `policy_version`, `ui_context` — jede Einwilligung ist einzeln nachweisbar (Art. 7 Abs. 1 DSGVO).

### 6.3 Indizes und Aufbewahrung (Auszug)

- `ride(user_id, started_at desc)`, `ride_metrics` Hypertable partitioniert nach Woche, Kompression nach 7 Tagen.
- `bike_component(bike_id) where removed_at is null` — der heiße Pfad der Garage.
- GIN auf `component_attribute(key, value_enum)` — Kompatibilitätsabfragen.
- Aufbewahrung: `ride_metrics` unbegrenzt (Nutzerdaten), `sensor_chunk` 30 Tage lokal / serverseitig nur bei Opt-in und dann 24 Monate, `compatibility_check` 24 Monate (Nachweiszweck), Logs 90 Tage.

### 6.4 Einheiten-Disziplin (MUSS)

| Größe | Speicherung | Anzeige |
|---|---|---|
| Druck | Pascal | psi oder bar |
| Länge | Meter | m / km / mm / inch |
| Masse | Kilogramm | kg / lb |
| Geschwindigkeit | m/s | km/h / mph |
| Energie | Joule | Wh |
| Winkel | Grad | Grad |
| Klicks | dimensionslose Ganzzahl **von geschlossen** | „6 von 18 (von zu)" |

Die Klick-Referenz ist der klassischste Fehler dieser Domäne: Hersteller zählen teils von offen, teils von geschlossen. **MUSS:** Gespeichert wird immer *von geschlossen*; die Anzeige folgt der Herstellerkonvention aus dem Katalog und nennt sie explizit.

### 6.5 Beispiel: die Datenkette einer Empfehlung

```
setup(v7).setup_value[fork.rebound] = 6 Klicks (von zu)
  + ride(2026-08-02).sensor_session.mount_mode = handlebar, kalibriert
  + calibration.zeta_front = 0.21
  + ride_event: 14 × impact_hard über 3,2 km Abfahrt
  + ride_feedback: front_feel = "zu rau"
  + component_model(FOX 38 Performance Elite).adjusters.rebound.total = 18
       ↓ deterministische Setup-Engine
recommendation.payload = {"adjuster":"fork.rebound","from":6,"to":8,
                          "unit":"clicks","bounds":[0,18]}
recommendation.evidence = [calibration:…, events:…, feedback:…]
       ↓ LLM formuliert, Numeric-Guard prüft {6,8,0,18,0.21,14,3.2}
rendered_text = "Zugstufe Gabel: 2 Klicks langsamer …"
```

### 6.6 Syntax der Kompatibilitätsregeln

Deklarativ, versioniert, prüfbar, ohne Turing-Vollständigkeit — bewusst, damit jede Regel statisch analysierbar und testbar bleibt.

```yaml
code: RL-DRV-011
title: Kassette benötigt passenden Freilaufkörper
severity: functional
categories: [cassette, rear_hub]
requires:
  - cassette.freehub_standard
  - rear_hub.freehub_standard
predicate:
  equals: [cassette.freehub_standard, rear_hub.freehub_standard]
on_pass: COMPATIBLE
on_fail: INCOMPATIBLE
explain_fail_de: >
  Die Kassette benötigt {cassette.freehub_standard}, deine Nabe hat
  {rear_hub.freehub_standard}. Ein Freilaufkörper-Tausch ist bei manchen Naben
  möglich – prüfe die Herstellerangabe deiner Nabe.
source_url: https://…
reviewed_by: "M. Braun"
reviewed_at: 2026-05-14
```

```yaml
code: RL-WHL-005
title: Reifenbreite zur Maulweite
severity: safety_critical
categories: [tire, rim]
requires: [tire.etrto_width_mm, rim.internal_width_mm]
predicate:
  and:
    - gte: [tire.etrto_width_mm, {mul: [rim.internal_width_mm, 1.4]}]
    - lte: [tire.etrto_width_mm, {mul: [rim.internal_width_mm, 3.0]}]
on_pass: CONDITIONAL          # bewusst nicht COMPATIBLE
on_fail: INCOMPATIBLE
condition_text_de: >
  Rechnerisch im üblichen Bereich. Verbindlich ist die Freigabe des
  Felgen- und des Reifenherstellers – prüfe beide.
source_url: https://…
reviewed_by: "M. Braun"
```

**Regel-Prinzipien (MUSS):**
1. Fehlt ein Wert aus `requires`, ist das Ergebnis `INSUFFICIENT_DATA` — das Prädikat wird gar nicht erst ausgewertet.
2. Rechnerische Näherungen ergeben höchstens `CONDITIONAL`, nie `COMPATIBLE`.
3. Jede Regel hat mindestens drei Testfälle (pass, fail, insufficient) im Regressionsset. Regeln ohne Tests werden vom Build abgelehnt.
4. Regelsatzversion wird in jeder `compatibility_check` protokolliert, damit vergangene Urteile reproduzierbar bleiben.

---

## 7. KI- und Sensor-Pipeline

### 7.1 Verarbeitungskette im Detail

| Stufe | Verarbeitung | Ort |
|---|---|---|
| S1 | Zeitstempel-Normalisierung, Ausreißerentfernung, Erkennung von Sensorsättigung | nativ |
| S2 | Transformation Gerätesystem → Bike-System mit dem Kalibrierungs-Quaternion | `dsp_core` |
| S3 | Orientierungsfusion: plattformseitige AHRS (iOS `CMDeviceMotion`, Android `TYPE_ROTATION_VECTOR`) als Basis, eigene Plausibilisierung gegen GNSS-Kurs und Gierrate | `dsp_core` |
| S4 | Filterbank: Hochpass 0,5 Hz (Drift), Bandpass 1–8 Hz (gefederte Masse), 2–12 Hz (Ruck/Laufruhe), Hochpass 15 Hz (Untergrundtextur) | `dsp_core` |
| S5 | Ereignisdetektion (Impact, Durchschlagsverdacht, Airtime, Bremsen, Sturzverdacht) | `dsp_core` |
| S6 | Fenster-Features, 2 s mit 50 % Überlappung: RMS je Band, Kurtosis, Spektralschwerpunkt, Nulldurchgangsrate, Perzentile | `dsp_core` |
| S7 | On-Device-Klassifikation: Terrainklasse und Fahrsituation | TFLite / Core ML |
| S8 | Aggregation zu Ride- und Segmentkennwerten | Dart |
| S9 | Setup-Empfehlung (regelbasiert) | Dart lokal, Server für Cross-Ride-Muster |
| S10 | Sprachliche Formulierung | Cloud-LLM, streng gegroundet |

### 7.2 Kalibrierung — Mathematik

**Ausrichtung.** Aus dem Mittelwert des Beschleunigungsvektors im Stillstand ergibt sich die Gravitationsrichtung `g_dev` im Gerätesystem. Mit der bekannten Soll-Richtung im Bike-System `g_bike = (0,0,−1)` folgt die Rotation
`q_mount = Rotation(g_dev → g_bike)`, ergänzt um den Gierwinkel aus dem GNSS-Kurs der ersten 30 s Fahrt (Rotation um die Gravitationsachse ist aus dem Stillstand allein nicht bestimmbar — dieser Umstand MUSS im Code kommentiert und im Test abgedeckt sein).

**Federungs-Antwortmessung.** Bei der Kompressions-Freigabe schwingt die Front als gedämpftes Feder-Masse-System aus. Aus den Amplituden aufeinanderfolgender Maxima `x₀ … xₙ` folgt das logarithmische Dekrement und daraus das Dämpfungsmaß:

```
δ = (1/n) · ln(x₀ / xₙ)
ζ = δ / √(4π² + δ²)
f_n = f_d / √(1 − ζ²)
```

Das ist eine direkte, physikalisch belastbare Messung — keine Schätzung. Sie ist die belastbarste Größe der gesamten Sensorik und deshalb der Anker der Zugstufen-Empfehlung.

**MUSS:** Die Messung wird dreimal wiederholt; die Streuung von `ζ` über die Wiederholungen bestimmt die Konfidenz. Bei Variationskoeffizient > 20 % wird die Messung verworfen und wiederholt.

**Wichtige Einschränkung, die dokumentiert und in der UI benannt wird:** Die Messung erfasst das Verhalten um den statischen Arbeitspunkt bei geringer Schaftgeschwindigkeit. Sie beschreibt damit primär die **Low-Speed-Zugstufe**. Aussagen zur High-Speed-Druckstufe lassen sich daraus **nicht** ableiten und werden **nicht** getroffen.

### 7.3 Metriken — Definitionen

**Schräglage.** Der naheliegende Weg (Neigung des Geräts gegen die Gravitationsrichtung) ist falsch: In der Kurve zeigt der gemessene Beschleunigungsvektor die Resultierende aus Erdbeschleunigung und Zentrifugalbeschleunigung und liegt nahezu senkrecht zur Bike-Ebene — die gemessene „Neigung" geht daher gegen null, während die reale Schräglage groß ist. Verwendet wird stattdessen:

```
θ_lean = atan( v · ω_yaw / g )
```

mit `v` aus GNSS (geglättet, 1 Hz, interpoliert) und `ω_yaw` aus dem Gyroskop um die Bike-Hochachse. Gültig ab 8 km/h; darunter wird kein Wert ausgegeben. Plausibilitätsprüfung gegen die fusionierte Lage; Abweichung > 15° ⇒ Konfidenz `niedrig`.

**Impact-Klassifikation.** Ereignis, wenn `|a_z|` einen adaptiven Schwellwert (Median + 6 × MAD des laufenden 30-s-Fensters) überschreitet **und** der Ruck `|da/dt|` über 400 g/s liegt. Klassifikation über das Integral der Beschleunigung über dem Schwellwert: leicht / mittel / hart, kalibriert je Bike-Kategorie. Sättigungsereignisse werden gesondert gezählt und senken die Konfidenz des gesamten Abschnitts.

**FNI.** Vertikalbeschleunigung → Hochpass 0,5 Hz → zweifache Integration innerhalb 2-s-Fenstern mit Nullphasen-Filterung → relative Vertikalauslenkung `Δz(t)`. Der FNI ist das 95. Perzentil von `|Δz|` je Fenster, normiert auf die 99. Perzentil-Verteilung desselben Bikes über die letzten 20 Rides.

**Ausdrücklich (MUSS):** Der FNI ist ein relativer Index. Er **DARF NICHT** in Millimeter oder Prozent des Federwegs übersetzt werden. In der UI erscheint er als Index mit Bezugstext („hoch für dieses Bike"), begleitet von `ConfidenceBadge`.

**Durchschlagsverdacht.** Nicht aus dem FNI abgeleitet, sondern eigener Detektor: sehr steilflankige Verzögerungsspitze (Anstiegszeit < 10 ms) mit anschließendem charakteristischem Nachschwingen. Ausgabe stets als *Verdacht* mit Konfidenz, nie als Feststellung.

**Flow-Score.** Formel und Teilwerte wie F-SEN-004. Terrainnormierung: Jeder Teilwert wird gegen die Verteilung derselben Terrainklasse desselben Nutzers normiert. Ein Score ohne Terrainklasse wird nicht ausgegeben.

### 7.4 Setup-Empfehlungs-Engine (deterministisch)

Die Engine ist ein Regelwerk, kein Modell. Eingaben: aktuelles Setup, Komponentengrenzen aus dem Katalog, `ζ` aus der Kalibrierung, Ride-Ereignisse, FNI-Verteilung, Terrainklassen, kategoriales Nutzer-Feedback, SAG.

**Regelbeispiele (Struktur, keine Erfindung von Zahlen — die Zielbereiche sind Startwerte, die in der Validierung zu bestätigen sind):**

| Regel | Bedingung | Aktion |
|---|---|---|
| `SR-REB-01` | `ζ_front` unter Zielband **und** Feedback „Front zu rau" **und** ≥ 8 harte Impacts/km | Zugstufe vorn 1–2 Klicks langsamer |
| `SR-SAG-02` | SAG vorn > 25 % (Enduro) **und** Durchschlagsverdacht > 0,5/km | Luftdruck +3–5 % **oder** ein Token mehr — **eine** Option, nicht beide |
| `SR-SAG-03` | SAG vorn < 15 % **und** Feedback „Front zu hart" **und** FNI dauerhaft niedrig | Luftdruck −3–5 % |
| `SR-TIR-04` | Reifendruck über Herstellerempfehlung für Fahrergewicht **und** hoher Anteil Textur-Energie > 15 Hz | Reifendruck −0,1 bar, Hinweis auf Insert-Empfehlung |
| `SR-COMP-05` | Zugstufe bereits am Anschlag **und** Symptom besteht fort | **Keine** Klick-Empfehlung, sondern Hinweis auf Service/Tune der Dämpfungskartusche |

**Harte Grenzen (MUSS, nicht umgehbar):**
1. Empfohlene Werte liegen **immer** innerhalb der Herstellergrenzen aus `component_model.adjusters`. Ein Vorschlag außerhalb ist ein Blocker-Defekt.
2. **Genau eine** Empfehlung pro Ride (F-AI-003).
3. Keine Empfehlung ohne mindestens **zwei unabhängige** Belege (z. B. Sensorbefund + Nutzerfeedback, oder zwei unabhängige Sensorbefunde).
4. Keine Empfehlungen zu sicherheitsrelevanten Eingriffen (Bremsen, Lenkkopf, Federwegsumbau, Steuersatz, Gabelservice) — dort ausschließlich der Hinweis, eine Fachwerkstatt aufzusuchen.
5. Bei Konfidenz `niedrig` wird keine Empfehlung ausgespielt, sondern eine Beobachtung ohne Handlungsaufforderung.

### 7.5 Validierungsstudie — Gate G-2

Die Fahrwerks-Features (FNI, Durchschlagsverdacht, Zugstufen-Empfehlung) gehen **erst nach bestandener Studie** in Produktion. Ohne dieses Gate wäre das Feature eine Behauptung.

**Aufbau:** Referenzmessung mit linearen Wegaufnehmern an Gabel und Dämpfer (kommerzielle Fahrwerkstelemetrie), zeitsynchron zum Smartphone. Mindestens 12 Fahrer, mindestens 6 verschiedene Bikes (Trail/Enduro, Luft und Stahlfeder, 27,5″ und 29″), mindestens 3 Halterungstypen, mindestens 40 Fahrstunden über mindestens 4 Terrainklassen, davon mindestens 20 % nass.

**Bestehenskriterien (alle MÜSSEN erfüllt sein):**

| Größe | Kriterium |
|---|---|
| Durchschlagserkennung | Recall ≥ 0,80 **und** Precision ≥ 0,70 gegen Referenz |
| FNI vs. reale Federwegsnutzung | Spearman ρ ≥ 0,75 innerhalb eines Bikes |
| FNI-Stabilität über Halterungen | Rangkorrelation zwischen Halterungstypen ρ ≥ 0,70 |
| Schräglage | mittlerer Absolutfehler ≤ 5° im Bereich 10–45° |
| Impact-Klassifikation | gewichtetes Cohen's κ ≥ 0,6 gegen Referenzenergie |
| Flow-Score Wiederholbarkeit | ICC ≥ 0,70 bei Wiederholung desselben Segments mit identischem Setup |
| Falsch-Positiv-Rate Empfehlungen | ≤ 10 % in Blindbewertung durch zwei unabhängige Fahrwerkstechniker |

Wird ein Kriterium verfehlt, geht das betroffene Feature **nicht** live; die übrigen Features bleiben davon unberührt. Ergebnisse werden im Produkt öffentlich zusammengefasst — Transparenz über die Genauigkeit ist hier ein Verkaufsargument, kein Risiko.

### 7.6 KI-Schichtung und Grounding

```
┌─ Schicht 1: deterministische Engines ───────────────────────┐
│  Kompatibilität · Setup-Regeln · Reichweite · Wartung        │
│  → erzeugen ALLE Zahlen, Grenzen, Urteile                    │
└──────────────────────────┬───────────────────────────────────┘
                           │ RecommendationSet (strukturiert)
┌─ Schicht 2: Statistik/ML (on-device) ───────────────────────┐
│  Terrainklassifikation · Ereigniserkennung · Rider-Profil    │
│  → erzeugen Merkmale, KEINE Handlungsempfehlungen            │
└──────────────────────────┬───────────────────────────────────┘
                           │
┌─ Schicht 3: Sprachmodell (Cloud) ───────────────────────────┐
│  Formulierung · Chat-Interface · Zusammenfassung             │
│  Werkzeugzugriff NUR auf Schicht 1 und 2                     │
└──────────────────────────┬───────────────────────────────────┘
                           │
┌─ Schicht 4: Numeric-Guard (deterministisch) ────────────────┐
│  Extrahiert alle Zahlen+Einheiten aus der Ausgabe            │
│  Vergleich gegen Whitelist aus Schicht 1/2                   │
│  Nicht belegt → verwerfen → deterministischer Fallback-Text  │
└──────────────────────────────────────────────────────────────┘
```

**MUSS:**
- Der Systemprompt der Schicht 3 verbietet ausdrücklich, Werte zu erzeugen, zu runden oder zu interpolieren.
- Der Numeric-Guard toleriert reine Wiederholungen und Einheitenumrechnungen aus der Whitelist, sonst nichts.
- Die Verwerfungsrate ist eine überwachte Kennzahl (Ziel < 2 %). Ein Anstieg deutet auf Prompt- oder Modell-Regression hin.
- Für jede LLM-Ausgabe wird ein deterministischer Fallback-Text vorgehalten, damit Ausfall oder Verwerfung nie zu einer leeren Ansicht führt.
- **Kein** LLM-Aufruf im Ride-Screen. Netzabhängigkeit während der Fahrt ist untersagt.

**Datensparsamkeit gegenüber dem Modellanbieter (MUSS):** Übergeben werden ausschließlich das strukturierte `RecommendationSet` und aggregierte Kontextwerte. Keine Rohkoordinaten, kein Track, keine Klarnamen, keine E-Mail-Adresse, keine Geräte-IDs. Auftragsverarbeitungsvertrag und EU-Verarbeitung sind Voraussetzung (siehe A-05).

### 7.7 Datenschutz-Engineering (DSGVO)

| Datenkategorie | Rechtsgrundlage | Besonderheit |
|---|---|---|
| Konto- und Bike-Daten | Art. 6 Abs. 1 lit. b (Vertrag) | |
| Standort- und Trackdaten | Art. 6 Abs. 1 lit. b für die Kernfunktion | Privatsphärenzonen als Voreinstellung anbieten |
| Herzfrequenz, Gewicht, Fitnesswerte | **Art. 9 Abs. 2 lit. a — ausdrückliche Einwilligung** | Gesundheitsdaten; getrennte Einwilligung, ohne sie bleibt die App voll nutzbar |
| Rohsensordaten für Modellverbesserung | Art. 6 Abs. 1 lit. a (Einwilligung) | Opt-in, granular, widerrufbar |
| Heatmap-Beitrag | Art. 6 Abs. 1 lit. a | Opt-in; Aggregation mit k ≥ 5 |
| Produktempfehlungen/Profilbildung | Art. 6 Abs. 1 lit. a | Ohne Einwilligung nur regelbasierte, nicht profilierende Vorschläge |
| Analytics | Art. 6 Abs. 1 lit. a | Ohne Einwilligung keine Ereignisse außer Absturzberichten |

**Pflichtmaßnahmen (MUSS):**
- **Datenschutz-Folgenabschätzung (Art. 35)** vor Launch — systematische Standortverfolgung in großem Umfang ist ein klarer Anwendungsfall.
- Verzeichnis von Verarbeitungstätigkeiten, Auftragsverarbeitungsverträge mit allen Dienstleistern (Hosting, Kartenkacheln, Push, LLM, Zahlungen, Absturzberichte).
- Verschlüsselung ruhender Daten, TLS 1.3 im Transport, Verschlüsselung der lokalen Datenbank über die Keystore/Keychain des Betriebssystems.
- Löschkonzept mit Nachweis: Kontolöschung entfernt auch Objektspeicher-Blobs und Backup-Einträge nach spätestens 90 Tagen.
- Einwilligungen sind granular, gleichrangig ablehnbar und ohne Nachteil für die Kernfunktion widerrufbar. Dark Patterns sind untersagt.
- Datenexport in offenen Formaten (GPX, FIT, JSON) — Art. 20.
- Kinder: Mindestalter 16 (bzw. nationale Grenze), Altersabfrage bei Registrierung.

---

## 8. Integrationskonzept

### 8.1 Bosch

**Grundlage:** Bosch stellt mit dem Live Data Interface eine dokumentierte, standardisierte BLE-Schnittstelle bereit, die laut Herstellerangabe kostenfrei für Dritt-Apps und -Geräte nutzbar ist und Live-Fahrdaten des *smart system* liefert. Erste öffentliche Referenzintegration ist Garmin Edge. Zusätzlich existieren ein eBike SDK und Cloud-APIs, deren Adressat jedoch Fahrradhersteller sind.

**Umsetzung:**

| Schritt | Inhalt | Zeitpunkt |
|---|---|---|
| B-1 | Registrierung/Zugang im Bosch-Entwicklerkanal, Nutzungsbedingungen und Markenrichtlinien prüfen | Vor Sprint 1 |
| B-2 | Abstraktionsschicht `MotorSystemAdapter` definieren (siehe unten) | Sprint 1–2 |
| B-3 | LDI-Adapter implementieren, Read-only | Sprint 3–5 |
| B-4 | Feldtest über die abgedeckten Generationen und Antriebslinien | Vor v1.0 |
| B-5 | Cloud-API-Eignung für Tourenhistorie prüfen (nur falls für unabhängige Anbieter zugänglich) | Phase 2 |

**Grenzen, die in der UI benannt werden MÜSSEN:**
- Nur *smart system*; ältere Bosch-Generationen fallen auf Stufe 0 zurück.
- Read-only. Keine Modussteuerung.
- Verfügbare Datenpunkte richten sich nach der Bosch-Freigabe und können sich ändern; der Adapter meldet fehlende Felder als „nicht verfügbar" statt sie zu schätzen.

### 8.2 Shimano

**Grundlage:** Für Shimano existiert **keine** öffentlich dokumentierte, smartphone-taugliche Schnittstelle. Der Zugang zum proprietären Kommunikationsprofil erfolgt über ein vertragsbasiertes Lizenzprogramm; Dritt-Radcomputer werden über das private ANT-Netzwerk angebunden, das auf Smartphones praktisch nicht verfügbar ist (iOS gar nicht ohne Zusatzhardware, Android nur auf wenigen Geräten mit ANT-Radio).

**Umsetzung:**

| Stufe | Inhalt | Bedingung |
|---|---|---|
| S-1 | Manuelle Erfassung von Motor, Akku, Kapazität aus dem Katalog; volle Reichweitenprognose | MVP, unbedingt |
| S-2 | Standard-BLE-Profile (CSCS/CPS/HRS) nutzen, soweit das jeweilige System sie bereitstellt | MVP |
| S-3 | Kontaktaufnahme zum Lizenzprogramm, Machbarkeit und Konditionen klären | Ab Monat 2, Ergebnis zu Gate G-3 |
| S-4 | Direktanbindung | **Nur nach Vertrag.** Ohne Vertrag ersatzlos gestrichen. |

**MUSS:** Die App **DARF NICHT** eine Shimano-Anbindung bewerben, die nicht vertraglich abgesichert ist. In Store-Beschreibung und Marketing wird der Funktionsumfang je Antriebssystem exakt benannt.

### 8.3 Abstraktionsschicht `MotorSystemAdapter`

Damit ist die Integrationsstrategie eine Implementierungsdetailfrage und keine Architekturfrage:

```
interface MotorSystemAdapter {
  Capabilities capabilities();        // welche Felder liefert dieses System tatsächlich
  Stream<MotorTelemetry> telemetry(); // vereinheitlichte Felder, jedes optional
  ConnectionState state();
  // KEIN write(), KEIN setAssistMode() — bewusst nicht Teil der Schnittstelle
}

Implementierungen: BoschLdiAdapter · StandardBleAdapter · ManualAdapter
                   [ShimanoAdapter nur nach Gate G-3]
```

**MUSS:** `capabilities()` steuert die UI direkt. Nicht gelieferte Felder werden ausgeblendet, **nicht** mit Null oder Schätzwerten gefüllt. Dass die Schnittstelle keine Schreiboperation kennt, ist eine bewusste architektonische Absicherung gegen F-EBK-000.

### 8.4 Karten, Geodaten, Lizenzen

| Datenquelle | Verwendung | Lizenz und Pflicht |
|---|---|---|
| OpenStreetMap | Kartendarstellung, Routing, Wegattribute | **ODbL** — Namensnennung Pflicht; abgeleitete Datenbanken unterliegen der Share-alike-Klausel. **MUSS:** Rechtsprüfung, welche Ableitungen (z. B. Heatmap-Aggregate auf OSM-Geometrie) als abgeleitete Datenbank gelten (A-06) |
| Copernicus DEM GLO-30 | Höhendaten global | Freie Nutzung unter Bedingungen der Copernicus-Lizenz, Namensnennung |
| Nationale Höhenmodelle (z. B. offene Landesdaten) | Höhere Auflösung regional | Je Datensatz eigene Lizenzprüfung |
| Mapillary | Trail View | Offene Lizenz, Namensnennung Pflicht |
| Wetterdienst (kommerziell, EU) | Prognose und Ride-Snapshot | Vertrag, Zwischenspeicherfristen beachten |
| Eigene Nutzerdaten | Heatmaps, Segmenterkennung | Nur mit Einwilligung, k ≥ 5 |

**MUSS:** Die Namensnennungen sind auf jeder Kartenansicht sichtbar (nicht nur in einem Untermenü) — das ist bei ODbL und Mapillary eine Lizenzbedingung, keine Höflichkeit.

**Kachel-Pipeline:** OSM-PBF → Planetiler → PMTiles → Objektspeicher + CDN. Aktualisierung monatlich, Offline-Regionen mit Versionsstempel; die App weist auf veraltete Regionen hin (> 90 Tage).

### 8.5 Shop und Zahlungen

**Stufe 1 — Affiliate (MVP+1).** Katalog wird redaktionell und per Händler-Feed gepflegt, Kompatibilitätsprüfung findet in AetherRide statt, Kauf beim Partner. Kein Zahlungsverkehr, keine Gewährleistung, kein Retourenprozess auf AetherRide-Seite. Geringes Risiko, schneller Start, echter Nutzentest der Kompatibilitäts-These.

**Stufe 2 — Marketplace (Phase 3, nur bei belegter Nachfrage).** Checkout über Stripe, Fulfillment durch Partnerhändler.
Pflichten, die dann **zwingend** umgesetzt sein müssen: Widerrufsbelehrung und 14-tägiges Widerrufsrecht, Impressum, Preisangabenverordnung, Versandkosten und Lieferzeit vor Kaufabschluss, Gewährleistung, GPSR-Herstellerangaben je Produkt, Umsatzsteuer über das EU-OSS-Verfahren, Verpackungsregister, Batterieverordnung bei Akkus, Streitschlichtungshinweis.

**MUSS:** Physische Waren werden **nicht** über Apple In-App-Purchase abgewickelt — das ist ein Verstoß gegen die App-Store-Richtlinien und führt zur Ablehnung. Nur digitale Abonnements (Pro) laufen über IAP bzw. Google Play Billing.

**Akkuversand (MUSS beachtet werden):** Lithium-Ionen-Akkus unterliegen Gefahrgutvorschriften. Sie werden in Stufe 1 grundsätzlich nicht vermittelt und in Stufe 2 nur über Händler mit nachgewiesener Gefahrgutzulassung.

### 8.6 Weitere Integrationen

| Ziel | Richtung | Priorität | Bemerkung |
|---|---|---|---|
| Strava | Export von Aktivitäten | P1 | Erhöht die Akzeptanz erheblich; Entwicklerprogramm und Markenrichtlinien beachten |
| Garmin / Wahoo | FIT-Import/-Export als Workflow | P1 | Dateibasiert, keine Partnerschaft nötig. Der reine GPX-Export je Ride ist bereits P0 (F-ACC-003, Datenportabilität) |
| Apple Health / Health Connect | Aktivitäten und Herzfrequenz | P2 | Nur mit ausdrücklicher Einwilligung (Art. 9) |
| Komoot | Routenimport per GPX | P2 | Dateibasiert |
| Herzfrequenzgurte | BLE Heart Rate Service | P1 | Standardprofil, keine Hürde |
| Leistungsmesser | BLE Cycling Power Service | P2 | Standardprofil; verbessert Reichweitenmodell deutlich |

### 8.7 Integrations-Gates im Überblick

| Gate | Gegenstand | Bedingung | Konsequenz bei Nichterfüllung |
|---|---|---|---|
| **G-0** | Team-Setup | Mobile-Stack bestätigt | Architekturentscheidung 5.1 neu bewerten |
| **G-1** | Bosch LDI | Zugang und Bedingungen geklärt | E-Bike-Telemetrie entfällt, Stufe 0 bleibt; Marketing anpassen |
| **G-2** | Fahrwerks-Validierung | Kriterien 7.5 erfüllt | Fahrwerks-Features gehen nicht live; Produktversprechen und Preismodell überarbeiten |
| **G-3** | Shimano-Lizenz | Vertrag unterzeichnet | Shimano-Direktanbindung ersatzlos gestrichen |
| **G-4** | Katalogabdeckung | ≥ 3.000 Komponentenmodelle mit vollständigen Schnittstellenattributen in den zehn wichtigsten Kategorien | Kompatibilitäts-Engine startet mit eingeschränktem Umfang und offener Kommunikation |
| **G-5** | Rechtsprüfung Wegerecht | Regelebene je Zielmarkt geprüft | Markteinführung nur in geprüften Ländern |

---

## 9. MVP-Scope und Phasen

### 9.1 Leitprinzip der Schnittführung

Der MVP muss **eine** These beweisen: *Wenn die App das Bike kennt, sind ihre Aussagen besser als die von Apps, die es nicht tun.* Alles, was diese These nicht prüft, ist gestrichen — auch dann, wenn es im Briefing als Must-Have geführt wird. Der Shop ist das prominenteste Beispiel: Er ist die **Monetarisierung** der These, nicht ihr Beweis, und wandert deshalb hinter den MVP.

### 9.2 Scope

| Bereich | MVP v1.0 | v1.1–v1.3 | Phase 2 | Phase 3 |
|---|---|---|---|---|
| Multi-Bike-Garage, Komponenten | ✅ voll | | | |
| Kompatibilitäts-Engine | ✅ 10 Kategorien | 20 Kategorien | alle | |
| Setup-Verwaltung, Historie | ✅ | | | |
| Bracketing | ✅ | Auto-Segmenterkennung verbessert | | |
| Wartung: Log + Intervalle | ✅ | belastungsgewichtete Prognose | | |
| Visuelle Bike-Darstellung | Foto + Liste | ✅ Schema + Hotspots | | |
| Sensorik: Aufzeichnung, Impacts, Schräglage, Flow | ✅ | | | |
| FNI, Durchschlagsverdacht, Zugstufen-Empfehlung | ⚠️ **nur bei bestandenem G-2**, sonst v1.1 | ✅ | | |
| Navigation: 7 Profile, Offline-Karten, Offline-Routing, TbT | ✅ | | | |
| Höhenprofil, Oberflächen-/Schwierigkeitsband | ✅ | | | |
| Routenvorschläge (KI) | ❌ — Discover bietet Suche, Filter, gespeicherte Routen | ✅ voll | | |
| Heatmaps | ❌ | ❌ | ✅ | |
| Trail View | ❌ | ❌ | ✅ | |
| E-Bike Stufe 0 (manuell) + Standard-BLE | ✅ | | | |
| Bosch LDI (read-only) | ✅ **bei G-1** | | | |
| Reichweitenprognose | Basisphysik | ✅ mit Selbstkalibrierung | | |
| Shimano-Direktanbindung | ❌ | ❌ | nur bei G-3 | |
| Assist-Modus-Steuerung | ❌ **dauerhaft ausgeschlossen ohne Vertrag** | ❌ | ❌ | ❌ |
| Post-Ride-Analyse (Fakten + Beobachtungen) | ✅ | | | |
| Setup-Empfehlung (max. 1/Ride) | ⚠️ G-2 | ✅ | | |
| Rider-Profil | ❌ | ✅ | | |
| KI-Chat | ❌ | ❌ | ✅ | |
| Shop: Affiliate | ❌ | ✅ | | |
| Shop: Marketplace + Versand | ❌ | ❌ | Bewertung | ✅ bei Nachfragebeleg |
| Wandern-Profil | ✅ | | | |
| GPX-Export je Ride + JSON-Vollexport (Datenportabilität) | ✅ | | | |
| Strava-Anbindung, FIT-Import/-Export als Workflow | ❌ | ✅ | | |
| Wearables (Wear OS, watchOS) | ❌ | ❌ | ❌ | ✅ |
| Live-Tracking / Sozialfunktionen | ❌ | ❌ | Bewertung | |

### 9.3 Zeit- und Ressourcenschätzung

**Kernteam (Vollzeitäquivalente):** 1 Product Manager · 1 Product Designer · 2 Mobile (davon 1 mit nachgewiesener nativer Sensor-/BLE-Erfahrung — **nicht verhandelbar**) · 2 Backend · 1 ML/Sensor-Engineer · 1 QA · 0,5 DevOps · **1 Datenkuration Katalog** · extern: Fachanwalt/Datenschutzbeauftragter, Fahrwerkstechniker als Fachberater.

| Phase | Dauer | Inhalt |
|---|---|---|
| **P0 — Fundament** | Monat 1–2 | Gates G-0/G-1 klären, Datenmodell, Sync-Engine, `dsp_core`-Prototyp, Kalibrierungsverfahren, Designsystem, Katalog-Werkzeuge |
| **MVP-Bau** | Monat 3–7 | Garage, Kompatibilität, Setups, Bracketing, Ride, Navigation, Post-Ride, Bosch LDI |
| **Validierung G-2** | Monat 5–7, parallel | Feldstudie Fahrwerk (7.5) |
| **Beta** | Monat 8 | 150–300 Testfahrer, DSGVO-Folgenabschätzung, Store-Einreichung |
| **v1.0** | Monat 9 | Launch DACH |
| **v1.1–v1.3** | Monat 10–15 | Empfehlungen, Rider-Profil, Reichweite, Strava, Affiliate-Shop |
| **Phase 2** | Monat 16–24 | Heatmaps, Trail View, KI-Chat, Shimano bei G-3 |

**Kritischer Pfad:** Katalog-Datenkuration. Rechnung: ~3.000 Komponentenmodelle mit vollständigen Schnittstellenattributen zu je 10–15 Minuten (bei guten Import-Werkzeugen und Herstellerdatenblättern) ergeben rund 600 Personenstunden, dazu ~150 Kompatibilitätsregeln zu je 1,5 Stunden inklusive Testfällen und Zweitprüfung. In Summe rund **vier Personenmonate reine Datenarbeit**, die ab Monat 1 laufen muss und nicht durch Entwickler nebenher erledigt werden kann. Wird das ignoriert, steht zum Launch eine funktionierende Engine ohne Daten — der häufigste Weg, wie Produkte dieser Art scheitern.

### 9.4 Launch-Kriterien (alle MÜSSEN erfüllt sein)

1. Alle NFR aus 5.7 gemessen und erfüllt.
2. Kompatibilitäts-Regressionsset vollständig grün, **null** kritische Fehlurteile.
3. Blindtest F-SET-003 (identisches Setup ⇒ „kein belegbarer Unterschied") ≥ 90 %.
4. G-2 entschieden — bestanden oder Feature ausgeschlossen. Kein „vorläufig live".
5. DSGVO-Folgenabschätzung abgeschlossen, Verzeichnis und AV-Verträge vollständig.
6. Barrierefreiheits-Audit ohne kritische Befunde.
7. Offline-Regression im Flugmodus vollständig grün.
8. Wegerechts-Regelebene für alle Startmärkte juristisch geprüft (G-5).
9. Store-Richtlinien-Vorprüfung: keine physischen Waren über IAP, korrekte Berechtigungstexte, Hintergrundstandort begründet.

---

## 10. Risiken und Gegenmaßnahmen

Bewertung: Eintrittswahrscheinlichkeit (W) und Auswirkung (A), je niedrig/mittel/hoch.

| ID | Risiko | W | A | Gegenmaßnahme | Verantwortung |
|---|---|---|---|---|---|
| **R-01** | Bosch-LDI-Zugang an Bedingungen geknüpft, die für einen unabhängigen Anbieter nicht erfüllbar sind | mittel | hoch | Gate G-1 vor Sprint 1; Stufe 0 und Standard-BLE tragen den E-Bike-Nutzen auch ohne LDI; Marketing erst nach Klärung | PM |
| **R-02** | Shimano-Lizenz kommt nicht zustande | **hoch** | mittel | Von Beginn an nicht eingeplant (0.4.1); Kommunikation ist von Tag 1 ehrlich, es entsteht kein Vertrauensschaden | PM |
| **R-03** | Fahrwerksvalidierung G-2 scheitert | mittel | **hoch** | Studie früh (ab Monat 5) statt kurz vor Launch; Produkt trägt auch ohne FNI (Garage, Kompatibilität, Navigation, Bracketing mit Zeit/Flow); Preismodell hat eine Rückfallvariante | ML-Lead |
| **R-04** | Katalogdaten unvollständig oder fehlerhaft ⇒ zu viele `INSUFFICIENT_DATA` ⇒ Engine wirkt nutzlos | **hoch** | **hoch** | Dedizierte Datenkuration ab Monat 1; Start mit den zehn Kategorien höchster Kaufhäufigkeit; Nutzerbeiträge mit redaktioneller Prüfung; Abdeckungsquote als Wochen-KPI; G-4 | Data Lead |
| **R-05** | Akkuverbrauch inakzeptabel bei Sensorik + Navigation + BLE | mittel | hoch | NFR-03/04 ab Sprint 1 im CI messen, nicht am Ende; adaptive Abtastrate als Rückfallebene (100 Hz bei niedrigem Akkustand); Energiesparmodus im Ride-Screen | Mobile Lead |
| **R-06** | Heatmaps ohne Nutzerbasis wertlos (Kaltstart) | hoch | niedrig | Erst Phase 2, wenn Datenbasis existiert; kein Zukauf mit ungeklärter Lizenz; ersatzweise OSM-Attributqualität als Trail-Indikator | PM |
| **R-07** | Haftung für Setup-Empfehlungen bei Unfall | niedrig | **sehr hoch** | Harte Grenzen 7.4; keine Empfehlungen zu sicherheitsrelevanten Eingriffen; Herstellergrenzen nie überschreiten; jede Empfehlung protokolliert und rekonstruierbar; Produkthaftpflicht; juristisch geprüfte Hinweistexte | Legal + PM |
| **R-08** | ODbL-Share-alike zwingt zur Offenlegung abgeleiteter Datenbestände | mittel | mittel | Frühe Rechtsprüfung (A-06); Architektur trennt OSM-abgeleitete von eigenen Daten sauber, sodass eine Offenlegung begrenzbar bleibt | Legal + Backend Lead |
| **R-09** | Flow-Score und Segmentzeiten erzeugen Wettbewerbsanreize auf öffentlichen Wegen ⇒ Konflikte mit Wanderern, Grundeigentümern, Behörden | mittel | hoch | Kein nutzerübergreifender Vergleich (F-SEN-004); keine öffentlichen Bestenlisten; Fokus der Kommunikation auf Setup statt Tempo; Wegerechtshinweise aktiv | PM |
| **R-10** | App-Store-Ablehnung (Hintergrundstandort, physische Waren, Gesundheitsdaten) | mittel | mittel | Richtlinien-Vorprüfung als Launch-Kriterium; Berechtigungstexte mit konkretem Nutzen; Waren nie über IAP | Mobile Lead |
| **R-11** | Scope-Ausweitung — die App will alles gleichzeitig sein | **hoch** | hoch | Nordstern-Metrik als Entscheidungsgrundlage; Feature-IDs mit Prioritätsstufe; kein Feature ohne zugeordneten KPI | PM |
| **R-12** | LLM erzeugt plausible, aber falsche Werte | mittel | hoch | Numeric-Guard (7.6) als harte Sperre; deterministischer Fallback; Verwerfungsrate als überwachte Kennzahl | ML-Lead |
| **R-13** | Datenschutzverstoß bei Standort-/Gesundheitsdaten | niedrig | **sehr hoch** | DSFA vor Launch; granulare Einwilligungen; Privatsphärenzonen als Voreinstellung; Datenminimierung gegenüber dem LLM-Anbieter; externe Prüfung | DSB |
| **R-14** | GNSS-Ungenauigkeit im Wald verfälscht Segment-Matching und damit das Bracketing | **hoch** | mittel | Matching über Geometrie **und** Barometerprofil **und** Sensorsignatur statt nur GPS; `match_quality` je Segment; bei niedriger Übereinstimmung keine Auswertung statt einer falschen | ML-Lead |
| **R-15** | Wissenskonzentration im nativen Sensor-/BLE-Modul auf einer Person | mittel | hoch | `dsp_core` in Rust mit Desktop-Testbarkeit und Referenzdatensätzen; Pair-Programming Pflicht in diesem Modul; Architekturdokumentation als Definition-of-Done | Eng. Lead |
| **R-16** | Nutzer pflegen die Garage nicht ⇒ das Fundament bleibt leer | mittel | **sehr hoch** | Katalog-Vorbefüllung über OEM-Ausstattungslisten als Standardweg; jeder ausgefüllte Slot schaltet sofort sichtbaren Nutzen frei; Fortschrittsanzeige „Bike zu 60 % erfasst" mit konkretem nächstem Schritt | Design + PM |

**R-16 verdient besondere Aufmerksamkeit:** Das gesamte Produktkonzept steht und fällt damit, dass Nutzer ihre Bikes vollständig erfassen. Die Katalog-Vorbefüllung ist deshalb kein Komfortfeature, sondern eine Überlebensfunktion — sie ist der Grund, warum `catalog_bike` mit OEM-Ausstattungslisten in 6.2 als eigene Entität existiert.

---

## 11. Annahmen und offene Punkte

Jeder Punkt hat eine verantwortliche Rolle und einen Zeitpunkt, bis zu dem er geklärt sein muss. Ein offener Punkt ohne Termin ist ein verdecktes Risiko.

| ID | Annahme / offener Punkt | Verantwortung | Fällig |
|---|---|---|---|
| **A-01** | Bosch LDI ist für einen unabhängigen App-Anbieter (nicht OEM) zugänglich; Nutzungsbedingungen, Registrierungspflichten und Markenrichtlinien sind erfüllbar. **Zu verifizieren, bevor irgendeine Bosch-Funktion beworben wird.** | PM | vor Sprint 1 |
| **A-02** | Der genaue Umfang der über LDI verfügbaren Felder und die abgedeckten *smart system*-Generationen sind zum Implementierungszeitpunkt zu erheben; die Angaben in 8.1 entsprechen dem Recherchestand August 2026 und können sich ändern. | Mobile Lead | Sprint 3 |
| **A-03** | Der Zusammenhang zwischen gemessenem Dämpfungsmaß `ζ` und der subjektiv als richtig empfundenen Zugstufe ist plausibel, aber **nicht belegt**. Die in 7.4 genannten Zielbänder sind Hypothesen und werden in G-2 bestimmt, nicht vorausgesetzt. | ML-Lead | G-2 |
| **A-04** | Die Zielgruppe ist bereit, für Setup-Funktionen zu zahlen. Zu prüfen vor Preisfestlegung durch Zahlungsbereitschaftsbefragung (n ≥ 300) und Beta-Konversion. | PM | Monat 6 |
| **A-05** | Ein LLM-Anbieter mit EU-Verarbeitung, Auftragsverarbeitungsvertrag und Zusicherung, dass Eingaben nicht zum Training verwendet werden, steht zu vertretbaren Kosten zur Verfügung. | CTO | Monat 4 |
| **A-06** | Rechtliche Bewertung, welche AetherRide-Datenbestände als von OSM abgeleitete Datenbank im Sinne der ODbL gelten (insbesondere Heatmap-Aggregate und angereicherte Wegattribute). | Legal | Monat 3 |
| **A-07** | Regionale Wegerechtslage je Zielmarkt (u. a. Befahrbarkeitsregelungen einzelner Bundesländer) — aktueller Rechtsstand ist zu erheben und **halbjährlich** nachzuprüfen. | Legal | G-5, danach halbjährlich |
| **A-08** | Haftungsrechtliche Bewertung von Setup-Empfehlungen nach deutschem und EU-Recht; Formulierung der Hinweistexte durch einen Fachanwalt. | Legal | Monat 5 |
| **A-09** | Verfügbarkeit maschinenlesbarer OEM-Ausstattungslisten für die Katalog-Vorbefüllung. Falls nicht verfügbar: manuelle Erfassung der 200 meistverkauften Modelle als Rückfallebene — Aufwand ca. 1,5 Personenmonate zusätzlich. | Data Lead | Monat 2 |
| **A-10** | Auf iOS ist kein direkter Zugriff auf den Umgebungslichtsensor vorgesehen; die Sunlight-Mode-Automatik nutzt dort die Systemhelligkeit als Näherung. Zu verifizieren gegen die zum Implementierungszeitpunkt aktuelle iOS-Version. | Mobile Lead | Sprint 6 |
| **A-11** | Die tatsächlich erreichbare Beschleunigungssensor-Reichweite variiert je Gerät (häufig ±8 g oder ±16 g). Bei ±8 g-Geräten sättigt der Sensor bei harten Schlägen. Erforderlich: Gerätematrix mit Messung der realen Reichweite und Kennzeichnung eingeschränkter Geräte in der App. | ML-Lead | Monat 4 |
| **A-12** | Barometer-Abtastrate auf iOS ist deutlich niedriger als auf Android. Alle Höhen- und Vertikalgeschwindigkeitsableitungen müssen ohne hochfrequentes Barometer auskommen. | ML-Lead | Sprint 4 |
| **A-13** | Das Umsatzmodell des Affiliate-Shops (Provisionssätze im Fahrradzubehörmarkt) ist zu erheben, bevor Entwicklungsaufwand in Stufe 2 fließt. | PM | Monat 12 |
| **A-14** | Marktstart DACH; weitere Märkte erfordern je eigene Prüfung von Wegerecht, Verbraucherrecht und Kartenlizenzen. | PM | vor Expansion |

**Bewusst nicht spezifiziert (und warum):** Detaillierte Backend-Endpunkt-Signaturen (gehören in die OpenAPI-Datei, nicht in ein Konzeptdokument), konkrete Pixel-Werte je Screen (gehören ins Design-File auf Basis der Token aus Kapitel 4), Sprintplanung (Aufgabe des Teams), Auswahl des LLM-Anbieters (abhängig von A-05).

---

## Anhang A — Must-Have und Nice-to-Have im Überblick

**Must-Have (ohne diese Punkte erfüllt das Produkt sein Versprechen nicht):**
Multi-Bike-Garage mit Komponenten · Kompatibilitäts-Engine mit vier Urteilen und Begründungskette · Setup-Verwaltung mit unveränderlichen Versionen · Bracketing mit statistischer Absicherung · Sensoraufzeichnung mit Montage-Erkennung und Kalibrierung · Post-Ride-Analyse · sportartspezifisches Routing mit Offline-Fähigkeit · Turn-by-Turn · E-Bike Stufe 0 · Trennung von Entscheidung und Formulierung in der KI · granulare Einwilligungen und Datenexport.

**Nice-to-Have (wertvoll, aber nicht konstitutiv):**
Heatmaps · Trail View · KI-Chat · Rider-Profil · Marketplace mit Versand · Wearables · Familien-Garage · Live-Tracking · belastungsgewichtete Wartungsprognose · schematische Bike-Darstellung.

**Ausgeschlossen (mit Begründung):**
Motorsteuerung ohne Herstellervertrag (0.4.1) · Federweg in Millimetern aus Smartphone-Sensorik (0.4.2) · eigenes Warenlager (0.4.4) · Reverse Engineering proprietärer Protokolle · nutzerübergreifende Bestenlisten (R-09) · Superlativ-Marketing (0.4.5).

## Anhang B — Quellen zum Herstellerstand (Recherchestand August 2026)

- Bosch eBike Systems, Live Data Interface: `bosch-ebike.com/us/business/live-data-interface`
- Bosch eBike Systems, eBike SDK und Cloud API: `bosch-ebike.com/en/company/industry-solutions/cloud-api-ebike-sdk`
- Bosch Presseinformation zum Live Data Interface und zur Garmin-Integration (2026)
- Bosch Developer Community: `community.developer.bosch.com`
- Shimano, Connected Partners: `bike.shimano.com/technologies/details/shimano-connected-partners.html`
- Shimano, Produktkommunikation zum vertragsbasierten Lizenzprogramm für das Kommunikationsprofil
- Shimano Newsroom zur Di2-Wireless-Funktionalität und zur ANT-Anbindung von Dritt-Radcomputern

**Hinweis (MUSS beachtet werden):** Diese Angaben sind ein Rechercheergebnis, keine vertragliche Zusage. Vor Implementierungsbeginn ist der Stand direkt beim jeweiligen Hersteller zu verifizieren (A-01, A-02).

## Anhang C — Glossar

| Begriff | Bedeutung |
|---|---|
| **Bracketing** | Systematisches Verstellen eines einzelnen Parameters über einen Bereich, um durch Vergleich das Optimum einzugrenzen |
| **Dämpfungsmaß ζ** | Dimensionsloses Maß der Schwingungsdämpfung; klein = schwingt lange nach, groß = kriecht zurück |
| **Durchschlag** | Vollständiges Ausnutzen des Federwegs bis zum mechanischen Anschlag |
| **ETRTO** | Europäische Normung für Reifen- und Felgenmaße |
| **FNI** | Federweg-Nutzungs-Index — relativer Index, **keine** Millimeterangabe |
| **Freilaufkörper** | Teil der Hinterradnabe, auf das die Kassette geschoben wird; Standards HG, Micro Spline, XD, XDR |
| **LDI** | Bosch Live Data Interface |
| **mtb:scale** | OSM-Attribut für die technische Schwierigkeit eines Trails (S0–S5) |
| **ODbL** | Open Database License — Lizenz von OpenStreetMap mit Namensnennungs- und Share-alike-Pflicht |
| **PMTiles** | Einzeldatei-Format für Vektorkacheln, gut geeignet für Offline und CDN |
| **sac_scale** | OSM-Attribut für die Schwierigkeit von Wanderwegen |
| **SAG** | Negativfederweg unter statischer Fahrerlast, in Prozent des Gesamthubs |
| **Token / Volumen-Spacer** | Einsatz in der Luftkammer, der die Progression der Federkennlinie erhöht |
| **Trunnion-Mount** | Dämpferaufnahme mit seitlicher Verschraubung am Dämpferkörper statt am Auge |

## Anhang D — Änderungshistorie

| Version | Datum | Änderung |
|---|---|---|
| 1.0 | 06.08.2026 | Erstfassung. Enthält fünf dokumentierte Korrekturen am Ausgangsbriefing (Kapitel 0.4). |

---

*Ende der Spezifikation.*
