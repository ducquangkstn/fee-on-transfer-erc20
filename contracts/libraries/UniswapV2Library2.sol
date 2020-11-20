pragma solidity ^0.6.0;

import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";

import "../interfaces/IERC20Extended.sol";

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
            uint256 reserveA,
            uint256 reserveB
        )
    {
        (address token0, ) = UniswapV2Library.sortTokens(tokenA, tokenB);
        pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path,
        address from,
        address to,
        bool[] memory areFOTTokens
    ) public virtual view returns (uint256[] memory amounts, uint256 acutalAmountOut) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        require(areFOTTokens.length == path.length, "UniswapV2Library: INVALID_FEE_PARAMS");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (address pair, uint256 reserveIn, uint256 reserveOut) = getReservesInfo(
                factory,
                path[i],
                path[i + 1]
            );

            uint256 actualAmountIn = amounts[i];
            // get the actual amountIn
            if (areFOTTokens[i]) {
                (actualAmountIn, ) = IERC20Extended(path[i]).getReceivedAmount(
                    from,
                    pair,
                    actualAmountIn
                );
            }
            amounts[i + 1] = UniswapV2Library.getAmountOut(actualAmountIn, reserveIn, reserveOut);
            // set the from address to calculate the next amountIn
            from = pair;
        }

        // get the actual amountOut
        acutalAmountOut = amounts[path.length - 1];
        if (areFOTTokens[path.length - 1]) {
            (acutalAmountOut, ) = IERC20Extended(path[path.length - 1]).getReceivedAmount(
                from,
                to,
                acutalAmountOut
            );
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path,
        address from,
        address to,
        bool[] memory areFOTTokens
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        require(areFOTTokens.length == path.length, "UniswapV2Library: INVALID_FEE_PARAMS");

        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (address pair, uint256 reserveIn, uint256 reserveOut) = getReservesInfo(
                factory,
                path[i],
                path[i + 1]
            );

            // get the actual amountOut
            if (areFOTTokens[i]) {
                (amounts[i], ) = IERC20Extended(path[i]).getSendAmount(pair, to, amounts[i]);
            }

            amounts[i - 1] = UniswapV2Library.getAmountIn(amounts[i], reserveIn, reserveOut);
            // set the to address to calculate the next amountOut
            to = pair;
        }
        // get the actual amountIn
        if (areFOTTokens[0]) {
            (amounts[0], ) = IERC20Extended(path[0]).getSendAmount(from, to, amounts[0]);
        }
    }
}
