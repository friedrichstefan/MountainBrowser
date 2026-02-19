# 🔧 API Setup Guide für AppleTV Browser

## Übersicht der APIs

Deine App verwendet drei APIs für bestmögliche Suchergebnisse:

| API | Zweck | Kostenlose Limits | 
|-----|-------|------------------|
| **Bing Search** | Web-Suche | 1,000 Anfragen/Monat |
| **YouTube Data API** | Video-Suche | 10,000 Einheiten/Tag (~1,000 Videos) |
| **Google Custom Search** | Bilder-Suche | 100 Anfragen/Tag |

## 1. Bing Search API (Web-Suche)

### Setup:
1. Gehe zu https://portal.azure.com
2. Klicke "Create a resource" → Suche "Bing Search v7"
3. Wähle **Free Tier (F1)** - kostenlos!
4. Erstelle die Ressource
5. Gehe zu "Keys and Endpoint" → Kopiere **Key 1**

### Kosten:
- ✅ **1,000 Anfragen/Monat kostenlos**
- Danach: $2 pro 1,000 zusätzliche Anfragen

---

## 2. YouTube Data API (Video-Suche)

### Setup:
1. Gehe zu https://console.developers.google.com
2. Erstelle neues Projekt (falls nicht vorhanden)
3. Aktiviere **YouTube Data API v3**
4. Erstelle Credentials → **API Key**
5. Kopiere den API Key

### Kosten:
- ✅ **10,000 Einheiten/Tag kostenlos** (ca. 1,000 Video-Suchen)
- Danach: $0.05 pro 100 Einheiten

---

## 3. Google Custom Search API (Bilder-Suche)

### Setup (etwas komplizierter):

#### A) API Key erstellen:
1. Gehe zu https://console.developers.google.com
2. Aktiviere **Custom Search API**
3. Erstelle Credentials → **API Key**

#### B) Custom Search Engine erstellen:
1. Gehe zu https://cse.google.com/cse/
2. Klicke "Add" → "Search the entire web"
3. Gib eine dummy URL ein (z.B. `example.com`)
4. Erstelle die Suchmaschine
5. **Wichtig:** Aktiviere "Image search" in Settings
6. **Wichtig:** Aktiviere "Search the entire web"
7. Kopiere die **Search Engine ID** (cx Parameter)

### Kosten:
- ✅ **100 Anfragen/Tag kostenlos**
- Danach: $5 pro 1,000 Anfragen

---

## 4. Environment Variables setzen

In deiner Netlify-Konsole (oder `.env` für lokale Entwicklung):

```bash
BING_API_KEY=dein_bing_api_key_hier
YOUTUBE_API_KEY=dein_youtube_api_key_hier  
GOOGLE_SEARCH_API_KEY=dein_google_api_key_hier
GOOGLE_SEARCH_ENGINE_ID=deine_search_engine_id_hier
```

---

## 💰 Gesamtkosten

**Für eine normale AppleTV Browser App:**
- **Monat 1-12:** Komplett kostenlos
- **Bei 10,000+ aktiven Nutzern:** ~$20-50/Monat

**Warum es sich lohnt:**
- ✅ Hochqualitative Suchergebnisse
- ✅ Offizielle YouTube-Integration  
- ✅ Sichere, skalierbare Architektur
- ✅ App Store konform
- ✅ Keine API Keys im Client-Code

---

## 🚨 Troubleshooting

**YouTube API 403 Error:**
- API nicht aktiviert → Google Console → YouTube Data API aktivieren
- Falscher Key → Neuen API Key erstellen

**Google Custom Search keine Bilder:**
- Image Search nicht aktiviert → CSE Settings → Image search ON
- "Search entire web" nicht aktiviert → Settings aktivieren

**Bing 401 Error:**
- Falscher Key → Azure Portal → neue Keys generieren
- Region falsch → Endpoint URL prüfen

**Rate Limits erreicht:**
- Normale Meldung in der App → "Limit erreicht, versuche es später"
- Automatischer Reset am nächsten Tag/Monat