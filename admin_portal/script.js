// Admin Dashboard - Complete JavaScript
const CONFIG = {
    API_BASE_URL: 'http://localhost:5001/api',
    DEFAULT_SCORE: 75
};

// Global state
let currentSection = 'dashboard';
let currentAgent = null;
let currentSociety = null;
let allAgents = [];
let allSocieties = [];
let allGuards = [];
let filteredAgents = [];
let currentFilter = 'all';
let allVerifications = [];
let currentVerification = null;

// Initialize dashboard
document.addEventListener('DOMContentLoaded', function() {
    initDateTime();
    loadDashboardStats();
    loadAgents();
    loadSocieties();
    
    // Update score indicator
    const scoreInput = document.getElementById('verification-score');
    if (scoreInput) {
        scoreInput.addEventListener('input', function() {
            document.getElementById('score-bar').style.width = this.value + '%';
        });
    }
    
    // Auto-refresh every 60 seconds
    setInterval(loadDashboardStats, 60000);
});

// User menu toggle (for modern header)
function toggleUserMenu() {
    const dropdown = document.getElementById('user-dropdown');
    if (dropdown) {
        dropdown.classList.toggle('show');
    }
}

// Close dropdown when clicking outside
document.addEventListener('click', function(event) {
    const userMenuContainer = document.querySelector('.user-menu-container');
    const dropdown = document.getElementById('user-dropdown');
    
    if (dropdown && !userMenuContainer.contains(event.target)) {
        dropdown.classList.remove('show');
    }
});

// Handle logout
function handleLogout() {
    if (confirm('Are you sure you want to logout?')) {
        // Clear session
        localStorage.removeItem('adminToken');
        sessionStorage.clear();
        // Redirect to login or home page
        window.location.href = '/';
    }
}

// Initialize date/time
function initDateTime() {
    function updateDateTime() {
        const now = new Date();
        const options = { 
            weekday: 'short', 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        };
        document.getElementById('current-datetime').textContent = 
            now.toLocaleDateString('en-US', options);
    }
    updateDateTime();
    setInterval(updateDateTime, 60000);
}

// ============= NAVIGATION =============
function showSection(section) {
    currentSection = section;
    
    // Update nav items (support both old .nav-item and new .nav-link)
    document.querySelectorAll('.nav-item, .nav-link').forEach(item => {
        item.classList.remove('active');
    });
    if (event && event.target) {
        const navItem = event.target.closest('.nav-item') || event.target.closest('.nav-link');
        if (navItem) navItem.classList.add('active');
    }
    
    // Hide all sections
    document.querySelectorAll('.content-section').forEach(sec => {
        sec.classList.remove('active');
    });
    
    // Show selected section
    const sectionEl = document.getElementById(section + '-section');
    if (sectionEl) {
        sectionEl.classList.add('active');
    }
    
    // Update page title
    const titles = {
        dashboard: 'Admin Dashboard',
        societies: 'Society Management',
        agents: 'Agent Verification',
        documents: 'Document Verification',
        monitoring: 'System Monitoring',
        sos: 'SOS Emergency Alerts'
    };
    const pageTitle = document.getElementById('page-title');
    if (pageTitle) {
        pageTitle.textContent = titles[section] || 'Admin Dashboard';
    }
    
    // Load section data
    if (section === 'agents') {
        loadAgents();
    } else if (section === 'societies') {
        loadSocieties();
    } else if (section === 'documents') {
        loadPendingVerifications();
    } else if (section === 'monitoring') {
        loadMonitoring();
    } else if (section === 'sos') {
        loadSOSAlerts();
    }
}

// ============= DASHBOARD STATS =============
async function loadDashboardStats() {
    try {
        // Load all data
        const [societiesRes, guardsRes, agentsRes, sosRes] = await Promise.all([
            fetch(`${CONFIG.API_BASE_URL}/societies`).catch(() => ({json: () => ({societies: []})})),
            fetch(`${CONFIG.API_BASE_URL}/guards`).catch(() => ({json: () => ({guards: []})})),
            fetch(`${CONFIG.API_BASE_URL}/agents/all`).catch(() => ({json: () => ({agents: []})})),
            fetch(`${CONFIG.API_BASE_URL}/sos`).catch(() => ({json: () => ({alerts: []})}))
        ]);
        
        const societies = (await societiesRes.json()).societies || [];
        const guards = (await guardsRes.json()).guards || [];
        const agents = (await agentsRes.json()).agents || [];
        const sosAlerts = (await sosRes.json()).alerts || [];
        
        // Update stats
        document.getElementById('total-societies').textContent = societies.length;
        document.getElementById('total-guards').textContent = guards.length;
        document.getElementById('pending-agents').textContent = agents.filter(a => !a.verified && !a.rejected).length;
        document.getElementById('active-agents').textContent = agents.filter(a => a.verified).length;
        document.getElementById('total-sos').textContent = sosAlerts.length;
        
    } catch (error) {
        console.error('Error loading dashboard stats:', error);
    }
}

// ============= SOCIETY MANAGEMENT =============
async function loadSocieties() {
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/societies`);
        const data = await response.json();
        allSocieties = data.societies || [];
        displaySocieties();
    } catch (error) {
        console.error('Error loading societies:', error);
        showError('societies-container', 'Failed to load societies');
    }
}

function displaySocieties() {
    const container = document.getElementById('societies-container');
    
    if (allSocieties.length === 0) {
        container.innerHTML = `
            <div class="no-data">
                <span class="icon">🏘️</span>
                <p>No societies found</p>
                <button class="btn btn-primary" onclick="showCreateSociety()">Create First Society</button>
            </div>
        `;
        return;
    }
    
    container.innerHTML = allSocieties.map(society => `
        <div class="society-card" onclick="viewSocietyDetail('${society._id}')">
            <div style="display: flex; justify-content: space-between; align-items: start;">
                <div>
                    <h3 style="font-size: 18px; margin-bottom: 8px;">${society.name}</h3>
                    <p style="color: #718096; font-size: 14px; margin-bottom: 8px;">
                        🆔 ${society.societyId || society._id}
                    </p>
                    <p style="color: #718096; font-size: 14px;">
                        📍 ${society.city}, ${society.state}
                    </p>
                </div>
                <div style="text-align: right;">
                    <div style="background: #e8f5e9; padding: 8px 16px; border-radius: 8px;">
                        <div style="font-size: 24px; font-weight: bold; color: #2e7d32;">
                            ${society.guardCount || 0}
                        </div>
                        <div style="font-size: 12px; color: #2e7d32;">Guards</div>
                    </div>
                </div>
            </div>
        </div>
    `).join('');
}

function showCreateSociety() {
    document.getElementById('create-society-modal').style.display = 'block';
    document.getElementById('create-society-form').reset();
}

function closeCreateSociety() {
    document.getElementById('create-society-modal').style.display = 'none';
}

async function submitCreateSociety(event) {
    event.preventDefault();
    
    const societyData = {
        name: document.getElementById('society-name').value,
        address: document.getElementById('society-address').value,
        city: document.getElementById('society-city').value,
        state: document.getElementById('society-state').value,
        pincode: document.getElementById('society-pincode').value
    };
    
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/societies`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(societyData)
        });
        
        const data = await response.json();
        
        if (data.success) {
            closeCreateSociety();
            
            // Ask if user wants to add guards now
            const addGuards = confirm(`✅ Society created successfully!\nSociety ID: ${data.society.societyId}\n\nWould you like to add guards now?`);
            
            if (addGuards) {
                // Navigate to society detail page
                await viewSocietyDetail(data.society._id);
                // Open add guard modal after a short delay
                setTimeout(() => showAddGuard(), 500);
            } else {
                loadSocieties();
                loadDashboardStats();
            }
        } else {
            alert('Failed to create society: ' + data.error);
        }
    } catch (error) {
        console.error('Error creating society:', error);
        alert('Failed to create society. Please try again.');
    }
}

// ============= SOCIETY DETAIL =============
async function viewSocietyDetail(societyId) {
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/societies/${societyId}`);
        const data = await response.json();
        currentSociety = data.society;
        
        // Hide all sections first
        document.querySelectorAll('.content-section').forEach(sec => {
            sec.classList.remove('active');
        });
        
        // Show society detail section
        const detailSection = document.getElementById('society-detail-section');
        if (detailSection) {
            detailSection.classList.add('active');
        }
        
        // Update page title
        document.getElementById('page-title').textContent = currentSociety.name;
        
        // Update nav (remove active from all)
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
        
        const content = document.getElementById('society-detail-content');
        content.innerHTML = `
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                <button class="btn btn-secondary" onclick="backToSocieties()" style="background: #718096;">
                    ← Back to Societies
                </button>
            </div>
            <div class="society-detail-header">
                <h2>${currentSociety.name}</h2>
                <p style="color: #718096; margin: 8px 0;">🆔 Society ID: ${currentSociety.societyId || currentSociety._id}</p>
                <p style="color: #718096;">📍 ${currentSociety.address}, ${currentSociety.city}, ${currentSociety.state} - ${currentSociety.pincode}</p>
            </div>
            
            <div class="society-tabs">
                <button class="tab-btn active" onclick="showSocietyTab('guards')">🛡️ Guards</button>
                <button class="tab-btn" onclick="showSocietyTab('activity')">📊 Activity Logs</button>
            </div>
            
            <div id="society-tab-content"></div>
        `;
        
        showSocietyTab('guards');
        
    } catch (error) {
        console.error('Error loading society details:', error);
        alert('Failed to load society details');
    }
}

function backToSocieties() {
    currentSociety = null;
    document.querySelectorAll('.nav-item').forEach((item, index) => {
        item.classList.remove('active');
        if (index === 1) { // Societies nav item
            item.classList.add('active');
        }
    });
    showSection('societies');
}

async function showSocietyTab(tab) {
    // Update tabs
    document.querySelectorAll('.society-tabs .tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');
    
    const content = document.getElementById('society-tab-content');
    
    if (tab === 'guards') {
        await loadSocietyGuards();
    } else if (tab === 'activity') {
        content.innerHTML = `
            <div class="info-box">
                📊 Activity logs coming soon...
            </div>
        `;
    }
}

async function loadSocietyGuards() {
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/societies/${currentSociety._id}/guards`);
        const data = await response.json();
        const guards = data.guards || [];
        
        const content = document.getElementById('society-tab-content');
        content.innerHTML = `
            <div style="margin-bottom: 20px;">
                <button class="btn btn-primary" onclick="showAddGuard()">➕ Add Guard</button>
            </div>
            
            <div class="guards-table">
                ${guards.length > 0 ? `
                    <table>
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Email</th>
                                <th>Phone</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${guards.map(guard => `
                                <tr>
                                    <td>${guard.name}</td>
                                    <td>${guard.email}</td>
                                    <td>${guard.phone || 'N/A'}</td>
                                    <td>
                                        <span class="status-badge ${guard.active ? 'active' : 'disabled'}">
                                            ${guard.active ? 'Active' : 'Disabled'}
                                        </span>
                                    </td>
                                    <td>
                                        <button class="btn btn-secondary" onclick="toggleGuardStatus('${guard._id}', ${!guard.active})">
                                            ${guard.active ? 'Disable' : 'Enable'}
                                        </button>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                ` : '<p style="padding: 20px; text-align: center; color: #718096;">No guards added yet</p>'}
            </div>
        `;
    } catch (error) {
        console.error('Error loading guards:', error);
    }
}

function showAddGuard() {
    document.getElementById('add-guard-modal').style.display = 'block';
    document.getElementById('add-guard-form').reset();
}

function closeAddGuard() {
    document.getElementById('add-guard-modal').style.display = 'none';
}

async function submitAddGuard(event) {
    event.preventDefault();
    
    const guardData = {
        name: document.getElementById('guard-name').value,
        email: document.getElementById('guard-email').value,
        phone: document.getElementById('guard-phone').value,
        societyId: currentSociety._id
    };
    
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/admin/guards/create`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(guardData)
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert(`✅ Guard added successfully!\n\nCredentials sent to: ${guardData.email}\nEmail: ${data.guard.email}\nTemporary Password: ${data.tempPassword || 'Check email'}`);
            closeAddGuard();
            loadSocietyGuards();
            loadDashboardStats();
        } else {
            alert('Failed to add guard: ' + data.error);
        }
    } catch (error) {
        console.error('Error adding guard:', error);
        alert('Failed to add guard. Please try again.');
    }
}

async function toggleGuardStatus(guardId, newStatus) {
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/admin/guards/${guardId}/status`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ active: newStatus })
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert(`✅ Guard ${newStatus ? 'enabled' : 'disabled'} successfully`);
            loadSocietyGuards();
        } else {
            alert('Failed to update guard status');
        }
    } catch (error) {
        console.error('Error updating guard status:', error);
        alert('Failed to update guard status');
    }
}

// ============= AGENT VERIFICATION (Existing code adapted) =============
async function loadAgents() {
    try {
        console.log('📋 Loading agents from API...');
        showLoading('agents-container');
        const response = await fetch(`${CONFIG.API_BASE_URL}/agents/all`);
        const data = await response.json();
        allAgents = data.agents || [];
        
        // Load all verifications to show OCR results alongside agents
        try {
            const verifyResponse = await fetch(`${CONFIG.API_BASE_URL}/verification/pending`);
            const verifyData = await verifyResponse.json();
            if (verifyData.success) {
                allVerifications = verifyData.results || [];
                console.log(`🤖 Loaded ${allVerifications.length} auto-verifications`);
                if (allVerifications.length > 0) {
                    console.log('📋 Verification IDs:', allVerifications.map(v => ({ id: v._id, agentId: v.agentId?._id || v.agentId, email: v.agentId?.email })));
                }
            }
        } catch (e) {
            console.log('⚠️ Could not load verifications:', e);
            allVerifications = [];
        }
        
        console.log(`✅ Loaded ${allAgents.length} agents:`, allAgents);
        console.log('📊 Agent Status Breakdown:');
        console.log('  - Pending:', allAgents.filter(a => !a.verified && !a.rejected).length);
        console.log('  - Verified:', allAgents.filter(a => a.verified).length);
        console.log('  - Rejected:', allAgents.filter(a => a.rejected).length);
        filterAgents(currentFilter);
    } catch (error) {
        console.error('❌ Error loading agents:', error);
        showError('agents-container', 'Failed to load agents');
    }
}

function filterAgents(filter) {
    currentFilter = filter;
    
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.classList.remove('active');
        if (btn.dataset.filter === filter) {
            btn.classList.add('active');
        }
    });
    
    switch(filter) {
        case 'pending':
            filteredAgents = allAgents.filter(a => !a.verified && !a.rejected);
            break;
        case 'verified':
            filteredAgents = allAgents.filter(a => a.verified);
            break;
        case 'rejected':
            filteredAgents = allAgents.filter(a => a.rejected);
            break;
        default:
            filteredAgents = [...allAgents];
    }
    
    displayAgents();
}

function searchAgents() {
    const searchTerm = document.getElementById('search-input').value.toLowerCase();
    
    if (!searchTerm) {
        filterAgents(currentFilter);
        return;
    }
    
    filteredAgents = allAgents.filter(agent => {
        return agent.name.toLowerCase().includes(searchTerm) ||
               agent.email.toLowerCase().includes(searchTerm) ||
               (agent.company && agent.company.toLowerCase().includes(searchTerm));
    });
    
    displayAgents();
}

function displayAgents() {
    const container = document.getElementById('agents-container');
    
    console.log(`🎨 Displaying ${filteredAgents.length} agents with filter: ${currentFilter}`);
    
    if (filteredAgents.length === 0) {
        container.innerHTML = `
            <div class="no-data">
                <span class="icon">📭</span>
                <p>No agents found</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = filteredAgents.map(agent => createAgentCard(agent)).join('');
}

function createAgentCard(agent) {
    const statusBadge = agent.verified 
        ? `<span class="status-badge active">✅ Verified</span>`
        : agent.rejected
        ? `<span class="status-badge disabled">❌ Rejected</span>`
        : `<span class="status-badge" style="background: #fef5e7; color: #f57c00;">⏳ Pending</span>`;
    
    const photoUrl = agent.photo 
        ? `${CONFIG.API_BASE_URL.replace('/api', '')}${agent.photo}`
        : 'https://via.placeholder.com/80?text=No+Photo';
    
    // Check if verification exists for this agent (with safety check)
    const verification = allVerifications?.find(v => v.agentId?._id === agent._id || v.agentId?.email === agent.email);
    let verificationBadge = '';
    if (verification) {
        const riskClass = verification.riskLevel.toLowerCase();
        verificationBadge = `<span class="risk-badge risk-${riskClass}" style="font-size: 11px; padding: 4px 8px;">${verification.riskLevel} (${verification.riskScore})</span>`;
    }
    
    return `
        <div class="agent-card" onclick="viewAgentDetails('${agent.email}')">
            <div style="display: flex; gap: 20px; align-items: center;">
                <img src="${photoUrl}" alt="${agent.name}" 
                     style="width: 80px; height: 80px; border-radius: 12px; object-fit: cover;"
                     onerror="this.src='https://via.placeholder.com/80?text=No+Photo'">
                <div style="flex: 1;">
                    <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 8px;">
                        <h3 style="font-size: 18px; margin: 0;">${agent.name}</h3>
                        ${statusBadge}
                        ${verificationBadge}
                        ${agent.verified ? `<span class="status-badge" style="background: #e3f2fd; color: #1976d2;">⭐ ${agent.score}/100</span>` : ''}
                    </div>
                    <p style="color: #718096; font-size: 14px; margin: 4px 0;">📧 ${agent.email}</p>
                    <p style="color: #718096; font-size: 14px; margin: 4px 0;">🏢 ${agent.company || 'N/A'}</p>
                    ${verification ? `<p style="color: #e67e22; font-size: 13px; margin: 4px 0; font-weight: 500;">🤖 Auto-Verified: ${verification.recommendation}</p>` : ''}
                </div>
                <div style="display: flex; gap: 8px;">
                    ${verification && !agent.verified && !agent.rejected ? `
                        <button class="btn btn-sm" style="background: #9b59b6; color: white;" onclick="event.stopPropagation(); viewVerificationDetail('${verification._id}')">
                            📄 View OCR
                        </button>
                    ` : ''}
                    ${!agent.verified && !agent.rejected ? `
                        <button class="btn btn-success" onclick="event.stopPropagation(); openVerifyModal('${agent.email}')">
                            ✅ Verify
                        </button>
                    ` : agent.verified ? `
                        <span class="badge badge-info">QR: View in Mobile App</span>
                    ` : ''}
                </div>
            </div>
        </div>
    `;
}

function viewAgentDetails(email) {
    const agent = allAgents.find(a => a.email === email);
    if (!agent) return;
    
    currentAgent = agent;
    
    const photoUrl = agent.photo 
        ? `${CONFIG.API_BASE_URL.replace('/api', '')}${agent.photo}`
        : 'https://via.placeholder.com/200?text=No+Photo';
    
    const modalBody = document.getElementById('agent-modal-body');
    modalBody.innerHTML = `
        <div style="text-align: center; margin-bottom: 20px;">
            <img src="${photoUrl}" alt="${agent.name}" 
                 style="max-width: 200px; border-radius: 12px;"
                 onerror="this.src='https://via.placeholder.com/200?text=No+Photo'">
        </div>
        <div class="detail-row" style="padding: 12px 0; border-bottom: 1px solid #e2e8f0;">
            <strong>Name:</strong> ${agent.name}
        </div>
        <div class="detail-row" style="padding: 12px 0; border-bottom: 1px solid #e2e8f0;">
            <strong>Email:</strong> ${agent.email}
        </div>
        <div class="detail-row" style="padding: 12px 0; border-bottom: 1px solid #e2e8f0;">
            <strong>Company:</strong> ${agent.company || 'N/A'}
        </div>
        <div class="detail-row" style="padding: 12px 0; border-bottom: 1px solid #e2e8f0;">
            <strong>Status:</strong> ${agent.verified ? '✅ Verified' : agent.rejected ? '❌ Rejected' : '⏳ Pending'}
        </div>
        ${agent.verified ? `
        <div class="detail-row" style="padding: 12px 0; border-bottom: 1px solid #e2e8f0;">
            <strong>Trust Score:</strong> ⭐ ${agent.score}/100
        </div>
        ` : ''}
        <div style="margin-top: 24px; display: flex; gap: 12px; justify-content: center;">
            ${!agent.verified && !agent.rejected ? `
                <button class="btn btn-success" onclick="openVerifyModal('${agent.email}')">✅ Verify Agent</button>
                <button class="btn btn-danger" onclick="rejectAgentDirect('${agent.email}')">❌ Reject</button>
            ` : agent.verified ? `
                <p class="text-muted"><i>📱 QR Code: Available in Agent Mobile App only</i></p>
            ` : ''}
        </div>
    `;
    
    document.getElementById('agent-modal').style.display = 'block';
}

function openVerifyModal(email) {
    const agent = allAgents.find(a => a.email === email);
    if (!agent) return;
    
    currentAgent = agent;
    document.getElementById('verification-score').value = CONFIG.DEFAULT_SCORE;
    document.getElementById('score-bar').style.width = CONFIG.DEFAULT_SCORE + '%';
    document.getElementById('verification-notes').value = '';
    
    closeAgentModal();
    document.getElementById('verify-modal').style.display = 'block';
}

async function approveAgent() {
    if (!currentAgent) return;
    
    const score = parseInt(document.getElementById('verification-score').value);
    const notes = document.getElementById('verification-notes').value;
    
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/agents/admin/verify/${currentAgent.email}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ score, notes })
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert(`✅ Agent verified successfully with score ${score}/100`);
            closeVerifyModal();
            loadAgents();
            loadDashboardStats();
        } else {
            alert('Failed to verify agent: ' + data.error);
        }
    } catch (error) {
        console.error('Error verifying agent:', error);
        alert('Failed to verify agent');
    }
}

async function rejectAgent() {
    if (!currentAgent) return;
    await rejectAgentDirect(currentAgent.email);
    closeVerifyModal();
}

async function rejectAgentDirect(email) {
    if (!confirm('Are you sure you want to reject this agent?')) return;
    
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/agents/admin/reject/${email}`, {
            method: 'POST'
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert('❌ Agent rejected');
            closeAgentModal();
            loadAgents();
            loadDashboardStats();
        } else {
            alert('Failed to reject agent');
        }
    } catch (error) {
        console.error('Error rejecting agent:', error);
        alert('Failed to reject agent');
    }
}

// QR Code generation removed - QR codes are only generated in the mobile app
// This ensures consistency and proper signature/hash generation

function downloadQR() {
    if (!currentAgent) return;
    
    const qrCanvas = document.querySelector('#qr-container canvas');
    if (!qrCanvas) return;
    
    const link = document.createElement('a');
    link.download = `agent-qr-${currentAgent.email}.png`;
    link.href = qrCanvas.toDataURL();
    link.click();
}

function printQR() {
    if (!currentAgent) return;
    
    const qrCanvas = document.querySelector('#qr-container canvas');
    if (!qrCanvas) return;
    
    const printWindow = window.open('', '', 'width=600,height=600');
    printWindow.document.write(`
        <html>
        <head>
            <title>Agent QR Code - ${currentAgent.name}</title>
            <style>
                body { font-family: Arial, sans-serif; text-align: center; padding: 40px; }
                h1 { margin-bottom: 20px; }
                img { margin: 20px 0; }
            </style>
        </head>
        <body>
            <h1>Agent QR Code</h1>
            <h2>${currentAgent.name}</h2>
            <img src="${qrCanvas.toDataURL()}" />
            <p><strong>Email:</strong> ${currentAgent.email}</p>
            <p><strong>Company:</strong> ${currentAgent.company || 'N/A'}</p>
            <p><strong>Trust Score:</strong> ${currentAgent.score || 0}/100</p>
        </body>
        </html>
    `);
    printWindow.document.close();
    printWindow.print();
}

// ============= MONITORING =============
async function loadMonitoring() {
    showMonitoringTab('sos');
}

async function showMonitoringTab(tab) {
    document.querySelectorAll('.monitoring-tabs .tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');
    
    const content = document.getElementById('monitoring-content');
    
    if (tab === 'sos') {
        try {
            const response = await fetch(`${CONFIG.API_BASE_URL}/sos`);
            const data = await response.json();
            const alerts = data.alerts || [];
            
            content.innerHTML = `
                <div style="background: white; border-radius: 12px; padding: 20px;">
                    <h3>SOS Alerts (Read-only)</h3>
                    ${alerts.length > 0 ? `
                        <table style="width: 100%; margin-top: 20px;">
                            <thead>
                                <tr style="background: #f7fafc;">
                                    <th style="padding: 12px; text-align: left;">Date</th>
                                    <th style="padding: 12px; text-align: left;">Resident</th>
                                    <th style="padding: 12px; text-align: left;">Society</th>
                                    <th style="padding: 12px; text-align: left;">Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${alerts.slice(0, 20).map(alert => `
                                    <tr style="border-bottom: 1px solid #e2e8f0;">
                                        <td style="padding: 12px;">${new Date(alert.triggeredAt).toLocaleString()}</td>
                                        <td style="padding: 12px;">${alert.triggeredBy?.name || 'Unknown'}</td>
                                        <td style="padding: 12px;">${alert.societyId?.name || 'N/A'}</td>
                                        <td style="padding: 12px;">
                                            <span class="status-badge ${alert.status === 'resolved' ? 'active' : ''}">${alert.status}</span>
                                        </td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                    ` : '<p style="padding: 20px; text-align: center; color: #718096;">No SOS alerts</p>'}
                </div>
            `;
        } catch (error) {
            content.innerHTML = '<div class="info-box">Failed to load SOS alerts</div>';
        }
    } else {
        content.innerHTML = '<div class="info-box">Coming soon...</div>';
    }
}

// ============= MODALS =============
function closeAgentModal() {
    document.getElementById('agent-modal').style.display = 'none';
}

function closeQRModal() {
    document.getElementById('qr-modal').style.display = 'none';
}

function closeVerifyModal() {
    document.getElementById('verify-modal').style.display = 'none';
}

// Close modals when clicking outside
window.onclick = function(event) {
    const modals = ['agent-modal', 'qr-modal', 'verify-modal', 'create-society-modal', 'add-guard-modal'];
    modals.forEach(modalId => {
        const modal = document.getElementById(modalId);
        if (event.target === modal) {
            modal.style.display = 'none';
        }
    });
}

// ============= SOS ALERTS MANAGEMENT =============
let allSOSAlerts = [];
let currentSOSFilter = 'all';

async function loadSOSAlerts() {
    try {
        showLoading('sos-alerts-container');
        console.log('📡 Fetching SOS alerts from API...');
        
        // Use the police/dashboard endpoint which doesn't require auth
        const response = await fetch(`${CONFIG.API_BASE_URL}/sos/police/dashboard`);
        console.log('Response status:', response.status);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('📊 SOS data received:', data);
        
        // Handle different response formats
        if (data.status === 'success' && data.data) {
            allSOSAlerts = data.data.events || [];
        } else if (data.sosEvents) {
            allSOSAlerts = data.sosEvents;
        } else if (Array.isArray(data)) {
            allSOSAlerts = data;
        } else {
            allSOSAlerts = [];
        }
        
        console.log(`✅ Loaded ${allSOSAlerts.length} SOS alerts`);
        displaySOSAlerts();
    } catch (error) {
        console.error('❌ Error loading SOS alerts:', error);
        showError('sos-alerts-container', 'Failed to load SOS alerts. Please try again.');
    }
}

function displaySOSAlerts() {
    const container = document.getElementById('sos-alerts-container');
    
    // Filter alerts based on current filter
    let filteredAlerts = allSOSAlerts;
    if (currentSOSFilter !== 'all') {
        filteredAlerts = allSOSAlerts.filter(alert => 
            (alert.status || '').toLowerCase() === currentSOSFilter
        );
    }
    
    // Sort by most recent first
    filteredAlerts.sort((a, b) => {
        const dateA = new Date(a.triggeredAt || a.createdAt);
        const dateB = new Date(b.triggeredAt || b.createdAt);
        return dateB - dateA;
    });
    
    if (filteredAlerts.length === 0) {
        container.innerHTML = `
            <div class="no-data">
                <span class="icon">🚨</span>
                <p>No ${currentSOSFilter === 'all' ? '' : currentSOSFilter + ' '}SOS alerts found</p>
                ${currentSOSFilter !== 'all' ? '<button class="btn btn-secondary" onclick="filterSOS(\'all\')">Show All Alerts</button>' : ''}
            </div>
        `;
        return;
    }
    
    container.innerHTML = filteredAlerts.map(alert => {
        const statusClass = getSOSStatusClass(alert.status);
        const statusIcon = getSOSStatusIcon(alert.status);
        const triggerTime = formatSOSTime(alert.triggeredAt || alert.createdAt);
        const userName = alert.userName || alert.triggeredBy?.name || 'Unknown User';
        const userRole = alert.userRole || alert.triggeredBy?.role || '';
        const flatNumber = alert.flatNumber || 'N/A';
        const description = alert.description || 'Emergency assistance required';
        const location = formatSOSLocation(alert);
        
        return `
            <div class="sos-alert-card ${statusClass}">
                <div class="sos-alert-header">
                    <div class="sos-alert-id">
                        <strong>🆔 ${alert.sosId || alert._id}</strong>
                        <span class="sos-status-badge ${statusClass}">${statusIcon} ${(alert.status || 'active').toUpperCase()}</span>
                    </div>
                    <div class="sos-alert-time">${triggerTime}</div>
                </div>
                <div class="sos-alert-body">
                    <div class="sos-info-row">
                        <span class="sos-label">👤 Triggered By:</span>
                        <span class="sos-value">${userName} ${userRole ? `(${userRole})` : ''}</span>
                    </div>
                    <div class="sos-info-row">
                        <span class="sos-label">🏠 Flat Number:</span>
                        <span class="sos-value">${flatNumber}</span>
                    </div>
                    ${location ? `
                    <div class="sos-info-row">
                        <span class="sos-label">📍 Location:</span>
                        <span class="sos-value">${location}</span>
                    </div>
                    ` : ''}
                    <div class="sos-info-row">
                        <span class="sos-label">📝 Description:</span>
                        <span class="sos-value">${description}</span>
                    </div>
                </div>
                <div class="sos-alert-actions">
                    ${alert.status === 'active' || alert.status === 'triggered' ? `
                        <button class="btn btn-sm btn-success" onclick="acknowledgeSOS('${alert.sosId || alert._id}')">
                            ✅ Acknowledge
                        </button>
                        <button class="btn btn-sm btn-primary" onclick="resolveSOS('${alert.sosId || alert._id}')">
                            ✔️ Resolve
                        </button>
                    ` : ''}
                    <button class="btn btn-sm btn-secondary" onclick="viewSOSDetail('${alert.sosId || alert._id}')">
                        👁️ View Details
                    </button>
                </div>
            </div>
        `;
    }).join('');
}

function filterSOS(status) {
    currentSOSFilter = status;
    
    // Update filter button states
    document.querySelectorAll('.sos-filters .filter-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');
    
    displaySOSAlerts();
}

function getSOSStatusClass(status) {
    const statusMap = {
        'active': 'sos-critical',
        'triggered': 'sos-critical',
        'acknowledged': 'sos-warning',
        'resolved': 'sos-success',
        'false_alarm': 'sos-muted'
    };
    return statusMap[status?.toLowerCase()] || 'sos-critical';
}

function getSOSStatusIcon(status) {
    const iconMap = {
        'active': '🚨',
        'triggered': '🚨',
        'acknowledged': '👀',
        'resolved': '✅',
        'false_alarm': '❌'
    };
    return iconMap[status?.toLowerCase()] || '🚨';
}

function formatSOSTime(timestamp) {
    if (!timestamp) return 'Unknown time';
    
    const date = new Date(timestamp);
    const now = new Date();
    const diffMs = now - date;
    const diffMins = Math.floor(diffMs / 60000);
    
    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins} min ago`;
    if (diffMins < 1440) return `${Math.floor(diffMins / 60)} hours ago`;
    
    return date.toLocaleString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function formatSOSLocation(alert) {
    if (alert.locationAddress) return alert.locationAddress;
    if (alert.location?.address) return alert.location.address;
    if (alert.latitude && alert.longitude) {
        return `${alert.latitude}, ${alert.longitude}`;
    }
    if (alert.location?.latitude && alert.location?.longitude) {
        return `${alert.location.latitude}, ${alert.location.longitude}`;
    }
    return null;
}

async function acknowledgeSOS(sosId) {
    if (!confirm('Acknowledge this SOS alert?')) return;
    
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/sos/${sosId}/acknowledge`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' }
        });
        
        if (response.ok) {
            alert('✅ SOS alert acknowledged');
            loadSOSAlerts();
        } else {
            alert('❌ Failed to acknowledge SOS');
        }
    } catch (error) {
        console.error('Error acknowledging SOS:', error);
        alert('❌ Error acknowledging SOS');
    }
}

async function resolveSOS(sosId) {
    const notes = prompt('Enter resolution notes (optional):');
    if (notes === null) return; // User cancelled
    
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/sos/${sosId}/resolve`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                outcome: 'safe',
                notes: notes || 'Resolved by admin'
            })
        });
        
        if (response.ok) {
            alert('✅ SOS alert resolved');
            loadSOSAlerts();
        } else {
            alert('❌ Failed to resolve SOS');
        }
    } catch (error) {
        console.error('Error resolving SOS:', error);
        alert('❌ Error resolving SOS');
    }
}

function viewSOSDetail(sosId) {
    const alert = allSOSAlerts.find(a => (a.sosId || a._id) === sosId);
    if (!alert) return;
    
    const detail = `
        🆔 SOS ID: ${alert.sosId || alert._id}
        
        📅 Triggered: ${new Date(alert.triggeredAt || alert.createdAt).toLocaleString()}
        📊 Status: ${(alert.status || 'active').toUpperCase()}
        
        👤 User: ${alert.userName || alert.triggeredBy?.name || 'Unknown'}
        📧 Email: ${alert.triggeredBy?.email || 'N/A'}
        📱 Phone: ${alert.triggeredBy?.phone || 'N/A'}
        🏠 Flat: ${alert.flatNumber || 'N/A'}
        
        📝 Description: ${alert.description || 'No description'}
        📍 Location: ${formatSOSLocation(alert) || 'No location data'}
        
        ${alert.resolvedAt ? `✅ Resolved: ${new Date(alert.resolvedAt).toLocaleString()}` : ''}
        ${alert.resolutionNotes ? `📄 Notes: ${alert.resolutionNotes}` : ''}
    `;
    
    alert(detail);
}

// ============= UTILITIES =============
function showLoading(containerId) {
    document.getElementById(containerId).innerHTML = `
        <div class="loading-spinner">
            <div class="spinner"></div>
            <p>Loading...</p>
        </div>
    `;
}

function showError(containerId, message) {
    document.getElementById(containerId).innerHTML = `
        <div class="no-data">
            <span class="icon">❌</span>
            <p>${message}</p>
        </div>
    `;
}

// ============= DOCUMENT VERIFICATION =============

// Load verification stats
async function loadVerificationStats() {
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/verification/stats`);
        const data = await response.json();
        
        if (data.success) {
            document.getElementById('pending-count').textContent = data.stats.pending;
            document.getElementById('critical-count').textContent = data.stats.criticalRisk;
            document.getElementById('approved-count').textContent = data.stats.approved;
            document.getElementById('rejected-count').textContent = data.stats.rejected;
        }
    } catch (error) {
        console.error('Failed to load verification stats:', error);
    }
}

// Load pending verifications
async function loadPendingVerifications() {
    showLoading('verifications-container');
    
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/verification/pending`);
        const data = await response.json();
        
        if (data.success) {
            allVerifications = data.results;
            displayVerifications(allVerifications);
            loadVerificationStats();
        } else {
            showError('verifications-container', data.message || 'Failed to load verifications');
        }
    } catch (error) {
        console.error('Error loading verifications:', error);
        showError('verifications-container', 'Failed to load verifications');
    }
}

// Display verifications
function displayVerifications(verifications) {
    const container = document.getElementById('verifications-container');
    
    if (!verifications || verifications.length === 0) {
        container.innerHTML = `
            <div class="no-data">
                <span class="icon">📄</span>
                <p>No verifications found</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = verifications.map(v => {
        const riskClass = v.riskLevel.toLowerCase();
        const agent = v.agentId || {};
        
        return `
            <div class="verification-card" onclick="viewVerificationDetail('${v._id}')">
                <div class="verification-header">
                    <div class="verification-info">
                        <h3>${agent.name || 'Unknown Agent'}</h3>
                        <p>Document ID: ${v.documentId}</p>
                        <p style="font-size: 12px; color: #9ca3af;">
                            ${new Date(v.verifiedAt).toLocaleString()}
                        </p>
                    </div>
                    <span class="risk-badge risk-${riskClass}">${v.riskLevel}</span>
                </div>
                
                <div class="verification-details">
                    <div class="detail-item">
                        <span class="detail-label">Risk Score</span>
                        <span class="detail-value">${v.riskScore}/100</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Validation</span>
                        <span class="detail-value">${Math.round(v.validation.overallScore * 100)}%</span>
                    </div>
                    <div class="detail-item">
                        <span class="detail-label">Tampered</span>
                        <span class="detail-value">${v.forensics.tampered ? '⚠️ Yes' : '✅ No'}</span>
                    </div>
                </div>
                
                <div class="verification-actions">
                    <button class="btn btn-sm btn-primary" onclick="event.stopPropagation(); viewVerificationDetail('${v._id}')">
                        View Details
                    </button>
                    <button class="btn btn-sm btn-success" onclick="event.stopPropagation(); quickApprove('${v._id}')">
                        ✅ Approve
                    </button>
                    <button class="btn btn-sm btn-secondary" onclick="event.stopPropagation(); quickReject('${v._id}')">
                        ❌ Reject
                    </button>
                </div>
            </div>
        `;
    }).join('');
}

// Filter verifications
function filterVerifications(filter) {
    // Update active button
    document.querySelectorAll('.verification-filters .filter-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');
    
    let filtered = allVerifications;
    
    if (filter === 'pending') {
        filtered = allVerifications.filter(v => v.adminDecision.status === 'PENDING');
    } else if (filter === 'critical') {
        filtered = allVerifications.filter(v => v.riskLevel === 'CRITICAL');
    }
    
    displayVerifications(filtered);
}

// View verification detail
async function viewVerificationDetail(verificationId) {
    try {
        console.log('🔍 Fetching verification details for ID:', verificationId);
        
        if (!verificationId) {
            console.error('❌ No verification ID provided');
            alert('Failed to load verification details: No verification ID');
            return;
        }
        
        const response = await fetch(`${CONFIG.API_BASE_URL}/verification/result/${verificationId}`);
        console.log('📡 Response status:', response.status);
        
        if (!response.ok) {
            const errorText = await response.text();
            console.error('❌ API Error:', errorText);
            throw new Error(`HTTP ${response.status}: ${errorText}`);
        }
        
        const data = await response.json();
        console.log('📦 Received data:', data);
        
        if (data.success) {
            currentVerification = data.result;
            showVerificationModal(data.result);
        } else {
            console.error('❌ API returned success=false:', data.message);
            alert('Failed to load verification details: ' + (data.message || 'Unknown error'));
        }
    } catch (error) {
        console.error('❌ Error loading verification:', error);
        alert('Failed to load verification details: ' + error.message);
    }
}

// Show verification modal
function showVerificationModal(v) {
    const agent = v.agentId || {};
    const ocr = v.ocrResults.extractedFields;
    const riskClass = v.riskLevel.toLowerCase();
    
    const modalBody = document.getElementById('doc-verification-body');
    modalBody.innerHTML = `
        <div class="doc-preview">
            <img src="${CONFIG.API_BASE_URL.replace('/api', '')}/${v.documentPath}" 
                 alt="Document" 
                 onerror="this.src='data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 width=%22400%22 height=%22300%22><rect width=%22400%22 height=%22300%22 fill=%22%23f3f4f6%22/><text x=%2250%%22 y=%2250%%22 font-family=%22Arial%22 font-size=%2218%22 fill=%22%236b7280%22 text-anchor=%22middle%22>Document Not Available</text></svg>'">
        </div>
        
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
            <div>
                <h3 style="margin-bottom: 4px;">${agent.name || 'Unknown Agent'}</h3>
                <p style="color: #6b7280; font-size: 14px;">Document ID: ${v.documentId}</p>
            </div>
            <span class="risk-badge risk-${riskClass}">${v.riskLevel} RISK (${v.riskScore}/100)</span>
        </div>
        
        <div class="ocr-results">
            <h3>📝 Extracted Information (OCR)</h3>
            <div class="ocr-field">
                <span class="field-label">Name:</span>
                <span class="field-value">${ocr.name || 'Not found'}</span>
            </div>
            <div class="ocr-field">
                <span class="field-label">ID Number:</span>
                <span class="field-value">${ocr.idNumber || 'Not found'}</span>
            </div>
            <div class="ocr-field">
                <span class="field-label">Date of Birth:</span>
                <span class="field-value">${ocr.dateOfBirth || 'Not found'}</span>
            </div>
            <div class="ocr-field">
                <span class="field-label">Expiry Date:</span>
                <span class="field-value">${ocr.expiryDate || 'Not found'}</span>
            </div>
            <div class="ocr-field">
                <span class="field-label">Gender:</span>
                <span class="field-value">${ocr.gender || 'Not found'}</span>
            </div>
            <div class="ocr-field">
                <span class="field-label">Confidence:</span>
                <span class="field-value">${Math.round(v.ocrResults.confidence * 100)}%</span>
            </div>
        </div>
        
        <div class="analysis-section">
            <h4>🔍 Validation Analysis</h4>
            <div class="analysis-grid">
                <div class="analysis-item ${v.validation.imageQuality.isGood ? 'success' : 'warning'}">
                    <div class="analysis-title">Image Quality</div>
                    <div class="analysis-value">${v.validation.imageQuality.score.toFixed(2)}</div>
                </div>
                <div class="analysis-item ${v.validation.templateValidation.isValid ? 'success' : 'error'}">
                    <div class="analysis-title">Template Valid</div>
                    <div class="analysis-value">${v.validation.templateValidation.isValid ? '✅ Yes' : '❌ No'}</div>
                </div>
                <div class="analysis-item ${v.validation.fieldValidation.allValid ? 'success' : 'warning'}">
                    <div class="analysis-title">Fields Valid</div>
                    <div class="analysis-value">${v.validation.fieldValidation.allValid ? '✅ Yes' : '⚠️ Issues'}</div>
                </div>
                <div class="analysis-item ${v.validation.overallScore > 0.7 ? 'success' : 'warning'}">
                    <div class="analysis-title">Overall Score</div>
                    <div class="analysis-value">${Math.round(v.validation.overallScore * 100)}%</div>
                </div>
            </div>
        </div>
        
        <div class="analysis-section">
            <h4>🔬 Forensics Analysis</h4>
            <div class="analysis-grid">
                <div class="analysis-item ${v.forensics.tampered ? 'error' : 'success'}">
                    <div class="analysis-title">Tampering Detected</div>
                    <div class="analysis-value">${v.forensics.tampered ? '⚠️ Yes' : '✅ No'}</div>
                </div>
                <div class="analysis-item ${v.forensics.tamperScore > 0.5 ? 'error' : 'success'}">
                    <div class="analysis-title">Tamper Score</div>
                    <div class="analysis-value">${Math.round(v.forensics.tamperScore * 100)}%</div>
                </div>
                <div class="analysis-item">
                    <div class="analysis-title">Indicators Found</div>
                    <div class="analysis-value">${v.forensics.indicators.length}</div>
                </div>
            </div>
            ${v.forensics.indicators.length > 0 ? `
                <div style="margin-top: 12px; padding: 12px; background: #fef3c7; border-radius: 6px;">
                    <strong>⚠️ Issues Found:</strong>
                    <ul style="margin: 8px 0 0 20px;">
                        ${v.forensics.indicators.map(i => `<li>${i}</li>`).join('')}
                    </ul>
                </div>
            ` : ''}
        </div>
        
        <div class="analysis-section">
            <h4>📊 Metadata Analysis</h4>
            <div class="analysis-grid">
                <div class="analysis-item ${v.metadata.hasEditingSoftware ? 'error' : 'success'}">
                    <div class="analysis-title">Editing Software</div>
                    <div class="analysis-value">${v.metadata.hasEditingSoftware ? '⚠️ Detected' : '✅ None'}</div>
                </div>
                <div class="analysis-item ${v.metadata.isScreenshot ? 'error' : 'success'}">
                    <div class="analysis-title">Screenshot</div>
                    <div class="analysis-value">${v.metadata.isScreenshot ? '⚠️ Yes' : '✅ No'}</div>
                </div>
                <div class="analysis-item ${v.metadata.hasCameraMetadata ? 'success' : 'warning'}">
                    <div class="analysis-title">Camera Metadata</div>
                    <div class="analysis-value">${v.metadata.hasCameraMetadata ? '✅ Present' : '⚠️ Missing'}</div>
                </div>
                <div class="analysis-item">
                    <div class="analysis-title">Metadata Risk</div>
                    <div class="analysis-value">${v.metadata.risk}</div>
                </div>
            </div>
        </div>
        
        <div class="decision-form">
            <h4 style="margin-bottom: 12px;">💡 Recommendation: ${v.recommendation}</h4>
            <label style="display: block; margin-bottom: 8px; font-weight: 500;">Decision Notes:</label>
            <textarea id="decision-notes" placeholder="Enter your decision notes..."></textarea>
            <div class="decision-actions">
                <button class="btn btn-approve" onclick="approveVerification('${v._id}')">
                    ✅ Approve Document
                </button>
                <button class="btn btn-reject" onclick="rejectVerification('${v._id}')">
                    ❌ Reject Document
                </button>
            </div>
        </div>
    `;
    
    document.getElementById('doc-verification-modal').style.display = 'block';
}

// Close verification modal
function closeDocVerificationModal() {
    document.getElementById('doc-verification-modal').style.display = 'none';
    currentVerification = null;
}

// Approve verification
async function approveVerification(verificationId) {
    const notes = document.getElementById('decision-notes').value;
    
    if (!confirm('Are you sure you want to APPROVE this document?')) return;
    
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/verification/approve/${verificationId}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                adminId: 'ADMIN_USER_ID', // TODO: Get from auth
                notes: notes
            })
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert('✅ Document approved successfully!');
            closeDocVerificationModal();
            loadPendingVerifications();
        } else {
            alert('Failed to approve: ' + data.message);
        }
    } catch (error) {
        console.error('Error approving verification:', error);
        alert('Failed to approve document');
    }
}

// Reject verification
async function rejectVerification(verificationId) {
    const reason = document.getElementById('decision-notes').value;
    
    if (!reason.trim()) {
        alert('Please provide a rejection reason');
        return;
    }
    
    if (!confirm('Are you sure you want to REJECT this document?')) return;
    
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/verification/reject/${verificationId}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                adminId: 'ADMIN_USER_ID', // TODO: Get from auth
                reason: reason
            })
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert('❌ Document rejected');
            closeDocVerificationModal();
            loadPendingVerifications();
        } else {
            alert('Failed to reject: ' + data.message);
        }
    } catch (error) {
        console.error('Error rejecting verification:', error);
        alert('Failed to reject document');
    }
}

// Quick approve/reject
async function quickApprove(verificationId) {
    if (!confirm('Quick approve this document?')) return;
    await approveVerification(verificationId);
}

async function quickReject(verificationId) {
    const reason = prompt('Enter rejection reason:');
    if (!reason) return;
    
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/verification/reject/${verificationId}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                adminId: 'ADMIN_USER_ID',
                reason: reason
            })
        });
        
        const data = await response.json();
        if (data.success) {
            alert('Document rejected');
            loadPendingVerifications();
        }
    } catch (error) {
        console.error('Error:', error);
    }
}
