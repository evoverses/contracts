// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title IERC20 L2 Token
 * @dev ERC20 Token that can be burned (destroyed).
 */
interface IERC20L2 is IERC20Upgradeable {
    function l1Token() external returns (address);

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;
}