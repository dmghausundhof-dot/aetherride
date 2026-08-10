# Play Console Runbook — Keystore, SKU, Publisher-API

Code-seitig ist alles vorbereitet (siehe unten). Alles auf dieser Seite ab
„Schritt 1" läuft ausschließlich in Google-Konsolen mit deinem Google-Konto
— das kann niemand außer dir ausführen (Login, 2FA, Zahlungsdaten,
Entwickler-Registrierung).

## Was bereits erledigt ist (Code)

- **Upload-Keystore generiert**: `android/keystore/aetherride-upload.jks`
  (Alias `aetherride`, RSA 2048, gültig bis 2056).
  `android/key.properties` zeigt darauf — beides **lokal, git-ignoriert**
  (`android/.gitignore`: `key.properties`, `**/*.jks`). Ohne `key.properties`
  fällt der Release-Build automatisch auf Debug-Signing zurück
  (`app/build.gradle.kts`) — das ist bewusst so, damit CI ohne Secrets baut.
- **SHA1**: `F3:24:9D:78:95:C1:E7:6C:72:9E:AC:E6:16:01:E6:6D:F6:EA:A3:AC`
- **SHA256**: `08:5F:25:15:97:3F:4C:91:3C:AE:4F:19:72:B5:4C:70:47:EE:A2:41:E5:2A:E3:02:1F:5D:B6:55:8F:08:8E:94`
  (Diese Fingerprints brauchst du unten für Play App Signing und optional für
  Google Sign-In / Supabase OAuth Client-Konfiguration.)
- **Release-Build verifiziert lokal**: `flutter build appbundle --release`
  läuft durch, produziert `build/app/outputs/bundle/release/app-release.aab`
  (aktuell 86 MB, debug-signiert — für den echten Play-Upload musst du unten
  mit dem Upload-Keystore neu bauen).
- **R8-Bug gefixt**: Play-Core-Split-Install-Klassen brachen den Release-Build
  (`android/app/proguard-rules.pro`) — war vorher rot, ist jetzt grün.
- **CI baut jetzt den Release-Build mit** (`release-build` Job in
  `.github/workflows/flutter-mobile.yml`), damit das nicht wieder unbemerkt
  bricht.

⚠️ **Backup**: Sichere `android/keystore/aetherride-upload.jks` und
`android/key.properties` **jetzt** an einen zweiten Ort (Passwort-Manager /
verschlüsseltes Backup), bevor du den ersten Upload machst. Solange der
Keystore nur lokal existiert und noch nie hochgeladen wurde, ist ein Verlust
unkritisch (einfach neu generieren). Sobald du damit das erste Mal in Play
Console hochlädst, ist es der Upload-Key für alle künftigen Updates —
Google kann ihn zurücksetzen (Play App Signing entkoppelt Upload-Key vom
finalen App-Signing-Key), aber das ist ein Support-Vorgang, kein Klick.

---

## Schritt 1 — Play Console: App anlegen

1. [play.google.com/console](https://play.google.com/console) → falls noch
   keine Entwicklerregistrierung: einmalig 25 $ Registrierungsgebühr.
2. „App erstellen" → Name `AetherRide`, Standardsprache Deutsch, App
   (nicht Spiel), Kostenlos (Pro läuft über In-App-Subscription, nicht
   App-Preis).
3. Package name **muss exakt** `com.aetherride.aetherride_mobile` sein
   (steht in `android/app/build.gradle.kts:namespace`) — das lässt sich
   später nicht mehr ändern.

## Schritt 2 — Play App Signing aktivieren

1. Release → Setup → App-Signing.
2. „Play App Signing verwenden" (empfohlen, Standard seit 2021) — Google
   verwaltet den finalen Signing-Key, du lieferst nur den Upload-Key.
3. Ersten Upload machen (Internal Testing Track, siehe Schritt 3) —
   Play Console fragt beim allerersten Upload nach dem Upload-Zertifikat;
   das ist der Keystore von oben (`aetherride-upload.jks`).

## Schritt 3 — Ersten Build hochladen (Internal Testing)

Auf deiner Maschine, mit dem echten Upload-Keystore signiert:

```bash
cd mobile
flutter build appbundle --release \
  --dart-define=SUPABASE_ANON_KEY="$NEXT_PUBLIC_SUPABASE_ANON_KEY" \
  --dart-define=API_BASE_URL=https://aetherride.vercel.app \
  --dart-define=STADIA_API_KEY="$NEXT_PUBLIC_STADIA_API_KEY"
```

→ `build/app/outputs/bundle/release/app-release.aab`. Release → Testing →
Internal testing → Neuer Release → AAB hochladen. Play Console signiert es
mit dem verwalteten Key und verteilt es an Tester.

## Schritt 4 — License Tester

Release → Setup → License Testing → deine eigene Google-Kontoadresse (und
ggf. Kolleg:innen) eintragen → diese Accounts können Testkäufe tätigen ohne
echte Abbuchung.

## Schritt 5 — Subscription-Produkt anlegen

Monetarisieren → Abos → Abo erstellen:

- **Produkt-ID exakt**: `aetherride_pro_monthly` (steht so im Code,
  `mobile/lib/data/billing/play_billing.dart` — muss zeichengenau passen)
- Preis DACH gemäß Spec: 6,99 €/Monat (Jahres-Variante optional zusätzlich)
- Basisplan aktivieren, veröffentlichen.

## Schritt 6 — Publisher API (Server-Side Verify)

Ohne diesen Schritt läuft die App im „Trusted-Token-MVP" (Client behauptet
Kaufstatus, Server vertraut ohne Google-Gegenprüfung) — für Launch akzeptabel
als Fallback, aber löst reale Zahlungsprüfung nicht. Für echte Prüfung:

1. [console.cloud.google.com](https://console.cloud.google.com) → Projekt
   wählen/anlegen → „Google Play Android Developer API" aktivieren.
2. IAM → Dienstkonto erstellen (z. B. `play-verify@…iam.gserviceaccount.com`)
   → JSON-Key erzeugen und herunterladen.
3. Play Console → Nutzer und Berechtigungen → Einladen → die
   Dienstkonto-E-Mail → Berechtigung „Finanzdaten anzeigen" (mindestens).
4. JSON-Inhalt als **ein-zeiliger String** in die Vercel-Env
   `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` (Projekt-Settings → Environment
   Variables, Production) — siehe `mobile/README.md` „Billing (Pro)".
5. Ohne diese Variable verifiziert `/api/billing/play-verify` weiterhin nur
   per Trusted-Token; mit ihr prüft der Server aktiv gegen Google.

## Schritt 7 — Store-Listing (Minimum für Review)

- Kurzbeschreibung (80 Zeichen), Vollbeschreibung, Feature-Grafik
  (1024×500), mind. 2 Screenshots Phone (Outdoor/Ride-Screen empfohlen,
  siehe P1-5 in `MARKET_READY_PLAN.md`).
- Datenschutzerklärung-URL: `https://aetherride.vercel.app/legal/datenschutz`
  (muss vor Review live + inhaltlich final sein, P0-12).
- Content Rating Fragebogen ausfüllen.
- Data Safety Form: Standort (ja, für Ride-Tracking), Sensordaten,
  Konto-Infos — ehrlich gemäß tatsächlicher Datennutzung ausfüllen (spart
  Review-Rückfragen).

## Danach: Production-Rollout

Internal → Closed/Open Testing (optional) → Production, gestaffelter
Rollout (z. B. 20 % → 100 %) empfohlen statt Big-Bang.

---

**Kurz-Referenz Ops-Checkliste** (Gesamtüberblick aller offenen Punkte,
nicht nur Play): [ANDROID_OPS_CHECKLIST.md](ANDROID_OPS_CHECKLIST.md)
