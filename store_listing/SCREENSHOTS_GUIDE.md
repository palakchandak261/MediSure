# MediSure — Screenshot Guide for Store Listing

## How to Take Screenshots

### Android (Play Store)
1. Run the app: `flutter run --release`
2. Navigate to each screen listed below
3. Press `Volume Down + Power` to screenshot
4. Screenshots are saved to your device gallery

### iOS (App Store)
1. Run on iOS Simulator: `flutter run -d "iPhone 14 Pro Max"`
2. Navigate to each screen
3. Press `Cmd + S` in Simulator to screenshot

---

## Required Screenshots (in order)

### Screenshot 1 — Home Screen
**Screen**: HomeScreen
**What to show**: 
- Greeting with user name
- "Upload Prescription" hero card
- Quick action chips (Nearby Pharmacy, Reminders, etc.)
- Feature highlight cards

### Screenshot 2 — Upload Prescription
**Screen**: UploadScreen
**What to show**:
- Camera/Gallery buttons
- Language selector
- "Analyze Prescription" button
- Tips section

### Screenshot 3 — OCR Result
**Screen**: ResultScreen
**What to show**:
- Extracted medicine list with names, dosages, timing
- "Order Medicines" button
- "Set Reminders" button

### Screenshot 4 — Medicine Reminders
**Screen**: RemindersScreen
**What to show**:
- Active reminders list
- Time picker
- Enable/disable toggles

### Screenshot 5 — Nearby Pharmacy
**Screen**: NearbyPharmacyScreen
**What to show**:
- Pharmacy list with distance, rating, delivery time
- Price comparison
- "Order" button

### Screenshot 6 — Payment
**Screen**: UpiPaymentScreen
**What to show**:
- Amount display
- QR code
- UPI app buttons (GPay, PhonePe, Paytm)

### Screenshot 7 — Adherence Calendar
**Screen**: AdherenceScreen
**What to show**:
- 30-day calendar with taken/missed indicators
- Adherence percentage
- Streak counter

### Screenshot 8 — Health Vitals
**Screen**: HealthVitalsScreen
**What to show**:
- BP, sugar, weight, temperature entries
- Trend chart

---

## Screenshot Specifications

| Store | Device | Resolution | Format |
|-------|--------|------------|--------|
| Play Store | Phone | 1080x1920 min | PNG/JPEG |
| Play Store | Feature Graphic | 1024x500 | PNG/JPEG |
| App Store | iPhone 6.5" | 1242x2688 | PNG |
| App Store | iPhone 5.5" | 1242x2208 | PNG |

---

## App Icon Specifications

| Platform | Size | Format | Notes |
|----------|------|--------|-------|
| Play Store | 512x512 | PNG | No alpha/transparency |
| App Store | 1024x1024 | PNG | No alpha, no rounded corners |
| Android launcher | 48-192px | PNG | Already in mipmap folders |

### Current Icon Location
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png      (48x48)
├── mipmap-hdpi/ic_launcher.png      (72x72)
├── mipmap-xhdpi/ic_launcher.png     (96x96)
├── mipmap-xxhdpi/ic_launcher.png    (144x144)
└── mipmap-xxxhdpi/ic_launcher.png   (192x192)
```

### To Generate New Icons
1. Create a 1024x1024 PNG with your design
2. Add `flutter_launcher_icons: ^0.13.1` to pubspec.yaml dev_dependencies
3. Add to pubspec.yaml:
   ```yaml
   flutter_icons:
     android: true
     ios: true
     image_path: "assets/icon/app_icon.png"
     adaptive_icon_background: "#5C6BC0"
     adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
   ```
4. Run: `flutter pub run flutter_launcher_icons`

---

## Privacy Policy (Required for Both Stores)

You must host a privacy policy before submitting. Minimum content:
- What data is collected (camera, location, health data)
- How data is stored (locally on device)
- Whether data is shared with third parties (no)
- Contact information

Free hosting options: GitHub Pages, Notion, Google Sites
