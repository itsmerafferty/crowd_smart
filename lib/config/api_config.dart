// ─────────────────────────────────────────────────────────────────────────────
// CrowdSmart – API Configuration
// ─────────────────────────────────────────────────────────────────────────────
//
// HOW TO SET UP YOUR GOOGLE MAPS API KEY:
//
// 1. Go to https://console.cloud.google.com/
// 2. Create or select a project
// 3. Enable these APIs:
//    - Maps SDK for Android
//    - Maps SDK for iOS
//    - Directions API
//    - Distance Matrix API
//    - Places API
// 4. Go to "Credentials" → Create API Key
// 5. Paste your key below as [googleMapsApiKey]
// 6. Also paste it in android/app/src/main/AndroidManifest.xml
//    at: android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"
//
// ─────────────────────────────────────────────────────────────────────────────

class ApiConfig {
  /// Your Google Maps Platform API Key.
  /// Replace this with your actual key.
  static const String googleMapsApiKey = 'AIzaSyBl1XHLRYGOcuQ8reJwmDY7Vt-bAQSnf-4';

  /// Baguio City center coordinates
  static const double baguioLat = 16.4119;
  static const double baguioLng = 120.5937;

  /// Default map zoom level
  static const double defaultZoom = 14.0;
  static const double detailZoom = 16.0;
}

