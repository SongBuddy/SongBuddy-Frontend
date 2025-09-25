@echo off
echo Testing Followers API to debug backend issue...
echo.

set BACKEND_URL=http://192.168.83.108:3000

echo ========================================
echo Testing Backend Health
echo ========================================
curl -X GET "%BACKEND_URL%/health"
echo.
echo.

echo ========================================
echo Testing Followers API with your user ID
echo ========================================
echo Testing with user ID: 31zyexjvpwecwru3w63q27hww5nu
curl -X GET "%BACKEND_URL%/api/users/31zyexjvpwecwru3w63q27hww5nu/followers?page=1&limit=20"
echo.
echo.

echo ========================================
echo Testing Following API with your user ID
echo ========================================
curl -X GET "%BACKEND_URL%/api/users/31zyexjvpwecwru3w63q27hww5nu/following?page=1&limit=20"
echo.
echo.

echo ========================================
echo Testing with a simple user ID
echo ========================================
curl -X GET "%BACKEND_URL%/api/users/test_user/followers?page=1&limit=20"
echo.
echo.

echo ========================================
echo Testing Follow Status API
echo ========================================
curl -X GET "%BACKEND_URL%/api/users/31zyexjvpwecwru3w63q27hww5nu/follow-status?currentUserId=31zyexjvpwecwru3w63q27hww5nu"
echo.
echo.

echo ========================================
echo Debug Information
echo ========================================
echo.
echo If you see 500 errors with "Cannot read properties of undefined (reading 'length')":
echo 1. The issue is in your backend code
echo 2. Check your backend console logs for more details
echo 3. The backend is trying to access .length on an undefined array
echo 4. Fix: Add null checks in your backend code
echo.
echo Common fixes:
echo - Add: const followers = await getFollowersFromDB(userId) || [];
echo - Add: if (!Array.isArray(followers)) return [];
echo - Add: const safeFollowers = followers ? followers : [];
echo.
pause
