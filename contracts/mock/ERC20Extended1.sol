pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../libraries/ERC20.sol";
import "../interfaces/IERC20Extended.sol";

contract ERC20Extended1 is ERC20, IERC20Extended {
    using SafeMath for uint256;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) public ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        uint256 burnAmount = value / 100;
        _burn(from, burnAmount);
        uint256 transferAmount = value.sub(burnAmount);

        super._transfer(from, to, transferAmount);
    }

    function transferExactDest(address _to, uint256 _value)
        external
        override
        returns (bool success)
    {
        // srcAmount = floor(_value * 100 / 99);
        uint256 srcAmount = (_value * 100 + 98) / 99;
        _transfer(msg.sender, _to, srcAmount);
        return true;
    }

    function transferExactDestFrom(
        address _from,
        address _to,
        uint256 _value
    ) external override returns (bool success) {
        uint256 srcAmount = (_value * 100 + 98) / 99;
        return transferFrom(_from, _to, srcAmount);
    }

    function getReceivedAmount(
        address, /*_from */
        address, /*_to*/
        uint256 _sentAmount
    ) external override view returns (uint256 receivedAmount, uint256 feeAmount) {
        feeAmount = _sentAmount / 100;
        receivedAmount = _sentAmount.sub(feeAmount);
    }

    function getSendAmount(
        address, /*_from*/
        address, /*_to*/
        uint256 _receivedAmount
    ) external override view returns (uint256 sendAmount, uint256 feeAmount) {
        sendAmount = (_receivedAmount * 100 + 98) / 99;
        feeAmount = sendAmount.sub(_receivedAmount);
    }
}
