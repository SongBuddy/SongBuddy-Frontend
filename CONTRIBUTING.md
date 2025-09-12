# 🤝 Contributing to SongBuddy

## 🚀 **Quick Start for Contributors**

### 1. Fork and Clone
1. **Fork the repository** on GitHub
2. **Clone your fork:**
```bash
git clone https://github.com/YOUR_USERNAME/SongBuddy.git
cd SongBuddy
```
3. **Add upstream remote:**
```bash
git remote add upstream https://github.com/mohammadaminrez/SongBuddy.git
```

### 2. Prerequisites
- **Flutter SDK**: Version 3.5.4 or higher
- **Dart SDK**: Included with Flutter
- **IDE**: VS Code or Android Studio (recommended)
- **Git**: For version control

### 3. Environment Setup
```bash
# Copy environment template
cp env.example .env

# Install dependencies
flutter pub get

# Verify Flutter installation
flutter doctor
```

### 4. Create Your Spotify App
**Each contributor needs their own Spotify app:**

1. **Go to** [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/applications)
2. **Create App** with these settings:
   - **App name**: `SongBuddy-YourName`
   - **Description**: `Social music app - development`
   - **Redirect URI**: `songbuddy://callback`
   - **APIs**: Web API, Android
   - **Package Name**: `com.songbuddy.app`
   - **SHA1**: `B0:E2:69:77:43:3F:55:44:E2:39:51:E7:74:24:73:8E:B1:C1:74:14`

3. **Update your `.env` file:**
   ```env
   SPOTIFY_CLIENT_ID=your_client_id_here
   SPOTIFY_CLIENT_SECRET=your_client_secret_here
   SPOTIFY_REDIRECT_URI=songbuddy://callback
   ```

### 5. Run the App
```bash
# For development
flutter run

# For specific platform
flutter run -d android  # Android
flutter run -d ios      # iOS (macOS only)
flutter run -d chrome   # Web
```

## 🔒 **Security Guidelines**

### **❌ NEVER Do:**
- Share your `.env` file
- Commit real credentials to Git
- Share your Client Secret
- Use production credentials for development

### **✅ ALWAYS Do:**
- Use your own Spotify app
- Keep credentials secure
- Test with development credentials
- Follow the setup guide

## 🧪 **Testing**

### **Manual Testing**
- Test Spotify login button functionality
- Verify API calls work correctly
- Check error handling scenarios
- Test on different platforms (Android/iOS/Web)

### **Running Tests**
```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Check code coverage
flutter test --coverage
```

## 📝 **Development Workflow**

1. **Create feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes** following code style guidelines

3. **Test thoroughly** on multiple platforms

4. **Commit changes:**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

5. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create pull request** on GitHub

7. **Get code review** and address feedback

8. **Merge to main** after approval

## 🎨 **Code Style Guidelines**

### **Dart/Flutter Standards**
- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter_lints` package (already configured)
- Run `flutter analyze` before committing
- Use meaningful variable and function names
- Add comments for complex logic

### **File Organization**
- Keep files under 200 lines when possible
- Use proper folder structure (`lib/screens/`, `lib/widgets/`, etc.)
- Follow existing naming conventions

### **Commit Messages**
Use [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation
- `style:` for formatting changes
- `refactor:` for code refactoring
- `test:` for adding tests

## 🔧 **Troubleshooting**

### **Common Issues**

**Flutter Doctor Issues:**
```bash
# Fix common Flutter issues
flutter doctor --android-licenses
flutter clean
flutter pub get
```

**Spotify Authentication Issues:**
- Verify your `.env` file has correct credentials
- Check redirect URI matches Spotify dashboard
- Ensure SHA1 fingerprint is correct for Android

**Build Issues:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**Platform-Specific Issues:**
- **Android**: Check Android SDK installation
- **iOS**: Verify Xcode installation (macOS only)
- **Web**: Ensure Chrome is installed

## 🐛 **Reporting Issues**

- Use GitHub Issues
- Include steps to reproduce
- Provide error logs
- Include device/OS info

## 💡 **Feature Ideas**

- Spotify integration improvements
- UI/UX enhancements
- Performance optimizations
- New social features

## 📚 **Resources**

- [Spotify Web API Documentation](https://developer.spotify.com/documentation/web-api/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Flutter Lints Package](https://pub.dev/packages/flutter_lints)

## ❓ **Need Help?**

- Check existing [GitHub Issues](https://github.com/mohammadaminrez/SongBuddy/issues)
- Ask in [GitHub Discussions](https://github.com/mohammadaminrez/SongBuddy/discussions)
- Review Flutter and Spotify documentation
- Test your Spotify credentials manually first
- Run `flutter doctor` to check your setup
