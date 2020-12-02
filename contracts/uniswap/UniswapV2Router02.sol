pragma solidity ^0.6.0;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../interfaces/IERC20Extended.sol";
import "../libraries/UniswapV2Library2.sol";
import "./UniswapV2Router01.sol";

contract UniswapV2Router02 is UniswapV2Router01 {
    using SafeMath for uint256;

    constructor(address _factory, address _weth) public UniswapV2Router01(_factory, _weth) {}

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

    function swapTokensForExactTokensSupportingFOTTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        bool[] calldata areFOTTokens,
        uint256 deadline
    ) external virtual ensure(deadline) {
        uint256[] memory amounts = UniswapV2Library2.getAmountsIn(
            factory,
            amountOut,
            path,
            msg.sender,
            to,
            areFOTTokens
        );
        require(amounts[0] <= amountInMax, "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
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

    function getAmountsInSupportingFOTTokens(
        uint256 amountOut,
        address[] memory path,
        address from,
        address to,
        bool[] memory areFOTTokens
    ) public virtual view returns (uint256[] memory amounts) {
        return UniswapV2Library2.getAmountsIn(factory, amountOut, path, from, to, areFOTTokens);
    }
}
