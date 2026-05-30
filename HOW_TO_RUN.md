# MediSure — Complete Setup & Run Guide

This guide covers every step to get MediSure running with all real integrations:
real backend, Google Vision OCR, Firebase FCM push notifications, Razorpay payments,
and Play Store / App Store listing assets.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter | ≥ 3.10 | https://flutter.dev/docs/get-started/install |
| Dart | ≥ 3.10 | Included with Flutter |
| Node.js | ≥ 18 | https://nodejs.org |
| Android Studio | Latest | https://developer.android.com/studio |
| Git | Any | https://git-scm.com |

---

## 1. Clone & Install Dependencies

```bash
# Flutter dependencies
cd "MediSure-main"
flutter pub get

# Backend dependencies
cd backend
npm install
cd ..
```

---

## 2. Real Backend Setup

### 2a. Configure backend/.env

Copy the example and fill in your values:

```bash
cp backend/.env.example backend/.env
```

Edit `backend/.env`:

```env
PORT=3000
NODE_ENV=development
JWT_SECRET=<generate: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))">
API_KEY=<any strong random string — must match BACKEND_API_KEY in .env>

# Firebase (optional — skip for local dev, uses in-memory store)
FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
FIREBASE_PROJECT_ID=your-firebase-project-id

# Google Vision OCR
GOOGLE_VISION_API_KEY=<your key from console.cloud.google.com>

# Razorpay
RAZORPAY_KEY_ID=rzp_test_<your key>
RAZORPAY_KEY_SECRET=<your secret>

UPI_ID=yourname@upi
UPI_PAYEE_NAME=Your Pharmacy Name
```

### 2b. Start the backend

```bash
cd backend
npm run dev        # development (auto-restart on changes)
# OR
npm start          # production
```

The server starts at http://localhost:3000. Test it:

```bash
curl http://localhost:3000/health
# Expected: {"status":"ok","version":"1.0.0",...}
```

### 2c. Enable backend in Flutter .env

Edit the root `.env` file:

```env
ENABLE_REMOTE_BACKEND=true
BACKEND_BASE_URL=http://10.0.2.2:3000   # Android emulator
# BACKEND_BASE_URL=http://localhost:3000  # Web / iOS simulator
BACKEND_API_KEY=<same value as API_KEY in backend/.env>
```

---

## 3. Google Vision OCR (Web)

Mobile uses ML Kit offline — no setup needed.
Web requires Google Vision API.

### Steps:
1. Go to https://console.cloud.google.com
2. Create a project (or select existing)
3. Enable **Cloud Vision API**: APIs & Services → Library → search "Cloud Vision API" → Enable
4. Create API key: APIs & Services → Credentials → Create Credentials → API Key
5. Restrict the key: API restrictions → Cloud Vision API only
6. Copy the key to `.env`:

```env
OCR_API_KEY=AIzaSy...your_key_here
```

Also add it to `backend/.env`:

```env
GOOGLE_VISION_API_KEY=AIzaSy...your_key_here
```

---

## 4. Firebase FCM Push Notifications

FCM enables background push notifications when the app is closed.

### 4a. Create Firebase project
1. Go to https://console.firebase.google.com
2. Click "Add project" → name it "MediSure"
3. Disable Google Analytics (optional) → Create project

### 4b. Add Android app
1. In Firebase Console → Project Overview → Add app → Android
2. Android package name: `com.example.medisure`
3. App nickname: MediSure
4. Click "Register app"
5. Download `google-services.json`
6. Place it at: `android/app/google-services.json`

### 4c. Enable Cloud Messaging
1. Firebase Console → Project Settings → Cloud Messaging
2. Ensure Firebase Cloud Messaging API is enabled
3. Note your **Server key** (for backend)

### 4d. Configure backend for FCM
1. Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key" → download JSON
3. Save as `backend/serviceAccountKey.json`
4. Update `backend/.env`:

```env
FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
FIREBASE_PROJECT_ID=your-firebase-project-id
```

### 4e. Verify FCM works
Run the app on a real Android device (FCM doesn't work on emulator without Google Play).
Check the debug console for:
```
✅ Firebase initialized
FCM Token: eyJhbGci...
✅ FCM token registered with backend
```

---

## 5. Razorpay Payment Integration

### 5a. Create Razorpay account
1. Go to https://razorpay.com → Sign Up
2. Complete KYC (business registration required for live payments)
3. For testing, use test mode — no KYC needed

### 5b. Get API keys
1. Razorpay Dashboard → Settings → API Keys
2. Click "Generate Test Key"
3. Copy Key ID (`rzp_test_...`) and Key Secret

### 5c. Configure keys
In root `.env`:
```env
RAZORPAY_KEY_ID=rzp_test_your_key_id
PAYMENT_GATEWAY_API_KEY=your_key_secret
```

In `backend/.env`:
```env
RAZORPAY_KEY_ID=rzp_test_your_key_id
RAZORPAY_KEY_SECRET=your_key_secret
```

### 5d. Test payment
Use Razorpay test cards:
- Card: `4111 1111 1111 1111`, Expiry: any future date, CVV: any 3 digits
- UPI: `success@razorpay` (always succeeds)
- UPI: `failure@razorpay` (always fails — for testing error handling)

### Note on UPI fallback
If Razorpay keys are not configured, the app automatically falls back to
direct UPI QR code payment (no gateway, no business registration needed).

---

## 6. Run the Flutter App

### Android (emulator or device)
```bash
flutter run
```

### Web
```bash
flutter run -d chrome
```

### With specific backend URL
```bash
flutter run --dart-define=ENABLE_REMOTE_BACKEND=true \
            --dart-define=BACKEND_BASE_URL=http://10.0.2.2:3000 \
            --dart-define=BACKEND_API_KEY=your_api_key \
            --dart-define=OCR_API_KEY=your_vision_key \
            --dart-define=RAZORPAY_KEY_ID=rzp_test_your_key
```

---

## 7. Deploy Backend to Production

### Option A: Railway (recommended, free tier available)

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and deploy
railway login
cd backend
railway init
railway up
```

Set environment variables in Railway dashboard → Variables.
Your backend URL will be: `https://medisure-backend.up.railway.app`

### Option B: Render

1. Push backend to GitHub
2. Go to https://render.com → New Web Service
3. Connect your repo, set root directory to `backend/`
4. Build command: `npm install`
5. Start command: `npm start`
6. Add all environment variables in Render dashboard

### Option C: Heroku

```bash
cd backend
heroku create medisure-backend
heroku config:set JWT_SECRET=... GOOGLE_VISION_API_KEY=... RAZORPAY_KEY_ID=...
git push heroku main
```

After deploying, update root `.env`:
```env
BACKEND_BASE_URL=https://your-deployed-url.railway.app
```

---

## 8. App Store / Play Store Listing

### Play Store (Android)

**Requirements:**
- Google Play Developer account ($25 one-time fee): https://play.google.com/console
- App signed with a release keystore

**Generate release keystore:**
```bash
keytool -genkey -v -keystore android/app/medisure-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias medisure
```

**Build release APK / AAB:**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**Store listing details** (see `store_listing/` folder):
- App name: MediSure — AI Prescription Manager
- Short description: Scan prescriptions, set reminders, order medicines
- Full description: See `store_listing/play_store_description.txt`
- Category: Medical
- Content rating: Everyone
- Screenshots: See `store_listing/screenshots/`

### App Store (iOS)

**Requirements:**
- Apple Developer account ($99/year): https://developer.apple.com
- Mac with Xcode

**Build:**
```bash
flutter build ipa --release
```

**Store listing details:**
- Same as Play Store
- Age rating: 4+
- Category: Medical

---

## 9. App Icon

The app icon files are at:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`

To regenerate with a custom icon:
1. Place your 1024×1024 PNG at `assets/icon/app_icon.png`
2. Add to pubspec.yaml:
   ```yaml
   flutter_icons:
     android: true
     ios: true
     image_path: "assets/icon/app_icon.png"
   ```
3. Run: `flutter pub run flutter_launcher_icons`

---

## 10. Troubleshooting

| Problem | Solution |
|---------|----------|
| `ENABLE_REMOTE_BACKEND=false` — backend not connecting | Set to `true` in `.env` and restart app |
| OCR returns empty on web | Set `OCR_API_KEY` in `.env` and enable Cloud Vision API |
| FCM not working | Ensure `google-services.json` is in `android/app/` and test on real device |
| Razorpay not opening | Set `RAZORPAY_KEY_ID` in `.env` — app falls back to UPI QR if not set |
| Backend 401 errors | Ensure `BACKEND_API_KEY` in `.env` matches `API_KEY` in `backend/.env` |
| `firebase_core` init fails | Missing `google-services.json` — app works without it (FCM disabled) |
| Android build fails | Run `flutter clean && flutter pub get` then rebuild |

---

## Quick Start (Local Dev, No External Services)

```bash
# 1. Install dependencies
flutter pub get
cd backend && npm install && cd ..

# 2. Start backend (uses in-memory store, no Firebase needed)
cd backend && npm run dev &

# 3. Run Flutter app
flutter run
```

The app works fully offline without any API keys.
OCR works on mobile (ML Kit), notifications work in-app.
UPI QR code works without Razorpay keys.
