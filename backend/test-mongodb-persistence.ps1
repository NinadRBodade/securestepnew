# MongoDB Persistence Test Script
# This script tests that registration and login work with MongoDB persistence

$BASE_URL = "http://localhost:3000/api"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MongoDB Persistence & Duplicate Check Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Register a new user
Write-Host "Test 1: Register new user (should succeed)" -ForegroundColor Yellow
$body = @{
    name = "John Doe"
    email = "john.doe@test.com"
    password = "Test1234"
    phone = "+919876543210"
    role = "resident"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "✅ SUCCESS: User registered" -ForegroundColor Green
    Write-Host "User ID: $($response.user.id)" -ForegroundColor Gray
    Write-Host "Token received: $($response.token.Substring(0, 30))..." -ForegroundColor Gray
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Try to register with same email (should fail)
Write-Host "Test 2: Register with same email (should fail with 'already registered')" -ForegroundColor Yellow
$body = @{
    name = "Jane Doe"
    email = "john.doe@test.com"
    password = "Different1234"
    phone = "+919876543211"
    role = "resident"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "❌ FAILED: Should have rejected duplicate email" -ForegroundColor Red
} catch {
    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    if ($errorResponse.message -eq "User already registered. Please login.") {
        Write-Host "✅ SUCCESS: Correctly rejected duplicate email" -ForegroundColor Green
        Write-Host "Message: $($errorResponse.message)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  WARNING: Wrong error message" -ForegroundColor Yellow
        Write-Host "Expected: 'User already registered. Please login.'" -ForegroundColor Gray
        Write-Host "Got: $($errorResponse.message)" -ForegroundColor Gray
    }
}
Write-Host ""

# Test 3: Try to register with same phone (should fail)
Write-Host "Test 3: Register with same phone (should fail with 'already registered')" -ForegroundColor Yellow
$body = @{
    name = "Jane Smith"
    email = "jane.smith@test.com"
    password = "Test1234"
    phone = "+919876543210"
    role = "resident"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "❌ FAILED: Should have rejected duplicate phone" -ForegroundColor Red
} catch {
    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    if ($errorResponse.message -eq "User already registered. Please login.") {
        Write-Host "✅ SUCCESS: Correctly rejected duplicate phone" -ForegroundColor Green
        Write-Host "Message: $($errorResponse.message)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  WARNING: Wrong error message" -ForegroundColor Yellow
        Write-Host "Expected: 'User already registered. Please login.'" -ForegroundColor Gray
        Write-Host "Got: $($errorResponse.message)" -ForegroundColor Gray
    }
}
Write-Host ""

# Test 4: Login with registered user (should succeed)
Write-Host "Test 4: Login with registered user (should succeed)" -ForegroundColor Yellow
$body = @{
    email = "john.doe@test.com"
    password = "Test1234"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/login" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "✅ SUCCESS: Login successful" -ForegroundColor Green
    Write-Host "User: $($response.user.name) ($($response.user.email))" -ForegroundColor Gray
    Write-Host "Role: $($response.user.role)" -ForegroundColor Gray
    Write-Host "Token received: $($response.token.Substring(0, 30))..." -ForegroundColor Gray
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 5: Login with wrong password (should fail)
Write-Host "Test 5: Login with wrong password (should fail)" -ForegroundColor Yellow
$body = @{
    email = "john.doe@test.com"
    password = "WrongPassword123"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/login" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "❌ FAILED: Should have rejected wrong password" -ForegroundColor Red
} catch {
    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    if ($errorResponse.message -eq "Invalid email or password") {
        Write-Host "✅ SUCCESS: Correctly rejected wrong password" -ForegroundColor Green
        Write-Host "Message: $($errorResponse.message)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  WARNING: Wrong error message" -ForegroundColor Yellow
        Write-Host "Got: $($errorResponse.message)" -ForegroundColor Gray
    }
}
Write-Host ""

# Test 6: Login with non-existent user (should fail)
Write-Host "Test 6: Login with non-existent user (should fail)" -ForegroundColor Yellow
$body = @{
    email = "nonexistent@test.com"
    password = "Test1234"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/login" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "❌ FAILED: Should have rejected non-existent user" -ForegroundColor Red
} catch {
    $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json
    if ($errorResponse.message -eq "Invalid email or password") {
        Write-Host "✅ SUCCESS: Correctly rejected non-existent user" -ForegroundColor Green
        Write-Host "Message: $($errorResponse.message)" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  WARNING: Wrong error message" -ForegroundColor Yellow
        Write-Host "Got: $($errorResponse.message)" -ForegroundColor Gray
    }
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Persistence Test Instructions:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. After running these tests, RESTART the backend server" -ForegroundColor White
Write-Host "2. Then run Test 4 again (login test)" -ForegroundColor White
Write-Host "3. If login still works after restart, MongoDB persistence is confirmed!" -ForegroundColor White
Write-Host ""
Write-Host "Quick restart & retest command:" -ForegroundColor Yellow
Write-Host "Restart backend, then run:" -ForegroundColor Gray
Write-Host '$body = @{email = "john.doe@test.com"; password = "Test1234"} | ConvertTo-Json' -ForegroundColor Cyan
Write-Host 'Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" -Method Post -Body $body -ContentType "application/json"' -ForegroundColor Cyan
Write-Host ""
