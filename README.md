# DailyLogR

> A focused, offline-first journaling app built with Flutter — one meaningful entry per day, always in sync.

---

## Overview

**DailyLogR** is a personal journaling app that enforces a single, intentional entry per calendar day. Rather than an open-ended notebook, it structures each entry around a title, a freeform note, a mood adjective, and a 1–5 star rating — giving you a consistent reflection habit and data you can actually analyze over time.

The app works fully offline from first launch. When a user signs in, entries sync to Firebase Firestore automatically. Anonymous entries written before sign-in are migrated with the user's consent.

---

## Features

| Category | Details |
|---|---|
| **Core Journaling** | One entry per day (enforced by date key), title + long-form note, mood adjective, 1–5 star rating |
| **Edit Window** | Entries are editable for today and up to 3 days back — no retroactive journaling |
| **Streak Tracking** | Consecutive day streak with at-risk detection and smart recovery hints |
| **Dashboard** | Personalized greeting, swipeable day carousel, 90-day activity calendar strip |
| **Analytics** | Rating trend chart, mood distribution pie, activity heatmap — filterable by week, month, or all time |
| **Offline-First** | Hive local storage; all writes succeed offline and sync when connectivity returns |
| **Cloud Sync** | Firestore sync on login and on network reconnect; pull-on-login, push-on-write |
| **Authentication** | Anonymous (no sign-in required), Email/Password, Google Sign-In |
| **Account Migration** | Dialog to merge or discard anonymous entries when signing in for the first time |
| **Trash & Recovery** | Soft-delete with 30-day auto-purge; restore from Trash screen |
| **Notifications** | Daily reminders at 8:30 PM & 11:00 PM; closing-window urgency alerts when the edit window is about to expire |
| **Settings** | Toggle notifications, change/set password, connect Google account |

---

## Tech Stack

| Concern | Technology |
|---|---|
| Framework | Flutter (Dart) · Material 3 |
| State Management | Riverpod 2 (`Notifier`, `Provider`, `StateProvider`) |
| Local Storage | Hive (typed boxes, keyed by `YYYY-MM-DD` date string) |
| Cloud Database | Cloud Firestore — path `users/{uid}/entries/{dayKey}` |
| Authentication | Firebase Auth — Email/Password + Google Sign-In |
| Notifications | `flutter_local_notifications` + `timezone` |
| Charts | `fl_chart` |
| Connectivity | `connectivity_plus` — auto-sync on reconnect |

---

## Architecture

DailyLogR follows a strict layered architecture:

```
Widgets / Screens
      │  (read providers, emit callbacks)
      ▼
   Providers          ← Riverpod NotifierProviders; orchestrate state, call services
      │
      ▼
   Services           ← Pure Dart; Hive I/O, Firestore, Firebase Auth, Notifications
      │
      ▼
   Models             ← Plain Hive-typed data class (JournalEntry)
```

**Key principle**: Screens are dumb renderers. No business logic lives in widget files. All mutations go through a provider, which delegates to a service.

---

## Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── models/
│   └── journal_entry.dart         # Hive data model — single source of truth
├── providers/
│   ├── auth_lifecycle_provider.dart
│   ├── journal_provider.dart
│   ├── streak_provider.dart
│   └── sync_provider.dart
├── services/
│   ├── firebase_auth_service.dart
│   ├── hive_service.dart
│   ├── notification_service.dart
│   ├── streak_service.dart
│   └── sync_service.dart
├── screens/
│   ├── main_screen.dart
│   ├── dashboard_screen.dart
│   ├── entries_screen.dart
│   ├── analytics_screen.dart
│   ├── settings_screen.dart
│   └── trash_screen.dart
├── utils/
│   ├── app_screens.dart           # AppScreen enum — drives navigation
│   ├── date_helper.dart           # DayKey utility
│   └── analytics_helper.dart
└── widgets/
    ├── analytics/
    │   ├── activity_heatmap.dart
    │   ├── mood_distribution_chart.dart
    │   ├── rating_trend_chart.dart
    │   └── summary_cards.dart
    ├── home_drawer.dart
    ├── auth_sheet.dart
    ├── dashboard_entry_carousel.dart
    └── ......
```

---

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.8.1
- A Firebase project with Authentication and Firestore enabled
- `FlutterFire CLI` for generating `firebase_options.dart`

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/almahfuz777/DailyLogR.git
cd DailyLogR

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase (if not already done)
flutterfire configure

# 4. Run the app
flutter run
```


### Regenerate Hive Adapters

Run this after any change to `journal_entry.dart`:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Roadmap

- [x] Core journaling (title, note, mood, rating)
- [x] Offline-first local storage with Hive
- [x] Firebase Authentication (Email/Password + Google Sign-In)
- [x] Cloud sync with Firestore (offline-resilient)
- [x] Anonymous → account entry migration
- [x] 3-day edit window enforcement
- [x] Soft delete + Trash screen with 30-day auto-purge
- [x] Multi-select bulk delete in Entries screen
- [x] Dashboard entry carousel with depth/scale animations
- [x] 90-day activity calendar strip
- [x] Streak tracking with at-risk detection and recovery hints
- [x] Analytics screen (rating trend, mood distribution, activity heatmap)
- [x] Settings: notifications toggle, password management, Google account linking
- [x] Daily reminder notifications + closing-window urgency alerts
- [x] Search entries
- [x] Custom moods / mood icons
- [x] Text formatting (numbered list and bulleted list)
- [x] Selectable background color for entry card
- [x] Undo / Redo support
- [x] Auto-save draft system
- [ ] Themes & personalization (dark mode, accent colors)
- [x] Export / backup system (PDF, CSV, JSON)
- [x] Import restore system
- [ ] “On This Day” memory recaps
- [x] Home Screen Widget support
- [ ] Photo attachments in entries
- [ ] Drawing / sketch canvas support
- [ ] Voice notes/ Audio transcription
- [ ] Smart writing prompts
- [ ] AI mood detection from entries
- [ ] AI-generated journal insights
- [ ] Streak milestone celebrations
- [ ] Shared journals / collaboration mode
- [ ] iOS full support & App Store release
---

## Contributing

Contributions are welcome. Please open an issue first to discuss what you'd like to change.

- Follow the existing architecture: no business logic in widgets or screens.
- Run `dart analyze` and `dart format .` before submitting a PR.
- Hive model changes: append-only new `@HiveField` indices; always re-run `build_runner`.

---

## License

MIT © [Al Mahfuz](https://github.com/almahfuz777)
