# Google Maps API Setup Instructions

The map now displays **real-time traffic indicators** with colored lines showing traffic conditions on roads!

## 🚦 Traffic Features Now Active:
- ✅ **RED lines** = Heavy traffic/congestion (Session Road, Governor Pack Road)
- ✅ **YELLOW lines** = Moderate traffic (Bonifacio Street, Kennon Road)
- ✅ **GREEN lines** = Smooth traffic (Camp John Hay, Leonard Wood, Loakan)
- ✅ **Live traffic layer** enabled
- ✅ **Color-coded markers** for crowd levels at tourist spots
- ✅ **Traffic status alerts** at the top of the map

## Step 1: Get a Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS (if testing on iOS)
4. Go to **Credentials** → **Create Credentials** → **API Key**
5. Copy your API key

## Step 2: Add API Key to Android

1. Open: `android/app/src/main/AndroidManifest.xml`
2. Find this line (already added):
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY_HERE"/>
   ```
3. Replace `YOUR_API_KEY_HERE` with your actual API key

## Step 3: Add API Key to iOS (if needed)

1. Open: `ios/Runner/AppDelegate.swift`
2. Add at the top:
   ```swift
   import GoogleMaps
   ```
3. Inside the `application` function, before `return`, add:
   ```swift
   GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
   ```

## Step 4: Rebuild the App

```bash
flutter clean
flutter pub get
flutter run
```

## Alternative: Test Without Real Map

If you want to test without setting up Google Maps immediately, you can temporarily replace the map widget with a placeholder image or container.

## Notes

- The API key is already configured in AndroidManifest.xml but needs your actual key
- Location permissions have been added
- Without a valid API key, the map will crash the app

## Security Note

For production apps:
- Restrict your API key in Google Cloud Console
- Add package name restriction: `com.example.crowd_smart`
- Never commit API keys to public repositories
- Consider using environment variables or secure storage
