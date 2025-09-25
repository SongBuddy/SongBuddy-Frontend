@echo off
echo Testing Feed API directly...
echo.

set BACKEND_URL=http://192.168.83.108:3000
set USER_ID=31zyexjvpwecwru3w63q27hww5nu

echo ========================================
echo Testing Feed API Endpoint
echo ========================================
echo URL: %BACKEND_URL%/api/posts/feed/%USER_ID%?currentUserId=%USER_ID%
echo.

curl -X GET "%BACKEND_URL%/api/posts/feed/%USER_ID%?currentUserId=%USER_ID%" ^
     -H "Content-Type: application/json" ^
     -v
echo.
echo.

echo ========================================
echo Testing with Pretty Print
echo ========================================
curl -X GET "%BACKEND_URL%/api/posts/feed/%USER_ID%?currentUserId=%USER_ID%" ^
     -H "Content-Type: application/json" | python -m json.tool
echo.
echo.

echo ========================================
echo Debug Information
echo ========================================
echo.
echo Look for these in the response:
echo 1. Status code (should be 200)
echo 2. Response body structure
echo 3. Whether posts are in "posts" or "data" field
echo 4. Number of posts returned
echo.
echo If you see posts in the response but Flutter shows 0:
echo - Check the response structure in Flutter logs
echo - Verify the JSON parsing in BackendService
echo.
pause
