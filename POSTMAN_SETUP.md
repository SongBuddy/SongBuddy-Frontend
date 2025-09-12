# 🚀 Postman Setup for Spotify API Testing

## 📥 **Import Collection**

1. **Open Postman**
2. **Click Import** (top left)
3. **Select the `postman_collection.json` file** from this project
4. **Import** the collection

## 🔧 **Setup Variables**

### **1. Environment Variables**
Create a new environment called "SongBuddy Development":

```json
{
  "base_url": "https://api.spotify.com/v1",
  "auth_url": "https://accounts.spotify.com/api/token",
  "client_id": "35c4d18b83ff493c89595f74003e5265",
  "client_secret": "db95b99103ee4817bf6ea69d2c5dfffc",
  "access_token": ""
}
```

### **2. Base64 Encode Credentials**
For the Authorization header, you need to base64 encode your credentials:

**Format:** `client_id:client_secret`
**Your credentials:** `35c4d18b83ff493c89595f74003e5265:db95b99103ee4817bf6ea69d2c5dfffc`

**Base64 encoded:** `MzVjNGQxOGI4M2ZmNDkzYzg5NTk1Zjc0MDAzZTUyNjU6ZGI5NWI5OTEwM2VlNDgxN2JmNmVhNjlkMmM1ZGZmZmM=`

## 🧪 **Testing Steps**

### **Step 1: Get Client Credentials Token**
1. **Run** "Get Client Credentials Token" request
2. **Copy** the `access_token` from response
3. **Set** the `access_token` variable in your environment

### **Step 2: Test User Endpoints**
- **Get Current User Profile** - Requires user authentication (will fail with client credentials)
- **Get Currently Playing Track** - Requires user authentication
- **Get User's Playlists** - Requires user authentication
- **Get User's Top Tracks** - Requires user authentication
- **Get User's Top Artists** - Requires user authentication
- **Get User's Saved Tracks** - Requires user authentication

## ⚠️ **Important Notes**

### **Client Credentials vs User Authentication**
- **Client Credentials Token** - Can access public data only
- **User Authentication** - Required for user-specific data (playlists, top tracks, etc.)

### **For User Data Testing**
To test user-specific endpoints, you need to:
1. **Implement OAuth flow** in your app
2. **Get user authorization** 
3. **Exchange code for user token**
4. **Use user token** in Postman

## 🎯 **Expected Results**

### **Client Credentials Token Response:**
```json
{
  "access_token": "BQC...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

### **User Profile Response (with user token):**
```json
{
  "id": "user_id",
  "display_name": "User Name",
  "email": "user@example.com",
  "followers": {
    "total": 100
  },
  "images": [...]
}
```

## 🔍 **Troubleshooting**

### **401 Unauthorized**
- Check if credentials are correct
- Verify base64 encoding
- Ensure token is not expired

### **403 Forbidden**
- User token required for this endpoint
- Insufficient permissions/scopes

### **404 Not Found**
- Invalid endpoint URL
- Check API documentation

## 📚 **Next Steps**

1. **Test client credentials** authentication
2. **Implement OAuth flow** in your Flutter app
3. **Test user-specific** endpoints
4. **Integrate** with your SongBuddy app
