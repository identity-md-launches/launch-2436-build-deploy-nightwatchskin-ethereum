// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {NightWatchSkin} from "../src/NightWatchSkin.sol";

/// @dev Drives the renderer with random callers, arguments and value-bearing calls. The skin holds
/// no value, so the invariants are that it never gains any, never changes, and that its accept/revert
/// decision and its output depend only on the arguments, whatever happened before.
contract SkinHandler is Test {
    NightWatchSkin public immutable skin;

    uint256 public validCalls;
    uint256 public invalidCalls;
    uint256 public validReverted;
    uint256 public invalidAccepted;
    uint256 public etherAccepted;
    uint256 public nondeterministic;

    constructor(NightWatchSkin skin_) {
        skin = skin_;
    }

    function renderValid(address caller, uint256 n, uint8 t, uint16[10] memory inputs) external {
        n = bound(n, 0, 9999);
        t = uint8(bound(t, 1, 6));
        bytes memory data = abi.encodeCall(NightWatchSkin.layer, (n, t, inputs));
        vm.prank(caller);
        (bool ok, bytes memory first) = address(skin).call(data);
        (bool again, bytes memory second) = address(skin).staticcall(data);
        ++validCalls;
        if (!ok || !again) ++validReverted;
        else if (keccak256(first) != keccak256(second)) ++nondeterministic;
    }

    function renderAny(address caller, uint256 n, uint8 t, uint16[10] memory inputs) external {
        bool inDomain = n <= 9999 && t >= 1 && t <= 6;
        vm.prank(caller);
        (bool ok,) = address(skin).call(abi.encodeCall(NightWatchSkin.layer, (n, t, inputs)));
        if (inDomain) {
            ++validCalls;
            if (!ok) ++validReverted;
        } else {
            ++invalidCalls;
            if (ok) ++invalidAccepted;
        }
    }

    function renderBadTier(uint256 n, uint8 t) external {
        n = bound(n, 0, 9999);
        t = t % 2 == 0 ? 0 : uint8(bound(t, 7, 255));
        uint16[10] memory inputs;
        (bool ok,) = address(skin).staticcall(abi.encodeCall(NightWatchSkin.layer, (n, t, inputs)));
        ++invalidCalls;
        if (ok) ++invalidAccepted;
    }

    function renderBadNumber(uint256 n, uint8 t) external {
        n = bound(n, 10_000, type(uint256).max);
        t = uint8(bound(t, 1, 6));
        uint16[10] memory inputs;
        (bool ok,) = address(skin).staticcall(abi.encodeCall(NightWatchSkin.layer, (n, t, inputs)));
        ++invalidCalls;
        if (ok) ++invalidAccepted;
    }

    function sendEther(uint256 amount, bytes calldata data) external {
        amount = bound(amount, 1, 100 ether);
        vm.deal(address(this), amount);
        (bool ok,) = address(skin).call{value: amount}(data);
        if (ok) ++etherAccepted;
    }

    function sendEtherWithLayer(uint256 amount, uint256 n, uint8 t) external {
        amount = bound(amount, 1, 100 ether);
        n = bound(n, 0, 9999);
        t = uint8(bound(t, 1, 6));
        uint16[10] memory inputs;
        vm.deal(address(this), amount);
        (bool ok,) = address(skin).call{value: amount}(abi.encodeCall(NightWatchSkin.layer, (n, t, inputs)));
        if (ok) ++etherAccepted;
    }

    function callUnknown(bytes4 selector, bytes calldata rest) external {
        if (selector == NightWatchSkin.layer.selector) return;
        (bool ok,) = address(skin).call(abi.encodePacked(selector, rest));
        if (ok) ++invalidAccepted;
    }
}

contract NightWatchSkinInvariantTest is Test {
    NightWatchSkin private skin;
    SkinHandler private handler;
    bytes32 private runtimeHash;
    bytes32 private captainHash;

    function setUp() public {
        skin = new NightWatchSkin();
        handler = new SkinHandler(skin);
        runtimeHash = address(skin).codehash;
        uint16[10] memory inputs = [uint16(1), 45, 103, 12, 19, 22, 69, 188, 204, 267];
        captainHash = keccak256(bytes(skin.layer(0, 6, inputs)));
        assertEq(captainHash, 0xeecaf052aaad318dfead6dc6ca66725156009b16cd331563b85b5cc64b060b53);
        targetContract(address(handler));
    }

    /// forge-config: default.invariant.runs = 64
    /// forge-config: default.invariant.depth = 32
    function invariant_holdsNoValue() public view {
        assertEq(address(skin).balance, 0);
        assertEq(handler.etherAccepted(), 0);
    }

    /// forge-config: default.invariant.runs = 64
    /// forge-config: default.invariant.depth = 32
    function invariant_codeNeverChanges() public view {
        assertEq(address(skin).codehash, runtimeHash);
    }

    /// forge-config: default.invariant.runs = 64
    /// forge-config: default.invariant.depth = 32
    function invariant_domainDecidesAcceptance() public view {
        assertEq(handler.validReverted(), 0, "valid call reverted");
        assertEq(handler.invalidAccepted(), 0, "invalid call accepted");
    }

    /// forge-config: default.invariant.runs = 64
    /// forge-config: default.invariant.depth = 32
    function invariant_outputIsHistoryIndependent() public view {
        assertEq(handler.nondeterministic(), 0);
        uint16[10] memory inputs = [uint16(1), 45, 103, 12, 19, 22, 69, 188, 204, 267];
        assertEq(keccak256(bytes(skin.layer(0, 6, inputs))), captainHash);
    }
}
