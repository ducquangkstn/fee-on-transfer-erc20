pragma solidity ^0.6.0;

import '@uniswap/v2-periphery/contracts/interfaces/IERC20.sol';

interface IERC20WithFee is IERC20 {
    function transferExactDest(address _to, uint _value) external returns (bool success);

    function transferExactDestFrom(
        address _from,
        address _to,
        uint _value
    ) external returns (bool success);

    function getReceivedAmount(
        address _from,
        address _to,
        uint _sentAmount
    ) external view returns (uint receivedAmount, uint feeAmount);

    function getSendAmount(
        address _from,
        address _to,
        uint _receivedAmount
    ) external view returns (uint sendAmount, uint feeAmount);
}
