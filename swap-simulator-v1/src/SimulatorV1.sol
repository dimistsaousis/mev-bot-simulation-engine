// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

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
        uint256 amountOut = 0;
        uint256 paramsArrayLength = paramsArray.length;

        for (uint256 i; i < paramsArrayLength; ) {
            SwapParams memory params = paramsArray[i];

            if (amountOut == 0) {
                amountOut = params.amount;
            } else {
                params.amount = amountOut;
            }

            if (params.protocol == 0) {
                amountOut = simulateUniswapV2SwapIn(params);
            } else if (params.protocol == 1) {
                amountOut = simulateUniswapV3SwapIn(params);
            } else if (params.protocol == 2) {
                amountOut = simulateCurveSwapIn(params);
            }

            unchecked {
                i++;
            }
        }

        return amountOut;
    }

    function simulateUniswapV2SwapIn(
        SwapParams memory params
    ) public returns (uint256 amountOut) {}

    function simulateUniswapV3SwapIn(
        SwapParams memory params
    ) public returns (uint256 amountOut) {}

    function simulateCurveSwapIn(
        SwapParams memory params
    ) public returns (uint256 amountOut) {}
}