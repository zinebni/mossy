# Mossy 🌿

> *"Look closer. Discover more."*

Mossy is an AI-powered nature exploration companion designed to inspire people to discover, understand, and collect the botanical world around them. Blending real-world plant identification with an evolving virtual sanctuary, generative AI lore, exploration challenges, and an adorable mascot, Mossy turns everyday nature walks into a cozy, interactive discovery game.

---

## 🌟 Core Features

- 🔍 **AI Plant Identification**: Snap a picture using the camera or select from your gallery. Powered by Pl@ntNet API with confidence scoring and multiple botanical candidates.
- 📖 **Generative Botanical Wisdom**: Educational descriptions, folklore, fun facts, and field observation tips powered by Google Gemini.
- 🐾 **Living Mascot Companion ("Mossy")**: A tiny custom-painted moss creature with dynamic expressions (happy, curious, searching, excited, sleepy) and interactive animations that reacts to your exploration progress.
- 📓 **Nature Discovery Journal**: Personal collection of all saved finds with high-resolution photos, scientific classification, notes, and favorite filters.
- 🗺️ **OpenStreetMap Exploration Map**: Interactive map pins showing exactly where you discovered each plant on your nature walks.
- 🎒 **Adventure Challenges & Quests**: Daily challenges and seasonal botanical quests that award explorer points (e.g. *"Find a 5-petaled flower"*, *"Spot climbing ivy"*).
- 🌺 **Virtual Garden Sanctuary**: A blossoming sanctuary rendered with custom canvas graphics that levels up (stages from *Moss Patch* to *Botanical Wonderland*) as you explore.
- 🏆 **Explorer Progression & Badges**: Earn experience points, unlock achievement badges, and level up from Novice Seedling to Master Botanist.
- 🌐 **Bilingual Localization**: Built-in support for English and French with real-time in-app switching and persistent preferences.
- 📴 **Offline-First Resilience**: Full fallback demo mode ensures every feature, challenge, and identification works seamlessly even without API keys or an active network connection.

---

## 🎨 Visual Identity & Design System

Mossy follows an organic, warm pastel aesthetic designed to feel inviting and calm:

| Color Token | Hex Code | Purpose |
|---|---|---|
| **Sage Green** | `#829B79` | Primary brand color, actions, badges |
| **Cream** | `#F7F3E9` | Warm background tone |
| **Mint Green** | `#D9E8CF` | Secondary accents, highlights, success |
| **Lavender** | `#E9DDF5` | Soft cards, secondary badges |
| **Peach** | `#F5D6C5` | Warm cards, warm accents |
| **Butter Yellow** | `#EFCF79` | Points, stars, achievements |
| **Dark Green** | `#2D3B2D` | High-contrast readable typography |

- **Typography**: Friendly, organic styling utilizing Google Fonts (`Fraunces` editorial serif for headings, `Nunito` rounded sans-serif for body).
- **Cards & Radii**: Smooth 18–24px organic rounded corners with subtle drop shadows.
- **Custom Canvas Graphics**: Mascot, garden landscapes, and onboarding illustrations are drawn directly in Flutter via `CustomPainter` to eliminate heavy raster dependencies.

---

## 🏗️ Architecture & Tech Stack

```
lib/
├── core/
│   ├── constants/       # Global constants, default values
│   ├── router/          # GoRouter with StatefulShellRoute (5-tab navigation)
│   ├── theme/           # Design system tokens (colors, typography, spacing, shadows)
│   └── widgets/         # Reusable design system components (MossyCard, MossyButton)
├── features/
│   ├── adventures/      # Daily challenges & quest list
│   ├── collection/      # Journal grid, list, search, filters & details
│   ├── discovery_map/   # FlutterMap OpenStreetMap integration
│   ├── explore/         # Camera/gallery picker, loading states, candidate rankings
│   ├── garden/          # Custom-painted virtual garden sanctuary
│   ├── home/            # Main dashboard, daily wisdom, quick actions
│   ├── onboarding/      # 4-step interactive feature tour
│   ├── profile/         # Level progress, stats, achievement badges
│   ├── settings/        # Preferences, language switcher, demo mode toggle
│   └── splash/          # Animated entrance with unfurling vine & mascot
├── l10n/                # Internationalization ARB files (en, fr)
├── services/            # Service layer with dual Supabase + Demo fallback implementations
└── shared/
    ├── models/          # Immutable domain models with JSON serialization
    ├── providers/       # Riverpod state notifiers & providers
    └── widgets/mascot/  # Mascot engine, expressions, accessories & painters
```

- **Framework**: Flutter 3.x (Dart 3.5+)
- **State Management**: Flutter Riverpod (`StateNotifierProvider`, `AsyncValue`)
- **Routing**: `go_router` with persistent bottom navigation tabs
- **Backend & Database**: Supabase (PostgreSQL, Row Level Security, Auth, Storage)
- **Edge Functions**: TypeScript functions on Deno for Pl@ntNet & Gemini integration
- **Maps**: `flutter_map` with OpenStreetMap raster tiles
- **Animations**: `flutter_animate` + custom Flutter `AnimationController`s

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.5.0`)
- Android Studio / Xcode (for device builds)
- Git

### 2. Clone & Install Dependencies
```bash
git clone https://github.com/your-username/mossy.git
cd mossy
flutter pub get
```

### 3. Environment Configuration
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Configure your API keys in `.env` (optional; demo mode will automatically engage if left unconfigured):
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
PLANTNET_API_KEY=your-plantnet-api-key
GEMINI_API_KEY=your-gemini-api-key
```

### 4. Run the App
- **Android**:
  ```bash
  flutter run -d android
  ```
- **iOS Simulator**:
  ```bash
  flutter run -d ios
  ```
- **Web / Chrome Preview**:
  ```bash
  flutter run -d chrome
  ```

---

## 🗄️ Backend Setup (Supabase)

The project includes ready-to-run database migrations and edge functions in the `supabase/` folder:

1. **Apply Database Migrations**:
   Run the SQL scripts in `supabase/migrations/` sequentially or deploy via Supabase CLI:
   ```bash
   supabase db push
   ```
2. **Deploy Edge Functions**:
   ```bash
   supabase functions deploy identify-plant
   supabase functions deploy generate-discovery-content
   supabase functions deploy generate-missions
   supabase functions deploy verify-mission
   supabase functions deploy award-points
   ```
3. **Configure Storage Buckets**:
   - `discovery-photos` (authenticated write, public read)
   - `avatars` (user-isolated upload)

---

## 📱 Testing & GitHub Actions CI/CD

### Run Local Tests & Analyzer
```bash
# Static analysis (zero issues)
flutter analyze

# Full test suite (16 unit and widget tests)
flutter test
```

### Automated iOS IPA & Android APK Generation
A complete GitHub Actions workflow is provided in [build_artifacts.yml](.github/workflows/build_artifacts.yml).
Whenever you push to `main` or trigger **Run workflow** manually under the **Actions** tab on GitHub:
1. All static analyzer checks and unit tests run on Ubuntu.
2. An **Android Release APK** (`app-release.apk`) is built and uploaded as a build artifact.
3. An **iOS Release IPA** (`mossy-release.ipa`) is built on macOS, packaged into a standard `Payload/` archive, and uploaded as an installable artifact.

#### Testing on Your Physical iPhone
Download `mossy-release.ipa` from the GitHub Actions run summary and install it directly via:
- [Sideloadly](https://sideloadly.io/) (Windows/macOS)
- [AltStore](https://altstore.io/)
- [TrollStore](https://github.com/opa334/TrollStore) (iOS 14.0–17.0)

---

## 📄 License
MIT License. Explore and enjoy nature responsibly!
