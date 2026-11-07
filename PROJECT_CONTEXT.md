# Mossy — Project Context & Technical Decisions

## 1. Product Vision & Experience Design

### Core Philosophy
Mossy is deliberately designed **not** to feel like a sterile administrative dashboard or a generic conversational AI chatbot. Instead, it is structured as a **warm, tactile, and playful nature discovery game**.

The core gameplay and learning loop:
$$\text{Photograph} \longrightarrow \text{Identify} \longrightarrow \text{Understand} \longrightarrow \text{Collect} \longrightarrow \text{Explore} \longrightarrow \text{Grow Sanctuary}$$

### The Mascot: "Mossy"
The mascot is an integral emotional anchor of the experience rather than a decorative sticker. 
- Drawn in real-time via `MascotPainter` (custom Flutter `CustomPainter`), eliminating raster asset bloat and allowing programmatic reactions.
- Distinct expressions: `happy`, `curious`, `searching`, `excited`, `sleepy`, `celebrating`.
- Accessories: `magnifyingGlass`, `backpack`, `wateringCan`, `flowerCrown`, `leafUmbrella`.
- Organic procedural animations: rhythmic breathing (squash & stretch), idle wobble, natural blink cycles, and tactile squish-bounce on user tap.

---

## 2. Technical Architecture & Engineering Decisions

### Dual-Mode Architecture (Connected + Demo Fallback)
To ensure the app is immediately usable for review, local development, offline excursions, and CI runs without mandatory cloud setup:
- Every service contract (`DiscoveryService`, `MissionService`, `GardenService`, `PointsService`, `AiContentService`, `PlantIdentificationService`) is implemented twice:
  1. `Supabase*Service`: Connected mode communicating with Supabase PostgreSQL and Edge Functions.
  2. `Demo*Service`: In-memory realistic offline fallback providing 10 varied nature quests, 12 botanical achievements, 10-level garden state, and mocked plant identification with botanical candidate rankings.
- If `.env` or network credentials are absent, the application gracefully initializes in demo mode without crashing or blocking the user.

### Botanical Identification & Safe AI Confidence
- Pl@ntNet API outputs raw similarity scores. These scores are **never** communicated as calibrated mathematical probabilities.
- Scores are categorized into clear human language:
  - $\ge 70\%$: *Very Likely Match*
  - $40\% - 69\%$: *Likely Match*
  - $20\% - 39\%$: *Possible Candidate*
  - $< 20\%$: *Uncertain*
- When confidence is low or ambiguous, candidate alternatives are ranked editorial-style so the explorer can visually verify leaf venation and petal geometry.

### State Management: Riverpod 2.0
- Replaced fragmented setState calls with structured `StateNotifierProvider` and `AsyncValue` wrappers.
- Global providers for data collections: `discoveriesProvider`, `missionsProvider`, `achievementsProvider`, `gardenStateProvider`, `userProfileProvider`, `localeProvider`.
- Automatic reactive UI updates when points are awarded or achievements unlock.

### Navigation: GoRouter with StatefulShellRoute
- Employs `StatefulShellRoute.indexedStack` preserving state across all 5 primary bottom navigation branches:
  1. `/home` — Dashboard, personalized greeting, daily challenge, recent finds.
  2. `/explore` — Camera viewfinder, gallery picker, identification loading state, results.
  3. `/collection` — Journal with search, category filters, favorite toggles, and detail views.
  4. `/adventures` — Daily quests, general missions, difficulty filters.
  5. `/garden` — Canvas-rendered virtual sanctuary, plant growth, level unlocks.
- Auxiliary routes: `/profile`, `/settings`, `/map`, `/onboarding`, `/splash`.

---

## 3. Database Schema & Backend Contracts

### Supabase Migrations (`supabase/migrations/`)
1. `create_profiles.sql` — Explorer accounts, username, avatar, level, total points.
2. `create_discoveries.sql` — User plant entries, photos, GPS coords, confidence score, notes.
3. `create_species_cache.sql` — Botanical classification cache (family, genus, species).
4. `create_missions.sql` — Challenge definitions, categories, difficulty, reward points, criteria.
5. `create_user_missions.sql` — User challenge progress, completion timestamps.
6. `create_achievements.sql` — Milestone badges and criteria.
7. `create_user_achievements.sql` — Unlocked achievements per user.
8. `create_garden_states.sql` — User sanctuary level, unlocked decoration items.
9. `create_points_ledger.sql` — Immutable append-only transaction ledger for point awards.
10. `seed_data.sql` — Default missions and achievement definitions.
11. `create_functions.sql` — RLS helper functions and points calculation triggers.
12. `storage_setup.sql` — Storage buckets for discovery photos and user avatars.

### Supabase Edge Functions (`supabase/functions/`)
- `identify-plant/index.ts` — Relays uploaded image to Pl@ntNet API; ranks candidate matches.
- `generate-discovery-content/index.ts` — Calls Gemini API to generate structured educational lore, fun facts, and safety notices.
- `generate-missions/index.ts` — Generates contextual seasonal challenges based on the user's region and flora.
- `verify-mission/index.ts` — Validates whether a submitted discovery fulfills the challenge criteria.
- `award-points/index.ts` — Atomically records points in the ledger and checks garden/achievement progression.

---

## 4. Current Milestone Status & Future Expansion

### Completed Milestones
- [x] Full Design System (colors, typography, cards, buttons, scaffolds).
- [x] CustomPainter Mascot Engine with expressions and accessories.
- [x] All 11 navigation screens fully built and connected.
- [x] Native iOS (`Info.plist`) and Android (`AndroidManifest.xml`) permissions.
- [x] Riverpod persistent localization infrastructure (English & French).
- [x] Full automated test suite (16 passing unit and widget tests).
- [x] Static code analysis passing with 0 errors and 0 warnings.
- [x] GitHub Actions CI/CD workflow producing installable `.ipa` and `.apk` artifacts.
- [x] Comprehensive documentation (`README.md` and `PROJECT_CONTEXT.md`).

### Future Roadmap (Post-Release)
1. **Fauna & Fungi Expansion**: Expand Pl@ntNet integration to support mushroom identification (e.g. via Mushroom Observer API) and urban wildlife spotting without rewriting core collection models.
2. **Social Sanctuary Visits**: Allow friends to visit each other's virtual gardens and leave pollination gifts.
3. **Augmented Reality Viewfinder**: Project Mossy in AR next to real-world plants during outdoor exploration.

