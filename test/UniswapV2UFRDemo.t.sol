pragma solidity =0.5.16;

import "../src/UniswapV2Pair.sol";

contract MockToken {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function transfer(address to, uint amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint amount) external returns (bool) {
        require(balanceOf[from] >= amount);
        require(allowance[from][msg.sender] >= amount);
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
}

contract MockUFR {
    address public frontend;
    address public protocol;
    mapping(address => uint) public received;

    constructor(address _frontend, address _protocol) public {
        frontend = _frontend;
        protocol = _protocol;
    }

    function routeERC20(address token, uint256 amount) external {
        uint bal = MockToken(token).balanceOf(address(this));
        uint toFrontend = bal * 70 / 100;
        uint toProtocol = bal - toFrontend;
        MockToken(token).transfer(frontend, toFrontend);
        MockToken(token).transfer(protocol, toProtocol);
        received[token] += amount;
    }
}

contract UniswapV2UFRDemoTest {
    MockToken tokenA;
    MockToken tokenB;
    UniswapV2Pair pair;
    MockUFR ufr;

    address frontend = address(0x1111);
    address protocol_addr = address(0x2222);
    address trader   = address(0x3333);
    address lp       = address(0x4444);

    bool private _passed;
    uint private _testCount;
    uint private _passCount;

    event log(string);
    event log_uint(string, uint);

    function _assert(bool condition, string memory message) internal {
        _testCount++;
        if (condition) {
            _passCount++;
        } else {
            emit log(message);
        }
    }

    function setUp() public {
        tokenA = new MockToken("Token A", "TKA");
        tokenB = new MockToken("Token B", "TKB");

        if (address(tokenA) > address(tokenB)) {
            MockToken tmp = tokenA;
            tokenA = tokenB;
            tokenB = tmp;
        }

        pair = new UniswapV2Pair();
        pair.initialize(address(tokenA), address(tokenB));

        ufr = new MockUFR(frontend, protocol_addr);
        pair.setFeeRouter(address(ufr));

        tokenA.mint(lp, 100000e18);
        tokenB.mint(lp, 100000e18);

        // Add liquidity
        tokenA.mint(address(pair), 10000e18);
        tokenB.mint(address(pair), 10000e18);
        pair.mint(lp);

        tokenA.mint(trader, 1000e18);
    }

    function test_swap_routesFees() public {
        setUp();

        uint amountIn = 100e18;

        tokenA.mint(address(pair), amountIn);

        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint rIn  = uint(r0);
        uint rOut = uint(r1);
        uint amountOut = (amountIn * 997 * rOut) / (rIn * 1000 + amountIn * 997);

        pair.swap(0, amountOut, trader, "");

        uint frontendBal = tokenA.balanceOf(frontend);
        uint protocolBal = tokenA.balanceOf(protocol_addr);

        _assert(frontendBal > 0, "FAIL: frontend received nothing");
        _assert(protocolBal > 0, "FAIL: protocol received nothing");
        _assert(ufr.received(address(tokenA)) > 0, "FAIL: UFR received nothing");

        emit log_uint("Frontend received", frontendBal);
        emit log_uint("Protocol received", protocolBal);
        emit log_uint("Total fee routed",  frontendBal + protocolBal);

        require(_passCount == _testCount, "Some tests failed");
    }

    function test_noFeeRouter_swapWorks() public {
        setUp();
        pair.setFeeRouter(address(0));

        uint amountIn = 100e18;
        tokenA.mint(address(pair), amountIn);

        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint rIn  = uint(r0);
        uint rOut = uint(r1);
        uint amountOut = (amountIn * 997 * rOut) / (rIn * 1000 + amountIn * 997);

        pair.swap(0, amountOut, trader, "");

        _assert(tokenA.balanceOf(frontend) == 0, "FAIL: fee routed without router");
        _assert(tokenA.balanceOf(protocol_addr) == 0, "FAIL: fee routed without router");
        require(_passCount == _testCount, "Some tests failed");
    }

    function test_7030_split_exact() public {
        setUp();

        uint amountIn = 1000e18;
        tokenA.mint(address(pair), amountIn);

        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint amountOut = (amountIn * 997 * uint(r1)) / (uint(r0) * 1000 + amountIn * 997);

        pair.swap(0, amountOut, trader, "");

        uint frontendBal = tokenA.balanceOf(frontend);
        uint protocolBal = tokenA.balanceOf(protocol_addr);
        uint total = frontendBal + protocolBal;

        // Verify 70/30 split
        // frontend = total * 70 / 100
        // tolerance: integer division may be off by 1
        uint expectedFrontend = total * 70 / 100;
        _assert(frontendBal == expectedFrontend, "FAIL: 70/30 split incorrect");
        _assert(protocolBal == total - expectedFrontend, "FAIL: remainder not to protocol");

        emit log_uint("Swap amount in",    amountIn);
        emit log_uint("Fee 0.3% total",    total);
        emit log_uint("Frontend 70%",      frontendBal);
        emit log_uint("Protocol 30%",      protocolBal);

        require(_passCount == _testCount, "Some tests failed");
    }

}