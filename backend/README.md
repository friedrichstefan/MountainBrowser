# AppleTV Browser Backend

Dieses Backend fungiert als Proxy für die AppleTV Browser App und ermöglicht sichere API-Aufrufe zu verschiedenen Suchanbietern, ohne API-Schlüssel im Client zu exponieren.

## 🏗️ Architektur

```
┌─────────────────┐    HTTPS     ┌──────────────────┐    API Calls    ┌─────────────────┐
│   AppleTV App   │ ──────────► │  Netlify Backend │ ──────────────► │  External APIs  │
│     (Swift)     │              │   (Node.js)      │                 │  Bing, Wikipedia │
└─────────────────┘              └──────────────────┘                 └─────────────────┘
```

### Vorteile dieser Architektur:
- **Sicherheit**: API-Schlüssel bleiben im Backend geschützt
- **Caching**: Netlify CDN reduziert Latenz
- **Skalierung**: Serverless Functions skalieren automatisch
- **CORS**: Kein Cross-Origin Problem
- **Monitoring**: Zentrale Überwachung aller API-Calls

## 🚀 Deployment

### 1. Vorbereitung

```bash
# In das backend-Verzeichnis wechseln
cd backend

# Dependencies installieren
npm install
```

### 2. Umgebungsvariablen

Erstelle eine `.env` Datei im `backend/` Verzeichnis:

```env
# Bing Search API (Required)
BING_API_KEY=your_bing_api_key_here
```

### 3. Lokale Entwicklung

```bash
# Netlify Dev Server starten
npm run dev

# Backend läuft auf http://localhost:8888
# Functions sind verfügbar unter /.netlify/functions/search
```

### 4. Production Deployment

#### Option A: Netlify CLI (Empfohlen)

```bash
# Netlify CLI installieren (falls noch nicht installiert)
npm install -g netlify-cli

# Bei Netlify anmelden
netlify login

# Site erstellen und verknüpfen
netlify init

# Umgebungsvariablen setzen
netlify env:set BING_API_KEY "your_bing_api_key_here"

# Deployen
npm run deploy
```

#### Option B: GitHub Integration

1. Repository zu GitHub pushen
2. Auf [Netlify](https://app.netlify.com) anmelden
3. "New site from Git" wählen
4. Repository auswählen
5. Build-Einstellungen:
   - **Build command**: `echo "No build needed"`
   - **Publish directory**: `.`
   - **Functions directory**: `netlify-functions`
6. Environment Variables hinzufügen:
   - `BING_API_KEY`: Dein Bing Search API Key
7. Deploy ausführen

### 5. DNS/Domain Setup

Nach erfolgreichem Deployment:

1. Notiere dir die Netlify-URL (z.B. `https://your-app-name.netlify.app`)
2. Aktualisiere `APIConfiguration.swift` in der iOS App:
   ```swift
   static let backendBaseURL = "https://your-app-name.netlify.app"
   ```

## 🔧 API Endpunkte

### Base URL
```
https://your-app-name.netlify.app
```

### Endpunkte

#### 1. Web Search
```
GET /api/search?query={searchTerm}&type=web&count=10
```

#### 2. Image Search
```
GET /api/search?query={searchTerm}&type=images&count=10
```

#### 3. Video Search
```
GET /api/search?query={searchTerm}&type=videos&count=10
```

#### 4. Wikipedia Search
```
GET /api/search?query={searchTerm}&type=wikipedia
```

#### 5. Combined Search (Alle Typen)
```
GET /api/search?query={searchTerm}&type=all&count=10
```

### Response Format

#### Web/Images/Videos:
```json
{
  "query": "Apple",
  "type": "web",
  "results": [
    {
      "title": "Apple",
      "url": "https://www.apple.com",
      "description": "Official Apple website",
      "displayUrl": "www.apple.com",
      "contentType": "web"
    }
  ],
  "totalEstimatedMatches": 1000000
}
```

#### Wikipedia:
```json
{
  "query": "Apple",
  "type": "wikipedia", 
  "wikipedia": {
    "title": "Apple Inc.",
    "summary": "Apple Inc. is an American multinational...",
    "articleURL": "https://en.wikipedia.org/wiki/Apple_Inc.",
    "imageURL": "https://upload.wikimedia.org/...",
    "coordinates": {
      "lat": 37.3349,
      "lon": -122.0090
    }
  }
}
```

#### Combined (All):
```json
{
  "query": "Apple",
  "type": "all",
  "web": { "results": [...], "totalEstimatedMatches": 1000000 },
  "images": { "results": [...] },
  "videos": { "results": [...] },
  "wikipedia": { "title": "...", "summary": "..." }
}
```

## 🔑 API Keys Setup

### Bing Search API

1. Gehe zu [Azure Portal](https://portal.azure.com)
2. Erstelle eine "Bing Search v7" Resource
3. Notiere den API Key aus dem "Keys and Endpoint" Bereich
4. Setze die Umgebungsvariable `BING_API_KEY`

### Rate Limits

- Bing Search API: 1000 calls/month (Free Tier)
- Netlify Functions: 125,000 requests/month (Free Tier)

## 🛠️ Monitoring & Debugging

### Logs anzeigen
```bash
# Netlify Logs (letzten Deployment)
netlify logs

# Live Logs (während Entwicklung)
netlify dev
```

### Function Logs
- Im Netlify Dashboard unter "Functions"
- Zeigt Requests, Response Times, Errors

### Testing

```bash
# Backend lokal testen
curl "http://localhost:8888/api/search?query=test&type=web"

# Production testen
curl "https://your-app-name.netlify.app/api/search?query=test&type=web"
```

## 🚨 Troubleshooting

### Häufige Probleme:

1. **"API key not configured"**
   - Prüfe Umgebungsvariablen in Netlify Dashboard
   - Stelle sicher, dass `BING_API_KEY` gesetzt ist

2. **CORS Errors**
   - Prüfe `netlify.toml` CORS Headers
   - Stelle sicher, dass Requests von der iOS App kommen

3. **Function Timeout**
   - Netlify Functions haben 10s Timeout (Free) / 15s (Pro)
   - Optimiere API Calls bei Bedarf

4. **502 Bad Gateway**
   - Function Error - prüfe Logs
   - Meist JSON Parsing oder API Key Probleme

### Debug Checklist:

- [ ] Umgebungsvariablen korrekt gesetzt?
- [ ] Backend URL in iOS App aktualisiert?
- [ ] API Keys gültig und nicht abgelaufen?
- [ ] Bing API Quota nicht erreicht?
- [ ] Netlify Functions Quota nicht erreicht?

## 📊 Performance

- **Cold Start**: ~1-3 Sekunden (erste Anfrage)
- **Warm Start**: ~100-300ms
- **Cache**: Netlify CDN für statische Inhalte
- **Timeout**: 10 Sekunden pro Function Call

## 🔒 Sicherheit

- API Keys sind server-seitig geschützt
- HTTPS only (Netlify erzwingt SSL)
- CORS richtig konfiguriert
- Keine sensitive Daten im Client-Code
- Rate Limiting durch Bing API

## 📈 Skalierung

Das Backend skaliert automatisch:
- **Netlify Functions**: Serverless, auto-scaling
- **CDN**: Globale Distribution
- **Caching**: Automatische Optimierung

Bei hohem Traffic erwäge:
- Netlify Pro Plan (höhere Limits)
- Bing Search API Upgrade
- Redis Caching für häufige Queries

## 🔧 Wartung

### Regelmäßige Aufgaben:
- API Key Rotation (alle 6-12 Monate)
- Dependency Updates (`npm audit`)
- Performance Monitoring
- Error Rate Überwachung

### Updates deployen:
```bash
git push origin main  # Auto-deployment via GitHub
# oder
npm run deploy       # Manual deployment