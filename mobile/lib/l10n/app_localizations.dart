import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'AetherRide'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In de, this message translates to:
  /// **'Für MTB, Gravel, Rennrad, City & E-Bike — eine App fürs Rad.'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In de, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navGarage.
  ///
  /// In de, this message translates to:
  /// **'Garage'**
  String get navGarage;

  /// No description provided for @navRide.
  ///
  /// In de, this message translates to:
  /// **'Fahren'**
  String get navRide;

  /// No description provided for @navDiscover.
  ///
  /// In de, this message translates to:
  /// **'Touren'**
  String get navDiscover;

  /// No description provided for @navParts.
  ///
  /// In de, this message translates to:
  /// **'Teile'**
  String get navParts;

  /// No description provided for @navKarte.
  ///
  /// In de, this message translates to:
  /// **'Karte'**
  String get navKarte;

  /// No description provided for @navWorkshop.
  ///
  /// In de, this message translates to:
  /// **'Werkstatt'**
  String get navWorkshop;

  /// No description provided for @navShop.
  ///
  /// In de, this message translates to:
  /// **'Laden'**
  String get navShop;

  /// No description provided for @hofJustRide.
  ///
  /// In de, this message translates to:
  /// **'Einfach fahren'**
  String get hofJustRide;

  /// No description provided for @hofShowTours.
  ///
  /// In de, this message translates to:
  /// **'Touren anzeigen'**
  String get hofShowTours;

  /// No description provided for @hofMapChoiceHint.
  ///
  /// In de, this message translates to:
  /// **'Ohne Touren losfahren, oder Touren auf der Karte zeigen.'**
  String get hofMapChoiceHint;

  /// No description provided for @werkstattPartsShelf.
  ///
  /// In de, this message translates to:
  /// **'Shop'**
  String get werkstattPartsShelf;

  /// No description provided for @werkstattForYourBike.
  ///
  /// In de, this message translates to:
  /// **'Für dein Rad'**
  String get werkstattForYourBike;

  /// No description provided for @werkstattMerch.
  ///
  /// In de, this message translates to:
  /// **'Merchandise'**
  String get werkstattMerch;

  /// No description provided for @werkstattShopParts.
  ///
  /// In de, this message translates to:
  /// **'Ersatzteile im Shop'**
  String get werkstattShopParts;

  /// No description provided for @shopGatewayKicker.
  ///
  /// In de, this message translates to:
  /// **'Über den Hof'**
  String get shopGatewayKicker;

  /// No description provided for @shopGatewayTitle.
  ///
  /// In de, this message translates to:
  /// **'Der Laden'**
  String get shopGatewayTitle;

  /// No description provided for @shopGatewayHint.
  ///
  /// In de, this message translates to:
  /// **'Hier wohnt das Rad nicht. Ehrliche Teile und Merch im Shopify-Shop — Kauf und Kasse dort, nicht in der App.'**
  String get shopGatewayHint;

  /// No description provided for @shopZumShop.
  ///
  /// In de, this message translates to:
  /// **'Zum Shop'**
  String get shopZumShop;

  /// No description provided for @shopForYourBikeHint.
  ///
  /// In de, this message translates to:
  /// **'Ersatzteile passend zu {name} — Kategorie und Laufrad. Keine erfundenen SKUs.'**
  String shopForYourBikeHint(String name);

  /// No description provided for @shopForYourBikeEmpty.
  ///
  /// In de, this message translates to:
  /// **'Stell ein Rad in der Werkstatt ab — dann öffnen wir die passenden Teile im Shop.'**
  String get shopForYourBikeEmpty;

  /// No description provided for @shopMerchHint.
  ///
  /// In de, this message translates to:
  /// **'Kleidung und Kleinzeug. Unabhängig vom Rad, nie nach Fit gefiltert.'**
  String get shopMerchHint;

  /// No description provided for @shopNotConnected.
  ///
  /// In de, this message translates to:
  /// **'Shop nicht verbunden'**
  String get shopNotConnected;

  /// No description provided for @shopNotConnectedHint.
  ///
  /// In de, this message translates to:
  /// **'Keine Storefront-URL. SHOPIFY_STOREFRONT_URL setzen, dann führt dieser Tab in den Laden.'**
  String get shopNotConnectedHint;

  /// No description provided for @shopOpenFailed.
  ///
  /// In de, this message translates to:
  /// **'Shop konnte nicht geöffnet werden.'**
  String get shopOpenFailed;

  /// No description provided for @shopPasswordWall.
  ///
  /// In de, this message translates to:
  /// **'Der Online-Store ist noch passwortgeschützt. Shopify-Admin: Online Store → Preferences → Password protection aus.'**
  String get shopPasswordWall;

  /// No description provided for @garageSetupTabHintTires.
  ///
  /// In de, this message translates to:
  /// **'Luftdruck grob nach Gewicht und Reifen — am Rad nachmessen, keine OEM-Tabelle.'**
  String get garageSetupTabHintTires;

  /// No description provided for @werkstattSetupTires.
  ///
  /// In de, this message translates to:
  /// **'Reifen / Druck grob'**
  String get werkstattSetupTires;

  /// No description provided for @werkstattSetupSuspension.
  ///
  /// In de, this message translates to:
  /// **'Fahrwerk — SAG und Luft nach Federweg'**
  String get werkstattSetupSuspension;

  /// No description provided for @werkstattSetupSuspensionUnknown.
  ///
  /// In de, this message translates to:
  /// **'Fahrwerk — Federweg nicht eingetragen'**
  String get werkstattSetupSuspensionUnknown;

  /// No description provided for @werkstattSetupDropper.
  ///
  /// In de, this message translates to:
  /// **'Vario-Stütze (eingetragen)'**
  String get werkstattSetupDropper;

  /// No description provided for @werkstattSetupWheel.
  ///
  /// In de, this message translates to:
  /// **'Laufrad {size}'**
  String werkstattSetupWheel(String size);

  /// No description provided for @werkstattSetupCockpit.
  ///
  /// In de, this message translates to:
  /// **'Cockpit — Lenker und Vorbau'**
  String get werkstattSetupCockpit;

  /// No description provided for @werkstattSetupBagsCockpit.
  ///
  /// In de, this message translates to:
  /// **'Taschen / Cockpit'**
  String get werkstattSetupBagsCockpit;

  /// No description provided for @werkstattSetupLightsRack.
  ///
  /// In de, this message translates to:
  /// **'Licht und Gepäckträger — nur wenn eingetragen'**
  String get werkstattSetupLightsRack;

  /// No description provided for @werkstattSetupDrivetrain.
  ///
  /// In de, this message translates to:
  /// **'Schaltung'**
  String get werkstattSetupDrivetrain;

  /// No description provided for @werkstattBatteryHonest.
  ///
  /// In de, this message translates to:
  /// **'Akku nur mit echtem Sensor'**
  String get werkstattBatteryHonest;

  /// No description provided for @werkstattBatteryHonestHint.
  ///
  /// In de, this message translates to:
  /// **'Kein Prozent ohne gekoppelten Sensor. Bosch LDI bleibt G-1.'**
  String get werkstattBatteryHonestHint;

  /// No description provided for @werkstattSensorEbike.
  ///
  /// In de, this message translates to:
  /// **'Radsensor (CSC) — Tempo und Trittfrequenz. Akku-Stand nur mit echtem Sensor.'**
  String get werkstattSensorEbike;

  /// No description provided for @werkstattSensorAnalog.
  ///
  /// In de, this message translates to:
  /// **'Radsensor — Tempo und Trittfrequenz am Rad.'**
  String get werkstattSensorAnalog;

  /// No description provided for @hofYourWatch.
  ///
  /// In de, this message translates to:
  /// **'Deine Uhr'**
  String get hofYourWatch;

  /// No description provided for @hofWatchHint.
  ///
  /// In de, this message translates to:
  /// **'Fitnesstracking am Fahrer — nicht am Rad. Puls nur mit echtem Sensor. Apple Watch oft ohne Standard-BLE.'**
  String get hofWatchHint;

  /// No description provided for @hofWatchPair.
  ///
  /// In de, this message translates to:
  /// **'Uhr koppeln'**
  String get hofWatchPair;

  /// No description provided for @hofWatchReconnect.
  ///
  /// In de, this message translates to:
  /// **'Neu koppeln'**
  String get hofWatchReconnect;

  /// No description provided for @hofWatchRemove.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get hofWatchRemove;

  /// No description provided for @hofWatchConnect.
  ///
  /// In de, this message translates to:
  /// **'Uhr verbinden'**
  String get hofWatchConnect;

  /// No description provided for @hofYou.
  ///
  /// In de, this message translates to:
  /// **'Du'**
  String get hofYou;

  /// No description provided for @hofYouSheetHint.
  ///
  /// In de, this message translates to:
  /// **'Du und deine Uhr. Der Radsensor bleibt am Rad in der Werkstatt.'**
  String get hofYouSheetHint;

  /// No description provided for @werkstattWatchEbike.
  ///
  /// In de, this message translates to:
  /// **'Smartwatch — Puls neben CSC. Kein erfundener SoC.'**
  String get werkstattWatchEbike;

  /// No description provided for @werkstattWatchAnalog.
  ///
  /// In de, this message translates to:
  /// **'Smartwatch / Fitnesstracking'**
  String get werkstattWatchAnalog;

  /// No description provided for @setupTirePressureLabel.
  ///
  /// In de, this message translates to:
  /// **'Vorderreifen (psi)'**
  String get setupTirePressureLabel;

  /// No description provided for @setupCompareHintTires.
  ///
  /// In de, this message translates to:
  /// **'Legt zwei verdeckte Reifendrücke an. Nach ein paar Fahrten siehst du, welcher sich besser anfühlt.'**
  String get setupCompareHintTires;

  /// No description provided for @setupTirePressureValue.
  ///
  /// In de, this message translates to:
  /// **'Reifen {value} psi'**
  String setupTirePressureValue(String value);

  /// No description provided for @searchHome.
  ///
  /// In de, this message translates to:
  /// **'Wohin willst du? Ort, Tour oder Adresse'**
  String get searchHome;

  /// No description provided for @startRide.
  ///
  /// In de, this message translates to:
  /// **'Fahrt starten'**
  String get startRide;

  /// No description provided for @startFreeride.
  ///
  /// In de, this message translates to:
  /// **'Ohne Route fahren'**
  String get startFreeride;

  /// No description provided for @startWithRoute.
  ///
  /// In de, this message translates to:
  /// **'Route fahren'**
  String get startWithRoute;

  /// No description provided for @goRide.
  ///
  /// In de, this message translates to:
  /// **'Losfahren'**
  String get goRide;

  /// No description provided for @readyTitle.
  ///
  /// In de, this message translates to:
  /// **'Bereit zum Fahren'**
  String get readyTitle;

  /// No description provided for @readyMessage.
  ///
  /// In de, this message translates to:
  /// **'GPS-Track startet sofort. Sensoren und Route sind optional — egal ob Trail, Asphalt oder City.'**
  String get readyMessage;

  /// No description provided for @optionalRoute.
  ///
  /// In de, this message translates to:
  /// **'Optional: unter Touren eine Route wählen und „Losfahren“.'**
  String get optionalRoute;

  /// No description provided for @starting.
  ///
  /// In de, this message translates to:
  /// **'Startet…'**
  String get starting;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @reset.
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get reset;

  /// No description provided for @errorPrefix.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {error}'**
  String errorPrefix(String error);

  /// No description provided for @discoverMenuPhotos.
  ///
  /// In de, this message translates to:
  /// **'Umgebungsfotos'**
  String get discoverMenuPhotos;

  /// No description provided for @discoverMenuOffline.
  ///
  /// In de, this message translates to:
  /// **'Offline-Karten'**
  String get discoverMenuOffline;

  /// No description provided for @discoverMenuCollections.
  ///
  /// In de, this message translates to:
  /// **'Sammlungen'**
  String get discoverMenuCollections;

  /// No description provided for @discoverMenuPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Heatmap & Privatsphäre'**
  String get discoverMenuPrivacy;

  /// No description provided for @partsTitle.
  ///
  /// In de, this message translates to:
  /// **'Teile & Zubehör'**
  String get partsTitle;

  /// No description provided for @partsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Live featured-parts in AetherRide — Soft-Fit & Preise, ohne Shopify-Passwort-Dead-End.'**
  String get partsSubtitle;

  /// No description provided for @weatherFallback.
  ///
  /// In de, this message translates to:
  /// **'Wetter nicht verfügbar'**
  String get weatherFallback;

  /// No description provided for @weatherLoading.
  ///
  /// In de, this message translates to:
  /// **'Wetter wird geladen…'**
  String get weatherLoading;

  /// No description provided for @statsRidesOne.
  ///
  /// In de, this message translates to:
  /// **'Fahrt'**
  String get statsRidesOne;

  /// No description provided for @statsRidesMany.
  ///
  /// In de, this message translates to:
  /// **'Fahrten'**
  String get statsRidesMany;

  /// No description provided for @profile.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @chat.
  ///
  /// In de, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @hofRideOut.
  ///
  /// In de, this message translates to:
  /// **'Rausfahren'**
  String get hofRideOut;

  /// No description provided for @hofOpenBike.
  ///
  /// In de, this message translates to:
  /// **'Rad öffnen'**
  String get hofOpenBike;

  /// No description provided for @hofParkBike.
  ///
  /// In de, this message translates to:
  /// **'Rad abstellen'**
  String get hofParkBike;

  /// No description provided for @hofRideWithoutBike.
  ///
  /// In de, this message translates to:
  /// **'Ohne Rad fahren'**
  String get hofRideWithoutBike;

  /// No description provided for @hofRideOutAgain.
  ///
  /// In de, this message translates to:
  /// **'Noch mal raus'**
  String get hofRideOutAgain;

  /// No description provided for @hofAtGate.
  ///
  /// In de, this message translates to:
  /// **'vor dem Tor'**
  String get hofAtGate;

  /// No description provided for @hofEmptyStand.
  ///
  /// In de, this message translates to:
  /// **'Leerer Stand'**
  String get hofEmptyStand;

  /// No description provided for @hofSkyUnknown.
  ///
  /// In de, this message translates to:
  /// **'Himmel unbekannt'**
  String get hofSkyUnknown;

  /// No description provided for @hofNoHonestLoop.
  ///
  /// In de, this message translates to:
  /// **'Kein ehrlicher Trail-Rundkurs'**
  String get hofNoHonestLoop;

  /// No description provided for @hofNotYetOut.
  ///
  /// In de, this message translates to:
  /// **'noch nicht draußen'**
  String get hofNotYetOut;

  /// No description provided for @hofJustBack.
  ///
  /// In de, this message translates to:
  /// **'gerade reingekommen'**
  String get hofJustBack;

  /// No description provided for @hofLastRideNoGps.
  ///
  /// In de, this message translates to:
  /// **'ohne GPS-Track — kein erfundener Verlauf'**
  String get hofLastRideNoGps;

  /// No description provided for @hofGpsUnknown.
  ///
  /// In de, this message translates to:
  /// **'Kein Standort — Himmel und Tor warten auf GPS.'**
  String get hofGpsUnknown;

  /// No description provided for @rideGpsUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Kein GPS — Track bleibt leer. Kein erfundener Verlauf.'**
  String get rideGpsUnavailable;

  /// No description provided for @hofAtHof.
  ///
  /// In de, this message translates to:
  /// **'am Hof'**
  String get hofAtHof;

  /// No description provided for @hofSinceOneDay.
  ///
  /// In de, this message translates to:
  /// **'seit 1 Tag'**
  String get hofSinceOneDay;

  /// No description provided for @hofSinceDays.
  ///
  /// In de, this message translates to:
  /// **'seit {days} Tagen'**
  String hofSinceDays(int days);

  /// No description provided for @hofNoBikeHere.
  ///
  /// In de, this message translates to:
  /// **'Kein Rad steht hier'**
  String get hofNoBikeHere;

  /// No description provided for @hofBringForward.
  ///
  /// In de, this message translates to:
  /// **'{name} nach vorn'**
  String hofBringForward(String name);

  /// No description provided for @hofCareInWorkshop.
  ///
  /// In de, this message translates to:
  /// **'{label} — in der Werkstatt'**
  String hofCareInWorkshop(String label);

  /// No description provided for @hofSensorAwake.
  ///
  /// In de, this message translates to:
  /// **'Sensor wach'**
  String get hofSensorAwake;

  /// No description provided for @hofOpenTours.
  ///
  /// In de, this message translates to:
  /// **'Touren öffnen'**
  String get hofOpenTours;

  /// No description provided for @hofSkyDry.
  ///
  /// In de, this message translates to:
  /// **'{temp}° · eher trocken'**
  String hofSkyDry(String temp);

  /// No description provided for @hofSkyDamp.
  ///
  /// In de, this message translates to:
  /// **'{temp}° · feucht möglich'**
  String hofSkyDamp(String temp);

  /// No description provided for @hofSkyWet.
  ///
  /// In de, this message translates to:
  /// **'{temp}° · Regen · Trails eher nass'**
  String hofSkyWet(String temp);

  /// No description provided for @hofLoopDuration.
  ///
  /// In de, this message translates to:
  /// **'⟲ {minutes} min'**
  String hofLoopDuration(int minutes);

  /// No description provided for @hofCommunityNotes.
  ///
  /// In de, this message translates to:
  /// **'{count} Stimmen zu dieser Runde'**
  String hofCommunityNotes(int count);

  /// No description provided for @homeSubtitleMtb.
  ///
  /// In de, this message translates to:
  /// **'Trails, Touren & dein Setup'**
  String get homeSubtitleMtb;

  /// No description provided for @homeSubtitleGravel.
  ///
  /// In de, this message translates to:
  /// **'Schotter, Distanz & Navigation'**
  String get homeSubtitleGravel;

  /// No description provided for @homeSubtitleRoad.
  ///
  /// In de, this message translates to:
  /// **'Asphalt, Tempo & Training'**
  String get homeSubtitleRoad;

  /// No description provided for @homeSubtitleUrban.
  ///
  /// In de, this message translates to:
  /// **'Pendeln, Stadt & Alltag'**
  String get homeSubtitleUrban;

  /// No description provided for @homeSubtitleEbike.
  ///
  /// In de, this message translates to:
  /// **'Assist, Reichweite & Touren'**
  String get homeSubtitleEbike;

  /// No description provided for @homeSubtitleDefault.
  ///
  /// In de, this message translates to:
  /// **'Jede Art zu fahren — dein Rad, deine Route'**
  String get homeSubtitleDefault;

  /// No description provided for @homeSubtitleWithWeather.
  ///
  /// In de, this message translates to:
  /// **'{weather} · {base}'**
  String homeSubtitleWithWeather(String weather, String base);

  /// No description provided for @tipHeroTitleMtb.
  ///
  /// In de, this message translates to:
  /// **'Heute raus aufs Rad'**
  String get tipHeroTitleMtb;

  /// No description provided for @tipHeroTitleGravel.
  ///
  /// In de, this message translates to:
  /// **'Heute Schotter oder Mix'**
  String get tipHeroTitleGravel;

  /// No description provided for @tipHeroTitleRoad.
  ///
  /// In de, this message translates to:
  /// **'Heute Asphalt-Kilometer'**
  String get tipHeroTitleRoad;

  /// No description provided for @tipHeroTitleUrban.
  ///
  /// In de, this message translates to:
  /// **'Heute durch die Stadt'**
  String get tipHeroTitleUrban;

  /// No description provided for @tipHeroTitleEbike.
  ///
  /// In de, this message translates to:
  /// **'Heute mit Assist unterwegs'**
  String get tipHeroTitleEbike;

  /// No description provided for @tipHeroTitleDefault.
  ///
  /// In de, this message translates to:
  /// **'Heute passt eine Fahrt'**
  String get tipHeroTitleDefault;

  /// No description provided for @tipHeroSubtitleMtb.
  ///
  /// In de, this message translates to:
  /// **'Route wählen oder einfach freifahren — Track lokal.'**
  String get tipHeroSubtitleMtb;

  /// No description provided for @tipHeroSubtitleGravel.
  ///
  /// In de, this message translates to:
  /// **'Plane eine Distanz oder starte ohne Route.'**
  String get tipHeroSubtitleGravel;

  /// No description provided for @tipHeroSubtitleRoad.
  ///
  /// In de, this message translates to:
  /// **'Runde bauen oder freies Training aufzeichnen.'**
  String get tipHeroSubtitleRoad;

  /// No description provided for @tipHeroSubtitleUrban.
  ///
  /// In de, this message translates to:
  /// **'Pendeln tracken oder kurze Runde speichern.'**
  String get tipHeroSubtitleUrban;

  /// No description provided for @tipHeroSubtitleEbike.
  ///
  /// In de, this message translates to:
  /// **'Tour planen und Reichweite im Blick behalten.'**
  String get tipHeroSubtitleEbike;

  /// No description provided for @tipHeroSubtitleDefault.
  ///
  /// In de, this message translates to:
  /// **'MTB, Gravel, Rennrad oder City — alles hier.'**
  String get tipHeroSubtitleDefault;

  /// No description provided for @chassisLayer.
  ///
  /// In de, this message translates to:
  /// **'Fahrwerk'**
  String get chassisLayer;

  /// No description provided for @sensorLayer.
  ///
  /// In de, this message translates to:
  /// **'Sensorik'**
  String get sensorLayer;

  /// No description provided for @filter.
  ///
  /// In de, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filterReset.
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get filterReset;

  /// No description provided for @filterResetFilters.
  ///
  /// In de, this message translates to:
  /// **'Filter zurücksetzen'**
  String get filterResetFilters;

  /// No description provided for @filterDurationLens.
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get filterDurationLens;

  /// No description provided for @filterSurfaceGroup.
  ///
  /// In de, this message translates to:
  /// **'Untergrund'**
  String get filterSurfaceGroup;

  /// No description provided for @filterExertion.
  ///
  /// In de, this message translates to:
  /// **'Schwierigkeit'**
  String get filterExertion;

  /// No description provided for @filterDistance.
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get filterDistance;

  /// No description provided for @filterElevation.
  ///
  /// In de, this message translates to:
  /// **'Höhenmeter'**
  String get filterElevation;

  /// No description provided for @filterForm.
  ///
  /// In de, this message translates to:
  /// **'Form'**
  String get filterForm;

  /// No description provided for @filterTrailNetwork.
  ///
  /// In de, this message translates to:
  /// **'Trailnetz (Karte)'**
  String get filterTrailNetwork;

  /// No description provided for @filterLoopsOnly.
  ///
  /// In de, this message translates to:
  /// **'Rundkurs'**
  String get filterLoopsOnly;

  /// No description provided for @filterLoopsOnlyTooltip.
  ///
  /// In de, this message translates to:
  /// **'Nur ehrliche Rundkurse (Start≈Ziel). Keine A→B-Füllung.'**
  String get filterLoopsOnlyTooltip;

  /// No description provided for @filterNetworkOn.
  ///
  /// In de, this message translates to:
  /// **'Netz an'**
  String get filterNetworkOn;

  /// No description provided for @filterNetworkOff.
  ///
  /// In de, this message translates to:
  /// **'Netz aus'**
  String get filterNetworkOff;

  /// No description provided for @filterOsmScaleTooltip.
  ///
  /// In de, this message translates to:
  /// **'OSM-Skala: {code}'**
  String filterOsmScaleTooltip(String code);

  /// No description provided for @filterShowTours.
  ///
  /// In de, this message translates to:
  /// **'{count} Touren zeigen'**
  String filterShowTours(int count);

  /// No description provided for @filterNoTours.
  ///
  /// In de, this message translates to:
  /// **'Keine Tour bei diesen Filtern.'**
  String get filterNoTours;

  /// No description provided for @filterNoToursHint.
  ///
  /// In de, this message translates to:
  /// **'Keine Touren — „Neu“ tippen oder Filter lockern.'**
  String get filterNoToursHint;

  /// No description provided for @loopLabel.
  ///
  /// In de, this message translates to:
  /// **'Rundkurs'**
  String get loopLabel;

  /// No description provided for @computeRoute.
  ///
  /// In de, this message translates to:
  /// **'Route berechnen'**
  String get computeRoute;

  /// No description provided for @adaptTour.
  ///
  /// In de, this message translates to:
  /// **'Anpassen'**
  String get adaptTour;

  /// No description provided for @adaptTourTitle.
  ///
  /// In de, this message translates to:
  /// **'Tour anpassen'**
  String get adaptTourTitle;

  /// No description provided for @adaptTourHint.
  ///
  /// In de, this message translates to:
  /// **'Start, Ziel oder Stopp ändern — dann Route berechnen.'**
  String get adaptTourHint;

  /// No description provided for @planRouteTitle.
  ///
  /// In de, this message translates to:
  /// **'Route planen'**
  String get planRouteTitle;

  /// No description provided for @planRouteCta.
  ///
  /// In de, this message translates to:
  /// **'+ Planen'**
  String get planRouteCta;

  /// No description provided for @discoverSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Ort oder Tour'**
  String get discoverSearchHint;

  /// No description provided for @filterAroundKm.
  ///
  /// In de, this message translates to:
  /// **'in {km} km'**
  String filterAroundKm(int km);

  /// No description provided for @mapToggleFab.
  ///
  /// In de, this message translates to:
  /// **'Karte'**
  String get mapToggleFab;

  /// No description provided for @communityWriteReview.
  ///
  /// In de, this message translates to:
  /// **'Bewertung schreiben'**
  String get communityWriteReview;

  /// No description provided for @discoverModeExplore.
  ///
  /// In de, this message translates to:
  /// **'Entdecken'**
  String get discoverModeExplore;

  /// No description provided for @discoverModeNavigate.
  ///
  /// In de, this message translates to:
  /// **'Navigieren'**
  String get discoverModeNavigate;

  /// No description provided for @discoverModeMine.
  ///
  /// In de, this message translates to:
  /// **'Meine'**
  String get discoverModeMine;

  /// No description provided for @navigateTitle.
  ///
  /// In de, this message translates to:
  /// **'Navigieren'**
  String get navigateTitle;

  /// No description provided for @navigateSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Ziel tippen oder Adresse — dann berechnen'**
  String get navigateSubtitle;

  /// No description provided for @navigateStartLabel.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get navigateStartLabel;

  /// No description provided for @navigateEndLabel.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get navigateEndLabel;

  /// No description provided for @navigateStartHint.
  ///
  /// In de, this message translates to:
  /// **'Adresse, Ort oder Tippen'**
  String get navigateStartHint;

  /// No description provided for @navigateEndHint.
  ///
  /// In de, this message translates to:
  /// **'Wohin willst du?'**
  String get navigateEndHint;

  /// No description provided for @navigateMyLocation.
  ///
  /// In de, this message translates to:
  /// **'Mein Standort'**
  String get navigateMyLocation;

  /// No description provided for @navigateSwap.
  ///
  /// In de, this message translates to:
  /// **'Start und Ziel tauschen'**
  String get navigateSwap;

  /// No description provided for @navigatePickStart.
  ///
  /// In de, this message translates to:
  /// **'Start auf Karte'**
  String get navigatePickStart;

  /// No description provided for @navigatePickEnd.
  ///
  /// In de, this message translates to:
  /// **'Ziel auf Karte'**
  String get navigatePickEnd;

  /// No description provided for @navigateAddVia.
  ///
  /// In de, this message translates to:
  /// **'Via'**
  String get navigateAddVia;

  /// No description provided for @navigateNeedStartEnd.
  ///
  /// In de, this message translates to:
  /// **'Start und Ziel setzen'**
  String get navigateNeedStartEnd;

  /// No description provided for @navigateComputeNeedBoth.
  ///
  /// In de, this message translates to:
  /// **'Route berechnen (Start & Ziel nötig)'**
  String get navigateComputeNeedBoth;

  /// No description provided for @navigateBackToExplore.
  ///
  /// In de, this message translates to:
  /// **'Zurück zu Entdecken'**
  String get navigateBackToExplore;

  /// No description provided for @mineSheetHint.
  ///
  /// In de, this message translates to:
  /// **'Deine Aufzeichnungen, Importe und gespeicherten Strecken'**
  String get mineSheetHint;

  /// No description provided for @mineEmptyCtaNavigate.
  ///
  /// In de, this message translates to:
  /// **'Route von A nach B'**
  String get mineEmptyCtaNavigate;

  /// No description provided for @gpxImportAction.
  ///
  /// In de, this message translates to:
  /// **'GPX importieren'**
  String get gpxImportAction;

  /// No description provided for @exploreOpenNavigate.
  ///
  /// In de, this message translates to:
  /// **'A→B navigieren'**
  String get exploreOpenNavigate;

  /// No description provided for @sheetDragHandleMine.
  ///
  /// In de, this message translates to:
  /// **'Meine-Strecken-Leiste ziehen'**
  String get sheetDragHandleMine;

  /// No description provided for @sheetDragHandleNavigate.
  ///
  /// In de, this message translates to:
  /// **'Navigations-Leiste ziehen'**
  String get sheetDragHandleNavigate;

  /// No description provided for @browseMap.
  ///
  /// In de, this message translates to:
  /// **'Karte'**
  String get browseMap;

  /// No description provided for @browseList.
  ///
  /// In de, this message translates to:
  /// **'Liste'**
  String get browseList;

  /// No description provided for @quickFilter1h.
  ///
  /// In de, this message translates to:
  /// **'1 Std'**
  String get quickFilter1h;

  /// No description provided for @sheetDragHandle.
  ///
  /// In de, this message translates to:
  /// **'Touren-Leiste ziehen'**
  String get sheetDragHandle;

  /// No description provided for @sheetPeekHint.
  ///
  /// In de, this message translates to:
  /// **'Nach oben ziehen — Touren & Filter'**
  String get sheetPeekHint;

  /// No description provided for @rideBarCollapseHint.
  ///
  /// In de, this message translates to:
  /// **'Nach unten ziehen zum Einklappen'**
  String get rideBarCollapseHint;

  /// No description provided for @rideBarExpandHint.
  ///
  /// In de, this message translates to:
  /// **'Öffnen'**
  String get rideBarExpandHint;

  /// No description provided for @rideBarStart.
  ///
  /// In de, this message translates to:
  /// **'Losfahren'**
  String get rideBarStart;

  /// No description provided for @rideBarRoute.
  ///
  /// In de, this message translates to:
  /// **'Strecke'**
  String get rideBarRoute;

  /// No description provided for @rideBarPointToPoint.
  ///
  /// In de, this message translates to:
  /// **'Strecke'**
  String get rideBarPointToPoint;

  /// No description provided for @emptyToursTitle.
  ///
  /// In de, this message translates to:
  /// **'Keine Touren gefunden'**
  String get emptyToursTitle;

  /// No description provided for @emptyToursFiltersBody.
  ///
  /// In de, this message translates to:
  /// **'Filter zurücksetzen — dann siehst du wieder Touren in der Nähe.'**
  String get emptyToursFiltersBody;

  /// No description provided for @emptyToursNearbyBody.
  ///
  /// In de, this message translates to:
  /// **'Ort oder Dauer anpassen — oder Filter zurücksetzen. Keine A→B-Füllung.'**
  String get emptyToursNearbyBody;

  /// No description provided for @showOnMap.
  ///
  /// In de, this message translates to:
  /// **'Auf Karte'**
  String get showOnMap;

  /// No description provided for @tourDetails.
  ///
  /// In de, this message translates to:
  /// **'Details'**
  String get tourDetails;

  /// No description provided for @moreFilters.
  ///
  /// In de, this message translates to:
  /// **'Mehr Filter'**
  String get moreFilters;

  /// No description provided for @moreActions.
  ///
  /// In de, this message translates to:
  /// **'Weitere Aktionen'**
  String get moreActions;

  /// No description provided for @filterSurfaceAsphalt.
  ///
  /// In de, this message translates to:
  /// **'Asphalt'**
  String get filterSurfaceAsphalt;

  /// No description provided for @filterSurfaceGravel.
  ///
  /// In de, this message translates to:
  /// **'Schotter'**
  String get filterSurfaceGravel;

  /// No description provided for @filterSurfaceTrail.
  ///
  /// In de, this message translates to:
  /// **'Trail'**
  String get filterSurfaceTrail;

  /// No description provided for @filterSurfaceMixed.
  ///
  /// In de, this message translates to:
  /// **'Gemischt'**
  String get filterSurfaceMixed;

  /// No description provided for @filterSurfaceAsphaltHint.
  ///
  /// In de, this message translates to:
  /// **'Asphalt · Radweg · befestigt'**
  String get filterSurfaceAsphaltHint;

  /// No description provided for @filterSurfaceGravelHint.
  ///
  /// In de, this message translates to:
  /// **'Schotter · Forst · verdichtet'**
  String get filterSurfaceGravelHint;

  /// No description provided for @filterSurfaceTrailHint.
  ///
  /// In de, this message translates to:
  /// **'Naturboden · Singletrail · Wurzel'**
  String get filterSurfaceTrailHint;

  /// No description provided for @filterSurfaceMixedHint.
  ///
  /// In de, this message translates to:
  /// **'Stadt · gemischter Belag'**
  String get filterSurfaceMixedHint;

  /// No description provided for @filterSurfaceAsphaltFull.
  ///
  /// In de, this message translates to:
  /// **'Asphalt · befestigt'**
  String get filterSurfaceAsphaltFull;

  /// No description provided for @filterSurfaceGravelFull.
  ///
  /// In de, this message translates to:
  /// **'Schotter · verdichtet'**
  String get filterSurfaceGravelFull;

  /// No description provided for @filterSurfaceTrailFull.
  ///
  /// In de, this message translates to:
  /// **'Naturboden · Trail'**
  String get filterSurfaceTrailFull;

  /// No description provided for @filterSurfaceMixedFull.
  ///
  /// In de, this message translates to:
  /// **'Stadt · gemischt'**
  String get filterSurfaceMixedFull;

  /// No description provided for @filterEffortEasy.
  ///
  /// In de, this message translates to:
  /// **'Leicht'**
  String get filterEffortEasy;

  /// No description provided for @filterEffortMid.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get filterEffortMid;

  /// No description provided for @filterEffortHard.
  ///
  /// In de, this message translates to:
  /// **'Anspruchsvoll'**
  String get filterEffortHard;

  /// No description provided for @filterEffortEasyHint.
  ///
  /// In de, this message translates to:
  /// **'S0 / entspannt / wenig Technik'**
  String get filterEffortEasyHint;

  /// No description provided for @filterEffortMidHint.
  ///
  /// In de, this message translates to:
  /// **'S1–S2 / sportlich / gemischt'**
  String get filterEffortMidHint;

  /// No description provided for @filterEffortHardHint.
  ///
  /// In de, this message translates to:
  /// **'S2+ / schwer / technisch'**
  String get filterEffortHardHint;

  /// No description provided for @filterElevFlat.
  ///
  /// In de, this message translates to:
  /// **'< 400 hm'**
  String get filterElevFlat;

  /// No description provided for @filterElevHilly.
  ///
  /// In de, this message translates to:
  /// **'400–1100 hm'**
  String get filterElevHilly;

  /// No description provided for @filterElevAlpine.
  ///
  /// In de, this message translates to:
  /// **'1100+ hm'**
  String get filterElevAlpine;

  /// No description provided for @filterDistMax20.
  ///
  /// In de, this message translates to:
  /// **'≤ 20 km'**
  String get filterDistMax20;

  /// No description provided for @filterDistMax40.
  ///
  /// In de, this message translates to:
  /// **'≤ 40 km'**
  String get filterDistMax40;

  /// No description provided for @filterDistMax70.
  ///
  /// In de, this message translates to:
  /// **'≤ 70 km'**
  String get filterDistMax70;

  /// No description provided for @filterScaleEasy.
  ///
  /// In de, this message translates to:
  /// **'Leicht'**
  String get filterScaleEasy;

  /// No description provided for @filterScaleMedium.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get filterScaleMedium;

  /// No description provided for @filterScaleHard.
  ///
  /// In de, this message translates to:
  /// **'Anspruchsvoll'**
  String get filterScaleHard;

  /// No description provided for @trailDiffEasy.
  ///
  /// In de, this message translates to:
  /// **'Leicht'**
  String get trailDiffEasy;

  /// No description provided for @trailDiffMedium.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get trailDiffMedium;

  /// No description provided for @trailDiffHard.
  ///
  /// In de, this message translates to:
  /// **'Schwer'**
  String get trailDiffHard;

  /// No description provided for @trailDiffVeryHard.
  ///
  /// In de, this message translates to:
  /// **'Sehr schwer'**
  String get trailDiffVeryHard;

  /// No description provided for @trailDiffUnrated.
  ///
  /// In de, this message translates to:
  /// **'Nicht eingestuft'**
  String get trailDiffUnrated;

  /// No description provided for @trailDiffOpen.
  ///
  /// In de, this message translates to:
  /// **'offen'**
  String get trailDiffOpen;

  /// No description provided for @durationAny.
  ///
  /// In de, this message translates to:
  /// **'egal'**
  String get durationAny;

  /// No description provided for @duration2to3h.
  ///
  /// In de, this message translates to:
  /// **'2–3 h'**
  String get duration2to3h;

  /// No description provided for @garageTitle.
  ///
  /// In de, this message translates to:
  /// **'Garage'**
  String get garageTitle;

  /// No description provided for @garageFabBike.
  ///
  /// In de, this message translates to:
  /// **'Rad abstellen'**
  String get garageFabBike;

  /// No description provided for @garageEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Die Box ist leer'**
  String get garageEmptyTitle;

  /// No description provided for @garageEmptyMessage.
  ///
  /// In de, this message translates to:
  /// **'Rad abstellen — ehrlich, ohne Demo-Kilometer. Dann siehst du, ob es bereit ist.'**
  String get garageEmptyMessage;

  /// No description provided for @garageAddBike.
  ///
  /// In de, this message translates to:
  /// **'Rad abstellen'**
  String get garageAddBike;

  /// No description provided for @garageStatBike.
  ///
  /// In de, this message translates to:
  /// **'RAD'**
  String get garageStatBike;

  /// No description provided for @garageStatBikes.
  ///
  /// In de, this message translates to:
  /// **'RÄDER'**
  String get garageStatBikes;

  /// No description provided for @garageStatKmTotal.
  ///
  /// In de, this message translates to:
  /// **'KM GESAMT'**
  String get garageStatKmTotal;

  /// No description provided for @garageQuickSwitch.
  ///
  /// In de, this message translates to:
  /// **'Schnellwechsel'**
  String get garageQuickSwitch;

  /// No description provided for @garageLastRides.
  ///
  /// In de, this message translates to:
  /// **'Letzte Fahrten'**
  String get garageLastRides;

  /// No description provided for @garageNoRidesTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Fahrten'**
  String get garageNoRidesTitle;

  /// No description provided for @garageNoRidesMessage.
  ///
  /// In de, this message translates to:
  /// **'Deine erste gespeicherte Fahrt erscheint hier.'**
  String get garageNoRidesMessage;

  /// No description provided for @garageActive.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get garageActive;

  /// No description provided for @garageActiveBike.
  ///
  /// In de, this message translates to:
  /// **'Aktives Bike · {name}'**
  String garageActiveBike(String name);

  /// No description provided for @garageEbikeBadge.
  ///
  /// In de, this message translates to:
  /// **'E-Bike'**
  String get garageEbikeBadge;

  /// No description provided for @garageMaintOk.
  ///
  /// In de, this message translates to:
  /// **'Alles in Ordnung'**
  String get garageMaintOk;

  /// No description provided for @garageMaintDue.
  ///
  /// In de, this message translates to:
  /// **'{count} Wartung fällig'**
  String garageMaintDue(int count);

  /// No description provided for @garageMaintOverdue.
  ///
  /// In de, this message translates to:
  /// **'{count} überfällig'**
  String garageMaintOverdue(int count);

  /// No description provided for @garagePartsCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Teile'**
  String garagePartsCount(int count);

  /// No description provided for @garageParts.
  ///
  /// In de, this message translates to:
  /// **'Teile'**
  String get garageParts;

  /// No description provided for @garageMaintenance.
  ///
  /// In de, this message translates to:
  /// **'Wartung'**
  String get garageMaintenance;

  /// No description provided for @garageSetup.
  ///
  /// In de, this message translates to:
  /// **'Setup'**
  String get garageSetup;

  /// No description provided for @garageInstall.
  ///
  /// In de, this message translates to:
  /// **'Teil hinzufügen'**
  String get garageInstall;

  /// No description provided for @garageOtherBikes.
  ///
  /// In de, this message translates to:
  /// **'Weitere Räder'**
  String get garageOtherBikes;

  /// No description provided for @garageTechDetails.
  ///
  /// In de, this message translates to:
  /// **'Technische Details'**
  String get garageTechDetails;

  /// No description provided for @garageTechHint.
  ///
  /// In de, this message translates to:
  /// **'Federweg, Rahmen, Setup-Basics — für Amateure'**
  String get garageTechHint;

  /// No description provided for @garageCtaMaintenance.
  ///
  /// In de, this message translates to:
  /// **'Wartung ansehen'**
  String get garageCtaMaintenance;

  /// No description provided for @garageCtaAddPart.
  ///
  /// In de, this message translates to:
  /// **'Teil hinzufügen'**
  String get garageCtaAddPart;

  /// No description provided for @garageCtaSetActive.
  ///
  /// In de, this message translates to:
  /// **'Als aktiv setzen'**
  String get garageCtaSetActive;

  /// No description provided for @garageCtaOpenSetup.
  ///
  /// In de, this message translates to:
  /// **'Zum Setup'**
  String get garageCtaOpenSetup;

  /// No description provided for @garageHours.
  ///
  /// In de, this message translates to:
  /// **'Stunden'**
  String get garageHours;

  /// No description provided for @garageTravel.
  ///
  /// In de, this message translates to:
  /// **'Federweg'**
  String get garageTravel;

  /// No description provided for @garageFrameSize.
  ///
  /// In de, this message translates to:
  /// **'Rahmengröße'**
  String get garageFrameSize;

  /// No description provided for @garageWheelSize.
  ///
  /// In de, this message translates to:
  /// **'Laufrad'**
  String get garageWheelSize;

  /// No description provided for @garageBrandModel.
  ///
  /// In de, this message translates to:
  /// **'Modell'**
  String get garageBrandModel;

  /// No description provided for @garageCompatFits.
  ///
  /// In de, this message translates to:
  /// **'Passt {count}'**
  String garageCompatFits(int count);

  /// No description provided for @garageCompatCheck.
  ///
  /// In de, this message translates to:
  /// **'Prüfen {count}'**
  String garageCompatCheck(int count);

  /// No description provided for @garageCompatNoFit.
  ///
  /// In de, this message translates to:
  /// **'Passt nicht {count}'**
  String garageCompatNoFit(int count);

  /// No description provided for @garagePartsEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Teile erfasst. Tippe auf „Teil hinzufügen“, dann erinnern wir dich an Wartung und zeigen, ob Teile zusammenpassen.'**
  String get garagePartsEmpty;

  /// No description provided for @garageMaintEmpty.
  ///
  /// In de, this message translates to:
  /// **'Alles im grünen Bereich — keine Wartung fällig.'**
  String get garageMaintEmpty;

  /// No description provided for @garageSetupTabTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Setup'**
  String get garageSetupTabTitle;

  /// No description provided for @garageSetupTabHint.
  ///
  /// In de, this message translates to:
  /// **'SAG = wie weit die Federung mit deinem Gewicht einsinkt (Richtwert oft ~25–30 %).'**
  String get garageSetupTabHint;

  /// No description provided for @garageYourParts.
  ///
  /// In de, this message translates to:
  /// **'Deine Teile'**
  String get garageYourParts;

  /// No description provided for @garageMissingSlots.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht erfasst (optional)'**
  String get garageMissingSlots;

  /// No description provided for @garageActiveBadge.
  ///
  /// In de, this message translates to:
  /// **'Aktives Bike'**
  String get garageActiveBadge;

  /// No description provided for @garageStatKm.
  ///
  /// In de, this message translates to:
  /// **'KM'**
  String get garageStatKm;

  /// No description provided for @garageStatHours.
  ///
  /// In de, this message translates to:
  /// **'STD.'**
  String get garageStatHours;

  /// No description provided for @garageStatMaint.
  ///
  /// In de, this message translates to:
  /// **'WARTUNG'**
  String get garageStatMaint;

  /// No description provided for @setupVersionsTitle.
  ///
  /// In de, this message translates to:
  /// **'Versionen & Vergleich'**
  String get setupVersionsTitle;

  /// No description provided for @setupVersionsHint.
  ///
  /// In de, this message translates to:
  /// **'Jede Änderung speichert eine neue Version. Du kannst jederzeit zurückwechseln.'**
  String get setupVersionsHint;

  /// No description provided for @setupRiderWeightLabel.
  ///
  /// In de, this message translates to:
  /// **'Fahrergewicht (kg) für Vorlagen'**
  String get setupRiderWeightLabel;

  /// No description provided for @setupNewVersionCta.
  ///
  /// In de, this message translates to:
  /// **'Neue Version'**
  String get setupNewVersionCta;

  /// No description provided for @setupCompareCta.
  ///
  /// In de, this message translates to:
  /// **'Zwei Varianten testen'**
  String get setupCompareCta;

  /// No description provided for @setupCompareHint.
  ///
  /// In de, this message translates to:
  /// **'Legt zwei verdeckte Varianten an (z. B. Zugstufe). Nach ein paar Fahrten siehst du, welche sich besser anfühlt.'**
  String get setupCompareHint;

  /// No description provided for @setupSavedVersions.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Versionen'**
  String get setupSavedVersions;

  /// No description provided for @setupEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Version — starte mit einer Vorlage oder speichere deine Einstellungen.'**
  String get setupEmpty;

  /// No description provided for @setupActiveBadge.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get setupActiveBadge;

  /// No description provided for @setupVersionMeta.
  ///
  /// In de, this message translates to:
  /// **'Version {version}'**
  String setupVersionMeta(int version);

  /// No description provided for @setupUseVersion.
  ///
  /// In de, this message translates to:
  /// **'Nutzen'**
  String get setupUseVersion;

  /// No description provided for @setupForkReboundValue.
  ///
  /// In de, this message translates to:
  /// **'Zug {value}'**
  String setupForkReboundValue(String value);

  /// No description provided for @setupSourceTemplate.
  ///
  /// In de, this message translates to:
  /// **'Vorlage'**
  String get setupSourceTemplate;

  /// No description provided for @setupSourceBaseline.
  ///
  /// In de, this message translates to:
  /// **'Basis'**
  String get setupSourceBaseline;

  /// No description provided for @setupSourceManual.
  ///
  /// In de, this message translates to:
  /// **'Manuell'**
  String get setupSourceManual;

  /// No description provided for @setupTemplatesTitle.
  ///
  /// In de, this message translates to:
  /// **'Vorlagen zum Start'**
  String get setupTemplatesTitle;

  /// No description provided for @setupTemplatesHint.
  ///
  /// In de, this message translates to:
  /// **'Ausgangspunkt — keine persönliche Empfehlung.'**
  String get setupTemplatesHint;

  /// No description provided for @setupApplyTemplate.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get setupApplyTemplate;

  /// No description provided for @setupNewVersionTitle.
  ///
  /// In de, this message translates to:
  /// **'Neue Setup-Version'**
  String get setupNewVersionTitle;

  /// No description provided for @setupNewVersionHint.
  ///
  /// In de, this message translates to:
  /// **'Gib der Version einen Namen, den du wiedererkennst — z. B. „Trail trocken“.'**
  String get setupNewVersionHint;

  /// No description provided for @setupVersionNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get setupVersionNameLabel;

  /// No description provided for @setupForkReboundLabel.
  ///
  /// In de, this message translates to:
  /// **'Gabel Zugstufe (Klicks)'**
  String get setupForkReboundLabel;

  /// No description provided for @setupCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get setupCancel;

  /// No description provided for @setupSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get setupSave;

  /// No description provided for @setupNewVersionDefaultName.
  ///
  /// In de, this message translates to:
  /// **'Version {n}'**
  String setupNewVersionDefaultName(int n);

  /// No description provided for @setupManualFallback.
  ///
  /// In de, this message translates to:
  /// **'Manuell'**
  String get setupManualFallback;

  /// No description provided for @setupTemplateAppliedLabel.
  ///
  /// In de, this message translates to:
  /// **'{label} (Vorlage)'**
  String setupTemplateAppliedLabel(String label);

  /// No description provided for @setupTemplateAppliedSnack.
  ///
  /// In de, this message translates to:
  /// **'Vorlage übernommen — {disclaimer}'**
  String setupTemplateAppliedSnack(String disclaimer);

  /// No description provided for @setupCompareVariantA.
  ///
  /// In de, this message translates to:
  /// **'Testvariante A'**
  String get setupCompareVariantA;

  /// No description provided for @setupCompareVariantB.
  ///
  /// In de, this message translates to:
  /// **'Testvariante B'**
  String get setupCompareVariantB;

  /// No description provided for @setupCompareResultFromRides.
  ///
  /// In de, this message translates to:
  /// **'Varianten angelegt · Auswertung aus {count} Fahrten: {summary}'**
  String setupCompareResultFromRides(int count, String summary);

  /// No description provided for @setupCompareResultDemo.
  ///
  /// In de, this message translates to:
  /// **'Varianten angelegt · noch wenig Fahr-Feedback — Beispiel-Auswertung: {summary}'**
  String setupCompareResultDemo(String summary);

  /// No description provided for @rideMap.
  ///
  /// In de, this message translates to:
  /// **'Karte'**
  String get rideMap;

  /// No description provided for @rideData.
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get rideData;

  /// No description provided for @rideLiveData.
  ///
  /// In de, this message translates to:
  /// **'Live-Daten'**
  String get rideLiveData;

  /// No description provided for @rideMapReady.
  ///
  /// In de, this message translates to:
  /// **'Karte bereit — Sensor optional nach Start'**
  String get rideMapReady;

  /// No description provided for @rideClearRoute.
  ///
  /// In de, this message translates to:
  /// **'Route entfernen'**
  String get rideClearRoute;

  /// No description provided for @postRideTitle.
  ///
  /// In de, this message translates to:
  /// **'Aktivität'**
  String get postRideTitle;

  /// No description provided for @postRideFreeride.
  ///
  /// In de, this message translates to:
  /// **'Freeride'**
  String get postRideFreeride;

  /// No description provided for @postRideTrackMap.
  ///
  /// In de, this message translates to:
  /// **'Gefahrener Track'**
  String get postRideTrackMap;

  /// No description provided for @postRideNoTrack.
  ///
  /// In de, this message translates to:
  /// **'Kein GPS-Track — Karte zeigt keinen Verlauf.'**
  String get postRideNoTrack;

  /// No description provided for @postRideStatDistance.
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get postRideStatDistance;

  /// No description provided for @postRideStatDuration.
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get postRideStatDuration;

  /// No description provided for @postRideStatPace.
  ///
  /// In de, this message translates to:
  /// **'Tempo'**
  String get postRideStatPace;

  /// No description provided for @postRideStatElevation.
  ///
  /// In de, this message translates to:
  /// **'Höhenmeter'**
  String get postRideStatElevation;

  /// No description provided for @postRideWeatherTitle.
  ///
  /// In de, this message translates to:
  /// **'Wetter'**
  String get postRideWeatherTitle;

  /// No description provided for @postRideWeatherStart.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get postRideWeatherStart;

  /// No description provided for @postRideWeatherEnd.
  ///
  /// In de, this message translates to:
  /// **'Ende'**
  String get postRideWeatherEnd;

  /// No description provided for @postRideWeatherUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Wetter nicht verfügbar'**
  String get postRideWeatherUnavailable;

  /// No description provided for @postRidePhotosTitle.
  ///
  /// In de, this message translates to:
  /// **'Fotos'**
  String get postRidePhotosTitle;

  /// No description provided for @postRidePhotosHint.
  ///
  /// In de, this message translates to:
  /// **'Bilder zur Fahrt hinzufügen — lokal gespeichert.'**
  String get postRidePhotosHint;

  /// No description provided for @postRidePhotoCamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera'**
  String get postRidePhotoCamera;

  /// No description provided for @postRidePhotoGallery.
  ///
  /// In de, this message translates to:
  /// **'Galerie'**
  String get postRidePhotoGallery;

  /// No description provided for @postRidePhotosShare.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get postRidePhotosShare;

  /// No description provided for @postRidePhotosShareText.
  ///
  /// In de, this message translates to:
  /// **'Meine AetherRide-Fahrt'**
  String get postRidePhotosShareText;

  /// No description provided for @postRidePhotosEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Fotos zum Teilen'**
  String get postRidePhotosEmpty;

  /// No description provided for @postRidePhotosMax.
  ///
  /// In de, this message translates to:
  /// **'Maximal {count} Fotos'**
  String postRidePhotosMax(int count);

  /// No description provided for @postRideCommunityStub.
  ///
  /// In de, this message translates to:
  /// **'Community-Feed folgt — Fotos bleiben lokal; teilen über die System-Share-Sheet.'**
  String get postRideCommunityStub;

  /// No description provided for @postRideSaveAsTour.
  ///
  /// In de, this message translates to:
  /// **'Als Tour speichern'**
  String get postRideSaveAsTour;

  /// No description provided for @postRideSaveAsTourDone.
  ///
  /// In de, this message translates to:
  /// **'In Meine Strecken gespeichert'**
  String get postRideSaveAsTourDone;

  /// No description provided for @postRideSaveAsTourNeedTrack.
  ///
  /// In de, this message translates to:
  /// **'Zum Speichern braucht es einen GPS-Track.'**
  String get postRideSaveAsTourNeedTrack;

  /// No description provided for @postRideSaveAsTourHint.
  ///
  /// In de, this message translates to:
  /// **'Speichert den Track als eigene Strecke (Import/Recorded) — sichtbar in Touren.'**
  String get postRideSaveAsTourHint;

  /// No description provided for @myRoutesTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Strecken'**
  String get myRoutesTitle;

  /// No description provided for @myRoutesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine eigenen Strecken — GPX importieren oder eine Fahrt aufzeichnen.'**
  String get myRoutesEmpty;

  /// No description provided for @myRoutesSourceImport.
  ///
  /// In de, this message translates to:
  /// **'Import'**
  String get myRoutesSourceImport;

  /// No description provided for @myRoutesSourceRecorded.
  ///
  /// In de, this message translates to:
  /// **'Aufgezeichnet'**
  String get myRoutesSourceRecorded;

  /// No description provided for @myRoutesSourceEngine.
  ///
  /// In de, this message translates to:
  /// **'Geplant'**
  String get myRoutesSourceEngine;

  /// No description provided for @myRoutesShowOnMap.
  ///
  /// In de, this message translates to:
  /// **'Eigene auf Karte'**
  String get myRoutesShowOnMap;

  /// No description provided for @myRoutesHideOnMap.
  ///
  /// In de, this message translates to:
  /// **'Eigene ausblenden'**
  String get myRoutesHideOnMap;

  /// No description provided for @myRouteNotesTitle.
  ///
  /// In de, this message translates to:
  /// **'Kommentare'**
  String get myRouteNotesTitle;

  /// No description provided for @myRouteNotesHint.
  ///
  /// In de, this message translates to:
  /// **'Lokale Notizen an dieser Strecke. Öffentliche Community-Kommentare folgen mit Konto.'**
  String get myRouteNotesHint;

  /// No description provided for @myRouteNotesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Kommentare.'**
  String get myRouteNotesEmpty;

  /// No description provided for @myRouteNotesPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'Kommentar schreiben…'**
  String get myRouteNotesPlaceholder;

  /// No description provided for @myRouteNotesAdd.
  ///
  /// In de, this message translates to:
  /// **'Senden'**
  String get myRouteNotesAdd;

  /// No description provided for @myRouteDetailPhotos.
  ///
  /// In de, this message translates to:
  /// **'Fotos'**
  String get myRouteDetailPhotos;

  /// No description provided for @myRouteOpenDetail.
  ///
  /// In de, this message translates to:
  /// **'Details'**
  String get myRouteOpenDetail;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
