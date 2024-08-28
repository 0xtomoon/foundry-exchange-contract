// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/ETHUSDCExchange.sol";
import "../src/ETHUSDCExchangeV2.sol";
import "../src/mock/USDCMock.sol";
import "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract ETHUSDCExchangeTest is Test {
    ETHUSDCExchange exchange;
    USDCMock usdc;
    MockV3Aggregator priceFeed;
    address owner;
    address nonOwner = address(0x1);

    function setUp() public {
        owner = address(this);  // Test contract is the owner
        usdc = new USDCMock();
        priceFeed = new MockV3Aggregator(8, 2000 * 10**8); // start with a price of $2000 per ETH
        address proxy = Upgrades.deployTransparentProxy(
            "ETHUSDCExchange.sol",
            owner,
            abi.encodeCall(ETHUSDCExchange.initialize, (address(usdc), address(priceFeed)))
        );

        exchange = ETHUSDCExchange(proxy);
        usdc.transfer(address(exchange), 100000 * 10**usdc.decimals());  // Funding the exchange with USDC
    }

    function testUpgrade() public {
        Upgrades.upgradeProxy(
            address(exchange),
            "ETHUSDCExchangeV2.sol",
            ""
        );
        assertEq(ETHUSDCExchangeV2(address(exchange)).returnHundred(), 100, "Contract is not upgraded successfully.");
    }

    function testDepositETH() public {
        // Setup: ensure the test contract has enough ETH to deposit
        uint depositAmount = 1 ether;
        vm.deal(address(this), depositAmount);  // Give this contract some ETH to deposit

        // Check initial conditions
        uint initialContractBalance = address(exchange).balance;
        uint initialSenderBalance = exchange.ethBalances(address(this));

        // Simulate the deposit
        vm.prank(address(this));  // Make the next call come from this address
        exchange.depositETH{value: depositAmount}();

        // Check the contract's balance has increased by the deposit amount
        assertEq(address(exchange).balance, initialContractBalance + depositAmount, "Contract balance did not increase correctly");

        // Check the sender's balance in the contract's ethBalances mapping
        uint newSenderBalance = exchange.ethBalances(address(this));
        assertEq(newSenderBalance, initialSenderBalance + depositAmount, "Sender's balance in the mapping was not updated correctly");

        // Emit the correct event
        assertEq(newSenderBalance, depositAmount, "Event DepositedETH not emitted with correct value");
    }

    function testSwapETHforUSDC() public {
        // Setup initial conditions
        uint depositAmount = 1 ether;
        vm.deal(address(this), depositAmount);  // Ensure this contract has ETH to deposit
        exchange.depositETH{value: depositAmount}();

        // Calculate expected USDC amount
        uint256 expectedUSDC = exchange.getUSDCAmount(depositAmount);
        
        uint usdcInitialBalance = usdc.balanceOf(address(exchange));
        uint initialUserUSDCBalance = usdc.balanceOf(address(this));

        // Perform the swap
        vm.prank(address(this));
        exchange.swapETHforUSDC(depositAmount);

        // Check post-swap ETH and USDC balances
        assertEq(exchange.ethBalances(address(this)), 0, "ETH balance should be zero after swap");
        assertEq(usdc.balanceOf(address(this)), initialUserUSDCBalance + expectedUSDC, "USDC balance incorrect after swap");
        assertEq(usdc.balanceOf(address(exchange)), usdcInitialBalance - expectedUSDC, "Contract USDC balance incorrect after swap");
    }

    function testWithdrawETH() public {
        // Setup initial conditions
        uint depositAmount = 1 ether;
        vm.deal(address(this), depositAmount);  // Ensure this contract has ETH to deposit
        exchange.depositETH{value: depositAmount}();

        uint withdrawalAmount = 0.5 ether;
        exchange.withdrawETH(withdrawalAmount);
        assertEq(address(this).balance, withdrawalAmount, "Withdraw ETH failed");
    }

    function testWithdrawUSDC() public {
        uint initialUserUSDCBalance = usdc.balanceOf(address(this));
        uint withdrawalAmount = 50000 * 10**usdc.decimals();
        exchange.withdrawUSDC(withdrawalAmount);
        assertEq(usdc.balanceOf(address(this)), initialUserUSDCBalance + withdrawalAmount, "Withdraw USDC failed");
    }

    function testWithdrawETHWithRevert() public {
        // Attempt to withdraw as a non-owner
        uint amount = 1 ether;
        vm.deal(address(exchange), amount);  // Ensure the contract has some ETH to withdraw
        vm.prank(nonOwner);  // Set the next call to come from a non-owner
        bytes memory encodedError = abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner);
        vm.expectRevert(encodedError);
        exchange.withdrawETH(amount);
    }

    function testWithdrawUSDCWithRevert() public {
        uint withdrawalAmount = 50000 * 10**usdc.decimals();
        vm.prank(nonOwner);  // Set the next call to come from a non-owner
        bytes memory encodedError = abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner);
        vm.expectRevert(encodedError);
        exchange.withdrawUSDC(withdrawalAmount);
    }

    receive() external payable {}  // Allow the contract to receive ETH
}
