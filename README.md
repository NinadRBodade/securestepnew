# SecureStep - Society Safety System

A comprehensive real-time safety and verification system designed for residential societies, providing emergency response, resident verification, and multi-stakeholder coordination through mobile apps and web portals.

## 📋 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)
- [Installation & Setup](#installation--setup)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [API Endpoints](#api-endpoints)
- [User Roles](#user-roles)
- [Features Documentation](#features-documentation)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

---

## 🎯 Overview

**SecureStep** is a multi-platform safety system that enables residents of societies to request emergency assistance, verify themselves through face recognition, and allows guards, agents, and police to respond efficiently. The system features real-time tracking, QR code scanning for offline verification, and blockchain integration for immutable records.

### Problem Statement
Residential societies need a unified platform for:
- Emergency SOS requests with real-time tracking
- Resident verification and gate access control
- Guard and agent management
- Police coordination for serious incidents
- Offline functionality for areas with poor connectivity

### Solution
A mobile-first application with web portals that enables:
- Residents to request help with location tracking
- Verification through face recognition and QR codes
- Real-time notification system via Socket.IO
- Multi-stakeholder coordination (residents, guards, agents, police)
- Offline QR code generation and scanning capability

---

## ✨ Key Features

### Resident Features
- **SOS Emergency Request**: Send distress signals with real-time location
- **SOS History**: Track past emergency requests and responses
- **Face Recognition**: Biometric verification for secure access
- **QR Code Scanning**: Verify credentials at gates
- **Complaint Management**: File and track complaints
- **Emergency Contacts**: Maintain list of emergency contacts
- **Profile Management**: Update personal information and preferences
- **Offline Support**: Generate offline QR codes for verification

### Guard Features
- **Real-Time Alerts**: Receive SOS notifications instantly
- **Resident Verification**: Scan QR codes or use face recognition
- **Job Management**: Accept and complete verification tasks
- **Document Upload**: Submit identification and certification documents
- **Status Updates**: Mark emergencies as acknowledged/resolved
- **Offline Queue**: Queue actions offline, sync when online

### Agent Features
- **Society Management**: Register and manage multiple societies
- **SOS Monitoring**: Track all emergencies in assigned societies
- **Guard Management**: Register and manage guards
- **Reporting**: View analytics and incident reports
- **Document Management**: Handle uploaded guard certifications

### Police Portal
- **Incident Dashboard**: Real-time view of all incidents
- **Map View**: Visualize emergency locations
- **Alert Details**: Access comprehensive incident information
- **Unit Dispatch**: Send police units to incidents
- **Status Tracking**: Monitor response status

### Admin Portal
- **System Management**: Oversee all users and societies
- **Analytics Dashboard**: View system statistics
- **User Management**: Create, edit, and manage all users
- **Society Configuration**: Set up new societies and agents

---

## 🏗️ Architecture

### System Architecture
```
┌─────────────────┐
│  Mobile App     │  (Flutter - iOS/Android)
│  (Residents,    │
│   Guards)       │
└────────┬────────┘
         │
         ├──────────────────┐
         │                  │
    ┌────▼────┐      ┌─────▼──────┐
    │  REST   │      │  Socket.IO │
    │   API   │      │  (Real-time)│
    └────┬────┘      └─────┬──────┘
         │                  │
         └──────────┬───────┘
                    │
         ┌──────────▼──────────┐
         │   Backend Server    │
         │   (Node.js/Express) │
         └──────────┬──────────┘
                    │
        ┌───────────┼──────────┐
        │           │          │
   ┌────▼────┐  ┌──▼────┐  ┌──▼──────┐
   │ MongoDB  │  │ Redis │  │Blockchain│
   │Database  │  │(Cache)│  │(IPFS)    │
   └──────────┘  └───────┘  └──────────┘

┌─────────────────────────────────────┐
│        Web Portals (HTML/JS)        │
│  (Admin, Agent, Police)             │
└─────────────────────────────────────┘
```

### Data Flow
1. **Resident initiates SOS** → Mobile app captures location & face image
2. **Request sent to backend** → Stored in MongoDB with timestamp
3. **Real-time notification** → Socket.IO sends to guards & agents
4. **Guard responds** → Face recognition verification or QR scan
5. **Status updates** → Tracked and notified to all stakeholders
6. **Blockchain record** → Incident hashed and stored immutably
7. **Police dispatch** → Police portal updated with incident details

---

## 📁 Project Structure

```
securestepnew/
├── lib/                              # Flutter app source code
│   ├── screens/                      # UI screens for different roles
│   │   ├── resident/                 # Resident app screens
│   │   │   ├── resident_home_screen.dart
│   │   │   ├── resident_sos_screen.dart
│   │   │   ├── resident_emergency_sos_screen.dart
│   │   │   ├── sos_history_screen.dart
│   │   │   ├── my_complaints_screen.dart
│   │   │   └── resident_settings_screen.dart
│   │   ├── guard/                    # Guard app screens
│   │   │   ├── guard_home_screen.dart
│   │   │   ├── guard_settings_screen.dart
│   │   │   └── agent_start_job_screen.dart
│   │   ├── agent/                    # Agent portal screens
│   │   │   ├── agent_home_screen.dart
│   │   │   ├── agent_settings_screen.dart
│   │   │   ├── upload_documents_screen.dart
│   │   │   └── agent_start_job_screen.dart
│   │   ├── admin/                    # Admin screens
│   │   │   └── admin_home_screen.dart
│   │   ├── login_screen_unified.dart # Unified login for all roles
│   │   └── ...
│   ├── services/                     # Business logic & API calls
│   │   ├── auth_service.dart
│   │   ├── sos_service.dart
│   │   ├── face_recognition_service.dart
│   │   └── ...
│   ├── models/                       # Data models
│   │   ├── user_model.dart
│   │   ├── sos_model.dart
│   │   └── ...
│   ├── config/                       # Configuration files
│   │   ├── api_config.dart
│   │   └── constants.dart
│   └── utils/                        # Utilities & helpers
│       ├── validators.dart
│       └── constants.dart
│
├── backend/                          # Node.js/Express backend
│   ├── src/
│   │   ├── server.js                 # Main server entry point
│   │   ├── controllers/
│   │   │   ├── auth.controller.js
│   │   │   ├── sos.controller.js
│   │   │   ├── user.controller.js
│   │   │   ├── face.controller.js
│   │   │   └── ...
│   │   ├── models/
│   │   │   ├── User.js
│   │   │   ├── SOS.js
│   │   │   ├── Society.js
│   │   │   └── ...
│   │   ├── routes/
│   │   │   ├── auth.routes.js
│   │   │   ├── sos.routes.js
│   │   │   ├── user.routes.js
│   │   │   └── ...
│   │   ├── middleware/
│   │   │   ├── auth.middleware.js
│   │   │   ├── validation.middleware.js
│   │   │   └── ...
│   │   ├── config/
│   │   │   └── database.js
│   │   └── utils/
│   │       ├── logger.js
│   │       ├── validators.js
│   │       └── ...
│   ├── .env.example                  # Environment variables template
│   ├── package.json
│   └── ...
│
├── admin_portal/                     # Admin web interface
│   ├── index.html
│   ├── script.js
│   └── styles.css
│
├── agent_portal/                     # Agent web interface
│   ├── index.html
│   ├── script.js
│   └── styles.css
│
├── police_portal/                    # Police web interface
│   ├── index.html
│   ├── script.js
│   └── styles.css
│
├── pubspec.yaml                      # Flutter dependencies
├── analysis_options.yaml             # Flutter lint configuration
├── README.md                         # This file
└── ...
```

---

## 🛠️ Tech Stack

### Frontend (Mobile)
- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider
- **APIs**: 
  - `dio` for HTTP requests
  - `google_mlkit_face_detection` for face recognition
  - `mobile_scanner` for QR code scanning
  - `camera` for image capture
  - `geolocator` for location services

### Frontend (Web)
- **HTML5, CSS3, JavaScript**
- **Socket.IO** for real-time updates
- **Google Maps API** for location visualization
- **Chart.js** for analytics

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: MongoDB (Mongoose ODM)
- **Real-time**: Socket.IO
- **Authentication**: JWT (JSON Web Tokens)
- **Caching**: Redis
- **Image Processing**: Sharp, Canvas
- **QR Code**: qrcode library
- **Face Recognition**: face-api.js
- **Email**: Nodemailer
- **Blockchain**: Ethers.js
- **IPFS**: Pinata SDK
- **OCR**: Tesseract.js
- **Rate Limiting**: express-rate-limit
- **Validation**: Joi

---

## 📦 Installation & Setup

### Prerequisites
- **Flutter SDK**: 3.x or higher
- **Node.js**: 18.0.0 or higher
- **MongoDB**: Latest version (or MongoDB Atlas cloud)
- **Git**: Latest version
- **Xcode** (for iOS development)
- **Android Studio** (for Android development)

### Backend Setup

#### 1. Clone the Repository
```bash
git clone https://github.com/NinadRBodade/securestepnew.git
cd securestepnew
```

#### 2. Install Backend Dependencies
```bash
cd backend
npm install
```

#### 3. Configure Environment Variables
```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your configuration
nano .env
```

See [Configuration](#configuration) section for details.

#### 4. Start MongoDB
```bash
# If using local MongoDB
mongod

# Or use MongoDB Atlas for cloud database
```

#### 5. Run Backend Server
```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

Backend will run on `http://localhost:5001`

### Mobile App Setup

#### 1. Install Flutter Dependencies
```bash
flutter pub get
```

#### 2. Configure API Endpoint
Edit `lib/config/api_config.dart`:
```dart
static String baseURL = 'http://localhost:5001'; // Change to your backend URL
```

#### 3. Run on Android
```bash
flutter run -d android
```

#### 4. Run on iOS
```bash
flutter run -d ios
```

#### 5. Build for Release
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

### Web Portal Setup

The web portals (admin, agent, police) are static HTML/JS applications. Simply open them in a browser:

- **Admin Portal**: `open admin_portal/index.html`
- **Agent Portal**: `open agent_portal/index.html`
- **Police Portal**: `open police_portal/index.html`

Or serve them with a web server:
```bash
# Using Python
python -m http.server 8000

# Using Node.js (http-server)
npm install -g http-server
http-server
```

---

## ⚙️ Configuration

### Backend Configuration (.env)

```env
# Server Configuration
NODE_ENV=development
PORT=5001

# Database
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/society_safety?retryWrites=true&w=majority

# JWT Authentication
JWT_SECRET=your_secure_jwt_secret_key_here

# Email Configuration (Gmail with App Password)
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password

# Blockchain Configuration (Optional)
BLOCKCHAIN_PROVIDER_URL=https://rpc-mumbai.maticvigil.com
PRIVATE_KEY=your_private_key
CONTRACT_ADDRESS=your_contract_address

# IPFS/Pinata (Optional)
PINATA_API_KEY=your_pinata_key
PINATA_API_SECRET=your_pinata_secret
```

### Mobile App Configuration (lib/config/api_config.dart)

```dart
class ApiConfig {
  static String baseURL = 'http://localhost:5001';
  static String socketURL = 'http://localhost:5001';
  // ... other configurations
}
```

### Mock Credentials for Testing

See `lib/utils/constants.dart` for test credentials:
```dart
const Map<String, String> mockCredentials = {
  'resident@example.com': 'resident123',
  'guard@example.com': 'guard123',
  'agent@example.com': 'agent123',
};
```

---

## 🚀 Running the Application

### Full Stack Local Development

#### Terminal 1 - MongoDB
```bash
mongod
```

#### Terminal 2 - Backend Server
```bash
cd backend
npm run dev
```

#### Terminal 3 - Flutter App
```bash
flutter run
```

#### Terminal 4 - Web Portals (Optional)
```bash
cd admin_portal
python -m http.server 8000
# Then open http://localhost:8000
```

### Using Docker (Optional)
```bash
# Build and run backend with Docker
docker-compose up
```

---

## 🔌 API Endpoints

### Authentication
```
POST   /api/auth/register        - Register new user
POST   /api/auth/login           - Login user
POST   /api/auth/logout          - Logout user
POST   /api/auth/refresh-token   - Refresh JWT token
```

### SOS Management
```
POST   /api/sos/create           - Create new SOS request
GET    /api/sos/list             - Get SOS history
GET    /api/sos/:id              - Get SOS details
PUT    /api/sos/:id/acknowledge  - Acknowledge SOS
PUT    /api/sos/:id/resolve      - Resolve SOS
GET    /api/sos/active           - Get active emergencies
```

### Face Recognition
```
POST   /api/face/register        - Register face for user
POST   /api/face/verify          - Verify face recognition
GET    /api/face/:userId         - Get stored face data
```

### QR Code
```
GET    /api/qr/generate          - Generate QR code
POST   /api/qr/verify            - Verify QR code
```

### User Management
```
GET    /api/users/:id            - Get user profile
PUT    /api/users/:id            - Update user profile
DELETE /api/users/:id            - Delete user
GET    /api/users/list           - List users
```

### Society Management
```
POST   /api/societies/create     - Create society
GET    /api/societies/list       - List societies
PUT    /api/societies/:id        - Update society
```

### Real-time Events (Socket.IO)
```
sos:created              - New SOS created
sos:acknowledged         - SOS acknowledged
sos:resolved             - SOS resolved
user:location-update     - Location update
user:connected           - User connected
user:disconnected        - User disconnected
```

---

## 👥 User Roles

### 1. Resident
- Request emergency assistance
- View SOS history
- Verify through face recognition or QR
- File complaints
- Manage profile and emergency contacts

### 2. Guard
- Respond to SOS alerts
- Verify residents
- Accept/complete verification jobs
- Upload certifications
- View assigned society incidents

### 3. Agent
- Register guards and manage team
- Monitor all SOS in assigned societies
- View analytics and reports
- Manage society information
- Create QR codes and verification links

### 4. Police
- View all incidents in jurisdiction
- Dispatch units to emergencies
- Track response status
- Access incident details and location
- Generate reports

### 5. Admin
- System-wide user management
- Society and agent oversight
- Analytics and reporting
- System configuration
- User role assignment

---

## 📱 Features Documentation

### SOS Emergency System
- **How It Works**: Resident taps SOS → Location captured → Real-time notification to guards → Face verification → Status updates
- **Offline Support**: SOS can be queued offline, synced when online
- **Real-time Updates**: Socket.IO notifications to all stakeholders
- **Location Tracking**: GPS coordinates with accuracy
- **History**: All SOS requests logged with timestamps

### Face Recognition
- **Registration**: Initial face scan during verification setup
- **Verification**: Compare captured face with stored face data
- **Liveness Detection**: Prevent spoofing with liveness checks
- **Multiple Captures**: Uses multiple frames for accuracy

### QR Code System
- **Generation**: Generate unique QR for residents
- **Offline QR**: Generate and store QR locally for offline use
- **Scanning**: Guards scan QR to verify residents
- **Validation**: Backend validates QR authenticity

### Complaint Management
- **Filing**: Residents file complaints with description and photos
- **Tracking**: View complaint status and responses
- **Escalation**: Complaints can be escalated to agents/police
- **Resolution**: Track complaint closure

### Real-time Notifications
- **Socket.IO**: WebSocket-based real-time updates
- **Push Notifications**: Mobile app push notifications
- **Email Alerts**: Critical incidents trigger email notifications

### Blockchain Integration (Optional)
- **Immutable Records**: Critical incidents hashed and stored
- **Verification**: Verify incident authenticity
- **Audit Trail**: Transparent incident history

---

## 🔒 Security

### Authentication & Authorization
- JWT-based authentication
- Role-based access control (RBAC)
- Password hashing with bcrypt
- Session management with token refresh

### Data Protection
- **Sensitive Data**: Face images and locations encrypted
- **HTTPS**: All API calls use HTTPS in production
- **Database**: MongoDB with authentication
- **.env File**: Environment variables not committed to git

### API Security
- Rate limiting on endpoints
- Input validation with Joi
- CORS configuration
- SQL injection prevention (Mongoose ORM)

### Privacy
- Users' locations visible only to authorized personnel
- Face recognition data stored securely
- Complaint data protected
- Audit logs maintained

### Important Security Notes
- **Do NOT commit `.env` files** with credentials
- **Rotate credentials regularly** (MongoDB, email, API keys)
- **Use strong JWT secrets** in production
- **Enable HTTPS** for all production deployments
- **Keep dependencies updated**: `npm audit fix`

---

## 🤝 Contributing

### Development Workflow
1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes and commit: `git commit -m "Add feature"`
3. Push to branch: `git push origin feature/your-feature`
4. Create a Pull Request

### Code Style
- Follow Flutter style guide for Dart code
- Use ESLint for JavaScript
- Add comments for complex logic
- Write meaningful commit messages

### Testing
- Test locally before pushing
- Test on multiple devices/browsers
- Check backend API responses
- Verify offline functionality

---

## 📄 License

This project is proprietary and confidential. Unauthorized copying or distribution is prohibited.

---

## 📞 Support & Contact

For issues, questions, or feature requests, please open an issue on GitHub or contact the development team.

---

## 🗂️ Additional Resources

- **Flutter Documentation**: https://flutter.dev/docs
- **Node.js/Express Docs**: https://expressjs.com/
- **MongoDB Docs**: https://docs.mongodb.com/
- **Socket.IO Docs**: https://socket.io/docs/
- **Google ML Kit**: https://developers.google.com/ml-kit

---

**Last Updated**: January 2, 2026  
**Version**: 1.0.0  
**Status**: Active Development
