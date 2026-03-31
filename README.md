# 🏔️ Mountain Browser

A modern, native web browser for **Apple TV (tvOS)**, built with **SwiftUI** and **SwiftData**.

Mountain Browser brings full-featured web browsing to the big screen 📺 -- optimized for the Siri Remote and the tvOS ecosystem.

![Platform](https://img.shields.io/badge/Platform-tvOS%2017.0+-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.10-orange?logo=swift)
![Framework](https://img.shields.io/badge/Framework-SwiftUI-blue)
![License](https://img.shields.io/badge/License-Proprietary-lightgrey)

---

## 📋 Table of Contents

- [Features](#-features)
- [Design](#-design)
- [Architecture](#-architecture)
- [Technical Details](#-technical-details)
- [Getting Started](#-getting-started)
- [API Configuration](#-api-configuration)
- [Controls (Siri Remote)](#-controls-siri-remote)
- [Localization](#-localization)
- [Project Structure](#-project-structure)
- [Legal](#-legal)

---

## ✨ Features

### 🔍 Integrated Web Search
- Web search via **DuckDuckGo** (HTML + Lite fallback) -- no API keys required
- Results in separate categories: **Web**, **Images**, and **Videos**
- Optional **Google Custom Search API** and **YouTube Data API v3** for enhanced results
- Search history with quick access to previous queries
- Direct URL entry and Google search

### 📖 Reader Mode
- Web pages rendered as native, readable text
- Optimized for TV display viewed from several meters away
- Link navigation directly within Reader View

### 🌐 Wikipedia Integration
- Automatic Wikipedia infoboxes for search queries (Knowledge Panel)
- Collapsible panel with image, summary, and info fields
- Multi-level detail view: from compact preview to full article
- Support for **6 languages**: 🇩🇪 German, 🇬🇧 English, 🇫🇷 French, 🇪🇸 Spanish, 🇮🇹 Italian + automatic system detection

### 🗂️ Tab Management
- Up to **8 simultaneous tabs** with full lifecycle management
- Safari-style tab overview in grid layout
- Three tab types: Search, Website, and empty Start Page
- Real-time status display (active, timestamp, result summary)
- Search results stored persistently per tab (as JSON in SwiftData)
- Lazy caching: JSON results are decoded only on access

### 🖱️ Two Navigation Modes
- **Scroll View** -- Standard navigation with focus and scroll (recommended)
- **Cursor View** -- Mouse cursor navigation via the Siri Remote touchpad
- Switch at any time via Settings or the Play/Pause button in WebView

### 🎬 Video Playback
- Direct playback of **MP4/M3U8/MOV** videos via the native `AVPlayer`
- **YouTube** and **Vimeo** videos play in an embedded WebView with autoplay
- Automatic video type detection (direct vs. web-based)

### 🔖 Bookmarks & History
- Bookmarks with folder support (cascade delete)
- Automatic browser history with timestamps
- Persistence via SwiftData (local)

### ⚙️ Settings
- JavaScript on/off
- Cookie management 🍪
- Pop-up blocker 🚫
- Navigation bar on/off
- Wikipedia language selection
- View mode switching (Scroll / Cursor)
- Reset all settings
- About screen with feature overview and technical details

---

## 🎨 Design

Mountain Browser uses a custom **glassmorphic design system** (`TVOSDesign`), developed specifically for tvOS:

- 🌑 **Dark color scheme** with subtle transparency and blur effects
- 🔮 **Animated background orbs** with radial color gradients
- ✨ **Focus effects** with glow, scale, spring animations, and colored accent borders
- 🎯 **Two focus modes**: `TVOSFocusModifier` for small controls, `TVOSCardGlowModifier` for large tiles
- 💎 **Glassmorphic cards** with `UnevenRoundedRectangle` support for grouped settings rows
- 📱 All UI elements are optimized for the **Siri Remote** and the tvOS focus engine
- 📐 Consistent **spacing**, **typography**, and **corner radius** system
- 🎛️ Custom `TransparentButtonStyle` that suppresses the default tvOS focus highlight

---

## 🏗️ Architecture

```
MountainBrowserApp
    |
    +-- MainBrowserView (Primary View)
    |       |
    |       +-- EnhancedSearchBar        (Search input + suggestions)
    |       +-- SearchTabBar             (Web / Images / Videos / Info)
    |       +-- SearchResultGridView     (Web results)
    |       +-- ImageResultGridView      (Image results)
    |       +-- VideoResultGridView      (Video results)
    |       +-- WikipediaInfoPanel       (Knowledge Panel)
    |       +-- SimpleBrowserTabView     (Tab overview)
    |
    +-- TabManager (@StateObject)
    |       |
    |       +-- BrowserTab (SwiftData @Model, up to 8)
    |       +-- SearchService            (DuckDuckGo + YouTube + Wikipedia)
    |       +-- DirectAPISearchService   (Fallback search)
    |
    +-- WebView Mode
    |       |
    |       +-- ScrollModeWebView        (Focus-based navigation)
    |       +-- CursorModeWebView        (Pointer-based navigation)
    |
    +-- Persistence (SwiftData)
            |
            +-- Bookmark / BookmarkFolder
            +-- HistoryEntry
            +-- BrowserTab (incl. JSON result cache)
```

### 🧩 Core Concepts

| Concept | Implementation |
|---|---|
| 🖼️ UI Framework | SwiftUI with UIKit bridge for WKWebView |
| 💾 Data Persistence | SwiftData (Bookmarks, History, Tabs) |
| ⚡ Concurrency | Swift async/await, `actor` for WikipediaService |
| 🔎 Search Service | DuckDuckGo HTML → DuckDuckGo Lite → Error handling |
| 🗄️ Caching | JSON-encoded results in SwiftData with transient cache properties |
| 🎨 Design System | Custom `TVOSDesign` module with over 100 design tokens |
| 🕹️ Input Modes | Scroll (Focus Engine) and Cursor (Touch Tracking) |

---

## 🔧 Technical Details

### 📋 Minimum Requirements
- **tvOS 17.0** or later
- **Xcode 15.0** or later
- **Swift 5.10**
- Apple TV 4K (recommended)

### 📦 Frameworks Used

| Framework | Purpose |
|---|---|
| SwiftUI | 🖼️ Declarative UI |
| SwiftData | 💾 Data persistence |
| WebKit (WKWebView) | 🌐 Web page rendering |
| AVKit | 🎬 Video playback |
| Combine | 🔄 Reactive data streams |
| os.log | 📝 System logging |

### ☁️ Backend (Optional)

Mountain Browser can be operated with an optional **Netlify backend** that serves as an API proxy:

- 🔧 Serverless Functions (Node.js) proxy search requests
- 🔐 API keys remain server-side and are not exposed in the client
- 🚀 Automatic deployment via GitHub integration
- 📡 Endpoint: `/api/search?query=...&type=web|images|videos|wikipedia|all`

---

## 🚀 Getting Started

```bash
# Clone the repository
git clone https://github.com/friedrichstefan/AppleTVBrowser.git

# Open the project in Xcode
open MountainBrowser.xcodeproj

# Build target: Apple TV Simulator or Apple TV (Device)
# Scheme: MountainBrowser
```

> 💡 **Note:** The app works without a backend and without API keys. DuckDuckGo search and Wikipedia are available out of the box.

---

## 🔑 API Configuration

For enhanced search results, the following APIs can optionally be configured:

| API | Purpose | Required? |
|---|---|---|
| 🦆 DuckDuckGo | Web search | No (built-in) |
| 📚 Wikipedia REST API | Knowledge Panels | No (built-in) |
| 🔍 Google Custom Search | Enhanced web search | Optional |
| ▶️ YouTube Data API v3 | Video search | Optional |

Configuration is done via `APIConfiguration.swift` or through environment variables in the Netlify backend.

---

## 🎮 Controls (Siri Remote)

### 📜 Scroll Mode (Default)

| Action | Input |
|---|---|
| 👆 Navigate | Swipe touchpad |
| ✅ Select | Click touchpad |
| ◀️ Back | Menu button |
| 📜 Scroll page | Swipe touchpad up/down |
| 🔄 Switch mode | Play/Pause button |

### 🖱️ Cursor Mode

| Action | Input |
|---|---|
| 👆 Move cursor | Swipe touchpad |
| ✅ Click | Click touchpad |
| ◀️ Back | Menu button |
| 📜 Scroll | Touchpad edge (top/bottom) |
| 🔄 Switch mode | Play/Pause button |

---

## 🌍 Localization

Mountain Browser fully supports **5 languages**:

| Language | Code | Status |
|---|---|---|
| 🇩🇪 German | `de` | ✅ Complete |
| 🇬🇧 English | `en` | ✅ Complete |
| 🇫🇷 French | `fr` | ✅ Complete |
| 🇪🇸 Spanish | `es` | ✅ Complete |
| 🇮🇹 Italian | `it` | ✅ Complete |

Localization is implemented via:
- 📄 `Localizable.xcstrings` (Xcode String Catalog)
- 🧩 `LocalizedStrings.swift` (centralized `L10n` enum with `String(localized:)`)
- 🔢 Pluralized strings for result displays
- 🌐 Automatic system language detection for Wikipedia

---

## 📁 Project Structure

```
AppleTVBrowser/
|-- MountainBrowser/
|   |-- MountainBrowserApp.swift          # 🚀 App entry point
|   |-- MainBrowserView.swift             # 🖼️ Main view
|   |-- TabManager.swift                  # 🗂️ Tab management
|   |-- BrowserTab.swift                  # 📋 Tab data model (SwiftData)
|   |-- SearchService.swift               # 🔍 Search implementation
|   |-- SearchViewModel.swift             # 🧠 Search UI state
|   |-- DirectAPISearchService.swift      # 🔄 Fallback search
|   |-- ScrollModeWebView.swift           # 📜 Scroll navigation mode
|   |-- CursorModeWebView.swift           # 🖱️ Cursor navigation mode
|   |-- TVOSDesign.swift                  # 🎨 Design system
|   |-- TVOSComponents.swift              # 🧩 Reusable UI components
|   |-- WikipediaInfo.swift               # 🌐 Wikipedia service & models
|   |-- WikipediaInfoPanel.swift          # 📚 Wikipedia UI
|   |-- Bookmark.swift                    # 🔖 Bookmark model
|   |-- BookmarkFolder.swift              # 📂 Folder model
|   |-- HistoryEntry.swift                # 🕐 History model
|   |-- BrowserPreferences.swift          # ⚙️ Settings enums
|   |-- LocalizedStrings.swift            # 🌍 Localization strings
|   |-- Localizable.xcstrings             # 📝 String catalog
|   |-- APIConfiguration.swift            # 🔑 API keys
|   |-- Info.plist                        # ℹ️ App configuration
|   +-- Assets.xcassets/                  # 🖼️ App icons & assets
|
|-- MountainBrowserTests/                 # 🧪 Unit tests
|-- MountainBrowserUITests/               # 🧪 UI tests
|-- backend/                              # ☁️ Netlify backend (optional)
|   |-- netlify-functions/search.js       # 📡 Search API proxy
|   |-- netlify.toml                      # ⚙️ Netlify configuration
|   +-- package.json                      # 📦 Node.js dependencies
+-- MountainBrowser.xcodeproj             # 🛠️ Xcode project
```

---

## ⚖️ Legal

**Mountain Browser** is proprietary software. All rights reserved.

- 🚫 Use, reproduction, or distribution of the source code is not permitted without explicit authorization.
- ™️ DuckDuckGo, Google, YouTube, Wikipedia, and Apple are registered trademarks of their respective owners.
- ℹ️ This app is not affiliated with any of the mentioned services or their operators.
