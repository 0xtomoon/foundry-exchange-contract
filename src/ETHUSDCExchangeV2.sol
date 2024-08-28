// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./ETHUSDCExchange.sol";

/// @custom:oz-upgrades-from ETHUSDCExchange
contract ETHUSDCExchangeV2 is ETHUSDCExchange {
    function returnHundred() public pure returns(uint256) {
        return 100;
    }
}
