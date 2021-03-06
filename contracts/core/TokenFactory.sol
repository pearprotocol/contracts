//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

import '@openzeppelin/contracts/proxy/Clones.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IToken.sol';
import './interfaces/ITokenFactory.sol';

contract TokenFactory is ITokenFactory {
    // Details for each token
    struct TokenInfo {
        address token;
        address creator;
        address deployer;
    }

    uint256 constant private SCALE = 10**18;
    uint256 constant public BASE_PRICE = 10**17; // 0.1
    uint256 constant public RISE_PRICE = 10**14; // 0.0001
    uint256 constant public INITIAL_TOKENS = 100000 * SCALE;

    IERC20 public dai;
    uint256 public totalDaiDeposited;
    address public interestManager;
    address public tokenTemplate;

    // mapping for address to token info
    mapping(address => TokenInfo) public tokenInfos;

    event NewToken(address indexed token, address indexed creator, address indexed deployer);
    event CreatorChanged(address indexed token, address indexed newCreator, address indexed oldCreator);
    event TokenMinted(address indexed token, address indexed sender, address indexed recipient, uint256 amount, uint256 cost);
    event TokenBurnt(address indexed token, address indexed sender, address indexed recipient, uint256 amount, uint256 cost);

    constructor(address _tokenTemplate) {
        tokenTemplate = _tokenTemplate;
        // dai = IERC20(_dai);
    }

    function createToken(string calldata tokenName, string calldata tokenSymbol) external override returns (address) {
        return createTokenWithCreator(tokenName, tokenSymbol, msg.sender);
    }

    function createTokenWithCreator(string calldata tokenName, string calldata tokenSymbol, address creator) public override returns (address) {
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

    function changeCreator(address token, address creator) external {
        require(creator != address(0x0), 'New creator must not be empty');

        TokenInfo memory tokenInfo = tokenInfos[token];
        require(tokenInfo.token != address(0x0), 'Token does not exist');
        require(tokenInfo.creator == msg.sender, 'Only current creator can change the creator');

        emit CreatorChanged(token, creator, tokenInfo.creator);
        tokenInfo.creator = creator;
    }

    function buyTokens(address token, uint256 tokenAmount, uint256 minimumTokenAmount, uint256 daiAmount, address recipient) external override {
        TokenInfo memory tokenInfo = tokenInfos[token];
        require(tokenInfo.token != address(0x0), 'Token does not exist');

        // actual amount of tokens
        uint256 actualAmount = tokenAmount;

        // get total supply
        uint256 supply = IERC20(token).totalSupply();
        uint256 costToBuy = buyCost(supply, actualAmount);
        if(costToBuy > daiAmount) {
            // get buy cost again for minimum token amount
            actualAmount = minimumTokenAmount;
            costToBuy = buyCost(supply, actualAmount);

            require(costToBuy <= daiAmount, "Too much slippage");
        }

        require(dai.transferFrom(msg.sender, address(interestManager), costToBuy), "DAI transfer failed");

        // update deposited dai
        totalDaiDeposited = totalDaiDeposited + costToBuy;

        // mint token to recipient
        IToken(token).mint(recipient, actualAmount);

        // emit an event for record
        emit TokenMinted(token, msg.sender, recipient, actualAmount, costToBuy);
    }

    function sellTokens(address token, uint256 tokenAmount, uint256 minimumPrice, address recipient) external override {
        TokenInfo memory tokenInfo = tokenInfos[token];
        require(tokenInfo.token != address(0x0), 'Token does not exist');

        // get total supply
        uint256 supply = IERC20(token).totalSupply();
        uint256 costToSell = sellCost(supply, tokenAmount);

        // check slippage
        require(costToSell >= minimumPrice, "Too much slippage");

        // update deposited dai
        totalDaiDeposited = totalDaiDeposited - costToSell;

        // burn token from sender
        IToken(token).burn(msg.sender, tokenAmount);

        // transfer dai
        require(dai.transfer(recipient, costToSell), "DAI transfer failed");

        // emit an event for record
        emit TokenBurnt(token, msg.sender, recipient, tokenAmount, costToSell);
    }

    //
    // Pure functions
    //

    function buyCost(uint256 supply, uint256 amount) public pure override returns (uint256) {
        uint256 hatchPrice = 0;
        uint256 updatedAmount = 0;
        uint256 updatedSupply = 0;

        if(supply < INITIAL_TOKENS) {
            uint256 remainingHatchTokens = INITIAL_TOKENS - supply;

            if(amount <= remainingHatchTokens) {
                return BASE_PRICE * (amount / SCALE);
            }

            hatchPrice = BASE_PRICE * (remainingHatchTokens / SCALE);
            updatedSupply = 0;
            updatedAmount = amount - remainingHatchTokens;
        } else {
            updatedSupply = supply - INITIAL_TOKENS;
            updatedAmount = amount;
        }

        uint256 priceAtSupply = BASE_PRICE + ((RISE_PRICE * updatedSupply) / SCALE);
        uint256 priceAtSupplyPlusAmount = BASE_PRICE + ((RISE_PRICE * (updatedSupply + updatedAmount)) / SCALE);
        uint256 average = (priceAtSupply + priceAtSupplyPlusAmount) / 2;

        return hatchPrice + (average * (updatedAmount / SCALE));
    }

    function sellCost(uint256 supply, uint256 amount) public pure override returns (uint256) {
        uint256 hatchPrice = 0;
        uint256 updatedAmount = amount;
        uint256 updatedSupply;

        if (supply - amount < INITIAL_TOKENS) {
            if (supply <= INITIAL_TOKENS) {
                return BASE_PRICE * (amount / SCALE);
            }

            uint256 tokensInHatch = INITIAL_TOKENS - (supply - amount);
            hatchPrice = BASE_PRICE * (tokensInHatch / SCALE);
            updatedAmount = amount - tokensInHatch;
            updatedSupply = supply - INITIAL_TOKENS;
        } else {
            updatedSupply = supply - INITIAL_TOKENS;
        }

        uint256 priceAtSupply = BASE_PRICE + ((RISE_PRICE * updatedSupply) / SCALE);
        uint256 priceAtSupplyMinusAmount = BASE_PRICE + ((RISE_PRICE * (updatedSupply - updatedAmount)) / SCALE);
        uint256 average = (priceAtSupply + priceAtSupplyMinusAmount) / 2;

        return hatchPrice + (average * (updatedAmount / SCALE));
    }
}
