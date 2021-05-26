//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '../erc20/ERC20.sol';

contract Token is ERC20, Initializable {
    address private _owner;

    /**
     * Constructs a Token with 18 decimals
     *
     * @param __name The name of the token
     * @param __symbol The symbol of the token
     * @param __owner The owner of this contract
     */
    function initialize(
        string calldata __name,
        string calldata __symbol,
        address __owner
    ) external initializer {
        _name = __name;
        _symbol = __symbol;
        _owner = __owner;
    }

    /**
     * Mints a given amount of tokens to an address
     *
     * @param account The address to receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address account, uint256 amount) external {
        require(_owner == msg.sender, 'Caller must be owner');
        _mint(account, amount);
    }

    /**
     * Burns a given amount of tokens from an address
     *
     * @param account The address for the tokens to be burned from
     * @param amount The amount of tokens to be burned
     */
    function burn(address account, uint256 amount) external {
        require(_owner == msg.sender, 'Caller must be owner');
        _burn(account, amount);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
}
