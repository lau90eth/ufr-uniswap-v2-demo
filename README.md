# UFR + Uniswap V2 Integration Demo

[![Solidity](https://img.shields.io/badge/Solidity-0.5.16-informational)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FF0077)](https://getfoundry.sh/)

> **Universal Fee Router** integrated into **Uniswap V2** for automatic fee splitting.

## Live UFR Contracts

| Network  | Address                                    | Status |
|----------|--------------------------------------------|--------|
| Ethereum | 0x42dca1984a1faac1ca7f1980a78fcd96782f36e9 | ✅ Live |
| Base     | 0xe3e462c58c1fe28b6b48208c4f0900d68c9d9785 | ✅ Live |
| Optimism | 0x0b262cb79ebe8ff6602e41cf286280485407b360 | ✅ Live |
| Arbitrum | 0xe3e462c58c1fe28b6b48208c4f0900d68c9d9785 | ✅ Live |

## What This Demo Shows

User swaps 1000 USDC → ETH  
↓ V2 Pair extracts 0.3% fee (3 USDC)  
↓ Fee sent to UFR  
↓ UFR splits instantly:  
   ├── 70% → Frontend  
   └── 30% → Protocol  
↓ Swap completes normally

## Quick Start

```bash
# Install dependencies
forge install

# Run tests
forge test -vvv

# Deploy & test locally
anvil &
forge script script/DeployDemo.s.sol --broadcast --fork-url http://localhost:8545

Modified Files
File,Changes
src/UniswapV2Pair.sol,"Added feeRouter, fee extraction in swap()"
src/UniswapV2Factory.sol,Added setFeeRouter() to configure UFR

UFR Interface (external)
interface IUniversalFeeRouter {
    function routeERC20(address token, uint256 amount) external;
    function routeETH() external payable;
}
