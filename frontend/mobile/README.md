# Frontend Mobile — Flutter App

Cross-platform mobile application for restaurant staff to scan mixed-rice plates, manage menus, track transactions, and configure restaurant settings.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter (Dart) |
| State management | Provider (`ChangeNotifier`) |
| HTTP client | `http` package |
| Auth | JWT stored in `SharedPreferences` |
| Camera | `image_picker` |

## Quick Start

### Prerequisites

- **Flutter SDK** ≥ 3.x
- Android Studio / Xcode (for emulators)
- Backend server running at the URL set in `lib/config.dart`

### Setup

```bash
# Install dependencies
flutter pub get

# Run on a connected device / emulator
flutter run
```

## Screens & Navigation

### Auth Flow

| Screen | File | Description |
|--------|------|-------------|
| Login | `pages/login_page.dart` | Email & password sign-in |
| Register | `pages/register_page.dart` | Owner registration (creates restaurant) |
| Onboarding | `pages/onboarding/` | First-time restaurant setup |

### Dashboard (Bottom Navigation)

| Tab | File | Description |
|-----|------|-------------|
| Home | `pages/dashboard/home_tab.dart` | Daily stats (bill count, revenue, average, accuracy) |
| Menu | `pages/dashboard/menu_tab.dart` | Toggle menu items active / inactive |
| Scan (FAB) | `pages/dashboard/scan_tab.dart` | Camera capture → AI detection → confirm order |
| History | `pages/dashboard/history_tab.dart` | Transaction history grouped by date |
| Settings | `pages/dashboard/settings_tab.dart` | Restaurant profile, employee, and account settings |

### Sub-Pages

| Screen | File | Description |
|--------|------|-------------|
| Confirm Order | `pages/dashboard/confirm_order_page.dart` | Review detected items before billing |
| Order Success | `pages/dashboard/order_success_page.dart` | Post-transaction summary |
| Transaction Details | `pages/dashboard/transaction_details_page.dart` | Itemized receipt view, void option |
| Menu Settings | `pages/settings/menu_settings_page.dart` | Full CRUD for menu items |
| Restaurant Profile | `pages/settings/restaurant_profile_page.dart` | Edit name, address, image |
| Business Hours | `pages/settings/business_hours_page.dart` | Set opening / closing hours |
| Employee Manager | `pages/settings/employee_manager_page.dart` | Invite / remove staff |
| Edit Profile | `pages/settings/edit_profile_page.dart` | Update user name / email |
| Change Password | `pages/settings/change_password_page.dart` | Update account password |

### Customer-Facing

| Screen | File | Description |
|--------|------|-------------|
| Quick Scan | `pages/customer_page.dart` | Public scan page for customers |

## Project Structure

```
lib/
├── config.dart              # API base URL
├── main.dart                # App entry point, routing, providers
├── models/
│   ├── bill.dart            # Bill & BillItem models
│   ├── detection_result.dart# AI detection result model
│   ├── menu_item.dart       # MenuItem model
│   ├── restaurant.dart      # Restaurant model
│   └── user.dart            # User model
├── pages/
│   ├── login_page.dart
│   ├── register_page.dart
│   ├── customer_page.dart
│   ├── onboarding/
│   ├── dashboard/           # Main dashboard tabs + sub-pages
│   └── settings/            # Settings sub-pages
├── providers/
│   └── ...                  # ChangeNotifier providers
├── services/
│   ├── api_service.dart     # Base HTTP client (JWT headers)
│   ├── auth_service.dart    # Login / register / token storage
│   ├── bill_service.dart    # Bills API
│   ├── customer_service.dart# Public predict API
│   ├── employee_service.dart# Employee management API
│   ├── menu_service.dart    # Menu items API
│   ├── predict_service.dart # AI predict API
│   └── restaurant_service.dart # Restaurant profile API
└── widgets/
    ├── add_item_sheet.dart   # Manually add items bottom sheet
    ├── stats_bar.dart        # Dashboard statistics bar
    └── void_transaction_sheet.dart # Void confirmation sheet
```

## Configuration

Edit `lib/config.dart` to point to your backend:

```dart
const String baseUrl = 'http://<YOUR_BACKEND_IP>:3000';
```

> **Tip:** When running on an Android emulator, use `10.0.2.2` instead of `localhost` to reach the host machine.
