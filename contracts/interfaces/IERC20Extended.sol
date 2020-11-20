pragma solidity ^0.6.0;

import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";

interface IERC20Extended is IERC20 {
    function transferExactDest(address _to, uint256 _value) external returns (bool success);

    function transferExactDestFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function getReceivedAmount(
        address _from,
        address _to,
        uint256 _sentAmount
    ) external view returns (uint256 receivedAmount, uint256 feeAmount);

    function getSendAmount(
        address _from,
        address _to,
        uint256 _receivedAmount
    ) external view returns (uint256 sendAmount, uint256 feeAmount);
}
