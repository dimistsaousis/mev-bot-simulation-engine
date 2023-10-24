// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "./protocols/uniswap/UniswapV2Library.sol";
import "./protocols/uniswap/IQuoterV2.sol";
import "./protocols/curve/ICurvePool.sol";

contract SimulatorV1 {
    using SafeMath for uint256;

    // Polygon network addresses
    address public UNISWAP_V2_FACTORY =
        0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32;
    address public UNISWAP_V3_QUOTER2 =
        0x61fFE014bA17989E743c5F6cB21bF9697530B21e;

    struct SwapParams {
        uint8 protocol; // 0 (UniswapV2), 1 (UniswapV3), 2 (Curve Finance)
        address pool; // used in Curve Finance
        address tokenIn;
        address tokenOut;
        uint24 fee; // only used in Uniswap V3
        uint256 amount; // amount in (1 USDC = 1,000,000 / 1 MATIC = 1 * 10 ** 18)
    }

    constructor() {}

    function simulateSwapIn(
        SwapParams[] memory paramsArray
    ) public returns (uint256) {
        // init the resulting value to 0
        uint256 amountOut = 0;
        uint256 paramsArrayLength = paramsArray.length;

        // loop through each values in paramsArray one by one
        for (uint256 i; i < paramsArrayLength; ) {
            SwapParams memory params = paramsArray[i];

            // if no swaps have been simulated yet, set amountOut to be
            // the initial amount in value from params struct
            if (amountOut == 0) {
                amountOut = params.amount;
            } else {
                // if amountOut isn't 0, meaning a swap path has been simulated
                // at least once, use that output to be the "amount"
                params.amount = amountOut;
            }

            if (params.protocol == 0) {
                amountOut = simulateUniswapV2SwapIn(params);
            } else if (params.protocol == 1) {
                amountOut = simulateUniswapV3SwapIn(params);
            } else if (params.protocol == 2) {
                amountOut = simulateCurveSwapIn(params);
            }

            // don't worry about this part
            // it simply increments i by 1
            // this code is referenced from: https://github.com/Uniswap/universal-router/blob/main/contracts/UniversalRouter.sol
            unchecked {
                i++;
            }
        }

        return amountOut;
    }

    function simulateUniswapV2SwapIn(
        SwapParams memory params
    ) public returns (uint256 amountOut) {
        (uint reserveIn, uint reserveOut) = UniswapV2Library.getReserves(
            UNISWAP_V2_FACTORY,
            params.tokenIn,
            params.tokenOut
        );
        amountOut = UniswapV2Library.getAmountOut(
            params.amount,
            reserveIn,
            reserveOut
        );
    }

    function simulateUniswapV3SwapIn(
        SwapParams memory params
    ) public returns (uint256 amountOut) {
        IQuoterV2 quoter = IQuoterV2(UNISWAP_V3_QUOTER2);
        IQuoterV2.QuoteExactInputSingleParams memory quoterParams;
        quoterParams.tokenIn = params.tokenIn;
        quoterParams.tokenOut = params.tokenOut;
        quoterParams.amountIn = params.amount;
        quoterParams.fee = params.fee;
        quoterParams.sqrtPriceLimitX96 = 0;
        (amountOut, , , ) = quoter.quoteExactInputSingle(quoterParams);
    }

    function simulateCurveSwapIn(
        SwapParams memory params
    ) public returns (uint256 amountOut) {
        ICurvePool pool = ICurvePool(params.pool);

        int128 i = 0;
        int128 j = 0;

        int128 coinIdx = 0;

        while (i == j) {
            address coin = pool.coins(coinIdx);

            if (coin == params.tokenIn) {
                i = coinIdx;
            } else if (coin == params.tokenOut) {
                j = coinIdx;
            }

            if (i != j) {
                break;
            }

            unchecked {
                coinIdx++;
            }
        }

        amountOut = ICurvePool(params.pool).get_dy(i, j, params.amount);
    }
}
