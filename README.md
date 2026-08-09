# Motorcycle Shop Manager (Flutter)

A complete inventory and billing management app for motorcycle repair and spare parts shops.

## Features
- **Inventory System** — add parts with name, category, purchase/sale price, stock quantity, and photo
- **Billing / Cart System** — filter by category tabs, edit quantities directly in checkout
- **Automatic stock updates** — stock decreases when a bill is created, increases when a purchase is recorded
- **Labour/Service charges** — add labour cost separately on each bill
- **Vehicle Service History** — search by bike number to see its full repair history
- **Suppliers & Purchases** — keep supplier records, track stock-in purchases (auto inventory update)
- **Shop Expenses** — track rent, salary, electricity and other running costs
- **Reports** — Profit/Loss (revenue, cost, gross/net profit), best-selling parts, monthly revenue trend
- **PDF Invoice + Share** — generate a PDF bill and share it via WhatsApp, print, or any app
- **Backup & Restore** — back up all shop data locally, share it manually (WhatsApp/Drive/email), and restore anytime — no login or account required
- **Settings** — customize shop name, address, phone, invoice footer, currency symbol and low-stock threshold
- **Splash screen + custom app icon** — branded loading screen and launcher icon matching the app theme
- **Local SQLite database** — works fully offline

## How to Run

```bash
flutter create motorcycle_shop        # generates android/ios/web platform folders
# copy this project's lib/, pubspec.yaml and assets/ into that new folder (overwrite)
cd motorcycle_shop
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter run
```

For a release APK:
```bash
flutter build apk --split-per-abi --release
```
APKs will be created at: `build/app/outputs/flutter-apk/`
(Use `app-arm64-v8a-release.apk` for almost all modern phones — it's the smallest file that covers 95%+ of devices.)

## Project Structure
```
lib/
  main.dart
  theme/
    app_theme.dart          -> Centralized colors, fonts, component styles
  services/
    settings_service.dart   -> Shop profile & invoice settings (stored locally)
  models/
    product.dart
    bill.dart                -> Bill + BillItem (vehicle info & cost price for profit tracking)
    supplier.dart
    purchase.dart
    expense.dart
  database/
    db_helper.dart            -> All SQLite logic + reports + backup/restore
  screens/
    splash_screen.dart
    main_nav_screen.dart       -> Bottom navigation shell
    dashboard_screen.dart      -> Home tab: stats, quick actions, recent bills
    inventory_screen.dart
    add_product_screen.dart
    billing_screen.dart         -> Category tabs + editable cart in checkout
    bill_detail_screen.dart     -> Invoice view + PDF share
    bill_history_screen.dart    -> Date filters (Today/Week/Month/custom)
    vehicle_history_screen.dart
    suppliers_screen.dart
    purchases_screen.dart
    expenses_screen.dart
    reports_screen.dart
    backup_screen.dart
    settings_screen.dart
    more_screen.dart            -> Secondary features menu
```

## Notes
- The database upgrades safely across versions — existing data is never lost when new features are added
- Backup files are saved inside the app's private `documents/backups/` folder on the device
- PDF sharing uses the system share sheet, so it works with whatever app is installed (WhatsApp, email, etc.)

## Ideas for Future Features
- Multi-user login (owner vs mechanic access levels)
- Barcode/QR scanning for parts
- Cloud sync via Google Sign-In + Google Drive (requires a free Google Cloud Console project)
- Customer credit/ledger tracking
- App PIN lock

## App Name & Icon

### 1. App Icon (already set up)
A custom icon (`assets/icon/icon.png`) is already included. Just run:
```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
The first command generates the launcher icon for Android/iOS, the second sets up the native splash screen (the first frame shown when the app opens, before Flutter even loads) in the same navy/orange theme. Then run `flutter run` as usual.

To use your own icon: replace `assets/icon/icon.png` (1024x1024, square) with your image, then run both commands again.

### 2. Changing the App Name (one-time, manual)

**Android:**
Open `android/app/src/main/AndroidManifest.xml` and find:
```xml
android:label="motorcycle_shop"
```
Replace it with your shop/app name, e.g.:
```xml
android:label="Shan Motorcycle Repair"
```

**iOS:**
Open `ios/Runner/Info.plist` and find:
```xml
<key>CFBundleDisplayName</key>
<string>motorcycle_shop</string>
```
Replace it with your app name:
```xml
<key>CFBundleDisplayName</key>
<string>Shan Motorcycle Repair</string>
```

After changing both, run:
```bash
flutter clean
flutter pub get
flutter run
```

Note: `name: motorcycle_shop` at the top of `pubspec.yaml` is just the internal project/package name (never shown on the phone) — no need to change it.
