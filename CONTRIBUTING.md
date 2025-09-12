# 🤝 Contributing to SongBuddy

## 🚀 **Quick Start for Contributors**

### 1. Fork and Clone
```bash
git clone https://github.com/yourusername/SongBuddy.git
cd SongBuddy
```

### 2. Environment Setup
```bash
# Copy environment template
cp env.example .env

# Install dependencies
flutter pub get
```

### 3. Create Your Spotify App
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

### 4. Run the App
```bash
flutter run
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

### **Postman Testing**
- Import `postman_collection.json`
- Follow `POSTMAN_SETUP.md` guide
- Test your credentials before coding

### **App Testing**
- Test Spotify login button
- Verify API calls work
- Check error handling

## 📝 **Development Workflow**

1. **Create feature branch**
2. **Make changes**
3. **Test thoroughly**
4. **Create pull request**
5. **Get code review**
6. **Merge to main**

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
- [Project Setup Guide](SETUP.md)
- [Postman Testing Guide](POSTMAN_SETUP.md)

## ❓ **Need Help?**

- Check existing issues
- Ask in discussions
- Review documentation
- Test with Postman first
