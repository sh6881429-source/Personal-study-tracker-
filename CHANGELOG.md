# Changelog

All notable changes to **PrepTracker By Yash** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [1.3.0] - 2026-07-10

### Added
- Home Dashboard presentation screen (`HomeScreen`) showing today's real progress and stats from Supabase
- Aggregated dashboard data model (`DashboardData`) grouping goals, streaks, logs, and upcoming countdowns
- `HomeRepository` interface and implementation (`HomeRepositoryImpl`) running parallel optimized queries using `Future.wait` and Supabase RPC functions
- `HomeController` (`homeControllerProvider`) managing loading, error, data, and pulling refresh states using AsyncValue
- Premium UI dashboard widgets:
  - `DashboardHeader` displaying timezone greetings, username, profile picture with caching, and active streak badges
  - `StudyProgressCard` displaying daily logged hours/minutes, progress percentages, and smooth animated progress bars
  - `DashboardMetricsGrid` showing completed chapters ratios, revision targets, daily gym log statuses, and bookmark counters
  - `ExamCountdownCard` showing upcoming milestone exams and remaining days counts
  - `QuickActionsGrid` displaying navigation shortcut tiles matching Neo Brutalism style buttons
  - `RecentActivityWidget` listing study logs, saved bookmark titles, and PDF uploads
  - `DashboardShimmerLoading` providing skeletal visual loading placeholders for cards and headers
- Welcoming onboarding empty state screen for new accounts with quick actions and subject builders

---

## [1.2.0] - 2026-07-10

### Added
- Complete SQL DDL database migration schema script (`supabase_complete_schema.sql`) for all 12 modules
- Row Level Security (RLS) policies configured for all 12 tables enforcing strict authenticated user ownership
- 11 immutable model classes with JSON serialization, value equality, and copyWith support for subjects, chapters, study sessions, bookmarks, PDFs, gym attendance, goals, settings, exams, AI chat history, and achievements
- 9 domain repository interfaces defining contract signatures for database querying and CRUD operations
- Dynamic PostgreSQL store functions for analytical metrics: study duration calculation, streak calculations, revision counters, and gym attendance summaries
- Supabase storage buckets config ('profile-images' and 'study-pdfs') alongside ownership policies
- Dashboard query index keys optimization for user IDs, study dates, and subject IDs

---

## [1.1.0] - 2026-07-10

### Added
- Complete Google-only OAuth login workflow integrated with Supabase Auth
- Auth state management notifier using Riverpod (`authProvider`) mapping session changes in real-time
- Route Guard redirects on GoRouter protecting all screens and enforcing login state checks
- Splash screen checking active persisted sessions and automatically restoring or redirecting users
- Premium Neo Brutalism Login screen with a single Google sign-in action button and loading state support
- Profile database table SQL schema, including Row Level Security (RLS) policies and automatic trigger for `updated_at`
- `AuthRepository` & `ProfileRepository` interfaces along with their implementation classes
- `AuthService` and `ProfileService` layers executing native GoogleSignIn / Supabase operations
- Automatic user database profile synchronization (upsert) on initial Google login

---

## [1.0.0] - 2026-07-10

### Added

- Project initialization with Flutter 3.44.6 and Dart 3.12.2
- Feature-first architecture setup following SOLID principles and repository pattern
- Material 3 + Neo Brutalism theme system with full light/dark mode support
- GoRouter navigation with bottom navigation shell route
- Riverpod state management scaffolding across all feature modules
- Supabase service scaffolding (auth, database, storage)
- Gemini AI service scaffolding for Ask Yash Bot
- Reusable widget library:
  - `NeoButton` — Neo Brutalism styled button with press animations
  - `NeoCard` — Bordered card with offset shadow
  - `NeoDialog` — Styled dialog with brutal borders
  - `LoadingWidget` — Skeleton and spinner loading states
  - `EmptyStateWidget` — Illustrated empty state placeholder
  - `ErrorWidget` — Styled error display with retry action
  - `NeoSnackbar` — Themed snackbar notifications
- Responsive layout system with breakpoints for mobile, tablet, and desktop
- 10 feature module placeholders:
  - Home Dashboard
  - Study Timer
  - Syllabus Tracker
  - Gym Tracker
  - Bookmark Manager
  - PDF Library
  - Analytics Dashboard
  - Ask Yash Bot (AI)
  - Profile
  - Settings
- Environment configuration with `.env` support
- Project documentation (README, CONTRIBUTING, LICENSE, TODO)

---

[Unreleased]: https://github.com/yourusername/preptracker/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/preptracker/releases/tag/v1.0.0
