# Install App on Your Phone

## Option 1: Direct Install via USB (Fastest)

### For Android Phone:
1. **Enable Developer Mode:**
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - You'll see "You are now a developer"

2. **Enable USB Debugging:**
   - Go to Settings → System → Developer Options
   - Enable "USB Debugging"

3. **Connect Phone:**
   - Connect your phone to Mac via USB cable
   - When popup appears on phone, select "Allow USB debugging"

4. **Install the app:**
   ```bash
   flutter devices  # Check if phone is detected
   flutter run      # Select your phone from the list
   ```

### For iPhone:
1. Connect iPhone to Mac via USB
2. Trust the computer when prompted
3. Run:
   ```bash
   flutter run
   ```

## Option 2: Build APK File (Share with others too)

### Build Release APK:
```bash
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Install APK on your phone:
1. Transfer the APK to your phone (via USB, email, or cloud)
2. Open the APK file on your phone
3. Allow "Install from Unknown Sources" if prompted
4. Install the app

## Option 3: Build App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

The bundle will be at: `build/app/outputs/bundle/release/app-release.aab`

## Current Status

You currently have an emulator running. To use your physical phone instead:

1. Close the emulator
2. Connect your phone via USB
3. Run `flutter devices` to verify it's detected
4. Run `flutter run` and select your phone

## Quick Install Command

Once phone is connected:
```bash
# Clean build
flutter clean
flutter pub get

# Build and install on connected device
flutter run --release
```

This will install the production-ready version on your phone.
