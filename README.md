# PANTAS Mobile App

PANTAS is a Flutter mobile application for library patrons. It connects to the PANTAS Laravel mobile API and gives students a focused way to sign in, browse the catalog, manage borrowed books, submit borrow-cart requests, reserve rooms, view notifications, manage their profile, and send feedback.

The app is designed to work with the Laravel API under:

```text
/api/mobile
```

## Features

- Student login with bearer-token authentication
- Student and faculty registration screen
- Profile loading from the authenticated API
- Catalog search, filters, new arrivals, and book details
- Borrow cart with real selected book IDs
- Current borrowed books and borrow history
- Borrow limits and server-side checkout validation messages
- Room list, availability checks, reservation submission, details, and pending cancellation
- Generated notifications from the backend
- Feedback submission
- Secure token storage

## Tech Stack

- Flutter
- Dart
- GoRouter
- HTTP package
- Flutter Secure Storage
- Intl
- Laravel mobile API backend

## Project Structure

```text
lib/
  app.dart
  main.dart
  core/
    config/
    network/
    router/
    storage/
    theme/
  features/
    auth/
    borrowed_books/
    borrow_cart/
    catalog/
    feedback/
    home/
    notifications/
    profile/
    rooms/
    settings/
  models/
  services/
  shared/
```

## Requirements

Install these before running the app:

- Flutter SDK
- Dart SDK through Flutter
- Android Studio
- Android SDK
- A running PANTAS Laravel backend, local or via ngrok

Check your environment:

```powershell
flutter doctor -v
```

## Getting Started

Clone the repository and install dependencies:

```powershell
git clone https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
cd YOUR_REPOSITORY
flutter pub get
```

Run the app:

```powershell
flutter run
```

Run checks:

```powershell
dart format lib test
flutter analyze
flutter test --reporter expanded
```

## API Configuration

API URLs are configured in:

```text
lib/core/config/api_config.dart
```

Common base URLs:

```text
Local browser or Windows testing:
http://127.0.0.1:8000/api/mobile

Android emulator:
http://10.0.2.2:8000/api/mobile

Physical phone or external testing:
https://your-ngrok-url.ngrok-free.dev/api/mobile

Production:
https://your-domain.com/api/mobile
```

Update `ApiConfig.baseUrl` based on your testing target.

Example:

```dart
static const String baseUrl = androidEmulator;
```

For ngrok testing, update the ngrok URL first:

```dart
static const String ngrok = 'https://your-ngrok-url.ngrok-free.dev/api/mobile';
static const String baseUrl = ngrok;
```

## Backend Setup Notes

The Flutter app expects the Laravel backend to expose mobile routes under:

```text
/api/mobile
```

Useful local backend commands:

```powershell
cd C:\dev\InternshipArea51\Pantas\pantas-v2.5
php artisan serve --host=0.0.0.0 --port=8000
```

For ngrok:

```powershell
ngrok http 8000
```

Then copy the generated HTTPS URL into `api_config.dart`.

## Test Account

For local development, the seeded test account is:

```text
Email: mobile.student@test.local
Password: password
```

## Android Studio

Open the Flutter project root:

```text
C:\dev\InternshipArea51\Pantas\Pantas-UI
```

Do not open only the nested `android/` folder unless you specifically want to inspect Android platform files.

If Android Studio opens the wrong nested platform project, close the project and reopen the Flutter root folder that contains `pubspec.yaml`.

## Useful Commands

Clean and refresh dependencies:

```powershell
flutter clean
flutter pub get
```

Run on an Android emulator:

```powershell
flutter run
```

Build a debug APK:

```powershell
flutter build apk --debug
```

Build a release APK:

```powershell
flutter build apk --release
```

## API Integration Coverage

Implemented mobile API integrations include:

- `POST /login`
- `POST /logout`
- `GET /me`
- `GET /profile`
- `POST /change-password`
- `GET /catalog/search`
- `GET /catalog/books/{book}`
- `GET /catalog/filters`
- `GET /catalog/new-arrivals`
- `GET /borrowed-books`
- `GET /borrow-history`
- `GET /borrow-limits`
- `POST /borrow-cart/submit`
- `GET /rooms`
- `GET /rooms/availability`
- `POST /rooms/reservations`
- `GET /rooms/reservations`
- `GET /rooms/reservations/{reservation}`
- `DELETE /rooms/reservations/{reservation}`
- `GET /notifications`
- `POST /feedback`

## Security Notes

- The app uses bearer tokens stored with `flutter_secure_storage`.
- Borrow-cart checkout sends only `book_ids`.
- The app does not send `student_id`; the backend resolves the student from the authenticated token.
- Protected endpoints require a valid bearer token.

## Git Workflow

Before committing:

```powershell
dart format lib test
flutter analyze
flutter test --reporter expanded
git status
```

Create a commit:

```powershell
git add .
git commit -m "Describe your change"
```

Push:

```powershell
git push origin main
```

## License

This project is for PANTAS library system development. Add a formal license file if the project will be distributed publicly.
