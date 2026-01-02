// Agent Verification Portal - JavaScript
// Configuration
const CONFIG = {
    API_BASE_URL: 'http://192.168.1.59:5001/api',
    DEFAULT_SCORE: 75
};

// Global variables
let allAgents = [];
let filteredAgents = [];
let currentFilter = 'all';
let currentAgent = null;

// Initialize portal
document.addEventListener('DOMContentLoaded', function() {
    initDateTime();
    loadAgents();
    
    // Update score indicator when score input changes
    const scoreInput = document.getElementById('verification-score');
    if (scoreInput) {
        scoreInput.addEventListener('input', function() {
            const scoreBar = document.getElementById('score-bar');
            scoreBar.style.width = this.value + '%';
        });
    }
    
    // Auto-refresh every 60 seconds
    setInterval(loadAgents, 60000);
});

// Initialize date/time display
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
    setInterval(updateDateTime, 60000); // Update every minute
}

// Load all agents from backend
async function loadAgents() {
    try {
        showLoading();
        
        const response = await fetch(`${CONFIG.API_BASE_URL}/agents`);
        
        if (!response.ok) {
            throw new Error('Failed to load agents');
        }
        
        const data = await response.json();
        allAgents = data.agents || [];
        
        updateStats();
        filterAgents(currentFilter);
        
    } catch (error) {
        console.error('Error loading agents:', error);
        showError('Failed to load agents. Please check if the backend is running.');
    }
}

// Update statistics
function updateStats() {
    const pending = allAgents.filter(a => !a.verified && a.documentsUploaded).length;
    const verified = allAgents.filter(a => a.verified).length;
    const rejected = allAgents.filter(a => a.rejected).length;
    const total = allAgents.length;
    
    document.getElementById('pending-count').textContent = pending;
    document.getElementById('verified-count').textContent = verified;
    document.getElementById('rejected-count').textContent = rejected;
    document.getElementById('total-count').textContent = total;
}

// Filter agents
function filterAgents(filter) {
    currentFilter = filter;
    
    // Update filter buttons
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.classList.remove('active');
        if (btn.dataset.filter === filter) {
            btn.classList.add('active');
        }
    });
    
    // Filter agents based on selection
    switch(filter) {
        case 'pending':
            filteredAgents = allAgents.filter(a => !a.verified && a.documentsUploaded && !a.rejected);
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

// Search agents
function searchAgents() {
    const searchTerm = document.getElementById('search-input').value.toLowerCase();
    
    if (!searchTerm) {
        filterAgents(currentFilter);
        return;
    }
    
    filteredAgents = allAgents.filter(agent => {
        return agent.name.toLowerCase().includes(searchTerm) ||
               agent.email.toLowerCase().includes(searchTerm) ||
               (agent.company && agent.company.toLowerCase().includes(searchTerm)) ||
               (agent.phone && agent.phone.includes(searchTerm));
    });
    
    displayAgents();
}

// Display agents in the list
function displayAgents() {
    const container = document.getElementById('agents-container');
    
    if (filteredAgents.length === 0) {
        container.innerHTML = `
            <div class="no-agents">
                <span class="icon">📭</span>
                <p>No agents found</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = filteredAgents.map(agent => createAgentCard(agent)).join('');
}

// Create agent card HTML
function createAgentCard(agent) {
    const statusBadge = agent.verified 
        ? `<span class="verified-badge">✅ Verified</span>`
        : agent.rejected
        ? `<span class="rejected-badge">❌ Rejected</span>`
        : `<span class="pending-badge">⏳ Pending</span>`;
    
    const scoreBadge = agent.verified 
        ? `<span class="score-badge">⭐ Score: ${agent.score || 0}/100</span>`
        : '';
    
    const photoUrl = agent.photo 
        ? `${CONFIG.API_BASE_URL.replace('/api', '')}${agent.photo}`
        : 'https://via.placeholder.com/80?text=No+Photo';
    
    const actions = agent.verified
        ? `<button class="btn btn-primary" onclick="viewQRCode('${agent.email}')">
               📱 View QR Code
           </button>`
        : !agent.rejected
        ? `<button class="btn btn-success" onclick="openVerifyModal('${agent.email}')">
               ✅ Verify
           </button>
           <button class="btn btn-danger" onclick="rejectAgentDirect('${agent.email}')">
               ❌ Reject
           </button>`
        : '';
    
    return `
        <div class="agent-card" onclick="viewAgentDetails('${agent.email}')">
            <img src="${photoUrl}" alt="${agent.name}" class="agent-photo" onerror="this.src='https://via.placeholder.com/80?text=No+Photo'">
            <div class="agent-info">
                <div class="agent-name">
                    ${agent.name}
                    ${statusBadge}
                    ${scoreBadge}
                </div>
                <div class="agent-details">
                    <div>📧 ${agent.email}</div>
                    <div>📱 ${agent.phone || 'N/A'}</div>
                    <div>🏢 ${agent.company || 'N/A'}</div>
                    <div>📅 Registered: ${new Date(agent.createdAt).toLocaleDateString()}</div>
                </div>
            </div>
            <div class="agent-actions" onclick="event.stopPropagation()">
                ${actions}
            </div>
        </div>
    `;
}

// View agent details
function viewAgentDetails(email) {
    const agent = allAgents.find(a => a.email === email);
    if (!agent) return;
    
    currentAgent = agent;
    
    const photoUrl = agent.photo 
        ? `${CONFIG.API_BASE_URL.replace('/api', '')}${agent.photo}`
        : 'https://via.placeholder.com/200?text=No+Photo';
    
    const idProofUrl = agent.idProof 
        ? `${CONFIG.API_BASE_URL.replace('/api', '')}${agent.idProof}`
        : null;
    
    const certificateUrl = agent.certificate 
        ? `${CONFIG.API_BASE_URL.replace('/api', '')}${agent.certificate}`
        : null;
    
    const modalBody = document.getElementById('modal-body');
    modalBody.innerHTML = `
        <div class="detail-row">
            <div class="detail-label">Photo:</div>
            <div class="detail-value">
                <img src="${photoUrl}" alt="${agent.name}" style="max-width: 200px; border-radius: 8px;" onerror="this.src='https://via.placeholder.com/200?text=No+Photo'">
            </div>
        </div>
        <div class="detail-row">
            <div class="detail-label">Name:</div>
            <div class="detail-value">${agent.name}</div>
        </div>
        <div class="detail-row">
            <div class="detail-label">Email:</div>
            <div class="detail-value">${agent.email}</div>
        </div>
        <div class="detail-row">
            <div class="detail-label">Phone:</div>
            <div class="detail-value">${agent.phone || 'N/A'}</div>
        </div>
        <div class="detail-row">
            <div class="detail-label">Company:</div>
            <div class="detail-value">${agent.company || 'N/A'}</div>
        </div>
        <div class="detail-row">
            <div class="detail-label">Service Type:</div>
            <div class="detail-value">${agent.serviceType || 'N/A'}</div>
        </div>
        <div class="detail-row">
            <div class="detail-label">Status:</div>
            <div class="detail-value">
                ${agent.verified ? '<span class="verified-badge">✅ Verified</span>' : 
                  agent.rejected ? '<span class="rejected-badge">❌ Rejected</span>' :
                  '<span class="pending-badge">⏳ Pending</span>'}
            </div>
        </div>
        ${agent.verified ? `
        <div class="detail-row">
            <div class="detail-label">Trust Score:</div>
            <div class="detail-value"><span class="score-badge">⭐ ${agent.score || 0}/100</span></div>
        </div>
        ` : ''}
        <div class="detail-row">
            <div class="detail-label">Registered:</div>
            <div class="detail-value">${new Date(agent.createdAt).toLocaleString()}</div>
        </div>
        <div class="detail-row">
            <div class="detail-label">Documents:</div>
            <div class="detail-value">
                <div class="documents-grid">
                    ${idProofUrl ? `
                    <div class="document-card">
                        <a href="${idProofUrl}" target="_blank">
                            <img src="${idProofUrl}" alt="ID Proof">
                        </a>
                        <div class="document-label">ID Proof</div>
                    </div>
                    ` : ''}
                    ${certificateUrl ? `
                    <div class="document-card">
                        <a href="${certificateUrl}" target="_blank">
                            <img src="${certificateUrl}" alt="Certificate">
                        </a>
                        <div class="document-label">Certificate</div>
                    </div>
                    ` : ''}
                </div>
            </div>
        </div>
        <div style="margin-top: 24px; display: flex; gap: 12px; justify-content: center;">
            ${!agent.verified && !agent.rejected ? `
                <button class="btn btn-success" onclick="openVerifyModal('${agent.email}')">
                    ✅ Verify Agent
                </button>
                <button class="btn btn-danger" onclick="rejectAgentDirect('${agent.email}')">
                    ❌ Reject
                </button>
            ` : agent.verified ? `
                <button class="btn btn-primary" onclick="viewQRCode('${agent.email}')">
                    📱 View QR Code
                </button>
            ` : ''}
        </div>
    `;
    
    document.getElementById('agent-modal').style.display = 'block';
}

// Open verify modal
function openVerifyModal(email) {
    const agent = allAgents.find(a => a.email === email);
    if (!agent) return;
    
    currentAgent = agent;
    document.getElementById('verification-score').value = CONFIG.DEFAULT_SCORE;
    document.getElementById('score-bar').style.width = CONFIG.DEFAULT_SCORE + '%';
    document.getElementById('verification-notes').value = '';
    
    closeModal();
    document.getElementById('verify-modal').style.display = 'block';
}

// Approve agent
async function approveAgent() {
    if (!currentAgent) return;
    
    const score = parseInt(document.getElementById('verification-score').value);
    const notes = document.getElementById('verification-notes').value;
    
    if (score < 0 || score > 100) {
        alert('Score must be between 0 and 100');
        return;
    }
    
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/agents/admin/verify/${currentAgent.email}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ score, notes })
        });
        
        if (!response.ok) {
            throw new Error('Failed to verify agent');
        }
        
        const data = await response.json();
        
        if (data.success) {
            alert(`✅ Agent verified successfully with score ${score}/100`);
            closeVerifyModal();
            loadAgents();
        } else {
            throw new Error(data.error || 'Verification failed');
        }
        
    } catch (error) {
        console.error('Error verifying agent:', error);
        alert('Failed to verify agent: ' + error.message);
    }
}

// Reject agent
async function rejectAgent() {
    if (!currentAgent) return;
    await rejectAgentDirect(currentAgent.email);
    closeVerifyModal();
}

// Reject agent directly
async function rejectAgentDirect(email) {
    if (!confirm('Are you sure you want to reject this agent?')) {
        return;
    }
    
    try {
        const response = await fetch(`${CONFIG.API_BASE_URL}/agents/admin/reject/${email}`, {
            method: 'POST'
        });
        
        if (!response.ok) {
            throw new Error('Failed to reject agent');
        }
        
        const data = await response.json();
        
        if (data.success) {
            alert('❌ Agent rejected');
            closeModal();
            loadAgents();
        } else {
            throw new Error(data.error || 'Rejection failed');
        }
        
    } catch (error) {
        console.error('Error rejecting agent:', error);
        alert('Failed to reject agent: ' + error.message);
    }
}

// View QR Code
async function viewQRCode(email) {
    const agent = allAgents.find(a => a.email === email);
    if (!agent || !agent.verified) {
        alert('Agent must be verified to generate QR code');
        return;
    }
    
    currentAgent = agent;
    
    // Clear previous QR code
    const qrContainer = document.getElementById('qr-container');
    qrContainer.innerHTML = '';
    
    // Generate QR data
    const qrData = JSON.stringify({
        id: agent._id || agent.id,
        name: agent.name,
        email: agent.email,
        company: agent.company,
        verified: true,
        score: agent.score || 0,
        timestamp: new Date().toISOString()
    });
    
    // Generate QR code
    new QRCode(qrContainer, {
        text: qrData,
        width: 256,
        height: 256,
        colorDark: '#000000',
        colorLight: '#ffffff',
        correctLevel: QRCode.CorrectLevel.H
    });
    
    // Display agent info
    document.getElementById('qr-info').innerHTML = `
        <h3>${agent.name}</h3>
        <p><strong>Email:</strong> ${agent.email}</p>
        <p><strong>Company:</strong> ${agent.company || 'N/A'}</p>
        <p><strong>Trust Score:</strong> ⭐ ${agent.score || 0}/100</p>
        <p><strong>Status:</strong> ✅ Verified</p>
    `;
    
    closeModal();
    document.getElementById('qr-modal').style.display = 'block';
}

// Download QR Code
function downloadQR() {
    if (!currentAgent) return;
    
    const qrCanvas = document.querySelector('#qr-container canvas');
    if (!qrCanvas) return;
    
    const link = document.createElement('a');
    link.download = `agent-qr-${currentAgent.email}.png`;
    link.href = qrCanvas.toDataURL();
    link.click();
}

// Print QR Code
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
                body {
                    font-family: Arial, sans-serif;
                    text-align: center;
                    padding: 40px;
                }
                h1 { margin-bottom: 20px; }
                img { margin: 20px 0; }
                .info { margin-top: 20px; }
            </style>
        </head>
        <body>
            <h1>Agent QR Code</h1>
            <h2>${currentAgent.name}</h2>
            <img src="${qrCanvas.toDataURL()}" />
            <div class="info">
                <p><strong>Email:</strong> ${currentAgent.email}</p>
                <p><strong>Company:</strong> ${currentAgent.company || 'N/A'}</p>
                <p><strong>Trust Score:</strong> ${currentAgent.score || 0}/100</p>
            </div>
        </body>
        </html>
    `);
    printWindow.document.close();
    printWindow.print();
}

// Modal functions
function closeModal() {
    document.getElementById('agent-modal').style.display = 'none';
    currentAgent = null;
}

function closeQRModal() {
    document.getElementById('qr-modal').style.display = 'none';
}

function closeVerifyModal() {
    document.getElementById('verify-modal').style.display = 'none';
}

// Close modals when clicking outside
window.onclick = function(event) {
    const agentModal = document.getElementById('agent-modal');
    const qrModal = document.getElementById('qr-modal');
    const verifyModal = document.getElementById('verify-modal');
    
    if (event.target === agentModal) {
        closeModal();
    }
    if (event.target === qrModal) {
        closeQRModal();
    }
    if (event.target === verifyModal) {
        closeVerifyModal();
    }
}

// Show loading state
function showLoading() {
    document.getElementById('agents-container').innerHTML = `
        <div class="loading-spinner">
            <div class="spinner"></div>
            <p>Loading agents...</p>
        </div>
    `;
}

// Show error message
function showError(message) {
    document.getElementById('agents-container').innerHTML = `
        <div class="no-agents">
            <span class="icon">❌</span>
            <p>${message}</p>
            <button class="btn btn-primary" onclick="loadAgents()" style="margin-top: 16px;">
                🔄 Retry
            </button>
        </div>
    `;
}
