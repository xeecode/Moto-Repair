# Motorcycle Shop Manager (Flutter)

Motorcycle repair & spare parts shop ke liye complete inventory + billing app.

## Features
- **Inventory System** — har part add karein: name, category, purchase/sale price, stock qty, image
- **Billing / Cart System** — category tabs se filter karo, checkout mein qty +/- direct edit karo
- **Auto stock update** — bill banane par stock automatically minus, purchase karne par automatically plus
- **Labour/Service charges** — bill mein alag se labour cost add karo
- **Vehicle Service History** — bike number se search karo, uski poori repair history dekho
- **Suppliers & Purchases** — supplier record rakho, stock-in purchases track karo (auto inventory update)
- **Shop Expenses** — rent, salary, bijli waghera track karo
- **Reports** — Profit/Loss (revenue, cost, gross/net profit), best-selling parts, monthly revenue trend
- **PDF Invoice + Share** — bill ko PDF bana kar WhatsApp/print/kahin bhi share karo
- **Backup & Restore** — apna sara data backup karo, kabhi bhi restore kar sako
- **Splash screen** — app open hote hi branded loading screen
- **Local SQLite database** — offline kaam karta hai

## How to Run

```bash
flutter create motorcycle_shop        # generates android/ios/web platform folders
# copy this project's lib/ and pubspec.yaml into that new folder (overwrite)
cd motorcycle_shop
flutter pub get
flutter run
```

For a release APK:
```bash
flutter build apk --release
```
APK milegi: `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure
```
lib/
  main.dart
  models/
    product.dart
    bill.dart              -> Bill + BillItem (with vehicle info & cost price)
    supplier.dart
    purchase.dart
    expense.dart
  database/
    db_helper.dart          -> All SQLite logic + reports + backup/restore
  screens/
    splash_screen.dart
    home_screen.dart
    inventory_screen.dart
    add_product_screen.dart
    billing_screen.dart      -> Category tabs + editable cart in checkout
    bill_detail_screen.dart  -> Invoice + PDF share
    bill_history_screen.dart
    vehicle_history_screen.dart
    suppliers_screen.dart
    purchases_screen.dart
    expenses_screen.dart
    reports_screen.dart
    backup_screen.dart
```

## Notes
- Database auto-upgrades safely — purana data delete nahi hota naye features add hone se
- Backup files device ke andar `app documents/backups/` folder mein save hote hain
- PDF share system share-sheet use karta hai — jo bhi app installed ho (WhatsApp, email, etc) usse share ho sakta hai

## Aage kya add ho sakta hai
- Multi-user login (owner vs mechanic access levels)
- Barcode/QR scanning for parts
- Cloud backup (Firebase / Google Drive)
- Customer credit/udhaar ledger

Batao agar in mein se koi feature next chahiye!

## App Name & Icon Change Karna

### 1. App Icon (automatic - already set up)
Ek custom icon (`assets/icon/icon.png`) already project mein hai. Bas yeh commands chalao:
```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
Pehla command icon generate karta hai, doosra native splash screen (app open hote hi jo pehla frame dikhta hai — icon load hone se pehle bhi) usi navy/orange theme mein set kar deta hai. Phir normal `flutter run` karo.

Agar apna khud ka icon lagana ho: `assets/icon/icon.png` (1024x1024, square) ko apni image se replace kar do, phir dono commands dobara chalao.

### 2. App Name Change Karna (manual - ek dafa)

**Android:**
`android/app/src/main/AndroidManifest.xml` file kholo, is line ko dhoondo:
```xml
android:label="motorcycle_shop"
```
Ussay apne shop/app ke naam se replace kar do, jaisay:
```xml
android:label="Shan Motorcycle Repair"
```

**iOS:**
`ios/Runner/Info.plist` file kholo, is line ko dhoondo:
```xml
<key>CFBundleDisplayName</key>
<string>motorcycle_shop</string>
```
Ussay apne app ke naam se replace kar do:
```xml
<key>CFBundleDisplayName</key>
<string>Shan Motorcycle Repair</string>
```

Dono jagah change karne ke baad:
```bash
flutter clean
flutter pub get
flutter run
```

Note: `pubspec.yaml` mein upar `name: motorcycle_shop` hai — yeh sirf internal project/code ka naam hai (jo phone pe kabhi nahi dikhta), isay change karne ki zaroorat nahi.
