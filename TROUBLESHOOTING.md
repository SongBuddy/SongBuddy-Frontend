# Troubleshooting Guide

## Internet Connection Error When Clicking Connect Button

If you're getting an "internet connection" error when clicking the Spotify connect button, here are the steps to resolve it:

### ✅ **Fixed Issues:**

1. **Missing Internet Permissions** - Added to Android manifest:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   ```

2. **Enhanced Error Handling** - Added connectivity checking and better error messages

3. **Multiple Launch Modes** - Added fallback URL launching methods

### 🔍 **Debug Steps:**

1. **Check Debug Screen** - Navigate to the 4th tab (Debug Auth) in the main app to see detailed information:
   - Environment variables status
   - Generated authorization URL
   - Connectivity status
   - URL launch capability

2. **Verify Environment Variables** - Ensure your `.env` file contains:
   ```
   SPOTIFY_CLIENT_ID=your_client_id_here
   SPOTIFY_CLIENT_SECRET=your_client_secret_here
   SPOTIFY_REDIRECT_URI=songbuddy://callback
   ```

3. **Check Network Connection** - Ensure your device/emulator has internet access

4. **Test URL Generation** - The debug screen will show the generated Spotify authorization URL

### 🛠️ **Common Solutions:**

#### **Solution 1: Restart the App**
- Stop the app completely
- Run `flutter clean`
- Run `flutter pub get`
- Restart the app

#### **Solution 2: Check Device/Emulator**
- Ensure your device has internet connection
- For emulator: Check that it has internet access
- Try opening a web browser on the device to verify connectivity

#### **Solution 3: Verify Spotify App Configuration**
- Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/applications)
- Ensure your app's redirect URI is exactly: `songbuddy://callback`
- Verify your client ID and secret are correct

#### **Solution 4: Platform-Specific Issues**

**Android:**
- Ensure you have a web browser installed
- Check that the app has internet permissions
- Try running on a physical device instead of emulator

**iOS:**
- Ensure you have Safari or another web browser
- Check iOS simulator has internet access
- Verify URL scheme is properly configured

### 🐛 **Debug Information:**

The debug screen will show:
- ✅ Environment variables loaded successfully
- ✅ Generated authorization URL
- ✅ Internet connection status
- ✅ URL launch capability

If any of these show ❌, that's where the issue is.

### 📱 **Testing Steps:**

1. Open the app
2. Navigate to the Debug Auth tab (4th tab)
3. Check all debug information shows ✅
4. Click "Test Login" button
5. Check console logs for detailed error messages

### 🔧 **Console Logs:**

Look for these debug messages in the console:
```
Generated auth URL: https://accounts.spotify.com/authorize?...
Can launch URL: true/false
URL launched successfully: true/false
```

### 📞 **Still Having Issues?**

If the problem persists:

1. **Check Console Logs** - Look for detailed error messages
2. **Test on Different Device** - Try on physical device vs emulator
3. **Verify Spotify App** - Double-check your Spotify app configuration
4. **Network Issues** - Try different network connection

### 🚀 **Quick Fix Commands:**

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check dependencies
flutter doctor

# Check for issues
flutter analyze
```

The internet connection error should now be resolved with the added permissions and enhanced error handling!
