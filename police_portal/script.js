// Police Dashboard - Real-time SOS Alert System
// Configuration
const CONFIG = {
    API_BASE_URL: 'http://10.156.78.17:5001/api',
    SOCKET_URL: 'http://10.156.78.17:5001',
    DEFAULT_CENTER: [19.0760, 72.8777], // Mumbai coordinates
    DEFAULT_ZOOM: 12
};

// Global variables
let map;
let socket;
let markers = {};
let alerts = [];
let currentFilter = 'all';
let selectedAlert = null;

// Initialize dashboard
document.addEventListener('DOMContentLoaded', function() {
    initMap();
    initSocket();
    initDateTime();
    loadAlerts();
    
    // Auto-refresh every 30 seconds
    setInterval(loadAlerts, 30000);
});

// Initialize Leaflet map
function initMap() {
    map = L.map('map').setView(CONFIG.DEFAULT_CENTER, CONFIG.DEFAULT_ZOOM);
    
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 19
    }).addTo(map);
    
    console.log('✅ Map initialized');
}

// Initialize Socket.IO connection
function initSocket() {
    socket = io(CONFIG.SOCKET_URL, {
        transports: ['websocket', 'polling']
    });
    
    socket.on('connect', () => {
        console.log('✅ Connected to server');
        updateConnectionStatus(true);
    });
    
    socket.on('disconnect', () => {
        console.log('❌ Disconnected from server');
        updateConnectionStatus(false);
    });
    
    // Listen for police SOS alerts
    socket.on('police:sos-alert', (data) => {
        console.log('🚨 NEW SOS ALERT received:', data);
        playAlertSound();
        
        // Format alert data with full user information
        const alert = {
            _id: data._id || data.sosId,
            sosId: data.sosId || data._id,
            triggeredBy: data.triggeredBy || { name: 'Unknown User', phone: null },
            flatNumber: data.flatNumber,
            societyId: typeof data.societyId === 'string' ? 
                { name: data.societyId } : 
                data.societyId,
            description: data.description || data.locationAddress,
            status: data.status || 'triggered',
            priority: data.priority || 'critical',
            triggeredAt: data.triggeredAt,
            location: data.location || (data.latitude && data.longitude ? {
                latitude: data.latitude,
                longitude: data.longitude,
                address: data.locationAddress
            } : null),
            locationAddress: data.locationAddress || data.description
        };
        
        addNewAlert(alert);
        showNotification('New Emergency Alert', `${alert.triggeredBy.name} - Flat ${alert.flatNumber}`);
    });
    
    // Listen for status updates
    socket.on('sos:acknowledged', (data) => {
        console.log('✅ SOS Acknowledged:', data);
        updateAlertStatus(data.sosId, 'acknowledged');
    });
    
    socket.on('sos:resolved', (data) => {
        console.log('✅ SOS Resolved:', data);
        updateAlertStatus(data.sosId, 'resolved');
    });
    
    socket.on('guard:arrived', (data) => {
        console.log('🚗 Guard arrived:', data);
        showNotification('Guard Arrived', `Guard ${data.guardName} has arrived at location`);
    });
}

// Update connection status indicator
function updateConnectionStatus(isConnected) {
    const statusEl = document.getElementById('connection-status');
    const dot = statusEl.querySelector('.status-dot');
    const text = statusEl.querySelector('span:last-child');
    
    if (isConnected) {
        dot.classList.remove('offline');
        dot.classList.add('online');
        text.textContent = 'Connected';
    } else {
        dot.classList.remove('online');
        dot.classList.add('offline');
        text.textContent = 'Disconnected';
    }
}

// Initialize date/time display
function initDateTime() {
    updateDateTime();
    setInterval(updateDateTime, 1000);
}

function updateDateTime() {
    const now = new Date();
    const options = {
        weekday: 'short',
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    };
    document.getElementById('current-datetime').textContent = now.toLocaleDateString('en-US', options);
}

// Load all alerts from API
async function loadAlerts() {
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/sos/police/dashboard`);
        const data = await response.json();
        
        if (data.status === 'success') {
            alerts = data.data.sosEvents || [];
            renderAlerts();
            updateStats();
            updateMap();
            console.log(`✅ Loaded ${alerts.length} alerts`);
        } else {
            console.error('❌ API error:', data.message);
        }
    } catch (error) {
        console.error('❌ Failed to load alerts:', error);
    }
}

// Add new real-time alert
function addNewAlert(alertData) {
    // alertData is already formatted, just add it directly
    alerts.unshift(alertData);
    renderAlerts();
    updateStats();
    updateMap();
}

// Update alert status
function updateAlertStatus(sosId, newStatus) {
    const alert = alerts.find(a => a.sosId === sosId);
    if (alert) {
        alert.status = newStatus;
        if (newStatus === 'acknowledged') {
            alert.acknowledgedAt = new Date().toISOString();
        } else if (newStatus === 'resolved') {
            alert.resolvedAt = new Date().toISOString();
        }
        renderAlerts();
        updateStats();
        updateMap();
    }
}

// Render alerts list
function renderAlerts() {
    const container = document.getElementById('alerts-container');
    
    // Filter alerts based on current filter
    let filteredAlerts = alerts;
    if (currentFilter !== 'all') {
        filteredAlerts = alerts.filter(a => {
            if (currentFilter === 'active') {
                return a.status === 'triggered' || a.status === 'active';
            }
            return a.status === currentFilter;
        });
    }
    
    if (filteredAlerts.length === 0) {
        container.innerHTML = `
            <div class="no-alerts">
                <span class="icon">📭</span>
                <p>No ${currentFilter === 'all' ? '' : currentFilter} alerts</p>
                <small>Alerts will appear here in real-time</small>
            </div>
        `;
        return;
    }
    
    container.innerHTML = filteredAlerts.map(alert => createAlertCard(alert)).join('');
}

// Create alert card HTML
function createAlertCard(alert) {
    const status = alert.status === 'triggered' ? 'active' : alert.status;
    const statusClass = getStatusClass(status);
    const statusIcon = getStatusIcon(status);
    const timeAgo = getTimeAgo(alert.triggeredAt);
    const priorityBadge = alert.priority === 'critical' ? '<span class="badge badge-critical">CRITICAL</span>' : '';
    
    // Get society name from societyId (could be string or object)
    const societyName = typeof alert.societyId === 'string' ? alert.societyId : (alert.societyId?.name || 'Unknown');
    
    // Format location information with all details
    const locationInfo = alert.location && alert.location.latitude && alert.location.longitude ? 
        `<div class="alert-location" onclick="showLocationOnMap('${alert.sosId}')">
            📍 <strong>GPS:</strong> ${alert.location.latitude.toFixed(6)}, ${alert.location.longitude.toFixed(6)}
            ${alert.location.address || alert.locationAddress ? `<br><small style="color: #666;">${alert.location.address || alert.locationAddress}</small>` : ''}
        </div>` : (alert.locationAddress ? `<div class="alert-location">📍 ${alert.locationAddress}</div>` : '');
    
    const agentInfo = alert.involvedAgent ? 
        `<div class="alert-agent">
            ⚠️ Agent on site: ${alert.involvedAgent.company || 'Unknown'}
            ${alert.involvedAgent.safetyScore ? `(Score: ${alert.involvedAgent.safetyScore}/5.0)` : ''}
        </div>` : '';
    
    return `
        <div class="alert-card ${statusClass}" onclick="showAlertDetails('${alert.sosId}')">
            <div class="alert-header">
                <div class="alert-title">
                    ${statusIcon} SOS ${alert.sosId}
                    ${priorityBadge}
                </div>
                <div class="alert-time">${timeAgo}</div>
            </div>
            <div class="alert-body">
                <div class="alert-info">
                    <strong>🏢 Society:</strong> ${societyName}
                </div>
                <div class="alert-info">
                    <strong>🏠 Flat:</strong> ${alert.flatNumber}
                </div>
                <div class="alert-info">
                    <strong>👤 Resident:</strong> ${alert.triggeredBy?.name || 'Unknown'}
                    ${alert.triggeredBy?.phone ? `<br>📞 ${alert.triggeredBy.phone}` : ''}
                    ${alert.triggeredBy?.email ? `<br>✉️ ${alert.triggeredBy.email}` : ''}
                </div>
                ${alert.description ? `
                <div class="alert-description">
                    💬 ${alert.description}
                </div>` : ''}
                ${locationInfo}
                ${agentInfo}
            </div>
            <div class="alert-footer">
                <span class="alert-status ${statusClass}">${status.toUpperCase()}</span>
                <button class="btn-small btn-verify" onclick="event.stopPropagation(); verifyBlockchain('${alert.sosId}')" title="Verify blockchain integrity">
                    🔐 Verify
                </button>
                ${status === 'active' ? 
                    '<button class="btn-small btn-primary" onclick="event.stopPropagation(); dispatchToAlert(\'' + alert.sosId + '\')">Dispatch Unit</button>' : 
                    status === 'acknowledged' ? 
                    '<span class="acknowledged-text">✓ Unit Dispatched</span>' : 
                    '<span class="resolved-text">✓ Resolved</span>'
                }
            </div>
        </div>
    `;
}

// Get status class
function getStatusClass(status) {
    switch(status) {
        case 'active':
        case 'triggered':
            return 'status-active';
        case 'acknowledged':
            return 'status-acknowledged';
        case 'resolved':
            return 'status-resolved';
        case 'false-alarm':
            return 'status-false';
        default:
            return '';
    }
}

// Get status icon
function getStatusIcon(status) {
    switch(status) {
        case 'active':
        case 'triggered':
            return '🚨';
        case 'acknowledged':
            return '⏰';
        case 'resolved':
            return '✅';
        case 'false-alarm':
            return '❌';
        default:
            return '🔔';
    }
}

// Get time ago string
function getTimeAgo(timestamp) {
    const now = new Date();
    const time = new Date(timestamp);
    const diffMs = now - time;
    const diffMins = Math.floor(diffMs / 60000);
    
    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours}h ago`;
    
    const diffDays = Math.floor(diffHours / 24);
    return `${diffDays}d ago`;
}

// Update statistics
function updateStats() {
    const activeCount = alerts.filter(a => a.status === 'triggered' || a.status === 'active').length;
    const acknowledgedCount = alerts.filter(a => a.status === 'acknowledged').length;
    
    // Resolved today
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const resolvedToday = alerts.filter(a => {
        if (a.status !== 'resolved') return false;
        const resolvedDate = new Date(a.resolvedAt);
        return resolvedDate >= today;
    }).length;
    
    document.getElementById('active-count').textContent = activeCount;
    document.getElementById('acknowledged-count').textContent = acknowledgedCount;
    document.getElementById('resolved-count').textContent = resolvedToday;
    document.getElementById('total-count').textContent = alerts.length;
}

// Update map markers
function updateMap() {
    // Clear existing markers
    Object.values(markers).forEach(marker => map.removeLayer(marker));
    markers = {};
    
    // Add markers for alerts with location
    alerts.forEach(alert => {
        if (alert.location && alert.location.latitude && alert.location.longitude) {
            const { latitude, longitude } = alert.location;
            const status = alert.status === 'triggered' ? 'active' : alert.status;
            
            const icon = L.divIcon({
                className: `custom-marker marker-${status}`,
                html: `<div class="marker-pin ${status}"></div>`,
                iconSize: [30, 42],
                iconAnchor: [15, 42]
            });
            
            const marker = L.marker([latitude, longitude], { icon })
                .addTo(map)
                .bindPopup(createMarkerPopup(alert));
            
            markers[alert.sosId] = marker;
        }
    });
    
    // Auto-center map if there are active alerts
    const activeAlerts = alerts.filter(a => 
        a.status === 'triggered' || a.status === 'active'
    ).filter(a => a.location);
    
    if (activeAlerts.length > 0) {
        const bounds = L.latLngBounds(
            activeAlerts.map(a => [a.location.latitude, a.location.longitude])
        );
        map.fitBounds(bounds, { padding: [50, 50] });
    }
}

// Create marker popup HTML
function createMarkerPopup(alert) {
    const societyName = typeof alert.societyId === 'string' ? alert.societyId : (alert.societyId?.name || 'Unknown');
    
    return `
        <div class="marker-popup">
            <strong>🚨 ${alert.sosId}</strong><br>
            <strong>👤 Name:</strong> ${alert.triggeredBy?.name || 'Unknown'}<br>
            ${alert.triggeredBy?.phone ? `<strong>📞 Phone:</strong> ${alert.triggeredBy.phone}<br>` : ''}
            <strong>🏢 Society:</strong> ${societyName}<br>
            <strong>🏠 Flat:</strong> ${alert.flatNumber}<br>
            <strong>📍 Location:</strong> ${alert.location.latitude.toFixed(6)}, ${alert.location.longitude.toFixed(6)}<br>
            ${alert.location.address || alert.locationAddress ? `<strong>Address:</strong> ${alert.location.address || alert.locationAddress}<br>` : ''}
            <strong>⏰ Status:</strong> ${alert.status}<br>
            <strong>🕐 Time:</strong> ${getTimeAgo(alert.triggeredAt)}<br>
            ${alert.description ? `<strong>💬 Details:</strong> ${alert.description}<br>` : ''}
            <button class="btn-small" onclick="showAlertDetails('${alert.sosId}')">View Details</button>
        </div>
    `;
}

// Show location on map
function showLocationOnMap(sosId) {
    event.stopPropagation();
    const alert = alerts.find(a => a.sosId === sosId);
    if (alert && alert.location) {
        map.setView([alert.location.latitude, alert.location.longitude], 16);
        markers[sosId]?.openPopup();
    }
}

// Filter alerts
function filterAlerts(filter) {
    currentFilter = filter;
    
    // Update button states
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.classList.remove('active');
        if (btn.dataset.filter === filter) {
            btn.classList.add('active');
        }
    });
    
    renderAlerts();
}

// Show alert details modal
function showAlertDetails(sosId) {
    const alert = alerts.find(a => a.sosId === sosId);
    if (!alert) return;
    
    selectedAlert = alert;
    
    const societyName = typeof alert.societyId === 'string' ? alert.societyId : (alert.societyId?.name || 'Unknown');
    const societyAddress = alert.locationAddress || (alert.location?.address) || (typeof alert.societyId === 'object' ? formatAddress(alert.societyId?.address) : 'Not provided');
    
    const modalBody = document.getElementById('modal-body');
    modalBody.innerHTML = `
        <div class="detail-section">
            <h3>🚨 Emergency Information</h3>
            <div class="detail-row">
                <span class="detail-label">SOS ID:</span>
                <span class="detail-value">${alert.sosId}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Status:</span>
                <span class="detail-value ${getStatusClass(alert.status)}">${alert.status.toUpperCase()}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Priority:</span>
                <span class="detail-value">${alert.priority.toUpperCase()}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Triggered:</span>
                <span class="detail-value">${new Date(alert.triggeredAt).toLocaleString()}</span>
            </div>
        </div>
        
        <div class="detail-section">
            <h3>🏢 Location Details</h3>
            <div class="detail-row">
                <span class="detail-label">Society:</span>
                <span class="detail-value">${societyName}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Address:</span>
                <span class="detail-value">${societyAddress}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Flat Number:</span>
                <span class="detail-value">${alert.flatNumber}</span>
            </div>
            ${alert.location && alert.location.latitude && alert.location.longitude ? `
            <div class="detail-row">
                <span class="detail-label">GPS Coordinates:</span>
                <span class="detail-value">
                    <strong>Lat:</strong> ${alert.location.latitude.toFixed(6)}, <strong>Long:</strong> ${alert.location.longitude.toFixed(6)}
                    <br>
                    <a href="https://www.google.com/maps?q=${alert.location.latitude},${alert.location.longitude}" target="_blank" class="link-btn">
                        📍 Open in Google Maps →
                    </a>
                </span>
            </div>` : ''}
        </div>
        
        <div class="detail-section">
            <h3>👤 Resident Information</h3>
            <div class="detail-row">
                <span class="detail-label">Name:</span>
                <span class="detail-value">${alert.triggeredBy?.name || 'Unknown'}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Email:</span>
                <span class="detail-value">${alert.triggeredBy?.email || 'Not provided'}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Phone:</span>
                <span class="detail-value">
                    ${alert.triggeredBy?.phone || 'Not provided'}
                    ${alert.triggeredBy?.phone ? `<a href="tel:${alert.triggeredBy.phone}" class="link-btn">📞 Call</a>` : ''}
                </span>
            </div>
        </div>
        
        ${alert.description ? `
        <div class="detail-section">
            <h3>💬 Description</h3>
            <p class="description-text">${alert.description}</p>
        </div>` : ''}
        
        ${alert.involvedAgent ? `
        <div class="detail-section alert-section">
            <h3>⚠️ Agent on Site</h3>
            <div class="detail-row">
                <span class="detail-label">Company:</span>
                <span class="detail-value">${alert.involvedAgent.company || 'Unknown'}</span>
            </div>
            ${alert.involvedAgent.safetyScore ? `
            <div class="detail-row">
                <span class="detail-label">Safety Score:</span>
                <span class="detail-value">${alert.involvedAgent.safetyScore}/5.0</span>
            </div>` : ''}
        </div>` : ''}
        
        ${alert.acknowledgedAt || alert.resolvedAt ? `
        <div class="detail-section">
            <h3>📋 Response Timeline</h3>
            ${alert.acknowledgedAt ? `
            <div class="detail-row">
                <span class="detail-label">Acknowledged:</span>
                <span class="detail-value">${new Date(alert.acknowledgedAt).toLocaleString()}</span>
            </div>` : ''}
            ${alert.resolvedAt ? `
            <div class="detail-row">
                <span class="detail-label">Resolved:</span>
                <span class="detail-value">${new Date(alert.resolvedAt).toLocaleString()}</span>
            </div>` : ''}
            ${alert.resolution?.notes ? `
            <div class="detail-row">
                <span class="detail-label">Resolution Notes:</span>
                <span class="detail-value">${alert.resolution.notes}</span>
            </div>` : ''}
        </div>` : ''}
    `;
    
    document.getElementById('alert-modal').style.display = 'flex';
}

// Format address
function formatAddress(address) {
    if (!address) return 'Not provided';
    if (typeof address === 'string') return address;
    return `${address.street || ''}, ${address.city || ''}, ${address.state || ''} ${address.pincode || ''}`.trim();
}

// Close modal
function closeModal() {
    document.getElementById('alert-modal').style.display = 'none';
    selectedAlert = null;
}

// Dispatch police to alert
function dispatchPolice() {
    if (!selectedAlert) return;
    
    if (confirm(`Dispatch police unit to ${selectedAlert.societyId?.name} - Flat ${selectedAlert.flatNumber}?`)) {
        console.log('🚓 Dispatching police to:', selectedAlert.sosId);
        // TODO: Implement police dispatch API call
        showNotification('Police Dispatched', `Unit dispatched to ${selectedAlert.flatNumber}`);
        closeModal();
    }
}

// Dispatch to specific alert
function dispatchToAlert(sosId) {
    const alert = alerts.find(a => a.sosId === sosId);
    if (!alert) return;
    
    if (confirm(`Dispatch police unit to ${alert.societyId?.name} - Flat ${alert.flatNumber}?`)) {
        console.log('🚓 Dispatching police to:', sosId);
        // TODO: Implement police dispatch API call
        showNotification('Police Dispatched', `Unit dispatched to ${alert.flatNumber}`);
    }
}

// Center map
function centerMap() {
    map.setView(CONFIG.DEFAULT_CENTER, CONFIG.DEFAULT_ZOOM);
}

// Toggle heatmap (placeholder)
function toggleHeatmap() {
    showNotification('Heatmap', 'Heatmap feature coming soon');
}

// Verify blockchain integrity for SOS
async function verifyBlockchain(sosId) {
    try {
        // Show loading state
        showNotification('Verifying...', `Checking blockchain integrity for ${sosId}`);
        
        const response = await fetch(`${CONFIG.API_BASE_URL}/sos/${sosId}/verify`);
        const data = await response.json();
        
        if (data.status === 'success') {
            const result = data.data;
            const verified = result.verified;
            
            // Create verification result modal/alert
            const icon = verified ? '✅' : '⚠️';
            const color = verified ? '#16a34a' : '#dc2626';
            const message = verified ? 
                'Data is AUTHENTIC - No tampering detected' : 
                'WARNING: Data has been TAMPERED';
            
            // Show result in a styled alert with HIDDEN hash
            const resultHTML = `
                <div style="background: white; padding: 20px; border-radius: 10px; border-left: 5px solid ${color}; max-width: 500px;">
                    <h3 style="margin: 0 0 15px 0; color: ${color};">${icon} Blockchain Verification</h3>
                    <p style="margin: 10px 0;"><strong>SOS ID:</strong> ${result.sosId}</p>
                    <p style="margin: 10px 0; font-size: 16px; color: ${color};"><strong>${message}</strong></p>
                    <p style="margin: 10px 0; font-size: 12px; color: #666;"><strong>Timestamp:</strong> ${new Date(result.timestamp).toLocaleString()}</p>
                    
                    <!-- Hidden hash container -->
                    <div id="hash-container" style="display: none; margin-top: 15px; padding: 10px; background: #f3f4f6; border-radius: 5px;">
                        <p style="margin: 5px 0; font-size: 11px; color: #666; font-family: monospace; word-break: break-all;"><strong>Hash:</strong> ${result.hash}</p>
                        <p style="margin: 5px 0; font-size: 10px; color: #999;">⚠️ For forensic/audit purposes only</p>
                    </div>
                    
                    <button 
                        onclick="document.getElementById('hash-container').style.display='block'; this.style.display='none';"
                        style="margin-top: 15px; padding: 8px 16px; background: #6b7280; color: white; border: none; border-radius: 5px; cursor: pointer; font-size: 12px;">
                        🔍 View Blockchain Hash (Advanced)
                    </button>
                </div>
            `;
            
            // Show in modal
            const modal = document.getElementById('alert-modal');
            const modalBody = document.getElementById('modal-body');
            modalBody.innerHTML = resultHTML;
            modal.style.display = 'flex';
            
            // Also show browser notification
            showNotification(
                verified ? '✅ Verified' : '⚠️ Tampered', 
                `${sosId}: ${message}`
            );
            
            console.log('🔐 Verification result:', result);
        } else {
            alert(`❌ ${data.message}`);
        }
    } catch (error) {
        console.error('Verification error:', error);
        alert(`❌ Verification failed: ${error.message}`);
    }
}

// Play alert sound
function playAlertSound() {
    const audio = document.getElementById('alert-sound');
    audio.play().catch(err => console.log('Audio play failed:', err));
}

// Show browser notification
function showNotification(title, body) {
    if (!("Notification" in window)) {
        console.log("This browser does not support notifications");
        return;
    }
    
    if (Notification.permission === "granted") {
        new Notification(title, { body, icon: '🚨' });
    } else if (Notification.permission !== "denied") {
        Notification.requestPermission().then(permission => {
            if (permission === "granted") {
                new Notification(title, { body, icon: '🚨' });
            }
        });
    }
}

// Request notification permission on load
if ("Notification" in window && Notification.permission === "default") {
    Notification.requestPermission();
}
