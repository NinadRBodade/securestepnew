# Backend Validation Test Script (PowerShell)
# Tests all validation endpoints with valid and invalid data

$BASE_URL = "http://localhost:3000/api"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Testing Backend Input Validation" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Registration with invalid name (contains numbers)
Write-Host "Test 1: Registration with invalid name (contains numbers)" -ForegroundColor Yellow
$body = @{
    name = "John123"
    email = "test@example.com"
    password = "Test1234"
    phone = "9876543210"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Registration with invalid email
Write-Host "Test 2: Registration with invalid email" -ForegroundColor Yellow
$body = @{
    name = "John Doe"
    email = "invalid-email"
    password = "Test1234"
    phone = "9876543210"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Registration with invalid phone (contains letters)
Write-Host "Test 3: Registration with invalid phone (contains letters)" -ForegroundColor Yellow
$body = @{
    name = "John Doe"
    email = "test@example.com"
    password = "Test1234"
    phone = "98765abc10"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 4: Registration with weak password (no uppercase)
Write-Host "Test 4: Registration with weak password (no uppercase)" -ForegroundColor Yellow
$body = @{
    name = "John Doe"
    email = "test@example.com"
    password = "test1234"
    phone = "9876543210"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 5: Registration with weak password (no lowercase)
Write-Host "Test 5: Registration with weak password (no lowercase)" -ForegroundColor Yellow
$body = @{
    name = "John Doe"
    email = "test@example.com"
    password = "TEST1234"
    phone = "9876543210"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 6: Registration with weak password (no number)
Write-Host "Test 6: Registration with weak password (no number)" -ForegroundColor Yellow
$body = @{
    name = "John Doe"
    email = "test@example.com"
    password = "TestPass"
    phone = "9876543210"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 7: Registration with weak password (too short)
Write-Host "Test 7: Registration with weak password (too short)" -ForegroundColor Yellow
$body = @{
    name = "John Doe"
    email = "test@example.com"
    password = "Test12"
    phone = "9876543210"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 8: Registration with invalid phone length
Write-Host "Test 8: Registration with invalid phone length (too short)" -ForegroundColor Yellow
$body = @{
    name = "John Doe"
    email = "test@example.com"
    password = "Test1234"
    phone = "98765"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 9: Valid registration (should succeed)
Write-Host "Test 9: Valid registration (should succeed)" -ForegroundColor Yellow
$body = @{
    name = "John Doe"
    email = "validuser@example.com"
    password = "Test1234"
    phone = "+919876543210"
    role = "resident"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/register" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 10: Login with invalid email
Write-Host "Test 10: Login with invalid email" -ForegroundColor Yellow
$body = @{
    email = "invalid-email"
    password = "Test1234"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/login" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 11: Valid login (should succeed)
Write-Host "Test 11: Valid login (should succeed)" -ForegroundColor Yellow
$body = @{
    email = "validuser@example.com"
    password = "Test1234"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/auth/login" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}
Write-Host ""

Write-Host "================================" -ForegroundColor Cyan
Write-Host "All tests completed!" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
