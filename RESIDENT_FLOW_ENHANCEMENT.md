# Resident Signup Flow Enhancement - Implementation Summary

## Overview
Enhanced the resident registration flow to distinguish between independent house residents and society residents, with proper MongoDB integration for society management.

## Changes Made

### 1. Backend - Society Model & Routes

**File:** `backend/src/models/Society.js` (NEW)
- Created Society schema with fields:
  - name (required)
  - address, city, state, pincode
  - totalFlats
  - isActive (default: true)

**File:** `backend/src/routes/society.routes.js` (UPDATED)
- `GET /api/society/list` - Fetch all active societies (sorted by name)
- `POST /api/society/create` - Create new society (for testing/admin)

**File:** `backend/src/server.js` (UPDATED)
- Changed route from `/api/societies` to `/api/society`

### 2. Frontend - Enhanced Registration Flow

**File:** `lib/screens/register_screen.dart` (UPDATED)

**New State Variables:**
- `_residentType` - 'independent' or 'society'
- `_selectedSocietyId` - MongoDB ObjectId of selected society
- `_selectedSocietyName` - Display name of selected society
- `_societies` - List of societies fetched from backend
- `_isLoadingSocieties` - Loading state for society fetch

**New Methods:**
- `_fetchSocieties()` - Fetches societies from API
- `_showSocietyPicker()` - Shows searchable bottom sheet with society list

**Enhanced UI Flow:**

1. **Role Selection** - User selects "Resident"

2. **Resident Type Selection** - Two button options:
   - **Independent House** - Green house icon
   - **Society Resident** - Apartment icon

3. **Independent House Path:**
   - No additional fields required
   - `societyId` = null
   - `flatNumber` = null
   - SOS will go ONLY to police

4. **Society Resident Path:**
   - Shows society picker button
   - Opens searchable bottom sheet with society list
   - User selects their society from dropdown
   - Flat number field becomes REQUIRED
   - SOS will go to guard + police

**Registration Logic:**
```dart
if (role == 'resident') {
  if (residentType == 'society') {
    societyId = selectedSocietyId (from MongoDB)
    flatNumber = user input (required)
  } else {
    societyId = null
    flatNumber = null
  }
} else {
  // Other roles (agent, guard, admin) - unchanged
  societyId = optional text input
  flatNumber = optional text input
}
```

### 3. Validation Rules

**For Resident Role:**
- Must select resident type (independent or society)
- If society resident:
  - Must select a society from dropdown
  - Must enter flat/house number

**For Other Roles:**
- No changes to existing behavior
- Society and flat fields remain optional text inputs

## Testing

### 1. Seed Sample Societies
```powershell
cd backend
.\seed-societies.ps1
```

This creates 5 sample societies:
- Green Valley Apartments (Mumbai)
- Sunrise Residency (Delhi)
- Palm Heights (Bangalore)
- Royal Gardens (Pune)
- Ocean View Towers (Chennai)

### 2. Test Registration Flow

**Independent House Resident:**
1. Register as Resident
2. Select "Independent House"
3. Complete registration
4. Verify: societyId is null in MongoDB

**Society Resident:**
1. Register as Resident
2. Select "Society Resident"
3. Select society from dropdown
4. Enter flat number (required)
5. Complete registration
6. Verify: societyId contains MongoDB ObjectId

### 3. Test SOS Flow
- Independent house resident → SOS to police only
- Society resident → SOS to guard + police

## Database Structure

**User Collection:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+919876543210",
  "role": "resident",
  "societyId": null,  // null for independent, ObjectId for society
  "flatNumber": null, // null for independent, "A-101" for society
  "emergencyPreference": "both"
}
```

**Society Collection:**
```json
{
  "_id": ObjectId("..."),
  "name": "Green Valley Apartments",
  "address": "123 Garden Road",
  "city": "Mumbai",
  "state": "Maharashtra",
  "pincode": "400001",
  "totalFlats": 150,
  "isActive": true,
  "createdAt": "2025-12-26T...",
  "updatedAt": "2025-12-26T..."
}
```

## UI Components

**Resident Type Buttons:**
- Side-by-side outlined buttons
- Active state: Filled with primary color
- Inactive state: Outlined with white background
- Icons: house (independent) and apartment (society)

**Society Picker:**
- Modal bottom sheet
- Draggable scroll sheet (70% height)
- Search functionality
- List with society name and city
- Avatar icons for each society

## Benefits

1. **Clear User Flow** - Explicit choice for residents
2. **Data Integrity** - Proper MongoDB references for societies
3. **Flexible SOS** - Different routing based on resident type
4. **Scalability** - Easy to add more societies via admin
5. **No Breaking Changes** - Other roles unaffected

## Files Modified

1. `backend/src/models/Society.js` (NEW)
2. `backend/src/routes/society.routes.js` (UPDATED)
3. `backend/src/server.js` (UPDATED)
4. `lib/screens/register_screen.dart` (UPDATED)
5. `backend/seed-societies.ps1` (NEW - test data)

## Notes

- No new UI screens added (reused existing components)
- Agent, Guard, Admin roles unchanged
- MongoDB persistence for societies
- Searchable dropdown for better UX
- Validation at both frontend and backend
