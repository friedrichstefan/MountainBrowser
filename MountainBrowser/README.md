# Mountain Browser

Ein moderner, nativer Webbrowser fuer **Apple TV (tvOS)**, entwickelt mit **SwiftUI** und **SwiftData**.

Mountain Browser bringt vollwertiges Webbrowsing auf den grossen Bildschirm -- optimiert fuer die Siri Remote und das tvOS-Oekosystem.

![Platform](https://img.shields.io/badge/Platform-tvOS%2017.0+-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.10-orange?logo=swift)
![Framework](https://img.shields.io/badge/Framework-SwiftUI-blue)
![License](https://img.shields.io/badge/License-Proprietary-lightgrey)

---

## Inhaltsverzeichnis

- [Features](#features)
- [Design](#design)
- [Architektur](#architektur)
- [Technische Details](#technische-details)
- [Erste Schritte](#erste-schritte)
- [API-Konfiguration](#api-konfiguration)
- [Bedienung (Siri Remote)](#bedienung-siri-remote)
- [Lokalisierung](#lokalisierung)
- [Projektstruktur](#projektstruktur)
- [Rechtliches](#rechtliches)

---

## Features

### Integrierte Websuche
- Websuche ueber **DuckDuckGo** (HTML + Lite-Fallback) -- keine API-Keys erforderlich
- Ergebnisse in separaten Kategorien: **Web**, **Bilder** und **Videos**
- Optionale **Google Custom Search API** und **YouTube Data API v3** fuer erweiterte Ergebnisse
- Suchverlauf mit schnellem Zugriff auf fruehere Suchanfragen
- Direkte URL-Eingabe und Google-Suche

### Reader Mode
- Webseiten werden als nativer, lesbarer Text dargestellt
- Optimiert fuer die Darstellung auf dem Fernseher aus mehreren Metern Entfernung
- Link-Navigation direkt im Reader View

### Wikipedia-Integration
- Automatische Wikipedia-Infoboxen zu Suchanfragen (Knowledge Panel)
- Kollabierbares Panel mit Bild, Zusammenfassung und Infofeldern
- Mehrstufige Detailansicht: kompakte Vorschau bis hin zum vollstaendigen Artikel
- Unterstuetzung fuer **6 Sprachen**: Deutsch, Englisch, Franzoesisch, Spanisch, Italienisch + automatische Systemerkennung

### Tab-Management
- Bis zu **8 gleichzeitige Tabs** mit vollstaendigem Lifecycle-Management
- Safari-aehnliche Tab-Uebersicht im Grid-Layout
- Drei Tab-Typen: Suche, Webseite und leere Startseite
- Echtzeit-Statusanzeige (aktiv, Zeitstempel, Ergebnis-Zusammenfassung)
- Suchergebnisse werden pro Tab persistent gespeichert (als JSON in SwiftData)
- Lazy Caching: JSON-Ergebnisse werden erst bei Zugriff decodiert

### Zwei Navigationsmodi
- **Scroll View** -- Standard-Navigation mit Fokus und Scroll (empfohlen)
- **Cursor View** -- Maus-Cursor-Navigation ueber das Siri Remote Touchpad
- Umschalten jederzeit ueber Einstellungen oder per Play/Pause-Taste im WebView

### Video-Wiedergabe
- Direkte Wiedergabe von **MP4/M3U8/MOV**-Videos ueber den nativen `AVPlayer`
- **YouTube**- und **Vimeo**-Videos werden im eingebetteten WebView mit Autoplay abgespielt
- Automatische Erkennung des Video-Typs (direkt vs. webbasiert)

### Lesezeichen & Verlauf
- Lesezeichen mit Ordner-Unterstuetzung (Cascade-Delete)
- Automatischer Browserverlauf mit Zeitstempel
- Persistenz ueber SwiftData (lokal)

### Einstellungen
- JavaScript ein/aus
- Cookie-Verwaltung
- Pop-up-Blocker
- Navigationsleiste ein/aus
- Wikipedia-Sprache waehlen
- Ansichtsmodus wechseln (Scroll / Cursor)
- Alle Einstellungen zuruecksetzen
- Ueber-die-App-Ansicht mit Feature-Uebersicht und technischen Details

---

## Design

Mountain Browser verwendet ein eigenes **glasmorphes Design-System** (`TVOSDesign`), speziell fuer tvOS entwickelt:

- **Dunkles Farbschema** mit subtilen Transparenz- und Blur-Effekten
- **Animierte Hintergrund-Orbs** mit radialen Farbverlaeufen
- **Fokus-Effekte** mit Glow, Scale, Spring-Animationen und farbigen Akzent-Raendern
- **Zwei Fokus-Modi**: `TVOSFocusModifier` fuer kleine Controls, `TVOSCardGlowModifier` fuer grosse Kacheln
- **Glassmorphic Cards** mit `UnevenRoundedRectangle`-Support fuer gruppierte Einstellungszeilen
- Alle UI-Elemente sind fuer die **Siri Remote** und den Fokus-Mechanismus von tvOS optimiert
- Konsistentes **Spacing-**, **Typography-** und **CornerRadius-System**
- Eigener `TransparentButtonStyle`, der den Standard-tvOS-Fokus-Highlight unterdrueckt

---

## Architektur

```
MountainBrowserApp
    |
    +-- MainBrowserView (Primaere View)
    |       |
    |       +-- EnhancedSearchBar        (Sucheingabe + Vorschlaege)
    |       +-- SearchTabBar             (Web / Bilder / Videos / Info)
    |       +-- SearchResultGridView     (Web-Ergebnisse)
    |       +-- ImageResultGridView      (Bild-Ergebnisse)
    |       +-- VideoResultGridView      (Video-Ergebnisse)
    |       +-- WikipediaInfoPanel       (Knowledge Panel)
    |       +-- SimpleBrowserTabView     (Tab-Uebersicht)
    |
    +-- TabManager (@StateObject)
    |       |
    |       +-- BrowserTab (SwiftData @Model, bis zu 8)
    |       +-- SearchService            (DuckDuckGo + YouTube + Wikipedia)
    |       +-- DirectAPISearchService   (Fallback-Suche)
    |
    +-- WebView-Modus
    |       |
    |       +-- ScrollModeWebView        (Fokus-basierte Navigation)
    |       +-- CursorModeWebView        (Zeiger-basierte Navigation)
    |
    +-- Persistenz (SwiftData)
            |
            +-- Bookmark / BookmarkFolder
            +-- HistoryEntry
            +-- BrowserTab (inkl. JSON-Ergebnis-Cache)
```

### Kernkonzepte

| Konzept | Umsetzung |
|---|---|
| UI-Framework | SwiftUI mit UIKit-Bruecke fuer WKWebView |
| Datenpersistenz | SwiftData (Bookmarks, History, Tabs) |
| Concurrency | Swift async/await, `actor` fuer WikipediaService |
| Suchdienst | DuckDuckGo HTML -> DuckDuckGo Lite -> Fehlerbehandlung |
| Caching | JSON-codierte Ergebnisse in SwiftData mit transienten Cache-Properties |
| Design-System | Eigenes `TVOSDesign`-Modul mit ueber 100 Design-Tokens |
| Eingabemodi | Scroll (Focus Engine) und Cursor (Touch-Tracking) |

---

## Technische Details

### Mindestanforderungen
- **tvOS 17.0** oder hoeher
- **Xcode 15.0** oder hoeher
- **Swift 5.10**
- Apple TV 4K (empfohlen)

### Verwendete Frameworks

| Framework | Zweck |
|---|---|
| SwiftUI | Deklarative UI |
| SwiftData | Datenpersistenz |
| WebKit (WKWebView) | Webseiten-Rendering |
| AVKit | Video-Wiedergabe |
| Combine | Reaktive Datenstroeme |
| os.log | System-Logging |

### Backend (optional)

Mountain Browser kann mit einem optionalen **Netlify-Backend** betrieben werden, das als API-Proxy dient:

- Serverless Functions (Node.js) proxyen Suchanfragen
- API-Keys bleiben serverseitig und werden nicht im Client exponiert
- Automatisches Deployment ueber GitHub-Integration
- Endpunkt: `/api/search?query=...&type=web|images|videos|wikipedia|all`

---

## Erste Schritte

```bash
# Repository klonen
git clone https://github.com/friedrichstefan/AppleTVBrowser.git

# Projekt in Xcode oeffnen
open MountainBrowser.xcodeproj

# Build-Target: Apple TV Simulator oder Apple TV (Geraet)
# Schema: MountainBrowser
```

> **Hinweis:** Die App funktioniert ohne Backend und ohne API-Keys. DuckDuckGo-Suche und Wikipedia sind sofort verfuegbar.

---

## API-Konfiguration

Fuer erweiterte Such-Ergebnisse koennen optional folgende APIs konfiguriert werden:

| API | Zweck | Erforderlich? |
|---|---|---|
| DuckDuckGo | Websuche | Nein (integriert) |
| Wikipedia REST API | Knowledge Panels | Nein (integriert) |
| Google Custom Search | Erweiterte Websuche | Optional |
| YouTube Data API v3 | Videosuche | Optional |

Die Konfiguration erfolgt ueber `APIConfiguration.swift` bzw. ueber Umgebungsvariablen im Netlify-Backend.

---

## Bedienung (Siri Remote)

### Scroll-Modus (Standard)

| Aktion | Eingabe |
|---|---|
| Navigation | Touchpad wischen |
| Auswaehlen | Touchpad klicken |
| Zurueck | Menu-Taste |
| Seite scrollen | Touchpad hoch/runter |
| Modus wechseln | Play/Pause-Taste |

### Cursor-Modus

| Aktion | Eingabe |
|---|---|
| Cursor bewegen | Touchpad wischen |
| Klick | Touchpad klicken |
| Zurueck | Menu-Taste |
| Scrollen | Touchpad-Rand (oben/unten) |
| Modus wechseln | Play/Pause-Taste |

---

## Lokalisierung

Mountain Browser unterstuetzt **5 Sprachen** vollstaendig:

| Sprache | Code | Status |
|---|---|---|
| Deutsch | `de` | Vollstaendig |
| Englisch | `en` | Vollstaendig |
| Franzoesisch | `fr` | Vollstaendig |
| Spanisch | `es` | Vollstaendig |
| Italienisch | `it` | Vollstaendig |

Die Lokalisierung erfolgt ueber:
- `Localizable.xcstrings` (Xcode String Catalog)
- `LocalizedStrings.swift` (zentrales `L10n`-Enum mit `String(localized:)`)
- Pluralisierte Strings fuer Ergebnisanzeigen
- Automatische Systemsprach-Erkennung fuer Wikipedia

---

## Projektstruktur

```
AppleTVBrowser/
|-- MountainBrowser/
|   |-- MountainBrowserApp.swift          # App-Einstiegspunkt
|   |-- MainBrowserView.swift             # Hauptansicht
|   |-- TabManager.swift                  # Tab-Verwaltung
|   |-- BrowserTab.swift                  # Tab-Datenmodell (SwiftData)
|   |-- SearchService.swift               # Such-Implementierung
|   |-- SearchViewModel.swift             # Such-UI-State
|   |-- DirectAPISearchService.swift      # Fallback-Suche
|   |-- ScrollModeWebView.swift           # Scroll-Navigationsmodus
|   |-- CursorModeWebView.swift           # Cursor-Navigationsmodus
|   |-- TVOSDesign.swift                  # Design-System
|   |-- TVOSComponents.swift              # Wiederverwendbare UI-Komponenten
|   |-- WikipediaInfo.swift               # Wikipedia-Service & Modelle
|   |-- WikipediaInfoPanel.swift          # Wikipedia-UI
|   |-- Bookmark.swift                    # Lesezeichen-Modell
|   |-- BookmarkFolder.swift              # Ordner-Modell
|   |-- HistoryEntry.swift                # Verlauf-Modell
|   |-- BrowserPreferences.swift          # Einstellungen-Enums
|   |-- LocalizedStrings.swift            # Lokalisierungs-Strings
|   |-- Localizable.xcstrings             # String-Katalog
|   |-- APIConfiguration.swift            # API-Schluessel
|   |-- Info.plist                        # App-Konfiguration
|   +-- Assets.xcassets/                  # App-Icons & Assets
|
|-- MountainBrowserTests/                 # Unit-Tests
|-- MountainBrowserUITests/               # UI-Tests
|-- backend/                              # Netlify-Backend (optional)
|   |-- netlify-functions/search.js       # Such-API-Proxy
|   |-- netlify.toml                      # Netlify-Konfiguration
|   +-- package.json                      # Node.js-Abhaengigkeiten
+-- MountainBrowser.xcodeproj             # Xcode-Projekt
```

---

## Rechtliches

**Mountain Browser** ist proprietaere Software. Alle Rechte vorbehalten.

- Die Nutzung, Vervielfaeltigung oder Weitergabe des Quellcodes ist ohne ausdrueckliche Genehmigung nicht gestattet.
- DuckDuckGo, Google, YouTube, Wikipedia und Apple sind eingetragene Marken ihrer jeweiligen Inhaber.
- Diese App steht in keiner Verbindung zu den genannten Diensten oder deren Betreibern.
