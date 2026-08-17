import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

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
    Locale('en'),
    Locale('fr'),
    Locale('it')
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'FlowLine'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In de, this message translates to:
  /// **'Ride further. Flow better — MTB, Gravel, Rennrad, City & E-Bike.'**
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

  /// No description provided for @navPlatz.
  ///
  /// In de, this message translates to:
  /// **'Platz'**
  String get navPlatz;

  /// No description provided for @navTabOf.
  ///
  /// In de, this message translates to:
  /// **'Tab {index} von {count}'**
  String navTabOf(int index, int count);

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

  /// No description provided for @werkstattPartsForBike.
  ///
  /// In de, this message translates to:
  /// **'Teile für dein Rad'**
  String get werkstattPartsForBike;

  /// No description provided for @shopLookupInShop.
  ///
  /// In de, this message translates to:
  /// **'Im Laden nachschlagen'**
  String get shopLookupInShop;

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
  /// **'Hier wohnt das Rad nicht. FlowLine zeigt ehrliche Teile — Kauf und Kasse bei Shopify, nicht in der App.'**
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

  /// No description provided for @shopMerchTitle.
  ///
  /// In de, this message translates to:
  /// **'Kleidung'**
  String get shopMerchTitle;

  /// No description provided for @shopMerchEmpty.
  ///
  /// In de, this message translates to:
  /// **'Kein Merch im Regal. Kleidung bleibt im Shop, nie nach dem Rad gefiltert.'**
  String get shopMerchEmpty;

  /// No description provided for @shopNotConnected.
  ///
  /// In de, this message translates to:
  /// **'Shop nicht verbunden'**
  String get shopNotConnected;

  /// No description provided for @shopNotConnectedHint.
  ///
  /// In de, this message translates to:
  /// **'Keine Storefront-URL. SHOPIFY_STOREFRONT_URL setzen, dann öffnet die Werkstatt den Laden.'**
  String get shopNotConnectedHint;

  /// No description provided for @shopOpenFailed.
  ///
  /// In de, this message translates to:
  /// **'Shop konnte nicht geöffnet werden.'**
  String get shopOpenFailed;

  /// No description provided for @shopPasswordWall.
  ///
  /// In de, this message translates to:
  /// **'Der Shop draußen ist noch nicht öffentlich — manchmal steht ein Passwort. Das Regal hier bleibt.'**
  String get shopPasswordWall;

  /// No description provided for @shopLockedTitle.
  ///
  /// In de, this message translates to:
  /// **'Shop draußen noch zu'**
  String get shopLockedTitle;

  /// No description provided for @shopPasswordConfirm.
  ///
  /// In de, this message translates to:
  /// **'Trotzdem öffnen'**
  String get shopPasswordConfirm;

  /// No description provided for @shopPasswordCancel.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get shopPasswordCancel;

  /// No description provided for @shopCyclingParts.
  ///
  /// In de, this message translates to:
  /// **'Teile'**
  String get shopCyclingParts;

  /// No description provided for @shopSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Teile, Marken, Maße…'**
  String get shopSearchHint;

  /// No description provided for @shopFeatured.
  ///
  /// In de, this message translates to:
  /// **'Passende Teile'**
  String get shopFeatured;

  /// No description provided for @shopOpenProduct.
  ///
  /// In de, this message translates to:
  /// **'Im Shop öffnen'**
  String get shopOpenProduct;

  /// No description provided for @shopAllParts.
  ///
  /// In de, this message translates to:
  /// **'Alle Teile'**
  String get shopAllParts;

  /// No description provided for @shopFitBanner.
  ///
  /// In de, this message translates to:
  /// **'Teile passend zu {name}'**
  String shopFitBanner(String name);

  /// No description provided for @shopShelfEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Teile zu dieser Suche.'**
  String get shopShelfEmpty;

  /// No description provided for @shopCatalogEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Teile im Regal. Der Laden bleibt die Tür zu Shopify.'**
  String get shopCatalogEmpty;

  /// No description provided for @shopFitOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur passende'**
  String get shopFitOnly;

  /// No description provided for @shopFitAllBikes.
  ///
  /// In de, this message translates to:
  /// **'Alle Räder'**
  String get shopFitAllBikes;

  /// No description provided for @shopFitBannerAll.
  ///
  /// In de, this message translates to:
  /// **'Teile passend zu deinen Rädern'**
  String get shopFitBannerAll;

  /// No description provided for @shopOpenInBrowser.
  ///
  /// In de, this message translates to:
  /// **'Im Browser öffnen'**
  String get shopOpenInBrowser;

  /// No description provided for @shopZumHaendler.
  ///
  /// In de, this message translates to:
  /// **'Zum Händler'**
  String get shopZumHaendler;

  /// No description provided for @shopOpenInApp.
  ///
  /// In de, this message translates to:
  /// **'Im Laden ansehen'**
  String get shopOpenInApp;

  /// No description provided for @shopProductMissing.
  ///
  /// In de, this message translates to:
  /// **'Dieses Produkt liegt nicht im Laden.'**
  String get shopProductMissing;

  /// No description provided for @shopCatalogFailed.
  ///
  /// In de, this message translates to:
  /// **'Katalog gerade nicht erreichbar. Der Laden bleibt die Tür zu Shopify.'**
  String get shopCatalogFailed;

  /// No description provided for @shopRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut laden'**
  String get shopRetry;

  /// No description provided for @shopSheetCheckout.
  ///
  /// In de, this message translates to:
  /// **'Kauf und Kasse bei Shopify, nicht in FlowLine.'**
  String get shopSheetCheckout;

  /// No description provided for @shopDetails.
  ///
  /// In de, this message translates to:
  /// **'Details'**
  String get shopDetails;

  /// No description provided for @shopFeaturedBikes.
  ///
  /// In de, this message translates to:
  /// **'Räder im Laden'**
  String get shopFeaturedBikes;

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
  /// **'Puls nur mit echtem Sensor.'**
  String get hofWatchHint;

  /// No description provided for @hofWatchPair.
  ///
  /// In de, this message translates to:
  /// **'Uhr koppeln'**
  String get hofWatchPair;

  /// No description provided for @hofWatchReconnect.
  ///
  /// In de, this message translates to:
  /// **'Verbinden'**
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
  /// **'Live featured-parts in FlowLine — Soft-Fit & Preise, ohne Shopify-Passwort-Dead-End.'**
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

  /// No description provided for @hofGateWetClosed.
  ///
  /// In de, this message translates to:
  /// **'Trails nass — kein ehrlicher Asphalt-Rundkurs in der Nähe'**
  String get hofGateWetClosed;

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

  /// No description provided for @hofAgoMinutes.
  ///
  /// In de, this message translates to:
  /// **'vor {minutes} min'**
  String hofAgoMinutes(int minutes);

  /// No description provided for @hofAgoHours.
  ///
  /// In de, this message translates to:
  /// **'vor {hours} Std.'**
  String hofAgoHours(int hours);

  /// No description provided for @hofWhatCameIn.
  ///
  /// In de, this message translates to:
  /// **'Was reinkam'**
  String get hofWhatCameIn;

  /// No description provided for @hofPackMissing.
  ///
  /// In de, this message translates to:
  /// **'Pack für {name} fehlt'**
  String hofPackMissing(String name);

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

  /// No description provided for @hofGarageType.
  ///
  /// In de, this message translates to:
  /// **'Typ {type}'**
  String hofGarageType(String type);

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

  /// No description provided for @hofGateAwayKm.
  ///
  /// In de, this message translates to:
  /// **'{km} km'**
  String hofGateAwayKm(int km);

  /// No description provided for @hofGateAwayNear.
  ///
  /// In de, this message translates to:
  /// **'unter 1 km'**
  String get hofGateAwayNear;

  /// No description provided for @hofCommunityNotes.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Stimme zu dieser Runde} other{{count} Stimmen zu dieser Runde}}'**
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

  /// No description provided for @filterFormAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get filterFormAll;

  /// No description provided for @filterFormPointToPoint.
  ///
  /// In de, this message translates to:
  /// **'A→B'**
  String get filterFormPointToPoint;

  /// No description provided for @filterFormPointToPointTooltip.
  ///
  /// In de, this message translates to:
  /// **'Etappen und lineare Trails (Start≠Ziel).'**
  String get filterFormPointToPointTooltip;

  /// No description provided for @filterFormDownhill.
  ///
  /// In de, this message translates to:
  /// **'Downhill'**
  String get filterFormDownhill;

  /// No description provided for @filterFormDownhillTooltip.
  ///
  /// In de, this message translates to:
  /// **'Abfahrten, Bikepark, Enduro A→B. Rundkurse nicht automatisch DH.'**
  String get filterFormDownhillTooltip;

  /// No description provided for @filterBikeType.
  ///
  /// In de, this message translates to:
  /// **'Fahrradtyp'**
  String get filterBikeType;

  /// No description provided for @filterBikeTypeHonesty.
  ///
  /// In de, this message translates to:
  /// **'Farben filtern die Touren. Navigieren: eine Rad-Route, außer zu Fuß.'**
  String get filterBikeTypeHonesty;

  /// No description provided for @filterSingletrail.
  ///
  /// In de, this message translates to:
  /// **'Singletrail (S-Skala)'**
  String get filterSingletrail;

  /// No description provided for @filterSingletrailHint.
  ///
  /// In de, this message translates to:
  /// **'Nur Touren/Wege mit ehrlicher Skala. Ohne Tag: keine Treffer.'**
  String get filterSingletrailHint;

  /// No description provided for @filterNoDownhillTours.
  ///
  /// In de, this message translates to:
  /// **'Keine Downhill-Touren in der Nähe'**
  String get filterNoDownhillTours;

  /// No description provided for @filterNoDownhillToursHint.
  ///
  /// In de, this message translates to:
  /// **'OSM-Trails nach S-Skala bleiben auf der Karte. Katalog hat hier keine DH-Runde.'**
  String get filterNoDownhillToursHint;

  /// No description provided for @filterNoScaleTours.
  ///
  /// In de, this message translates to:
  /// **'Keine Tour mit dieser S-Stufe'**
  String get filterNoScaleTours;

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
  /// **'Nur Rundkurse — Start und Ziel gleich.'**
  String get filterLoopsOnlyTooltip;

  /// No description provided for @filterNetworkOn.
  ///
  /// In de, this message translates to:
  /// **'Wege auf der Karte'**
  String get filterNetworkOn;

  /// No description provided for @filterNetworkOff.
  ///
  /// In de, this message translates to:
  /// **'Wege ausblenden'**
  String get filterNetworkOff;

  /// No description provided for @filterOsmScaleTooltip.
  ///
  /// In de, this message translates to:
  /// **'OSM-Skala: {code}'**
  String filterOsmScaleTooltip(String code);

  /// No description provided for @filterShowTours.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Tour zeigen} other{{count} Touren zeigen}}'**
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
  /// **'Navigieren'**
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
  /// **'Zwischenstopp'**
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
  /// **'Ort oder Dauer anpassen — oder Filter zurücksetzen.'**
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
  /// **'Rad anlegen'**
  String get garageFabBike;

  /// No description provided for @garageEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Rad hier'**
  String get garageEmptyTitle;

  /// No description provided for @garageEmptyMessage.
  ///
  /// In de, this message translates to:
  /// **'Name und Typ reichen. Katalog ist Suche — Serienteile nur wenn du sie übernimmst.'**
  String get garageEmptyMessage;

  /// No description provided for @garageAddBike.
  ///
  /// In de, this message translates to:
  /// **'Rad anlegen'**
  String get garageAddBike;

  /// No description provided for @garageAddAnother.
  ///
  /// In de, this message translates to:
  /// **'Weiteres Rad'**
  String get garageAddAnother;

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
  /// **'Karte liegt. Sensor danach, wenn du willst.'**
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
  /// **'Meine FlowLine-Fahrt'**
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
  /// **'Fotos bleiben lokal. Stimmen hängen an der Tour, nicht in einem Feed.'**
  String get postRideCommunityStub;

  /// No description provided for @postRideOpenTour.
  ///
  /// In de, this message translates to:
  /// **'Tour öffnen'**
  String get postRideOpenTour;

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
  /// **'Private Notiz'**
  String get myRouteNotesTitle;

  /// No description provided for @myRouteNotesHint.
  ///
  /// In de, this message translates to:
  /// **'Nur für dich. Öffentliche Stimmen erst nach Freigabe, unter Stimmen.'**
  String get myRouteNotesHint;

  /// No description provided for @myRouteNotesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Notiz.'**
  String get myRouteNotesEmpty;

  /// No description provided for @myRouteNotesPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'Nur für dich — keine Stimme.'**
  String get myRouteNotesPlaceholder;

  /// No description provided for @myRouteNotesAdd.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
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

  /// No description provided for @collectionRouteCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, one{1 Route · tippen zum Öffnen} other{{count} Routen · tippen zum Öffnen}}'**
  String collectionRouteCount(int count);

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get add;

  /// No description provided for @skip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get next;

  /// No description provided for @onLabel.
  ///
  /// In de, this message translates to:
  /// **'An'**
  String get onLabel;

  /// No description provided for @offLabel.
  ///
  /// In de, this message translates to:
  /// **'Aus'**
  String get offLabel;

  /// No description provided for @signIn.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get signOut;

  /// No description provided for @account.
  ///
  /// In de, this message translates to:
  /// **'Konto'**
  String get account;

  /// No description provided for @register.
  ///
  /// In de, this message translates to:
  /// **'Registrieren'**
  String get register;

  /// No description provided for @edit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get edit;

  /// No description provided for @share.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get share;

  /// No description provided for @done.
  ///
  /// In de, this message translates to:
  /// **'Erledigt'**
  String get done;

  /// No description provided for @authSignedInSyncing.
  ///
  /// In de, this message translates to:
  /// **'Angemeldet — synchronisiere…'**
  String get authSignedInSyncing;

  /// No description provided for @authSignedInSyncFailed.
  ///
  /// In de, this message translates to:
  /// **'Angemeldet. Sync: {error}'**
  String authSignedInSyncFailed(String error);

  /// No description provided for @authCloudUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Sync ist gerade nicht verfügbar.'**
  String get authCloudUnavailable;

  /// No description provided for @authEmailPasswordRequired.
  ///
  /// In de, this message translates to:
  /// **'E-Mail und Passwort (min. 8 Zeichen) nötig.'**
  String get authEmailPasswordRequired;

  /// No description provided for @authAccountCreatedConfirm.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellt — ggf. E-Mail bestätigen, dann anmelden.'**
  String get authAccountCreatedConfirm;

  /// No description provided for @authSupabaseMissing.
  ///
  /// In de, this message translates to:
  /// **'Supabase nicht konfiguriert.'**
  String get authSupabaseMissing;

  /// No description provided for @authBrowserOpened.
  ///
  /// In de, this message translates to:
  /// **'Browser geöffnet — nach Login kehrst du automatisch zurück.'**
  String get authBrowserOpened;

  /// No description provided for @authDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen?'**
  String get authDeleteTitle;

  /// No description provided for @authDeleteBody.
  ///
  /// In de, this message translates to:
  /// **'Remote-Konto und lokale App-Daten werden gelöscht. Exportiere vorher GPX/JSON unter Daten & Privatsphäre.'**
  String get authDeleteBody;

  /// No description provided for @authRemoteDeleted.
  ///
  /// In de, this message translates to:
  /// **'Remote-Konto gelöscht.'**
  String get authRemoteDeleted;

  /// No description provided for @authRemoteUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Remote-Löschung nicht verfügbar — nur lokale Daten entfernt.'**
  String get authRemoteUnavailable;

  /// No description provided for @authRemoteFailed.
  ///
  /// In de, this message translates to:
  /// **'Remote-Löschung fehlgeschlagen ({code}) — lokal trotzdem gelöscht.'**
  String authRemoteFailed(int code);

  /// No description provided for @authRemoteUnreachable.
  ///
  /// In de, this message translates to:
  /// **'Server nicht erreichbar — nur lokale Daten entfernt.'**
  String get authRemoteUnreachable;

  /// No description provided for @authLocalDeleted.
  ///
  /// In de, this message translates to:
  /// **'Lokale Daten gelöscht. Export ggf. unter Privatsphäre nachholen.'**
  String get authLocalDeleted;

  /// No description provided for @authEmail.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get authEmail;

  /// No description provided for @authEmailHint.
  ///
  /// In de, this message translates to:
  /// **'E-Mail-Adresse'**
  String get authEmailHint;

  /// No description provided for @authPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get authPassword;

  /// No description provided for @authCreateAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto erstellen'**
  String get authCreateAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In de, this message translates to:
  /// **'Schon ein Konto? Anmelden'**
  String get authHaveAccount;

  /// No description provided for @authNewHere.
  ///
  /// In de, this message translates to:
  /// **'Neu hier? Registrieren'**
  String get authNewHere;

  /// No description provided for @authWithGoogle.
  ///
  /// In de, this message translates to:
  /// **'Mit Google'**
  String get authWithGoogle;

  /// No description provided for @authWithApple.
  ///
  /// In de, this message translates to:
  /// **'Mit Apple'**
  String get authWithApple;

  /// No description provided for @authPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Daten & Privatsphäre'**
  String get authPrivacy;

  /// No description provided for @authOpenAssistant.
  ///
  /// In de, this message translates to:
  /// **'Assistent öffnen'**
  String get authOpenAssistant;

  /// No description provided for @authDeleteAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get authDeleteAccount;

  /// No description provided for @authSyncNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt synchronisieren'**
  String get authSyncNow;

  /// No description provided for @authSyncing.
  ///
  /// In de, this message translates to:
  /// **'Synchronisiere…'**
  String get authSyncing;

  /// No description provided for @authSyncOk.
  ///
  /// In de, this message translates to:
  /// **'Sync OK'**
  String get authSyncOk;

  /// No description provided for @authSyncActive.
  ///
  /// In de, this message translates to:
  /// **'Sync mit {api} ist aktiv.'**
  String authSyncActive(String api);

  /// No description provided for @authCreating.
  ///
  /// In de, this message translates to:
  /// **'Erstelle…'**
  String get authCreating;

  /// No description provided for @authSigningIn.
  ///
  /// In de, this message translates to:
  /// **'Melde an…'**
  String get authSigningIn;

  /// No description provided for @billingTitle.
  ///
  /// In de, this message translates to:
  /// **'FlowLine Pro'**
  String get billingTitle;

  /// No description provided for @billingYouHavePro.
  ///
  /// In de, this message translates to:
  /// **'Du hast Pro.'**
  String get billingYouHavePro;

  /// No description provided for @billingFreeToPro.
  ///
  /// In de, this message translates to:
  /// **'Free → Pro'**
  String get billingFreeToPro;

  /// No description provided for @billingMoreBikes.
  ///
  /// In de, this message translates to:
  /// **'Mehr Bikes, Sync-Vorteile und Offline-Regionen.'**
  String get billingMoreBikes;

  /// No description provided for @billingAlreadyPro.
  ///
  /// In de, this message translates to:
  /// **'Pro ist bereits aktiv — kein erneuter Kauf nötig.'**
  String get billingAlreadyPro;

  /// No description provided for @billingForceProDebug.
  ///
  /// In de, this message translates to:
  /// **'Debug: Force-Pro. Stripe/Play bleiben ausgeblendet.'**
  String get billingForceProDebug;

  /// No description provided for @billingStripeMonth.
  ///
  /// In de, this message translates to:
  /// **'Stripe — monatlich'**
  String get billingStripeMonth;

  /// No description provided for @billingStripeYear.
  ///
  /// In de, this message translates to:
  /// **'Stripe — jährlich'**
  String get billingStripeYear;

  /// No description provided for @billingPlayMonth.
  ///
  /// In de, this message translates to:
  /// **'Google Play — monatlich'**
  String get billingPlayMonth;

  /// No description provided for @billingPlayRestore.
  ///
  /// In de, this message translates to:
  /// **'Play-Käufe wiederherstellen'**
  String get billingPlayRestore;

  /// No description provided for @billingPlayHint.
  ///
  /// In de, this message translates to:
  /// **'Hinweis: Ohne GOOGLE_PLAY_SERVICE_ACCOUNT_JSON prüft der Server Käufe nicht gegen Google.'**
  String get billingPlayHint;

  /// No description provided for @billingSyncStatus.
  ///
  /// In de, this message translates to:
  /// **'Abo-Status synchronisieren'**
  String get billingSyncStatus;

  /// No description provided for @billingSyncAfterPurchase.
  ///
  /// In de, this message translates to:
  /// **'Nach Kauf synchronisieren'**
  String get billingSyncAfterPurchase;

  /// No description provided for @billingPleaseSignIn.
  ///
  /// In de, this message translates to:
  /// **'Bitte zuerst anmelden.'**
  String get billingPleaseSignIn;

  /// No description provided for @billingNoCheckoutUrl.
  ///
  /// In de, this message translates to:
  /// **'Keine Checkout-URL'**
  String get billingNoCheckoutUrl;

  /// No description provided for @billingBrowserFailed.
  ///
  /// In de, this message translates to:
  /// **'Browser konnte nicht geöffnet werden'**
  String get billingBrowserFailed;

  /// No description provided for @billingCheckoutOpened.
  ///
  /// In de, this message translates to:
  /// **'Checkout geöffnet — danach „Sync after purchase“.'**
  String get billingCheckoutOpened;

  /// No description provided for @billingPlayOnlyAndroid.
  ///
  /// In de, this message translates to:
  /// **'Play Billing nur auf Android.'**
  String get billingPlayOnlyAndroid;

  /// No description provided for @billingPlayStarted.
  ///
  /// In de, this message translates to:
  /// **'Play-Kauf gestartet…'**
  String get billingPlayStarted;

  /// No description provided for @billingVerifying.
  ///
  /// In de, this message translates to:
  /// **'Kauf wird verifiziert…'**
  String get billingVerifying;

  /// No description provided for @billingProTrusted.
  ///
  /// In de, this message translates to:
  /// **'Pro gesetzt (Trusted-Token-MVP — ohne Google Play Service Account). Sync OK.'**
  String get billingProTrusted;

  /// No description provided for @billingProActive.
  ///
  /// In de, this message translates to:
  /// **'Pro aktiv. Sync läuft.'**
  String get billingProActive;

  /// No description provided for @billingRestoring.
  ///
  /// In de, this message translates to:
  /// **'Käufe werden wiederhergestellt…'**
  String get billingRestoring;

  /// No description provided for @billingRestoreStarted.
  ///
  /// In de, this message translates to:
  /// **'Restore gestartet — gültige Abos werden verifiziert.'**
  String get billingRestoreStarted;

  /// No description provided for @billingSyncOkTier.
  ///
  /// In de, this message translates to:
  /// **'Sync OK — Tarif: {tier}'**
  String billingSyncOkTier(String tier);

  /// No description provided for @billingPlayError.
  ///
  /// In de, this message translates to:
  /// **'Play: {error}'**
  String billingPlayError(String error);

  /// No description provided for @billingSyncError.
  ///
  /// In de, this message translates to:
  /// **'Sync: {error}'**
  String billingSyncError(String error);

  /// No description provided for @billingRestoreError.
  ///
  /// In de, this message translates to:
  /// **'Restore: {error}'**
  String billingRestoreError(String error);

  /// No description provided for @chatAssistant.
  ///
  /// In de, this message translates to:
  /// **'Assistent'**
  String get chatAssistant;

  /// No description provided for @chatWelcome.
  ///
  /// In de, this message translates to:
  /// **'Frag mich, was ansteht — oder zu Setup, Routen und Teilen.'**
  String get chatWelcome;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Frag mich'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptyMessage.
  ///
  /// In de, this message translates to:
  /// **'Was ansteht, Setup, Routen oder Teile — probier einen Vorschlag oben oder tipp direkt los.'**
  String get chatEmptyMessage;

  /// No description provided for @chatLockedRiding.
  ///
  /// In de, this message translates to:
  /// **'Während der Fahrt ist Chat gesperrt.'**
  String get chatLockedRiding;

  /// No description provided for @chatHint.
  ///
  /// In de, this message translates to:
  /// **'Nachricht…'**
  String get chatHint;

  /// No description provided for @chatHintLocked.
  ///
  /// In de, this message translates to:
  /// **'Gesperrt während Ride'**
  String get chatHintLocked;

  /// No description provided for @chatAsk.
  ///
  /// In de, this message translates to:
  /// **'Fragen'**
  String get chatAsk;

  /// No description provided for @chatSnooze7.
  ///
  /// In de, this message translates to:
  /// **'7 Tage still'**
  String get chatSnooze7;

  /// No description provided for @chatNoAnswer.
  ///
  /// In de, this message translates to:
  /// **'Keine Antwort.'**
  String get chatNoAnswer;

  /// No description provided for @chatUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Der Assistent ist gerade nicht erreichbar. Versuch\'s später noch einmal.'**
  String get chatUnavailable;

  /// No description provided for @chatNetworkError.
  ///
  /// In de, this message translates to:
  /// **'Netzwerkfehler: {error}'**
  String chatNetworkError(String error);

  /// No description provided for @chatErrorStatus.
  ///
  /// In de, this message translates to:
  /// **'Fehler {code}'**
  String chatErrorStatus(int code);

  /// No description provided for @chatLimitReached.
  ///
  /// In de, this message translates to:
  /// **'Limit erreicht.'**
  String get chatLimitReached;

  /// No description provided for @chatQuota.
  ///
  /// In de, this message translates to:
  /// **'Kontingent: {used} / {limit} · noch {remaining}'**
  String chatQuota(String used, String limit, String remaining);

  /// No description provided for @chatToolDev.
  ///
  /// In de, this message translates to:
  /// **'Werkzeug (Entwickler)'**
  String get chatToolDev;

  /// No description provided for @chatToolAuto.
  ///
  /// In de, this message translates to:
  /// **'Auto'**
  String get chatToolAuto;

  /// No description provided for @chatPromptWatch.
  ///
  /// In de, this message translates to:
  /// **'Was steht an?'**
  String get chatPromptWatch;

  /// No description provided for @chatPromptWatchQuery.
  ///
  /// In de, this message translates to:
  /// **'Was steht an?'**
  String get chatPromptWatchQuery;

  /// No description provided for @chatPromptGarage.
  ///
  /// In de, this message translates to:
  /// **'Garage'**
  String get chatPromptGarage;

  /// No description provided for @chatPromptGarageQuery.
  ///
  /// In de, this message translates to:
  /// **'Was steckt in meiner Garage?'**
  String get chatPromptGarageQuery;

  /// No description provided for @chatPromptRange.
  ///
  /// In de, this message translates to:
  /// **'Reichweite'**
  String get chatPromptRange;

  /// No description provided for @chatPromptRangeQuery.
  ///
  /// In de, this message translates to:
  /// **'Welche Reichweite habe ich mit aktuellem Akku?'**
  String get chatPromptRangeQuery;

  /// No description provided for @chatPromptSetups.
  ///
  /// In de, this message translates to:
  /// **'Setups'**
  String get chatPromptSetups;

  /// No description provided for @chatPromptSetupsQuery.
  ///
  /// In de, this message translates to:
  /// **'Welche Setups hatte ich und was hat sich geändert?'**
  String get chatPromptSetupsQuery;

  /// No description provided for @chatPromptRides.
  ///
  /// In de, this message translates to:
  /// **'Fahrten'**
  String get chatPromptRides;

  /// No description provided for @chatPromptRidesQuery.
  ///
  /// In de, this message translates to:
  /// **'Zusammenfassung meiner letzten Fahrten'**
  String get chatPromptRidesQuery;

  /// No description provided for @chatPromptRoutes.
  ///
  /// In de, this message translates to:
  /// **'Routen'**
  String get chatPromptRoutes;

  /// No description provided for @chatPromptRoutesQuery.
  ///
  /// In de, this message translates to:
  /// **'Welche Routen passen zu mir?'**
  String get chatPromptRoutesQuery;

  /// No description provided for @chatPromptShop.
  ///
  /// In de, this message translates to:
  /// **'Laden'**
  String get chatPromptShop;

  /// No description provided for @chatPromptShopQuery.
  ///
  /// In de, this message translates to:
  /// **'Brauche ich bald neue Verschleißteile?'**
  String get chatPromptShopQuery;

  /// No description provided for @chatToolWatch.
  ///
  /// In de, this message translates to:
  /// **'Was steht an'**
  String get chatToolWatch;

  /// No description provided for @chatToolGarage.
  ///
  /// In de, this message translates to:
  /// **'Werkstatt'**
  String get chatToolGarage;

  /// No description provided for @chatToolCompat.
  ///
  /// In de, this message translates to:
  /// **'Kompatibilität'**
  String get chatToolCompat;

  /// No description provided for @chatToolRange.
  ///
  /// In de, this message translates to:
  /// **'Reichweite'**
  String get chatToolRange;

  /// No description provided for @chatToolSetupHistory.
  ///
  /// In de, this message translates to:
  /// **'Setup-Historie'**
  String get chatToolSetupHistory;

  /// No description provided for @chatToolRides.
  ///
  /// In de, this message translates to:
  /// **'Fahrten'**
  String get chatToolRides;

  /// No description provided for @chatToolRoutes.
  ///
  /// In de, this message translates to:
  /// **'Routen'**
  String get chatToolRoutes;

  /// No description provided for @chatToolShop.
  ///
  /// In de, this message translates to:
  /// **'Laden'**
  String get chatToolShop;

  /// No description provided for @chatSubtitleDue.
  ///
  /// In de, this message translates to:
  /// **'Was ansteht, Setup, Routen, Teile'**
  String get chatSubtitleDue;

  /// No description provided for @coachHintsTooltip.
  ///
  /// In de, this message translates to:
  /// **'{count} Hinweise'**
  String coachHintsTooltip(int count);

  /// No description provided for @privacyTitle.
  ///
  /// In de, this message translates to:
  /// **'Daten & Privatsphäre'**
  String get privacyTitle;

  /// No description provided for @privacyConsents.
  ///
  /// In de, this message translates to:
  /// **'Einwilligungen'**
  String get privacyConsents;

  /// No description provided for @privacyHud.
  ///
  /// In de, this message translates to:
  /// **'HUD'**
  String get privacyHud;

  /// No description provided for @privacyZones.
  ///
  /// In de, this message translates to:
  /// **'Privacy-Zonen'**
  String get privacyZones;

  /// No description provided for @privacyZoneAdd.
  ///
  /// In de, this message translates to:
  /// **'Zone'**
  String get privacyZoneAdd;

  /// No description provided for @privacyNoZones.
  ///
  /// In de, this message translates to:
  /// **'Keine Zonen — Start/Ziel-Umgebung kann getrimmt werden.'**
  String get privacyNoZones;

  /// No description provided for @privacyZoneRadius.
  ///
  /// In de, this message translates to:
  /// **'{label} Radius'**
  String privacyZoneRadius(String label);

  /// No description provided for @privacyZoneDelete.
  ///
  /// In de, this message translates to:
  /// **'Zone löschen'**
  String get privacyZoneDelete;

  /// No description provided for @privacyFamilyHint.
  ///
  /// In de, this message translates to:
  /// **'Familien-Link / Mitfahrer: unter Profil → Familien-Garage weitere Fahrer mit eigenem Gewicht anlegen.'**
  String get privacyFamilyHint;

  /// No description provided for @privacyExportTitle.
  ///
  /// In de, this message translates to:
  /// **'Export (Art. 20)'**
  String get privacyExportTitle;

  /// No description provided for @privacyExportGpx.
  ///
  /// In de, this message translates to:
  /// **'Letzter Ride als GPX'**
  String get privacyExportGpx;

  /// No description provided for @privacyExportFit.
  ///
  /// In de, this message translates to:
  /// **'Letzter Ride als FIT'**
  String get privacyExportFit;

  /// No description provided for @privacyExportJson.
  ///
  /// In de, this message translates to:
  /// **'JSON-Vollexport'**
  String get privacyExportJson;

  /// No description provided for @privacyExportStravaStub.
  ///
  /// In de, this message translates to:
  /// **'Strava-Payload (lokal, Entwickler)'**
  String get privacyExportStravaStub;

  /// No description provided for @privacyStravaConnect.
  ///
  /// In de, this message translates to:
  /// **'Mit Strava verbinden'**
  String get privacyStravaConnect;

  /// No description provided for @privacyStravaUpload.
  ///
  /// In de, this message translates to:
  /// **'Letzten Ride zu Strava'**
  String get privacyStravaUpload;

  /// No description provided for @privacyStravaLiveHint.
  ///
  /// In de, this message translates to:
  /// **'Live-Upload nutzt gespeicherte OAuth-Tokens (Server).'**
  String get privacyStravaLiveHint;

  /// No description provided for @privacyStravaOauthHint.
  ///
  /// In de, this message translates to:
  /// **'OAuth öffnet den Browser; nach Freigabe App fortsetzen.'**
  String get privacyStravaOauthHint;

  /// No description provided for @privacyStravaMissing.
  ///
  /// In de, this message translates to:
  /// **'Strava ist nicht eingerichtet. GPX, FIT und JSON sind die Exportwege.'**
  String get privacyStravaMissing;

  /// No description provided for @privacyStravaConnected.
  ///
  /// In de, this message translates to:
  /// **'Strava verbunden'**
  String get privacyStravaConnected;

  /// No description provided for @privacyStravaCallback.
  ///
  /// In de, this message translates to:
  /// **'Strava-Callback empfangen'**
  String get privacyStravaCallback;

  /// No description provided for @privacyStravaStatus.
  ///
  /// In de, this message translates to:
  /// **'Strava: {status}'**
  String privacyStravaStatus(String status);

  /// No description provided for @privacyStravaUnreachable.
  ///
  /// In de, this message translates to:
  /// **'Strava-Status nicht erreichbar — Stub-Export bleibt lokal'**
  String get privacyStravaUnreachable;

  /// No description provided for @privacyStravaUrlMissing.
  ///
  /// In de, this message translates to:
  /// **'Strava-Authorize-URL fehlt — einloggen und erneut versuchen.'**
  String get privacyStravaUrlMissing;

  /// No description provided for @privacyStravaBrowser.
  ///
  /// In de, this message translates to:
  /// **'Strava im Browser — nach Freigabe zurück zur App, Status aktualisiert sich.'**
  String get privacyStravaBrowser;

  /// No description provided for @privacyNoRideUpload.
  ///
  /// In de, this message translates to:
  /// **'Kein Ride zum Upload'**
  String get privacyNoRideUpload;

  /// No description provided for @privacyChunksUploaded.
  ///
  /// In de, this message translates to:
  /// **'{n} Chunk(s) hochgeladen, {left} ausstehend'**
  String privacyChunksUploaded(int n, int left);

  /// No description provided for @privacyChunksBlocked.
  ///
  /// In de, this message translates to:
  /// **'Kein Upload (Login/Netz?) — {left} ausstehend'**
  String privacyChunksBlocked(int left);

  /// No description provided for @privacyChunksNone.
  ///
  /// In de, this message translates to:
  /// **'Keine ausstehenden Chunks'**
  String get privacyChunksNone;

  /// No description provided for @privacyHeatmapCells.
  ///
  /// In de, this message translates to:
  /// **'Heatmap: {n} Zellen beigetragen (sichtbar erst ab k≥5).'**
  String privacyHeatmapCells(int n);

  /// No description provided for @privacyHeatmapNone.
  ///
  /// In de, this message translates to:
  /// **'Heatmap: kein Beitrag (Login/Consent/Track prüfen).'**
  String get privacyHeatmapNone;

  /// No description provided for @privacyUploadNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt hochladen'**
  String get privacyUploadNow;

  /// No description provided for @privacyChunksPending.
  ///
  /// In de, this message translates to:
  /// **'Rohdaten-Chunks: {count} ausstehend'**
  String privacyChunksPending(int count);

  /// No description provided for @privacyChunksPendingConsentOff.
  ///
  /// In de, this message translates to:
  /// **'Rohdaten-Chunks: {count} ausstehend (Consent aus)'**
  String privacyChunksPendingConsentOff(int count);

  /// No description provided for @privacySharedGpx.
  ///
  /// In de, this message translates to:
  /// **'GPX geteilt · {path}'**
  String privacySharedGpx(String path);

  /// No description provided for @privacySharedFit.
  ///
  /// In de, this message translates to:
  /// **'FIT geteilt · {path}'**
  String privacySharedFit(String path);

  /// No description provided for @privacySharedStravaStub.
  ///
  /// In de, this message translates to:
  /// **'Strava-Stub geteilt · {path}'**
  String privacySharedStravaStub(String path);

  /// No description provided for @privacyExportSubject.
  ///
  /// In de, this message translates to:
  /// **'FlowLine Export'**
  String get privacyExportSubject;

  /// No description provided for @privacyNoRideExporting.
  ///
  /// In de, this message translates to:
  /// **'Kein Ride zum Exportieren.'**
  String get privacyNoRideExporting;

  /// No description provided for @privacySharedJson.
  ///
  /// In de, this message translates to:
  /// **'JSON geteilt · {path}'**
  String privacySharedJson(String path);

  /// No description provided for @privacyNoRideExport.
  ///
  /// In de, this message translates to:
  /// **'Kein Ride zum Exportieren.'**
  String get privacyNoRideExport;

  /// No description provided for @consentRawTitle.
  ///
  /// In de, this message translates to:
  /// **'Rohdaten-Upload'**
  String get consentRawTitle;

  /// No description provided for @consentRawBody.
  ///
  /// In de, this message translates to:
  /// **'Sensor-Rohdaten nur bei WLAN und wenn du zustimmst. Jederzeit widerrufbar.'**
  String get consentRawBody;

  /// No description provided for @consentHeatmapTitle.
  ///
  /// In de, this message translates to:
  /// **'Heatmap (eigene Fahrten, anonym)'**
  String get consentHeatmapTitle;

  /// No description provided for @consentHeatmapBody.
  ///
  /// In de, this message translates to:
  /// **'Lokal: deine Fahrten. Mit Konto: anonymisierte Zellen ohne Zeitstempel. Die Beliebtheitskarte erscheint erst, wenn genug Fahrer in einer Zelle unterwegs waren (k≥5).'**
  String get consentHeatmapBody;

  /// No description provided for @consentRecoTitle.
  ///
  /// In de, this message translates to:
  /// **'Produktempfehlungen'**
  String get consentRecoTitle;

  /// No description provided for @consentRecoBody.
  ///
  /// In de, this message translates to:
  /// **'Nur anlassbezogen, mit nachvollziehbarem Datenpunkt. Kein Tracking-Marketing.'**
  String get consentRecoBody;

  /// No description provided for @consentAnalyticsTitle.
  ///
  /// In de, this message translates to:
  /// **'Analytics'**
  String get consentAnalyticsTitle;

  /// No description provided for @consentAnalyticsBody.
  ///
  /// In de, this message translates to:
  /// **'Produktmetriken ohne Gesundheits- oder Rohsensordaten.'**
  String get consentAnalyticsBody;

  /// No description provided for @consentHealthTitle.
  ///
  /// In de, this message translates to:
  /// **'Gesundheitsdaten'**
  String get consentHealthTitle;

  /// No description provided for @consentHealthBody.
  ///
  /// In de, this message translates to:
  /// **'Vorbereitung — noch keine Anbindung an Health Connect. Die Einwilligung speichert nur deine Präferenz für später.'**
  String get consentHealthBody;

  /// No description provided for @privacyZoneTapHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf die Karte, um die Zone zu setzen.'**
  String get privacyZoneTapHint;

  /// No description provided for @privacyZoneRadiusHint.
  ///
  /// In de, this message translates to:
  /// **'Radius gilt für Export und Heatmap.'**
  String get privacyZoneRadiusHint;

  /// No description provided for @privacyZoneLabel.
  ///
  /// In de, this message translates to:
  /// **'Label'**
  String get privacyZoneLabel;

  /// No description provided for @privacyZoneRadiusWord.
  ///
  /// In de, this message translates to:
  /// **'Radius'**
  String get privacyZoneRadiusWord;

  /// No description provided for @privacyZoneApplyCoords.
  ///
  /// In de, this message translates to:
  /// **'Koordinaten übernehmen'**
  String get privacyZoneApplyCoords;

  /// No description provided for @privacyZoneCoords.
  ///
  /// In de, this message translates to:
  /// **'Koordinaten'**
  String get privacyZoneCoords;

  /// No description provided for @privacyZoneCoordsHint.
  ///
  /// In de, this message translates to:
  /// **'Nur falls du den Punkt zahlenbasiert setzen willst'**
  String get privacyZoneCoordsHint;

  /// No description provided for @profilePictureSet.
  ///
  /// In de, this message translates to:
  /// **'Profilbild gesetzt'**
  String get profilePictureSet;

  /// No description provided for @profileSaved.
  ///
  /// In de, this message translates to:
  /// **'Profil gespeichert'**
  String get profileSaved;

  /// No description provided for @profileLocalOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur lokal — zum Sync anmelden'**
  String get profileLocalOnly;

  /// No description provided for @profileSyncCloudKept.
  ///
  /// In de, this message translates to:
  /// **'Sync: Cloud übernommen'**
  String get profileSyncCloudKept;

  /// No description provided for @profileSyncDeviceUploaded.
  ///
  /// In de, this message translates to:
  /// **'Sync: Gerät hochgeladen'**
  String get profileSyncDeviceUploaded;

  /// No description provided for @profileSyncCurrent.
  ///
  /// In de, this message translates to:
  /// **'Sync: aktuell'**
  String get profileSyncCurrent;

  /// No description provided for @profileSyncConflictTitle.
  ///
  /// In de, this message translates to:
  /// **'Sync-Konflikt'**
  String get profileSyncConflictTitle;

  /// No description provided for @profileSyncConflictBody.
  ///
  /// In de, this message translates to:
  /// **'Cloud und dieses Gerät unterscheiden sich.\nCloud: {when}\n\nWelche Version soll gelten?'**
  String profileSyncConflictBody(String when);

  /// No description provided for @profileKeepCloud.
  ///
  /// In de, this message translates to:
  /// **'Cloud behalten'**
  String get profileKeepCloud;

  /// No description provided for @profileForceDevice.
  ///
  /// In de, this message translates to:
  /// **'Gerät erzwingen'**
  String get profileForceDevice;

  /// No description provided for @profileConflictCloud.
  ///
  /// In de, this message translates to:
  /// **'Konflikt: Cloud behalten'**
  String get profileConflictCloud;

  /// No description provided for @profileConflictDevice.
  ///
  /// In de, this message translates to:
  /// **'Konflikt: Gerät erzwingen'**
  String get profileConflictDevice;

  /// No description provided for @profileSyncCancelled.
  ///
  /// In de, this message translates to:
  /// **'Sync abgebrochen'**
  String get profileSyncCancelled;

  /// No description provided for @profileSignInForBilling.
  ///
  /// In de, this message translates to:
  /// **'Bitte anmelden für Aboverwaltung'**
  String get profileSignInForBilling;

  /// No description provided for @profileNoStripeSub.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Stripe-Abo — zuerst Pro upgraden.'**
  String get profileNoStripeSub;

  /// No description provided for @profilePortalError.
  ///
  /// In de, this message translates to:
  /// **'Portal: {code}'**
  String profilePortalError(int code);

  /// No description provided for @profileNoPortalUrl.
  ///
  /// In de, this message translates to:
  /// **'Keine Portal-URL'**
  String get profileNoPortalUrl;

  /// No description provided for @profileFamilyRiderTitle.
  ///
  /// In de, this message translates to:
  /// **'Familien-Fahrer'**
  String get profileFamilyRiderTitle;

  /// No description provided for @profileName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profileWeightKg.
  ///
  /// In de, this message translates to:
  /// **'Gewicht kg'**
  String get profileWeightKg;

  /// No description provided for @profileRiderAdded.
  ///
  /// In de, this message translates to:
  /// **'Fahrer hinzugefügt'**
  String get profileRiderAdded;

  /// No description provided for @profileRiderFallback.
  ///
  /// In de, this message translates to:
  /// **'Fahrer'**
  String get profileRiderFallback;

  /// No description provided for @profileActiveBike.
  ///
  /// In de, this message translates to:
  /// **'Aktiv: {name} · {category}'**
  String profileActiveBike(String name, String category);

  /// No description provided for @profileDisciplines.
  ///
  /// In de, this message translates to:
  /// **'Deine Disziplinen'**
  String get profileDisciplines;

  /// No description provided for @profileDisciplinesHint.
  ///
  /// In de, this message translates to:
  /// **'Vorlieben für Touren. Routing folgt dem aktiven Rad, nicht dieser Liste allein.'**
  String get profileDisciplinesHint;

  /// No description provided for @profileRiderCard.
  ///
  /// In de, this message translates to:
  /// **'Fahrerprofil'**
  String get profileRiderCard;

  /// No description provided for @profilePublic.
  ///
  /// In de, this message translates to:
  /// **'Öffentlich'**
  String get profilePublic;

  /// No description provided for @profileAccountSync.
  ///
  /// In de, this message translates to:
  /// **'Konto & Sync'**
  String get profileAccountSync;

  /// No description provided for @profileCloudBilling.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Sync & Abo'**
  String get profileCloudBilling;

  /// No description provided for @profileSignedIn.
  ///
  /// In de, this message translates to:
  /// **'Angemeldet'**
  String get profileSignedIn;

  /// No description provided for @profileFamilyGarage.
  ///
  /// In de, this message translates to:
  /// **'Familien-Garage'**
  String get profileFamilyGarage;

  /// No description provided for @profileFamilyHint.
  ///
  /// In de, this message translates to:
  /// **'Weitere Fahrer mit eigenem Gewicht — z. B. Partner oder Kind.'**
  String get profileFamilyHint;

  /// No description provided for @profileLegal.
  ///
  /// In de, this message translates to:
  /// **'Rechtliches'**
  String get profileLegal;

  /// No description provided for @profilePrivacyPolicy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get profilePrivacyPolicy;

  /// No description provided for @profileImprint.
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get profileImprint;

  /// No description provided for @profileWithdrawal.
  ///
  /// In de, this message translates to:
  /// **'Widerruf'**
  String get profileWithdrawal;

  /// No description provided for @profileSetPrimary.
  ///
  /// In de, this message translates to:
  /// **'Als Haupt-Disziplin setzen'**
  String get profileSetPrimary;

  /// No description provided for @profilePrimarySuffix.
  ///
  /// In de, this message translates to:
  /// **'{label} · Haupt'**
  String profilePrimarySuffix(String label);

  /// No description provided for @profileNeedOneDiscipline.
  ///
  /// In de, this message translates to:
  /// **'Mindestens eine Disziplin bleibt gewählt.'**
  String get profileNeedOneDiscipline;

  /// No description provided for @profileLocalUntilSignIn.
  ///
  /// In de, this message translates to:
  /// **'Lokal — Sync nach Anmeldung'**
  String get profileLocalUntilSignIn;

  /// No description provided for @profileChangePhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto ändern'**
  String get profileChangePhoto;

  /// No description provided for @profileActivityLabel.
  ///
  /// In de, this message translates to:
  /// **'Aktivität — letzte Fahrten auf dem Hof'**
  String get profileActivityLabel;

  /// No description provided for @profileBikeOne.
  ///
  /// In de, this message translates to:
  /// **'Bike'**
  String get profileBikeOne;

  /// No description provided for @profileBikes.
  ///
  /// In de, this message translates to:
  /// **'Bikes'**
  String get profileBikes;

  /// No description provided for @profileRideOne.
  ///
  /// In de, this message translates to:
  /// **'Ride'**
  String get profileRideOne;

  /// No description provided for @profileRides.
  ///
  /// In de, this message translates to:
  /// **'Rides'**
  String get profileRides;

  /// No description provided for @profileKmTotal.
  ///
  /// In de, this message translates to:
  /// **'km gesamt'**
  String get profileKmTotal;

  /// No description provided for @profileKmElevation.
  ///
  /// In de, this message translates to:
  /// **'km · {hm} hm'**
  String profileKmElevation(int hm);

  /// No description provided for @profileProActive.
  ///
  /// In de, this message translates to:
  /// **'FlowLine Pro aktiv'**
  String get profileProActive;

  /// No description provided for @profileManage.
  ///
  /// In de, this message translates to:
  /// **'Verwalten'**
  String get profileManage;

  /// No description provided for @profileProPerks.
  ///
  /// In de, this message translates to:
  /// **'Offline-Karten, unbegrenzte Bikes, Fahrwerksanalyse & Bracketing.'**
  String get profileProPerks;

  /// No description provided for @profileUpgradePro.
  ///
  /// In de, this message translates to:
  /// **'Pro upgraden'**
  String get profileUpgradePro;

  /// No description provided for @profileDisplayName.
  ///
  /// In de, this message translates to:
  /// **'Anzeigename'**
  String get profileDisplayName;

  /// No description provided for @profileRiderWeight.
  ///
  /// In de, this message translates to:
  /// **'Fahrergewicht (kg)'**
  String get profileRiderWeight;

  /// No description provided for @profileRideStyle.
  ///
  /// In de, this message translates to:
  /// **'Fahrstil'**
  String get profileRideStyle;

  /// No description provided for @profileSkillBeginner.
  ///
  /// In de, this message translates to:
  /// **'Einsteiger'**
  String get profileSkillBeginner;

  /// No description provided for @profileSkillBasics.
  ///
  /// In de, this message translates to:
  /// **'Grundlagen'**
  String get profileSkillBasics;

  /// No description provided for @profileSkillAdvanced.
  ///
  /// In de, this message translates to:
  /// **'Fortgeschritten'**
  String get profileSkillAdvanced;

  /// No description provided for @profileSkillExperienced.
  ///
  /// In de, this message translates to:
  /// **'Erfahren'**
  String get profileSkillExperienced;

  /// No description provided for @profileSkillPro.
  ///
  /// In de, this message translates to:
  /// **'Profi'**
  String get profileSkillPro;

  /// No description provided for @profileSubGarage.
  ///
  /// In de, this message translates to:
  /// **'Garage'**
  String get profileSubGarage;

  /// No description provided for @profileSubWeight.
  ///
  /// In de, this message translates to:
  /// **'Fahrergewicht'**
  String get profileSubWeight;

  /// No description provided for @profileSubSkill.
  ///
  /// In de, this message translates to:
  /// **'Können ({skill} / 5)'**
  String profileSubSkill(int skill);

  /// No description provided for @profileStyleEfficientPace.
  ///
  /// In de, this message translates to:
  /// **'Effizient / Tempo'**
  String get profileStyleEfficientPace;

  /// No description provided for @profileStyleSteady.
  ///
  /// In de, this message translates to:
  /// **'Gleichmäßig'**
  String get profileStyleSteady;

  /// No description provided for @profileStyleExploring.
  ///
  /// In de, this message translates to:
  /// **'Entdeckend'**
  String get profileStyleExploring;

  /// No description provided for @profileStyleCommute.
  ///
  /// In de, this message translates to:
  /// **'Alltag / Pendeln'**
  String get profileStyleCommute;

  /// No description provided for @profileStyleTours.
  ///
  /// In de, this message translates to:
  /// **'Touren'**
  String get profileStyleTours;

  /// No description provided for @profileStyleRelaxed.
  ///
  /// In de, this message translates to:
  /// **'Locker'**
  String get profileStyleRelaxed;

  /// No description provided for @profileStyleAggressive.
  ///
  /// In de, this message translates to:
  /// **'Aggressiv'**
  String get profileStyleAggressive;

  /// No description provided for @profileStyleFlow.
  ///
  /// In de, this message translates to:
  /// **'Flow'**
  String get profileStyleFlow;

  /// No description provided for @profileStyleLines.
  ///
  /// In de, this message translates to:
  /// **'Linien suchen'**
  String get profileStyleLines;

  /// No description provided for @profileStyleEfficient.
  ///
  /// In de, this message translates to:
  /// **'Effizient'**
  String get profileStyleEfficient;

  /// No description provided for @profileDisciplinesSaved.
  ///
  /// In de, this message translates to:
  /// **'Disziplinen: {list}'**
  String profileDisciplinesSaved(String list);

  /// No description provided for @profileAlsoList.
  ///
  /// In de, this message translates to:
  /// **'auch {list}'**
  String profileAlsoList(String list);

  /// No description provided for @publicProfileTitle.
  ///
  /// In de, this message translates to:
  /// **'Öffentliches Profil'**
  String get publicProfileTitle;

  /// No description provided for @publicProfileHint.
  ///
  /// In de, this message translates to:
  /// **'Opt-in. Handle an Stimmen, keine Tracks, kein Tab.'**
  String get publicProfileHint;

  /// No description provided for @publicProfileHandle.
  ///
  /// In de, this message translates to:
  /// **'Handle'**
  String get publicProfileHandle;

  /// No description provided for @publicProfileBio.
  ///
  /// In de, this message translates to:
  /// **'Bio'**
  String get publicProfileBio;

  /// No description provided for @publicProfileRegion.
  ///
  /// In de, this message translates to:
  /// **'Region'**
  String get publicProfileRegion;

  /// No description provided for @publicProfileShowRides.
  ///
  /// In de, this message translates to:
  /// **'Fahrtenzahl zeigen'**
  String get publicProfileShowRides;

  /// No description provided for @publicProfileFoot.
  ///
  /// In de, this message translates to:
  /// **'Kein öffentlicher Track, keine DMs. Handle bleibt lokal bis Sync.'**
  String get publicProfileFoot;

  /// No description provided for @hudMediaTitle.
  ///
  /// In de, this message translates to:
  /// **'Medien im HUD'**
  String get hudMediaTitle;

  /// No description provided for @hudMediaProfileHint.
  ///
  /// In de, this message translates to:
  /// **'Optionaler Zugriff, damit das HUD den aktuellen Titel zeigt. Play/Pause geht oft schon ohne.'**
  String get hudMediaProfileHint;

  /// No description provided for @hudMediaPrivacyHint.
  ///
  /// In de, this message translates to:
  /// **'Einstellung unter Profil. Optionaler Zugriff auf die Medien-Session für den Titel im HUD.'**
  String get hudMediaPrivacyHint;

  /// No description provided for @onboardHowYouRide.
  ///
  /// In de, this message translates to:
  /// **'Wie fährst du?'**
  String get onboardHowYouRide;

  /// No description provided for @onboardYourWeight.
  ///
  /// In de, this message translates to:
  /// **'Dein Gewicht'**
  String get onboardYourWeight;

  /// No description provided for @onboardFirstRide.
  ///
  /// In de, this message translates to:
  /// **'Erste Fahrt'**
  String get onboardFirstRide;

  /// No description provided for @onboardWeightHint.
  ///
  /// In de, this message translates to:
  /// **'Für Setup, SAG & Reichweite — nur lokal, jederzeit änderbar. Auch ohne Federgabel sinnvoll (z. B. City).'**
  String get onboardWeightHint;

  /// No description provided for @onboardGpsHint.
  ///
  /// In de, this message translates to:
  /// **'Echter GPS-Track — ohne Demo. Bike optional. MTB, Gravel, Rennrad oder City: gleich gut.'**
  String get onboardGpsHint;

  /// No description provided for @onboardGpsStatus.
  ///
  /// In de, this message translates to:
  /// **'Standort für GPS-Track…'**
  String get onboardGpsStatus;

  /// No description provided for @onboardServicesOff.
  ///
  /// In de, this message translates to:
  /// **'Ortungsdienste einschalten, dann erneut versuchen.'**
  String get onboardServicesOff;

  /// No description provided for @onboardDeniedForever.
  ///
  /// In de, this message translates to:
  /// **'Standort in den App-Einstellungen erlauben.'**
  String get onboardDeniedForever;

  /// No description provided for @onboardNeedGps.
  ///
  /// In de, this message translates to:
  /// **'Standort erlauben — ohne GPS kein Track.'**
  String get onboardNeedGps;

  /// No description provided for @onboardWeightLabel.
  ///
  /// In de, this message translates to:
  /// **'Fahrergewicht: {kg} kg'**
  String onboardWeightLabel(int kg);

  /// No description provided for @onboardDiscipline.
  ///
  /// In de, this message translates to:
  /// **'Disziplin: {label}'**
  String onboardDiscipline(String label);

  /// No description provided for @onboardSensorsHint.
  ///
  /// In de, this message translates to:
  /// **'Standort für den GPS-Track. Bluetooth-Sensoren später in der Werkstatt — gilt für alle Bike-Typen.'**
  String get onboardSensorsHint;

  /// No description provided for @onboardNextRide.
  ///
  /// In de, this message translates to:
  /// **'Weiter zur Fahrt'**
  String get onboardNextRide;

  /// No description provided for @onboardParkBikeFirst.
  ///
  /// In de, this message translates to:
  /// **'Zuerst Rad abstellen'**
  String get onboardParkBikeFirst;

  /// No description provided for @onboardLater.
  ///
  /// In de, this message translates to:
  /// **'Später einrichten'**
  String get onboardLater;

  /// No description provided for @offlineMapsTitle.
  ///
  /// In de, this message translates to:
  /// **'Offline-Karten'**
  String get offlineMapsTitle;

  /// No description provided for @offlineMapsHint.
  ///
  /// In de, this message translates to:
  /// **'Lädt Routing und Kartenkacheln für die Region. Ohne Netz: geladene Karte und Routing im Gebiet.'**
  String get offlineMapsHint;

  /// No description provided for @offlineRegionActive.
  ///
  /// In de, this message translates to:
  /// **'Region aktiv'**
  String get offlineRegionActive;

  /// No description provided for @offlineNoRegion.
  ///
  /// In de, this message translates to:
  /// **'Keine Region aktiv'**
  String get offlineNoRegion;

  /// No description provided for @offlineReadyBoth.
  ///
  /// In de, this message translates to:
  /// **'Routing + Kartenkacheln bereit.'**
  String get offlineReadyBoth;

  /// No description provided for @offlineReadyRouting.
  ///
  /// In de, this message translates to:
  /// **'Routing bereit — Karte noch nicht offline.'**
  String get offlineReadyRouting;

  /// No description provided for @offlineLoadBelow.
  ///
  /// In de, this message translates to:
  /// **'Unten ein gebautes Pack laden.'**
  String get offlineLoadBelow;

  /// No description provided for @offlineRegions.
  ///
  /// In de, this message translates to:
  /// **'Regionen'**
  String get offlineRegions;

  /// No description provided for @offlineSearchRegion.
  ///
  /// In de, this message translates to:
  /// **'Region suchen'**
  String get offlineSearchRegion;

  /// No description provided for @offlineNoneFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Region gefunden'**
  String get offlineNoneFound;

  /// No description provided for @offlineNoPacks.
  ///
  /// In de, this message translates to:
  /// **'Keine ladbaren Packs. Stubs unten — kein Demo-Graph unter fremdem Namen.'**
  String get offlineNoPacks;

  /// No description provided for @offlineNotBuilt.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht gebaut ({count})'**
  String offlineNotBuilt(int count);

  /// No description provided for @offlineStubsHint.
  ///
  /// In de, this message translates to:
  /// **'Catalog-Stubs — Download deaktiviert'**
  String get offlineStubsHint;

  /// No description provided for @offlineRemoveRegion.
  ///
  /// In de, this message translates to:
  /// **'Region entfernen'**
  String get offlineRemoveRegion;

  /// No description provided for @offlineStyleTitle.
  ///
  /// In de, this message translates to:
  /// **'Kartenstil (optional)'**
  String get offlineStyleTitle;

  /// No description provided for @offlineStyleHint.
  ///
  /// In de, this message translates to:
  /// **'Default: DACH z11 Style-JSON. Nur ändern für eigenen MapLibre-Style.'**
  String get offlineStyleHint;

  /// No description provided for @offlineStyleUrl.
  ///
  /// In de, this message translates to:
  /// **'Style-JSON-URL'**
  String get offlineStyleUrl;

  /// No description provided for @offlineSaveStyle.
  ///
  /// In de, this message translates to:
  /// **'Style speichern'**
  String get offlineSaveStyle;

  /// No description provided for @offlineRegionActiveSnack.
  ///
  /// In de, this message translates to:
  /// **'{name} aktiv'**
  String offlineRegionActiveSnack(String name);

  /// No description provided for @offlineActivateError.
  ///
  /// In de, this message translates to:
  /// **'Aktivieren: {error}'**
  String offlineActivateError(String error);

  /// No description provided for @offlinePackError.
  ///
  /// In de, this message translates to:
  /// **'Region-Pack: {error}'**
  String offlinePackError(String error);

  /// No description provided for @offlineRemoved.
  ///
  /// In de, this message translates to:
  /// **'Region entfernt'**
  String get offlineRemoved;

  /// No description provided for @offlineNoRemoteDach.
  ///
  /// In de, this message translates to:
  /// **'Keine Remote-Packs — DACH-Fallback aktiv'**
  String get offlineNoRemoteDach;

  /// No description provided for @offlineNoBuiltPacks.
  ///
  /// In de, this message translates to:
  /// **'Keine gebauten Packs auf diesem Server'**
  String get offlineNoBuiltPacks;

  /// No description provided for @offlineDachCatalog.
  ///
  /// In de, this message translates to:
  /// **'Offline — DACH-Regionen aus App-Katalog'**
  String get offlineDachCatalog;

  /// No description provided for @offlineReadyMapRouting.
  ///
  /// In de, this message translates to:
  /// **'Karte + Routing bereit'**
  String get offlineReadyMapRouting;

  /// No description provided for @offlineRoutingBg.
  ///
  /// In de, this message translates to:
  /// **'Routing bereit, Karte lädt im Hintergrund'**
  String get offlineRoutingBg;

  /// No description provided for @offlineBasemapFail.
  ///
  /// In de, this message translates to:
  /// **'Routing bereit — Basemap-Download fehlgeschlagen, Karte braucht CDN'**
  String get offlineBasemapFail;

  /// No description provided for @offlineTilesMissing.
  ///
  /// In de, this message translates to:
  /// **'Routing bereit, Kartenkacheln fehlen (Netz/Limit)'**
  String get offlineTilesMissing;

  /// No description provided for @offlineDemoGraph.
  ///
  /// In de, this message translates to:
  /// **'Demo-Graph Schwarzwald aktiv — nicht {name}-Karte'**
  String offlineDemoGraph(String name);

  /// No description provided for @offlineStyleCleared.
  ///
  /// In de, this message translates to:
  /// **'Override gelöscht — Default-Style aktiv'**
  String get offlineStyleCleared;

  /// No description provided for @offlineStyleSaved.
  ///
  /// In de, this message translates to:
  /// **'Style gespeichert. Karte wird neu geladen: {url}'**
  String offlineStyleSaved(String url);

  /// No description provided for @platzTogetherKicker.
  ///
  /// In de, this message translates to:
  /// **'Zusammen raus'**
  String get platzTogetherKicker;

  /// No description provided for @platzTogetherTitle.
  ///
  /// In de, this message translates to:
  /// **'Zusammen raus'**
  String get platzTogetherTitle;

  /// No description provided for @platzTogetherHint.
  ///
  /// In de, this message translates to:
  /// **'Einladen teilt den Link. Deine Gruppen bleiben. Freigegeben listet zusätzlich offene Gruppen auf dem Platz — kein Feed.'**
  String get platzTogetherHint;

  /// No description provided for @platzTogetherListHint.
  ///
  /// In de, this message translates to:
  /// **'Gruppe vor dem Tor. Eingeloggt: auf dem Server. Sonst nur dieses Gerät — der Host sieht dich nicht. Freunde auf der Karte nur während der Fahrt, nach Opt-in.'**
  String get platzTogetherListHint;

  /// No description provided for @platzCreateGroup.
  ///
  /// In de, this message translates to:
  /// **'Gruppe anlegen'**
  String get platzCreateGroup;

  /// No description provided for @platzJoinCode.
  ///
  /// In de, this message translates to:
  /// **'Code'**
  String get platzJoinCode;

  /// No description provided for @platzNoGroup.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Gruppe. Einladen teilt den Link — nichts Vorgespieltes.'**
  String get platzNoGroup;

  /// No description provided for @platzHost.
  ///
  /// In de, this message translates to:
  /// **'Gastgeber'**
  String get platzHost;

  /// No description provided for @platzGuest.
  ///
  /// In de, this message translates to:
  /// **'Gast'**
  String get platzGuest;

  /// No description provided for @platzYou.
  ///
  /// In de, this message translates to:
  /// **'Du'**
  String get platzYou;

  /// No description provided for @platzInvite.
  ///
  /// In de, this message translates to:
  /// **'Einladen'**
  String get platzInvite;

  /// No description provided for @platzDissolve.
  ///
  /// In de, this message translates to:
  /// **'Auflösen'**
  String get platzDissolve;

  /// No description provided for @platzLeave.
  ///
  /// In de, this message translates to:
  /// **'Verlassen'**
  String get platzLeave;

  /// No description provided for @platzCopyLink.
  ///
  /// In de, this message translates to:
  /// **'Link kopieren'**
  String get platzCopyLink;

  /// No description provided for @platzInviteShares.
  ///
  /// In de, this message translates to:
  /// **'Einladen teilt den Gruppenlink'**
  String get platzInviteShares;

  /// No description provided for @platzInviteSharesProfile.
  ///
  /// In de, this message translates to:
  /// **' und dein Platz-Profil'**
  String get platzInviteSharesProfile;

  /// No description provided for @platzInviteAsYou.
  ///
  /// In de, this message translates to:
  /// **'Auf der Einladung stehst du als Du. Namen im Profil festlegen?'**
  String get platzInviteAsYou;

  /// No description provided for @platzInviteAsYouLater.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get platzInviteAsYouLater;

  /// No description provided for @platzInviteOpenProfile.
  ///
  /// In de, this message translates to:
  /// **'Zum Profil'**
  String get platzInviteOpenProfile;

  /// No description provided for @platzMembersCount.
  ///
  /// In de, this message translates to:
  /// **'{count} dabei'**
  String platzMembersCount(int count);

  /// No description provided for @platzOnServer.
  ///
  /// In de, this message translates to:
  /// **'auf dem Server'**
  String get platzOnServer;

  /// No description provided for @platzOnDevice.
  ///
  /// In de, this message translates to:
  /// **'nur auf diesem Gerät'**
  String get platzOnDevice;

  /// No description provided for @platzCollectionDefaultName.
  ///
  /// In de, this message translates to:
  /// **'Sammlung {day}.{month}.'**
  String platzCollectionDefaultName(int day, int month);

  /// No description provided for @platzPinsOff.
  ///
  /// In de, this message translates to:
  /// **'Freunde auf der Karte · aus'**
  String get platzPinsOff;

  /// No description provided for @platzPinsHudOnly.
  ///
  /// In de, this message translates to:
  /// **'Freunde nur während der Fahrt'**
  String get platzPinsHudOnly;

  /// No description provided for @platzCollectionsKicker.
  ///
  /// In de, this message translates to:
  /// **'Sammlungen'**
  String get platzCollectionsKicker;

  /// No description provided for @platzNoCollection.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Sammlung — in der Akte einer Tour anlegen.'**
  String get platzNoCollection;

  /// No description provided for @platzCollectionTours.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tour} other{{count} Touren}}'**
  String platzCollectionTours(int count);

  /// No description provided for @platzCreateCollection.
  ///
  /// In de, this message translates to:
  /// **'Sammlung anlegen'**
  String get platzCreateCollection;

  /// No description provided for @platzJoinWithCode.
  ///
  /// In de, this message translates to:
  /// **'Mit Link beitreten'**
  String get platzJoinWithCode;

  /// No description provided for @platzJoinCodeField.
  ///
  /// In de, this message translates to:
  /// **'Einladungslink'**
  String get platzJoinCodeField;

  /// No description provided for @platzJoinLinkHint.
  ///
  /// In de, this message translates to:
  /// **'Link aus WhatsApp oder Messages einfügen. Privat braucht den Einladungslink — kein Code zum Abtippen.'**
  String get platzJoinLinkHint;

  /// No description provided for @platzJoinEmpty.
  ///
  /// In de, this message translates to:
  /// **'Link fehlt.'**
  String get platzJoinEmpty;

  /// No description provided for @platzJoinInvalid.
  ///
  /// In de, this message translates to:
  /// **'Kein gültiger Einladungslink.'**
  String get platzJoinInvalid;

  /// No description provided for @platzJoin.
  ///
  /// In de, this message translates to:
  /// **'Beitreten'**
  String get platzJoin;

  /// No description provided for @platzStartLabel.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get platzStartLabel;

  /// No description provided for @platzStartNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt'**
  String get platzStartNow;

  /// No description provided for @platzStartIn1h.
  ///
  /// In de, this message translates to:
  /// **'In 1 h'**
  String get platzStartIn1h;

  /// No description provided for @platzStartToday18.
  ///
  /// In de, this message translates to:
  /// **'Heute 18:00'**
  String get platzStartToday18;

  /// No description provided for @platzStartTomorrow10.
  ///
  /// In de, this message translates to:
  /// **'Morgen 10:00'**
  String get platzStartTomorrow10;

  /// No description provided for @platzDurationLabel.
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get platzDurationLabel;

  /// No description provided for @platzMeetingPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'Treffpunkt (optional)'**
  String get platzMeetingPlaceholder;

  /// No description provided for @platzMeetingHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Parkplatz am Bad'**
  String get platzMeetingHint;

  /// No description provided for @platzPinsOnHud.
  ///
  /// In de, this message translates to:
  /// **'Freunde auf der Karte · an'**
  String get platzPinsOnHud;

  /// No description provided for @platzPinsHint.
  ///
  /// In de, this message translates to:
  /// **'Nur während der Fahrt, nicht auf der öffentlichen Karte.'**
  String get platzPinsHint;

  /// No description provided for @platzTourNotInMappe.
  ///
  /// In de, this message translates to:
  /// **'Tour nicht in der Mappe.'**
  String get platzTourNotInMappe;

  /// No description provided for @platzTourNotInMappeHint.
  ///
  /// In de, this message translates to:
  /// **'Katalog-Touren legt Losfahren in die Mappe. Private GPX braucht den Link vom Gastgeber — kein erfundener Track.'**
  String get platzTourNotInMappeHint;

  /// No description provided for @platzCollectionsHint.
  ///
  /// In de, this message translates to:
  /// **'Anlegen in der Akte. Teilen nur mit freigegebenen oder Katalog-Touren — private GPX bleibt draußen.'**
  String get platzCollectionsHint;

  /// No description provided for @akteTourKicker.
  ///
  /// In de, this message translates to:
  /// **'Tour'**
  String get akteTourKicker;

  /// No description provided for @stimmenShareNeedRelease.
  ///
  /// In de, this message translates to:
  /// **'Erst unter Mein freigeben — sonst geht der Link ins Leere.'**
  String get stimmenShareNeedRelease;

  /// No description provided for @platzNeedSharedTour.
  ///
  /// In de, this message translates to:
  /// **'Gruppe nur an freigegebener oder Katalog-Tour. Private GPX bleibt privat.'**
  String get platzNeedSharedTour;

  /// No description provided for @platzShareTourFirst.
  ///
  /// In de, this message translates to:
  /// **'Zuerst eine Tour freigeben'**
  String get platzShareTourFirst;

  /// No description provided for @platzShareTourFirstHint.
  ///
  /// In de, this message translates to:
  /// **'Ohne Freigabe bleibt die Gruppe unsichtbar für Freunde. Tippe eine Tour — in der Akte unter Mein auf Freigeben, dann Gruppe anlegen.'**
  String get platzShareTourFirstHint;

  /// No description provided for @platzHostCannotSee.
  ///
  /// In de, this message translates to:
  /// **'Nur auf diesem Gerät. Der Host sieht dich nicht — anmelden.'**
  String get platzHostCannotSee;

  /// No description provided for @platzJoinLocal.
  ///
  /// In de, this message translates to:
  /// **'Lokal dabei: {title}. Der Host sieht dich nicht — anmelden.'**
  String platzJoinLocal(String title);

  /// No description provided for @platzNoSharedTours.
  ///
  /// In de, this message translates to:
  /// **'Keine freigegebenen oder Katalog-Touren. Private GPX bleibt draußen.'**
  String get platzNoSharedTours;

  /// No description provided for @platzGroupCreated.
  ///
  /// In de, this message translates to:
  /// **'Gruppe {code} — Einladen teilt den Link.'**
  String platzGroupCreated(String code);

  /// No description provided for @platzGroupCreatedNote.
  ///
  /// In de, this message translates to:
  /// **'Gruppe {code} — {note}'**
  String platzGroupCreatedNote(String code, String note);

  /// No description provided for @platzShareSubject.
  ///
  /// In de, this message translates to:
  /// **'Zusammen raus: {title}'**
  String platzShareSubject(String title);

  /// No description provided for @platzLinkCopied.
  ///
  /// In de, this message translates to:
  /// **'Link kopiert. Wer ihn hat, kann beitreten, solange die Gruppe offen ist.'**
  String get platzLinkCopied;

  /// No description provided for @platzWindowClosed.
  ///
  /// In de, this message translates to:
  /// **'Fenster zu'**
  String get platzWindowClosed;

  /// No description provided for @platzWindowHours.
  ///
  /// In de, this message translates to:
  /// **'Fenster {hours} h'**
  String platzWindowHours(int hours);

  /// No description provided for @platzWindowMinutes.
  ///
  /// In de, this message translates to:
  /// **'Fenster {minutes} min'**
  String platzWindowMinutes(int minutes);

  /// No description provided for @platzWindowOpen.
  ///
  /// In de, this message translates to:
  /// **'Fenster offen'**
  String get platzWindowOpen;

  /// No description provided for @platzCollectionShare.
  ///
  /// In de, this message translates to:
  /// **'Sammlung „{name}“: {routes}'**
  String platzCollectionShare(String name, String routes);

  /// No description provided for @rerouteTitle.
  ///
  /// In de, this message translates to:
  /// **'Abseits der Route.'**
  String get rerouteTitle;

  /// No description provided for @rerouteHint.
  ///
  /// In de, this message translates to:
  /// **'Ruhig bleiben — du entscheidest.'**
  String get rerouteHint;

  /// No description provided for @rerouteRejoin.
  ///
  /// In de, this message translates to:
  /// **'Zurück zur Route'**
  String get rerouteRejoin;

  /// No description provided for @rerouteStay.
  ///
  /// In de, this message translates to:
  /// **'Bleiben'**
  String get rerouteStay;

  /// No description provided for @rerouteSkip.
  ///
  /// In de, this message translates to:
  /// **'Abschnitt überspringen'**
  String get rerouteSkip;

  /// No description provided for @bleOff.
  ///
  /// In de, this message translates to:
  /// **'Bluetooth ist aus — bitte einschalten.'**
  String get bleOff;

  /// No description provided for @bleDenied.
  ///
  /// In de, this message translates to:
  /// **'Bluetooth-Berechtigung fehlt.'**
  String get bleDenied;

  /// No description provided for @bleUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Bluetooth LE ist auf diesem Gerät nicht verfügbar.'**
  String get bleUnavailable;

  /// No description provided for @bleScanFailed.
  ///
  /// In de, this message translates to:
  /// **'Suche fehlgeschlagen'**
  String get bleScanFailed;

  /// No description provided for @bleConnecting.
  ///
  /// In de, this message translates to:
  /// **'Verbinde …'**
  String get bleConnecting;

  /// No description provided for @blePairFailed.
  ///
  /// In de, this message translates to:
  /// **'Kopplung fehlgeschlagen'**
  String get blePairFailed;

  /// No description provided for @bleNothingFound.
  ///
  /// In de, this message translates to:
  /// **'Nichts gefunden'**
  String get bleNothingFound;

  /// No description provided for @bleScanAgain.
  ///
  /// In de, this message translates to:
  /// **'Erneut suchen'**
  String get bleScanAgain;

  /// No description provided for @bleHowTo.
  ///
  /// In de, this message translates to:
  /// **'So verbindest du'**
  String get bleHowTo;

  /// No description provided for @watchPairTitle.
  ///
  /// In de, this message translates to:
  /// **'Uhr koppeln'**
  String get watchPairTitle;

  /// No description provided for @watchPairHint.
  ///
  /// In de, this message translates to:
  /// **'Puls nur mit echtem Sensor. Uhr-Akku ist nicht der Rad-Akku.'**
  String get watchPairHint;

  /// No description provided for @watchScanning.
  ///
  /// In de, this message translates to:
  /// **'Suche Uhr und Puls-Gurt …'**
  String get watchScanning;

  /// No description provided for @watchEmptyHint.
  ///
  /// In de, this message translates to:
  /// **'Broadcast an, Handy nah. Apple Watch sendet keinen Standard-Puls.'**
  String get watchEmptyHint;

  /// No description provided for @watchNoHr.
  ///
  /// In de, this message translates to:
  /// **'Kein Puls-Signal — Broadcast an der Uhr prüfen.'**
  String get watchNoHr;

  /// No description provided for @watchNoDeviceId.
  ///
  /// In de, this message translates to:
  /// **'Verbunden, aber ohne Geräte-ID'**
  String get watchNoDeviceId;

  /// No description provided for @bleBikeTitle.
  ///
  /// In de, this message translates to:
  /// **'Rad koppeln'**
  String get bleBikeTitle;

  /// No description provided for @bleBikeHint.
  ///
  /// In de, this message translates to:
  /// **'Akku und Assist nur bei echtem GATT — nichts erfinden.'**
  String get bleBikeHint;

  /// No description provided for @bleRememberAnyway.
  ///
  /// In de, this message translates to:
  /// **'Trotzdem merken'**
  String get bleRememberAnyway;

  /// No description provided for @bleScanningDrive.
  ///
  /// In de, this message translates to:
  /// **'Suche Antrieb und Sensoren …'**
  String get bleScanningDrive;

  /// No description provided for @bleEmptyEbike.
  ///
  /// In de, this message translates to:
  /// **'Display wecken, Flow oder E-TUBE zu, Handy nah halten.'**
  String get bleEmptyEbike;

  /// No description provided for @bleEmptySensor.
  ///
  /// In de, this message translates to:
  /// **'Sensor in die Nähe legen und am Rad aktivieren (Magnet/Kurbel).'**
  String get bleEmptySensor;

  /// No description provided for @bleConnectFailed.
  ///
  /// In de, this message translates to:
  /// **'Verbindung fehlgeschlagen'**
  String get bleConnectFailed;

  /// No description provided for @dieBoxReady.
  ///
  /// In de, this message translates to:
  /// **'Bereit'**
  String get dieBoxReady;

  /// No description provided for @dieBoxAlmost.
  ///
  /// In de, this message translates to:
  /// **'Fast bereit'**
  String get dieBoxAlmost;

  /// No description provided for @dieBoxUnknown.
  ///
  /// In de, this message translates to:
  /// **'Neu hier'**
  String get dieBoxUnknown;

  /// No description provided for @dieBoxNothingDueMonday.
  ///
  /// In de, this message translates to:
  /// **'Montag-bereit — Licht und Kette sitzen.'**
  String get dieBoxNothingDueMonday;

  /// No description provided for @dieBoxNothingDue.
  ///
  /// In de, this message translates to:
  /// **'Bereit — nichts liegt an.'**
  String get dieBoxNothingDue;

  /// No description provided for @dieBoxCscHint.
  ///
  /// In de, this message translates to:
  /// **'Tacho am Rad koppeln. Die Uhr bleibt beim Fahren.'**
  String get dieBoxCscHint;

  /// No description provided for @dieBoxEmptyHint.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts eingetragen. Name und Typ reichen — Teile nur, wenn sie wirklich dran sind.'**
  String get dieBoxEmptyHint;

  /// No description provided for @dieBoxAddSomething.
  ///
  /// In de, this message translates to:
  /// **'Etwas eintragen'**
  String get dieBoxAddSomething;

  /// No description provided for @dieBoxAddMore.
  ///
  /// In de, this message translates to:
  /// **'Weiteres eintragen'**
  String get dieBoxAddMore;

  /// No description provided for @dieBoxBatteryHint.
  ///
  /// In de, this message translates to:
  /// **'Akkustand erscheint, sobald ein Sensor am Rad koppelt. Bis dahin keine Zahl.'**
  String get dieBoxBatteryHint;

  /// No description provided for @dieBoxPressureTitle.
  ///
  /// In de, this message translates to:
  /// **'Druck merken'**
  String get dieBoxPressureTitle;

  /// No description provided for @dieBoxPressureHint.
  ///
  /// In de, this message translates to:
  /// **'Vorn und hinten am Ventil ablesen.'**
  String get dieBoxPressureHint;

  /// No description provided for @dieBoxPressureFront.
  ///
  /// In de, this message translates to:
  /// **'Vorn'**
  String get dieBoxPressureFront;

  /// No description provided for @dieBoxPressureRear.
  ///
  /// In de, this message translates to:
  /// **'Hinten'**
  String get dieBoxPressureRear;

  /// No description provided for @dieBoxPressureLogged.
  ///
  /// In de, this message translates to:
  /// **'Druck gemerkt'**
  String get dieBoxPressureLogged;

  /// No description provided for @dieBoxSagTitle.
  ///
  /// In de, this message translates to:
  /// **'Federung merken'**
  String get dieBoxSagTitle;

  /// No description provided for @dieBoxSagHint.
  ///
  /// In de, this message translates to:
  /// **'Prozent an Gabel und Dämpfer. SAG ist, wie weit die Federung mit dir einsinkt.'**
  String get dieBoxSagHint;

  /// No description provided for @dieBoxSagFork.
  ///
  /// In de, this message translates to:
  /// **'Gabel SAG %'**
  String get dieBoxSagFork;

  /// No description provided for @dieBoxSagShock.
  ///
  /// In de, this message translates to:
  /// **'Dämpfer SAG %'**
  String get dieBoxSagShock;

  /// No description provided for @dieBoxSagLogged.
  ///
  /// In de, this message translates to:
  /// **'SAG gemerkt'**
  String get dieBoxSagLogged;

  /// No description provided for @dieBoxTravelTitle.
  ///
  /// In de, this message translates to:
  /// **'Federweg eintragen'**
  String get dieBoxTravelTitle;

  /// No description provided for @dieBoxTravelHint.
  ///
  /// In de, this message translates to:
  /// **'Nur der Federweg, der am Rad steht.'**
  String get dieBoxTravelHint;

  /// No description provided for @dieBoxTravelFront.
  ///
  /// In de, this message translates to:
  /// **'Vorn mm'**
  String get dieBoxTravelFront;

  /// No description provided for @dieBoxTravelRear.
  ///
  /// In de, this message translates to:
  /// **'Hinten mm'**
  String get dieBoxTravelRear;

  /// No description provided for @dieBoxTravelSave.
  ///
  /// In de, this message translates to:
  /// **'Eintragen'**
  String get dieBoxTravelSave;

  /// No description provided for @dieBoxChainLogged.
  ///
  /// In de, this message translates to:
  /// **'Kette gemessen'**
  String get dieBoxChainLogged;

  /// No description provided for @dieBoxChainNotes.
  ///
  /// In de, this message translates to:
  /// **'Mit der Lehre gemessen'**
  String get dieBoxChainNotes;

  /// No description provided for @dieBoxSetActiveTitle.
  ///
  /// In de, this message translates to:
  /// **'Dieses Rad nach vorn'**
  String get dieBoxSetActiveTitle;

  /// No description provided for @dieBoxSetActiveHint.
  ///
  /// In de, this message translates to:
  /// **'Eines steht in der Box — Umschalten holt es nach vorn.'**
  String get dieBoxSetActiveHint;

  /// No description provided for @dieBoxSetActiveCta.
  ///
  /// In de, this message translates to:
  /// **'Als aktiv setzen'**
  String get dieBoxSetActiveCta;

  /// No description provided for @dieBoxLightsTitle.
  ///
  /// In de, this message translates to:
  /// **'Licht eintragen'**
  String get dieBoxLightsTitle;

  /// No description provided for @dieBoxLightsHint.
  ///
  /// In de, this message translates to:
  /// **'Nur wenn Licht wirklich am Rad ist.'**
  String get dieBoxLightsHint;

  /// No description provided for @dieBoxLightsCta.
  ///
  /// In de, this message translates to:
  /// **'Licht eintragen'**
  String get dieBoxLightsCta;

  /// No description provided for @dieBoxLockTitle.
  ///
  /// In de, this message translates to:
  /// **'Schloss eintragen'**
  String get dieBoxLockTitle;

  /// No description provided for @dieBoxLockHint.
  ///
  /// In de, this message translates to:
  /// **'Nur wenn ein Schloss am Rad ist.'**
  String get dieBoxLockHint;

  /// No description provided for @dieBoxLockCta.
  ///
  /// In de, this message translates to:
  /// **'Schloss eintragen'**
  String get dieBoxLockCta;

  /// No description provided for @dieBoxRackTitle.
  ///
  /// In de, this message translates to:
  /// **'Träger eintragen'**
  String get dieBoxRackTitle;

  /// No description provided for @dieBoxRackHint.
  ///
  /// In de, this message translates to:
  /// **'Nur wenn das Rad einen Gepäckträger hat.'**
  String get dieBoxRackHint;

  /// No description provided for @dieBoxRackCta.
  ///
  /// In de, this message translates to:
  /// **'Träger eintragen'**
  String get dieBoxRackCta;

  /// No description provided for @dieBoxBagsTitle.
  ///
  /// In de, this message translates to:
  /// **'Taschen eintragen'**
  String get dieBoxBagsTitle;

  /// No description provided for @dieBoxBagsHint.
  ///
  /// In de, this message translates to:
  /// **'Nur wenn Taschen am Rad sind.'**
  String get dieBoxBagsHint;

  /// No description provided for @dieBoxBagsCta.
  ///
  /// In de, this message translates to:
  /// **'Taschen eintragen'**
  String get dieBoxBagsCta;

  /// No description provided for @dieBoxPressureMissingTitle.
  ///
  /// In de, this message translates to:
  /// **'Druck merken'**
  String get dieBoxPressureMissingTitle;

  /// No description provided for @dieBoxPressureMissingHint.
  ///
  /// In de, this message translates to:
  /// **'Vorn und hinten am Ventil ablesen.'**
  String get dieBoxPressureMissingHint;

  /// No description provided for @dieBoxPressureMissingCta.
  ///
  /// In de, this message translates to:
  /// **'Druck merken'**
  String get dieBoxPressureMissingCta;

  /// No description provided for @dieBoxTirePressureTitle.
  ///
  /// In de, this message translates to:
  /// **'Reifendruck merken'**
  String get dieBoxTirePressureTitle;

  /// No description provided for @dieBoxTirePressureHint.
  ///
  /// In de, this message translates to:
  /// **'Vorn und hinten am Ventil ablesen.'**
  String get dieBoxTirePressureHint;

  /// No description provided for @dieBoxTravelMissingTitle.
  ///
  /// In de, this message translates to:
  /// **'Federweg eintragen'**
  String get dieBoxTravelMissingTitle;

  /// No description provided for @dieBoxTravelMissingHint.
  ///
  /// In de, this message translates to:
  /// **'Nur der Federweg, der am Rad steht.'**
  String get dieBoxTravelMissingHint;

  /// No description provided for @dieBoxTravelMissingCta.
  ///
  /// In de, this message translates to:
  /// **'Federweg eintragen'**
  String get dieBoxTravelMissingCta;

  /// No description provided for @dieBoxSagMissingTitle.
  ///
  /// In de, this message translates to:
  /// **'Federung merken'**
  String get dieBoxSagMissingTitle;

  /// No description provided for @dieBoxSagMissingHint.
  ///
  /// In de, this message translates to:
  /// **'Eine Zahl an Gabel und Dämpfer, abgelesen am Rad.'**
  String get dieBoxSagMissingHint;

  /// No description provided for @dieBoxSagMissingCta.
  ///
  /// In de, this message translates to:
  /// **'Federung merken'**
  String get dieBoxSagMissingCta;

  /// No description provided for @dieBoxChainTitle.
  ///
  /// In de, this message translates to:
  /// **'Kette merken'**
  String get dieBoxChainTitle;

  /// No description provided for @dieBoxChainHint.
  ///
  /// In de, this message translates to:
  /// **'Mit der Lehre messen, dann hier merken.'**
  String get dieBoxChainHint;

  /// No description provided for @dieBoxChainCta.
  ///
  /// In de, this message translates to:
  /// **'Kette gemessen'**
  String get dieBoxChainCta;

  /// No description provided for @dieBoxBrakesTitle.
  ///
  /// In de, this message translates to:
  /// **'Bremsen eintragen'**
  String get dieBoxBrakesTitle;

  /// No description provided for @dieBoxBrakesHint.
  ///
  /// In de, this message translates to:
  /// **'Nur wenn Beläge am Rad sind.'**
  String get dieBoxBrakesHint;

  /// No description provided for @dieBoxBrakesCta.
  ///
  /// In de, this message translates to:
  /// **'Bremse eintragen'**
  String get dieBoxBrakesCta;

  /// No description provided for @dieBoxChainDueTitle.
  ///
  /// In de, this message translates to:
  /// **'Kette mit der Lehre prüfen'**
  String get dieBoxChainDueTitle;

  /// No description provided for @dieBoxChainDueHint.
  ///
  /// In de, this message translates to:
  /// **'Anschauen und mit der Lehre messen.'**
  String get dieBoxChainDueHint;

  /// No description provided for @dieBoxParkTrailTitle.
  ///
  /// In de, this message translates to:
  /// **'Park oder Trail'**
  String get dieBoxParkTrailTitle;

  /// No description provided for @dieBoxParkTrailHint.
  ///
  /// In de, this message translates to:
  /// **'Beide Setups sind da — wechseln, wenn du willst.'**
  String get dieBoxParkTrailHint;

  /// No description provided for @dieBoxParkTrailCta.
  ///
  /// In de, this message translates to:
  /// **'Wechseln'**
  String get dieBoxParkTrailCta;

  /// No description provided for @dieBoxChipLight.
  ///
  /// In de, this message translates to:
  /// **'Licht'**
  String get dieBoxChipLight;

  /// No description provided for @dieBoxChipLock.
  ///
  /// In de, this message translates to:
  /// **'Schloss'**
  String get dieBoxChipLock;

  /// No description provided for @dieBoxChipRack.
  ///
  /// In de, this message translates to:
  /// **'Träger'**
  String get dieBoxChipRack;

  /// No description provided for @dieBoxChipBags.
  ///
  /// In de, this message translates to:
  /// **'Taschen'**
  String get dieBoxChipBags;

  /// No description provided for @dieBoxChipTires.
  ///
  /// In de, this message translates to:
  /// **'Reifen'**
  String get dieBoxChipTires;

  /// No description provided for @dieBoxChipDropper.
  ///
  /// In de, this message translates to:
  /// **'Vario'**
  String get dieBoxChipDropper;

  /// No description provided for @dieBoxChipBrakes.
  ///
  /// In de, this message translates to:
  /// **'Bremsen'**
  String get dieBoxChipBrakes;

  /// No description provided for @dieBoxChipParkTrail.
  ///
  /// In de, this message translates to:
  /// **'Park | Trail'**
  String get dieBoxChipParkTrail;

  /// No description provided for @dieBoxChipTravel.
  ///
  /// In de, this message translates to:
  /// **'Federweg'**
  String get dieBoxChipTravel;

  /// No description provided for @dieBoxChipCsc.
  ///
  /// In de, this message translates to:
  /// **'CSC'**
  String get dieBoxChipCsc;

  /// No description provided for @dieBoxChipBatteryHonest.
  ///
  /// In de, this message translates to:
  /// **'Akku ehrlich'**
  String get dieBoxChipBatteryHonest;

  /// No description provided for @dieBoxChipSag.
  ///
  /// In de, this message translates to:
  /// **'SAG'**
  String get dieBoxChipSag;

  /// No description provided for @dieBoxChipChain.
  ///
  /// In de, this message translates to:
  /// **'Kette'**
  String get dieBoxChipChain;

  /// No description provided for @dieBoxChipPressure.
  ///
  /// In de, this message translates to:
  /// **'Druck'**
  String get dieBoxChipPressure;

  /// No description provided for @dieBoxChipCockpit.
  ///
  /// In de, this message translates to:
  /// **'Cockpit'**
  String get dieBoxChipCockpit;

  /// No description provided for @lastRideKm.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt {km} km'**
  String lastRideKm(String km);

  /// No description provided for @lastRideNoGps.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt unterwegs — ohne GPS-Strecke'**
  String get lastRideNoGps;

  /// No description provided for @dieBoxSentenceEverydayReady.
  ///
  /// In de, this message translates to:
  /// **'{name} wohnt hier · Montag-bereit'**
  String dieBoxSentenceEverydayReady(String name);

  /// No description provided for @dieBoxBitLightsChainOk.
  ///
  /// In de, this message translates to:
  /// **'Licht und Kette ok'**
  String get dieBoxBitLightsChainOk;

  /// No description provided for @dieBoxBitPressureUnknown.
  ///
  /// In de, this message translates to:
  /// **'Druck nicht gemessen'**
  String get dieBoxBitPressureUnknown;

  /// No description provided for @dieBoxBitLightsMissing.
  ///
  /// In de, this message translates to:
  /// **'Licht nicht eingetragen'**
  String get dieBoxBitLightsMissing;

  /// No description provided for @dieBoxSentenceNotReady.
  ///
  /// In de, this message translates to:
  /// **'{name} wohnt hier'**
  String dieBoxSentenceNotReady(String name);

  /// No description provided for @dieBoxSentenceBits.
  ///
  /// In de, this message translates to:
  /// **'{name} · {bits}'**
  String dieBoxSentenceBits(String name, String bits);

  /// No description provided for @dieBoxWheelOpen.
  ///
  /// In de, this message translates to:
  /// **'Laufrad offen'**
  String get dieBoxWheelOpen;

  /// No description provided for @dieBoxBitPressureLogged.
  ///
  /// In de, this message translates to:
  /// **'Druck gemerkt'**
  String get dieBoxBitPressureLogged;

  /// No description provided for @dieBoxBitPressureRough.
  ///
  /// In de, this message translates to:
  /// **'Druck grob — nachmessen'**
  String get dieBoxBitPressureRough;

  /// No description provided for @dieBoxBitBagsYes.
  ///
  /// In de, this message translates to:
  /// **'Taschen da'**
  String get dieBoxBitBagsYes;

  /// No description provided for @dieBoxBitBagsNo.
  ///
  /// In de, this message translates to:
  /// **'Taschen nicht eingetragen'**
  String get dieBoxBitBagsNo;

  /// No description provided for @dieBoxBitChainYes.
  ///
  /// In de, this message translates to:
  /// **'Kette gemessen'**
  String get dieBoxBitChainYes;

  /// No description provided for @dieBoxBitChainNo.
  ///
  /// In de, this message translates to:
  /// **'Kette noch nicht gemessen'**
  String get dieBoxBitChainNo;

  /// No description provided for @dieBoxBitPressureToday.
  ///
  /// In de, this message translates to:
  /// **'Druck heute offen'**
  String get dieBoxBitPressureToday;

  /// No description provided for @dieBoxSentencePark.
  ///
  /// In de, this message translates to:
  /// **'Park-Setup'**
  String get dieBoxSentencePark;

  /// No description provided for @dieBoxSagLoggedShort.
  ///
  /// In de, this message translates to:
  /// **'SAG gemerkt'**
  String get dieBoxSagLoggedShort;

  /// No description provided for @dieBoxSagMissingShort.
  ///
  /// In de, this message translates to:
  /// **'SAG nicht gemessen'**
  String get dieBoxSagMissingShort;

  /// No description provided for @dieBoxSentenceNoTravel.
  ///
  /// In de, this message translates to:
  /// **'{name} wohnt hier'**
  String dieBoxSentenceNoTravel(String name);

  /// No description provided for @dieBoxDriveAssist.
  ///
  /// In de, this message translates to:
  /// **' · E-Antrieb'**
  String get dieBoxDriveAssist;

  /// No description provided for @dieBoxSentenceMtb.
  ///
  /// In de, this message translates to:
  /// **'{name} · {travel}{drive}'**
  String dieBoxSentenceMtb(String name, String travel, String drive);

  /// No description provided for @dieBoxSentenceFallback.
  ///
  /// In de, this message translates to:
  /// **'{name} wohnt hier'**
  String dieBoxSentenceFallback(String name);

  /// No description provided for @close.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @remove.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get remove;

  /// No description provided for @garageMoreOnBike.
  ///
  /// In de, this message translates to:
  /// **'Mehr am Rad'**
  String get garageMoreOnBike;

  /// No description provided for @garageMoreOnBikeHint.
  ///
  /// In de, this message translates to:
  /// **'Teile, Wartung, Setup-Versionen — hinter der Box'**
  String get garageMoreOnBikeHint;

  /// No description provided for @garageDeleteBike.
  ///
  /// In de, this message translates to:
  /// **'Rad löschen'**
  String get garageDeleteBike;

  /// No description provided for @garageDeleteBikeTitle.
  ///
  /// In de, this message translates to:
  /// **'Rad löschen?'**
  String get garageDeleteBikeTitle;

  /// No description provided for @garageDeleteBikeBody.
  ///
  /// In de, this message translates to:
  /// **'Komponenten und Setups dieses Bikes entfallen lokal.'**
  String get garageDeleteBikeBody;

  /// No description provided for @garageRemovePartTitle.
  ///
  /// In de, this message translates to:
  /// **'Bauteil entfernen?'**
  String get garageRemovePartTitle;

  /// No description provided for @garageRemovePartBody.
  ///
  /// In de, this message translates to:
  /// **'{slot}: {name} wird aus der Garage entfernt.'**
  String garageRemovePartBody(String slot, String name);

  /// No description provided for @garageNotLogged.
  ///
  /// In de, this message translates to:
  /// **'Nicht erfasst'**
  String get garageNotLogged;

  /// No description provided for @garageOptions.
  ///
  /// In de, this message translates to:
  /// **'Optionen'**
  String get garageOptions;

  /// No description provided for @garageFitTitle.
  ///
  /// In de, this message translates to:
  /// **'Passgenauigkeit'**
  String get garageFitTitle;

  /// No description provided for @garageFitStatus.
  ///
  /// In de, this message translates to:
  /// **'Status: {label}'**
  String garageFitStatus(String label);

  /// No description provided for @garageFitSeverity.
  ///
  /// In de, this message translates to:
  /// **'Schwere: {label}'**
  String garageFitSeverity(String label);

  /// No description provided for @garageFitSeveritySafety.
  ///
  /// In de, this message translates to:
  /// **'sicherheitskritisch'**
  String get garageFitSeveritySafety;

  /// No description provided for @garageFitSeverityFunctional.
  ///
  /// In de, this message translates to:
  /// **'funktional'**
  String get garageFitSeverityFunctional;

  /// No description provided for @garageFitExplained.
  ///
  /// In de, this message translates to:
  /// **'Einfach erklärt'**
  String get garageFitExplained;

  /// No description provided for @garageFitCondition.
  ///
  /// In de, this message translates to:
  /// **'Bedingung: {text}'**
  String garageFitCondition(String text);

  /// No description provided for @garageFitHint.
  ///
  /// In de, this message translates to:
  /// **'Hinweis: {text}'**
  String garageFitHint(String text);

  /// No description provided for @garageFitMissing.
  ///
  /// In de, this message translates to:
  /// **'Noch fehlende Infos'**
  String get garageFitMissing;

  /// No description provided for @garageFitSource.
  ///
  /// In de, this message translates to:
  /// **'Quelle: {url}'**
  String garageFitSource(String url);

  /// No description provided for @garageGroupCount.
  ///
  /// In de, this message translates to:
  /// **'{group} · {count}'**
  String garageGroupCount(String group, int count);

  /// No description provided for @garageVerdictFits.
  ///
  /// In de, this message translates to:
  /// **'Passt'**
  String get garageVerdictFits;

  /// No description provided for @garageVerdictCheck.
  ///
  /// In de, this message translates to:
  /// **'Prüfen'**
  String get garageVerdictCheck;

  /// No description provided for @garageVerdictNoFit.
  ///
  /// In de, this message translates to:
  /// **'Passt nicht'**
  String get garageVerdictNoFit;

  /// No description provided for @garageVerdictUnclear.
  ///
  /// In de, this message translates to:
  /// **'Unklar'**
  String get garageVerdictUnclear;

  /// No description provided for @garageAllCount.
  ///
  /// In de, this message translates to:
  /// **'alle {count}'**
  String garageAllCount(int count);

  /// No description provided for @garageActiveStamp.
  ///
  /// In de, this message translates to:
  /// **'AKTIV'**
  String get garageActiveStamp;

  /// No description provided for @garageFreeOneBikeTitle.
  ///
  /// In de, this message translates to:
  /// **'Free: ein Rad'**
  String get garageFreeOneBikeTitle;

  /// No description provided for @garageFreeOneBikeBody.
  ///
  /// In de, this message translates to:
  /// **'Im Free-Tarif ist ein Rad vorgesehen. Du kannst lokal trotzdem weitere anlegen — Sync-Limits gelten nach dem Anmelden.'**
  String get garageFreeOneBikeBody;

  /// No description provided for @garageUnlockPro.
  ///
  /// In de, this message translates to:
  /// **'Pro freischalten'**
  String get garageUnlockPro;

  /// No description provided for @garageAddAnyway.
  ///
  /// In de, this message translates to:
  /// **'Trotzdem anlegen'**
  String get garageAddAnyway;

  /// No description provided for @garageSlotFrame.
  ///
  /// In de, this message translates to:
  /// **'Rahmen'**
  String get garageSlotFrame;

  /// No description provided for @garageSlotFork.
  ///
  /// In de, this message translates to:
  /// **'Gabel'**
  String get garageSlotFork;

  /// No description provided for @garageSlotRearShock.
  ///
  /// In de, this message translates to:
  /// **'Dämpfer'**
  String get garageSlotRearShock;

  /// No description provided for @garageSlotHeadset.
  ///
  /// In de, this message translates to:
  /// **'Steuersatz'**
  String get garageSlotHeadset;

  /// No description provided for @garageSlotStem.
  ///
  /// In de, this message translates to:
  /// **'Vorbau'**
  String get garageSlotStem;

  /// No description provided for @garageSlotHandlebar.
  ///
  /// In de, this message translates to:
  /// **'Lenker'**
  String get garageSlotHandlebar;

  /// No description provided for @garageSlotGrips.
  ///
  /// In de, this message translates to:
  /// **'Griffe'**
  String get garageSlotGrips;

  /// No description provided for @garageSlotSeatpost.
  ///
  /// In de, this message translates to:
  /// **'Sattelstütze'**
  String get garageSlotSeatpost;

  /// No description provided for @garageSlotSaddle.
  ///
  /// In de, this message translates to:
  /// **'Sattel'**
  String get garageSlotSaddle;

  /// No description provided for @garageSlotFrontHub.
  ///
  /// In de, this message translates to:
  /// **'Nabe vorn'**
  String get garageSlotFrontHub;

  /// No description provided for @garageSlotRearHub.
  ///
  /// In de, this message translates to:
  /// **'Nabe hinten'**
  String get garageSlotRearHub;

  /// No description provided for @garageSlotFrontRim.
  ///
  /// In de, this message translates to:
  /// **'Felge vorn'**
  String get garageSlotFrontRim;

  /// No description provided for @garageSlotRearRim.
  ///
  /// In de, this message translates to:
  /// **'Felge hinten'**
  String get garageSlotRearRim;

  /// No description provided for @garageSlotTireFront.
  ///
  /// In de, this message translates to:
  /// **'Reifen vorn'**
  String get garageSlotTireFront;

  /// No description provided for @garageSlotTireRear.
  ///
  /// In de, this message translates to:
  /// **'Reifen hinten'**
  String get garageSlotTireRear;

  /// No description provided for @garageSlotCassette.
  ///
  /// In de, this message translates to:
  /// **'Kassette'**
  String get garageSlotCassette;

  /// No description provided for @garageSlotChain.
  ///
  /// In de, this message translates to:
  /// **'Kette'**
  String get garageSlotChain;

  /// No description provided for @garageSlotCrankset.
  ///
  /// In de, this message translates to:
  /// **'Kurbel'**
  String get garageSlotCrankset;

  /// No description provided for @garageSlotBottomBracket.
  ///
  /// In de, this message translates to:
  /// **'Innenlager'**
  String get garageSlotBottomBracket;

  /// No description provided for @garageSlotFrontDerailleur.
  ///
  /// In de, this message translates to:
  /// **'Umwerfer'**
  String get garageSlotFrontDerailleur;

  /// No description provided for @garageSlotRearDerailleur.
  ///
  /// In de, this message translates to:
  /// **'Schaltwerk'**
  String get garageSlotRearDerailleur;

  /// No description provided for @garageSlotShifter.
  ///
  /// In de, this message translates to:
  /// **'Schalthebel'**
  String get garageSlotShifter;

  /// No description provided for @garageSlotBrakeFront.
  ///
  /// In de, this message translates to:
  /// **'Bremse vorn'**
  String get garageSlotBrakeFront;

  /// No description provided for @garageSlotBrakeRear.
  ///
  /// In de, this message translates to:
  /// **'Bremse hinten'**
  String get garageSlotBrakeRear;

  /// No description provided for @garageSlotRotorFront.
  ///
  /// In de, this message translates to:
  /// **'Scheibe vorn'**
  String get garageSlotRotorFront;

  /// No description provided for @garageSlotRotorRear.
  ///
  /// In de, this message translates to:
  /// **'Scheibe hinten'**
  String get garageSlotRotorRear;

  /// No description provided for @garageSlotMotor.
  ///
  /// In de, this message translates to:
  /// **'Motor'**
  String get garageSlotMotor;

  /// No description provided for @garageSlotBattery.
  ///
  /// In de, this message translates to:
  /// **'Akku'**
  String get garageSlotBattery;

  /// No description provided for @garageSlotDisplay.
  ///
  /// In de, this message translates to:
  /// **'Display'**
  String get garageSlotDisplay;

  /// No description provided for @garageSlotLight.
  ///
  /// In de, this message translates to:
  /// **'Licht'**
  String get garageSlotLight;

  /// No description provided for @garageSlotLock.
  ///
  /// In de, this message translates to:
  /// **'Schloss'**
  String get garageSlotLock;

  /// No description provided for @garageSlotRack.
  ///
  /// In de, this message translates to:
  /// **'Gepäckträger'**
  String get garageSlotRack;

  /// No description provided for @garageSlotBags.
  ///
  /// In de, this message translates to:
  /// **'Taschen'**
  String get garageSlotBags;

  /// No description provided for @garageSlotOther.
  ///
  /// In de, this message translates to:
  /// **'Sonstiges'**
  String get garageSlotOther;

  /// No description provided for @garageGroupSuspension.
  ///
  /// In de, this message translates to:
  /// **'Fahrwerk'**
  String get garageGroupSuspension;

  /// No description provided for @garageGroupWheels.
  ///
  /// In de, this message translates to:
  /// **'Laufräder'**
  String get garageGroupWheels;

  /// No description provided for @garageGroupCockpit.
  ///
  /// In de, this message translates to:
  /// **'Cockpit'**
  String get garageGroupCockpit;

  /// No description provided for @garageGroupDrivetrain.
  ///
  /// In de, this message translates to:
  /// **'Antrieb'**
  String get garageGroupDrivetrain;

  /// No description provided for @garageGroupBrakes.
  ///
  /// In de, this message translates to:
  /// **'Bremsen'**
  String get garageGroupBrakes;

  /// No description provided for @garageGroupPower.
  ///
  /// In de, this message translates to:
  /// **'E-Bike'**
  String get garageGroupPower;

  /// No description provided for @garageGroupOther.
  ///
  /// In de, this message translates to:
  /// **'Weiteres'**
  String get garageGroupOther;

  /// No description provided for @dieBoxZoneToday.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get dieBoxZoneToday;

  /// No description provided for @dieBoxZoneOnBike.
  ///
  /// In de, this message translates to:
  /// **'Am Rad'**
  String get dieBoxZoneOnBike;

  /// No description provided for @dieBoxZoneSensor.
  ///
  /// In de, this message translates to:
  /// **'Sensor'**
  String get dieBoxZoneSensor;

  /// No description provided for @garageCatalogOffline.
  ///
  /// In de, this message translates to:
  /// **'Katalog offline — du kannst dein Bike unter „Mein Rad“ oder „GPX“ anlegen.'**
  String get garageCatalogOffline;

  /// No description provided for @garageNoHit.
  ///
  /// In de, this message translates to:
  /// **'Kein Treffer — Liste nutzen oder anders suchen.'**
  String get garageNoHit;

  /// No description provided for @garageSearchUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Suche gerade nicht möglich — Liste nutzen.'**
  String get garageSearchUnavailable;

  /// No description provided for @garageFileUnreadable.
  ///
  /// In de, this message translates to:
  /// **'Datei konnte nicht gelesen werden'**
  String get garageFileUnreadable;

  /// No description provided for @garageGpxInvalid.
  ///
  /// In de, this message translates to:
  /// **'Kein gültiger GPX-Track (min. 2 Punkte)'**
  String get garageGpxInvalid;

  /// No description provided for @garageNeedMakeModel.
  ///
  /// In de, this message translates to:
  /// **'Bitte Hersteller und Modell wählen'**
  String get garageNeedMakeModel;

  /// No description provided for @garageCreateFailed.
  ///
  /// In de, this message translates to:
  /// **'Anlegen fehlgeschlagen: {error}'**
  String garageCreateFailed(String error);

  /// No description provided for @garageOemSetup.
  ///
  /// In de, this message translates to:
  /// **'Serien-Setup'**
  String get garageOemSetup;

  /// No description provided for @garageCatalogIdentity.
  ///
  /// In de, this message translates to:
  /// **'Katalog-Identität'**
  String get garageCatalogIdentity;

  /// No description provided for @garageImportBike.
  ///
  /// In de, this message translates to:
  /// **'Import-Bike'**
  String get garageImportBike;

  /// No description provided for @garageImportNoGpx.
  ///
  /// In de, this message translates to:
  /// **'Import ohne GPX — Komponenten später ergänzen'**
  String get garageImportNoGpx;

  /// No description provided for @garageBaseSetup.
  ///
  /// In de, this message translates to:
  /// **'Basis-Setup'**
  String get garageBaseSetup;

  /// No description provided for @garageFreeExtraLocal.
  ///
  /// In de, this message translates to:
  /// **'Free: weiteres Bike lokal angelegt (Multi-Bike ist Pro).'**
  String get garageFreeExtraLocal;

  /// No description provided for @garageOemTakeover.
  ///
  /// In de, this message translates to:
  /// **'Serienteile übernehmen ({count})'**
  String garageOemTakeover(int count);

  /// No description provided for @garageOemHint.
  ///
  /// In de, this message translates to:
  /// **'Sonst nur Identität. Katalog bleibt Suche.'**
  String get garageOemHint;

  /// No description provided for @garageReachStack.
  ///
  /// In de, this message translates to:
  /// **'Reach {reach} mm · Stack {stack} mm'**
  String garageReachStack(String reach, String stack);

  /// No description provided for @garageCatalogNotLoaded.
  ///
  /// In de, this message translates to:
  /// **'Katalog nicht geladen — wechsle auf „Mein Rad“ oder versuch es später.'**
  String get garageCatalogNotLoaded;

  /// No description provided for @garageSearchBrandHint.
  ///
  /// In de, this message translates to:
  /// **'Focus SAM, Canyon Grizl, Stevens …'**
  String get garageSearchBrandHint;

  /// No description provided for @garageSearchIntro.
  ///
  /// In de, this message translates to:
  /// **'Suche nach Marke und Modell, mach ein Foto oder wähle aus der Liste.'**
  String get garageSearchIntro;

  /// No description provided for @garageHideList.
  ///
  /// In de, this message translates to:
  /// **'Liste ausblenden'**
  String get garageHideList;

  /// No description provided for @garagePickFromList.
  ///
  /// In de, this message translates to:
  /// **'Aus Liste wählen'**
  String get garagePickFromList;

  /// No description provided for @garageManufacturer.
  ///
  /// In de, this message translates to:
  /// **'Hersteller'**
  String get garageManufacturer;

  /// No description provided for @garageNickname.
  ///
  /// In de, this message translates to:
  /// **'Spitzname (optional)'**
  String get garageNickname;

  /// No description provided for @garageNicknameHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Trail'**
  String get garageNicknameHint;

  /// No description provided for @garageTravelFrontMm.
  ///
  /// In de, this message translates to:
  /// **'Federweg vorn (mm)'**
  String get garageTravelFrontMm;

  /// No description provided for @garageTravelRearMm.
  ///
  /// In de, this message translates to:
  /// **'Federweg hinten (mm)'**
  String get garageTravelRearMm;

  /// No description provided for @garageTravelOnlyIfPresent.
  ///
  /// In de, this message translates to:
  /// **'Nur wenn am Rad steht'**
  String get garageTravelOnlyIfPresent;

  /// No description provided for @garageOnBikeCheck.
  ///
  /// In de, this message translates to:
  /// **'Am Rad — nur anhaken wenn wirklich da'**
  String get garageOnBikeCheck;

  /// No description provided for @garageBagsOnBike.
  ///
  /// In de, this message translates to:
  /// **'Taschen am Rad'**
  String get garageBagsOnBike;

  /// No description provided for @garageBrandOptional.
  ///
  /// In de, this message translates to:
  /// **'Marke (optional)'**
  String get garageBrandOptional;

  /// No description provided for @garageModelOptional.
  ///
  /// In de, this message translates to:
  /// **'Modell (optional)'**
  String get garageModelOptional;

  /// No description provided for @garagePickGpx.
  ///
  /// In de, this message translates to:
  /// **'GPX-Datei wählen'**
  String get garagePickGpx;

  /// No description provided for @garageNameOptional.
  ///
  /// In de, this message translates to:
  /// **'Name (optional)'**
  String get garageNameOptional;

  /// No description provided for @garageMyBike.
  ///
  /// In de, this message translates to:
  /// **'Mein Rad'**
  String get garageMyBike;

  /// No description provided for @garageCatalog.
  ///
  /// In de, this message translates to:
  /// **'Katalog'**
  String get garageCatalog;

  /// No description provided for @garageImport.
  ///
  /// In de, this message translates to:
  /// **'Importieren'**
  String get garageImport;

  /// No description provided for @garageCreateBike.
  ///
  /// In de, this message translates to:
  /// **'Rad anlegen'**
  String get garageCreateBike;

  /// No description provided for @garageGpxImported.
  ///
  /// In de, this message translates to:
  /// **'GPX „{name}“ · {km} km'**
  String garageGpxImported(String name, String km);

  /// No description provided for @garageName.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get garageName;

  /// No description provided for @garageNameHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Gravel, City, MTB'**
  String get garageNameHint;

  /// No description provided for @garagePhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto'**
  String get garagePhoto;

  /// No description provided for @garageGallery.
  ///
  /// In de, this message translates to:
  /// **'Galerie'**
  String get garageGallery;

  /// No description provided for @garageSlotHeading.
  ///
  /// In de, this message translates to:
  /// **'Slot'**
  String get garageSlotHeading;

  /// No description provided for @garageEditPart.
  ///
  /// In de, this message translates to:
  /// **'Teil bearbeiten'**
  String get garageEditPart;

  /// No description provided for @garageInstallPart.
  ///
  /// In de, this message translates to:
  /// **'Teil installieren'**
  String get garageInstallPart;

  /// No description provided for @garageSearchParts.
  ///
  /// In de, this message translates to:
  /// **'Teile suchen (API/Cache)'**
  String get garageSearchParts;

  /// No description provided for @garageSearchPartsHint.
  ///
  /// In de, this message translates to:
  /// **'Hersteller / Modell — optional'**
  String get garageSearchPartsHint;

  /// No description provided for @garageSearchPartsHelper.
  ///
  /// In de, this message translates to:
  /// **'Ohne Treffer: Basisdaten manuell'**
  String get garageSearchPartsHelper;

  /// No description provided for @garageHits.
  ///
  /// In de, this message translates to:
  /// **'Treffer'**
  String get garageHits;

  /// No description provided for @garageNoHitsManual.
  ///
  /// In de, this message translates to:
  /// **'Keine Treffer — manuell ausfüllen (Basis). Cache kann leer sein.'**
  String get garageNoHitsManual;

  /// No description provided for @garageCacheId.
  ///
  /// In de, this message translates to:
  /// **'Cache-ID: {id}'**
  String garageCacheId(String id);

  /// No description provided for @garageCompatAttrs.
  ///
  /// In de, this message translates to:
  /// **'Kompat-Attribute · {slot}'**
  String garageCompatAttrs(String slot);

  /// No description provided for @garageCompatAttrsHint.
  ///
  /// In de, this message translates to:
  /// **'Woher: Herstellerdatenblatt oder Aufdruck am Bauteil. Leer lassen, wenn unbekannt — dann „Daten fehlen\\\" statt Rätselraten.'**
  String get garageCompatAttrsHint;

  /// No description provided for @garageExtraAttr.
  ///
  /// In de, this message translates to:
  /// **'Weiteres Attribut (fortgeschritten)'**
  String get garageExtraAttr;

  /// No description provided for @garageAttrKey.
  ///
  /// In de, this message translates to:
  /// **'Attribut-Key'**
  String get garageAttrKey;

  /// No description provided for @garageAttrValue.
  ///
  /// In de, this message translates to:
  /// **'Attribut-Wert'**
  String get garageAttrValue;

  /// No description provided for @garageCompatPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'Kompat-Platzhalter gesetzt (z. B. 148×12 / Microspline) — keine Katalog-Wahrheit. Attribute prüfen.'**
  String get garageCompatPlaceholder;

  /// No description provided for @garageSagGuideTitle.
  ///
  /// In de, this message translates to:
  /// **'Federungs-Richtwerte (Fahrer {kg} kg)'**
  String garageSagGuideTitle(String kg);

  /// No description provided for @garageSagGuideFork.
  ///
  /// In de, this message translates to:
  /// **'Gabel: {psi} psi ({min}–{max}) · SAG {sag}%'**
  String garageSagGuideFork(String psi, String min, String max, String sag);

  /// No description provided for @garageSagGuideShock.
  ///
  /// In de, this message translates to:
  /// **'Dämpfer: {psi} psi ({min}–{max}) · SAG {sag}%'**
  String garageSagGuideShock(String psi, String min, String max, String sag);

  /// No description provided for @garageSagGuideHint.
  ///
  /// In de, this message translates to:
  /// **'Richtwert zum Einstieg — am Bike messen, dann feinjustieren.'**
  String get garageSagGuideHint;

  /// No description provided for @garageMeasureSag.
  ///
  /// In de, this message translates to:
  /// **'SAG messen'**
  String get garageMeasureSag;

  /// No description provided for @garageShowMeasureSteps.
  ///
  /// In de, this message translates to:
  /// **'Messschritte anzeigen'**
  String get garageShowMeasureSteps;

  /// No description provided for @garageOdometer.
  ///
  /// In de, this message translates to:
  /// **'Kilometerstand'**
  String get garageOdometer;

  /// No description provided for @garageOperatingHours.
  ///
  /// In de, this message translates to:
  /// **'Betriebsstunden'**
  String get garageOperatingHours;

  /// No description provided for @garageOdoStand.
  ///
  /// In de, this message translates to:
  /// **'Stand: {km} km'**
  String garageOdoStand(String km);

  /// No description provided for @garageHoursStand.
  ///
  /// In de, this message translates to:
  /// **'Stunden: {hours} h'**
  String garageHoursStand(String hours);

  /// No description provided for @garageAddKmNoGps.
  ///
  /// In de, this message translates to:
  /// **'km ohne GPS-Track hinzufügen'**
  String get garageAddKmNoGps;

  /// No description provided for @garageDistanceKm.
  ///
  /// In de, this message translates to:
  /// **'Distanz (km)'**
  String get garageDistanceKm;

  /// No description provided for @garageImportKm.
  ///
  /// In de, this message translates to:
  /// **'km importieren (ohne GPS-Ride)'**
  String get garageImportKm;

  /// No description provided for @garageMaintLog.
  ///
  /// In de, this message translates to:
  /// **'Wartungslog'**
  String get garageMaintLog;

  /// No description provided for @garageMaintLogEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einträge — Odometer-Set erzeugt Logs.'**
  String get garageMaintLogEmpty;

  /// No description provided for @garageBleScanning.
  ///
  /// In de, this message translates to:
  /// **'Suche Geräte …'**
  String get garageBleScanning;

  /// No description provided for @garageBlePaired.
  ///
  /// In de, this message translates to:
  /// **'Gerät gekoppelt'**
  String get garageBlePaired;

  /// No description provided for @garageBlePairedNamed.
  ///
  /// In de, this message translates to:
  /// **'Gekoppelt: {name}'**
  String garageBlePairedNamed(String name);

  /// No description provided for @garageBlePairFailed.
  ///
  /// In de, this message translates to:
  /// **'Kopplung fehlgeschlagen'**
  String get garageBlePairFailed;

  /// No description provided for @garageBleRemoved.
  ///
  /// In de, this message translates to:
  /// **'Sensor entfernt'**
  String get garageBleRemoved;

  /// No description provided for @garageBleDisconnected.
  ///
  /// In de, this message translates to:
  /// **'Bluetooth nicht verbunden'**
  String get garageBleDisconnected;

  /// No description provided for @garageBleHintEbike.
  ///
  /// In de, this message translates to:
  /// **'Bosch, Shimano STEPS oder CSC. Display einschalten.'**
  String get garageBleHintEbike;

  /// No description provided for @garageBleHintSensor.
  ///
  /// In de, this message translates to:
  /// **'Sensor am Rad, nicht am Fahrer.'**
  String get garageBleHintSensor;

  /// No description provided for @discoverRefresh.
  ///
  /// In de, this message translates to:
  /// **'Neu'**
  String get discoverRefresh;

  /// No description provided for @discoverChangePlace.
  ///
  /// In de, this message translates to:
  /// **'Ort ändern'**
  String get discoverChangePlace;

  /// No description provided for @discoverSuggestDuration.
  ///
  /// In de, this message translates to:
  /// **'Dauer vorschlagen'**
  String get discoverSuggestDuration;

  /// No description provided for @discoverDemoCities.
  ///
  /// In de, this message translates to:
  /// **'Demo-Städte'**
  String get discoverDemoCities;

  /// No description provided for @discoverNearbyTitle.
  ///
  /// In de, this message translates to:
  /// **'In deiner Nähe · {profile}'**
  String discoverNearbyTitle(String profile);

  /// No description provided for @discoverNearbyHintGps.
  ///
  /// In de, this message translates to:
  /// **'Tippen zeigt die Strecke · Losfahren startet die Navigation'**
  String get discoverNearbyHintGps;

  /// No description provided for @discoverNearbyHintNoGps.
  ///
  /// In de, this message translates to:
  /// **'Standort freigeben für Touren ab hier'**
  String get discoverNearbyHintNoGps;

  /// No description provided for @discoverGrantLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort freigeben'**
  String get discoverGrantLocation;

  /// No description provided for @discoverSuggestionsComputing.
  ///
  /// In de, this message translates to:
  /// **'Vorschläge werden berechnet…'**
  String get discoverSuggestionsComputing;

  /// No description provided for @discoverNoSuggestions.
  ///
  /// In de, this message translates to:
  /// **'Keine Vorschläge — Standort setzen, Rad-Profil wählen oder „Neu“.'**
  String get discoverNoSuggestions;

  /// No description provided for @discoverAdaptSuggestion.
  ///
  /// In de, this message translates to:
  /// **'Vorschlag anpassen: {label}'**
  String discoverAdaptSuggestion(String label);

  /// No description provided for @discoverTours.
  ///
  /// In de, this message translates to:
  /// **'Touren'**
  String get discoverTours;

  /// No description provided for @discoverToursLoops.
  ///
  /// In de, this message translates to:
  /// **'Touren · {count} Rundkurse'**
  String discoverToursLoops(int count);

  /// No description provided for @discoverToursCount.
  ///
  /// In de, this message translates to:
  /// **'Touren · {count}'**
  String discoverToursCount(int count);

  /// No description provided for @discoverNoGpsCurated.
  ///
  /// In de, this message translates to:
  /// **'Ohne GPS: kuratierte Touren · Standort für Nähe'**
  String get discoverNoGpsCurated;

  /// No description provided for @discoverGrantLocationNearby.
  ///
  /// In de, this message translates to:
  /// **'Standort freigeben für Touren in deiner Nähe'**
  String get discoverGrantLocationNearby;

  /// No description provided for @discoverToursNearbyCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tour in der Nähe} other{{count} Touren in der Nähe}}'**
  String discoverToursNearbyCount(int count);

  /// No description provided for @discoverCuratedLoops.
  ///
  /// In de, this message translates to:
  /// **'{count} kuratierte Rundkurse'**
  String discoverCuratedLoops(int count);

  /// No description provided for @discoverOfflineSuffix.
  ///
  /// In de, this message translates to:
  /// **' · offline'**
  String get discoverOfflineSuffix;

  /// No description provided for @discoverHeatmapConsent.
  ///
  /// In de, this message translates to:
  /// **'Heatmaps nach Consent — Privatsphäre öffnen'**
  String get discoverHeatmapConsent;

  /// No description provided for @discoverRideToStartShort.
  ///
  /// In de, this message translates to:
  /// **'Zum Startpunkt'**
  String get discoverRideToStartShort;

  /// No description provided for @discoverLoopsNearby.
  ///
  /// In de, this message translates to:
  /// **'Rundkurse in deiner Nähe'**
  String get discoverLoopsNearby;

  /// No description provided for @discoverNoLoop90.
  ///
  /// In de, this message translates to:
  /// **'Keine Runde in 90 km — nächste Regionen'**
  String get discoverNoLoop90;

  /// No description provided for @discoverRecommendedNoGps.
  ///
  /// In de, this message translates to:
  /// **'Empfohlene Touren · auch ohne GPS'**
  String get discoverRecommendedNoGps;

  /// No description provided for @discoverRecommended.
  ///
  /// In de, this message translates to:
  /// **'Empfohlen ({count})'**
  String discoverRecommended(int count);

  /// No description provided for @discoverRecommendedHint.
  ///
  /// In de, this message translates to:
  /// **'Für alle Radtypen · Strecke beim Losfahren'**
  String get discoverRecommendedHint;

  /// No description provided for @discoverInRegion.
  ///
  /// In de, this message translates to:
  /// **'In der Region ({count})'**
  String discoverInRegion(int count);

  /// No description provided for @discoverToursAround.
  ///
  /// In de, this message translates to:
  /// **'Touren aus der Umgebung'**
  String get discoverToursAround;

  /// No description provided for @discoverAfterLocation.
  ///
  /// In de, this message translates to:
  /// **'Erscheint nach Standort'**
  String get discoverAfterLocation;

  /// No description provided for @discoverNeedLocationTrails.
  ///
  /// In de, this message translates to:
  /// **'Standort oder Start setzen für Trailnetz'**
  String get discoverNeedLocationTrails;

  /// No description provided for @discoverTrailLoading.
  ///
  /// In de, this message translates to:
  /// **'Trailnetz lädt…'**
  String get discoverTrailLoading;

  /// No description provided for @discoverTrailEmpty.
  ///
  /// In de, this message translates to:
  /// **'Kein OSM-Trailnetz in der Nähe'**
  String get discoverTrailEmpty;

  /// No description provided for @discoverTrailCount.
  ///
  /// In de, this message translates to:
  /// **'Trailnetz {count} · Tippen zum Auswählen'**
  String discoverTrailCount(int count);

  /// No description provided for @discoverTrailOffline.
  ///
  /// In de, this message translates to:
  /// **'Trailnetz offline'**
  String get discoverTrailOffline;

  /// No description provided for @discoverOsmLivePath.
  ///
  /// In de, this message translates to:
  /// **'OSM-Live-Pfad'**
  String get discoverOsmLivePath;

  /// No description provided for @discoverOsmTags.
  ///
  /// In de, this message translates to:
  /// **'Tags aus OpenStreetMap'**
  String get discoverOsmTags;

  /// No description provided for @discoverTapMapTrails.
  ///
  /// In de, this message translates to:
  /// **'Tippen auf der Karte wählt Trails.'**
  String get discoverTapMapTrails;

  /// No description provided for @discoverTrailApproachHint.
  ///
  /// In de, this message translates to:
  /// **'Anfahrt zum Einstieg, dann Overlay speichern oder fahren.'**
  String get discoverTrailApproachHint;

  /// No description provided for @discoverTrailGravityHint.
  ///
  /// In de, this message translates to:
  /// **'DH: Auto oder zu Fuß zum oberen Einstieg. Die Abfahrt folgt dem Trail, nicht der Straße.'**
  String get discoverTrailGravityHint;

  /// No description provided for @discoverRideToTrailhead.
  ///
  /// In de, this message translates to:
  /// **'Zum Startpunkt anfahren'**
  String get discoverRideToTrailhead;

  /// No description provided for @discoverApproachByCar.
  ///
  /// In de, this message translates to:
  /// **'Anfahrt mit Auto'**
  String get discoverApproachByCar;

  /// No description provided for @discoverApproachOnFoot.
  ///
  /// In de, this message translates to:
  /// **'Zu Fuß zum Einstieg'**
  String get discoverApproachOnFoot;

  /// No description provided for @discoverAtTrailStart.
  ///
  /// In de, this message translates to:
  /// **'Ich bin am Start'**
  String get discoverAtTrailStart;

  /// No description provided for @discoverApproachByBike.
  ///
  /// In de, this message translates to:
  /// **'Mit dem Rad anfahren'**
  String get discoverApproachByBike;

  /// No description provided for @discoverTrailUnsuitableForBike.
  ///
  /// In de, this message translates to:
  /// **'Mit {bike} nicht auf diesen Trail. Garage wechseln — nicht heimlich als MTB routen.'**
  String discoverTrailUnsuitableForBike(String bike);

  /// No description provided for @discoverTrailOrientedDownhill.
  ///
  /// In de, this message translates to:
  /// **'Einstieg oben (Höhe)'**
  String get discoverTrailOrientedDownhill;

  /// No description provided for @discoverTrailStartUphillUnknown.
  ///
  /// In de, this message translates to:
  /// **'Höhe unklar — näherer Einstieg'**
  String get discoverTrailStartUphillUnknown;

  /// No description provided for @discoverPutOnRoute.
  ///
  /// In de, this message translates to:
  /// **'Auf Route legen'**
  String get discoverPutOnRoute;

  /// No description provided for @discoverOpenOsm.
  ///
  /// In de, this message translates to:
  /// **'Auf OpenStreetMap öffnen'**
  String get discoverOpenOsm;

  /// No description provided for @discoverApproachTrailhead.
  ///
  /// In de, this message translates to:
  /// **'Anfahrt zum Einstieg…'**
  String get discoverApproachTrailhead;

  /// No description provided for @discoverApproachPlusTrail.
  ///
  /// In de, this message translates to:
  /// **'Anfahrt + Trail · {km} km · {diff}'**
  String discoverApproachPlusTrail(String km, String diff);

  /// No description provided for @discoverTrailLaid.
  ///
  /// In de, this message translates to:
  /// **'Trail gelegt · {diff} · {km} km — speichern oder Los'**
  String discoverTrailLaid(String diff, String km);

  /// No description provided for @discoverSurfaceNature.
  ///
  /// In de, this message translates to:
  /// **'Naturweg'**
  String get discoverSurfaceNature;

  /// No description provided for @discoverSurfaceGrass.
  ///
  /// In de, this message translates to:
  /// **'Gras'**
  String get discoverSurfaceGrass;

  /// No description provided for @discoverSurfaceWood.
  ///
  /// In de, this message translates to:
  /// **'Holz'**
  String get discoverSurfaceWood;

  /// No description provided for @discoverHighwayPath.
  ///
  /// In de, this message translates to:
  /// **'Pfad'**
  String get discoverHighwayPath;

  /// No description provided for @discoverHighwayTrack.
  ///
  /// In de, this message translates to:
  /// **'Forstweg'**
  String get discoverHighwayTrack;

  /// No description provided for @discoverHighwayCycle.
  ///
  /// In de, this message translates to:
  /// **'Radweg'**
  String get discoverHighwayCycle;

  /// No description provided for @discoverHighwayBridle.
  ///
  /// In de, this message translates to:
  /// **'Reitweg'**
  String get discoverHighwayBridle;

  /// No description provided for @discoverHighwayFoot.
  ///
  /// In de, this message translates to:
  /// **'Fußweg'**
  String get discoverHighwayFoot;

  /// No description provided for @discoverSetStartEnd.
  ///
  /// In de, this message translates to:
  /// **'Start & Ziel setzen — dann Route berechnen'**
  String get discoverSetStartEnd;

  /// No description provided for @discoverAdjustStops.
  ///
  /// In de, this message translates to:
  /// **'Start, Ziel oder Stopp anpassen'**
  String get discoverAdjustStops;

  /// No description provided for @discoverNoHitsFor.
  ///
  /// In de, this message translates to:
  /// **'Keine Treffer für „{query}“'**
  String discoverNoHitsFor(String query);

  /// No description provided for @discoverGeocodeFailed.
  ///
  /// In de, this message translates to:
  /// **'Adresssuche fehlgeschlagen'**
  String get discoverGeocodeFailed;

  /// No description provided for @discoverStartEndHit.
  ///
  /// In de, this message translates to:
  /// **'{kind}: {label}'**
  String discoverStartEndHit(String kind, String label);

  /// No description provided for @discoverIdeaStartSet.
  ///
  /// In de, this message translates to:
  /// **'Tour-Idee: Start = Ortspunkt, Ziel-Vorschlag gesetzt — Route berechnen.'**
  String get discoverIdeaStartSet;

  /// No description provided for @discoverSuggestEnd.
  ///
  /// In de, this message translates to:
  /// **'Ziel-Vorschlag (anpassbar)'**
  String get discoverSuggestEnd;

  /// No description provided for @discoverTourInPlan.
  ///
  /// In de, this message translates to:
  /// **'Tour in Navigieren — Start, Ziel oder Stopp ändern'**
  String get discoverTourInPlan;

  /// No description provided for @discoverNeedLocationTours.
  ///
  /// In de, this message translates to:
  /// **'Standort oder Start setzen für Touren'**
  String get discoverNeedLocationTours;

  /// No description provided for @discoverOaOffline.
  ///
  /// In de, this message translates to:
  /// **'Touren gerade nicht erreichbar'**
  String get discoverOaOffline;

  /// No description provided for @discoverOaNoLive.
  ///
  /// In de, this message translates to:
  /// **'Keine Live-Touren in der Nähe'**
  String get discoverOaNoLive;

  /// No description provided for @discoverOaCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tour in der Nähe} other{{count} Touren in der Nähe}}'**
  String discoverOaCount(int count);

  /// No description provided for @discoverLocationOff.
  ///
  /// In de, this message translates to:
  /// **'Ortungsdienst aus — Start tippen oder Adresse'**
  String get discoverLocationOff;

  /// No description provided for @discoverLocationDenied.
  ///
  /// In de, this message translates to:
  /// **'Standort-Berechtigung fehlt — Adresse nutzen'**
  String get discoverLocationDenied;

  /// No description provided for @discoverNoGpsFix.
  ///
  /// In de, this message translates to:
  /// **'Kein GPS-Fix — Karte tippen oder Adresse suchen'**
  String get discoverNoGpsFix;

  /// No description provided for @discoverMyPosition.
  ///
  /// In de, this message translates to:
  /// **'Meine Position'**
  String get discoverMyPosition;

  /// No description provided for @discoverLocationReady.
  ///
  /// In de, this message translates to:
  /// **'Standort bereit · In der Nähe wird geladen…'**
  String get discoverLocationReady;

  /// No description provided for @discoverLocationUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Position nicht verfügbar — Adresse oder Tippen'**
  String get discoverLocationUnavailable;

  /// No description provided for @discoverComputing.
  ///
  /// In de, this message translates to:
  /// **'Route wird berechnet…'**
  String get discoverComputing;

  /// No description provided for @discoverComputingN.
  ///
  /// In de, this message translates to:
  /// **'{count} Routen werden berechnet…'**
  String discoverComputingN(int count);

  /// No description provided for @discoverHeadingNorth.
  ///
  /// In de, this message translates to:
  /// **'Richtung Norden'**
  String get discoverHeadingNorth;

  /// No description provided for @discoverHeadingEast.
  ///
  /// In de, this message translates to:
  /// **'Richtung Osten'**
  String get discoverHeadingEast;

  /// No description provided for @discoverHeadingSouthwest.
  ///
  /// In de, this message translates to:
  /// **'Richtung Südwest'**
  String get discoverHeadingSouthwest;

  /// No description provided for @discoverTargetNorth.
  ///
  /// In de, this message translates to:
  /// **'Ziel im Norden — Rückweg noch nicht enthalten'**
  String get discoverTargetNorth;

  /// No description provided for @discoverTargetEast.
  ///
  /// In de, this message translates to:
  /// **'Ziel im Osten — Rückweg noch nicht enthalten'**
  String get discoverTargetEast;

  /// No description provided for @discoverTargetSouthwest.
  ///
  /// In de, this message translates to:
  /// **'Ziel im Südwest — Rückweg noch nicht enthalten'**
  String get discoverTargetSouthwest;

  /// No description provided for @discoverApproxLabel.
  ///
  /// In de, this message translates to:
  /// **'{label} (Näherung)'**
  String discoverApproxLabel(String label);

  /// No description provided for @discoverQuickRoute.
  ///
  /// In de, this message translates to:
  /// **'Kurzroute'**
  String get discoverQuickRoute;

  /// No description provided for @discoverRoutingLimit.
  ///
  /// In de, this message translates to:
  /// **'Routing-Limit — Näherung genutzt. Später erneut berechnen.'**
  String get discoverRoutingLimit;

  /// No description provided for @discoverNoQuickRoutes.
  ///
  /// In de, this message translates to:
  /// **'Keine Kurzrouten'**
  String get discoverNoQuickRoutes;

  /// No description provided for @discoverPartialApprox.
  ///
  /// In de, this message translates to:
  /// **'Teilweise Näherung — Live-Routing eingeschränkt'**
  String get discoverPartialApprox;

  /// No description provided for @discoverPlannedRoute.
  ///
  /// In de, this message translates to:
  /// **'Geplante Route'**
  String get discoverPlannedRoute;

  /// No description provided for @discoverStraightFallback.
  ///
  /// In de, this message translates to:
  /// **'Keine Strecke von der Karte — Ziel neu setzen.'**
  String get discoverStraightFallback;

  /// No description provided for @discoverSaved.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert'**
  String get discoverSaved;

  /// No description provided for @discoverSavedNamed.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert: {name}'**
  String discoverSavedNamed(String name);

  /// No description provided for @discoverSavedRouteLoaded.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Route geladen'**
  String get discoverSavedRouteLoaded;

  /// No description provided for @discoverStartSetPickEnd.
  ///
  /// In de, this message translates to:
  /// **'Start gesetzt — jetzt Ziel wählen'**
  String get discoverStartSetPickEnd;

  /// No description provided for @discoverEndSetComputing.
  ///
  /// In de, this message translates to:
  /// **'Ziel gesetzt — Route wird berechnet'**
  String get discoverEndSetComputing;

  /// No description provided for @discoverFromHere.
  ///
  /// In de, this message translates to:
  /// **'Von hier'**
  String get discoverFromHere;

  /// No description provided for @discoverNearbyPhotos.
  ///
  /// In de, this message translates to:
  /// **'Fotos in der Nähe'**
  String get discoverNearbyPhotos;

  /// No description provided for @discoverToMyTours.
  ///
  /// In de, this message translates to:
  /// **'Zu Meine Touren'**
  String get discoverToMyTours;

  /// No description provided for @discoverAlreadyInMappe.
  ///
  /// In de, this message translates to:
  /// **'Schon in der Mappe'**
  String get discoverAlreadyInMappe;

  /// No description provided for @discoverInMappeNamed.
  ///
  /// In de, this message translates to:
  /// **'In der Mappe: {name}'**
  String discoverInMappeNamed(String name);

  /// No description provided for @discoverAddRoute.
  ///
  /// In de, this message translates to:
  /// **'Route hinzufügen'**
  String get discoverAddRoute;

  /// No description provided for @discoverAddRouteHint.
  ///
  /// In de, this message translates to:
  /// **'Name + Start — ohne erfundenen Track. Strecke später berechnen oder GPX.'**
  String get discoverAddRouteHint;

  /// No description provided for @discoverMapCenter.
  ///
  /// In de, this message translates to:
  /// **'Kartenmitte'**
  String get discoverMapCenter;

  /// No description provided for @discoverSaveToMine.
  ///
  /// In de, this message translates to:
  /// **'In Meine Touren speichern'**
  String get discoverSaveToMine;

  /// No description provided for @discoverSavedToMine.
  ///
  /// In de, this message translates to:
  /// **'In Meine Touren: {name}'**
  String discoverSavedToMine(String name);

  /// No description provided for @discoverPickFileAgain.
  ///
  /// In de, this message translates to:
  /// **'Datei erneut wählen'**
  String get discoverPickFileAgain;

  /// No description provided for @discoverGpxUnreadable.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ konnte nicht gelesen werden — beschädigt oder kein gültiges GPX.'**
  String discoverGpxUnreadable(String name);

  /// No description provided for @discoverGpxInvalid.
  ///
  /// In de, this message translates to:
  /// **'GPX ungültig oder zu wenige Punkte — andere Datei wählen?'**
  String get discoverGpxInvalid;

  /// No description provided for @discoverGpxImported.
  ///
  /// In de, this message translates to:
  /// **'GPX importiert: {name} · {km} km'**
  String discoverGpxImported(String name, String km);

  /// No description provided for @discoverSavedDotName.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert · {name}'**
  String discoverSavedDotName(String name);

  /// No description provided for @discoverAsActive.
  ///
  /// In de, this message translates to:
  /// **'Als aktiv'**
  String get discoverAsActive;

  /// No description provided for @discoverLocalFoldersHint.
  ///
  /// In de, this message translates to:
  /// **'Lokale Ordner für gespeicherte Routen — kein Social-Feed.'**
  String get discoverLocalFoldersHint;

  /// No description provided for @discoverNoSavedInCollection.
  ///
  /// In de, this message translates to:
  /// **'Keine passenden gespeicherten Routen in dieser Sammlung'**
  String get discoverNoSavedInCollection;

  /// No description provided for @discoverNoCollectionYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Sammlung.'**
  String get discoverNoCollectionYet;

  /// No description provided for @discoverNewCollection.
  ///
  /// In de, this message translates to:
  /// **'Neue Sammlung'**
  String get discoverNewCollection;

  /// No description provided for @discoverNeedRouteAndCollection.
  ///
  /// In de, this message translates to:
  /// **'Braucht mindestens eine gespeicherte Route und eine Sammlung'**
  String get discoverNeedRouteAndCollection;

  /// No description provided for @discoverPickRoute.
  ///
  /// In de, this message translates to:
  /// **'Route wählen'**
  String get discoverPickRoute;

  /// No description provided for @discoverPickCollection.
  ///
  /// In de, this message translates to:
  /// **'Sammlung wählen'**
  String get discoverPickCollection;

  /// No description provided for @discoverAddedToCollection.
  ///
  /// In de, this message translates to:
  /// **'Zur Sammlung hinzugefügt'**
  String get discoverAddedToCollection;

  /// No description provided for @discoverRouteToCollection.
  ///
  /// In de, this message translates to:
  /// **'Route zu Sammlung'**
  String get discoverRouteToCollection;

  /// No description provided for @discoverStartSavedNoTrack.
  ///
  /// In de, this message translates to:
  /// **'Startpunkt gespeichert — noch keine Strecke. Navigieren oder GPX.'**
  String get discoverStartSavedNoTrack;

  /// No description provided for @discoverComputedRoute.
  ///
  /// In de, this message translates to:
  /// **'Berechnete Route'**
  String get discoverComputedRoute;

  /// No description provided for @discoverSavedRoute.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherte Route'**
  String get discoverSavedRoute;

  /// No description provided for @discoverViaN.
  ///
  /// In de, this message translates to:
  /// **'Stopp {n}'**
  String discoverViaN(int n);

  /// No description provided for @discoverTourGone.
  ///
  /// In de, this message translates to:
  /// **'Tour nicht mehr verfügbar'**
  String get discoverTourGone;

  /// No description provided for @discoverTourGoneBody.
  ///
  /// In de, this message translates to:
  /// **'Diese Tour ist gerade nicht in der Liste — z. B. weil ein Filter sie ausschließt.'**
  String get discoverTourGoneBody;

  /// No description provided for @discoverTourTimeline.
  ///
  /// In de, this message translates to:
  /// **'Tourverlauf'**
  String get discoverTourTimeline;

  /// No description provided for @discoverNoTrackYet.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Strecke — „Route berechnen“ baut sie live.'**
  String get discoverNoTrackYet;

  /// No description provided for @discoverDuration.
  ///
  /// In de, this message translates to:
  /// **'Dauer'**
  String get discoverDuration;

  /// No description provided for @discoverLength.
  ///
  /// In de, this message translates to:
  /// **'Länge'**
  String get discoverLength;

  /// No description provided for @discoverAscent.
  ///
  /// In de, this message translates to:
  /// **'Aufstieg'**
  String get discoverAscent;

  /// No description provided for @discoverElevationProfile.
  ///
  /// In de, this message translates to:
  /// **'Höhenprofil'**
  String get discoverElevationProfile;

  /// No description provided for @discoverDescent.
  ///
  /// In de, this message translates to:
  /// **'↓ {m} m Abstieg'**
  String discoverDescent(String m);

  /// No description provided for @discoverTip.
  ///
  /// In de, this message translates to:
  /// **'Tipp'**
  String get discoverTip;

  /// No description provided for @discoverBestTime.
  ///
  /// In de, this message translates to:
  /// **'Beste Zeit'**
  String get discoverBestTime;

  /// No description provided for @discoverDiscipline.
  ///
  /// In de, this message translates to:
  /// **'Disziplin'**
  String get discoverDiscipline;

  /// No description provided for @discoverCorridor.
  ///
  /// In de, this message translates to:
  /// **'Korridor'**
  String get discoverCorridor;

  /// No description provided for @discoverTraits.
  ///
  /// In de, this message translates to:
  /// **'Merkmale'**
  String get discoverTraits;

  /// No description provided for @discoverTipsInfo.
  ///
  /// In de, this message translates to:
  /// **'Tipps & Infos'**
  String get discoverTipsInfo;

  /// No description provided for @discoverStartPoint.
  ///
  /// In de, this message translates to:
  /// **'Startpunkt'**
  String get discoverStartPoint;

  /// No description provided for @discoverFromHereKm.
  ///
  /// In de, this message translates to:
  /// **'{dist} von hier'**
  String discoverFromHereKm(String dist);

  /// No description provided for @discoverApproach.
  ///
  /// In de, this message translates to:
  /// **'Anfahrt'**
  String get discoverApproach;

  /// No description provided for @discoverInMyTours.
  ///
  /// In de, this message translates to:
  /// **'In Meine Touren'**
  String get discoverInMyTours;

  /// No description provided for @discoverPinIdeaNamed.
  ///
  /// In de, this message translates to:
  /// **'Idee „{name}“ — nur Ortspunkt'**
  String discoverPinIdeaNamed(String name);

  /// No description provided for @discoverPinIdea.
  ///
  /// In de, this message translates to:
  /// **'Tour-Idee — nur Ortspunkt auf der Karte'**
  String get discoverPinIdea;

  /// No description provided for @discoverStartEndReady.
  ///
  /// In de, this message translates to:
  /// **'Start/Ziel gesetzt. Route berechnen oder Ziel anpassen.'**
  String get discoverStartEndReady;

  /// No description provided for @discoverComputeAndSave.
  ///
  /// In de, this message translates to:
  /// **'Route berechnen & speichern'**
  String get discoverComputeAndSave;

  /// No description provided for @discoverChangePlaceSearch.
  ///
  /// In de, this message translates to:
  /// **'Ort ändern — Stadt oder Adresse suchen'**
  String get discoverChangePlaceSearch;

  /// No description provided for @discoverDemoRegion.
  ///
  /// In de, this message translates to:
  /// **'Demo-Region: {name}'**
  String discoverDemoRegion(String name);

  /// No description provided for @discoverPickProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil wählen'**
  String get discoverPickProfile;

  /// No description provided for @discoverOwn.
  ///
  /// In de, this message translates to:
  /// **'Eigene'**
  String get discoverOwn;

  /// No description provided for @discoverStartOnlyNoTrack.
  ///
  /// In de, this message translates to:
  /// **'{badge} · Startpunkt — noch keine Strecke'**
  String discoverStartOnlyNoTrack(String badge);

  /// No description provided for @discoverShowLess.
  ///
  /// In de, this message translates to:
  /// **'Weniger anzeigen'**
  String get discoverShowLess;

  /// No description provided for @discoverShowMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr anzeigen'**
  String get discoverShowMore;

  /// No description provided for @discoverTrailView.
  ///
  /// In de, this message translates to:
  /// **'Trail-Ansicht'**
  String get discoverTrailView;

  /// No description provided for @discoverNoPhotosNearby.
  ///
  /// In de, this message translates to:
  /// **'Keine Fotos in der Nähe'**
  String get discoverNoPhotosNearby;

  /// No description provided for @discoverImageUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Bild nicht verfügbar'**
  String get discoverImageUnavailable;

  /// No description provided for @discoverNoLivePhotos.
  ///
  /// In de, this message translates to:
  /// **'Keine Live-Fotos'**
  String get discoverNoLivePhotos;

  /// No description provided for @discoverOpenMapillary.
  ///
  /// In de, this message translates to:
  /// **'Mapillary öffnen'**
  String get discoverOpenMapillary;

  /// No description provided for @discoverMapillarySample.
  ///
  /// In de, this message translates to:
  /// **'Beispiel — Mapillary nicht verfügbar'**
  String get discoverMapillarySample;

  /// No description provided for @discoverNoTrackOnMap.
  ///
  /// In de, this message translates to:
  /// **'Kein Track — erst auf der Karte laden oder GPX.'**
  String get discoverNoTrackOnMap;

  /// No description provided for @discoverNoClosedLoop.
  ///
  /// In de, this message translates to:
  /// **'Kein geschlossener Rundkurs-Track — Tour erneut wählen oder Anpassen.'**
  String get discoverNoClosedLoop;

  /// No description provided for @discoverNoLiveTrackPlan.
  ///
  /// In de, this message translates to:
  /// **'Kein Live-Track — Route berechnen öffnet Planen mit Ziel-Vorschlag.'**
  String get discoverNoLiveTrackPlan;

  /// No description provided for @discoverNotClosedLoopNav.
  ///
  /// In de, this message translates to:
  /// **'Geometrie ist keine geschlossene Runde — Navigation abgebrochen.'**
  String get discoverNotClosedLoopNav;

  /// No description provided for @discoverNoRealPolyline.
  ///
  /// In de, this message translates to:
  /// **'Keine echte Strecke — Route neu berechnen oder GPX.'**
  String get discoverNoRealPolyline;

  /// No description provided for @discoverPoiIdeaHint.
  ///
  /// In de, this message translates to:
  /// **'Anfahrt zum Ortspunkt — kein Tour-Track. Ziel weiterplanen oder GPX.'**
  String get discoverPoiIdeaHint;

  /// No description provided for @discoverHybridKm.
  ///
  /// In de, this message translates to:
  /// **'Hybrid · {km} km'**
  String discoverHybridKm(String km);

  /// No description provided for @discoverAroundPoiComputing.
  ///
  /// In de, this message translates to:
  /// **'Route um Ortspunkt wird berechnet…'**
  String get discoverAroundPoiComputing;

  /// No description provided for @discoverLiveRouteReady.
  ///
  /// In de, this message translates to:
  /// **'Live-Route · {km} km — speichern oder Losfahren'**
  String discoverLiveRouteReady(String km);

  /// No description provided for @discoverPoiNamed.
  ///
  /// In de, this message translates to:
  /// **'Ortspunkt · {name}'**
  String discoverPoiNamed(String name);

  /// No description provided for @discoverNotLoopAb.
  ///
  /// In de, this message translates to:
  /// **'Kein Rundkurs — A→B-Vorschlag gesetzt. „Route berechnen“ oder Ziel tippen.'**
  String get discoverNotLoopAb;

  /// No description provided for @discoverApproxAb.
  ///
  /// In de, this message translates to:
  /// **'Näherungsroute A→B · Ziel auf Karte anpassen, dann erneut berechnen.'**
  String get discoverApproxAb;

  /// No description provided for @discoverRoutingFailedRetry.
  ///
  /// In de, this message translates to:
  /// **'Routing fehlgeschlagen — Ziel tippen und erneut berechnen.'**
  String get discoverRoutingFailedRetry;

  /// No description provided for @discoverUnplausibleDropped.
  ///
  /// In de, this message translates to:
  /// **'Unplausibles Routing-Ergebnis verworfen'**
  String get discoverUnplausibleDropped;

  /// No description provided for @discoverAltChosen.
  ///
  /// In de, this message translates to:
  /// **'Alternative gewählt: {label}'**
  String discoverAltChosen(String label);

  /// No description provided for @discoverLoading.
  ///
  /// In de, this message translates to:
  /// **'Laden'**
  String get discoverLoading;

  /// No description provided for @discoverCatalog.
  ///
  /// In de, this message translates to:
  /// **'Katalog'**
  String get discoverCatalog;

  /// No description provided for @discoverShared.
  ///
  /// In de, this message translates to:
  /// **'freigegeben'**
  String get discoverShared;

  /// No description provided for @discoverPrivate.
  ///
  /// In de, this message translates to:
  /// **'privat'**
  String get discoverPrivate;

  /// No description provided for @discoverPrivateCap.
  ///
  /// In de, this message translates to:
  /// **'Privat'**
  String get discoverPrivateCap;

  /// No description provided for @discoverShareRelease.
  ///
  /// In de, this message translates to:
  /// **'Freigeben'**
  String get discoverShareRelease;

  /// No description provided for @discoverRiddenWith.
  ///
  /// In de, this message translates to:
  /// **'gefahren mit {name}'**
  String discoverRiddenWith(String name);

  /// No description provided for @discoverPrivateCommentHint.
  ///
  /// In de, this message translates to:
  /// **'Noch privat — nach Freigabe können andere kommentieren.'**
  String get discoverPrivateCommentHint;

  /// No description provided for @discoverRemoveFromMappe.
  ///
  /// In de, this message translates to:
  /// **'Aus der Mappe nehmen'**
  String get discoverRemoveFromMappe;

  /// No description provided for @discoverLinkNoTrack.
  ///
  /// In de, this message translates to:
  /// **'Link ohne Spur — zu lang für die URL. Name und Stats, kein GPS.'**
  String get discoverLinkNoTrack;

  /// No description provided for @discoverLinkCopiedTrack.
  ///
  /// In de, this message translates to:
  /// **'Link kopiert. Enthält eine vereinfachte Spur.'**
  String get discoverLinkCopiedTrack;

  /// No description provided for @discoverLinkCopiedStats.
  ///
  /// In de, this message translates to:
  /// **'Link kopiert. Name und Stats, kein Track.'**
  String get discoverLinkCopiedStats;

  /// No description provided for @discoverTrackLocal.
  ///
  /// In de, this message translates to:
  /// **'Track liegt lokal. Sync zwischen deinen Geräten.'**
  String get discoverTrackLocal;

  /// No description provided for @discoverNoTrackEntry.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Track — nur der Eintrag in der Mappe.'**
  String get discoverNoTrackEntry;

  /// No description provided for @discoverVisibility.
  ///
  /// In de, this message translates to:
  /// **'Sichtbarkeit'**
  String get discoverVisibility;

  /// No description provided for @discoverCopyLink.
  ///
  /// In de, this message translates to:
  /// **'Link kopieren'**
  String get discoverCopyLink;

  /// No description provided for @discoverNoSavedFilter.
  ///
  /// In de, this message translates to:
  /// **'Keine Touren in diesem Filter.'**
  String get discoverNoSavedFilter;

  /// No description provided for @discoverMineEmptyHint.
  ///
  /// In de, this message translates to:
  /// **'Noch keine eigenen Strecken — Route hinzufügen, GPX oder aufzeichnen.'**
  String get discoverMineEmptyHint;

  /// No description provided for @overlayLegendTitle.
  ///
  /// In de, this message translates to:
  /// **'Wege · OSM'**
  String get overlayLegendTitle;

  /// No description provided for @overlayLegendCompactCity.
  ///
  /// In de, this message translates to:
  /// **'City'**
  String get overlayLegendCompactCity;

  /// No description provided for @overlayLegendCompactMtb.
  ///
  /// In de, this message translates to:
  /// **'MTB'**
  String get overlayLegendCompactMtb;

  /// No description provided for @overlayScaleNote.
  ///
  /// In de, this message translates to:
  /// **'S0–S3+ nur wenn die Spur bewertet ist. Sonst unbewertet.'**
  String get overlayScaleNote;

  /// No description provided for @overlayRoadAsphalt.
  ///
  /// In de, this message translates to:
  /// **'Radweg / Asphalt'**
  String get overlayRoadAsphalt;

  /// No description provided for @overlayUnrated.
  ///
  /// In de, this message translates to:
  /// **'unbewertet'**
  String get overlayUnrated;

  /// No description provided for @overlayLegendEmpty.
  ///
  /// In de, this message translates to:
  /// **'Kein Overlay an dieser Stelle. OSM-Wege gibt es ab Zoom 12 auf dem DACH-Blatt. Das Radnetz folgt dem Blatt darunter.'**
  String get overlayLegendEmpty;

  /// No description provided for @overlayLegendMeshTitle.
  ///
  /// In de, this message translates to:
  /// **'Radnetz · OSM'**
  String get overlayLegendMeshTitle;

  /// No description provided for @overlayLegendMeshNote.
  ///
  /// In de, this message translates to:
  /// **'Signierte Radrouten (ICN/NCN/RCN) auf diesem Blatt. Wege ab Zoom 12 im ganzen DACH-Blatt.'**
  String get overlayLegendMeshNote;

  /// No description provided for @overlayLegendCompactGravel.
  ///
  /// In de, this message translates to:
  /// **'Gravel'**
  String get overlayLegendCompactGravel;

  /// No description provided for @discoverChipTooltip.
  ///
  /// In de, this message translates to:
  /// **'Touren und Wege nach Radtyp'**
  String get discoverChipTooltip;

  /// No description provided for @discoverLocateLongPress.
  ///
  /// In de, this message translates to:
  /// **'Mein Standort · lange drücken: Navi-Symbol'**
  String get discoverLocateLongPress;

  /// No description provided for @discoverNavHonestyBike.
  ///
  /// In de, this message translates to:
  /// **'Rad-Profile: dieselbe Route'**
  String get discoverNavHonestyBike;

  /// No description provided for @discoverNavHonestyFoot.
  ///
  /// In de, this message translates to:
  /// **'Navi: Zu Fuß'**
  String get discoverNavHonestyFoot;

  /// No description provided for @stimmenTitle.
  ///
  /// In de, this message translates to:
  /// **'Stimmen'**
  String get stimmenTitle;

  /// No description provided for @stimmenHint.
  ///
  /// In de, this message translates to:
  /// **'Sterne, Text und Fotos — Cloud nach Freigabe. Keine erfundenen Stimmen.'**
  String get stimmenHint;

  /// No description provided for @stimmenWrite.
  ///
  /// In de, this message translates to:
  /// **'Stimme schreiben'**
  String get stimmenWrite;

  /// No description provided for @stimmenHowWas.
  ///
  /// In de, this message translates to:
  /// **'Wie war die Tour?'**
  String get stimmenHowWas;

  /// No description provided for @stimmenEmptyName.
  ///
  /// In de, this message translates to:
  /// **'Leer bleibt Du'**
  String get stimmenEmptyName;

  /// No description provided for @stimmenAddPhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto hinzufügen'**
  String get stimmenAddPhoto;

  /// No description provided for @stimmenSaving.
  ///
  /// In de, this message translates to:
  /// **'Speichern …'**
  String get stimmenSaving;

  /// No description provided for @stimmenShareSubject.
  ///
  /// In de, this message translates to:
  /// **'Tour teilen'**
  String get stimmenShareSubject;

  /// No description provided for @stimmenEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Stimmen.'**
  String get stimmenEmpty;

  /// No description provided for @stimmenLabel.
  ///
  /// In de, this message translates to:
  /// **'Stimme'**
  String get stimmenLabel;

  /// No description provided for @stimmenCloudApproved.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert — veröffentlicht (AI-Freigabe)'**
  String get stimmenCloudApproved;

  /// No description provided for @stimmenCloudRejected.
  ///
  /// In de, this message translates to:
  /// **'Lokal gespeichert — Cloud hat den Text abgelehnt'**
  String get stimmenCloudRejected;

  /// No description provided for @stimmenCloudPending.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert — lokal und in Prüfung (AI/Mensch)'**
  String get stimmenCloudPending;

  /// No description provided for @stimmenCloudLocal.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert — lokal (Cloud nach Login)'**
  String get stimmenCloudLocal;

  /// No description provided for @stimmenCloudFailed.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert lokal — Cloud gerade nicht erreichbar'**
  String get stimmenCloudFailed;

  /// No description provided for @akteHonestyCatalog.
  ///
  /// In de, this message translates to:
  /// **'Katalog-Tour ist schon öffentlich. Freigeben macht deine Akte teilbar — der Link zeigt Name und Stats, keinen privaten Extra-Track.'**
  String get akteHonestyCatalog;

  /// No description provided for @akteHonestyTrack.
  ///
  /// In de, this message translates to:
  /// **'Freigeben erzeugt einen Link. Der Link enthält eine vereinfachte Spur (Koordinaten), nicht nur den Namen. Zurück auf Privat nimmt die Tour aus Filtern und speichert den Widerruf auf dem Server, wenn du eingeloggt bist. Ohne Login gilt er nur auf diesem Gerät.'**
  String get akteHonestyTrack;

  /// No description provided for @akteHonestyNoTrack.
  ///
  /// In de, this message translates to:
  /// **'Freigeben erzeugt einen Link mit Name und Stats — ohne Track, weil keiner gespeichert ist.'**
  String get akteHonestyNoTrack;

  /// No description provided for @stimmenSubmit.
  ///
  /// In de, this message translates to:
  /// **'Absenden'**
  String get stimmenSubmit;

  /// No description provided for @ortSheetVia.
  ///
  /// In de, this message translates to:
  /// **'Als Zwischenziel'**
  String get ortSheetVia;

  /// No description provided for @ortSheetHere.
  ///
  /// In de, this message translates to:
  /// **'Touren hierher'**
  String get ortSheetHere;

  /// No description provided for @ortSheetMaps.
  ///
  /// In de, this message translates to:
  /// **'In Maps öffnen'**
  String get ortSheetMaps;

  /// No description provided for @ortKindCafe.
  ///
  /// In de, this message translates to:
  /// **'Café'**
  String get ortKindCafe;

  /// No description provided for @ortKindWater.
  ///
  /// In de, this message translates to:
  /// **'Wasser'**
  String get ortKindWater;

  /// No description provided for @ortKindViewpoint.
  ///
  /// In de, this message translates to:
  /// **'Aussicht'**
  String get ortKindViewpoint;

  /// No description provided for @ortKindShop.
  ///
  /// In de, this message translates to:
  /// **'Laden'**
  String get ortKindShop;

  /// No description provided for @ortKindRepair.
  ///
  /// In de, this message translates to:
  /// **'Werkstatt'**
  String get ortKindRepair;

  /// No description provided for @ortKindTrailhead.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get ortKindTrailhead;

  /// No description provided for @ortKindTip.
  ///
  /// In de, this message translates to:
  /// **'Tipp'**
  String get ortKindTip;

  /// No description provided for @ortKindMeet.
  ///
  /// In de, this message translates to:
  /// **'Treffpunkt'**
  String get ortKindMeet;

  /// No description provided for @ortKindOther.
  ///
  /// In de, this message translates to:
  /// **'Ort'**
  String get ortKindOther;

  /// No description provided for @viaMoveUp.
  ///
  /// In de, this message translates to:
  /// **'Nach oben'**
  String get viaMoveUp;

  /// No description provided for @viaMoveDown.
  ///
  /// In de, this message translates to:
  /// **'Nach unten'**
  String get viaMoveDown;

  /// No description provided for @stimmeTagsHint.
  ///
  /// In de, this message translates to:
  /// **'Zustand — optional, max. drei'**
  String get stimmeTagsHint;

  /// No description provided for @stimmeTagNass.
  ///
  /// In de, this message translates to:
  /// **'nass'**
  String get stimmeTagNass;

  /// No description provided for @stimmeTagZu.
  ///
  /// In de, this message translates to:
  /// **'zu'**
  String get stimmeTagZu;

  /// No description provided for @stimmeTagVielLos.
  ///
  /// In de, this message translates to:
  /// **'viel los'**
  String get stimmeTagVielLos;

  /// No description provided for @stimmeTagTop.
  ///
  /// In de, this message translates to:
  /// **'top'**
  String get stimmeTagTop;

  /// No description provided for @stimmeTagBaustelle.
  ///
  /// In de, this message translates to:
  /// **'Baustelle'**
  String get stimmeTagBaustelle;

  /// No description provided for @postRideStimmeTitle.
  ///
  /// In de, this message translates to:
  /// **'Stimme zur Tour?'**
  String get postRideStimmeTitle;

  /// No description provided for @postRideStimmeHint.
  ///
  /// In de, this message translates to:
  /// **'Nur diese Tour, kein Track im Text. Skip ist in Ordnung.'**
  String get postRideStimmeHint;

  /// No description provided for @postRideStimmePrivate.
  ///
  /// In de, this message translates to:
  /// **'Stimme erst nach Freigabe. Die Tour ist privat — in der Akte unter Mein teilen.'**
  String get postRideStimmePrivate;

  /// No description provided for @postRideStimmePrivateCta.
  ///
  /// In de, this message translates to:
  /// **'In der Akte freigeben'**
  String get postRideStimmePrivateCta;

  /// No description provided for @postRideStimmeSkip.
  ///
  /// In de, this message translates to:
  /// **'Jetzt nicht'**
  String get postRideStimmeSkip;

  /// No description provided for @postRideStimmeDone.
  ///
  /// In de, this message translates to:
  /// **'Stimme gespeichert.'**
  String get postRideStimmeDone;

  /// No description provided for @postRideOrtTitle.
  ///
  /// In de, this message translates to:
  /// **'Ort merken?'**
  String get postRideOrtTitle;

  /// No description provided for @postRideOrtHint.
  ///
  /// In de, this message translates to:
  /// **'Immer privat an der Runde. Öffentlich nur mit Login, auf der Linie, nach Freigabe.'**
  String get postRideOrtHint;

  /// No description provided for @postRideOrtSkip.
  ///
  /// In de, this message translates to:
  /// **'Jetzt nicht'**
  String get postRideOrtSkip;

  /// No description provided for @postRideOrtDone.
  ///
  /// In de, this message translates to:
  /// **'Ort gespeichert.'**
  String get postRideOrtDone;

  /// No description provided for @postRideOrtNameHint.
  ///
  /// In de, this message translates to:
  /// **'Name des Orts'**
  String get postRideOrtNameHint;

  /// No description provided for @postRideOrtSave.
  ///
  /// In de, this message translates to:
  /// **'Merken'**
  String get postRideOrtSave;

  /// No description provided for @postRideOrtOffTrack.
  ///
  /// In de, this message translates to:
  /// **'Kein Punkt auf der gefahrenen Linie — nur private Notiz, ohne Pin.'**
  String get postRideOrtOffTrack;

  /// No description provided for @postRideOrtPrivateOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur für dich — ohne Login oder ohne öffentliche Tour kein Community-Ort.'**
  String get postRideOrtPrivateOnly;

  /// No description provided for @postRideOrtPending.
  ///
  /// In de, this message translates to:
  /// **'Ort merkt die Cloud nach Freigabe. Bis dahin nur auf dem Gerät.'**
  String get postRideOrtPending;

  /// No description provided for @postRideOrtFailed.
  ///
  /// In de, this message translates to:
  /// **'Cloud hat den Ort nicht genommen — bleibt privat auf dem Gerät.'**
  String get postRideOrtFailed;

  /// No description provided for @stimmeDifficultyHint.
  ///
  /// In de, this message translates to:
  /// **'Schwierigkeit gegenüber der Markierung — optional'**
  String get stimmeDifficultyHint;

  /// No description provided for @stimmeDifficultyEasier.
  ///
  /// In de, this message translates to:
  /// **'leichter'**
  String get stimmeDifficultyEasier;

  /// No description provided for @stimmeDifficultyAsMarked.
  ///
  /// In de, this message translates to:
  /// **'wie markiert'**
  String get stimmeDifficultyAsMarked;

  /// No description provided for @stimmeDifficultyHarder.
  ///
  /// In de, this message translates to:
  /// **'härter'**
  String get stimmeDifficultyHarder;

  /// No description provided for @akteDifficultyCrowdEasier.
  ///
  /// In de, this message translates to:
  /// **'Fahrer: eher leichter als markiert ({n})'**
  String akteDifficultyCrowdEasier(int n);

  /// No description provided for @akteDifficultyCrowdAsMarked.
  ///
  /// In de, this message translates to:
  /// **'Fahrer: wie markiert ({n})'**
  String akteDifficultyCrowdAsMarked(int n);

  /// No description provided for @akteDifficultyCrowdHarder.
  ///
  /// In de, this message translates to:
  /// **'Fahrer: eher härter als markiert ({n})'**
  String akteDifficultyCrowdHarder(int n);

  /// No description provided for @akteAddToCollection.
  ///
  /// In de, this message translates to:
  /// **'Zu Sammlung'**
  String get akteAddToCollection;

  /// No description provided for @discoverEditorialSets.
  ///
  /// In de, this message translates to:
  /// **'Redaktion'**
  String get discoverEditorialSets;

  /// No description provided for @discoverEditorialHonesty.
  ///
  /// In de, this message translates to:
  /// **'Redaktionelle Ideen — keine User-Sammlungen.'**
  String get discoverEditorialHonesty;

  /// No description provided for @discoverEditorialEmpty.
  ///
  /// In de, this message translates to:
  /// **'Diese Region ist im Katalog, die Touren sind gerade nicht in der Liste.'**
  String get discoverEditorialEmpty;

  /// No description provided for @discoverLayerTours.
  ///
  /// In de, this message translates to:
  /// **'Touren'**
  String get discoverLayerTours;

  /// No description provided for @discoverLayerPlaces.
  ///
  /// In de, this message translates to:
  /// **'Orte'**
  String get discoverLayerPlaces;

  /// No description provided for @discoverLayerHeat.
  ///
  /// In de, this message translates to:
  /// **'Heat'**
  String get discoverLayerHeat;

  /// No description provided for @discoverLayerHeatOff.
  ///
  /// In de, this message translates to:
  /// **'Heat aus'**
  String get discoverLayerHeatOff;

  /// No description provided for @discoverVariantPlanned.
  ///
  /// In de, this message translates to:
  /// **'Wie geplant'**
  String get discoverVariantPlanned;

  /// No description provided for @discoverVariantFlatter.
  ///
  /// In de, this message translates to:
  /// **'Weniger hm'**
  String get discoverVariantFlatter;

  /// No description provided for @discoverVariantUnpaved.
  ///
  /// In de, this message translates to:
  /// **'Mehr unpaved'**
  String get discoverVariantUnpaved;

  /// No description provided for @discoverVariantValhallaOnly.
  ///
  /// In de, this message translates to:
  /// **'Varianten nur mit Live-Valhalla'**
  String get discoverVariantValhallaOnly;

  /// No description provided for @discoverTrailWet.
  ///
  /// In de, this message translates to:
  /// **'eher nass'**
  String get discoverTrailWet;

  /// No description provided for @discoverTrailDamp.
  ///
  /// In de, this message translates to:
  /// **'feucht möglich'**
  String get discoverTrailDamp;

  /// No description provided for @discoverTrailDry.
  ///
  /// In de, this message translates to:
  /// **'eher trocken'**
  String get discoverTrailDry;

  /// No description provided for @discoverWeatherStart.
  ///
  /// In de, this message translates to:
  /// **'Start {temp}° · {hint}'**
  String discoverWeatherStart(String temp, String hint);

  /// No description provided for @discoverWeatherSummit.
  ///
  /// In de, this message translates to:
  /// **'Gipfel {temp}° · {hint}'**
  String discoverWeatherSummit(String temp, String hint);

  /// No description provided for @discoverFilmstripAttribution.
  ///
  /// In de, this message translates to:
  /// **'Mapillary CC BY-SA'**
  String get discoverFilmstripAttribution;

  /// No description provided for @discoverOfflineAfterSave.
  ///
  /// In de, this message translates to:
  /// **'Region für offline laden?'**
  String get discoverOfflineAfterSave;

  /// No description provided for @discoverOfflineAfterSaveAction.
  ///
  /// In de, this message translates to:
  /// **'Packs'**
  String get discoverOfflineAfterSaveAction;

  /// No description provided for @discoverRoundTrip.
  ///
  /// In de, this message translates to:
  /// **'Hin & zurück'**
  String get discoverRoundTrip;

  /// No description provided for @discoverOutboundOnly.
  ///
  /// In de, this message translates to:
  /// **'nur Hinweg'**
  String get discoverOutboundOnly;

  /// No description provided for @discoverOsmNoHitsSuffix.
  ///
  /// In de, this message translates to:
  /// **' · keine Wege-Treffer'**
  String get discoverOsmNoHitsSuffix;

  /// No description provided for @discoverLiveRoutingUnavailable.
  ///
  /// In de, this message translates to:
  /// **' · Live-Routing nicht verfügbar'**
  String get discoverLiveRoutingUnavailable;

  /// No description provided for @discoverUnplausibleLive.
  ///
  /// In de, this message translates to:
  /// **' · Live-Routing lieferte kein plausibles Ergebnis'**
  String get discoverUnplausibleLive;

  /// No description provided for @discoverTapEndCompute.
  ///
  /// In de, this message translates to:
  /// **'Ziel tippen oder Adresse — dann Route berechnen.'**
  String get discoverTapEndCompute;

  /// No description provided for @discoverPlanYourself.
  ///
  /// In de, this message translates to:
  /// **'Route selbst planen — Start & Ziel setzen'**
  String get discoverPlanYourself;

  /// No description provided for @discoverLoopBadge.
  ///
  /// In de, this message translates to:
  /// **'⟲ Rundkurs'**
  String get discoverLoopBadge;

  /// No description provided for @discoverElevMin.
  ///
  /// In de, this message translates to:
  /// **'Min {min}'**
  String discoverElevMin(Object min);

  /// No description provided for @discoverHeatmapOffline.
  ///
  /// In de, this message translates to:
  /// **'Heatmap offline'**
  String get discoverHeatmapOffline;

  /// No description provided for @discoverCreate.
  ///
  /// In de, this message translates to:
  /// **'Anlegen'**
  String get discoverCreate;

  /// No description provided for @discoverRegionSource.
  ///
  /// In de, this message translates to:
  /// **'Region'**
  String get discoverRegionSource;

  /// No description provided for @discoverTourNoun.
  ///
  /// In de, this message translates to:
  /// **'Tour'**
  String get discoverTourNoun;

  /// No description provided for @discoverOsmLive.
  ///
  /// In de, this message translates to:
  /// **'OSM live'**
  String get discoverOsmLive;

  /// No description provided for @discoverApproachParen.
  ///
  /// In de, this message translates to:
  /// **'({name})'**
  String discoverApproachParen(Object name);

  /// No description provided for @discoverShop.
  ///
  /// In de, this message translates to:
  /// **'Laden'**
  String get discoverShop;

  /// No description provided for @discoverPreview.
  ///
  /// In de, this message translates to:
  /// **'Vorschau'**
  String get discoverPreview;

  /// No description provided for @discoverApproachName.
  ///
  /// In de, this message translates to:
  /// **'{name} (Anfahrt)'**
  String discoverApproachName(Object name);

  /// No description provided for @discoverFromHereName.
  ///
  /// In de, this message translates to:
  /// **'{name} (von hier)'**
  String discoverFromHereName(Object name);

  /// No description provided for @rideLocationOff.
  ///
  /// In de, this message translates to:
  /// **'Standort aus'**
  String get rideLocationOff;

  /// No description provided for @rideLocationOffBody.
  ///
  /// In de, this message translates to:
  /// **'Ohne Standort kein GPS-Track. Bitte Ortungsdienste einschalten.'**
  String get rideLocationOffBody;

  /// No description provided for @rideSettings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get rideSettings;

  /// No description provided for @rideLocationPermission.
  ///
  /// In de, this message translates to:
  /// **'Standort-Berechtigung'**
  String get rideLocationPermission;

  /// No description provided for @rideLocationDeniedForever.
  ///
  /// In de, this message translates to:
  /// **'Standort dauerhaft verweigert. In den App-Einstellungen freigeben, sonst bleibt der Track leer.'**
  String get rideLocationDeniedForever;

  /// No description provided for @rideAppSettings.
  ///
  /// In de, this message translates to:
  /// **'App-Einstellungen'**
  String get rideAppSettings;

  /// No description provided for @rideLocationNeeded.
  ///
  /// In de, this message translates to:
  /// **'Standort nötig für Track & Navigation — erneut starten und erlauben.'**
  String get rideLocationNeeded;

  /// No description provided for @rideGpsFix.
  ///
  /// In de, this message translates to:
  /// **'GPS-Fix…'**
  String get rideGpsFix;

  /// No description provided for @rideGpsFixN.
  ///
  /// In de, this message translates to:
  /// **'GPS-Fix {count}…'**
  String rideGpsFixN(Object count);

  /// No description provided for @rideGpsStillSim.
  ///
  /// In de, this message translates to:
  /// **'GPS still — Sim-Track (nicht speichern)'**
  String get rideGpsStillSim;

  /// No description provided for @rideGpsStillWeak.
  ///
  /// In de, this message translates to:
  /// **'GPS still — Signal schwach / Stand'**
  String get rideGpsStillWeak;

  /// No description provided for @rideGpsSimActive.
  ///
  /// In de, this message translates to:
  /// **'Sim-Track aktiv (AETHER_SIM_MOTION)'**
  String get rideGpsSimActive;

  /// No description provided for @rideBleOffSnack.
  ///
  /// In de, this message translates to:
  /// **'Bluetooth aus — Fahren auch ohne Sensor möglich; später verbinden.'**
  String get rideBleOffSnack;

  /// No description provided for @rideBleDeniedSnack.
  ///
  /// In de, this message translates to:
  /// **'Nearby/Bluetooth verweigert — GPS-Navigation läuft ohne Sensor.'**
  String get rideBleDeniedSnack;

  /// No description provided for @rideNoBikeSensor.
  ///
  /// In de, this message translates to:
  /// **'Kein Radsensor gefunden — GPS-Track läuft weiter.'**
  String get rideNoBikeSensor;

  /// No description provided for @rideOfflineRerouteToast.
  ///
  /// In de, this message translates to:
  /// **'Reroute braucht Internet. Auf der geladenen Route bleiben.'**
  String get rideOfflineRerouteToast;

  /// No description provided for @rideStayOnTrail.
  ///
  /// In de, this message translates to:
  /// **'Auf dem Trail bleiben — keine Straßen-Umleitung.'**
  String get rideStayOnTrail;

  /// No description provided for @rideFollowTrail.
  ///
  /// In de, this message translates to:
  /// **'Trail folgen'**
  String get rideFollowTrail;

  /// No description provided for @rideNoGpsRejoin.
  ///
  /// In de, this message translates to:
  /// **'Kein GPS-Fix für Rejoin'**
  String get rideNoGpsRejoin;

  /// No description provided for @rideRejoinFailed.
  ///
  /// In de, this message translates to:
  /// **'Rejoin fehlgeschlagen: {error}'**
  String rideRejoinFailed(Object error);

  /// No description provided for @rideSkipAheadWhy.
  ///
  /// In de, this message translates to:
  /// **'Abschnitt übersprungen — zurück zur Route.'**
  String get rideSkipAheadWhy;

  /// No description provided for @rideRejoinWhy.
  ///
  /// In de, this message translates to:
  /// **'Zurück zur Route.'**
  String get rideRejoinWhy;

  /// No description provided for @rideSkipAheadTts.
  ///
  /// In de, this message translates to:
  /// **'Abschnitt übersprungen'**
  String get rideSkipAheadTts;

  /// No description provided for @rideRouteRestoredTts.
  ///
  /// In de, this message translates to:
  /// **'Route wiederhergestellt'**
  String get rideRouteRestoredTts;

  /// No description provided for @rideOffRouteTts.
  ///
  /// In de, this message translates to:
  /// **'Abseits der Route'**
  String get rideOffRouteTts;

  /// No description provided for @rideRerouting.
  ///
  /// In de, this message translates to:
  /// **'Route wird neu berechnet …'**
  String get rideRerouting;

  /// No description provided for @rideUndo10s.
  ///
  /// In de, this message translates to:
  /// **'10 s Rückgängig'**
  String get rideUndo10s;

  /// No description provided for @rideUndo.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get rideUndo;

  /// No description provided for @rideStayOffHint.
  ///
  /// In de, this message translates to:
  /// **'Du bleibst abseits — tippe für Optionen.'**
  String get rideStayOffHint;

  /// No description provided for @rideRecalc.
  ///
  /// In de, this message translates to:
  /// **'Neu berechnen …'**
  String get rideRecalc;

  /// No description provided for @rideTapOptions.
  ///
  /// In de, this message translates to:
  /// **'Tippe für Optionen.'**
  String get rideTapOptions;

  /// No description provided for @rideOptions.
  ///
  /// In de, this message translates to:
  /// **'Optionen'**
  String get rideOptions;

  /// No description provided for @ridePause.
  ///
  /// In de, this message translates to:
  /// **'Pause'**
  String get ridePause;

  /// No description provided for @rideResume.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get rideResume;

  /// No description provided for @rideRunning.
  ///
  /// In de, this message translates to:
  /// **'Fahrt läuft'**
  String get rideRunning;

  /// No description provided for @rideStop.
  ///
  /// In de, this message translates to:
  /// **'Beenden'**
  String get rideStop;

  /// No description provided for @rideTapAgain.
  ///
  /// In de, this message translates to:
  /// **'Nochmal tippen'**
  String get rideTapAgain;

  /// No description provided for @rideStopNeedsTwo.
  ///
  /// In de, this message translates to:
  /// **'Beenden erfordert 2 Tipps'**
  String get rideStopNeedsTwo;

  /// No description provided for @rideQuietDisplay.
  ///
  /// In de, this message translates to:
  /// **'Ruhige Anzeige'**
  String get rideQuietDisplay;

  /// No description provided for @rideFollowCamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera folgen'**
  String get rideFollowCamera;

  /// No description provided for @rideFollowOn.
  ///
  /// In de, this message translates to:
  /// **'Kamera-Follow an'**
  String get rideFollowOn;

  /// No description provided for @rideFollowFree.
  ///
  /// In de, this message translates to:
  /// **'Kamera frei'**
  String get rideFollowFree;

  /// No description provided for @rideLiveRide.
  ///
  /// In de, this message translates to:
  /// **'Live-Fahrt'**
  String get rideLiveRide;

  /// No description provided for @rideReady.
  ///
  /// In de, this message translates to:
  /// **'Bereit'**
  String get rideReady;

  /// No description provided for @rideTtsOn.
  ///
  /// In de, this message translates to:
  /// **'TTS an'**
  String get rideTtsOn;

  /// No description provided for @rideTtsMute.
  ///
  /// In de, this message translates to:
  /// **'TTS stumm'**
  String get rideTtsMute;

  /// No description provided for @rideNorthUp.
  ///
  /// In de, this message translates to:
  /// **'Norden oben'**
  String get rideNorthUp;

  /// No description provided for @rideHeadingUp.
  ///
  /// In de, this message translates to:
  /// **'Fahrtrichtung oben'**
  String get rideHeadingUp;

  /// No description provided for @rideHeadingCourse.
  ///
  /// In de, this message translates to:
  /// **'{mode}, Kurs {cardinal}'**
  String rideHeadingCourse(Object cardinal, Object mode);

  /// No description provided for @rideAutoRerouteOn.
  ///
  /// In de, this message translates to:
  /// **'Auto-Reroute an'**
  String get rideAutoRerouteOn;

  /// No description provided for @rideAutoRerouteOff.
  ///
  /// In de, this message translates to:
  /// **'Auto-Reroute aus'**
  String get rideAutoRerouteOff;

  /// No description provided for @rideAutoRerouteActive.
  ///
  /// In de, this message translates to:
  /// **'Auto-Reroute aktiv (Cooldown {sec}s)'**
  String rideAutoRerouteActive(Object sec);

  /// No description provided for @rideAutoRerouteManual.
  ///
  /// In de, this message translates to:
  /// **'Auto-Reroute aus — manueller Rejoin bleibt'**
  String get rideAutoRerouteManual;

  /// No description provided for @rideSunlightAuto.
  ///
  /// In de, this message translates to:
  /// **'Sunlight Mode (Auto)'**
  String get rideSunlightAuto;

  /// No description provided for @rideSunlightManual.
  ///
  /// In de, this message translates to:
  /// **'Sunlight Mode (Manuell)'**
  String get rideSunlightManual;

  /// No description provided for @rideDisplayNamed.
  ///
  /// In de, this message translates to:
  /// **'Display: {name}'**
  String rideDisplayNamed(Object name);

  /// No description provided for @rideDisplayNamedBattery.
  ///
  /// In de, this message translates to:
  /// **'Display: {name} (kostet Akku)'**
  String rideDisplayNamedBattery(Object name);

  /// No description provided for @rideCostsBattery.
  ///
  /// In de, this message translates to:
  /// **'kostet Akku'**
  String get rideCostsBattery;

  /// No description provided for @rideBatteryTitle.
  ///
  /// In de, this message translates to:
  /// **'Display & Akku'**
  String get rideBatteryTitle;

  /// No description provided for @rideBatteryHint.
  ///
  /// In de, this message translates to:
  /// **'Display an lassen? Mehr Akku-Verbrauch. Standard spart Akku.'**
  String get rideBatteryHint;

  /// No description provided for @rideBatteryPocketSnack.
  ///
  /// In de, this message translates to:
  /// **'Pocket — Display darf aus (Akku sparen).'**
  String get rideBatteryPocketSnack;

  /// No description provided for @rideBatteryLenkerSnack.
  ///
  /// In de, this message translates to:
  /// **'Lenker — Display an (kostet Akku).'**
  String get rideBatteryLenkerSnack;

  /// No description provided for @rideBatteryUltraSnack.
  ///
  /// In de, this message translates to:
  /// **'Ultra — Display nur bei Abbiegen (kostet Akku).'**
  String get rideBatteryUltraSnack;

  /// No description provided for @rideBatteryPocket.
  ///
  /// In de, this message translates to:
  /// **'Pocket'**
  String get rideBatteryPocket;

  /// No description provided for @rideBatteryLenker.
  ///
  /// In de, this message translates to:
  /// **'Lenker'**
  String get rideBatteryLenker;

  /// No description provided for @rideBatteryUltra.
  ///
  /// In de, this message translates to:
  /// **'Ultra'**
  String get rideBatteryUltra;

  /// No description provided for @rideBatteryPocketSub.
  ///
  /// In de, this message translates to:
  /// **'Stimme + Haptik, Display darf aus'**
  String get rideBatteryPocketSub;

  /// No description provided for @rideBatteryLenkerSub.
  ///
  /// In de, this message translates to:
  /// **'Display an lassen'**
  String get rideBatteryLenkerSub;

  /// No description provided for @rideBatteryUltraSub.
  ///
  /// In de, this message translates to:
  /// **'Display nur bei Abbiegen wecken'**
  String get rideBatteryUltraSub;

  /// No description provided for @rideDefault.
  ///
  /// In de, this message translates to:
  /// **'Standard'**
  String get rideDefault;

  /// No description provided for @rideSpeed.
  ///
  /// In de, this message translates to:
  /// **'Tempo'**
  String get rideSpeed;

  /// No description provided for @rideSensorSpeed.
  ///
  /// In de, this message translates to:
  /// **'Sensor-Tempo'**
  String get rideSensorSpeed;

  /// No description provided for @rideDistance.
  ///
  /// In de, this message translates to:
  /// **'Distanz'**
  String get rideDistance;

  /// No description provided for @rideTime.
  ///
  /// In de, this message translates to:
  /// **'Zeit'**
  String get rideTime;

  /// No description provided for @rideHeart.
  ///
  /// In de, this message translates to:
  /// **'Puls'**
  String get rideHeart;

  /// No description provided for @rideHeartWaiting.
  ///
  /// In de, this message translates to:
  /// **'Puls wartet'**
  String get rideHeartWaiting;

  /// No description provided for @rideCadence.
  ///
  /// In de, this message translates to:
  /// **'Kadenz'**
  String get rideCadence;

  /// No description provided for @rideBikeSensor.
  ///
  /// In de, this message translates to:
  /// **'Radsensor'**
  String get rideBikeSensor;

  /// No description provided for @rideWatch.
  ///
  /// In de, this message translates to:
  /// **'Smartwatch'**
  String get rideWatch;

  /// No description provided for @rideConnected.
  ///
  /// In de, this message translates to:
  /// **'Verbunden'**
  String get rideConnected;

  /// No description provided for @ridePower.
  ///
  /// In de, this message translates to:
  /// **'Leistung'**
  String get ridePower;

  /// No description provided for @rideSoc.
  ///
  /// In de, this message translates to:
  /// **'Akku'**
  String get rideSoc;

  /// No description provided for @rideAssist.
  ///
  /// In de, this message translates to:
  /// **'Assist'**
  String get rideAssist;

  /// No description provided for @rideBatteryChip.
  ///
  /// In de, this message translates to:
  /// **'Akku'**
  String get rideBatteryChip;

  /// No description provided for @rideWheelSpeed.
  ///
  /// In de, this message translates to:
  /// **'Rad'**
  String get rideWheelSpeed;

  /// No description provided for @rideRestKm.
  ///
  /// In de, this message translates to:
  /// **'noch km'**
  String get rideRestKm;

  /// No description provided for @rideUntilJoin.
  ///
  /// In de, this message translates to:
  /// **'bis Route'**
  String get rideUntilJoin;

  /// No description provided for @rideRestLoop.
  ///
  /// In de, this message translates to:
  /// **'Rest Runde'**
  String get rideRestLoop;

  /// No description provided for @rideKmToRoute.
  ///
  /// In de, this message translates to:
  /// **'{km} km zur Route'**
  String rideKmToRoute(String km);

  /// No description provided for @rideEta.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get rideEta;

  /// No description provided for @rideKmh.
  ///
  /// In de, this message translates to:
  /// **'km/h'**
  String get rideKmh;

  /// No description provided for @rideKm.
  ///
  /// In de, this message translates to:
  /// **'km'**
  String get rideKm;

  /// No description provided for @rideChassisOff.
  ///
  /// In de, this message translates to:
  /// **'Fahrwerksanalyse aus'**
  String get rideChassisOff;

  /// No description provided for @rideChassisHint.
  ///
  /// In de, this message translates to:
  /// **'Handy am Lenker befestigen und als montiert markieren.'**
  String get rideChassisHint;

  /// No description provided for @rideMarkMounted.
  ///
  /// In de, this message translates to:
  /// **'Als montiert markieren'**
  String get rideMarkMounted;

  /// No description provided for @rideWaitingSensors.
  ///
  /// In de, this message translates to:
  /// **'Warte auf Sensorik…'**
  String get rideWaitingSensors;

  /// No description provided for @rideThereafter.
  ///
  /// In de, this message translates to:
  /// **'Danach'**
  String get rideThereafter;

  /// No description provided for @rideAutoLock.
  ///
  /// In de, this message translates to:
  /// **'Auto-Lock'**
  String get rideAutoLock;

  /// No description provided for @rideAutoLockHint.
  ///
  /// In de, this message translates to:
  /// **'Tippen zum Aufwecken'**
  String get rideAutoLockHint;

  /// No description provided for @rideWake.
  ///
  /// In de, this message translates to:
  /// **'Aufwecken'**
  String get rideWake;

  /// No description provided for @rideMusicHud.
  ///
  /// In de, this message translates to:
  /// **'Musik im HUD'**
  String get rideMusicHud;

  /// No description provided for @rideMusicHudHint.
  ///
  /// In de, this message translates to:
  /// **'Titel von Spotify & Co. anzeigen'**
  String get rideMusicHudHint;

  /// No description provided for @rideDismissHint.
  ///
  /// In de, this message translates to:
  /// **'Hinweis schließen'**
  String get rideDismissHint;

  /// No description provided for @rideMusicControls.
  ///
  /// In de, this message translates to:
  /// **'Musiksteuerung'**
  String get rideMusicControls;

  /// No description provided for @ridePrevTrack.
  ///
  /// In de, this message translates to:
  /// **'Vorheriger Titel'**
  String get ridePrevTrack;

  /// No description provided for @rideNextTrack.
  ///
  /// In de, this message translates to:
  /// **'Nächster Titel'**
  String get rideNextTrack;

  /// No description provided for @ridePlay.
  ///
  /// In de, this message translates to:
  /// **'Abspielen'**
  String get ridePlay;

  /// No description provided for @rideNavSymbol.
  ///
  /// In de, this message translates to:
  /// **'Symbol'**
  String get rideNavSymbol;

  /// No description provided for @rideChangeNavSymbol.
  ///
  /// In de, this message translates to:
  /// **'Navi-Symbol ändern'**
  String get rideChangeNavSymbol;

  /// No description provided for @rideNavPuckTitle.
  ///
  /// In de, this message translates to:
  /// **'Navi-Symbol'**
  String get rideNavPuckTitle;

  /// No description provided for @rideNavPuckHint.
  ///
  /// In de, this message translates to:
  /// **'Alle Varianten auf dunkel und hell. Tippen wählt das Symbol für Karte und HUD. 0° = Spitze oben.'**
  String get rideNavPuckHint;

  /// No description provided for @rideRecommend.
  ///
  /// In de, this message translates to:
  /// **'Empfehlung'**
  String get rideRecommend;

  /// No description provided for @ridePuckDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get ridePuckDark;

  /// No description provided for @ridePuckLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get ridePuckLight;

  /// No description provided for @ridePuckBergA.
  ///
  /// In de, this message translates to:
  /// **'Berg-A'**
  String get ridePuckBergA;

  /// No description provided for @ridePuckTopDown.
  ///
  /// In de, this message translates to:
  /// **'Rad von oben'**
  String get ridePuckTopDown;

  /// No description provided for @ridePuckHofTor.
  ///
  /// In de, this message translates to:
  /// **'Hof-Tor'**
  String get ridePuckHofTor;

  /// No description provided for @ridePuckKomet.
  ///
  /// In de, this message translates to:
  /// **'Aether-Komet'**
  String get ridePuckKomet;

  /// No description provided for @ridePuckKiesel.
  ///
  /// In de, this message translates to:
  /// **'Kiesel'**
  String get ridePuckKiesel;

  /// No description provided for @ridePuckLenkerBug.
  ///
  /// In de, this message translates to:
  /// **'Lenker-Bug'**
  String get ridePuckLenkerBug;

  /// No description provided for @ridePuckLichtkegel.
  ///
  /// In de, this message translates to:
  /// **'Lichtkegel'**
  String get ridePuckLichtkegel;

  /// No description provided for @ridePuckChevron.
  ///
  /// In de, this message translates to:
  /// **'Chevron'**
  String get ridePuckChevron;

  /// No description provided for @ridePuckBergASub.
  ///
  /// In de, this message translates to:
  /// **'Buchstabe, Berg und Pfeil in einem'**
  String get ridePuckBergASub;

  /// No description provided for @ridePuckTopDownSub.
  ///
  /// In de, this message translates to:
  /// **'Orthografisch: Nase, Hörner, zwei Reifen — dreht mit'**
  String get ridePuckTopDownSub;

  /// No description provided for @ridePuckHofTorSub.
  ///
  /// In de, this message translates to:
  /// **'Zwei Schenkel, unten offen'**
  String get ridePuckHofTorSub;

  /// No description provided for @ridePuckKometSub.
  ///
  /// In de, this message translates to:
  /// **'Speerblatt mit orangem Funken'**
  String get ridePuckKometSub;

  /// No description provided for @ridePuckKieselSub.
  ///
  /// In de, this message translates to:
  /// **'Weiches Dreieck mit Halo'**
  String get ridePuckKieselSub;

  /// No description provided for @ridePuckLenkerBugSub.
  ///
  /// In de, this message translates to:
  /// **'Spitze Nase, zwei Lenkerhörner'**
  String get ridePuckLenkerBugSub;

  /// No description provided for @ridePuckLichtkegelSub.
  ///
  /// In de, this message translates to:
  /// **'Dunkle Scheibe, oranger Kegel'**
  String get ridePuckLichtkegelSub;

  /// No description provided for @ridePuckChevronSub.
  ///
  /// In de, this message translates to:
  /// **'Standard-Navi-Pfeil'**
  String get ridePuckChevronSub;

  /// No description provided for @rideChipLive.
  ///
  /// In de, this message translates to:
  /// **'Live'**
  String get rideChipLive;

  /// No description provided for @rideChipRouteOffline.
  ///
  /// In de, this message translates to:
  /// **'Route offline'**
  String get rideChipRouteOffline;

  /// No description provided for @rideChipOfflineMapOk.
  ///
  /// In de, this message translates to:
  /// **'Offline · Karte ok · Reroute: Netz'**
  String get rideChipOfflineMapOk;

  /// No description provided for @rideChipMapsMissing.
  ///
  /// In de, this message translates to:
  /// **'Karten fehlen'**
  String get rideChipMapsMissing;

  /// No description provided for @rideCardinalN.
  ///
  /// In de, this message translates to:
  /// **'N'**
  String get rideCardinalN;

  /// No description provided for @rideCardinalNE.
  ///
  /// In de, this message translates to:
  /// **'NO'**
  String get rideCardinalNE;

  /// No description provided for @rideCardinalE.
  ///
  /// In de, this message translates to:
  /// **'O'**
  String get rideCardinalE;

  /// No description provided for @rideCardinalSE.
  ///
  /// In de, this message translates to:
  /// **'SO'**
  String get rideCardinalSE;

  /// No description provided for @rideCardinalS.
  ///
  /// In de, this message translates to:
  /// **'S'**
  String get rideCardinalS;

  /// No description provided for @rideCardinalSW.
  ///
  /// In de, this message translates to:
  /// **'SW'**
  String get rideCardinalSW;

  /// No description provided for @rideCardinalW.
  ///
  /// In de, this message translates to:
  /// **'W'**
  String get rideCardinalW;

  /// No description provided for @rideCardinalNW.
  ///
  /// In de, this message translates to:
  /// **'NW'**
  String get rideCardinalNW;

  /// No description provided for @navCueArrive.
  ///
  /// In de, this message translates to:
  /// **'Ziel erreicht'**
  String get navCueArrive;

  /// No description provided for @navCueSlightLeft.
  ///
  /// In de, this message translates to:
  /// **'Leicht links'**
  String get navCueSlightLeft;

  /// No description provided for @navCueSlightRight.
  ///
  /// In de, this message translates to:
  /// **'Leicht rechts'**
  String get navCueSlightRight;

  /// No description provided for @navCueTurnLeft.
  ///
  /// In de, this message translates to:
  /// **'Links abbiegen'**
  String get navCueTurnLeft;

  /// No description provided for @navCueTurnRight.
  ///
  /// In de, this message translates to:
  /// **'Rechts abbiegen'**
  String get navCueTurnRight;

  /// No description provided for @navCueSharpLeft.
  ///
  /// In de, this message translates to:
  /// **'Scharf links'**
  String get navCueSharpLeft;

  /// No description provided for @navCueSharpRight.
  ///
  /// In de, this message translates to:
  /// **'Scharf rechts'**
  String get navCueSharpRight;

  /// No description provided for @liveHintBracketRun.
  ///
  /// In de, this message translates to:
  /// **'Durchgang {n} erfasst'**
  String liveHintBracketRun(String n);

  /// No description provided for @liveHintImpactStreak.
  ///
  /// In de, this message translates to:
  /// **'Harte Schlagfolge erkannt'**
  String get liveHintImpactStreak;

  /// No description provided for @liveHintStandSetup.
  ///
  /// In de, this message translates to:
  /// **'Stand: Setup prüfen möglich'**
  String get liveHintStandSetup;

  /// No description provided for @maintForkLower.
  ///
  /// In de, this message translates to:
  /// **'Gabel Lower-Leg Service'**
  String get maintForkLower;

  /// No description provided for @maintForkFull.
  ///
  /// In de, this message translates to:
  /// **'Gabel Vollservice (Feder/Dämpfer)'**
  String get maintForkFull;

  /// No description provided for @maintShockAir.
  ///
  /// In de, this message translates to:
  /// **'Dämpfer Air-Can Service'**
  String get maintShockAir;

  /// No description provided for @maintShockFull.
  ///
  /// In de, this message translates to:
  /// **'Dämpfer Vollservice'**
  String get maintShockFull;

  /// No description provided for @maintChainWear.
  ///
  /// In de, this message translates to:
  /// **'Kettenverschleiß prüfen'**
  String get maintChainWear;

  /// No description provided for @maintCassetteCheck.
  ///
  /// In de, this message translates to:
  /// **'Kassette prüfen (nach 2–3 Ketten)'**
  String get maintCassetteCheck;

  /// No description provided for @maintPadsFront.
  ///
  /// In de, this message translates to:
  /// **'Bremsbeläge vorne prüfen'**
  String get maintPadsFront;

  /// No description provided for @maintPadsRear.
  ///
  /// In de, this message translates to:
  /// **'Bremsbeläge hinten prüfen'**
  String get maintPadsRear;

  /// No description provided for @maintSealant.
  ///
  /// In de, this message translates to:
  /// **'Tubeless-Milch erneuern'**
  String get maintSealant;

  /// No description provided for @maintDropper.
  ///
  /// In de, this message translates to:
  /// **'Dropper Lower-Post Service'**
  String get maintDropper;

  /// No description provided for @maintDays.
  ///
  /// In de, this message translates to:
  /// **'{n} Tage'**
  String maintDays(String n);

  /// No description provided for @maintNoInterval.
  ///
  /// In de, this message translates to:
  /// **'Kein Intervall'**
  String get maintNoInterval;

  /// No description provided for @compatTitleDrv011.
  ///
  /// In de, this message translates to:
  /// **'Kassette benötigt passenden Freilaufkörper'**
  String get compatTitleDrv011;

  /// No description provided for @compatTitleFrm004.
  ///
  /// In de, this message translates to:
  /// **'Hinterbau-Einbaubreite muss zur Nabe passen'**
  String get compatTitleFrm004;

  /// No description provided for @compatTitleSus007.
  ///
  /// In de, this message translates to:
  /// **'Dämpfer-Maß muss zur Rahmenvorgabe passen'**
  String get compatTitleSus007;

  /// No description provided for @compatTitleSus012.
  ///
  /// In de, this message translates to:
  /// **'Gabel-Schaft vs. Steuersatz (S.H.I.S.)'**
  String get compatTitleSus012;

  /// No description provided for @compatTitleBrk003.
  ///
  /// In de, this message translates to:
  /// **'Bremssattel-Aufnahme am Rahmen'**
  String get compatTitleBrk003;

  /// No description provided for @compatTitleBrk008.
  ///
  /// In de, this message translates to:
  /// **'Bremsscheiben-Aufnahme vs. Nabe'**
  String get compatTitleBrk008;

  /// No description provided for @compatTitleBrk008f.
  ///
  /// In de, this message translates to:
  /// **'Bremsscheibe vorne vs. Vorderradnabe'**
  String get compatTitleBrk008f;

  /// No description provided for @compatTitleWhl005.
  ///
  /// In de, this message translates to:
  /// **'Reifenbreite zur Felgen-Maulweite'**
  String get compatTitleWhl005;

  /// No description provided for @compatTitleWhl005f.
  ///
  /// In de, this message translates to:
  /// **'Vorderreifen zur Felgen-Maulweite'**
  String get compatTitleWhl005f;

  /// No description provided for @compatTitleWhl009.
  ///
  /// In de, this message translates to:
  /// **'Reifen-Außenmaß vs. Rahmenfreigang'**
  String get compatTitleWhl009;

  /// No description provided for @compatTitleCkp002.
  ///
  /// In de, this message translates to:
  /// **'Lenker-Klemmdurchmesser vs. Vorbau'**
  String get compatTitleCkp002;

  /// No description provided for @compatTitleSpt006.
  ///
  /// In de, this message translates to:
  /// **'Sattelstützendurchmesser vs. Sitzrohr'**
  String get compatTitleSpt006;

  /// No description provided for @compatTitleBb003.
  ///
  /// In de, this message translates to:
  /// **'Innenlager-Standard vs. Kurbelwelle'**
  String get compatTitleBb003;

  /// No description provided for @compatTitleBb003f.
  ///
  /// In de, this message translates to:
  /// **'Innenlager vs. Rahmen-Standard'**
  String get compatTitleBb003f;

  /// No description provided for @compatTitleEbk002.
  ///
  /// In de, this message translates to:
  /// **'Motor-Interface nur bei OEM-Freigabe'**
  String get compatTitleEbk002;

  /// No description provided for @compatTitleFrm004f.
  ///
  /// In de, this message translates to:
  /// **'Vorderrad-Achse vs. Gabel'**
  String get compatTitleFrm004f;

  /// No description provided for @compatFailDrv011.
  ///
  /// In de, this message translates to:
  /// **'Die Kassette benötigt {cassette}, deine Nabe hat {hub}.'**
  String compatFailDrv011(String cassette, String hub);

  /// No description provided for @compatFailFrm004.
  ///
  /// In de, this message translates to:
  /// **'Rahmen-Einbaubreite {frame} ≠ Nabe {hub}.'**
  String compatFailFrm004(String frame, String hub);

  /// No description provided for @compatFailSus007.
  ///
  /// In de, this message translates to:
  /// **'Dämpfer {eye}×{stroke} ({mount}) passt nicht zur Rahmenvorgabe.'**
  String compatFailSus007(String eye, String stroke, String mount);

  /// No description provided for @compatFailSus012.
  ///
  /// In de, this message translates to:
  /// **'Gabel-Schaft {fork} passt nicht zum Steuersatz {headset}.'**
  String compatFailSus012(String fork, String headset);

  /// No description provided for @compatFailBrk003.
  ///
  /// In de, this message translates to:
  /// **'Bremssattel {caliper} vs. Rahmenaufnahme {frame}.'**
  String compatFailBrk003(String caliper, String frame);

  /// No description provided for @compatFailBrk008.
  ///
  /// In de, this message translates to:
  /// **'Scheibe {rotor} ≠ Nabe {hub}.'**
  String compatFailBrk008(String rotor, String hub);

  /// No description provided for @compatFailBrk008f.
  ///
  /// In de, this message translates to:
  /// **'Vordere Scheibe {rotor} ≠ Nabe {hub}.'**
  String compatFailBrk008f(String rotor, String hub);

  /// No description provided for @compatFailWhl005.
  ///
  /// In de, this message translates to:
  /// **'Reifenbreite {tire} mm außerhalb Bereich für Maulweite {rim} mm.'**
  String compatFailWhl005(String tire, String rim);

  /// No description provided for @compatFailWhl005f.
  ///
  /// In de, this message translates to:
  /// **'Vorderreifen {tire} mm außerhalb Bereich für {rim} mm.'**
  String compatFailWhl005f(String tire, String rim);

  /// No description provided for @compatFailWhl009.
  ///
  /// In de, this message translates to:
  /// **'Reifenbreite {tire} mm > Rahmenfreigang {max} mm.'**
  String compatFailWhl009(String tire, String max);

  /// No description provided for @compatFailCkp002.
  ///
  /// In de, this message translates to:
  /// **'Lenkerklemmung {bar} mm ≠ Vorbau {stem} mm.'**
  String compatFailCkp002(String bar, String stem);

  /// No description provided for @compatFailSpt006.
  ///
  /// In de, this message translates to:
  /// **'Stütze Ø {post} passt nicht zu Rahmen Ø {frame}.'**
  String compatFailSpt006(String post, String frame);

  /// No description provided for @compatFailBb003.
  ///
  /// In de, this message translates to:
  /// **'Innenlager-Welle {bb} ≠ Kurbel {crank}.'**
  String compatFailBb003(String bb, String crank);

  /// No description provided for @compatFailBb003f.
  ///
  /// In de, this message translates to:
  /// **'Innenlager {bb} ≠ Rahmen {frame}.'**
  String compatFailBb003f(String bb, String frame);

  /// No description provided for @compatFailEbk002.
  ///
  /// In de, this message translates to:
  /// **'Motortausch außerhalb OEM-Freigabe unzulässig. Frame {frame} ≠ Motor {motor}.'**
  String compatFailEbk002(String frame, String motor);

  /// No description provided for @compatFailFrm004f.
  ///
  /// In de, this message translates to:
  /// **'Gabel-Achse {fork} ≠ Nabe {hub}.'**
  String compatFailFrm004f(String fork, String hub);

  /// No description provided for @compatRuleOk.
  ///
  /// In de, this message translates to:
  /// **'Regel erfüllt.'**
  String get compatRuleOk;

  /// No description provided for @compatConditional.
  ///
  /// In de, this message translates to:
  /// **'Bedingt kompatibel'**
  String get compatConditional;

  /// No description provided for @compatMissingFacts.
  ///
  /// In de, this message translates to:
  /// **'Fehlende Attribute — kein COMPATIBLE ohne vollständige Faktenlage.'**
  String get compatMissingFacts;

  /// No description provided for @compatWorkshopHint.
  ///
  /// In de, this message translates to:
  /// **'Sicherheitsrelevante Montage: Fachwerkstatt. Drehmomente nur aus Herstellerdokumenten.'**
  String get compatWorkshopHint;

  /// No description provided for @compatConditionBrk003.
  ///
  /// In de, this message translates to:
  /// **'Nur mit passendem Adapter (Post Mount ↔ IS).'**
  String get compatConditionBrk003;

  /// No description provided for @compatDatasheet.
  ///
  /// In de, this message translates to:
  /// **'Herstellerdatenblatt prüfen'**
  String get compatDatasheet;

  /// No description provided for @attrFreehub.
  ///
  /// In de, this message translates to:
  /// **'Freilauf-Standard'**
  String get attrFreehub;

  /// No description provided for @attrRearSpacing.
  ///
  /// In de, this message translates to:
  /// **'Hinterbau-Einbaubreite'**
  String get attrRearSpacing;

  /// No description provided for @attrEyeToEye.
  ///
  /// In de, this message translates to:
  /// **'Einbaulänge (Auge-zu-Auge)'**
  String get attrEyeToEye;

  /// No description provided for @attrStroke.
  ///
  /// In de, this message translates to:
  /// **'Hub'**
  String get attrStroke;

  /// No description provided for @attrMountType.
  ///
  /// In de, this message translates to:
  /// **'Montage-Typ'**
  String get attrMountType;

  /// No description provided for @attrShockEyeToEye.
  ///
  /// In de, this message translates to:
  /// **'Rahmenvorgabe: Einbaulänge'**
  String get attrShockEyeToEye;

  /// No description provided for @attrShockStroke.
  ///
  /// In de, this message translates to:
  /// **'Rahmenvorgabe: Hub'**
  String get attrShockStroke;

  /// No description provided for @attrShockMount.
  ///
  /// In de, this message translates to:
  /// **'Rahmenvorgabe: Montage-Typ'**
  String get attrShockMount;

  /// No description provided for @attrSteerer.
  ///
  /// In de, this message translates to:
  /// **'Gabelschaft'**
  String get attrSteerer;

  /// No description provided for @attrBrakeMount.
  ///
  /// In de, this message translates to:
  /// **'Bremssattel-Aufnahme'**
  String get attrBrakeMount;

  /// No description provided for @attrBrakeMountRear.
  ///
  /// In de, this message translates to:
  /// **'Rahmen: Bremsaufnahme hinten'**
  String get attrBrakeMountRear;

  /// No description provided for @attrRotorMount.
  ///
  /// In de, this message translates to:
  /// **'Scheiben-Aufnahme'**
  String get attrRotorMount;

  /// No description provided for @attrTireWidth.
  ///
  /// In de, this message translates to:
  /// **'Reifenbreite'**
  String get attrTireWidth;

  /// No description provided for @attrRimWidth.
  ///
  /// In de, this message translates to:
  /// **'Felgen-Maulweite (innen)'**
  String get attrRimWidth;

  /// No description provided for @attrMaxTire.
  ///
  /// In de, this message translates to:
  /// **'Rahmen: max. Reifenfreigang'**
  String get attrMaxTire;

  /// No description provided for @attrBarClamp.
  ///
  /// In de, this message translates to:
  /// **'Klemmdurchmesser'**
  String get attrBarClamp;

  /// No description provided for @attrStemClamp.
  ///
  /// In de, this message translates to:
  /// **'Vorbau-Klemmung'**
  String get attrStemClamp;

  /// No description provided for @attrSeatpostDia.
  ///
  /// In de, this message translates to:
  /// **'Durchmesser'**
  String get attrSeatpostDia;

  /// No description provided for @attrMinInsert.
  ///
  /// In de, this message translates to:
  /// **'Min. Einstecktiefe'**
  String get attrMinInsert;

  /// No description provided for @attrMaxInsert.
  ///
  /// In de, this message translates to:
  /// **'Rahmen: max. Einstecktiefe'**
  String get attrMaxInsert;

  /// No description provided for @attrCrankAxle.
  ///
  /// In de, this message translates to:
  /// **'Kurbelwelle'**
  String get attrCrankAxle;

  /// No description provided for @attrBbStandard.
  ///
  /// In de, this message translates to:
  /// **'Innenlager-Standard'**
  String get attrBbStandard;

  /// No description provided for @attrMotorInterface.
  ///
  /// In de, this message translates to:
  /// **'Motor-Interface'**
  String get attrMotorInterface;

  /// No description provided for @attrAxleFront.
  ///
  /// In de, this message translates to:
  /// **'Achse'**
  String get attrAxleFront;

  /// No description provided for @howToFreehub.
  ///
  /// In de, this message translates to:
  /// **'Aufdruck Freilaufkörper / Naben-Datenblatt'**
  String get howToFreehub;

  /// No description provided for @howToRearSpacing.
  ///
  /// In de, this message translates to:
  /// **'Rahmen-/Naben-Spec (Boost 148, 142×12, …)'**
  String get howToRearSpacing;

  /// No description provided for @howToEyeToEye.
  ///
  /// In de, this message translates to:
  /// **'Dämpfer-Aufdruck'**
  String get howToEyeToEye;

  /// No description provided for @howToStroke.
  ///
  /// In de, this message translates to:
  /// **'Dämpfer-Katalog'**
  String get howToStroke;

  /// No description provided for @howToMountType.
  ///
  /// In de, this message translates to:
  /// **'Trunnion vs. Eyelet'**
  String get howToMountType;

  /// No description provided for @howToSteerer.
  ///
  /// In de, this message translates to:
  /// **'1⅛″ oder tapered 1,5″ / S.H.I.S.'**
  String get howToSteerer;

  /// No description provided for @howToBrakeMount.
  ///
  /// In de, this message translates to:
  /// **'Post Mount / Flat Mount / IS'**
  String get howToBrakeMount;

  /// No description provided for @howToBrakeMountRear.
  ///
  /// In de, this message translates to:
  /// **'Rahmen-Spec'**
  String get howToBrakeMountRear;

  /// No description provided for @howToRotorMount.
  ///
  /// In de, this message translates to:
  /// **'Center Lock oder 6-Loch'**
  String get howToRotorMount;

  /// No description provided for @howToTireWidth.
  ///
  /// In de, this message translates to:
  /// **'ETRTO'**
  String get howToTireWidth;

  /// No description provided for @howToRimWidth.
  ///
  /// In de, this message translates to:
  /// **'Felgen-Datenblatt'**
  String get howToRimWidth;

  /// No description provided for @howToMaxTire.
  ///
  /// In de, this message translates to:
  /// **'Rahmen-Herstellerangabe'**
  String get howToMaxTire;

  /// No description provided for @howToBarClamp.
  ///
  /// In de, this message translates to:
  /// **'31,8 oder 35,0'**
  String get howToBarClamp;

  /// No description provided for @howToStemClamp.
  ///
  /// In de, this message translates to:
  /// **'Vorbau-Datenblatt'**
  String get howToStemClamp;

  /// No description provided for @howToSeatpostDia.
  ///
  /// In de, this message translates to:
  /// **'27,2 / 30,9 / 31,6 / 34,9'**
  String get howToSeatpostDia;

  /// No description provided for @howToMinInsert.
  ///
  /// In de, this message translates to:
  /// **'Dropper-Handbuch'**
  String get howToMinInsert;

  /// No description provided for @howToMaxInsert.
  ///
  /// In de, this message translates to:
  /// **'Rahmen-Geometrie'**
  String get howToMaxInsert;

  /// No description provided for @howToCrankAxle.
  ///
  /// In de, this message translates to:
  /// **'DUB / 24mm / 30mm'**
  String get howToCrankAxle;

  /// No description provided for @howToBbStandard.
  ///
  /// In de, this message translates to:
  /// **'BSA / T47 / PF92 / …'**
  String get howToBbStandard;

  /// No description provided for @howToMotorInterface.
  ///
  /// In de, this message translates to:
  /// **'z. B. bosch_smart_system'**
  String get howToMotorInterface;

  /// No description provided for @howToAxleFront.
  ///
  /// In de, this message translates to:
  /// **'15×100 / 15×110 Boost / …'**
  String get howToAxleFront;

  /// No description provided for @postRideObsImpacts.
  ///
  /// In de, this message translates to:
  /// **'Viele harte Impacts ({count} auf {km} km) — Front/Dämpfer stark belastet.'**
  String postRideObsImpacts(String count, String km);

  /// No description provided for @postRideObsSmooth.
  ///
  /// In de, this message translates to:
  /// **'Wenige Impacts bei {km} km — eher flowig oder glatter Untergrund.'**
  String postRideObsSmooth(String km);

  /// No description provided for @postRideObsFlowHigh.
  ///
  /// In de, this message translates to:
  /// **'Hoher Flow-Score ({flow}) — Tempo und Linienwahl wirkten stimmig.'**
  String postRideObsFlowHigh(String flow);

  /// No description provided for @postRideObsFlowLow.
  ///
  /// In de, this message translates to:
  /// **'Niedriger Flow-Score ({flow}) — viele Tempo-Brüche oder Stopps.'**
  String postRideObsFlowLow(String flow);

  /// No description provided for @postRideObsPeakG.
  ///
  /// In de, this message translates to:
  /// **'Peak {g} g — harte Einschläge; Setup und Reifendruck prüfen.'**
  String postRideObsPeakG(String g);

  /// No description provided for @postRideFrontTooFirm.
  ///
  /// In de, this message translates to:
  /// **'zu hart'**
  String get postRideFrontTooFirm;

  /// No description provided for @postRideFrontOk.
  ///
  /// In de, this message translates to:
  /// **'ok'**
  String get postRideFrontOk;

  /// No description provided for @postRideBumpsHarsh.
  ///
  /// In de, this message translates to:
  /// **'rau'**
  String get postRideBumpsHarsh;

  /// No description provided for @postRideObsFbHarsh.
  ///
  /// In de, this message translates to:
  /// **'Feedback: Front {front} · kleine Schläge {bumps}.'**
  String postRideObsFbHarsh(String front, String bumps);

  /// No description provided for @postRideObsFbSoft.
  ///
  /// In de, this message translates to:
  /// **'Feedback: Front wirkt weich / taucht beim Anbremsen ab.'**
  String get postRideObsFbSoft;

  /// No description provided for @postRideSugReboundSlowTitle.
  ///
  /// In de, this message translates to:
  /// **'Zugstufe Gabel: 2 Klicks langsamer'**
  String get postRideSugReboundSlowTitle;

  /// No description provided for @postRideSugReboundSlowContent.
  ///
  /// In de, this message translates to:
  /// **'Aktuell ca. {current} Klicks von geschlossen → Ziel {next}.'**
  String postRideSugReboundSlowContent(String current, String next);

  /// No description provided for @postRideSugReboundSlowEffect.
  ///
  /// In de, this message translates to:
  /// **'Ruhigere Front bei Schlagfolgen, etwas weniger Pop.'**
  String get postRideSugReboundSlowEffect;

  /// No description provided for @postRideSugReboundFastTitle.
  ///
  /// In de, this message translates to:
  /// **'Zugstufe Gabel: 2 Klicks schneller'**
  String get postRideSugReboundFastTitle;

  /// No description provided for @postRideSugReboundFastContent.
  ///
  /// In de, this message translates to:
  /// **'Aktuell ca. {current} Klicks → Ziel {next} (weniger Dive).'**
  String postRideSugReboundFastContent(String current, String next);

  /// No description provided for @postRideSugReboundFastEffect.
  ///
  /// In de, this message translates to:
  /// **'Stabileres Anbremsen, weniger Durchschlag-Gefühl.'**
  String get postRideSugReboundFastEffect;

  /// No description provided for @postRideSugPressureTitle.
  ///
  /// In de, this message translates to:
  /// **'Luftdruck Front prüfen'**
  String get postRideSugPressureTitle;

  /// No description provided for @postRideSugPressureContent.
  ///
  /// In de, this message translates to:
  /// **'Sehr hohe Peak-g — Druck und Volumen-Spacer gegen Hersteller-Tabelle halten.'**
  String get postRideSugPressureContent;

  /// No description provided for @postRideSugPressureEffect.
  ///
  /// In de, this message translates to:
  /// **'Weniger Bottom-out-Risiko, klareres Feedback.'**
  String get postRideSugPressureEffect;

  /// No description provided for @postRideSugLimitsClicks.
  ///
  /// In de, this message translates to:
  /// **'Herstellerbereich typisch 0–14 Klicks von geschlossen.'**
  String get postRideSugLimitsClicks;

  /// No description provided for @postRideSugLimitsPressure.
  ///
  /// In de, this message translates to:
  /// **'Nur im freigegebenen Druckbereich des Reifens/Gabel.'**
  String get postRideSugLimitsPressure;

  /// No description provided for @postRideReasonHarshBumps.
  ///
  /// In de, this message translates to:
  /// **'Feedback „kleine Schläge rau“'**
  String get postRideReasonHarshBumps;

  /// No description provided for @postRideReasonFrontFirm.
  ///
  /// In de, this message translates to:
  /// **'Feedback „Front zu hart“'**
  String get postRideReasonFrontFirm;

  /// No description provided for @postRideReasonImpacts.
  ///
  /// In de, this message translates to:
  /// **'{count} Impacts / {km} km'**
  String postRideReasonImpacts(String count, String km);

  /// No description provided for @postRideReasonRms.
  ///
  /// In de, this message translates to:
  /// **'RMS {rms} g'**
  String postRideReasonRms(String rms);

  /// No description provided for @postRideReasonFrontLoad.
  ///
  /// In de, this message translates to:
  /// **'Hohe Schlagbelastung an der Front'**
  String get postRideReasonFrontLoad;

  /// No description provided for @postRideReasonDive.
  ///
  /// In de, this message translates to:
  /// **'Feedback „taucht ab“'**
  String get postRideReasonDive;

  /// No description provided for @postRideReasonFrontSoft.
  ///
  /// In de, this message translates to:
  /// **'Feedback „Front zu weich“'**
  String get postRideReasonFrontSoft;

  /// No description provided for @postRideReasonSoftDive.
  ///
  /// In de, this message translates to:
  /// **'Front zu weich / Dive'**
  String get postRideReasonSoftDive;

  /// No description provided for @postRideReasonPeakLong.
  ///
  /// In de, this message translates to:
  /// **'Peak ≥ 5 g bei längerer Fahrt'**
  String get postRideReasonPeakLong;

  /// No description provided for @postRideAnalysis.
  ///
  /// In de, this message translates to:
  /// **'Analyse'**
  String get postRideAnalysis;

  /// No description provided for @postRideExpect.
  ///
  /// In de, this message translates to:
  /// **'Erwartung: {text}'**
  String postRideExpect(String text);

  /// No description provided for @postRideLimit.
  ///
  /// In de, this message translates to:
  /// **'Grenze: {text}'**
  String postRideLimit(String text);

  /// No description provided for @postRideEvidence.
  ///
  /// In de, this message translates to:
  /// **'Evidenz'**
  String get postRideEvidence;

  /// No description provided for @postRideConfidence.
  ///
  /// In de, this message translates to:
  /// **'Konfidenz {level}'**
  String postRideConfidence(String level);

  /// No description provided for @postRideConfHigh.
  ///
  /// In de, this message translates to:
  /// **'hoch'**
  String get postRideConfHigh;

  /// No description provided for @postRideConfMedium.
  ///
  /// In de, this message translates to:
  /// **'mittel'**
  String get postRideConfMedium;

  /// No description provided for @postRideConfLow.
  ///
  /// In de, this message translates to:
  /// **'niedrig'**
  String get postRideConfLow;

  /// No description provided for @postRideFactRide.
  ///
  /// In de, this message translates to:
  /// **'{km} km · {hm} hm · {min} min'**
  String postRideFactRide(String km, String hm, String min);

  /// No description provided for @postRideFactMetrics.
  ///
  /// In de, this message translates to:
  /// **'Flow {flow} · Peak {g} g · {impacts} Impacts'**
  String postRideFactMetrics(String flow, String g, String impacts);

  /// No description provided for @postRideFactMetricsLean.
  ///
  /// In de, this message translates to:
  /// **'Flow {flow} · Peak {g} g · {impacts} Impacts · Lean {lean}°'**
  String postRideFactMetricsLean(
      String flow, String g, String impacts, String lean);

  /// No description provided for @postRideFactBike.
  ///
  /// In de, this message translates to:
  /// **'Bike: {name}'**
  String postRideFactBike(String name);

  /// No description provided for @postRideFactSoc.
  ///
  /// In de, this message translates to:
  /// **'SOC {soc}%'**
  String postRideFactSoc(String soc);

  /// No description provided for @rideGPeak.
  ///
  /// In de, this message translates to:
  /// **'G-Peak'**
  String get rideGPeak;

  /// No description provided for @rideLean.
  ///
  /// In de, this message translates to:
  /// **'Neig.'**
  String get rideLean;

  /// No description provided for @rideFlow.
  ///
  /// In de, this message translates to:
  /// **'Flow'**
  String get rideFlow;

  /// No description provided for @garageSetNamed.
  ///
  /// In de, this message translates to:
  /// **'{name} setzen'**
  String garageSetNamed(String name);

  /// No description provided for @bleKindPower.
  ///
  /// In de, this message translates to:
  /// **'Powermeter'**
  String get bleKindPower;

  /// No description provided for @bleKindOtherDrive.
  ///
  /// In de, this message translates to:
  /// **'E-Antrieb'**
  String get bleKindOtherDrive;

  /// No description provided for @bleTipBosch.
  ///
  /// In de, this message translates to:
  /// **'Flow komplett schließen · 10–20 cm am Display'**
  String get bleTipBosch;

  /// No description provided for @bleTipShimano.
  ///
  /// In de, this message translates to:
  /// **'E-TUBE schließen · in 15 s nach Power/Taster tippen'**
  String get bleTipShimano;

  /// No description provided for @bleTipYamaha.
  ///
  /// In de, this message translates to:
  /// **'e-Sync schließen · Tempo über CSC-Sensor'**
  String get bleTipYamaha;

  /// No description provided for @bleTipOtherDrive.
  ///
  /// In de, this message translates to:
  /// **'Hersteller-App schließen · Display an, nah halten'**
  String get bleTipOtherDrive;

  /// No description provided for @bleTipCsc.
  ///
  /// In de, this message translates to:
  /// **'Sensor am Rad wecken, nah halten'**
  String get bleTipCsc;

  /// No description provided for @bleTipPower.
  ///
  /// In de, this message translates to:
  /// **'Powermeter einschalten, nah halten'**
  String get bleTipPower;

  /// No description provided for @blePairLeadEbike.
  ///
  /// In de, this message translates to:
  /// **'Display an, Hersteller-App zu, Handy nah — dann antippen.'**
  String get blePairLeadEbike;

  /// No description provided for @blePairLeadSensor.
  ///
  /// In de, this message translates to:
  /// **'Sensor am Rad wecken, nicht die Uhr am Handgelenk.'**
  String get blePairLeadSensor;

  /// No description provided for @bleNoteSensorBrand.
  ///
  /// In de, this message translates to:
  /// **'Sensor'**
  String get bleNoteSensorBrand;

  /// No description provided for @bleNoteSensorLine.
  ///
  /// In de, this message translates to:
  /// **'Magnet oder Kurbel, nah an den Sensor — nicht die Uhr.'**
  String get bleNoteSensorLine;

  /// No description provided for @bleNoteBoschLine.
  ///
  /// In de, this message translates to:
  /// **'Flow komplett schließen (nicht nur Hintergrund). Display an, 10–20 cm.'**
  String get bleNoteBoschLine;

  /// No description provided for @bleNoteShimanoLine.
  ///
  /// In de, this message translates to:
  /// **'E-TUBE schließen. Nach Power oder Taster oft nur 15 s — dann tippen.'**
  String get bleNoteShimanoLine;

  /// No description provided for @bleNoteYamahaLine.
  ///
  /// In de, this message translates to:
  /// **'e-Sync bzw. TQ-App zu. Live-Tempo meist nur über CSC-Sensor.'**
  String get bleNoteYamahaLine;

  /// No description provided for @bleNoteFazuaLine.
  ///
  /// In de, this message translates to:
  /// **'Remote an — CSC und Power wie ein normaler Sensor.'**
  String get bleNoteFazuaLine;

  /// No description provided for @bleNoteOtherBrand.
  ///
  /// In de, this message translates to:
  /// **'Andere'**
  String get bleNoteOtherBrand;

  /// No description provided for @bleNoteOtherLine.
  ///
  /// In de, this message translates to:
  /// **'RideControl / Mission Control schließen. Ein Phone, Display an.'**
  String get bleNoteOtherLine;

  /// No description provided for @bleGattWatchRejected.
  ///
  /// In de, this message translates to:
  /// **'Verbindung abgelehnt — andere Fitness-App schließen, Uhr nah halten.'**
  String get bleGattWatchRejected;

  /// No description provided for @bleGattWatchTimeout.
  ///
  /// In de, this message translates to:
  /// **'Timeout — Uhr nah halten, Broadcast-Herzfrequenz prüfen.'**
  String get bleGattWatchTimeout;

  /// No description provided for @bleGattWatchFailed.
  ///
  /// In de, this message translates to:
  /// **'Uhr-Verbindung fehlgeschlagen'**
  String get bleGattWatchFailed;

  /// No description provided for @bleGattRejectedBosch.
  ///
  /// In de, this message translates to:
  /// **'Verbindung abgelehnt — Bosch Flow schließen, Display an, 10–20 cm.'**
  String get bleGattRejectedBosch;

  /// No description provided for @bleGattRejectedShimano.
  ///
  /// In de, this message translates to:
  /// **'Verbindung abgelehnt — E-TUBE schließen, Display an, nah halten.'**
  String get bleGattRejectedShimano;

  /// No description provided for @bleGattRejectedGeneric.
  ///
  /// In de, this message translates to:
  /// **'Verbindung abgelehnt — Bosch Flow / Shimano E-TUBE schließen, Display an, nah halten.'**
  String get bleGattRejectedGeneric;

  /// No description provided for @bleGattTimeoutBosch.
  ///
  /// In de, this message translates to:
  /// **'Timeout — Display wecken, Flow zu, nah halten. Motorwerte nur mit CSC oder offiziellem LDI.'**
  String get bleGattTimeoutBosch;

  /// No description provided for @bleGattTimeoutShimano.
  ///
  /// In de, this message translates to:
  /// **'Timeout — E-TUBE zu, in 15 s nach Power/Taster tippen.'**
  String get bleGattTimeoutShimano;

  /// No description provided for @bleGattTimeoutDrive.
  ///
  /// In de, this message translates to:
  /// **'Timeout — Hersteller-App zu, Display an. Tempo über CSC-Sensor.'**
  String get bleGattTimeoutDrive;

  /// No description provided for @bleGattTimeoutSensor.
  ///
  /// In de, this message translates to:
  /// **'Timeout — Sensor wecken, näher rangehen.'**
  String get bleGattTimeoutSensor;

  /// No description provided for @bleDriveFailBosch.
  ///
  /// In de, this message translates to:
  /// **'Bosch erkannt, keine Live-Motorwerte. Als Nächstes einen Radsensor (CSC) koppeln.'**
  String get bleDriveFailBosch;

  /// No description provided for @bleDriveFailShimano.
  ///
  /// In de, this message translates to:
  /// **'Shimano erkannt, keine Live-Motorwerte. Als Nächstes einen Radsensor (CSC) koppeln.'**
  String get bleDriveFailShimano;

  /// No description provided for @bleDriveFailYamaha.
  ///
  /// In de, this message translates to:
  /// **'Yamaha erkannt, keine Live-Motorwerte. Tempo über CSC-Sensor koppeln.'**
  String get bleDriveFailYamaha;

  /// No description provided for @bleDriveFailGeneric.
  ///
  /// In de, this message translates to:
  /// **'Antrieb erkannt, keine Live-Motorwerte. Als Nächstes einen Radsensor (CSC) koppeln.'**
  String get bleDriveFailGeneric;

  /// No description provided for @bleStatusBtOff.
  ///
  /// In de, this message translates to:
  /// **'Bluetooth aus'**
  String get bleStatusBtOff;

  /// No description provided for @bleStatusScanFailed.
  ///
  /// In de, this message translates to:
  /// **'Radsensor-Suche fehlgeschlagen'**
  String get bleStatusScanFailed;

  /// No description provided for @bleStatusNoSensor.
  ///
  /// In de, this message translates to:
  /// **'Kein Radsensor gefunden'**
  String get bleStatusNoSensor;

  /// No description provided for @bleStatusNoneInRange.
  ///
  /// In de, this message translates to:
  /// **'Kein Rad, Antrieb oder Sensor in Reichweite'**
  String get bleStatusNoneInRange;

  /// No description provided for @bleStatusDriveSeen.
  ///
  /// In de, this message translates to:
  /// **'Antrieb gesehen — in der Werkstatt koppeln (Bosch/Shimano)'**
  String get bleStatusDriveSeen;

  /// No description provided for @bleStatusNoCscInRange.
  ///
  /// In de, this message translates to:
  /// **'Kein Radsensor in Reichweite'**
  String get bleStatusNoCscInRange;

  /// No description provided for @bleStatusSensorDisconnected.
  ///
  /// In de, this message translates to:
  /// **'Radsensor getrennt'**
  String get bleStatusSensorDisconnected;

  /// No description provided for @bleStatusReconnectLost.
  ///
  /// In de, this message translates to:
  /// **'Verbindung verloren — Display prüfen, Flow/E-TUBE schließen, in der Werkstatt erneut koppeln.'**
  String get bleStatusReconnectLost;

  /// No description provided for @bleStatusRetry.
  ///
  /// In de, this message translates to:
  /// **'Verbinde … Retry {n}/{max}'**
  String bleStatusRetry(String n, String max);

  /// No description provided for @bleStatusAttempt.
  ///
  /// In de, this message translates to:
  /// **'Verbinde … Versuch {n}/{max}'**
  String bleStatusAttempt(String n, String max);

  /// No description provided for @bleStatusReconnect.
  ///
  /// In de, this message translates to:
  /// **'Verbinde erneut … ({n}/{max})'**
  String bleStatusReconnect(String n, String max);

  /// No description provided for @bleStatusDriveNoLive.
  ///
  /// In de, this message translates to:
  /// **'{who} · erkannt — Tempo über CSC, Akku nur mit Standard-GATT'**
  String bleStatusDriveNoLive(String who);

  /// No description provided for @bleStatusNeedBond.
  ///
  /// In de, this message translates to:
  /// **'Display braucht Bluetooth-Kopplung für den Akku.'**
  String get bleStatusNeedBond;

  /// No description provided for @bleStatusBonding.
  ///
  /// In de, this message translates to:
  /// **'System-Kopplung …'**
  String get bleStatusBonding;

  /// No description provided for @bleStatusDriveNeedBond.
  ///
  /// In de, this message translates to:
  /// **'{who} · erkannt — Akku nach Bluetooth-Kopplung in der Werkstatt'**
  String bleStatusDriveNeedBond(String who);

  /// No description provided for @bleConnectedNamed.
  ///
  /// In de, this message translates to:
  /// **'{name} verbunden'**
  String bleConnectedNamed(String name);

  /// No description provided for @bleWordSensor.
  ///
  /// In de, this message translates to:
  /// **'Sensor'**
  String get bleWordSensor;

  /// No description provided for @bleWordWatch.
  ///
  /// In de, this message translates to:
  /// **'Uhr'**
  String get bleWordWatch;

  /// No description provided for @bleSectionDrive.
  ///
  /// In de, this message translates to:
  /// **'Antrieb'**
  String get bleSectionDrive;

  /// No description provided for @bleSectionSensors.
  ///
  /// In de, this message translates to:
  /// **'Sensoren'**
  String get bleSectionSensors;

  /// No description provided for @watchStatusPickFromList.
  ///
  /// In de, this message translates to:
  /// **'Uhr in der Liste wählen'**
  String get watchStatusPickFromList;

  /// No description provided for @watchStatusScanFailed.
  ///
  /// In de, this message translates to:
  /// **'Uhr-Suche fehlgeschlagen'**
  String get watchStatusScanFailed;

  /// No description provided for @watchStatusConnectedSim.
  ///
  /// In de, this message translates to:
  /// **'Uhr verbunden (Sim)'**
  String get watchStatusConnectedSim;

  /// No description provided for @watchStatusDisconnected.
  ///
  /// In de, this message translates to:
  /// **'Uhr getrennt'**
  String get watchStatusDisconnected;

  /// No description provided for @watchStatusNoHrService.
  ///
  /// In de, this message translates to:
  /// **'Uhr gefunden, aber ohne Standard-Puls-Service'**
  String get watchStatusNoHrService;

  /// No description provided for @watchStatusReconnectLost.
  ///
  /// In de, this message translates to:
  /// **'Uhr getrennt — Broadcast prüfen, in der Nähe erneut koppeln.'**
  String get watchStatusReconnectLost;

  /// No description provided for @watchStatusReconnect.
  ///
  /// In de, this message translates to:
  /// **'Uhr verbindet erneut … ({n}/{max})'**
  String watchStatusReconnect(String n, String max);

  /// No description provided for @watchStatusBattery.
  ///
  /// In de, this message translates to:
  /// **'Uhr-Akku {n} %'**
  String watchStatusBattery(String n);

  /// No description provided for @watchHrSensorFallback.
  ///
  /// In de, this message translates to:
  /// **'Herzfrequenz-Sensor'**
  String get watchHrSensorFallback;

  /// No description provided for @watchCheckBluetooth.
  ///
  /// In de, this message translates to:
  /// **'Bluetooth prüfen'**
  String get watchCheckBluetooth;

  /// No description provided for @watchOutOfRange.
  ///
  /// In de, this message translates to:
  /// **'Uhr nicht in Reichweite'**
  String get watchOutOfRange;

  /// No description provided for @watchRemoved.
  ///
  /// In de, this message translates to:
  /// **'Uhr entfernt'**
  String get watchRemoved;

  /// No description provided for @watchRememberedOffline.
  ///
  /// In de, this message translates to:
  /// **'{name} · gemerkt, nicht live'**
  String watchRememberedOffline(String name);

  /// No description provided for @watchRememberedOfflineNoName.
  ///
  /// In de, this message translates to:
  /// **'Gemerkt, nicht live'**
  String get watchRememberedOfflineNoName;

  /// No description provided for @watchLiveNamed.
  ///
  /// In de, this message translates to:
  /// **'{name} · live'**
  String watchLiveNamed(String name);

  /// No description provided for @watchLiveBpm.
  ///
  /// In de, this message translates to:
  /// **'{name} · {bpm} bpm'**
  String watchLiveBpm(String name, String bpm);

  /// No description provided for @watchHonestyHr.
  ///
  /// In de, this message translates to:
  /// **'Puls per Standard-BLE'**
  String get watchHonestyHr;

  /// No description provided for @watchHonestyGarmin.
  ///
  /// In de, this message translates to:
  /// **'Garmin: Broadcast-HR einschalten'**
  String get watchHonestyGarmin;

  /// No description provided for @watchHonestyApple.
  ///
  /// In de, this message translates to:
  /// **'Apple Watch: kein Standard-BLE-Puls'**
  String get watchHonestyApple;

  /// No description provided for @watchHonestyGalaxy.
  ///
  /// In de, this message translates to:
  /// **'Galaxy: meist kein Standard-Puls'**
  String get watchHonestyGalaxy;

  /// No description provided for @watchHonestyUnknown.
  ///
  /// In de, this message translates to:
  /// **'Nur mit sichtbarem Puls-Broadcast'**
  String get watchHonestyUnknown;

  /// No description provided for @watchTipHr.
  ///
  /// In de, this message translates to:
  /// **'Sensor- oder Broadcast-Modus an, nah halten'**
  String get watchTipHr;

  /// No description provided for @watchTipGarmin.
  ///
  /// In de, this message translates to:
  /// **'In der Garmin-Uhr: Herzfrequenz senden / Broadcast'**
  String get watchTipGarmin;

  /// No description provided for @watchTipApple.
  ///
  /// In de, this message translates to:
  /// **'Kein BLE-Puls zu Android — HealthKit nur auf iPhone'**
  String get watchTipApple;

  /// No description provided for @watchTipGalaxy.
  ///
  /// In de, this message translates to:
  /// **'Nur wenn die Uhr Puls per Bluetooth sendet — sonst Samsung Health'**
  String get watchTipGalaxy;

  /// No description provided for @watchTipUnknown.
  ///
  /// In de, this message translates to:
  /// **'Puls-Broadcast an der Uhr muss aktiv sein'**
  String get watchTipUnknown;

  /// No description provided for @watchNotePolarBrand.
  ///
  /// In de, this message translates to:
  /// **'Polar / Gurt'**
  String get watchNotePolarBrand;

  /// No description provided for @watchNotePolarLine.
  ///
  /// In de, this message translates to:
  /// **'Sensor-Modus an. Standard-Puls — das koppeln wir.'**
  String get watchNotePolarLine;

  /// No description provided for @watchNoteGarminLine.
  ///
  /// In de, this message translates to:
  /// **'Herzfrequenz senden / Broadcast in den Uhr-Einstellungen.'**
  String get watchNoteGarminLine;

  /// No description provided for @watchNoteAppleLine.
  ///
  /// In de, this message translates to:
  /// **'Kein Standard-BLE-Puls zu Android. Nicht koppeln.'**
  String get watchNoteAppleLine;

  /// No description provided for @watchNoteGalaxyLine.
  ///
  /// In de, this message translates to:
  /// **'Meist nur Samsung Health. Nur mit sichtbarem Puls-Broadcast.'**
  String get watchNoteGalaxyLine;

  /// No description provided for @watchPairLeadText.
  ///
  /// In de, this message translates to:
  /// **'Puls am Fahrer, nicht am Rad. Nur ein echter Herzfrequenz-Sensor.'**
  String get watchPairLeadText;

  /// No description provided for @blePairAgain.
  ///
  /// In de, this message translates to:
  /// **'Neu koppeln'**
  String get blePairAgain;

  /// No description provided for @bleRemoveDevice.
  ///
  /// In de, this message translates to:
  /// **'Gerät entfernen'**
  String get bleRemoveDevice;

  /// No description provided for @bleSemanticsPaired.
  ///
  /// In de, this message translates to:
  /// **'Bluetooth gekoppelt'**
  String get bleSemanticsPaired;

  /// No description provided for @bleSemanticsPair.
  ///
  /// In de, this message translates to:
  /// **'Bluetooth koppeln'**
  String get bleSemanticsPair;

  /// No description provided for @bleTooltipPair.
  ///
  /// In de, this message translates to:
  /// **'Antrieb oder Sensor koppeln'**
  String get bleTooltipPair;

  /// No description provided for @bleRemoveWheel.
  ///
  /// In de, this message translates to:
  /// **'Radsensor entfernen'**
  String get bleRemoveWheel;

  /// No description provided for @bleRemoveDrive.
  ///
  /// In de, this message translates to:
  /// **'Antrieb entfernen'**
  String get bleRemoveDrive;

  /// No description provided for @bleSemanticsLive.
  ///
  /// In de, this message translates to:
  /// **'Bluetooth live'**
  String get bleSemanticsLive;

  /// No description provided for @bleTooltipSaved.
  ///
  /// In de, this message translates to:
  /// **'Gekoppelt, nicht verbunden'**
  String get bleTooltipSaved;

  /// No description provided for @watchOtherWatch.
  ///
  /// In de, this message translates to:
  /// **'Andere Uhr'**
  String get watchOtherWatch;

  /// No description provided for @bikeCatMtbTrail.
  ///
  /// In de, this message translates to:
  /// **'MTB Trail'**
  String get bikeCatMtbTrail;

  /// No description provided for @bikeCatMtb.
  ///
  /// In de, this message translates to:
  /// **'MTB'**
  String get bikeCatMtb;

  /// No description provided for @bikeCatEnduro.
  ///
  /// In de, this message translates to:
  /// **'Enduro'**
  String get bikeCatEnduro;

  /// No description provided for @bikeCatDh.
  ///
  /// In de, this message translates to:
  /// **'Downhill'**
  String get bikeCatDh;

  /// No description provided for @bikeCatGravel.
  ///
  /// In de, this message translates to:
  /// **'Gravel'**
  String get bikeCatGravel;

  /// No description provided for @bikeCatRoad.
  ///
  /// In de, this message translates to:
  /// **'Rennrad'**
  String get bikeCatRoad;

  /// No description provided for @bikeCatUrban.
  ///
  /// In de, this message translates to:
  /// **'City'**
  String get bikeCatUrban;

  /// No description provided for @bikeCatCargo.
  ///
  /// In de, this message translates to:
  /// **'Lastenrad'**
  String get bikeCatCargo;

  /// No description provided for @bikeCatFolding.
  ///
  /// In de, this message translates to:
  /// **'Faltrad'**
  String get bikeCatFolding;

  /// No description provided for @bikeCatKids.
  ///
  /// In de, this message translates to:
  /// **'Kinderrad'**
  String get bikeCatKids;

  /// No description provided for @bikeCatEmtb.
  ///
  /// In de, this message translates to:
  /// **'E-MTB'**
  String get bikeCatEmtb;

  /// No description provided for @bikeCatEtrekking.
  ///
  /// In de, this message translates to:
  /// **'E-Trekking'**
  String get bikeCatEtrekking;

  /// No description provided for @bikeCatHiking.
  ///
  /// In de, this message translates to:
  /// **'Zu Fuß'**
  String get bikeCatHiking;

  /// No description provided for @bikeCatEgravel.
  ///
  /// In de, this message translates to:
  /// **'E-Gravel'**
  String get bikeCatEgravel;

  /// No description provided for @bikeCatEcity.
  ///
  /// In de, this message translates to:
  /// **'E-City'**
  String get bikeCatEcity;

  /// No description provided for @bikeCatEcargo.
  ///
  /// In de, this message translates to:
  /// **'E-Lastenrad'**
  String get bikeCatEcargo;

  /// No description provided for @bikeCatEfolding.
  ///
  /// In de, this message translates to:
  /// **'E-Faltrad'**
  String get bikeCatEfolding;

  /// No description provided for @bikeCatEkids.
  ///
  /// In de, this message translates to:
  /// **'E-Kinderrad'**
  String get bikeCatEkids;

  /// No description provided for @bikeCatEroad.
  ///
  /// In de, this message translates to:
  /// **'E-Road'**
  String get bikeCatEroad;

  /// No description provided for @bikeBlurbMtbTrail.
  ///
  /// In de, this message translates to:
  /// **'Singletrails & Wald'**
  String get bikeBlurbMtbTrail;

  /// No description provided for @bikeBlurbMtb.
  ///
  /// In de, this message translates to:
  /// **'Trails & Touren'**
  String get bikeBlurbMtb;

  /// No description provided for @bikeBlurbEnduro.
  ///
  /// In de, this message translates to:
  /// **'Steil & technisch'**
  String get bikeBlurbEnduro;

  /// No description provided for @bikeBlurbDh.
  ///
  /// In de, this message translates to:
  /// **'Bikepark & Abfahrt'**
  String get bikeBlurbDh;

  /// No description provided for @bikeBlurbGravel.
  ///
  /// In de, this message translates to:
  /// **'Schotter & Distanz'**
  String get bikeBlurbGravel;

  /// No description provided for @bikeBlurbRoad.
  ///
  /// In de, this message translates to:
  /// **'Asphalt & Tempo'**
  String get bikeBlurbRoad;

  /// No description provided for @bikeBlurbUrban.
  ///
  /// In de, this message translates to:
  /// **'Alltag & Pendeln'**
  String get bikeBlurbUrban;

  /// No description provided for @bikeBlurbCargo.
  ///
  /// In de, this message translates to:
  /// **'Lasten & Alltag'**
  String get bikeBlurbCargo;

  /// No description provided for @bikeBlurbFolding.
  ///
  /// In de, this message translates to:
  /// **'Falten & mitnehmen'**
  String get bikeBlurbFolding;

  /// No description provided for @bikeBlurbKids.
  ///
  /// In de, this message translates to:
  /// **'Kinderrad'**
  String get bikeBlurbKids;

  /// No description provided for @bikeBlurbEmtb.
  ///
  /// In de, this message translates to:
  /// **'Trail mit Assist'**
  String get bikeBlurbEmtb;

  /// No description provided for @bikeBlurbEtrekking.
  ///
  /// In de, this message translates to:
  /// **'Touren mit Assist'**
  String get bikeBlurbEtrekking;

  /// No description provided for @bikeBlurbHiking.
  ///
  /// In de, this message translates to:
  /// **'Zu Fuß unterwegs'**
  String get bikeBlurbHiking;

  /// No description provided for @bikeBlurbMtbTrailFocus.
  ///
  /// In de, this message translates to:
  /// **'Singletrail-Fokus'**
  String get bikeBlurbMtbTrailFocus;

  /// No description provided for @onboardSportTrail.
  ///
  /// In de, this message translates to:
  /// **'Trail'**
  String get onboardSportTrail;

  /// No description provided for @sportsSummaryPrimary.
  ///
  /// In de, this message translates to:
  /// **'Haupt: {label}'**
  String sportsSummaryPrimary(String label);

  /// No description provided for @sportsSummaryPrimaryAlso.
  ///
  /// In de, this message translates to:
  /// **'Haupt: {label} · auch {list}'**
  String sportsSummaryPrimaryAlso(String label, String list);

  /// No description provided for @seasonYearRound.
  ///
  /// In de, this message translates to:
  /// **'Ganzjährig'**
  String get seasonYearRound;

  /// No description provided for @seasonSpringSummer.
  ///
  /// In de, this message translates to:
  /// **'Frühling–Sommer'**
  String get seasonSpringSummer;

  /// No description provided for @seasonAutumn.
  ///
  /// In de, this message translates to:
  /// **'Herbst'**
  String get seasonAutumn;

  /// No description provided for @seasonWinter.
  ///
  /// In de, this message translates to:
  /// **'Winter'**
  String get seasonWinter;

  /// No description provided for @naeheInYourRegion.
  ///
  /// In de, this message translates to:
  /// **'~60 Min in deiner Region'**
  String get naeheInYourRegion;

  /// No description provided for @naeheAroundYou.
  ///
  /// In de, this message translates to:
  /// **'~60 Min um dich'**
  String get naeheAroundYou;

  /// No description provided for @sportTagTouring.
  ///
  /// In de, this message translates to:
  /// **'Touring'**
  String get sportTagTouring;

  /// No description provided for @sportTagEbike.
  ///
  /// In de, this message translates to:
  /// **'E-Bike'**
  String get sportTagEbike;

  /// No description provided for @overlayRheinNeckar.
  ///
  /// In de, this message translates to:
  /// **'Rhein-Neckar / Heidelberg'**
  String get overlayRheinNeckar;

  /// No description provided for @overlaySchwarzwaldNord.
  ///
  /// In de, this message translates to:
  /// **'Schwarzwald Süd'**
  String get overlaySchwarzwaldNord;

  /// No description provided for @overlayBodensee.
  ///
  /// In de, this message translates to:
  /// **'Bodensee'**
  String get overlayBodensee;

  /// No description provided for @overlayStuttgart.
  ///
  /// In de, this message translates to:
  /// **'Stuttgart / Mittlerer Neckar'**
  String get overlayStuttgart;

  /// No description provided for @overlayMuenchen.
  ///
  /// In de, this message translates to:
  /// **'München & Umland'**
  String get overlayMuenchen;

  /// No description provided for @overlayNuernberg.
  ///
  /// In de, this message translates to:
  /// **'Nürnberg / Franken'**
  String get overlayNuernberg;

  /// No description provided for @overlayFrankfurtRheinMain.
  ///
  /// In de, this message translates to:
  /// **'Frankfurt Rhein-Main'**
  String get overlayFrankfurtRheinMain;

  /// No description provided for @overlayKoelnRhein.
  ///
  /// In de, this message translates to:
  /// **'Köln / Rheinland'**
  String get overlayKoelnRhein;

  /// No description provided for @overlayHamburg.
  ///
  /// In de, this message translates to:
  /// **'Hamburg & Umland'**
  String get overlayHamburg;

  /// No description provided for @overlayBerlin.
  ///
  /// In de, this message translates to:
  /// **'Berlin & Brandenburg'**
  String get overlayBerlin;

  /// No description provided for @overlayDresdenElbland.
  ///
  /// In de, this message translates to:
  /// **'Dresden / Elbland'**
  String get overlayDresdenElbland;

  /// No description provided for @overlayWien.
  ///
  /// In de, this message translates to:
  /// **'Wien & Wienerwald'**
  String get overlayWien;

  /// No description provided for @overlaySalzburg.
  ///
  /// In de, this message translates to:
  /// **'Salzburg'**
  String get overlaySalzburg;

  /// No description provided for @overlayInnsbruck.
  ///
  /// In de, this message translates to:
  /// **'Innsbruck / Tirol'**
  String get overlayInnsbruck;

  /// No description provided for @overlayZuerich.
  ///
  /// In de, this message translates to:
  /// **'Zürich & Umland'**
  String get overlayZuerich;

  /// No description provided for @overlayBern.
  ///
  /// In de, this message translates to:
  /// **'Bern / Mittelland'**
  String get overlayBern;

  /// No description provided for @overlayBasel.
  ///
  /// In de, this message translates to:
  /// **'Basel / Dreiländereck'**
  String get overlayBasel;

  /// No description provided for @overlayRuhrgebiet.
  ///
  /// In de, this message translates to:
  /// **'Ruhrgebiet'**
  String get overlayRuhrgebiet;

  /// No description provided for @overlayDuesseldorf.
  ///
  /// In de, this message translates to:
  /// **'Düsseldorf / Niederrhein'**
  String get overlayDuesseldorf;

  /// No description provided for @overlayHannover.
  ///
  /// In de, this message translates to:
  /// **'Hannover / Leine'**
  String get overlayHannover;

  /// No description provided for @overlayLeipzig.
  ///
  /// In de, this message translates to:
  /// **'Leipzig / Neuseenland'**
  String get overlayLeipzig;

  /// No description provided for @overlayFreiburg.
  ///
  /// In de, this message translates to:
  /// **'Freiburg / Schauinsland'**
  String get overlayFreiburg;

  /// No description provided for @overlayKarlsruhe.
  ///
  /// In de, this message translates to:
  /// **'Karlsruhe / Hardt'**
  String get overlayKarlsruhe;

  /// No description provided for @overlayAugsburg.
  ///
  /// In de, this message translates to:
  /// **'Augsburg / Lech'**
  String get overlayAugsburg;

  /// No description provided for @overlayKiel.
  ///
  /// In de, this message translates to:
  /// **'Kiel / Förde'**
  String get overlayKiel;

  /// No description provided for @overlayRostock.
  ///
  /// In de, this message translates to:
  /// **'Rostock / Warnow'**
  String get overlayRostock;

  /// No description provided for @overlayKassel.
  ///
  /// In de, this message translates to:
  /// **'Kassel / Bergpark'**
  String get overlayKassel;

  /// No description provided for @overlayTrierMosel.
  ///
  /// In de, this message translates to:
  /// **'Trier / Mosel'**
  String get overlayTrierMosel;

  /// No description provided for @overlayPfalz.
  ///
  /// In de, this message translates to:
  /// **'Pfälzerwald'**
  String get overlayPfalz;

  /// No description provided for @overlaySauerland.
  ///
  /// In de, this message translates to:
  /// **'Sauerland'**
  String get overlaySauerland;

  /// No description provided for @overlayEifelTrails.
  ///
  /// In de, this message translates to:
  /// **'Eifel'**
  String get overlayEifelTrails;

  /// No description provided for @overlayHarz.
  ///
  /// In de, this message translates to:
  /// **'Harz'**
  String get overlayHarz;

  /// No description provided for @overlayThueringerWald.
  ///
  /// In de, this message translates to:
  /// **'Thüringer Wald'**
  String get overlayThueringerWald;

  /// No description provided for @overlayBayerischerWald.
  ///
  /// In de, this message translates to:
  /// **'Bayerischer Wald'**
  String get overlayBayerischerWald;

  /// No description provided for @overlayAllgaeu.
  ///
  /// In de, this message translates to:
  /// **'Allgäu'**
  String get overlayAllgaeu;

  /// No description provided for @overlayChiemgau.
  ///
  /// In de, this message translates to:
  /// **'Chiemgau'**
  String get overlayChiemgau;

  /// No description provided for @overlaySaarbruecken.
  ///
  /// In de, this message translates to:
  /// **'Saarbrücken'**
  String get overlaySaarbruecken;

  /// No description provided for @overlayMuenster.
  ///
  /// In de, this message translates to:
  /// **'Münsterland'**
  String get overlayMuenster;

  /// No description provided for @overlayAachen.
  ///
  /// In de, this message translates to:
  /// **'Aachen / Dreiländereck'**
  String get overlayAachen;

  /// No description provided for @overlayLuebeck.
  ///
  /// In de, this message translates to:
  /// **'Lübeck / Trave'**
  String get overlayLuebeck;

  /// No description provided for @overlayBremen.
  ///
  /// In de, this message translates to:
  /// **'Bremen / Weser'**
  String get overlayBremen;

  /// No description provided for @overlayMagdeburg.
  ///
  /// In de, this message translates to:
  /// **'Magdeburg / Elbe'**
  String get overlayMagdeburg;

  /// No description provided for @overlayErfurt.
  ///
  /// In de, this message translates to:
  /// **'Erfurt'**
  String get overlayErfurt;

  /// No description provided for @overlayKoblenz.
  ///
  /// In de, this message translates to:
  /// **'Koblenz / Rhein-Mosel'**
  String get overlayKoblenz;

  /// No description provided for @overlayGraz.
  ///
  /// In de, this message translates to:
  /// **'Graz / Murtal'**
  String get overlayGraz;

  /// No description provided for @overlayLinz.
  ///
  /// In de, this message translates to:
  /// **'Linz / Donau'**
  String get overlayLinz;

  /// No description provided for @overlayKlagenfurt.
  ///
  /// In de, this message translates to:
  /// **'Klagenfurt / Wörthersee'**
  String get overlayKlagenfurt;

  /// No description provided for @overlayVillach.
  ///
  /// In de, this message translates to:
  /// **'Villach / Drau'**
  String get overlayVillach;

  /// No description provided for @overlayBregenz.
  ///
  /// In de, this message translates to:
  /// **'Bregenz / Vorarlberg'**
  String get overlayBregenz;

  /// No description provided for @overlayKitzbuehel.
  ///
  /// In de, this message translates to:
  /// **'Kitzbühel / Wilder Kaiser'**
  String get overlayKitzbuehel;

  /// No description provided for @overlayGenf.
  ///
  /// In de, this message translates to:
  /// **'Genf / Lac Léman'**
  String get overlayGenf;

  /// No description provided for @overlayLausanne.
  ///
  /// In de, this message translates to:
  /// **'Lausanne / Lavaux'**
  String get overlayLausanne;

  /// No description provided for @overlayLuzern.
  ///
  /// In de, this message translates to:
  /// **'Luzern / Vierwaldstättersee'**
  String get overlayLuzern;

  /// No description provided for @overlayStGallen.
  ///
  /// In de, this message translates to:
  /// **'St. Gallen / Appenzell'**
  String get overlayStGallen;

  /// No description provided for @overlayLugano.
  ///
  /// In de, this message translates to:
  /// **'Lugano / Tessin'**
  String get overlayLugano;

  /// No description provided for @overlayInterlaken.
  ///
  /// In de, this message translates to:
  /// **'Interlaken / Berner Oberland'**
  String get overlayInterlaken;

  /// No description provided for @overlayChur.
  ///
  /// In de, this message translates to:
  /// **'Chur / Graubünden'**
  String get overlayChur;

  /// No description provided for @overlayZermatt.
  ///
  /// In de, this message translates to:
  /// **'Zermatt / Mattertal'**
  String get overlayZermatt;

  /// No description provided for @overlayStMoritz.
  ///
  /// In de, this message translates to:
  /// **'St. Moritz / Engadin'**
  String get overlayStMoritz;

  /// No description provided for @overlayDavos.
  ///
  /// In de, this message translates to:
  /// **'Davos / Landwasser'**
  String get overlayDavos;

  /// No description provided for @overlayStrasbourg.
  ///
  /// In de, this message translates to:
  /// **'Straßburg / Ill'**
  String get overlayStrasbourg;

  /// No description provided for @overlayAlsaceVins.
  ///
  /// In de, this message translates to:
  /// **'Elsass / Route des Vins'**
  String get overlayAlsaceVins;

  /// No description provided for @overlayVosges.
  ///
  /// In de, this message translates to:
  /// **'Vogesen / Ballon d\'Alsace'**
  String get overlayVosges;

  /// No description provided for @overlayNancyMoselle.
  ///
  /// In de, this message translates to:
  /// **'Nancy / Moselle'**
  String get overlayNancyMoselle;

  /// No description provided for @overlayJuraFr.
  ///
  /// In de, this message translates to:
  /// **'Jura / Pontarlier'**
  String get overlayJuraFr;

  /// No description provided for @overlayAnnecy.
  ///
  /// In de, this message translates to:
  /// **'Annecy / Semnoz'**
  String get overlayAnnecy;

  /// No description provided for @overlayMorzine.
  ///
  /// In de, this message translates to:
  /// **'Morzine / Portes du Soleil'**
  String get overlayMorzine;

  /// No description provided for @overlayLyon.
  ///
  /// In de, this message translates to:
  /// **'Lyon / Tête d\'Or'**
  String get overlayLyon;

  /// No description provided for @overlayGrenoble.
  ///
  /// In de, this message translates to:
  /// **'Grenoble / Isère'**
  String get overlayGrenoble;

  /// No description provided for @overlayDijon.
  ///
  /// In de, this message translates to:
  /// **'Dijon / Canal de Bourgogne'**
  String get overlayDijon;

  /// No description provided for @overlayChambery.
  ///
  /// In de, this message translates to:
  /// **'Chambéry / Lac du Bourget'**
  String get overlayChambery;

  /// No description provided for @overlayParis.
  ///
  /// In de, this message translates to:
  /// **'Paris / Bois & Seine'**
  String get overlayParis;

  /// No description provided for @overlayLille.
  ///
  /// In de, this message translates to:
  /// **'Lille / Citadelle'**
  String get overlayLille;

  /// No description provided for @overlayNice.
  ///
  /// In de, this message translates to:
  /// **'Nizza / Promenade des Anglais'**
  String get overlayNice;

  /// No description provided for @overlayMarseille.
  ///
  /// In de, this message translates to:
  /// **'Marseille / Corniche'**
  String get overlayMarseille;

  /// No description provided for @overlayBordeaux.
  ///
  /// In de, this message translates to:
  /// **'Bordeaux / Garonne'**
  String get overlayBordeaux;

  /// No description provided for @overlayToulouse.
  ///
  /// In de, this message translates to:
  /// **'Toulouse / Canal du Midi'**
  String get overlayToulouse;

  /// No description provided for @overlayNantes.
  ///
  /// In de, this message translates to:
  /// **'Nantes / Erdre'**
  String get overlayNantes;

  /// No description provided for @offlineProgressPack.
  ///
  /// In de, this message translates to:
  /// **'Pack {got} / {total}'**
  String offlineProgressPack(String got, String total);

  /// No description provided for @offlineProgressBasemap.
  ///
  /// In de, this message translates to:
  /// **'Basemap {id}…'**
  String offlineProgressBasemap(String id);

  /// No description provided for @offlineProgressBasemapBytes.
  ///
  /// In de, this message translates to:
  /// **'Basemap {got} / {total}'**
  String offlineProgressBasemapBytes(String got, String total);

  /// No description provided for @offlineProgressMapZoom.
  ///
  /// In de, this message translates to:
  /// **'Karte (Zoom {min}–{max})…'**
  String offlineProgressMapZoom(String min, String max);

  /// No description provided for @offlineProgressMapPercent.
  ///
  /// In de, this message translates to:
  /// **'Karte {percent}%'**
  String offlineProgressMapPercent(String percent);

  /// No description provided for @offlineProgressActivating.
  ///
  /// In de, this message translates to:
  /// **'Aktivieren…'**
  String get offlineProgressActivating;

  /// No description provided for @offlineProgressManifest.
  ///
  /// In de, this message translates to:
  /// **'Manifest…'**
  String get offlineProgressManifest;

  /// No description provided for @offlineProgressPackFile.
  ///
  /// In de, this message translates to:
  /// **'Pack {file}…'**
  String offlineProgressPackFile(String file);

  /// No description provided for @offlineProgressGraphFile.
  ///
  /// In de, this message translates to:
  /// **'offline_graph.json…'**
  String get offlineProgressGraphFile;

  /// No description provided for @offlineProgressDemoGraph.
  ///
  /// In de, this message translates to:
  /// **'Demo-Graph (Schwarzwald)…'**
  String get offlineProgressDemoGraph;

  /// No description provided for @offlinePacksReadyOne.
  ///
  /// In de, this message translates to:
  /// **'1 Pack ladbar'**
  String get offlinePacksReadyOne;

  /// No description provided for @offlinePacksReadyCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Packs ladbar'**
  String offlinePacksReadyCount(int count);

  /// No description provided for @offlinePackNotBuilt.
  ///
  /// In de, this message translates to:
  /// **'{name}: Pack noch nicht gebaut — kein Download.'**
  String offlinePackNotBuilt(String name);

  /// No description provided for @offlineShaMismatch.
  ///
  /// In de, this message translates to:
  /// **'SHA-256 stimmt mit keinem Download überein (erwartet {sha})'**
  String offlineShaMismatch(String sha);

  /// No description provided for @offlineInvalidGraphFolder.
  ///
  /// In de, this message translates to:
  /// **'Ordner {id} enthält keinen gültigen Graph für diese Region'**
  String offlineInvalidGraphFolder(String id);

  /// No description provided for @offlineNoRemotePack.
  ///
  /// In de, this message translates to:
  /// **'Kein Remote-Pack für {name}. Catalog-Stubs aktivieren keinen fremden Demo-Graph.'**
  String offlineNoRemotePack(String name);

  /// No description provided for @offlineDownloadEmpty.
  ///
  /// In de, this message translates to:
  /// **'Download leer'**
  String get offlineDownloadEmpty;

  /// No description provided for @offlineNoGraphAfterExtract.
  ///
  /// In de, this message translates to:
  /// **'Kein Graph nach Extract'**
  String get offlineNoGraphAfterExtract;

  /// No description provided for @offlineRawPmtiles.
  ///
  /// In de, this message translates to:
  /// **'Roh-.pmtiles wird nicht unterstützt — MapLibre-Style-JSON mit pmtiles://-Source nötig.'**
  String get offlineRawPmtiles;

  /// No description provided for @offlineInvalidUrl.
  ///
  /// In de, this message translates to:
  /// **'Ungültige URL'**
  String get offlineInvalidUrl;

  /// No description provided for @offlineExpectStyleJson.
  ///
  /// In de, this message translates to:
  /// **'Erwarte Style-JSON-URL (*.json oder /styles/…), keine Tile-Datei.'**
  String get offlineExpectStyleJson;

  /// No description provided for @offlineSubActive.
  ///
  /// In de, this message translates to:
  /// **'Aktiv — tippen zum Aktualisieren'**
  String get offlineSubActive;

  /// No description provided for @offlineSubInstalled.
  ///
  /// In de, this message translates to:
  /// **'Installiert — tippen zum Aktivieren'**
  String get offlineSubInstalled;

  /// No description provided for @offlineSubDemoGraph.
  ///
  /// In de, this message translates to:
  /// **'Demo-Graph in der App (kein Remote-Pack)'**
  String get offlineSubDemoGraph;

  /// No description provided for @offlineSubNotBuilt.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht gebaut'**
  String get offlineSubNotBuilt;

  /// No description provided for @offlineSubLoad.
  ///
  /// In de, this message translates to:
  /// **'Routing + Karte laden'**
  String get offlineSubLoad;

  /// No description provided for @offlineSubLoadSized.
  ///
  /// In de, this message translates to:
  /// **'{size} · Routing + Karte'**
  String offlineSubLoadSized(String size);

  /// No description provided for @offlineGraphMissing.
  ///
  /// In de, this message translates to:
  /// **'Kein Graph in {name}'**
  String offlineGraphMissing(String name);

  /// No description provided for @offlineGraphSha.
  ///
  /// In de, this message translates to:
  /// **'Graph-SHA von {name} stimmt nicht'**
  String offlineGraphSha(String name);

  /// No description provided for @offlineGraphDemoMismatch.
  ///
  /// In de, this message translates to:
  /// **'Demo-Graph Schwarzwald passt nicht zu {name}'**
  String offlineGraphDemoMismatch(String name);

  /// No description provided for @offlineEngineLinkedNoTiles.
  ///
  /// In de, this message translates to:
  /// **'Graph-Engine · Valhalla gelinkt, Region-Tiles fehlen noch'**
  String get offlineEngineLinkedNoTiles;

  /// No description provided for @offlineEngineTilesNotBuilt.
  ///
  /// In de, this message translates to:
  /// **'Graph-Engine · Valhalla-Tiles nicht gebaut'**
  String get offlineEngineTilesNotBuilt;

  /// No description provided for @offlineNoTiles.
  ///
  /// In de, this message translates to:
  /// **'keine Tiles'**
  String get offlineNoTiles;

  /// No description provided for @offlineFfiMissing.
  ///
  /// In de, this message translates to:
  /// **'FFI fehlt — graph-only / Valhalla-Flag nicht gelinkt'**
  String get offlineFfiMissing;

  /// No description provided for @offlineValhallaTilesLinked.
  ///
  /// In de, this message translates to:
  /// **'Valhalla-Tiles · libvalhalla gelinkt'**
  String get offlineValhallaTilesLinked;

  /// No description provided for @offlineValhallaTilesUnlinked.
  ///
  /// In de, this message translates to:
  /// **'Valhalla-Tiles · UNLINKED (Code {code})'**
  String offlineValhallaTilesUnlinked(String code);

  /// No description provided for @offlineValhallaFeature.
  ///
  /// In de, this message translates to:
  /// **'Valhalla-Feature verfügbar'**
  String get offlineValhallaFeature;

  /// No description provided for @offlineValhallaNotLinked.
  ///
  /// In de, this message translates to:
  /// **'Valhalla nicht gelinkt'**
  String get offlineValhallaNotLinked;

  /// No description provided for @garageMuscle.
  ///
  /// In de, this message translates to:
  /// **'Muskel'**
  String get garageMuscle;

  /// No description provided for @garageOemTaken.
  ///
  /// In de, this message translates to:
  /// **'{name}: {count} Serienteile übernommen.'**
  String garageOemTaken(String name, int count);

  /// No description provided for @garageOemTakenPartial.
  ///
  /// In de, this message translates to:
  /// **'{name}: {taken} Serienteile, {skipped} übersprungen.'**
  String garageOemTakenPartial(String name, int taken, int skipped);

  /// No description provided for @garageOemKitOff.
  ///
  /// In de, this message translates to:
  /// **'{name} abgestellt — Teile selbst anlegen, Kit war aus.'**
  String garageOemKitOff(String name);

  /// No description provided for @garageGpxSaved.
  ///
  /// In de, this message translates to:
  /// **'{name}: GPX gespeichert ({km} km).'**
  String garageGpxSaved(String name, String km);

  /// No description provided for @garageKmImported.
  ///
  /// In de, this message translates to:
  /// **'+{km} km importiert'**
  String garageKmImported(String km);

  /// No description provided for @garageLogOdoUpdated.
  ///
  /// In de, this message translates to:
  /// **'Kilometerstand aktualisiert'**
  String get garageLogOdoUpdated;

  /// No description provided for @garageLogHoursUpdated.
  ///
  /// In de, this message translates to:
  /// **'Betriebsstunden aktualisiert'**
  String get garageLogHoursUpdated;

  /// No description provided for @garageLogGpxImport.
  ///
  /// In de, this message translates to:
  /// **'GPX importiert'**
  String get garageLogGpxImport;

  /// No description provided for @garageLogImportPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'Import ohne Komponenten'**
  String get garageLogImportPlaceholder;

  /// No description provided for @garageLogManualKm.
  ///
  /// In de, this message translates to:
  /// **'Manuell: {km} km'**
  String garageLogManualKm(String km);

  /// No description provided for @garageLogManualHours.
  ///
  /// In de, this message translates to:
  /// **'Manuell: {hours} h'**
  String garageLogManualHours(String hours);

  /// No description provided for @garageLogPsiFront.
  ///
  /// In de, this message translates to:
  /// **'vorn {psi} psi'**
  String garageLogPsiFront(String psi);

  /// No description provided for @garageLogPsiRear.
  ///
  /// In de, this message translates to:
  /// **'hinten {psi} psi'**
  String garageLogPsiRear(String psi);

  /// No description provided for @garageLogBarFront.
  ///
  /// In de, this message translates to:
  /// **'vorn {bar} bar'**
  String garageLogBarFront(String bar);

  /// No description provided for @garageLogBarRear.
  ///
  /// In de, this message translates to:
  /// **'hinten {bar} bar'**
  String garageLogBarRear(String bar);

  /// No description provided for @bikeCatEmtbTrail.
  ///
  /// In de, this message translates to:
  /// **'E-MTB Trail'**
  String get bikeCatEmtbTrail;

  /// No description provided for @bikeCatEenduro.
  ///
  /// In de, this message translates to:
  /// **'E-Enduro'**
  String get bikeCatEenduro;

  /// No description provided for @bikeCatEdh.
  ///
  /// In de, this message translates to:
  /// **'E-DH'**
  String get bikeCatEdh;

  /// No description provided for @discoverCatalogTours.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Katalog 1 Tour} other{Katalog {count} Touren}}'**
  String discoverCatalogTours(int count);

  /// No description provided for @discoverCatalogToursSuffix.
  ///
  /// In de, this message translates to:
  /// **' · Katalog {count}'**
  String discoverCatalogToursSuffix(int count);

  /// No description provided for @discoverToursOsmStatus.
  ///
  /// In de, this message translates to:
  /// **'Touren {tours} · {withTrack} mit Strecke'**
  String discoverToursOsmStatus(int tours, int withTrack, int osm);

  /// No description provided for @discoverElevationApprox.
  ///
  /// In de, this message translates to:
  /// **'~{hm} hm (Schätzung — Höhe gerade nicht da)'**
  String discoverElevationApprox(String hm);

  /// No description provided for @discoverElevationGainLoss.
  ///
  /// In de, this message translates to:
  /// **'+{gain} / −{loss} hm'**
  String discoverElevationGainLoss(String gain, String loss);

  /// No description provided for @discoverElevationGainLossSource.
  ///
  /// In de, this message translates to:
  /// **'+{gain} / −{loss} hm · {source}'**
  String discoverElevationGainLossSource(
      String gain, String loss, String source);

  /// No description provided for @discoverDurationMin.
  ///
  /// In de, this message translates to:
  /// **'{n} Min'**
  String discoverDurationMin(String n);

  /// No description provided for @discoverPlanName.
  ///
  /// In de, this message translates to:
  /// **'{name} (Plan)'**
  String discoverPlanName(String name);

  /// No description provided for @demoCityMuenchen.
  ///
  /// In de, this message translates to:
  /// **'München'**
  String get demoCityMuenchen;

  /// No description provided for @demoCityKoeln.
  ///
  /// In de, this message translates to:
  /// **'Köln'**
  String get demoCityKoeln;

  /// No description provided for @demoCityZuerich.
  ///
  /// In de, this message translates to:
  /// **'Zürich'**
  String get demoCityZuerich;

  /// No description provided for @demoCityWien.
  ///
  /// In de, this message translates to:
  /// **'Wien'**
  String get demoCityWien;

  /// No description provided for @demoCityKonstanz.
  ///
  /// In de, this message translates to:
  /// **'Konstanz'**
  String get demoCityKonstanz;

  /// No description provided for @demoCityParis.
  ///
  /// In de, this message translates to:
  /// **'Paris'**
  String get demoCityParis;

  /// No description provided for @demoCityStrasbourg.
  ///
  /// In de, this message translates to:
  /// **'Straßburg'**
  String get demoCityStrasbourg;

  /// No description provided for @demoCityNice.
  ///
  /// In de, this message translates to:
  /// **'Nizza'**
  String get demoCityNice;

  /// No description provided for @postRideStravaConnect.
  ///
  /// In de, this message translates to:
  /// **'Strava verbinden unter Daten & Privatsphäre.'**
  String get postRideStravaConnect;

  /// No description provided for @postRideStravaKeysMissing.
  ///
  /// In de, this message translates to:
  /// **'Strava-Keys fehlen — GPX/FIT nutzen.'**
  String get postRideStravaKeysMissing;

  /// No description provided for @postRideStravaStatusDown.
  ///
  /// In de, this message translates to:
  /// **'Strava-Status nicht erreichbar — GPX/FIT nutzen.'**
  String get postRideStravaStatusDown;

  /// No description provided for @postRideStravaHint.
  ///
  /// In de, this message translates to:
  /// **'Strava: mit GPS-Track via Uploads-API; ohne Track nur Metadaten.'**
  String get postRideStravaHint;

  /// No description provided for @postRideStravaError.
  ///
  /// In de, this message translates to:
  /// **'Strava: {error}'**
  String postRideStravaError(String error);

  /// No description provided for @postRideHeatmapPrivate.
  ///
  /// In de, this message translates to:
  /// **'Heatmap: Tour ist privat — Track nicht beigetragen.'**
  String get postRideHeatmapPrivate;

  /// No description provided for @postRideHeatmapError.
  ///
  /// In de, this message translates to:
  /// **'Heatmap: {error}'**
  String postRideHeatmapError(String error);

  /// No description provided for @postRideSetupSaved.
  ///
  /// In de, this message translates to:
  /// **'Setup-Version gespeichert'**
  String get postRideSetupSaved;

  /// No description provided for @postRideSetupSaveFailed.
  ///
  /// In de, this message translates to:
  /// **'Setup speichern fehlgeschlagen: {error}'**
  String postRideSetupSaveFailed(String error);

  /// No description provided for @postRideGpxEmpty.
  ///
  /// In de, this message translates to:
  /// **'Kein GPS-Track — GPX wäre leer'**
  String get postRideGpxEmpty;

  /// No description provided for @postRideGpxExportError.
  ///
  /// In de, this message translates to:
  /// **'GPX-Export: {error}'**
  String postRideGpxExportError(String error);

  /// No description provided for @postRideFitExportError.
  ///
  /// In de, this message translates to:
  /// **'FIT-Export: {error}'**
  String postRideFitExportError(String error);

  /// No description provided for @postRideShareGpx.
  ///
  /// In de, this message translates to:
  /// **'GPX teilen'**
  String get postRideShareGpx;

  /// No description provided for @postRideSimActive.
  ///
  /// In de, this message translates to:
  /// **'Sim-Track war aktiv'**
  String get postRideSimActive;

  /// No description provided for @postRideSimDistance.
  ///
  /// In de, this message translates to:
  /// **' (~{km} km simuliert)'**
  String postRideSimDistance(String km);

  /// No description provided for @postRideSimUnreliable.
  ///
  /// In de, this message translates to:
  /// **' — Distanz/Analyse ggf. unzuverlässig. Für echte Rides AETHER_SIM_MOTION aus.'**
  String get postRideSimUnreliable;

  /// No description provided for @postRideAvgSpeedHigh.
  ///
  /// In de, this message translates to:
  /// **'Ungewöhnlich hohe Durchschnittsgeschwindigkeit — GPS/Sim prüfen.'**
  String get postRideAvgSpeedHigh;

  /// No description provided for @postRideSuggestionTaken.
  ///
  /// In de, this message translates to:
  /// **'Übernommen'**
  String get postRideSuggestionTaken;

  /// No description provided for @postRideSuggestionAccept.
  ///
  /// In de, this message translates to:
  /// **'Empfehlung annehmen'**
  String get postRideSuggestionAccept;

  /// No description provided for @postRideAssistEstimate.
  ///
  /// In de, this message translates to:
  /// **'Assist (Schätzung)'**
  String get postRideAssistEstimate;

  /// No description provided for @postRideAssistDominant.
  ///
  /// In de, this message translates to:
  /// **'Dominant: {mode} · ~{wh} Wh'**
  String postRideAssistDominant(String mode, String wh);

  /// No description provided for @postRideAssistApproach.
  ///
  /// In de, this message translates to:
  /// **'Schätzung: {mode} (Anfahrt)'**
  String postRideAssistApproach(String mode);

  /// No description provided for @postRideAssistClimb.
  ///
  /// In de, this message translates to:
  /// **'Schätzung: {mode} (Steigung, {pct} %)'**
  String postRideAssistClimb(String mode, String pct);

  /// No description provided for @postRideAssistRest.
  ///
  /// In de, this message translates to:
  /// **'Schätzung: {mode} (Rest)'**
  String postRideAssistRest(String mode);

  /// No description provided for @postRideAssistDisclaimer.
  ///
  /// In de, this message translates to:
  /// **'Schätzungen aus Leistungs-/Geschwindigkeitssignatur — kein OEM-Auslesen. Keine Motorsteuerung (F-EBK-000).'**
  String get postRideAssistDisclaimer;

  /// No description provided for @postRideFeelTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie hat es sich angefühlt?'**
  String get postRideFeelTitle;

  /// No description provided for @postRideFrontSuspension.
  ///
  /// In de, this message translates to:
  /// **'Federung vorne'**
  String get postRideFrontSuspension;

  /// No description provided for @postRideFrontTooSoft.
  ///
  /// In de, this message translates to:
  /// **'zu weich'**
  String get postRideFrontTooSoft;

  /// No description provided for @postRideBrakeDive.
  ///
  /// In de, this message translates to:
  /// **'Bremsnick'**
  String get postRideBrakeDive;

  /// No description provided for @postRideBrakeDives.
  ///
  /// In de, this message translates to:
  /// **'taucht'**
  String get postRideBrakeDives;

  /// No description provided for @postRideBrakeNeutral.
  ///
  /// In de, this message translates to:
  /// **'neutral'**
  String get postRideBrakeNeutral;

  /// No description provided for @postRideBrakeHarsh.
  ///
  /// In de, this message translates to:
  /// **'hart'**
  String get postRideBrakeHarsh;

  /// No description provided for @postRideSmallBumps.
  ///
  /// In de, this message translates to:
  /// **'Kleine Schläge'**
  String get postRideSmallBumps;

  /// No description provided for @postRideBumpsVague.
  ///
  /// In de, this message translates to:
  /// **'schwammig'**
  String get postRideBumpsVague;

  /// No description provided for @postRideSaveFeedback.
  ///
  /// In de, this message translates to:
  /// **'Feedback speichern'**
  String get postRideSaveFeedback;

  /// No description provided for @postRideShortRideMetrics.
  ///
  /// In de, this message translates to:
  /// **'Kurzride — Metriken eingeschränkt (< 0,5 km).'**
  String get postRideShortRideMetrics;

  /// No description provided for @postRideMetricsTitle.
  ///
  /// In de, this message translates to:
  /// **'Metriken'**
  String get postRideMetricsTitle;

  /// No description provided for @postRideDefaultName.
  ///
  /// In de, this message translates to:
  /// **'Fahrt'**
  String get postRideDefaultName;

  /// No description provided for @platzCreateGroupHint.
  ///
  /// In de, this message translates to:
  /// **'Tour wählen, Sichtbarkeit, dann den Link teilen.'**
  String get platzCreateGroupHint;

  /// No description provided for @platzGroupPublicHint.
  ///
  /// In de, this message translates to:
  /// **'Wer den Link hat, kann beitreten. Unter Freigegeben können andere die Gruppe auf dem Platz sehen.'**
  String get platzGroupPublicHint;

  /// No description provided for @platzGroupPrivateHint.
  ///
  /// In de, this message translates to:
  /// **'Nur wer den Link hat, kann beitreten. Kein öffentliches Verzeichnis.'**
  String get platzGroupPrivateHint;

  /// No description provided for @platzNoPrivateGroups.
  ///
  /// In de, this message translates to:
  /// **'Keine privaten Gruppen in diesem Filter.'**
  String get platzNoPrivateGroups;

  /// No description provided for @platzMakePrivate.
  ///
  /// In de, this message translates to:
  /// **'Privat machen'**
  String get platzMakePrivate;

  /// No description provided for @platzMakePublic.
  ///
  /// In de, this message translates to:
  /// **'Auf dem Platz listen'**
  String get platzMakePublic;

  /// No description provided for @platzNoPublicGroups.
  ///
  /// In de, this message translates to:
  /// **'Keine offenen Gruppen auf dem Server.'**
  String get platzNoPublicGroups;

  /// No description provided for @platzPublicGroupsHint.
  ///
  /// In de, this message translates to:
  /// **'Offene Gruppen — Beitritt mit Login, kein Explore-GPS.'**
  String get platzPublicGroupsHint;

  /// No description provided for @platzListedPublic.
  ///
  /// In de, this message translates to:
  /// **'auf dem Platz'**
  String get platzListedPublic;

  /// No description provided for @filterVisibilityAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get filterVisibilityAll;

  /// No description provided for @filterVisibilityPublic.
  ///
  /// In de, this message translates to:
  /// **'Freigegeben'**
  String get filterVisibilityPublic;

  /// No description provided for @mappeTitle.
  ///
  /// In de, this message translates to:
  /// **'Die Mappe'**
  String get mappeTitle;

  /// No description provided for @mappeSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Touren merken, kurz schreiben, Freunde per Link mitnehmen — dieselben Touren wie auf der Karte.'**
  String get mappeSubtitle;

  /// No description provided for @mappeAddHint.
  ///
  /// In de, this message translates to:
  /// **'Name + Start (GPS, sonst letzte Kartenmitte, sonst ohne Pin) — ohne erfundenen Track. GPX als Option darunter.'**
  String get mappeAddHint;

  /// No description provided for @mappeStartNone.
  ///
  /// In de, this message translates to:
  /// **'Start: noch ohne Pin — GPS oder Karte öffnen.'**
  String get mappeStartNone;

  /// No description provided for @mappeStartPin.
  ///
  /// In de, this message translates to:
  /// **'Start: {lat}°N, {lng}°E'**
  String mappeStartPin(String lat, String lng);

  /// No description provided for @mappeStartGps.
  ///
  /// In de, this message translates to:
  /// **'Start: dein Standort ({coords})'**
  String mappeStartGps(String coords);

  /// No description provided for @mappeStartMap.
  ///
  /// In de, this message translates to:
  /// **'Start: letzte Kartenmitte ({coords})'**
  String mappeStartMap(String coords);

  /// No description provided for @mappePutIn.
  ///
  /// In de, this message translates to:
  /// **'In die Mappe legen'**
  String get mappePutIn;

  /// No description provided for @mappeSaved.
  ///
  /// In de, this message translates to:
  /// **'In der Mappe: {name}'**
  String mappeSaved(String name);

  /// No description provided for @mappeImported.
  ///
  /// In de, this message translates to:
  /// **'Importiert: {name}'**
  String mappeImported(String name);

  /// No description provided for @mappeEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine eigenen Strecken — Route hinzufügen.'**
  String get mappeEmpty;

  /// No description provided for @mappeStimmenEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Stimmen zu deinen Touren. Nach Freigabe können andere schreiben.'**
  String get mappeStimmenEmpty;

  /// No description provided for @myRoutesSourceOwn.
  ///
  /// In de, this message translates to:
  /// **'Eigene'**
  String get myRoutesSourceOwn;

  /// No description provided for @privacyZoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Privacy-Zone'**
  String get privacyZoneTitle;

  /// No description provided for @privacyZoneEdit.
  ///
  /// In de, this message translates to:
  /// **'Zone anpassen'**
  String get privacyZoneEdit;

  /// No description provided for @privacyZoneInvalidCoords.
  ///
  /// In de, this message translates to:
  /// **'Bitte gültige Koordinaten angeben'**
  String get privacyZoneInvalidCoords;

  /// No description provided for @privacyZoneNeedTap.
  ///
  /// In de, this message translates to:
  /// **'Bitte auf die Karte tippen'**
  String get privacyZoneNeedTap;

  /// No description provided for @privacyZoneTapShort.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf die Karte'**
  String get privacyZoneTapShort;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Erneut'**
  String get retry;

  /// No description provided for @hofSystemStatus.
  ///
  /// In de, this message translates to:
  /// **'Systemstatus'**
  String get hofSystemStatus;

  /// No description provided for @hofSystemOk.
  ///
  /// In de, this message translates to:
  /// **'Alles verbunden — Werkstatt, Fahrten und Sync laufen normal.'**
  String get hofSystemOk;

  /// No description provided for @hofSupabaseMissing.
  ///
  /// In de, this message translates to:
  /// **'Supabase nicht konfiguriert'**
  String get hofSupabaseMissing;

  /// No description provided for @hofSupabaseMissingHint.
  ///
  /// In de, this message translates to:
  /// **'Cloud-Sync ist nicht eingerichtet — Anmeldung und Sync sind aus.'**
  String get hofSupabaseMissingHint;

  /// No description provided for @hofSyncSessionExpired.
  ///
  /// In de, this message translates to:
  /// **'Sync: Sitzung abgelaufen'**
  String get hofSyncSessionExpired;

  /// No description provided for @hofSyncLoginOnly.
  ///
  /// In de, this message translates to:
  /// **'Sync nur mit Login'**
  String get hofSyncLoginOnly;

  /// No description provided for @hofSyncLocalHint.
  ///
  /// In de, this message translates to:
  /// **'Garage/Rides bleiben lokal — Konto für Cloud-Sync.'**
  String get hofSyncLocalHint;

  /// No description provided for @hofSystemNotice.
  ///
  /// In de, this message translates to:
  /// **'Systemstatus — Hinweis vorhanden'**
  String get hofSystemNotice;

  /// No description provided for @hofSystemHint.
  ///
  /// In de, this message translates to:
  /// **'Systemstatus — Hinweis'**
  String get hofSystemHint;

  /// No description provided for @hofSystemOkTooltip.
  ///
  /// In de, this message translates to:
  /// **'Systemstatus: ok'**
  String get hofSystemOkTooltip;

  /// No description provided for @hofTafelTitle.
  ///
  /// In de, this message translates to:
  /// **'Die Tafel'**
  String get hofTafelTitle;

  /// No description provided for @hofTafelVoiceOne.
  ///
  /// In de, this message translates to:
  /// **'Neue Stimme zu {name}'**
  String hofTafelVoiceOne(String name);

  /// No description provided for @hofTafelVoices.
  ///
  /// In de, this message translates to:
  /// **'{count} Stimmen zu {name}'**
  String hofTafelVoices(int count, String name);

  /// No description provided for @hofTafelGroup.
  ///
  /// In de, this message translates to:
  /// **'Gruppe vor dem Tor · {title}'**
  String hofTafelGroup(String title);

  /// No description provided for @ridePuckSemantics.
  ///
  /// In de, this message translates to:
  /// **'Navigation, {name}'**
  String ridePuckSemantics(String name);

  /// No description provided for @dieBoxSentenceHome.
  ///
  /// In de, this message translates to:
  /// **'{name} wohnt hier'**
  String dieBoxSentenceHome(String name);

  /// No description provided for @dieBoxLater.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get dieBoxLater;

  /// No description provided for @dieBoxSentenceMtbReady.
  ///
  /// In de, this message translates to:
  /// **'{name} · {travel}{drive} · bereit'**
  String dieBoxSentenceMtbReady(String name, String travel, String drive);

  /// No description provided for @dieBoxSentenceReadyBits.
  ///
  /// In de, this message translates to:
  /// **'{name} · {bits} · bereit'**
  String dieBoxSentenceReadyBits(String name, String bits);
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
      <String>['de', 'en', 'fr', 'it'].contains(locale.languageCode);

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
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
