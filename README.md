# 💊 MediSure — AI-Powered Prescription Management App

> A smart healthcare companion built with Flutter that helps users manage medicines, set reminders, order from nearby pharmacies, and track health vitals.

---

## 📱 Screenshots

| Home Screen | Nearby Pharmacies | Order Tracking |
|-------------|-------------------|----------------|
| AI-powered dashboard | Real GPS-based pharmacy finder | Live order status updates |

---

## ✨ Features

### 🗺️ Pharmacy & Ordering
- **Nearby Pharmacies** — Real GPS location, distance, open/closed status
- **Order Medicines Online** — Cart, delivery address, payment selection
- **UPI Payment** — QR code scanner with exact amount
- **Order Tracking** — Live status: Confirmed → Processing → Shipped → Delivered
- **Price Comparison** — Compare prices across Apollo, MedPlus, 1mg & more

### 🔔 Smart Notifications
- **Medicine Reminders** — Set exact time, auto popup on any screen
- **Snooze** — 5 min / 10 min snooze options
- **Notification Center** — All alerts in one place
- **Email Notifications** — Order confirmation & delivery updates via Gmail

### 📊 Health Tracking
- **Medicine Adherence** — 30-day calendar, streaks, percentage
- **Health Vitals** — Log BP, blood sugar, weight, heart rate
- **Health Analytics** — Medicine usage trends and insights

### 👨‍👩‍👧 Family & Caregiving
- **Family Profiles** — Manage medicines for entire family
- **Emergency Contacts** — Blood group, allergies, chronic conditions

### 💊 Medicine Tools
- **Prescription Upload** — OCR in 7 Indian languages
- **Drug Interaction Checker** — Safety warnings with severity levels
- **Medicine Information** — Side effects, prices, alternatives
- **Expiry Tracking** — Alerts for expired/expiring medicines
- **Barcode Scanner** — Verify medicine authenticity

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.10+
- Dart SDK 3.0+
- Android Studio / VS Code
- Chrome (for web) or Android device

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/ankita12365/MediSure.git

# 2. Navigate to project folder
cd MediSure

# 3. Install dependencies
flutter pub get

# 4. Run on Chrome (Web)
flutter run -d chrome --web-port=8080 --web-hostname=localhost

# 5. Run on Android
flutter run -d android
```

### Continuous Integration

This repository includes a GitHub Actions workflow at `.github/workflows/flutter.yml` that runs `flutter analyze` and `flutter test` on pushes and pull requests.

### Remote backend support

A remote backend can be enabled at runtime using Dart defines. The app also supports optional service keys for backend authorization and external APIs:

```bash
flutter run \
  --dart-define=ENABLE_REMOTE_BACKEND=true \
  --dart-define=BACKEND_BASE_URL=https://api.medisure.com \
  --dart-define=BACKEND_API_KEY=your_backend_key \
  --dart-define=MAPS_API_KEY=your_maps_key \
  --dart-define=OCR_API_KEY=your_ocr_key
```

When remote backend support is enabled, the app uses `BackendService` for auth, prescription sync, secure token storage, and remote order routing. If the remote backend is unavailable, the app can fall back to local secure credentials and stored prescriptions, while still keeping order progress functional offline.

### Remote backend contract
- `POST /auth/login` → returns `{ user, token }`
- `POST /auth/register` → returns `{ user, token }`
- `GET /users/{userId}/prescriptions`
- `POST /users/{userId}/prescriptions`
- `DELETE /users/{userId}/prescriptions/{prescriptionId}`
- `GET /users/{userId}/orders`
- `POST /orders`

### UPI and payment configuration
Use Dart defines for production UPI merchant configuration:
```bash
flutter run \
  --dart-define=ENABLE_REMOTE_BACKEND=true \
  --dart-define=BACKEND_BASE_URL=https://api.medisure.com \
  --dart-define=BACKEND_API_KEY=your_backend_key \
  --dart-define=MAPS_API_KEY=your_maps_key \
  --dart-define=OCR_API_KEY=your_ocr_key \
  --dart-define=UPI_ID=yourupi@bank \
  --dart-define=UPI_PAYEE_NAME="MediSure Merchant"
```

To set CI secrets in GitHub, add `BACKEND_API_KEY`, `MAPS_API_KEY`, `OCR_API_KEY`, `UPI_ID`, and `UPI_PAYEE_NAME` to repository secrets.

### Real location & pharmacy data

The nearby pharmacy feature uses open data from OpenStreetMap and Overpass API for real local pharmacy discovery, plus IP-based and GPS location fallback for web and mobile.

### Test Login
```
Email: test@medisure.com
Password: MediSure@123
```

Remote backend support is optional. The app will use remote auth when enabled, and otherwise fall back to secure local credentials for offline startup readiness.

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.10+ |
| Language | Dart |
| State Management | Provider |
| Local Storage | Hive + SharedPreferences || Secure Credentials | flutter_secure_storage || OCR | Google ML Kit (mobile) + OCR.space (web) |
| Location | Geolocator + IP-API |
| Maps | Google Maps (via URL) |
| Notifications | Custom timer-based system |
| Email | mailto: deep link |
| WhatsApp | wa.me deep link |
| QR Code | qr_flutter |

---

## 📁 Project Structure

```
MediSure/
├── lib/
│   ├── core/theme/          # App theme & colors
│   ├── models/              # Data models
│   ├── screens/             # All UI screens (17+)
│   ├── services/            # Business logic (15+)
│   ├── widgets/             # Reusable components
│   └── main.dart            # App entry point
├── android/                 # Android configuration
├── web/                     # Web configuration
├── assets/                  # Translations, templates
├── pubspec.yaml             # Dependencies
└── README.md
```

---

## 📧 Contact

**Developer:** Palak Chandak  
**Email:** chandakpalak78@gmail.com 

---

## 📄 License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
