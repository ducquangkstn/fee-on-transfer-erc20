pragma solidity ^0.6.0;

import '@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol';

import '../interfaces/IERC20WithFee.sol';

library UniswapV2Library2 {
    function getReservesInfo(
        address factory,
        address tokenA,
        address tokenB
    )
        internal
        view
        returns (
            address pair,
            uint reserveA,
            uint reserveB
        )
    {
        (address token0, ) = UniswapV2Library.sortTokens(tokenA, tokenB);
        pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /// @dev getAmountOut when trade tokenWithFee
    /// @return amounts temporary amountOut when call to pair
    /// @return actualAmountOut the final received amount
    function getAmountsOut(
        address factory,
        uint amountIn,
        address[] memory path,
        address from,
        address to,
        bool[] memory areFOTTokens
    ) internal virtual view returns (uint[] memory amounts, uint actualAmountOut) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        require(areFOTTokens.length == path.length, 'UniswapV2Library: INVALID_FEE_PARAMS');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (address pair, uint reserveIn, uint reserveOut) = getReservesInfo(factory, path[i], path[i + 1]);

            uint actualAmountIn = amounts[i];
            // get the actual amountIn
            if (areFOTTokens[i]) {
                (actualAmountIn, ) = IERC20WithFee(path[i]).getReceivedAmount(from, pair, actualAmountIn);
            }
            amounts[i + 1] = UniswapV2Library.getAmountOut(actualAmountIn, reserveIn, reserveOut);
            // set the from address to calculate the next amountIn
            from = pair;
        }

        // get the actual amountOut
        actualAmountOut = amounts[path.length - 1];
        if (areFOTTokens[path.length - 1]) {
            (actualAmountOut, ) = IERC20WithFee(path[path.length - 1]).getReceivedAmount(from, to, actualAmountOut);
        }
    }

    /// @dev performs chained getAmountIn calculations on any number of pairs
    /// @return amounts the amount need to send to 1st pair and the temporary amountOut when call to pair
    function getAmountsIn(
        address factory,
        uint amountOut,
        address[] memory path,
        address from,
        address to,
        bool[] memory areFOTTokens
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        require(areFOTTokens.length == path.length, 'UniswapV2Library: INVALID_FEE_PARAMS');

        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (address pair, uint reserveIn, uint reserveOut) = getReservesInfo(factory, path[i - 1], path[i]);

            // get the actual amountOut
            if (areFOTTokens[i]) {
                (amounts[i], ) = IERC20WithFee(path[i]).getSendAmount(pair, to, amounts[i]);
            }

            amounts[i - 1] = UniswapV2Library.getAmountIn(amounts[i], reserveIn, reserveOut);
            // set the to address to calculate the next amountOut
            to = pair;
        }
        // get the actual amountIn
        if (areFOTTokens[0]) {
            (amounts[0], ) = IERC20WithFee(path[0]).getSendAmount(from, to, amounts[0]);
        }
    }
}
