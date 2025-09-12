# 🎵 SongBuddy Setup Guide

## Environment Variables Setup

### 1. Create Your Own Spotify App
**Each contributor needs their own Spotify app:**

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/applications)
2. Click "Create App"
3. Fill in app details:
   - **App name**: SongBuddy (or SongBuddy-YourName)
   - **App description**: Social music app
   - **Website**: Your website (optional)
   - **Redirect URI**: `songbuddy://callback`
4. **Select APIs**: Web API, Android (and iOS if needed)
5. **Set Package Name**: `com.songbuddy.app`
6. **Set SHA1 Fingerprint**: `B0:E2:69:77:43:3F:55:44:E2:39:51:E7:74:24:73:8E:B1:C1:74:14`
7. Save and note your **Client ID** and **Client Secret**

### 2. Create Environment File
1. Copy `env.example` to `.env`:
   ```bash
   cp env.example .env
   ```

2. Edit `.env` file with your actual credentials:
   ```env
   SPOTIFY_CLIENT_ID=your_actual_client_id_here
   SPOTIFY_CLIENT_SECRET=your_actual_client_secret_here
   SPOTIFY_REDIRECT_URI=songbuddy://callback
   ```

### 3. Security Notes
- ✅ **Never share your `.env` file** - It contains sensitive credentials
- ✅ **Each developer needs their own Spotify app** - Don't share credentials
- ✅ **Keep Client Secret secure** - Never commit to version control
- ✅ **Use different apps for dev/staging/production** - Environment separation
- ✅ `.env` file is automatically ignored by Git
- ✅ Never commit your actual credentials to version control

### 4. Running the App
```bash
flutter pub get
flutter run
```

## Troubleshooting

### "Environment variables not set" Error
- Make sure `.env` file exists in project root
- Check that file contains valid Spotify credentials
- Verify file is not empty or corrupted

### Spotify API Errors
- Verify Client ID and Secret are correct
- Check Redirect URI matches exactly in Spotify Dashboard
- Ensure Spotify app is not in "Development Mode" restrictions

## Next Steps
1. Set up your Spotify app credentials
2. Test the login flow
3. Implement token storage
4. Add music data fetching
