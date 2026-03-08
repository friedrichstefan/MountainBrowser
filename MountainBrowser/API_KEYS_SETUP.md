# 🔧 API Keys Setup für DirectAPISearchService

## ⚠️ WICHTIGER HINWEIS
Diese Lösung ist nur für **Entwicklung und Tests** gedacht!
**NIEMALS für App Store-Releases verwenden** - API-Keys wären sichtbar!

## 🚀 Schnelle Test-Konfiguration

### 1. API-Keys besorgen (kostenlos)

#### DuckDuckGo Search API (für Web-Suche) ✅ KOSTENLOS
- Keine Konfiguration nötig!
- Funktioniert ohne API-Key
- Liefert immer Ergebnisse

#### YouTube Data API (für Videos)
1. Gehe zu: https://console.developers.google.com
2. Aktiviere "YouTube Data API v3"
3. Erstelle API Key
4. Kopiere **API Key**

#### Google Custom Search (für Bilder UND Web-Suche)
1. **API-Key erstellen:**
   - Gehe zu: https://console.developers.google.com
   - Aktiviere "Custom Search API"
   - Erstelle API Key
   
2. **Search Engine erstellen:**
   - Gehe zu: https://programmablesearchengine.google.com (früher cse.google.com)
   - Erstelle neue Suchmaschine:
   - "Search the entire web" aktivieren
   - "Image search" aktivieren
   - "Safe Search" aktivieren
   
3. Kopiere **Search Engine ID** (cx Parameter)

### 2. Keys in Code eintragen

Öffne `AppleTVBrowser/DirectAPISearchService.swift` und ersetze:

```swift
private struct APIKeys {
    // DuckDuckGo Search (kostenlos, kein API-Key erforderlich)
    // Bing Search API (wird durch DuckDuckGo ersetzt)
    static let bingAPIKey = "YOUR_BING_API_KEY_HERE"
    
    // YouTube Data API (https://console.developers.google.com)
    static let youtubeAPIKey = "HIER_DEINEN_YOUTUBE_KEY_EINTRAGEN"
    
    // Google Custom Search API (https://console.developers.google.com)
    static let googleSearchAPIKey = "HIER_DEINEN_GOOGLE_KEY_EINTRAGEN"
    static let googleSearchEngineId = "HIER_DEINE_SEARCH_ENGINE_ID_EINTRAGEN"
}
```

### 3. App testen

1. Baue die App neu
2. Führe eine Suche aus (z.B. "Apple TV")
3. Überprüfe alle Tabs: Web, Bilder, Videos, Info

## 🔍 Troubleshooting

### "API-Key nicht konfiguriert"
- Keys in DirectAPISearchService.swift noch nicht ersetzt
- Keys müssen echte Werte enthalten, nicht "YOUR_..._HERE"

### 401/403 Fehler
- **Bing:** Falscher Subscription Key oder Region
- **YouTube:** API nicht aktiviert oder falscher Key
- **Google:** Falscher API Key oder Search Engine ID

### Keine Bilder gefunden
- Google Custom Search: "Image search" aktivieren
- "Search the entire web" aktivieren

### Rate Limits
- **Bing:** 1,000 Anfragen/Monat (kostenlos)
- **YouTube:** 10,000 Einheiten/Tag (kostenlos)
- **Google:** 100 Anfragen/Tag (kostenlos)

## ✅ Test-Checklist

Nach dem Setup sollten funktionieren:
- [ ] Web-Suche (Bing) - zeigt Websites
- [ ] Bilder-Suche (Google) - zeigt Thumbnails
- [ ] Video-Suche (YouTube) - zeigt Videos
- [ ] Wikipedia-Info (funktioniert immer ohne Keys)

## 🔄 Nächste Schritte

Für **Produktion**:
1. Backend deployen (siehe `backend/` Ordner)
2. API-Keys als Umgebungsvariablen setzen
3. SearchViewModel auf SearchService zurück ändern
4. backendBaseURL in APIConfiguration.swift setzen

**Dann ist die App App Store-ready!**