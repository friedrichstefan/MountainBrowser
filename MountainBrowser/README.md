# 🏔️ Mountain Browser

Ein moderner, nativer Webbrowser für **Apple TV (tvOS)**, entwickelt mit **SwiftUI** und **SwiftData**.

Mountain Browser bringt vollwertiges Webbrowsing auf den großen Bildschirm — optimiert für die Siri Remote und das tvOS-Ökosystem.

![Platform](https://img.shields.io/badge/Platform-tvOS%2017.0+-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.10-orange?logo=swift)
![Framework](https://img.shields.io/badge/Framework-SwiftUI-blue)
![License](https://img.shields.io/badge/License-Proprietary-lightgrey)

---

## ✨ Features

### 🔍 Integrierte Websuche
- Websuche mit Ergebnissen in separaten Kategorien: **Web**, **Bilder** und **Videos**
- Suchverlauf mit schnellem Zugriff auf frühere Suchanfragen
- Direkte URL-Eingabe und Google-Suche

### 📖 Reader Mode
- Webseiten werden als nativer, lesbarer Text dargestellt
- Optimiert für die Darstellung auf dem Fernseher
- Link-Navigation direkt im Reader View

### 📚 Wikipedia-Integration
- Integrierte Wikipedia-Infoboxen zu Suchanfragen
- Mehrstufige Detailansicht: kompakte Vorschau → vollständiger Artikel
- Unterstützung für **6 Sprachen**: Deutsch, Englisch, Französisch, Spanisch, Italienisch + automatische Systemerkennung

### 🗂️ Tab-Management
- Bis zu **8 gleichzeitige Tabs**
- Safari-ähnliche Tab-Übersicht im Grid-Layout
- Tabs für Suchen, Webseiten und leere Startseiten
- Echtzeit-Statusanzeige (aktiv, Zeitstempel, Ergebnis-Zusammenfassung)

### 🖥️ Zwei Navigationsmodi
- **Scroll View** — Standard-Navigation mit Fokus und Scroll (empfohlen)
- **Cursor View** — Maus-Cursor-Navigation über das Siri Remote Touchpad

### 🎬 Video-Wiedergabe
- Direkte Wiedergabe von MP4/M3U8/MOV-Videos über den nativen AVPlayer
- YouTube- und Vimeo-Videos werden im eingebetteten WebView abgespielt

### 🔖 Lesezeichen & Verlauf
- Lesezeichen mit Ordner-Unterstützung
- Automatischer Browserverlauf
- Persistenz über SwiftData (lokal)

### ⚙️ Einstellungen
- JavaScript ein/aus
- Cookie-Verwaltung
- Pop-up-Blocker
- Navigationsleiste ein/aus
- Wikipedia-Sprache wählen
- Ansichtsmodus wechseln
- Einstellungen zurücksetzen

---

## 🎨 Design

Mountain Browser verwendet ein **glasmorphes Design-System** (`TVOSDesign`), speziell für tvOS entwickelt:

- Dunkles Farbschema mit subtilen Transparenz-Effekten
- Animierte Hintergrund-Orbs mit Farbverläufen
- Fokus-Effekte mit Glow, Scale und Spring-Animationen
- Alle UI-Elemente sind für die Siri Remote und den Fokus-Mechanismus von tvOS optimiert
- Konsistentes Spacing- und Typography-System

---

## 🏗️ Architektur

