// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToken is IERC20 {
    function initialize(string calldata __name, string calldata __symbol, address __owner) external;
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}