// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ITokenFactory {
    function createToken(string calldata tokenName, string calldata tokenSymbol) external returns (address);
    function createTokenWithCreator(string calldata tokenName, string calldata tokenSymbol, address creator) external returns (address);

    function buyCost(uint256 supply, uint256 amount) external pure returns (uint256);
    function sellCost(uint256 supply, uint256 amount) external pure returns (uint256);

    function buyTokens(address token, uint256 tokenAmount, uint256 slippage, uint256 daiAmount, address recipient) external;
    function sellTokens(address token, uint256 tokenAmount, uint256 minimumPrice, address recipient) external;
}