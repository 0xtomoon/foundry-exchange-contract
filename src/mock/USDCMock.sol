// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDCMock is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {
        _mint(address(msg.sender), 1000000 * 10**decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 6;  // USDC uses 6 decimal places
    }
}
