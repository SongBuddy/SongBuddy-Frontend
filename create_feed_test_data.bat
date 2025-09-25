@echo off
echo Creating test data for home feed...
echo.

set BACKEND_URL=http://192.168.83.108:3000

echo ========================================
echo Step 1: Create Test Users
echo ========================================

echo Creating Alice...
curl -X POST "%BACKEND_URL%/api/users" ^
     -H "Content-Type: application/json" ^
     -d "{\"id\":\"alice123\",\"displayName\":\"Alice Johnson\",\"username\":\"alice\",\"email\":\"alice@example.com\",\"profilePicture\":\"https://i.pravatar.cc/150?img=1\"}"
echo.

echo Creating Bob...
curl -X POST "%BACKEND_URL%/api/users" ^
     -H "Content-Type: application/json" ^
     -d "{\"id\":\"bob456\",\"displayName\":\"Bob Smith\",\"username\":\"bob\",\"email\":\"bob@example.com\",\"profilePicture\":\"https://i.pravatar.cc/150?img=2\"}"
echo.

echo Creating Charlie...
curl -X POST "%BACKEND_URL%/api/users" ^
     -H "Content-Type: application/json" ^
     -d "{\"id\":\"charlie789\",\"displayName\":\"Charlie Brown\",\"username\":\"charlie\",\"email\":\"charlie@example.com\",\"profilePicture\":\"https://i.pravatar.cc/150?img=3\"}"
echo.

echo ========================================
echo Step 2: Create Follow Relationships
echo ========================================

echo Following Alice...
curl -X POST "%BACKEND_URL%/api/users/alice123/follow" ^
     -H "Content-Type: application/json" ^
     -d "{\"followerId\":\"31zyexjvpwecwru3w63q27hww5nu\"}"
echo.

echo Following Bob...
curl -X POST "%BACKEND_URL%/api/users/bob456/follow" ^
     -H "Content-Type: application/json" ^
     -d "{\"followerId\":\"31zyexjvpwecwru3w63q27hww5nu\"}"
echo.

echo Following Charlie...
curl -X POST "%BACKEND_URL%/api/users/charlie789/follow" ^
     -H "Content-Type: application/json" ^
     -d "{\"followerId\":\"31zyexjvpwecwru3w63q27hww5nu\"}"
echo.

echo ========================================
echo Step 3: Create Posts for Followed Users
echo ========================================

echo Creating post for Alice...
curl -X POST "%BACKEND_URL%/api/posts" ^
     -H "Content-Type: application/json" ^
     -d "{\"userId\":\"alice123\",\"songName\":\"Blinding Lights\",\"artistName\":\"The Weeknd\",\"songImage\":\"https://i.scdn.co/image/ab67616d00001e02257c60eb99821fe397f817b2\",\"description\":\"This track always gives me a boost of energy 🚀🔥\"}"
echo.

echo Creating post for Bob...
curl -X POST "%BACKEND_URL%/api/posts" ^
     -H "Content-Type: application/json" ^
     -d "{\"userId\":\"bob456\",\"songName\":\"Levitating\",\"artistName\":\"Dua Lipa\",\"songImage\":\"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSDTJ4AuwUIeQ-wc-z78atPgem_s9RgBtGP_A&s\",\"description\":\"Perfect for dancing! 💃\"}"
echo.

echo Creating post for Charlie...
curl -X POST "%BACKEND_URL%/api/posts" ^
     -H "Content-Type: application/json" ^
     -d "{\"userId\":\"charlie789\",\"songName\":\"As It Was\",\"artistName\":\"Harry Styles\",\"songImage\":\"https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSF0Jqpe95kORYuGnJhSprCr8KG_WtwW8oS9Q&ss\",\"description\":\"Makes me feel nostalgic ✨\"}"
echo.

echo ========================================
echo Step 4: Test Feed API
echo ========================================

echo Testing feed API...
curl -X GET "%BACKEND_URL%/api/posts/feed/31zyexjvpwecwru3w63q27hww5nu?currentUserId=31zyexjvpwecwru3w63q27hww5nu"
echo.

echo ========================================
echo Test Data Creation Complete!
echo ========================================
echo.
echo You should now see 3 posts in your home feed:
echo - Alice: Blinding Lights by The Weeknd
echo - Bob: Levitating by Dua Lipa  
echo - Charlie: As It Was by Harry Styles
echo.
pause
