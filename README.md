<p align="center">
  <img src="assets/images/logo.png" alt="PrepTracker Logo" width="120" />
</p>

<h1 align="center">📚 PrepTracker By Yash</h1>

<p align="center">
  <strong>Your all-in-one personal productivity companion for study & gym tracking.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.44.6-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.12.2-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Supabase-Backend-3FCF8E?logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/Gemini_AI-Powered-8E75B2?logo=google&logoColor=white" alt="Gemini AI" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
  <img src="https://img.shields.io/badge/Design-Neo_Brutalism-000000" alt="Neo Brutalism" />
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-screenshots">Screenshots</a> •
  <a href="#-tech-stack">Tech Stack</a> •
  <a href="#-architecture">Architecture</a> •
  <a href="#-getting-started">Getting Started</a> •
  <a href="#-contributing">Contributing</a> •
  <a href="#-license">License</a>
</p>

---

## ✨ Features

| Feature | Description |
|---|---|
| 🏠 **Home Dashboard** | At-a-glance view of today's plan, stats, streaks, and quick actions |
| ⏱️ **Study Timer** | Pomodoro-style timer with subject tagging, session history, and focus stats |
| 📖 **Syllabus Tracker** | Track subjects, chapters, and completion progress with visual indicators |
| 🏋️ **Gym Tracker** | Log workouts, exercises, sets, reps, and weight with workout templates |
| 🔖 **Bookmark Manager** | Save and organize important study resources, links, and references |
| 📄 **PDF Library** | Store, view, and manage study PDFs and documents in one place |
| 📊 **Analytics** | Comprehensive dashboards for study hours, gym progress, and trends |
| 🤖 **Ask Yash Bot** | AI-powered study assistant powered by Google Gemini |
| 👤 **Profile** | Personalized user profile with stats, achievements, and preferences |
| ⚙️ **Settings** | Theme toggle (light/dark), notifications, data management, and more |

---

## 📸 Screenshots

> 🚧 Screenshots coming soon — the app is currently in active development.

<!-- 
<p align="center">
  <img src="screenshots/home.png" width="200" />
  <img src="screenshots/study_timer.png" width="200" />
  <img src="screenshots/gym_tracker.png" width="200" />
  <img src="screenshots/analytics.png" width="200" />
</p>
-->

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.44.6 |
| **Language** | Dart 3.12.2 |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Backend / Auth** | Supabase (Google OAuth) |
| **AI** | Google Gemini API (Free Tier) |
| **Design System** | Material 3 + Neo Brutalism |
| **Platforms** | Web, Android, iOS |

---

## 🏗️ Architecture

PrepTracker follows a **feature-first architecture** with **SOLID principles** and the **repository pattern** for clean separation of concerns.

```
┌─────────────────────────────────────────────────────┐
│                    Presentation                      │
│              (Screens, Widgets, Pages)               │
├─────────────────────────────────────────────────────┤
│                   State Management                   │
│              (Riverpod Providers/Notifiers)           │
├─────────────────────────────────────────────────────┤
│                     Domain                           │
│                (Models, Entities)                     │
├─────────────────────────────────────────────────────┤
│                    Repository                        │
│           (Data Sources, API Clients)                │
├─────────────────────────────────────────────────────┤
│                    Services                          │
│          (Supabase, Gemini, Storage)                 │
└─────────────────────────────────────────────────────┘
```

---

## 📁 Folder Structure

```
lib/
├── app.dart                        # App entry widget
├── main.dart                       # Bootstrap & initialization
├── core/
│   ├── constants/                  # App-wide constants
│   ├── router/                     # GoRouter configuration
│   ├── services/                   # Supabase, Gemini, Storage services
│   ├── theme/                      # Material 3 + Neo Brutalism theme
│   └── utils/                      # Helpers, extensions, formatters
├── shared/
│   └── widgets/                    # Reusable UI components
│       ├── neo_button.dart
│       ├── neo_card.dart
│       ├── neo_dialog.dart
│       ├── loading_widget.dart
│       ├── empty_state_widget.dart
│       ├── error_widget.dart
│       └── neo_snackbar.dart
└── features/
    ├── home/                       # Dashboard feature
    ├── study_timer/                # Study timer feature
    ├── syllabus_tracker/           # Syllabus tracking feature
    ├── gym_tracker/                # Gym workout tracking feature
    ├── bookmarks/                  # Bookmark manager feature
    ├── pdf_library/                # PDF library feature
    ├── analytics/                  # Analytics dashboard feature
    ├── ask_yash/                   # AI chatbot feature
    ├── profile/                    # User profile feature
    └── settings/                   # App settings feature
```

Each feature module follows:
```
feature_name/
├── data/                           # Repositories & data sources
├── domain/                         # Models & entities
├── presentation/
│   ├── screens/                    # Full-page screens
│   ├── widgets/                    # Feature-specific widgets
│   └── providers/                  # Riverpod providers
└── feature_name.dart               # Barrel file
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>= 3.44.6`
- [Dart SDK](https://dart.dev/get-dart) `>= 3.12.2`
- A [Supabase](https://supabase.com/) project (free tier works)
- A [Google Gemini API Key](https://aistudio.google.com/apikey) (free tier)
- Git

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/preptracker.git
cd preptracker

# 2. Create environment file
cp .env.example .env
# Edit .env with your API keys (see table below)

# 3. Install dependencies
flutter pub get

# 4. Run the app
flutter run
```

### Environment Variables

Create a `.env` file in the project root with the following:

| Variable | Description | Required |
|---|---|---|
| `SUPABASE_URL` | Your Supabase project URL | ✅ |
| `SUPABASE_ANON_KEY` | Your Supabase anonymous/public key | ✅ |
| `GEMINI_API_KEY` | Google Gemini API key for Ask Yash Bot | ✅ |

### Build Commands

```bash
# 🌐 Web
flutter build web --release

# 🤖 Android (APK)
flutter build apk --release

# 🤖 Android (App Bundle)
flutter build appbundle --release

# 🍎 iOS
flutter build ios --release
```

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Credits

- **Built with** ❤️ by [Yash](https://github.com/yourusername)
- **Design System** — Neo Brutalism + Material 3
- **Backend** — [Supabase](https://supabase.com/)
- **AI** — [Google Gemini](https://deepmind.google/technologies/gemini/)
- **Framework** — [Flutter](https://flutter.dev/)

---

<p align="center">
  <sub>Made with 📚 dedication and 🏋️ discipline.</sub>
</p>
