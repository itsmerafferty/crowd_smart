# CrowdSmart – Google Maps API Setup Guide

## Step 1 — Get Your API Key

1. Go to [https://console.cloud.google.com/](https://console.cloud.google.com/)
2. Create a new project (e.g. **CrowdSmart**)
3. Go to **APIs & Services → Library** and enable:
   - ✅ Maps SDK for Android
   - ✅ Maps SDK for iOS
   - ✅ Directions API
   - ✅ Distance Matrix API
   - ✅ Places API (for search)
4. Go to **APIs & Services → Credentials → Create Credentials → API Key**
5. Copy your API key

---

## Step 2 — Add the Key to the App

### File 1: `lib/config/api_config.dart`
```dart
static const String googleMapsApiKey = 'PASTE_YOUR_KEY_HERE';
```

### File 2: `android/app/src/main/AndroidManifest.xml`
Find this line and replace the value:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="PASTE_YOUR_KEY_HERE"/>
```

---

## Step 3 — Run the App

```bash
flutter pub get
flutter run
```

---

## Features Enabled by Google Maps API

| Feature | API Used |
|---------|---------|
| Interactive map centered on Baguio | Maps SDK for Android |
| Real-time traffic overlay | Maps SDK (trafficEnabled) |
| Color-coded traffic polylines | Maps SDK |
| Tourist & parking markers | Maps SDK |
| Satellite / Terrain / Hybrid views | Maps SDK |
| Route suggestions | Directions API |
| My Location blue dot | Maps SDK |

---

## Troubleshooting

- **Map shows grey tiles**: API key is wrong or Maps SDK not enabled
- **"This app is not authorized"**: Check API key restrictions in Google Console
- **Location not showing**: Make sure `ACCESS_FINE_LOCATION` permission is granted on device

