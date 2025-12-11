// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {TradeFinanceHook} from "../src/TradeFinanceHook.sol";
import {IPoolManager} from "@uniswap/v4-core/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/types/Currency.sol";
import {ModifyLiquidityParams, SwapParams} from "@uniswap/v4-core/types/PoolOperation.sol";
import {Hooks} from "@uniswap/v4-core/libraries/Hooks.sol";

contract TradeFinanceHookTest is Test {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    TradeFinanceHook hook;
    IPoolManager poolManager;
    PoolKey testKey;
    PoolId testPoolId;

    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        // Deploy mock pool manager
        poolManager = IPoolManager(address(0x1234));
        
        // Deploy hook
        vm.prank(address(this));
        hook = new TradeFinanceHook(poolManager);

        // Setup test pool key
        testKey = PoolKey({
            currency0: Currency.wrap(address(0x1000)),
            currency1: Currency.wrap(address(0x2000)),
            fee: 3000,
            tickSpacing: 60,
            hooks: hook
        });

        testPoolId = testKey.toId();

        console.log("Hook deployed at:", address(hook));
        console.log("Test setup complete");
    }

    function test_HookPermissions() public view {
        Hooks.Permissions memory permissions = hook.getHookPermissions();
        
        assertTrue(permissions.beforeInitialize, "beforeInitialize should be true");
        assertTrue(permissions.afterInitialize, "afterInitialize should be true");
        assertTrue(permissions.beforeAddLiquidity, "beforeAddLiquidity should be true");
        assertTrue(permissions.afterAddLiquidity, "afterAddLiquidity should be true");
        assertTrue(permissions.beforeRemoveLiquidity, "beforeRemoveLiquidity should be true");
        assertTrue(permissions.beforeSwap, "beforeSwap should be true");
        assertTrue(permissions.afterSwap, "afterSwap should be true");
        assertTrue(permissions.beforeSwapReturnDelta, "beforeSwapReturnDelta should be true");
    }

    function test_RegisterTradeAsset() public {
        // Create trade asset
        TradeFinanceHook.TradeAsset memory asset = TradeFinanceHook.TradeAsset({
            faceValue: 100000e18,
            maturityTimestamp: block.timestamp + 90 days,
            creditScore: 75,
            assetType: TradeFinanceHook.AssetType.INVOICE,
            jurisdictionHash: keccak256("US"),
            isActive: false
        });

        // Encode hookData with KYC approval and asset
        bytes memory hookData = abi.encode(true, asset);

        // Mock beforeAddLiquidity call from pool manager
        vm.prank(address(poolManager));
        
        // First set pool as MLETR compliant
        bytes memory initData = abi.encode(true);
        hook.beforeInitialize(address(this), testKey, 0);

        // Then add liquidity with asset registration
        hook.beforeAddLiquidity(alice, testKey, ModifyLiquidityParams(0, 0, 0, bytes32(0)), hookData);

        // Verify asset was registered
        (uint256 faceValue, uint256 maturity, uint8 creditScore, , , bool isActive) = 
            hook.tradeAssets(testPoolId, alice);
        
        assertEq(faceValue, 100000e18, "Face value mismatch");
        assertEq(maturity, block.timestamp + 90 days, "Maturity mismatch");
        assertEq(creditScore, 75, "Credit score mismatch");
        assertTrue(isActive, "Asset should be active");
    }

    function test_RiskScoreCalculation() public {
        // Setup pool compliance
        vm.prank(address(poolManager));
        bytes memory initData = abi.encode(true);
        hook.beforeInitialize(address(this), testKey, 0);

        // Register asset with low credit score
        TradeFinanceHook.TradeAsset memory asset = TradeFinanceHook.TradeAsset({
            faceValue: 100000e18,
            maturityTimestamp: block.timestamp + 5 days, // Near maturity
            creditScore: 60, // Low credit
            assetType: TradeFinanceHook.AssetType.INVOICE,
            jurisdictionHash: keccak256("US"),
            isActive: false
        });

        bytes memory hookData = abi.encode(true, asset);
        vm.prank(address(poolManager));
        hook.beforeAddLiquidity(alice, testKey, ModifyLiquidityParams(0, 0, 0, bytes32(0)), hookData);

        // Get risk score
        uint256 riskScore = hook.getRiskScore(testPoolId, alice);
        
        console.log("Risk score:", riskScore);
        
        // Risk score should be high due to:
        // - Low credit score (60): (100-60)*100 = 4000
        // - Near maturity (<7 days): +500
        // Total: ~4500
        assertGt(riskScore, 4000, "Risk score should reflect low credit");
    }

    function test_DynamicFeeCalculation() public {
        // Setup pool
        vm.prank(address(poolManager));
        bytes memory initData = abi.encode(true);
        hook.beforeInitialize(address(this), testKey, 0);

        // Register low-risk asset
        TradeFinanceHook.TradeAsset memory lowRiskAsset = TradeFinanceHook.TradeAsset({
            faceValue: 100000e18,
            maturityTimestamp: block.timestamp + 90 days,
            creditScore: 95, // High credit
            assetType: TradeFinanceHook.AssetType.LETTER_OF_CREDIT,
            jurisdictionHash: keccak256("US"),
            isActive: false
        });

        bytes memory hookData = abi.encode(true, lowRiskAsset);
        vm.prank(address(poolManager));
        hook.beforeAddLiquidity(alice, testKey, ModifyLiquidityParams(0, 0, 0, bytes32(0)), hookData);

        uint24 lowRiskFee = hook.getDynamicFee(testPoolId, alice);
        
        // Register high-risk asset for bob
        TradeFinanceHook.TradeAsset memory highRiskAsset = TradeFinanceHook.TradeAsset({
            faceValue: 100000e18,
            maturityTimestamp: block.timestamp + 3 days,
            creditScore: 40, // Low credit
            assetType: TradeFinanceHook.AssetType.RECEIVABLE,
            jurisdictionHash: keccak256("US"),
            isActive: false
        });

        bytes memory bobHookData = abi.encode(true, highRiskAsset);
        vm.prank(address(poolManager));
        hook.beforeAddLiquidity(bob, testKey, ModifyLiquidityParams(0, 0, 0, bytes32(0)), bobHookData);

        uint24 highRiskFee = hook.getDynamicFee(testPoolId, bob);

        console.log("Low risk fee:", lowRiskFee);
        console.log("High risk fee:", highRiskFee);

        assertLt(lowRiskFee, highRiskFee, "High risk should have higher fee");
        assertGe(lowRiskFee, 10 * 100, "Fee should be at least 0.1%");
        assertLe(highRiskFee, 300 * 100, "Fee should not exceed 3%");
    }

    function test_RiskEventTracking() public {
        // Setup pool
        vm.prank(address(poolManager));
        bytes memory initData = abi.encode(true);
        hook.beforeInitialize(address(this), testKey, 0);

        // Register asset
        TradeFinanceHook.TradeAsset memory asset = TradeFinanceHook.TradeAsset({
            faceValue: 100000e18,
            maturityTimestamp: block.timestamp + 90 days,
            creditScore: 80,
            assetType: TradeFinanceHook.AssetType.INVOICE,
            jurisdictionHash: keccak256("US"),
            isActive: false
        });

        bytes memory hookData = abi.encode(true, asset);
        vm.prank(address(poolManager));
        hook.beforeAddLiquidity(alice, testKey, ModifyLiquidityParams(0, 0, 0, bytes32(0)), hookData);

        // Get initial risk score
        uint256 initialRisk = hook.getRiskScore(testPoolId, alice);

        // Add late payment event
        hook.addRiskEvent(testPoolId, alice, 50, true, false);

        // Risk should increase
        uint256 newRisk = hook.getRiskScore(testPoolId, alice);
        
        console.log("Initial risk:", initialRisk);
        console.log("Risk after late payment:", newRisk);
        
        assertGt(newRisk, initialRisk, "Risk should increase after late payment");
    }

    function test_Constants() public view {
        assertEq(hook.LIQUIDATION_THRESHOLD(), 8000, "Liquidation threshold should be 80%");
        assertEq(hook.SOFT_LIQUIDATION_MAX(), 2000, "Max liquidation should be 20%");
        assertEq(hook.MIN_FEE_BPS(), 10, "Min fee should be 0.1%");
        assertEq(hook.MAX_FEE_BPS(), 300, "Max fee should be 3%");
    }
}
