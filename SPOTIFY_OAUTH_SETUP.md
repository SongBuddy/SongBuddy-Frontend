# Spotify OAuth Setup Guide

This guide explains how to set up and use the Spotify OAuth authentication flow in SongBuddy.

## Prerequisites

1. A Spotify Developer account
2. A Spotify app created in the Spotify Developer Dashboard
3. Flutter development environment set up

## Setup Steps

### 1. Create Spotify App

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/applications)
2. Click "Create App"
3. Fill in the app details:
   - App name: SongBuddy
   - App description: Music companion app
   - Website: Your website (optional)
   - Redirect URI: `songbuddy://callback`

### 2. Configure Environment Variables

1. Copy `env.example` to `.env`:
   ```bash
   cp env.example .env
   ```

2. Fill in your Spotify app credentials in `.env`:
   ```
   SPOTIFY_CLIENT_ID=your_client_id_here
   SPOTIFY_CLIENT_SECRET=your_client_secret_here
   SPOTIFY_REDIRECT_URI=songbuddy://callback
   ```

### 3. Install Dependencies

Run the following command to install required packages:
```bash
flutter pub get
```

## How It Works

### Authentication Flow

1. **User clicks login button** → Opens Spotify authorization page
2. **User authorizes the app** → Spotify redirects to `songbuddy://callback` with authorization code
3. **App receives callback** → Extracts authorization code from deep link
4. **Code exchange** → Exchanges authorization code for access token
5. **Token storage** → Stores access token securely using Flutter Secure Storage
6. **User info retrieval** → Gets user profile information to validate token
7. **Navigation** → Redirects user to main app screen

### Key Components

#### AuthService (`lib/services/auth_service.dart`)
- Handles the complete OAuth flow
- Manages authentication state
- Stores tokens securely
- Handles errors and timeouts

#### AuthProvider (`lib/providers/auth_provider.dart`)
- Global authentication provider
- Singleton pattern for app-wide access
- Manages authentication state across the app

#### SpotifyService (`lib/services/spotify_service.dart`)
- Handles Spotify API calls
- Generates authorization URLs
- Exchanges codes for tokens
- Makes authenticated API requests

### Deep Link Configuration

The app is configured to handle `songbuddy://callback` deep links:

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="songbuddy" />
</intent-filter>
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>songbuddy</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>songbuddy</string>
        </array>
    </dict>
</array>
```

## Usage Examples

### Check Authentication Status
```dart
final authProvider = AuthProvider();
await authProvider.initialize();

if (authProvider.isAuthenticated) {
  // User is logged in
  print('User ID: ${authProvider.userId}');
  print('Access Token: ${authProvider.accessToken}');
} else {
  // User needs to log in
  await authProvider.login();
}
```

### Listen to Authentication Changes
```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _authProvider.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    setState(() {
      // Update UI based on auth state
    });
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
```

### Logout User
```dart
final authProvider = AuthProvider();
await authProvider.logout();
```

## Error Handling

The implementation includes comprehensive error handling for:

- Network connectivity issues
- Invalid authorization codes
- Token exchange failures
- Token validation errors
- Authentication timeouts (5 minutes)
- Deep link parsing errors

## Security Features

- **Secure Token Storage**: Uses Flutter Secure Storage for sensitive data
- **Token Validation**: Validates tokens by fetching user information
- **Automatic Cleanup**: Clears expired tokens automatically
- **Error Recovery**: Provides clear error messages and recovery options

## Testing

To test the OAuth flow:

1. Ensure your `.env` file is properly configured
2. Run the app: `flutter run`
3. Navigate to the onboarding screen
4. Click "Continue with Spotify"
5. Complete the authorization in your browser
6. Verify you're redirected back to the app
7. Check the settings screen to confirm authentication status

## Troubleshooting

### Common Issues

1. **"Could not launch Spotify authorization URL"**
   - Check internet connectivity
   - Verify Spotify app credentials

2. **"No authorization code received"**
   - Ensure redirect URI matches exactly: `songbuddy://callback`
   - Check deep link configuration

3. **"Token validation failed"**
   - Verify Spotify app permissions
   - Check network connectivity

4. **Authentication timeout**
   - Complete authorization within 5 minutes
   - Check if browser blocked the redirect

### Debug Tips

- Check console logs for detailed error messages
- Verify environment variables are loaded correctly
- Test deep link handling with `flutter run --debug`
- Use Spotify's token validation endpoint for debugging

## API Permissions

The app requests the following Spotify permissions:
- `user-read-private`: Read user's subscription details
- `user-read-email`: Read user's email address
- `user-read-currently-playing`: Read currently playing track
- `user-read-playback-state`: Read user's playback state
- `user-library-read`: Read user's saved tracks and albums
- `playlist-read-private`: Read user's private playlists

## Next Steps

After successful authentication, you can:
- Fetch user's playlists
- Get currently playing track
- Access user's saved tracks
- Implement music recommendations
- Add social features

For more information, see the [Spotify Web API documentation](https://developer.spotify.com/documentation/web-api/).
