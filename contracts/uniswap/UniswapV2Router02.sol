pragma solidity ^0.6.0;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "../interfaces/IERC20Extended.sol";
import "../libraries/UniswapV2Library2.sol";
import "./UniswapV2Router01.sol";

contract UniswapV2Router02 is UniswapV2Router01 {
    using SafeMath for uint256;

    constructor(address _factory, address _WETH) public UniswapV2Router01(_factory, _WETH) {}

    function addLiquiditySupportingFOTTokens(
        address[2] calldata tokens,
        uint256[2] calldata desiredAmounts,
        uint256[2] calldata minAmounts,
        bool[2] calldata areFOTTokens,
        address to,
        uint256 deadline
    )
        external
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            tokens[0],
            tokens[1],
            desiredAmounts[0],
            desiredAmounts[1],
            minAmounts[0],
            minAmounts[1]
        );
        address pair = UniswapV2Library.pairFor(factory, tokens[0], tokens[1]);
        if (areFOTTokens[0]) {
            IERC20Extended(tokens[0]).transferExactDestFrom(msg.sender, pair, amountA);
        } else {
            TransferHelper.safeTransferFrom(tokens[0], msg.sender, pair, amountA);
        }
        if (areFOTTokens[1]) {
            IERC20Extended(tokens[1]).transferExactDestFrom(msg.sender, pair, amountB);
        } else {
            TransferHelper.safeTransferFrom(tokens[1], msg.sender, pair, amountB);
        }
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    function addLiquidityETHSupportingFOTTokens(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        bool isFOTToken,
        address to,
        uint256 deadline
    )
        external
        payable
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        if (isFOTToken) {
            IERC20Extended(token).transferExactDestFrom(msg.sender, pair, amountToken);
        } else {
            TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        }
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFOTTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual ensure(deadline) returns (uint256 amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );

        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityETHWithPermitSupportingFOTTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint256 value = approveMax ? uint256(-1) : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFOTTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFOTTokens(address[] memory path, address _to) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = UniswapV2Library.getAmountOut(
                    amountInput,
                    reserveInput,
                    reserveOutput
                );
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(factory, output, path[i + 2])
                : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFOTTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        bool[] calldata areFOTTokens,
        uint256 deadline
    ) external virtual ensure(deadline) {
        (uint256[] memory amounts, uint256 actualAmountOut) = UniswapV2Library2.getAmountsOut(
            factory,
            amountIn,
            path,
            msg.sender,
            to,
            areFOTTokens
        );
        require(actualAmountOut >= amountOutMin, "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amountIn
        );
        _swap(amounts, path, to);
    }

    function swapExactETHForTokensSupportingFOTTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        bool[] calldata areFOTTokens,
        uint256 deadline
    ) external virtual payable ensure(deadline) {
        require(path[0] == WETH, "UniswapV2Router: INVALID_PATH");
        uint256 amountIn = msg.value;
        (uint256[] memory amounts, uint256 actualAmountOut) = UniswapV2Library2.getAmountsOut(
            factory,
            amountIn,
            path,
            msg.sender,
            to,
            areFOTTokens
        );
        require(actualAmountOut >= amountOutMin, "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");

        IWETH(WETH).deposit{value: amountIn}();
        assert(
            IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn)
        );
        _swap(amounts, path, to);
    }

    function swapExactTokensForETHSupportingFOTTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        bool[] calldata areFOTTokens,
        uint256 deadline
    ) external virtual ensure(deadline) {
        require(path[path.length - 1] == WETH, "UniswapV2Router: INVALID_PATH");
        (uint256[] memory amounts, uint256 actualAmountOut) = UniswapV2Library2.getAmountsOut(
            factory,
            amountIn,
            path,
            msg.sender,
            to,
            areFOTTokens
        );
        require(actualAmountOut >= amountOutMin, "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amountIn
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(actualAmountOut);
        TransferHelper.safeTransferETH(to, actualAmountOut);
    }

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path,
        address from,
        address to,
        bool[] memory areFOTTokens
    ) public virtual view returns (uint256[] memory amounts, uint256 actualAmountOut) {
        return UniswapV2Library2.getAmountsOut(factory, amountIn, path, from, to, areFOTTokens);
    }

    // function getAmountsIn(
    //     uint256 amountOut,
    //     address[] memory path,
    //     bool[] memory areFOTTokens
    // ) public virtual override view returns (uint256[] memory amounts) {
    //     return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    // }
}
