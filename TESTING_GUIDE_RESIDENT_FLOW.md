# Quick Start Guide: Testing Enhanced Resident Flow

## Step 1: Start Backend
```powershell
cd backend
npm start
```
Wait for "✅ MongoDB connected successfully"

## Step 2: Seed Sample Societies
```powershell
# In a new terminal
cd backend
.\seed-societies.ps1
```

You should see:
```
✅ Created: Green Valley Apartments
✅ Created: Sunrise Residency
✅ Created: Palm Heights
✅ Created: Royal Gardens
✅ Created: Ocean View Towers
```

## Step 3: Start Flutter App
```powershell
# In a new terminal
flutter run
```

## Step 4: Test Independent House Flow

1. Open the app
2. Tap "Register" or "Create Account"
3. Fill in basic details:
   - Name: Test User
   - Email: test@example.com
   - Phone: 9876543210
   - Password: Test1234
4. Select Role: **Resident**
5. You'll see: "Do you live in a society?"
6. Tap **Independent House** button
7. Tap "Register"

**Expected Result:**
- ✅ Registration successful
- ✅ In MongoDB: `societyId: null`, `flatNumber: null`

## Step 5: Test Society Resident Flow

1. Open the app
2. Tap "Register"
3. Fill in basic details:
   - Name: Society User
   - Email: society@example.com
   - Phone: 9876543211
   - Password: Test1234
4. Select Role: **Resident**
5. Tap **Society Resident** button
6. A button appears: "Select Your Society"
7. Tap the button → Bottom sheet opens with society list
8. Select a society (e.g., "Green Valley Apartments")
9. Enter Flat Number: A-101
10. Tap "Register"

**Expected Result:**
- ✅ Registration successful
- ✅ In MongoDB: `societyId: "<ObjectId>"`, `flatNumber: "A-101"`

## Step 6: Verify in MongoDB

### Using MongoDB Compass or Shell:
```javascript
// View all users
db.users.find().pretty()

// Check independent house user
db.users.findOne({ email: "test@example.com" })
// Should have: societyId: null

// Check society resident
db.users.findOne({ email: "society@example.com" })
// Should have: societyId: "ObjectId(...)"

// View all societies
db.societies.find().pretty()
```

## Step 7: Test Login

1. Login with independent house user:
   - Email: test@example.com
   - Password: Test1234
   
2. Login with society resident:
   - Email: society@example.com
   - Password: Test1234

**Both should work!**

## Verification Checklist

- [ ] Backend starts without errors
- [ ] Societies seeded successfully
- [ ] Flutter app runs
- [ ] Independent house registration works
- [ ] Society resident registration works
- [ ] Society dropdown shows all societies
- [ ] Flat number required for society residents
- [ ] MongoDB has correct data
- [ ] Login works for both types
- [ ] Validation works (try submitting without society)

## Common Issues

### Issue: "Could not load societies"
**Solution:** Check backend is running and `/api/society/list` endpoint works

### Issue: Empty society dropdown
**Solution:** Run seed-societies.ps1 script

### Issue: "Please select your society"
**Solution:** This is correct! You must select from dropdown

### Issue: Registration fails
**Solution:** Check backend logs for error messages

## API Endpoints to Test

```powershell
# Get societies list
Invoke-RestMethod -Uri "http://localhost:3000/api/society/list"

# Create a new society
$body = @{
    name = "Test Society"
    city = "Mumbai"
} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:3000/api/society/create" -Method Post -Body $body -ContentType "application/json"
```

## Success Indicators

✅ **Independent House User:**
- Registered without selecting society
- No society picker shown
- `societyId` is null in DB
- Can login successfully

✅ **Society Resident:**
- Must select society from dropdown
- Flat number is required
- `societyId` has MongoDB ObjectId in DB
- Can login successfully

✅ **Other Roles (Agent, Guard, Admin):**
- Not affected by changes
- Optional society text field still works
