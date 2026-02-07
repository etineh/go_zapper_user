# GoZapper Flutter App

A Flutter customer app for the GoZapper delivery management platform, built with MVVM architecture and Provider for state management.

## 🎯 Project Overview

This is the customer-facing mobile application that connects to the GoZapper backend services. Users can register, log in, and manage their delivery requests.

## 🏗️ Architecture

The app follows **MVVM (Model-View-ViewModel)** architecture with clean architecture principles:

```
lib/
├── core/                      # Core utilities and configurations
│   ├── constants/            # App colors, routes, themes, constants
│   ├── di/                   # Dependency injection setup
│   ├── errors/               # Error handling (failures, exceptions)
│   ├── navigation/           # App routing configuration
│   ├── network/              # API client (Dio)
│   └── utils/                # Validators, snackbar utils
├── data/                      # Data layer
│   ├── datasources/          # Remote & local data sources
│   ├── models/               # Data models (DTOs)
│   └── repositories/         # Repository implementations
├── domain/                    # Domain layer
│   ├── entities/             # Business entities
│   └── repositories/         # Repository interfaces
├── presentation/              # Presentation layer
│   ├── providers/            # State management (ViewModels)
│   ├── screens/              # UI screens
│   └── widgets/              # Reusable widgets
└── main.dart                  # App entry point
```

## 📦 Dependencies

### State Management & Architecture
- **provider** - State management
- **dartz** - Functional programming (Either type)
- **equatable** - Value equality

### Networking & API
- **dio** - HTTP client
- **pretty_dio_logger** - API logging
- **flutter_secure_storage** - Secure token storage
- **shared_preferences** - Local data persistence

### UI Components
- **intl_phone_field** - Phone number input
- **country_code_picker** - Country selection
- **pin_code_fields** - OTP input
- **dropdown_button2** - Enhanced dropdowns

### Navigation & Utilities
- **go_router** - Declarative routing
- **logger** - Logging utility
- **intl** - Internationalization

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.5.4 or higher
- Android Studio / Xcode
- Backend services running (see `/Users/mac/Desktop/Server/gozapper`)

### Backend Setup

Make sure your GoZapper backend is running:

```bash
cd /Users/mac/Desktop/Server/gozapper
./start.sh
```

Verify services are running:
- Organization Service: http://localhost:5001/health
- Delivery Service: http://localhost:5003/health

### Install Dependencies

```bash
flutter pub get
```

### Run the App

```bash
# Run on emulator/device
flutter run

# Run in debug mode with hot reload
flutter run --debug

# Run in release mode (optimized)
flutter run --release
```

## 📱 Features Implemented

### ✅ Authentication Flow
- **Onboarding Screen** - Welcome screen with app introduction
- **Multi-step Sign Up**:
  - Phone number input with country code
  - Full name
  - Email address
  - Country & city selection
  - Terms & conditions agreement
  - Password creation
- **Login Screen** - Email/password authentication
- **OTP Verification** - Custom numeric keypad for OTP entry
- **Social Login Placeholders** - Email & Google (coming soon)

### ✅ Core Features
- **Home Screen** - Dashboard with user info
- **API Integration** - Connected to GoZapper backend
- **Secure Storage** - JWT tokens stored securely
- **Error Handling** - Comprehensive error management
- **Form Validation** - Client-side validation for all inputs

## 🎨 Design System

### Colors
- **Primary**: #00D968 (Green)
- **Background**: #F5F5F5
- **Text Primary**: #1E1E1E
- **Text Secondary**: #757575

### Typography
- Font Family: Inter (can be customized)
- Heading sizes: 24px, 18px, 16px, 14px

## 🔧 Configuration

### API Endpoints

Edit `lib/core/constants/app_constants.dart` to configure API endpoints:

```dart
static const String baseUrl = 'http://localhost:5001/api/v1';
static const String deliveryBaseUrl = 'http://localhost:5003/api/v1';
```

For Android Emulator, use:
```dart
static const String baseUrl = 'http://10.0.2.2:5001/api/v1';
```

For iOS Simulator or real device, use your machine's IP:
```dart
static const String baseUrl = 'http://192.168.x.x:5001/api/v1';
```

## 📝 API Integration

### Implemented Endpoints

1. **Register** - `POST /api/v1/organizations/register`
2. **Login** - `POST /api/v1/organizations/login`
3. **Verify OTP** - `POST /api/v1/organizations/verify-otp`
4. **Resend OTP** - `POST /api/v1/organizations/resend-otp`

### Adding New Endpoints

1. Add endpoint constant in `app_constants.dart`
2. Create/update data source in `data/datasources/`
3. Create/update repository in `data/repositories/`
4. Add method to provider in `presentation/providers/`
5. Call from UI screen

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage
```

## 🐛 Troubleshooting

### API Connection Issues

**Problem**: Cannot connect to backend
**Solution**:
- Check backend is running: `curl http://localhost:5001/health`
- Use correct IP for emulator/simulator
- Check firewall settings

### Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### State Not Updating

- Ensure Provider is wrapping the widget tree in `main.dart`
- Call `notifyListeners()` in provider after state changes

## 🔐 Security Notes

- JWT tokens are stored in FlutterSecureStorage
- Passwords are never logged or cached
- API client automatically adds auth headers
- 401 responses trigger automatic logout

## 🎯 Next Steps

### Features to Implement
- [ ] Create Delivery flow
- [ ] Order tracking
- [ ] Payment integration
- [ ] Push notifications
- [ ] Profile management
- [ ] Order history
- [ ] Real-time tracking with maps
- [ ] In-app chat with rider

### Improvements
- [ ] Add custom fonts
- [ ] Add app icons
- [ ] Add splash screen
- [ ] Implement refresh tokens
- [ ] Add unit tests
- [ ] Add integration tests
- [ ] Implement Google/Email OAuth
- [ ] Add error tracking (Sentry/Firebase Crashlytics)

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Provider Documentation](https://pub.dev/packages/provider)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Dio Documentation](https://pub.dev/packages/dio)

## 👥 Team

Built for the GoZapper platform

## 📄 License

[Add your license here]

---

**Happy Zapping! ⚡**
