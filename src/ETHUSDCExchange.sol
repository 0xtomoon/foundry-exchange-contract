// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @title A contract for swapping ETH with USDC based on Chainlink price feeds
/// @notice This contract allows users to deposit ETH and swap it for USDC using real-time prices and also allows withdrawal of ETH and USDC by the owner.
contract ETHUSDCExchange is Initializable, OwnableUpgradeable {
    IERC20 public usdcToken;
    AggregatorV3Interface public priceFeed;

    // State variables
    mapping(address => uint256) public ethBalances;

    // Events
    event DepositedETH(address indexed user, uint256 amount);
    event SwappedETHforUSDC(address indexed user, uint256 ethAmount, uint256 usdcAmount);
    event WithdrawnETH(uint256 amount);
    event WithdrawnUSDC(uint256 amount);

    /// @notice Initializes the contract with specified USDC token and Chainlink price feed addresses
    /// @param _usdcTokenAddress The address of the USDC token contract
    /// @param _priceFeedAddress The address of the Chainlink price feed contract
    function initialize(address _usdcTokenAddress, address _priceFeedAddress) public initializer {
        __Ownable_init(msg.sender);
        usdcToken = IERC20(_usdcTokenAddress);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    /// @notice Allows users to deposit ETH into the contract
    /// @dev Emits a DepositedETH event on successful deposit
    function depositETH() external payable {
        ethBalances[msg.sender] += msg.value;
        emit DepositedETH(msg.sender, msg.value);
    }

    /// @notice Allows users to swap their deposited ETH for USDC based on the current market price
    /// @param ethAmount The amount of ETH to swap
    /// @dev Emits a SwappedETHforUSDC event on successful swap
    function swapETHforUSDC(uint256 ethAmount) external {
        require(ethBalances[msg.sender] >= ethAmount, "Insufficient ETH balance");
        uint256 usdcAmount = getUSDCAmount(ethAmount);
        require(usdcToken.balanceOf(address(this)) >= usdcAmount, "Insufficient USDC in contract");
        ethBalances[msg.sender] -= ethAmount;
        usdcToken.transfer(msg.sender, usdcAmount);
        emit SwappedETHforUSDC(msg.sender, ethAmount, usdcAmount);
    }

    /// @notice Calculates the amount of USDC equivalent to the given amount of ETH
    /// @param ethAmount The amount of ETH
    /// @return The equivalent amount of USDC
    /// @dev Fetches the latest ETH/USD price from Chainlink and performs the conversion
    function getUSDCAmount(uint256 ethAmount) public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 priceInUsdc = uint256(price);
        return (ethAmount * priceInUsdc) / 1e20; // 1e18 (wei) * 1e8 (Chainlink price) / 1e6 (USDC decimals) = 1e20
    }

    /// @notice Allows the owner to withdraw ETH from the contract
    /// @param amount The amount of ETH to withdraw
    /// @dev Emits a WithdrawnETH event on successful withdrawal
    function withdrawETH(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Failed to send Ether");
        emit WithdrawnETH(amount);
    }

    /// @notice Allows the owner to withdraw USDC from the contract
    /// @param amount The amount of USDC to withdraw
    /// @dev Emits a WithdrawnUSDC event on successful withdrawal
    function withdrawUSDC(uint256 amount) external onlyOwner {
        require(usdcToken.balanceOf(address(this)) >= amount, "Insufficient USDC balance");
        usdcToken.transfer(owner(), amount);
        emit WithdrawnUSDC(amount);
    }
}
