# 🎵 SongBuddy

A modern social music app built with Flutter that connects with Spotify to share music experiences with friends. Discover new music, share your favorite tracks, and connect with friends through the universal language of music.

## ✨ Features

- 🎧 **Spotify Integration** - Seamless connection with your Spotify account
- 👥 **Social Music Sharing** - Share your favorite tracks and playlists with friends
- 📱 **Cross-Platform** - Runs on iOS, Android, Web, macOS, Linux, and Windows
- 🎨 **Beautiful UI** - Modern, intuitive design with smooth animations
- 🔐 **Secure Authentication** - Safe and secure Spotify OAuth integration
- 📊 **Music Discovery** - Explore trending tracks and discover new music
- 👤 **User Profiles** - Create and customize your music profile

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.5.4 or higher)
- Dart SDK
- Spotify Developer Account
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/mohammadaminrez/songbuddy.git
   cd songbuddy
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   ```bash
   cp env.example .env
   ```
   
   Edit the `.env` file with your Spotify app credentials:
   ```env
   SPOTIFY_CLIENT_ID=your_spotify_client_id
   SPOTIFY_CLIENT_SECRET=your_spotify_client_secret
   SPOTIFY_REDIRECT_URI=songbuddy://callback
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Spotify App Setup

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/applications)
2. Create a new app
3. Set the redirect URI to `songbuddy://callback`
4. Copy your Client ID and Client Secret to the `.env` file

## 🏗️ Project Structure

```
lib/
├── constants/          # App-wide constants (colors, text styles)
├── providers/          # State management (auth provider)
├── screens/            # App screens
│   ├── on_boarding/    # Onboarding flow
│   ├── home_feed_screen.dart
│   ├── profile_screen.dart
│   ├── settings_screen.dart
│   └── splash_screen.dart
├── services/           # API services
│   ├── auth_service.dart
│   └── spotify_service.dart
├── theme/              # App theming
├── widgets/            # Reusable UI components
└── main.dart           # App entry point
```

## 🛠️ Tech Stack

- **Framework**: Flutter 3.5.4+
- **Language**: Dart
- **State Management**: Provider
- **HTTP Client**: http package
- **Secure Storage**: flutter_secure_storage
- **Environment Variables**: flutter_dotenv
- **URL Handling**: url_launcher
- **Connectivity**: connectivity_plus

## 📱 Supported Platforms

- ✅ iOS
- ✅ Android
- ✅ Web

## 🔧 Development

### Running Tests
```bash
flutter test
```

### Building for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Code Analysis
```bash
flutter analyze
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow the existing code style
- Write tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Spotify for providing the amazing API
- Flutter team for the excellent framework
- All contributors who help make this project better

## 📞 Support

If you encounter any issues or have questions:

- Open an issue on GitHub
- Join our community discussions

---

Made with ❤️