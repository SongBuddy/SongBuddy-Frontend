@echo off
echo Checking your follow status and feed...
echo.

set BACKEND_URL=http://192.168.83.108:3000
set USER_ID=31zyexjvpwecwru3w63q27hww5nu

echo ========================================
echo Step 1: Check Your Followers
echo ========================================
echo Getting your followers...
curl -X GET "%BACKEND_URL%/api/users/%USER_ID%/followers"
echo.
echo.

echo ========================================
echo Step 2: Check Your Following
echo ========================================
echo Getting users you follow...
curl -X GET "%BACKEND_URL%/api/users/%USER_ID%/following"
echo.
echo.

echo ========================================
echo Step 3: Check Feed Posts
echo ========================================
echo Getting your feed posts...
curl -X GET "%BACKEND_URL%/api/posts/feed/%USER_ID%?currentUserId=%USER_ID%"
echo.
echo.

echo ========================================
echo Step 4: Check All Posts (for debugging)
echo ========================================
echo Getting all posts in the system...
curl -X GET "%BACKEND_URL%/api/posts/search?limit=50"
echo.
echo.

echo ========================================
echo Debug Information
echo ========================================
echo.
echo If you see empty arrays [] for followers/following:
echo 1. You need to follow some users first
echo 2. Run create_feed_test_data.bat to create test users and follow them
echo.
echo If you see empty posts [] in feed:
echo 1. The users you follow don't have any posts
echo 2. Run create_feed_test_data.bat to create posts for followed users
echo.
echo If you see errors:
echo 1. Check if your backend is running
echo 2. Check if the API endpoints are working
echo.
pause
