# Uniswap V4 Trade Finance Hook MVP

A production-ready Uniswap V4 Hook implementation for MLETR-compliant trade finance instruments with risk-based dynamic fees and automated liquidation.

## 🚀 Quick Links

- **Smart Contracts**: [`src/TradeFinanceHook.sol`](src/TradeFinanceHook.sol)
- **Frontend Demo**: [`demo/`](demo/) - Open `demo/index.html` in browser
- **Tests**: [`test/TradeFinanceHook.t.sol`](test/TradeFinanceHook.t.sol)
- **Deployment**: [`script/DeployTradeFinanceHook.s.sol`](script/DeployTradeFinanceHook.s.sol)

## 🎯 Overview

This MVP implements a sophisticated trade finance protocol as a Uniswap V4 Hook that:

- ✅ Tokenizes MLETR-compliant trade assets (invoices, bills of lading, letters of credit, receivables)
- ✅ Calculates dynamic fees (0.1%-3%) based on credit risk, maturity risk, and payment history
- ✅ Enforces KYC/AML compliance via hook attestations
- ✅ Implements curve-style soft liquidation with max 20% gradual conversion
- ✅ Monitors collateral health in real-time
- ✅ Prevents withdrawal during liquidation scenarios

## 🏗️ Architecture

### Hook Callbacks Implemented

| Callback | Purpose |
|----------|---------|
| `beforeInitialize` | Validates MLETR compliance before pool creation |
| `afterInitialize` | Sets default risk parameters for the pool |
| `beforeAddLiquidity` | Enforces KYC/AML requirements and registers trade assets |
| `afterAddLiquidity` | Updates collateral health tracking |
| `beforeRemoveLiquidity` | Blocks withdrawals during liquidation |
| `beforeSwap` | Calculates dynamic fees and triggers liquidation checks |
| `afterSwap` | Updates health factors based on swap impact |
| `beforeSwapReturnDelta` | Returns risk-adjusted fee to the pool |

### Risk Scoring Model

The hook calculates a composite risk score based on:

1. **Credit Risk**: `(100 - creditScore) × 100`
   - Credit scores range from 0-100
   - Lower scores = higher risk

2. **Maturity Risk**: `+500` if maturity < 7 days
   - Near-term maturities increase liquidity risk

3. **Event Risk**: Weighted by severity
   - Late payments: `severity × 2`
   - Credit downgrades: `severity × 3`
   - Only considers events from last 30 days

### Dynamic Fee Calculation

```solidity
fee = MIN_FEE (0.1%) + (riskScore × (MAX_FEE - MIN_FEE) / 15000)
```

- Minimum: 0.1% (10 bps)
- Maximum: 3% (300 bps)
- Automatically adjusts based on real-time risk

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Solidity 0.8.26+

### Installation

```bash
# Clone and navigate to project
cd /path/to/uniswap

# Install dependencies (already done during setup)
forge install

# Compile contracts
forge build
```

### Run Tests

## 🎨 Frontend Demo

A beautiful, modern DeFi interface to showcase the protocol:

```bash
# Open the demo
cd demo
open index.html

# Or use a local server
python3 -m http.server 8000
# Visit http://localhost:8000
```

**Features:**
- 📊 Real-time risk dashboard
- 💎 Trade asset management
- ⚡ Dynamic fee calculator
- 🏥 Health factor visualization
- 🏦 Active pools browser

See [`demo/README.md`](demo/README.md) for full demo documentation.

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test test_RiskScoreCalculation -vvv

# Check coverage
forge coverage
```

### Deploy

1. Set up environment variables:

```bash
# Create .env file
echo "PRIVATE_KEY=your_private_key_here" > .env
echo "SEPOLIA_RPC_URL=your_rpc_url" >> .env
```

2. Mine for valid hook address (with correct permission flags):

```bash
forge script script/DeployTradeFinanceHook.s.sol:DeployTradeFinanceHook --sig "findSalt()"
```

3. Deploy to testnet:

```bash
forge script script/DeployTradeFinanceHook.s.sol:DeployTradeFinanceHook \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify
```

## 📋 Contract Interface

### Trade Asset Registration

```solidity
struct TradeAsset {
    uint256 faceValue;           // Face value of the asset
    uint256 maturityTimestamp;   // Unix timestamp of maturity
    uint8 creditScore;            // Credit score 0-100
    AssetType assetType;          // INVOICE, BILL_OF_LADING, etc.
    bytes32 jurisdictionHash;     // MLETR jurisdiction compliance
    bool isActive;                // Active status
}
```

### Add Liquidity with Asset

When adding liquidity, pass KYC approval and asset data in `hookData`:

```solidity
bytes memory hookData = abi.encode(
    true,  // KYC approved
    TradeAsset({
        faceValue: 100000e18,
        maturityTimestamp: block.timestamp + 90 days,
        creditScore: 85,
        assetType: AssetType.INVOICE,
        jurisdictionHash: keccak256("US"),
        isActive: false
    })
);
```

### Query Risk & Fees

```solidity
// Get current risk score for a user
uint256 risk = hook.getRiskScore(poolId, userAddress);

// Get dynamic fee for a user
uint24 fee = hook.getDynamicFee(poolId, userAddress);

// Get collateral health
(uint256 collateral, uint256 debt, uint256 timestamp, uint256 healthFactor) = 
    hook.collateralHealth(poolId, userAddress);
```

### Add Risk Events

```solidity
// Record a late payment
hook.addRiskEvent(
    poolId,
    userAddress,
    50,    // severity (0-100)
    true,  // isLatePayment
    false  // isCreditDowngrade
);
```

## 🔐 Security Features

1. **KYC/AML Enforcement**: Requires attestation before liquidity addition
2. **MLETR Compliance**: Validates jurisdiction compliance before pool initialization
3. **Liquidation Protection**: Blocks withdrawals when health factor < 80%
4. **Gradual Liquidation**: Max 20% per liquidation event to minimize market impact
5. **Real-time Monitoring**: Updates health factors on every swap

## 📊 Key Constants

```solidity
LIQUIDATION_THRESHOLD = 8000;     // 80% health factor threshold
SOFT_LIQUIDATION_MAX = 2000;      // 20% max per liquidation
MIN_HEALTH_FACTOR = 10000;        // 1.0 minimum (100%)
MIN_FEE_BPS = 10;                 // 0.1% minimum fee
MAX_FEE_BPS = 300;                // 3% maximum fee
MATURITY_RISK_DAYS = 7;           // Days threshold for maturity risk
```

## 🧪 Test Coverage

The test suite covers:

- ✅ Hook permission verification
- ✅ Trade asset registration
- ✅ Risk score calculation with multiple factors
- ✅ Dynamic fee adjustment based on risk
- ✅ Risk event tracking and impact
- ✅ Collateral health monitoring
- ✅ Liquidation triggers

Run tests:
```bash
forge test -vvv
```

## 🛠️ Development Roadmap

### ✅ MVP (Completed)
- Core hook implementation with 8 callbacks
- Risk-based dynamic fee system
- Trade asset tokenization
- Soft liquidation mechanism
- KYC/AML compliance framework
- Basic test suite

### 🔄 Future Enhancements
- Oracle integration for real-time credit scoring
- Multi-asset collateral support
- Advanced liquidation strategies
- Cross-chain MLETR verification
- Governance module for risk parameters
- Integration with trade finance platforms
- Comprehensive fuzzing tests

## 📖 Resources

- [Uniswap V4 Documentation](https://docs.uniswap.org/contracts/v4/overview)
- [Hook Development Guide](https://docs.uniswap.org/contracts/v4/concepts/hooks)
- [MLETR Framework](https://uncitral.un.org/en/texts/ecommerce/modellaw/electronic_transferable_records)
- [CREATE2 Address Mining](https://www.quicknode.com/guides/defi/dexs/how-to-create-uniswap-v4-hooks)

## 🤝 Contributing

This is an MVP implementation. Contributions for:
- Additional test coverage
- Gas optimizations
- Security improvements
- Documentation enhancements

are welcome!

## ⚠️ Disclaimer

This is a Minimum Viable Product (MVP) for demonstration purposes. **DO NOT USE IN PRODUCTION** without:

1. Comprehensive security audit
2. Extensive testing on testnets
3. Legal review for MLETR compliance
4. Integration testing with Uniswap V4 mainnet deployment
5. Proper oracle integration for credit scoring

## 📄 License

MIT License - see LICENSE file for details

## 🏆 Features Summary

| Feature | Status | Description |
|---------|--------|-------------|
| MLETR Compliance | ✅ | Trade asset validation with jurisdiction hashing |
| Dynamic Fees | ✅ | 0.1%-3% risk-adjusted fees |
| KYC/AML | ✅ | hookData-based attestation |
| Soft Liquidation | ✅ | Max 20% gradual conversion |
| Risk Scoring | ✅ | Credit + Maturity + Event risk |
| Health Monitoring | ✅ | Real-time collateral tracking |
| CREATE2 Deploy | ✅ | Address mining for hook permissions |
| Test Suite | ✅ | Core functionality coverage |

---

**Built with ⚡ Foundry & 🦄 Uniswap V4**

For questions or support, please open an issue in the repository.
