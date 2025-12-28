# Script to create sample societies for testing

$BASE_URL = "http://localhost:3000/api"

Write-Host "Creating sample societies..." -ForegroundColor Cyan
Write-Host ""

$societies = @(
    @{
        name = "Green Valley Apartments"
        address = "123 Garden Road"
        city = "Mumbai"
        state = "Maharashtra"
        pincode = "400001"
        totalFlats = 150
    },
    @{
        name = "Sunrise Residency"
        address = "456 Sunrise Street"
        city = "Delhi"
        state = "Delhi"
        pincode = "110001"
        totalFlats = 200
    },
    @{
        name = "Palm Heights"
        address = "789 Palm Avenue"
        city = "Bangalore"
        state = "Karnataka"
        pincode = "560001"
        totalFlats = 100
    },
    @{
        name = "Royal Gardens"
        address = "321 Royal Road"
        city = "Pune"
        state = "Maharashtra"
        pincode = "411001"
        totalFlats = 180
    },
    @{
        name = "Ocean View Towers"
        address = "654 Ocean Drive"
        city = "Chennai"
        state = "Tamil Nadu"
        pincode = "600001"
        totalFlats = 250
    }
)

$successCount = 0
$failCount = 0

foreach ($society in $societies) {
    $body = $society | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$BASE_URL/society/create" -Method Post -Body $body -ContentType "application/json" -ErrorAction Stop
        Write-Host "✅ Created: $($society.name)" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "❌ Failed: $($society.name)" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Yellow
        $failCount++
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "Successfully created: $successCount societies" -ForegroundColor Green
Write-Host "Failed: $failCount societies" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verify by fetching the list
Write-Host "Fetching society list to verify..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/society/list" -Method Get -ErrorAction Stop
    Write-Host "✅ Found $($response.societies.Count) societies:" -ForegroundColor Green
    foreach ($society in $response.societies) {
        Write-Host "   - $($society.name) ($($society.city))" -ForegroundColor Gray
    }
} catch {
    Write-Host "❌ Failed to fetch societies" -ForegroundColor Red
}
