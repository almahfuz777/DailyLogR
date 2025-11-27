# 📓 DailyLogR

**DailyLogR** is a clean, lightweight journaling app built with Flutter, designed around the idea of writing one meaningful note per day.
The app focuses on simplicity, mood tracking, and structured entries, making it easy to reflect on your daily experiences.

# 🚀 Features
- One entry per day: Clean, structured journaling with enforced date uniqueness.
- Title + Note: Add a quick headline or jump straight into writing.
- Mood adjective selector: Summarize your day with a single descriptive word.
- 5-star rating system: Quantify how the day felt at a glance.
- Date restrictions: Only today or the previous two days can be logged; no backlog dumping.
- Local storage with Hive: Offline-first, fast, reliable, and optimized for future cloud syncing.
- Modern UI: Clean Material 3 interface with responsive sheets and polished interactions.

# 🧱 Tech Stack

- Flutter (Material 3)
- Dart
- Hive (local persistence)
- Centralized service layer (HiveService)
- Firebase-ready data model (`toJson`, `fromJson`, stable IDs)

# 🔮 Roadmap
- [x] Entry creation & editing
- [x] Local Storage with Hive
- [x] Mood adjective selector
- [x] 5-star rating system
- [x] Prevent future, old and duplicate date entries 
- [x] Initial release with core journaling features
- [ ] Firebase Authentication
- [ ] Cloud sync (Hive ⇆ Firestore)
- [ ] Reminders & notifications
- [ ] Mood analytics dashboard
- [ ] Weekly/monthly trends, insights & streaks
- [ ] Journaling heatmap calendar view
- [ ] Export / backup system
- [ ] Themes & personalization

# 🛠️ Getting Started
1. Clone the repo
2. Install dependencies
3. Run the app

```bash
git clone https://github.com/almahfuz777/DailyLogR.git
cd dailylogr
flutter pub get
flutter run
```

# 🤝 Contributing
Contributions are welcome! Please open issues or submit pull requests for bug fixes, features, or improvements.
Please follow the existing code style and include tests where applicable.
