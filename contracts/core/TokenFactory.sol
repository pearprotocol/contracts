//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

import '@openzeppelin/contracts/proxy/Clones.sol';
import './interfaces/IToken.sol';

contract TokenFactory {
    // Details for each token
    struct TokenInfo {
        address token;
        address creator;
        address deployer;
    }

    uint256 public numberOfTokens;
    address public tokenTemplate;

    // mapping for address to token info
    mapping(address => TokenInfo) public tokenInfos;

    event NewToken(address indexed token, address indexed creator, address indexed deployer);

    constructor(address _tokenTemplate) {
        tokenTemplate = _tokenTemplate;
    }

    function createToken(string calldata tokenName, string calldata tokenSymbol) public returns (address) {
        return createTokenWithCreator(tokenName, tokenSymbol, msg.sender);
    }

    function createTokenWithCreator(string calldata tokenName, string calldata tokenSymbol, address creator) public returns (address) {
        IToken token = IToken(Clones.clone(tokenTemplate));
        token.initialize(
            string(abi.encodePacked('Pear: ', tokenName)),
            string(abi.encodePacked('PEAR_', tokenSymbol)),
            address(this)
        );

        TokenInfo memory tokenInfo = TokenInfo({
            token: address(token),
            creator: creator,
            deployer: msg.sender
        });

        tokenInfos[address(token)] = tokenInfo;

        emit NewToken(address(token), creator, msg.sender);

        // return token address
        return address(token);
    }
}
