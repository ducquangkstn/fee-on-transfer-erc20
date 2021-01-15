pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

import '../libraries/ERC20.sol';
import '../interfaces/IERC20WithFee.sol';

contract MockERC20WithFee1 is ERC20, IERC20WithFee {
    using SafeMath for uint;

    uint private constant FEE_BPS = 100;
    uint private constant BPS = 10000;

    constructor(
        string memory _name,
        string memory _symbol,
        uint _totalSupply
    ) public ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    }

    function transferExactDest(address _to, uint _value) external override returns (bool success) {
        (uint srcAmount, ) = getSendAmount(msg.sender, _to, _value);
        _transfer(msg.sender, _to, srcAmount);
        return true;
    }

    function transferExactDestFrom(
        address _from,
        address _to,
        uint _value
    ) external override returns (bool success) {
        (uint srcAmount, ) = getSendAmount(_from, _to, _value);
        return transferFrom(_from, _to, srcAmount);
    }

    function getReceivedAmount(
        address, /*_from */
        address, /*_to*/
        uint _sentAmount
    ) public override view returns (uint receivedAmount, uint feeAmount) {
        receivedAmount = (_sentAmount * (BPS - FEE_BPS)) / BPS;
        feeAmount = _sentAmount.sub(receivedAmount);
    }

    function getSendAmount(
        address, /*_from*/
        address, /*_to*/
        uint _receivedAmount
    ) public override view returns (uint sendAmount, uint feeAmount) {
        // srcAmount = floor(_value * BPS / BPS - FEE_BPS);
        sendAmount = (_receivedAmount * BPS + BPS - FEE_BPS - 1) / (BPS - FEE_BPS);
        feeAmount = sendAmount.sub(_receivedAmount);
    }

    function _transfer(
        address from,
        address to,
        uint value
    ) internal override {
        (uint transferAmount, uint burnAmount) = getReceivedAmount(from, to, value);
        _burn(from, burnAmount);
        super._transfer(from, to, transferAmount);
    }
}
