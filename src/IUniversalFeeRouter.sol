pragma solidity >=0.5.0;

/**
 * @title IUniversalFeeRouter
 * @notice External interface - UFR already deployed at:
 *   Mainnet:  0x42dca1984a1faac1ca7f1980a78fcd96782f36e9
 *   Base/Arb: 0xe3e462c58c1fe28b6b48208c4f0900d68c9d9785
 *   Optimism: 0x0b262cb79ebe8ff6602e41cf286280485407b360
 */
interface IUniversalFeeRouter {
    /// @notice Route ERC20 fees to configured recipients
    function routeERC20(address token, uint256 amount) external;

    /// @notice Route ETH fees to configured recipients
    function routeETH() external payable;
}
