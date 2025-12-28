# 👮 Agent Verification Portal

## Overview
Web-based portal for society administrators to verify delivery and service agents. Provides a comprehensive interface to review agent applications, verify documents, approve/reject agents, and generate QR codes for verified agents.

## ✨ Features

### Agent Management
- **View All Agents**: See all registered agents with their status (Pending, Verified, Rejected)
- **Filter by Status**: Quickly filter agents by verification status
- **Search Functionality**: Search agents by name, email, company, or phone
- **Real-time Statistics**: Dashboard shows pending, verified, rejected, and total agent counts

### Agent Verification
- **Document Review**: View uploaded ID proof, photos, and certificates
- **Trust Score System**: Assign trust scores (0-100) to verified agents
- **Verification Notes**: Add notes during the verification process
- **Approve/Reject**: One-click approval or rejection of agent applications

### QR Code Generation
- **Auto-generate QR**: Verified agents automatically get QR codes
- **View QR Code**: Display agent QR code with details
- **Download QR**: Download QR code as PNG image
- **Print QR**: Print QR code with agent information

### User Interface
- **Modern Design**: Clean, professional interface with smooth animations
- **Responsive**: Works on desktop, tablet, and mobile devices
- **Real-time Updates**: Auto-refresh every 60 seconds
- **Status Indicators**: Color-coded badges for quick status identification

## 🚀 Getting Started

### Prerequisites
- Node.js backend running on http://localhost:5001
- MongoDB database with agent collection
- Modern web browser (Chrome, Firefox, Safari, Edge)

### Setup

1. **Start the Backend Server**
   ```bash
   cd backend
   npm start
   ```

2. **Open the Portal**
   - Open `index.html` in your web browser
   - Or serve it using a local web server:
   ```bash
   # Using Python
   python -m http.server 8080
   
   # Using Node.js http-server
   npx http-server -p 8080
   ```

3. **Access the Portal**
   - Open browser and go to: `http://localhost:8080/agent_portal/`

### Configuration

Edit the `CONFIG` object in `script.js` to match your backend URL:

```javascript
const CONFIG = {
    API_BASE_URL: 'http://localhost:5001/api',
    DEFAULT_SCORE: 75
};
```

## 📋 Usage Guide

### Viewing Agents

1. **Dashboard Overview**
   - See statistics at the top (Pending, Verified, Rejected, Total)
   - All agents are displayed in card format with photos and details

2. **Filter Agents**
   - Click filter buttons: "All Agents", "Pending", "Verified", "Rejected"
   - Use search box to find specific agents

3. **View Details**
   - Click on any agent card to view full details
   - Review documents (ID proof, certificates)
   - See registration date and contact information

### Verifying Agents

1. **Select Agent**
   - Click "Verify" button on pending agent
   - Or open agent details and click "Verify Agent"

2. **Set Trust Score**
   - Adjust score slider (0-100)
   - Higher scores indicate more trustworthy agents
   - Visual indicator shows score level

3. **Add Notes** (Optional)
   - Add verification notes or comments
   - Notes are saved for future reference

4. **Approve**
   - Click "✅ Approve & Generate QR"
   - Agent status changes to "Verified"
   - QR code is automatically generated

### Rejecting Agents

1. **Reject Application**
   - Click "❌ Reject" on agent card
   - Or open agent details and click reject
   - Confirm rejection when prompted

2. **Result**
   - Agent status changes to "Rejected"
   - Agent cannot access the system

### Managing QR Codes

1. **View QR Code**
   - Click "📱 View QR Code" on verified agent
   - QR code displays with agent information

2. **Download QR**
   - Click "Download QR" button
   - QR code saves as PNG image
   - Filename: `agent-qr-{email}.png`

3. **Print QR**
   - Click "Print QR" button
   - Print-friendly page opens
   - Includes agent details and QR code

## 🔌 API Endpoints Used

### GET /api/agents
Fetches all registered agents
- **Response**: `{ agents: [...] }`

### POST /api/agents/admin/verify/:email
Verifies an agent and generates QR code
- **Body**: `{ score: 75, notes: "Verified documents" }`
- **Response**: `{ success: true, agent: {...} }`

### POST /api/agents/admin/reject/:email
Rejects an agent application
- **Response**: `{ success: true }`

## 🎨 UI Components

### Status Badges
- 🟢 **Verified**: Green badge with checkmark
- 🟠 **Pending**: Orange badge with clock
- 🔴 **Rejected**: Red badge with X

### Trust Score
- **0-40**: Low trust (Red zone)
- **41-70**: Medium trust (Orange zone)
- **71-100**: High trust (Green zone)

### Agent Cards
- Photo thumbnail
- Name and status badges
- Contact information (email, phone)
- Company and registration date
- Quick action buttons

## 🔧 Troubleshooting

### Agents Not Loading
1. Check if backend server is running
2. Verify API_BASE_URL in script.js
3. Check browser console for errors
4. Ensure MongoDB is running

### QR Code Not Generating
1. Ensure agent is verified
2. Check QRCode.js library is loaded
3. Clear browser cache and reload

### Images Not Displaying
1. Verify file paths in backend
2. Check CORS settings on backend
3. Ensure uploads folder is accessible

## 📱 Mobile Support

The portal is fully responsive and works on mobile devices:
- Touch-friendly buttons
- Responsive grid layout
- Mobile-optimized modals
- Swipe-friendly cards

## 🔒 Security Notes

- This portal should be protected with authentication
- Only authorized administrators should access it
- Consider implementing role-based access control
- Use HTTPS in production
- Validate all inputs on backend

## 🎯 Future Enhancements

- [ ] Admin authentication system
- [ ] Agent activity logs
- [ ] Bulk operations (verify/reject multiple)
- [ ] Export agent list to CSV/PDF
- [ ] Email notifications to agents
- [ ] Agent performance analytics
- [ ] Facial recognition integration
- [ ] Document verification AI

## 📄 License

Part of SecureStep Society Management System

---

**Built with ❤️ for efficient agent management**
