# Garage Bike-Schema Spec v1 — „richtiges Rad“
**Kritik Luka:** Geometrie / Fahrradschema „zum Davonlaufen“  
**Ist:** `BikeSilhouette.tsx` (Web, F-GAR-004) · Android/Flutter Garage noch ohne Paritäts-SVG  
**Soll:** Seitenansicht mit echten Proportionen + Slot-Hotspots · Sport-aware · Web = Android  
**Stand:** 2026-08-11

---

## 1) Was am aktuellen Schema falsch ist (F-GAR-004)

Datei: `src/components/garage/BikeSilhouette.tsx`

| Problem | Ist | Wirkung |
|---|---|---|
| **Kein Diamant-Rahmen** | `framePath` = 4-Punkt-Polygon `M…Z` | Sieht aus wie ein Parallelogramm, nicht wie ein Bike |
| **Keine echte Geometrie** | Kein Head Tube, Seat Tube, Chain-/Seatstays als getrennte Rohre; BB/Kurbel fehlt als Form | Crank „schwebt“ nur als Hotspot; Rad wirkt kaputt |
| **Gabel = orangener Strich** | Eine Linie HT→Nabe | Keine Gabel-Krone, kein Travel-Unterschied MTB |
| **Lenker = waagerechte Linie** | Road/Gravel ohne Drops; Flat bar ohne Rise | Sport nicht erkennbar |
| **Laufräder ok-ish, Anbindung falsch** | Kreise @ (60,145)/(250,145) | Stay-/Gabel-Linien treffen Naben nur ungefähr |
| **Hotspots = lose Dots** | Fixed cx/cy, r=9 (~18px) | Liegen „neben“ dem Rad; Hit-Target &lt; 44pt; wirken wie UI-Konfetti |
| **Reifen-Differenz schwach** | Nur `wheelRadius` 32–38 | Keine Reifen-*Dicke* (Road dünn vs MTB fett) |
| **Seat/Sattel** | Ellipse + Linie | Sattelstütze trifft Rahmen nicht klar |
| **Kind-Mapping inkonsistent** | `mtb_trail` → hardtail bis Shock | Verständlich technisch, visuell springt das Schema |
| **Debug-Chrome** | Label `Schema · {drawKind}` | Wirkt intern, nicht produktreif |

**Fazit:** F-GAR-004 lieferte „8 Silhouetten“ als Path-Varianten eines Stick-Frames — nicht 8 erkennbare Bikes. Das erklärt Lukás Reaktion.

---

## 2) Soll-Geometrie (Seitenansicht)

### ViewBox & Layout
- **viewBox:** `0 0 400 240` (breiteres Rad, weniger gequetscht als 320×200)
- **Ground:** y = 200  
- **Achsen:** Front Hub `(88, 200−R)`, Rear Hub `(312, 200−R)` → Radstand ≈ 224 units (~consistent 2.6–2.8× wheel for road/gravel feel)
- **BB:** `(190, 168)` roughly — unter ST/DT, vor hinterer Achse
- **Scale:** 1 Schema-Komponente, Varianten über Token (Winkel, Travel, Reifen-Stroke, Bar-Typ)

### Rohr-Set (immer zeichnen)
1. Front wheel + tire ring (stroke = tire thickness)  
2. Rear wheel + tire ring  
3. Fork (crown → dropout; MTB: längere / versetzte Gabel)  
4. Head tube  
5. Top tube  
6. Down tube  
7. Seat tube  
8. Chain stays  
9. Seat stays  
10. Stem + handlebar (Drop | Flat | Riser)  
11. Seatpost + saddle  
12. Crank + chainring (Kreis am BB)  
13. Optional: rear shock link, motor/battery block, rack/fenders  

### Sport-Token (sichtbar unterscheidbar)

| Token | Road | Gravel | MTB (Trail/Enduro) | City/Urban |
|---|---|---|---|---|
| Tire stroke | 3 | 5 | 8–10 | 5 |
| Bar | Drops | Flared drops / flat | Flat/riser | Flat upright |
| Stack visual | niedrig | mittel | höher | hoch |
| Fork | starr kurz | starr | Federweg sichtbar | starr / leicht |
| Shock | — | — | ja (Fully) | — |
| Rack/Fender | — | optional | — | optional default |

**Empfehlung Eng:** **4 Basis-SVG Templates** (road / gravel / mtb_full / city) + Hardtail als mtb ohne shock-layer — nicht 8 fast gleiche Polygone. DH/E-MTB = mtb Template + Motor/Battery + längere Gabel-Tokens.

---

## 3) Slot-Hotspots (an Geometrie verankert)

Jeder Hotspot = **Anchor-Punkt am SVG** + unsichtbarer Hit-Kreis **r ≥ 22** (≈44pt @1x) + sichtbarer Status-Dot r=6–8.

| Slot | Anchor | Sichtbar wenn |
|---|---|---|
| `tire_front` | Front hub | immer |
| `fork` | Fork mid | immer |
| `brake_front` | Near front caliper | immer |
| `handlebar` | Bar center | immer |
| `stem` | Stem mid | immer |
| `frame` | Mid top-tube / front triangle | immer |
| `seatpost` | Seatpost mid | immer |
| `saddle` | Saddle | immer |
| `crank` / chainring | BB | immer (Slot-Name laut Catalog) |
| `chain` | Lower run BB→cassette | immer |
| `cassette` | Rear hub outer | immer |
| `tire_rear` | Rear hub | immer |
| `brake_rear` | Rear caliper | immer |
| `rear_shock` | Shock body | Fully only |
| `motor` / `battery` | Mid DT / BB area | eBike only |
| `pedals` | Pedal tip | optional P1 |

**Statusfarben** (behalten): ok `#22C55E` · maintenance `#EAB308` · missing `#6B7280`  
**Selected:** Ring Accent um Hit-Area.

---

## 4) Wire — Soll-Look (ASCII)
```
        saddle
          ▪
         │ seatpost
    drops══╗
         stem
          ║ HT
     TT ════════╗
      ╱         ║ ST
     ╱          ║
  fork          ║
    │      DT   ║
    ●═════╱═════● BB ═══ crank
   ╱╲          ╱╲
  ○   ○       ○   ○     ← dicke Reifen-Ringe sport-aware
 front         rear
   ▪tire    ▪cassette
```

---

## 5) Web + Android Parität

| | Web | Android (Flutter) |
|---|---|---|
| Asset | Shared SVG in `packages/` oder `assets/bike_schema/` | `flutter_svg` gleiche Files |
| API | `<BikeSchema kind hotspots onSelect>` | `BikeSchema` widget gleiche props |
| Hotspot IDs | `ComponentSlot` enum shared | gleiche Strings |
| Variante | `BikeSchemaKind` aus category mapper | **ein** Mapper shared (Dart/TS sync test) |

**Nicht:** Flutter CustomPainter neu erfinden parallel zum Web-SVG.

---

## 6) Eng-Tickets

| ID | Titel | Prio |
|---|---|---|
| **G-SCH-01** | Audit replace: neue SVG Templates road/gravel/mtb/city | P0 |
| **G-SCH-02** | Hotspot anchors + 44pt hit targets + a11y labels | P0 |
| **G-SCH-03** | Category→Kind mapper + Fully/Hardtail/eBike layers | P0 |
| **G-SCH-04** | Web `BikeSilhouette` → `BikeSchema` swap | P0 |
| **G-SCH-05** | Flutter Garage Parität (gleiche SVGs) | P0 Android |
| **G-SCH-06** | Visual QA Checklist (Screenshot Road/Gravel/MTB/City) | P0 |
| **G-SCH-07** | Optional: Dropper, Fender, Rack overlays | P1 |

---

## 7) Acceptance (Luka-Bar)
- [ ] Untrained viewer says „Das ist ein Rennrad / Gravel / MTB / City“ in &lt;2s  
- [ ] Seat tube trifft BB; Stays treffen Rear Hub; Fork trifft Front Hub  
- [ ] Hotspots sitzen auf Bauteilen, nicht daneben  
- [ ] Tap targets ≥44pt  
- [ ] Web und Android pixel-ähnlich  
- [ ] Kein `Schema · drawKind` Debug-Label in Prod  

---

## 8) Umsetzungsnotiz für Eng
Bestehenden Status-/Maintenance-Flow behalten (ok/missing/maintenance). **Nur Geometrie + Anchor-Map ersetzen.** F-GAR-004 als erledigt markieren erst nach G-SCH-06 QA.

---

## Research Amendment — Proportionen & SVG-Ansatz (Aug 2026)

Quellen: BikeSize/OEM-Geo-Erklärer, Wikimedia Bicycle diagram, rattleCAD / bicycle-geometry (parametrisch). City-Zahlen unsicherer als Road/MTB.

### Erkennungs-Hierarchie (stärkste Cues)
1. **MTB:** dicke Reifen + Federweg + kurzer Stem + langes WB  
2. **City:** Rack + Schutzbleche + aufrechte Bars  
3. **Gravel:** Drops + fette Reifen + Clearance  
4. **Road:** Drops + dünne Reifen + kompaktes WB  

### Starter-Params (Silhouette M, indikativ)
| Param | Road | Gravel | MTB Trail | City |
|---|---|---|---|---|
| Wheelbase (normiert) | 990 | 1040 | 1200 | 1080 |
| Tire visual width | 28 | 45 | 60 | 38 |
| HTA | ~72.5° | ~71° | ~65° | ~71° |
| Bar | drop | drop flare | flat short stem | swept flat |
| Extra | — | clearance | fork travel ± shock | fenders + rack |

### SVG-Ansatz (final)
**Hybrid:** ein parametrisches Skeleton (Achsen, BB, HT, ST stabil) + **4 Presets** — nicht ein Zeichnung für alle, nicht 8 Copy-Paste-Polygone.  
**viewBox:** `0 0 1000 500` (2:1); Ground/Axle-Y konstant beim Sport-Switch.  
**Hotspots:** stabile IDs; hide per Sport; invisible hit layer ≥44pt; Overlap-Priority pedals > crank > chain > frame.

### Zusätzliche Ist-Fehler (gegen Research)
Floating BB/Crank, Stem-Länge falsch (MTB zu lang), Head-Angle überall ~73°, Tire-Gauge zu schwach differenziert, Scale-Jump zwischen Varianten — alles adressieren in G-SCH-01.

---

## 9) Bildreferenzen (Go — Eng-Umsetzung)

**Ordner:** `aetherride-ux/bike-schema-refs/`  
**Zweck:** Visuelle Wahrheit für G-SCH-01 — nicht Prod-Asset final, aber Geometrie-/Cue-Referenz.

| File | Sport | Was prüfen |
|---|---|---|
| `schema-ref-road.svg/.png` | Road | Drops, dünne Reifen, kompaktes WB, Stem länger |
| `schema-ref-gravel.svg/.png` | Gravel | Drops + dickere Reifen, etwas längeres WB |
| `schema-ref-mtb.svg/.png` | MTB | Flat bar, kurzer Stem, Sus-Fork + Shock, längstes WB, fette Reifen |
| `schema-ref-city.svg/.png` | City | Swept bars, Rack + Fender, aufrechter Stack |

**Externe Open-Refs (Lizenz beachten, nur Inspiration):**
- Wikimedia [Bicycle diagram-en.svg](https://commons.wikimedia.org/wiki/File:Bicycle_diagram-en.svg) — Bauteil-Benennung, ~2:1  
- Wikimedia Diamantrahmen Rohr-/Winkelnamen — HT/TT/ST/DT/CS/SS  
- BikeSize Geometry Comparison 2026 — Stack/Reach/HTA Ranges  

**Eng-Regel:** Prod-SVGs dürfen die Ref-SVGs als Start nehmen (parametrisch cleanen), Hotspot-IDs aus Spec §3. QA: Sport in &lt;2s erkennbar neben diesen Refs.
