// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "src/ETHUSDCExchange.sol";
import "src/mock/USDCMock.sol";
import "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployETHUSDCExchange is Script {
    function run() external {
        // Start broadcasting the deployment transaction
        vm.startBroadcast();

        USDCMock usdc = new USDCMock();

        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(8, 2000 * 10**8);

        address proxy = Upgrades.deployTransparentProxy(
            "ETHUSDCExchange.sol",
            msg.sender,
            abi.encodeCall(ETHUSDCExchange.initialize, (address(usdc), address(mockPriceFeed)))
        );

        // Stop broadcasting the transaction
        vm.stopBroadcast();

        // Log the proxy contract address
        console.log("USDCMock deployed at:", address(usdc));
        console.log("MockV3Aggregator deployed at:", address(mockPriceFeed));
        console.log("ETHUSDCExchange deployed at:", address(proxy));
    }
}
