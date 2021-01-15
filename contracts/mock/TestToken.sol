pragma solidity ^0.6.0;

import '../libraries/ERC20.sol';

contract TestToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint _totalSupply
    ) public ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    }
}
