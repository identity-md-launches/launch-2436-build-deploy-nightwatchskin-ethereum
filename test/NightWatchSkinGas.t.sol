// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {NightWatchSkin} from "../src/NightWatchSkin.sol";

/// @dev Report one cold external STATICCALL per tier, with maximum-width identifiers and ID.
contract NightWatchSkinGasTest is Test {
    NightWatchSkin private skin;

    function setUp() public {
        skin = new NightWatchSkin();
    }

    function test_gasTierOne() public {
        _measure(1);
    }

    function test_gasTierTwo() public {
        _measure(2);
    }

    function test_gasTierThree() public {
        _measure(3);
    }

    function test_gasTierFour() public {
        _measure(4);
    }

    function test_gasTierFive() public {
        _measure(5);
    }

    function test_gasTierSix() public {
        _measure(6);
    }

    function _measure(uint8 t) private {
        uint16[10] memory inputs;
        for (uint256 i; i < 10; ++i) {
            inputs[i] = type(uint16).max;
        }
        vm.cool(address(skin));
        // Encoding is outside the measured region; returndata copying/decoding is inside.
        bytes memory data = abi.encodeCall(NightWatchSkin.layer, (9999, t, inputs));
        uint256 before = gasleft();
        (bool success, bytes memory result) = address(skin).staticcall(data);
        string memory svg = abi.decode(result, (string));
        uint256 used = before - gasleft();
        assertTrue(success);
        emit log_named_uint(string.concat("tier ", vm.toString(t), " cold staticcall gas"), used);
        emit log_named_uint("SVG bytes", bytes(svg).length);
        // Prevent an accidental unbounded/very expensive renderer regression.
        assertLt(used, 1_000_000);
    }
}
