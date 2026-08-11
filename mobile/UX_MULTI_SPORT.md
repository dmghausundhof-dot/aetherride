# UX Multi-Sport Redesign

Ziel: **eine App für alle Radfahrer:innen** — MTB, Gravel, Rennrad, City, E-Bike/E-Trekking — ohne MTB-only Framing.

## Prinzipien

1. **Gleiche Würde** — Disziplinen gleichwertig im Onboarding und in den Labels.
2. **Sport-adaptiv** — Copy und Features (Fahrwerk/SAG) folgen dem gewählten Sport.
3. **Deutsche Primärsprache** — Fahren, Touren, Teile (kein Discover/Shop/Ride).
4. **Power-Features progressiv** — Setup/Fahrwerk für Federgabel-Sports; City/Road schlank.

## Navigation

| Alt | Neu |
|-----|-----|
| Home | Home |
| Garage | Garage |
| Ride | **Fahren** |
| Discover | **Touren** |
| Shop | **Teile** |

## Code

- `lib/domain/sport/discipline_ux.dart` — Labels, Familien, Copy
- Shell / Onboarding / Home / Ride / Discover / Shop angepasst

## Offen (nächste UX-Schritte)

- Discover: Sport-Filter-Chips als primäre Reihe (Profil-Default)
- Ride: Mount/Fahrwerk-UI nur wenn `showsChassisLayer`
- Profile: Disziplin prominent ändern
- Web-Parität: gleiche Nav-Labels
