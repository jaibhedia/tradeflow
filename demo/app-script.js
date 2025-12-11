// Sample data
const sampleAssets = [
    {
        id: 1,
        type: 'INVOICE',
        icon: '📄',
        faceValue: 125000,
        creditScore: 85,
        maturity: '2026-03-15',
        jurisdiction: 'US',
        riskScore: 1500
    },
    {
        id: 2,
        type: 'LETTER_OF_CREDIT',
        icon: '📋',
        faceValue: 250000,
        creditScore: 92,
        maturity: '2026-06-20',
        jurisdiction: 'UK',
        riskScore: 800
    },
    {
        id: 3,
        type: 'RECEIVABLE',
        icon: '💰',
        faceValue: 75000,
        creditScore: 68,
        maturity: '2025-12-28',
        jurisdiction: 'SG',
        riskScore: 4200
    }
];

const samplePools = [
    {
        name: 'Premium Invoice Pool',
        icon: '💎',
        assetType: 'INVOICE',
        tvl: 4200000,
        apy: 8.2,
        riskScore: 1200,
        maturity: '90 days'
    },
    {
        name: 'LoC Diversified',
        icon: '🏦',
        assetType: 'LETTER_OF_CREDIT',
        tvl: 6800000,
        apy: 6.5,
        riskScore: 800,
        maturity: '120 days'
    },
    {
        name: 'Short-term Receivables',
        icon: '⚡',
        assetType: 'RECEIVABLE',
        tvl: 1400000,
        apy: 9.8,
        riskScore: 3500,
        maturity: '30 days'
    }
];

// State
let userAssets = [...sampleAssets];
let connectedWallet = null;

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    renderAssets();
    renderPools();
    updateRiskMetrics();
    setupEventListeners();
    animateOnScroll();
});

// Event Listeners
function setupEventListeners() {
    // Connect Wallet
    document.getElementById('connectBtn').addEventListener('click', connectWallet);
    
    // Add Asset Modal
    document.getElementById('addAssetBtn').addEventListener('click', openModal);
    document.getElementById('closeModal').addEventListener('click', closeModal);
    
    // Asset Form
    document.getElementById('assetForm').addEventListener('submit', handleAssetSubmit);
    
    // Credit Score Slider
    document.getElementById('creditScore').addEventListener('input', (e) => {
        document.getElementById('scoreDisplay').textContent = e.target.value;
    });
    
    // Close modal on outside click
    document.getElementById('addAssetModal').addEventListener('click', (e) => {
        if (e.target.id === 'addAssetModal') {
            closeModal();
        }
    });
}

// Wallet Connection
function connectWallet() {
    const btn = document.getElementById('connectBtn');
    
    if (!connectedWallet) {
        // Simulate wallet connection
        setTimeout(() => {
            connectedWallet = '0x742d...9A3f';
            btn.innerHTML = `<span class="wallet-icon">⚡</span> ${connectedWallet}`;
            showNotification('Wallet connected successfully!', 'success');
        }, 500);
    } else {
        connectedWallet = null;
        btn.innerHTML = '<span class="wallet-icon">⚡</span> Connect Wallet';
        showNotification('Wallet disconnected', 'info');
    }
}

// Render Assets
function renderAssets() {
    const container = document.getElementById('assetsList');
    
    if (userAssets.length === 0) {
        container.innerHTML = `
            <div style="text-align: center; padding: 40px; color: var(--text-secondary);">
                <div style="font-size: 48px; margin-bottom: 16px;">📦</div>
                <p>No trade assets registered yet</p>
                <p style="font-size: 14px; margin-top: 8px;">Click "Add Asset" to get started</p>
            </div>
        `;
        return;
    }
    
    container.innerHTML = userAssets.map(asset => `
        <div class="asset-card">
            <div class="asset-header">
                <div class="asset-type">
                    <span class="asset-icon">${asset.icon}</span>
                    <span>${formatAssetType(asset.type)}</span>
                </div>
                <div class="asset-badge">${asset.jurisdiction}</div>
            </div>
            <div class="asset-details">
                <div class="detail-item">
                    <span class="detail-label">Face Value</span>
                    <span class="detail-value">$${formatNumber(asset.faceValue)}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">Credit Score</span>
                    <span class="detail-value" style="color: ${getCreditColor(asset.creditScore)}">${asset.creditScore}/100</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">Maturity</span>
                    <span class="detail-value">${formatDate(asset.maturity)}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">Risk Score</span>
                    <span class="detail-value" style="color: ${getRiskColor(asset.riskScore)}">${asset.riskScore}</span>
                </div>
            </div>
        </div>
    `).join('');
}

// Render Pools
function renderPools() {
    const tbody = document.getElementById('poolsTable');
    
    tbody.innerHTML = samplePools.map(pool => `
        <tr>
            <td>
                <div class="pool-name">
                    <div class="pool-icon">${pool.icon}</div>
                    <span>${pool.name}</span>
                </div>
            </td>
            <td><span class="asset-type-badge">${formatAssetType(pool.assetType)}</span></td>
            <td>$${formatNumber(pool.tvl)}</td>
            <td style="color: var(--success); font-weight: 600;">${pool.apy}%</td>
            <td><span class="risk-badge ${getRiskLevel(pool.riskScore)}">${pool.riskScore}</span></td>
            <td>${pool.maturity}</td>
            <td><button class="action-btn">Add Liquidity</button></td>
        </tr>
    `).join('');
}

// Update Risk Metrics
function updateRiskMetrics() {
    if (userAssets.length === 0) return;
    
    // Calculate composite risk score
    const totalRisk = userAssets.reduce((sum, asset) => sum + asset.riskScore, 0);
    const avgRisk = totalRisk / userAssets.length;
    
    // Update risk score
    document.getElementById('riskScore').textContent = Math.round(avgRisk).toLocaleString();
    
    // Update risk bar
    const riskPercentage = Math.min((avgRisk / 15000) * 100, 100);
    document.getElementById('riskFill').style.width = riskPercentage + '%';
    
    // Calculate dynamic fee
    const baseFee = 0.10;
    const maxFee = 3.00;
    const riskPremium = (avgRisk / 15000) * (maxFee - baseFee);
    const totalFee = baseFee + riskPremium;
    
    document.getElementById('feePercentage').textContent = totalFee.toFixed(2) + '%';
    document.getElementById('riskPremium').textContent = '+' + riskPremium.toFixed(2) + '%';
    
    // Simulate health factor updates
    animateHealthFactor();
}

// Animate Health Factor
function animateHealthFactor() {
    const healthArc = document.getElementById('healthArc');
    const healthValue = document.getElementById('healthValue');
    
    let health = 100;
    const target = 142;
    const duration = 1500;
    const start = Date.now();
    
    function animate() {
        const elapsed = Date.now() - start;
        const progress = Math.min(elapsed / duration, 1);
        
        health = 100 + (target - 100) * easeOutQuart(progress);
        
        // Update text
        healthValue.textContent = Math.round(health) + '%';
        
        // Update arc (251.2 is the total arc length)
        const offset = 251.2 * (1 - (health / 200));
        healthArc.setAttribute('stroke-dashoffset', offset);
        
        if (progress < 1) {
            requestAnimationFrame(animate);
        }
    }
    
    animate();
}

// Modal Functions
function openModal() {
    document.getElementById('addAssetModal').classList.add('active');
}

function closeModal() {
    document.getElementById('addAssetModal').classList.remove('active');
    document.getElementById('assetForm').reset();
    document.getElementById('scoreDisplay').textContent = '75';
}

// Handle Asset Form Submit
function handleAssetSubmit(e) {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const assetType = document.getElementById('assetType').value;
    const faceValue = parseFloat(document.getElementById('faceValue').value);
    const creditScore = parseInt(document.getElementById('creditScore').value);
    const maturity = document.getElementById('maturityDate').value;
    const jurisdiction = document.getElementById('jurisdiction').value;
    
    // Calculate risk score
    const creditRisk = (100 - creditScore) * 100;
    const maturityDays = Math.ceil((new Date(maturity) - new Date()) / (1000 * 60 * 60 * 24));
    const maturityRisk = maturityDays < 7 ? 500 : 0;
    const riskScore = creditRisk + maturityRisk;
    
    // Create new asset
    const newAsset = {
        id: userAssets.length + 1,
        type: assetType,
        icon: getAssetIcon(assetType),
        faceValue: faceValue,
        creditScore: creditScore,
        maturity: maturity,
        jurisdiction: jurisdiction,
        riskScore: riskScore
    };
    
    // Add to assets
    userAssets.push(newAsset);
    
    // Update UI
    renderAssets();
    updateRiskMetrics();
    closeModal();
    
    showNotification('Trade asset registered successfully!', 'success');
}

// Helper Functions
function formatAssetType(type) {
    return type.split('_').map(word => 
        word.charAt(0) + word.slice(1).toLowerCase()
    ).join(' ');
}

function formatNumber(num) {
    if (num >= 1000000) {
        return (num / 1000000).toFixed(1) + 'M';
    } else if (num >= 1000) {
        return (num / 1000).toFixed(0) + 'K';
    }
    return num.toLocaleString();
}

function formatDate(dateStr) {
    const date = new Date(dateStr);
    const options = { month: 'short', day: 'numeric', year: 'numeric' };
    return date.toLocaleDateString('en-US', options);
}

function getCreditColor(score) {
    if (score >= 80) return 'var(--success)';
    if (score >= 60) return 'var(--warning)';
    return 'var(--danger)';
}

function getRiskColor(score) {
    if (score < 2000) return 'var(--success)';
    if (score < 5000) return 'var(--warning)';
    return 'var(--danger)';
}

function getRiskLevel(score) {
    if (score < 2000) return 'low';
    if (score < 5000) return 'medium';
    return 'high';
}

function getAssetIcon(type) {
    const icons = {
        'INVOICE': '📄',
        'BILL_OF_LADING': '🚢',
        'LETTER_OF_CREDIT': '📋',
        'RECEIVABLE': '💰'
    };
    return icons[type] || '📦';
}

function easeOutQuart(x) {
    return 1 - Math.pow(1 - x, 4);
}

function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.style.cssText = `
        position: fixed;
        top: 24px;
        right: 24px;
        padding: 16px 24px;
        background: ${type === 'success' ? 'var(--success)' : 'var(--primary)'};
        color: white;
        border-radius: 12px;
        box-shadow: 0 8px 24px rgba(0,0,0,0.3);
        z-index: 2000;
        font-weight: 500;
        animation: slideIn 0.3s ease;
    `;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

// Animations
function animateOnScroll() {
    const cards = document.querySelectorAll('.stat-card, .asset-card, .panel');
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry, index) => {
            if (entry.isIntersecting) {
                setTimeout(() => {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }, index * 100);
            }
        });
    }, { threshold: 0.1 });
    
    cards.forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        card.style.transition = 'all 0.5s ease';
        observer.observe(card);
    });
}

// Add animation keyframes
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(100%);
            opacity: 0;
        }
    }
`;
document.head.appendChild(style);

// Simulate real-time updates
setInterval(() => {
    // Randomly update TVL
    const statValue = document.querySelector('.stat-value');
    if (statValue && Math.random() > 0.7) {
        const currentValue = parseFloat(statValue.textContent.replace('$', '').replace('M', ''));
        const newValue = currentValue + (Math.random() - 0.5) * 0.2;
        statValue.textContent = '$' + newValue.toFixed(1) + 'M';
    }
}, 5000);
