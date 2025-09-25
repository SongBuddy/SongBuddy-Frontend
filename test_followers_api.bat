@echo off
echo Testing Followers API Endpoint...
echo.

REM Set your backend URL
set BACKEND_URL=http://192.168.83.108:3000

echo Testing backend health first...
curl -X GET "%BACKEND_URL%/health"
echo.
echo.

echo Testing followers endpoint with a test user...
echo.

REM Test with a simple user ID
curl -X GET "%BACKEND_URL%/api/users/test_user/followers?page=1&limit=20"
echo.
echo.

echo Testing with your actual user ID (replace YOUR_USER_ID with your real ID)...
curl -X GET "%BACKEND_URL%/api/users/YOUR_USER_ID/followers?page=1&limit=20"
echo.
echo.

echo Testing following endpoint...
curl -X GET "%BACKEND_URL%/api/users/YOUR_USER_ID/following?page=1&limit=20"
echo.
echo.

echo If you get 500 errors, the issue is in the backend code.
echo Check your backend logs for more details.
echo.
pause
