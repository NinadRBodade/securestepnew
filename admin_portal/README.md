# Admin Dashboard - Complete Guide

## 🎯 Overview
The Admin Dashboard is a comprehensive web-based control center for managing the entire SecureStep system including societies, guards, agents, and monitoring.

## 🚀 Quick Start

### Starting the Servers
```powershell
# Navigate to backend directory
cd backend

# Start both servers (run in separate terminals or as background jobs)
node src/server.js    # Backend API - Port 5001
node portal-server.js # Portal Server - Port 8080
```

### Access the Dashboard
Open your browser and navigate to:
```
http://localhost:8080/admin_portal/index.html
```

Or access the portal hub:
```
http://localhost:8080
```

## 📋 Features

### 1. Dashboard Home
- **Summary Statistics**
  - Total Societies count
  - Total Guards count
  - Pending Agents (awaiting verification)
  - Active Agents (verified and approved)
  - SOS Alerts count

- **Quick Actions**
  - Create New Society
  - Add Guard
  - View Pending Agents

### 2. Society Management
**Create Society:**
- Name (required)
- Full Address
- City, State, Pincode
- Auto-generated Society ID (format: SOC-YYYY-XXXX)

**View Societies:**
- List all societies with guard counts
- Click any society to view details

**Society Detail Page:**
- View society information
- **Guards Tab:** 
  - View all guards for this society
  - Add new guard
  - Enable/disable guards
- **Activity Logs Tab:** Coming soon

### 3. Guard Management
**Adding Guards:**
- Guards must be created within a society
- Click "Add Guard" from society detail page
- Required info: Name, Email, Phone
- System automatically:
  - Generates secure credentials
  - Creates guard account
  - Sends email with login details
  - Links guard to society (cannot be changed)

**Guard Credentials:**
- Email: As provided during creation
- Password: Auto-generated 8-character secure password
- Sent via email (logged to console in development)
- Guards must change password on first login

**Managing Guards:**
- Enable/Disable guard accounts
- View guard activity logs
- Guards remain linked to their society permanently

### 4. Agent Verification
**View All Agents:**
- Filter by status:
  - All Agents
  - Pending (not verified/rejected)
  - Verified (approved with trust score)
  - Rejected
- Search by name, email, or company

**Verify Agent:**
1. Click agent card or "Verify" button
2. Review agent details and documents
3. Set trust score (0-100)
4. Add verification notes
5. Approve or Reject

**Approved Agents:**
- Receive QR code for entry
- QR code contains:
  - Agent ID
  - Name, Email, Company
  - Trust Score
  - Verification status
  - Timestamp
- Download or print QR code

**QR Code Actions:**
- View: Display QR code with agent info
- Download: Save as PNG image
- Print: Direct print with agent details

### 5. System Monitoring (Read-Only)
**SOS Events:**
- View all emergency alerts
- Resident name and location
- Society information
- Alert status (active/resolved)
- Timestamp

**Guard Activity:** Coming soon
- Check-in/check-out logs
- Active patrol status
- Society assignments

**Agent Logs:** Coming soon
- Entry/exit records
- Visit duration
- Society visited

## 🔧 API Endpoints

### Societies
```
POST   /api/societies              - Create society
GET    /api/societies              - Get all societies
GET    /api/societies/:id          - Get society details
PUT    /api/societies/:id          - Update society
GET    /api/societies/:id/guards   - Get society guards
```

### Guards (Admin)
```
POST   /api/admin/guards/create       - Create guard
GET    /api/admin/guards              - Get all guards
PUT    /api/admin/guards/:id/status   - Enable/disable guard
```

### Agents
```
GET    /api/agents                      - Get all agents
POST   /api/agents/admin/verify/:email - Verify agent
POST   /api/agents/admin/reject/:email - Reject agent
```

### Monitoring
```
GET    /api/sos                    - Get SOS alerts
```

## 📁 File Structure
```
admin_portal/
├── index.html      - Complete dashboard UI
├── styles.css      - Responsive styling
└── script.js       - Full JavaScript logic

backend/
├── src/
│   ├── models/
│   │   ├── Society.js               - Society model with auto-ID
│   │   └── Guard.js                 - Guard model
│   ├── controllers/
│   │   ├── society.controller.js    - Society operations
│   │   └── admin.guard.controller.js - Guard management
│   └── routes/
│       ├── society.routes.js         - Society routes
│       └── admin.guard.routes.js     - Admin guard routes
└── portal-server.js                  - Serves static portal files
```

## 🔐 Security Notes

1. **Admin Access:** Web-only, no mobile app access
2. **Guard Credentials:** Auto-generated, sent via email
3. **Guard-Society Link:** Immutable after creation
4. **Agent QR Codes:** Only generated after verification
5. **Monitoring:** Read-only access to logs

## 🎨 UI Features

**Responsive Design:**
- Desktop: Full sidebar navigation
- Mobile: Collapsible menu, stacked cards

**Animations:**
- Smooth section transitions
- Modal slide-up effects
- Hover effects on cards
- Loading states

**Color Coding:**
- Primary: Purple gradient (#667eea to #764ba2)
- Success: Green (#48bb78)
- Danger: Red (#f56565)
- Info: Light blue (#e3f2fd)

## 🐛 Troubleshooting

**Dashboard not loading:**
```powershell
# Check if servers are running
Get-NetTCPConnection -LocalPort 5001,8080 -State Listen

# Restart servers if needed
Stop-Process -Name node -Force
# Then start again
```

**Can't create society:**
- Check backend logs for errors
- Verify MongoDB connection
- Ensure all required fields filled

**Guard credentials not sending:**
- Email service not configured (development mode)
- Check console logs for credentials
- Manually provide to guard

**Society ID not auto-generating:**
- Check MongoDB connection
- Verify Society model pre-save hook
- Check for duplicate IDs

## 📊 Data Flow

1. **Society Creation:**
   - Admin fills form → POST /api/societies
   - Server generates Society ID (SOC-YYYY-XXXX)
   - Saves to MongoDB → Returns society object
   - Dashboard updates list

2. **Guard Creation:**
   - Admin selects society → Clicks "Add Guard"
   - Fills form → POST /api/admin/guards/create
   - Server generates password → Creates guard
   - Updates society guard count
   - Logs credentials → Sends email (TODO)
   - Dashboard updates guard list

3. **Agent Verification:**
   - Admin reviews agent → Sets score and notes
   - POST /api/agents/admin/verify/:email
   - Server updates agent status
   - Generates QR data → Returns success
   - Dashboard shows QR code option

## 🔄 Auto-Refresh
- Dashboard stats refresh every 60 seconds
- Manual refresh available for data tables

## 📱 Mobile Access
- Fully responsive design
- Touch-optimized interactions
- Optimized for tablets and phones

## ✅ Testing

**Create Test Society:**
```javascript
POST http://localhost:5001/api/societies
{
  "name": "Test Society",
  "address": "123 Main St",
  "city": "Mumbai",
  "state": "Maharashtra",
  "pincode": "400001"
}
```

**Add Test Guard:**
```javascript
POST http://localhost:5001/api/admin/guards/create
{
  "name": "John Guard",
  "email": "john.guard@test.com",
  "phone": "1234567890",
  "societyId": "SOCIETY_ID_HERE"
}
```

## 🚧 Coming Soon

1. **Email Integration:** Auto-send guard credentials
2. **Activity Logs:** Guard and agent tracking
3. **Admin Authentication:** Login system
4. **Advanced Filters:** Date ranges, status filters
5. **Export Data:** CSV/PDF reports
6. **Bulk Operations:** Multiple guard creation
7. **Guard Performance:** Metrics and analytics

## 📞 Support

For issues or questions:
1. Check server logs: `node src/server.js` output
2. Check browser console (F12)
3. Verify MongoDB connection
4. Review this guide

## 🎉 Success Indicators

✅ Both servers running (ports 5001 & 8080)
✅ Dashboard loads without errors
✅ Can create societies with auto-generated IDs
✅ Can add guards with credentials logged
✅ Can verify/reject agents
✅ Can view SOS monitoring data
✅ All modals open/close properly
✅ Navigation works smoothly

---

**Last Updated:** 2024
**Version:** 1.0.0
**Platform:** Web (Chrome/Firefox/Safari recommended)
