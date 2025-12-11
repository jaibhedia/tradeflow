# TradeFlow - Trade Finance Protocol Demo

A modern, minimalistic DeFi interface showcasing the Uniswap V4 Trade Finance Hook MVP.

## 🎨 Features

### Dashboard Components
- **Real-time Stats**: TVL, Active Assets, APY, Liquidation Health
- **Trade Asset Management**: Register and track MLETR-compliant assets
- **Risk Dashboard**: Composite risk scoring with visual indicators
- **Dynamic Fee Calculator**: Real-time fee adjustments based on risk
- **Health Factor Gauge**: Collateral health monitoring with liquidation warnings
- **Pool Browser**: Browse and interact with active trade finance pools

### Interactive Elements
- ✅ Wallet connection simulation
- ✅ Asset registration modal with KYC verification
- ✅ Dynamic risk score calculation
- ✅ Animated health factor visualization
- ✅ Real-time fee updates
- ✅ Responsive design for all devices

## 🚀 Quick Start

### Option 1: Open Locally
```bash
# Navigate to demo folder
cd demo

# Open in browser (macOS)
open index.html

# Or use a local server
python3 -m http.server 8000
# Then visit http://localhost:8000
```

### Option 2: Use Live Server (VS Code)
1. Install "Live Server" extension
2. Right-click `index.html`
3. Select "Open with Live Server"

## 📱 UI/UX Highlights

### Design Philosophy
- **Dark Mode First**: Modern dark theme with gradient accents
- **Minimal & Clean**: Focus on essential information
- **DeFi Native**: Familiar patterns from leading protocols
- **Data-Dense**: Maximum information, minimum clutter

### Color Palette
```css
Primary: #667eea (Purple Blue)
Secondary: #764ba2 (Deep Purple)
Success: #10b981 (Green)
Warning: #f59e0b (Amber)
Danger: #ef4444 (Red)
Background: #0f1117 (Dark)
```

### Key Interactions
1. **Connect Wallet** → Simulates wallet connection with address display
2. **Add Asset** → Opens modal for trade asset registration
3. **Risk Calculation** → Real-time updates based on asset parameters
4. **Fee Display** → Shows base + risk premium breakdown
5. **Health Monitoring** → Animated gauge with threshold warnings

## 🎯 Demo Flow

### 1. Initial State
- Pre-loaded with 3 sample trade assets
- Shows aggregated risk metrics
- Displays 3 active liquidity pools

### 2. Add New Asset
- Click "Add Asset" button
- Fill in trade asset details:
  - Asset type (Invoice, LoC, etc.)
  - Face value
  - Credit score (0-100)
  - Maturity date
  - Jurisdiction
- See real-time risk score calculation
- KYC badge shows compliance

### 3. Risk Updates
- Composite risk score updates automatically
- Risk bar shows visual position (Low/Medium/High)
- Dynamic fee adjusts based on risk
- Health factor shows collateralization

### 4. Pool Interaction
- Browse available pools
- See TVL, APY, and risk metrics
- Filter by asset type
- Simulated "Add Liquidity" action

## 📊 Data Visualization

### Risk Score Components
```javascript
creditRisk = (100 - creditScore) × 100
maturityRisk = +500 if < 7 days
compositeRisk = creditRisk + maturityRisk + eventRisk
```

### Dynamic Fee Formula
```javascript
baseFee = 0.10%
maxFee = 3.00%
riskPremium = (riskScore / 15000) × (maxFee - baseFee)
totalFee = baseFee + riskPremium
```

### Health Factor
```javascript
healthFactor = (collateral / debt) × 100
liquidationThreshold = 80%
```

## 🎬 Pitch Presentation Tips

### Key Talking Points
1. **MLETR Compliance**: Built for regulatory-compliant trade finance
2. **Risk-Based Pricing**: Dynamic fees reflect real credit risk
3. **Automated Protection**: Soft liquidation prevents cascading losses
4. **Real-Time Monitoring**: Health factors update on every transaction
5. **Uniswap V4 Native**: Leverages hooks for seamless integration

### Demo Walkthrough
```
1. Show dashboard → "This is the trader's view"
2. Click Add Asset → "Register a new invoice"
3. Adjust credit score → "See how risk affects fees"
4. Point to health gauge → "Automated liquidation protection"
5. Show pools table → "Diversified liquidity pools"
```

### Value Propositions
- **For Traders**: Access to DeFi liquidity for trade finance
- **For LPs**: Risk-adjusted returns on trade assets
- **For Markets**: Programmable, transparent trade finance
- **For Regulators**: MLETR-compliant, auditable

## 🛠️ Technical Stack

- **Pure HTML/CSS/JS**: No framework dependencies
- **Modern CSS**: Grid, Flexbox, Custom Properties
- **Vanilla JavaScript**: No jQuery or libraries
- **Responsive**: Works on mobile, tablet, desktop
- **Accessible**: Semantic HTML, ARIA labels

## 🎨 Customization

### Change Theme
Edit CSS variables in `styles.css`:
```css
:root {
    --primary: #667eea;      /* Main brand color */
    --bg-primary: #0f1117;   /* Background */
    /* ... */
}
```

### Add More Assets
Edit `sampleAssets` array in `script.js`:
```javascript
const sampleAssets = [
    {
        type: 'INVOICE',
        faceValue: 100000,
        creditScore: 85,
        // ...
    }
];
```

### Modify Pools
Edit `samplePools` array in `script.js`

## 📝 Notes for Pitch

### What's Simulated
- Wallet connection (no real Web3)
- Asset registration (stored in memory)
- Risk calculations (using demo formulas)
- Pool interactions (visual only)

### What's Real
- Risk scoring algorithm matches smart contract
- Fee calculations use actual formulas
- Health factor thresholds match contract constants
- UI/UX represents production-ready design

## 🚀 Next Steps for Production

1. Integrate Web3 (ethers.js/viem)
2. Connect to deployed hook contract
3. Add real wallet connection (MetaMask, etc.)
4. Implement actual pool interactions
5. Add transaction signing
6. Oracle integration for credit scores
7. Real-time event listening
8. IPFS for asset metadata

## 📄 License

MIT - Built for demonstration purposes

---

**Perfect for pitch decks, investor demos, and product showcases!**
