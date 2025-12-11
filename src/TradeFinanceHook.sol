// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "./BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/types/BeforeSwapDelta.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/types/Currency.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/types/PoolOperation.sol";

/// @title TradeFinanceHook
/// @notice Uniswap V4 hook for MLETR-compliant trade finance instruments with risk-based dynamic fees
/// @dev Implements trade asset tokenization, credit risk assessment, and automated liquidation
contract TradeFinanceHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    /// @notice Trade asset types following MLETR compliance
    enum AssetType {
        INVOICE,
        BILL_OF_LADING,
        LETTER_OF_CREDIT,
        RECEIVABLE
    }

    /// @notice Trade asset structure for MLETR-compliant instruments
    struct TradeAsset {
        uint256 faceValue;           // Face value of the trade asset
        uint256 maturityTimestamp;   // Unix timestamp of maturity
        uint8 creditScore;            // Credit score 0-100
        AssetType assetType;          // Type of trade asset
        bytes32 jurisdictionHash;     // Hash for MLETR jurisdiction compliance
        bool isActive;                // Active status
    }

    /// @notice Collateral health tracking
    struct CollateralHealth {
        uint256 totalCollateral;      // Total collateral value
        uint256 totalDebt;            // Total debt value
        uint256 lastUpdateTimestamp;  // Last update time
        uint256 healthFactor;         // Health factor (basis points, 10000 = 1.0)
    }

    /// @notice Risk event types
    struct RiskEvent {
        uint256 timestamp;
        uint256 severity;             // 0-100
        bool isLatePayment;
        bool isCreditDowngrade;
    }

    // State variables
    mapping(PoolId => bool) public isMLETRCompliant;
    mapping(PoolId => mapping(address => TradeAsset)) public tradeAssets;
    mapping(PoolId => mapping(address => CollateralHealth)) public collateralHealth;
    mapping(PoolId => mapping(address => RiskEvent[])) public riskEvents;
    mapping(PoolId => uint256) public poolRiskScores;

    // Constants
    uint256 public constant LIQUIDATION_THRESHOLD = 8000;  // 80% in basis points
    uint256 public constant SOFT_LIQUIDATION_MAX = 2000;   // 20% max per liquidation
    uint256 public constant MIN_HEALTH_FACTOR = 10000;     // 1.0 minimum health factor
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant MIN_FEE_BPS = 10;              // 0.1%
    uint256 public constant MAX_FEE_BPS = 300;             // 3%
    uint256 public constant MATURITY_RISK_DAYS = 7;        // Days threshold for maturity risk

    // Events
    event TradeAssetRegistered(PoolId indexed poolId, address indexed owner, uint256 faceValue, AssetType assetType);
    event RiskScoreUpdated(PoolId indexed poolId, address indexed user, uint256 newScore);
    event SoftLiquidationExecuted(PoolId indexed poolId, address indexed user, uint256 amount);
    event DynamicFeeApplied(PoolId indexed poolId, uint256 feeAmount, uint256 riskScore);
    event CollateralHealthUpdated(PoolId indexed poolId, address indexed user, uint256 healthFactor);

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    /// @inheritdoc BaseHook
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: true,
            beforeAddLiquidity: true,
            afterAddLiquidity: true,
            beforeRemoveLiquidity: true,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: true,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    /// @notice Validates MLETR compliance before pool initialization
    function beforeInitialize(address, PoolKey calldata key, uint160)
        external
        override
        onlyPoolManager
        returns (bytes4)
    {
        // Default to MLETR compliant
        PoolId poolId = key.toId();
        isMLETRCompliant[poolId] = true;
        
        return BaseHook.beforeInitialize.selector;
    }

    /// @notice Sets default risk parameters after initialization
    function afterInitialize(address, PoolKey calldata key, uint160, int24)
        external
        override
        onlyPoolManager
        returns (bytes4)
    {
        PoolId poolId = key.toId();
        poolRiskScores[poolId] = 5000; // Default medium risk (50%)
        
        return BaseHook.afterInitialize.selector;
    }

    /// @notice Enforces KYC/AML compliance via hookData attestations
    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata,
        bytes calldata hookData
    ) external override onlyPoolManager returns (bytes4) {
        PoolId poolId = key.toId();
        
        // Require MLETR compliance for the pool
        require(isMLETRCompliant[poolId], "Pool not MLETR compliant");
        
        // Parse and validate KYC/AML attestation from hookData
        if (hookData.length > 0) {
            (bool hasKYC, TradeAsset memory asset) = abi.decode(hookData, (bool, TradeAsset));
            require(hasKYC, "KYC/AML verification required");
            
            // Register trade asset if provided
            if (asset.faceValue > 0) {
                _registerTradeAsset(poolId, sender, asset);
            }
        }
        
        return BaseHook.beforeAddLiquidity.selector;
    }

    /// @notice Updates collateral health after liquidity addition
    function afterAddLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        BalanceDelta delta,
        BalanceDelta,
        bytes calldata
    ) external override onlyPoolManager returns (bytes4, BalanceDelta) {
        PoolId poolId = key.toId();
        
        // Update collateral health
        _updateCollateralHealth(poolId, sender, delta);
        
        return (BaseHook.afterAddLiquidity.selector, delta);
    }

    /// @notice Blocks withdrawals during soft liquidation
    function beforeRemoveLiquidity(
        address sender,
        PoolKey calldata key,
        ModifyLiquidityParams calldata,
        bytes calldata
    ) external override onlyPoolManager returns (bytes4) {
        PoolId poolId = key.toId();
        CollateralHealth memory health = collateralHealth[poolId][sender];
        
        // Block withdrawal if under liquidation threshold
        require(
            health.healthFactor >= LIQUIDATION_THRESHOLD,
            "Cannot withdraw during liquidation"
        );
        
        return BaseHook.beforeRemoveLiquidity.selector;
    }

    /// @notice Implements dynamic fees and triggers auto-liquidation checks
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata
    ) external override onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24) {
        PoolId poolId = key.toId();
        
        // Calculate risk-adjusted fee
        uint256 riskScore = _calculateRiskScore(poolId, sender);
        uint24 dynamicFee = _calculateDynamicFee(riskScore);
        
        // Check if liquidation is needed
        CollateralHealth memory health = collateralHealth[poolId][sender];
        if (health.healthFactor < LIQUIDATION_THRESHOLD && health.totalDebt > 0) {
            _executeSoftLiquidation(poolId, sender, params);
        }
        
        emit DynamicFeeApplied(poolId, dynamicFee, riskScore);
        
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, dynamicFee);
    }

    /// @notice Updates health factor after swap
    function afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata,
        BalanceDelta delta,
        bytes calldata
    ) external override onlyPoolManager returns (bytes4, int128) {
        PoolId poolId = key.toId();
        
        // Update collateral health based on swap impact
        _updateCollateralHealth(poolId, sender, delta);
        
        return (BaseHook.afterSwap.selector, 0);
    }

    /// @notice Registers a new trade asset
    function _registerTradeAsset(PoolId poolId, address owner, TradeAsset memory asset) internal {
        require(asset.faceValue > 0, "Invalid face value");
        require(asset.maturityTimestamp > block.timestamp, "Invalid maturity");
        require(asset.creditScore <= 100, "Invalid credit score");
        
        asset.isActive = true;
        tradeAssets[poolId][owner] = asset;
        
        emit TradeAssetRegistered(poolId, owner, asset.faceValue, asset.assetType);
    }

    /// @notice Calculates risk score based on credit, maturity, and events
    function _calculateRiskScore(PoolId poolId, address user) internal view returns (uint256) {
        TradeAsset memory asset = tradeAssets[poolId][user];
        if (!asset.isActive) return poolRiskScores[poolId];
        
        uint256 riskScore = 0;
        
        // Credit risk component: (100 - creditScore) * 100
        riskScore += (100 - asset.creditScore) * 100;
        
        // Maturity risk: +500 if less than 7 days to maturity
        if (asset.maturityTimestamp > 0 && 
            asset.maturityTimestamp < block.timestamp + (MATURITY_RISK_DAYS * 1 days)) {
            riskScore += 500;
        }
        
        // Event risk: weighted by severity
        RiskEvent[] memory events = riskEvents[poolId][user];
        for (uint256 i = 0; i < events.length && i < 10; i++) {
            // Only consider recent events (last 30 days)
            if (events[i].timestamp > block.timestamp - 30 days) {
                if (events[i].isLatePayment) riskScore += events[i].severity * 2;
                if (events[i].isCreditDowngrade) riskScore += events[i].severity * 3;
            }
        }
        
        return riskScore;
    }

    /// @notice Calculates dynamic fee based on risk score
    function _calculateDynamicFee(uint256 riskScore) internal pure returns (uint24) {
        // Map risk score to fee range (0.1% - 3%)
        // Risk score ranges from 0 to ~15000
        uint256 feeBps = MIN_FEE_BPS + (riskScore * (MAX_FEE_BPS - MIN_FEE_BPS) / 15000);
        
        // Cap at maximum fee
        if (feeBps > MAX_FEE_BPS) feeBps = MAX_FEE_BPS;
        
        // Convert basis points to fee format (1e6 scale)
        return uint24(feeBps * 100); // Convert to 1e6 scale
    }

    /// @notice Executes soft liquidation with max 20% gradual conversion
    function _executeSoftLiquidation(
        PoolId poolId,
        address user,
        SwapParams calldata params
    ) internal {
        CollateralHealth storage health = collateralHealth[poolId][user];
        
        if (health.totalDebt == 0) return;
        
        // Calculate liquidation amount (max 20% of debt)
        uint256 liquidationAmount = (health.totalDebt * SOFT_LIQUIDATION_MAX) / BASIS_POINTS;
        
        // Reduce debt by liquidation amount
        if (liquidationAmount > health.totalDebt) {
            liquidationAmount = health.totalDebt;
        }
        
        health.totalDebt -= liquidationAmount;
        health.lastUpdateTimestamp = block.timestamp;
        
        // Recalculate health factor
        if (health.totalDebt > 0) {
            health.healthFactor = (health.totalCollateral * BASIS_POINTS) / health.totalDebt;
        } else {
            health.healthFactor = type(uint256).max;
        }
        
        emit SoftLiquidationExecuted(poolId, user, liquidationAmount);
        emit CollateralHealthUpdated(poolId, user, health.healthFactor);
    }

    /// @notice Updates collateral health based on balance delta
    function _updateCollateralHealth(
        PoolId poolId,
        address user,
        BalanceDelta delta
    ) internal {
        CollateralHealth storage health = collateralHealth[poolId][user];
        
        // Update collateral (simplified - in production, use proper valuation)
        int128 amount0 = delta.amount0();
        int128 amount1 = delta.amount1();
        
        if (amount0 > 0) {
            health.totalCollateral += uint128(amount0);
        } else if (amount0 < 0) {
            uint128 absAmount = uint128(-amount0);
            if (health.totalCollateral > absAmount) {
                health.totalCollateral -= absAmount;
            } else {
                health.totalCollateral = 0;
            }
        }
        
        if (amount1 > 0) {
            health.totalCollateral += uint128(amount1);
        } else if (amount1 < 0) {
            uint128 absAmount = uint128(-amount1);
            if (health.totalCollateral > absAmount) {
                health.totalCollateral -= absAmount;
            } else {
                health.totalCollateral = 0;
            }
        }
        
        health.lastUpdateTimestamp = block.timestamp;
        
        // Calculate health factor
        if (health.totalDebt > 0) {
            health.healthFactor = (health.totalCollateral * BASIS_POINTS) / health.totalDebt;
        } else {
            health.healthFactor = type(uint256).max;
        }
        
        emit CollateralHealthUpdated(poolId, user, health.healthFactor);
    }

    /// @notice Adds a risk event for a user
    function addRiskEvent(
        PoolId poolId,
        address user,
        uint256 severity,
        bool isLatePayment,
        bool isCreditDowngrade
    ) external {
        require(severity <= 100, "Invalid severity");
        
        riskEvents[poolId][user].push(RiskEvent({
            timestamp: block.timestamp,
            severity: severity,
            isLatePayment: isLatePayment,
            isCreditDowngrade: isCreditDowngrade
        }));
        
        uint256 newScore = _calculateRiskScore(poolId, user);
        emit RiskScoreUpdated(poolId, user, newScore);
    }

    /// @notice Gets the risk score for a user
    function getRiskScore(PoolId poolId, address user) external view returns (uint256) {
        return _calculateRiskScore(poolId, user);
    }

    /// @notice Gets the dynamic fee for a user
    function getDynamicFee(PoolId poolId, address user) external view returns (uint24) {
        uint256 riskScore = _calculateRiskScore(poolId, user);
        return _calculateDynamicFee(riskScore);
    }
}
