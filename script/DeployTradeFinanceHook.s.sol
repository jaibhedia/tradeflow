// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IPoolManager} from "@uniswap/v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/libraries/Hooks.sol";
import {TradeFinanceHook} from "../src/TradeFinanceHook.sol";

/// @notice Script to mine and deploy TradeFinanceHook with correct address prefix
/// @dev Uses CREATE2 to find an address that matches hook permission flags
contract DeployTradeFinanceHook is Script {
    // Pool manager address (update with actual deployed address)
    // For testing, use a mock address
    address constant POOL_MANAGER = address(0x0000000000000000000000000000000000000001);
    
    /// @notice Mines a salt that produces a hook address with correct permission flags
    /// @return hookAddress The computed hook address
    /// @return salt The salt that produces the correct address
    function mineSalt(address deployer, bytes memory creationCode)
        public
        view
        returns (address hookAddress, uint256 salt)
    {
        // Get required hook permissions
        uint160 flags = uint160(
            Hooks.BEFORE_INITIALIZE_FLAG |
            Hooks.AFTER_INITIALIZE_FLAG |
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
            Hooks.AFTER_ADD_LIQUIDITY_FLAG |
            Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_SWAP_FLAG |
            Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG
        );

        // Mine for a salt where address matches required flags
        for (uint256 i = 0; i < 100000; i++) {
            address predictedAddress = computeCreate2Address(deployer, i, creationCode);
            
            // Check if the address has the correct prefix (flags in upper bits)
            if (uint160(predictedAddress) & flags == flags) {
                return (predictedAddress, i);
            }
        }
        
        revert("Could not find valid salt within range");
    }

    /// @notice Computes CREATE2 address
    function computeCreate2Address(address deployer, uint256 salt, bytes memory creationCode)
        public
        pure
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                deployer,
                salt,
                keccak256(creationCode)
            )
        );
        return address(uint160(uint256(hash)));
    }

    /// @notice Main deployment function
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer address:", deployer);
        console.log("Pool Manager:", POOL_MANAGER);
        
        // Get creation code
        bytes memory creationCode = abi.encodePacked(
            type(TradeFinanceHook).creationCode,
            abi.encode(POOL_MANAGER)
        );
        
        console.log("Mining for valid salt...");
        
        // Mine salt
        (address predictedAddress, uint256 salt) = mineSalt(deployer, creationCode);
        
        console.log("Found valid address:", predictedAddress);
        console.log("Salt:", salt);
        
        // Deploy with CREATE2
        vm.startBroadcast(deployerPrivateKey);
        
        TradeFinanceHook hook = new TradeFinanceHook{salt: bytes32(salt)}(
            IPoolManager(POOL_MANAGER)
        );
        
        vm.stopBroadcast();
        
        require(address(hook) == predictedAddress, "Address mismatch");
        
        console.log("TradeFinanceHook deployed at:", address(hook));
        console.log("Deployment successful!");
    }

    /// @notice Dry run to find valid salt without deploying
    function findSalt() public view {
        address deployer = msg.sender;
        
        bytes memory creationCode = abi.encodePacked(
            type(TradeFinanceHook).creationCode,
            abi.encode(POOL_MANAGER)
        );
        
        console.log("Searching for valid salt...");
        console.log("Deployer:", deployer);
        
        (address predictedAddress, uint256 salt) = mineSalt(deployer, creationCode);
        
        console.log("Valid address found:", predictedAddress);
        console.log("Required salt:", salt);
    }
}
