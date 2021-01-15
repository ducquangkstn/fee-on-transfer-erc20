pragma solidity 0.6.6;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol';

/// @dev interface for modified uniswap router 02
interface IUniswapV2Router02 is IUniswapV2Router01 {
    /// @dev add liquidity for token with fee and eth
    /// @param amountTokenDesired maximum amount of token to contribute to pair
    /// @param amountTokenMin minimum amount of token to contribute to pair
    /// @param  amountETHMin minimum amount of eth to contribute to pair
    function addLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        );

    /// @dev add liquidity for tokens
    /// @param tokens address of token
    /// @param desiredAmounts maximum amount of token to contribute to pair
    /// @param minAmounts minimum amount of eth to contribute to pair
    /// @param isFOTTokenFlags flags for fee-on-transfer token
    function addLiquiditySupportingFeeOnTransferTokens(
        address[2] calldata tokens,
        uint[2] calldata desiredAmounts,
        uint[2] calldata minAmounts,
        bool[2] calldata isFOTTokenFlags,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB,
            uint liquidity
        );

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    /// @dev swap from token to token
    /// @param amountIn the exact amount user need to pay
    /// @param amountOutMin the minimun output amount user received
    /// @param path the token trade paths
    /// @param to dest address
    /// @param isFOTTokenFlags the flags indicate which tokens have fee on transfer
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        bool[] calldata isFOTTokenFlags,
        uint deadline
    ) external returns (uint[] memory amounts, uint actualAmountOut);

    /// @dev swap from eth to token
    /// @param amountOutMin the minimun output amount user received
    /// @param path the token trade paths
    /// @param to dest address
    /// @param isFOTTokenFlags the flags indicate which tokens have fee on transfer
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        bool[] calldata isFOTTokenFlags,
        uint deadline
    ) external payable returns (uint[] memory amounts, uint actualAmountOut);

    /// @dev swap from token to eth
    /// @param amountIn the exact amount user need to pay
    /// @param amountOutMin the minimun output amount user received
    /// @param path the token trade paths
    /// @param to dest address
    /// @param isFOTTokenFlags the flags indicate which tokens have fee on transfer
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        bool[] calldata isFOTTokenFlags,
        uint deadline
    ) external returns (uint[] memory amounts, uint actualAmountOut);

    /// @dev swap from token to token
    /// @param amountOut the exact amount user received
    /// @param amountInMax the maximum output amount user need to pay
    /// @param path the token trade paths
    /// @param to dest address
    /// @param isFOTTokenFlags the flags indicate which tokens have fee on transfer
    function swapTokensForExactTokensSupportingFeeOnTransferTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        bool[] calldata isFOTTokenFlags,
        uint deadline
    ) external returns (uint[] memory amounts);
}
