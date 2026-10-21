// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {NightWatchSkin} from "../src/NightWatchSkin.sol";
import {ReferenceVectors} from "./fixtures/ReferenceVectors.sol";

/// @dev Rehearse factory deployment without a signer, external contracts or configuration.
contract SkinDeploymentProbe {
    function deploy(bytes32 salt) external returns (NightWatchSkin) {
        return new NightWatchSkin{salt: salt}();
    }
}

contract NightWatchSkinTest is Test {
    NightWatchSkin private skin;

    function setUp() public {
        skin = new NightWatchSkin();
    }

    function test_vectorTierOne() public view {
        uint16[10] memory inputs = [uint16(184), 185, 186, 189, 190, 78, 80, 81, 82, 86];
        assertEq(
            keccak256(bytes(skin.layer(1, 1, inputs))),
            0x2a93428c834d0f406f41844fbd93691276402298a395e0462c27cf41a6634e4c
        );
    }

    function test_vectorTierThree() public view {
        uint16[10] memory inputs = [uint16(26), 30, 50, 2, 5, 96, 97, 93, 94, 87];
        assertEq(
            keccak256(bytes(skin.layer(7, 3, inputs))),
            0xaaf9e3a1dd4ce02bdfe8a864f16037c4c574974d1fe5e852b78ac8c6ba0477e0
        );
    }

    function test_vectorTierFive() public view {
        uint16[10] memory inputs = [uint16(10), 45, 103, 12, 19, 22, 69, 188, 204, 267];
        assertEq(
            keccak256(bytes(skin.layer(50, 5, inputs))),
            0xb2e57d5de55080f34fe0d6818af8d64f27b6850b3c2bd9fe18ad19682b55fb8f
        );
    }

    function test_vectorCaptainZero() public view {
        uint16[10] memory inputs = [uint16(1), 45, 103, 12, 19, 22, 69, 188, 204, 267];
        assertEq(
            keccak256(bytes(skin.layer(0, 6, inputs))),
            0xeecaf052aaad318dfead6dc6ca66725156009b16cd331563b85b5cc64b060b53
        );
    }

    function test_independentReferenceCorpus() public view {
        for (uint256 i; i < ReferenceVectors.COUNT; ++i) {
            (uint256 n, uint8 t, uint16[10] memory inputs, bytes32 expected) = ReferenceVectors.get(i);
            assertEq(keccak256(bytes(skin.layer(n, t, inputs))), expected, vm.toString(i));
        }
    }

    function test_revertTierZero() public {
        uint16[10] memory inputs;
        vm.expectRevert(NightWatchSkin.InvalidTier.selector);
        skin.layer(1, 0, inputs);
    }

    function test_revertTierSeven() public {
        uint16[10] memory inputs;
        vm.expectRevert(NightWatchSkin.InvalidTier.selector);
        skin.layer(1, 7, inputs);
    }

    function test_revertNumberTenThousand() public {
        uint16[10] memory inputs;
        vm.expectRevert(NightWatchSkin.InvalidNumber.selector);
        skin.layer(10_000, 6, inputs);
    }

    function testFuzz_revertAllOutOfRangeNumbers(uint256 n, uint8 t, uint16[10] memory inputs) public {
        n = bound(n, 10_000, type(uint256).max);
        t = uint8(bound(t, 1, 6));
        vm.expectRevert(NightWatchSkin.InvalidNumber.selector);
        skin.layer(n, t, inputs);
    }

    function testFuzz_revertAllHighTiers(uint8 t, uint16[10] memory inputs) public {
        t = uint8(bound(t, 7, 255));
        vm.expectRevert(NightWatchSkin.InvalidTier.selector);
        skin.layer(9999, t, inputs);
    }

    function testFuzz_anyoneCanRenderDeterministically(uint256 n, uint8 t, uint16[10] memory inputs, address caller)
        public
    {
        n = bound(n, 0, 9999);
        t = uint8(bound(t, 1, 6));
        string memory expected = skin.layer(n, t, inputs);
        vm.warp(2_000_000_000);
        vm.roll(30_000_000);
        vm.chainId(1);
        vm.prank(caller);
        assertEq(skin.layer(n, t, inputs), expected);
    }

    function testFuzz_barPeriodAndCodeSensitivity(uint256 n, uint16[10] memory inputs, uint8 slot) public view {
        n %= 10_000;
        slot %= 10;
        // Changing one input by 41 preserves bar heights, but must change the code rows.
        inputs[slot] %= 65_495;
        bytes32 barsBefore = keccak256(bytes(skin.layer(n, 1, inputs)));
        bytes32 codesBefore = keccak256(bytes(skin.layer(n, 3, inputs)));
        inputs[slot] += 41;
        assertEq(keccak256(bytes(skin.layer(n, 1, inputs))), barsBefore);
        assertNotEq(keccak256(bytes(skin.layer(n, 3, inputs))), codesBefore);
    }

    function test_noStorageReadsOrWrites() public {
        uint16[10] memory inputs;
        vm.record();
        skin.layer(9999, 6, inputs);
        (bytes32[] memory reads, bytes32[] memory writes) = vm.accesses(address(skin));
        assertEq(reads.length, 0);
        assertEq(writes.length, 0);
    }

    function test_staticCallSucceeds() public view {
        uint16[10] memory inputs;
        (bool success, bytes memory result) =
            address(skin).staticcall(abi.encodeCall(NightWatchSkin.layer, (0, 6, inputs)));
        assertTrue(success);
        assertEq(abi.decode(result, (string)), skin.layer(0, 6, inputs));
    }

    function test_rejectsEtherWithOrWithoutLayerCalldata() public {
        uint16[10] memory inputs;
        vm.deal(address(this), 2 wei);
        (bool emptyAccepted,) = address(skin).call{value: 1 wei}("");
        (bool layerAccepted,) = address(skin).call{value: 1 wei}(abi.encodeCall(NightWatchSkin.layer, (0, 6, inputs)));
        assertFalse(emptyAccepted);
        assertFalse(layerAccepted);
        assertEq(address(skin).balance, 0);
        assertEq(address(this).balance, 2 wei);
    }

    function test_rejectsEmptyAndUnknownCalldata() public view {
        (bool emptyAccepted,) = address(skin).staticcall("");
        (bool unknownAccepted,) = address(skin).staticcall(hex"ffffffff");
        assertFalse(emptyAccepted);
        assertFalse(unknownAccepted);
    }

    function test_forcedBalanceDoesNotAffectRenderingOrEnableCalls() public {
        uint16[10] memory inputs;
        string memory expected = skin.layer(0, 6, inputs);
        // The EVM can force balances onto contracts even without a payable entry point.
        vm.deal(address(skin), 1 ether);
        assertEq(skin.layer(0, 6, inputs), expected);
        (bool withdrawal,) = address(skin).call(abi.encodeWithSignature("withdraw()"));
        assertFalse(withdrawal);
        assertEq(address(skin).balance, 1 ether);
    }

    function test_rejectsTruncatedAndNonCanonicalAbi() public view {
        uint16[10] memory inputs;
        bytes memory args = abi.encodeCall(NightWatchSkin.layer, (0, 6, inputs));
        // A uint8 tier word with a high bit set is not a valid ABI encoding.
        args[36] = 0x01;
        (bool dirtyTier,) = address(skin).staticcall(args);
        assertFalse(dirtyTier);
        args = abi.encodeCall(NightWatchSkin.layer, (0, 6, inputs));
        // Likewise, each identifier must fit uint16, not just its low two bytes.
        args[68] = 0x01;
        (bool dirtyInput,) = address(skin).staticcall(args);
        assertFalse(dirtyInput);
        (bool truncated,) = address(skin).staticcall(abi.encodePacked(NightWatchSkin.layer.selector));
        assertFalse(truncated);
    }

    function test_factoryDeploymentHasNoConfigurationOrPrivileges() public {
        SkinDeploymentProbe factory = new SkinDeploymentProbe();
        bytes32 salt = keccak256("NightWatchSkin factory rehearsal");
        address expected = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(hex"ff", address(factory), salt, keccak256(type(NightWatchSkin).creationCode))
                    )
                )
            )
        );
        NightWatchSkin deployed = factory.deploy(salt);
        assertEq(address(deployed), expected);
        assertEq(address(deployed).code, address(skin).code);
        uint16[10] memory inputs;
        assertEq(deployed.layer(0, 6, inputs), skin.layer(0, 6, inputs));
        assertEq(address(deployed).balance, 0);
    }

    function test_runtimeFitsEthereumAndHasNoForbiddenInstructions() public view {
        bytes memory code = address(skin).code;
        assertGt(code.length, 0);
        assertLe(code.length, 24_576);
        // Match the protected launch floor's reachable-code treatment of trailing literal data.
        bool reachable = true;
        for (uint256 i; i < code.length; ++i) {
            uint8 op = uint8(code[i]);
            if (op == 0x5b) reachable = true;
            if (op >= 0x60 && op <= 0x7f) {
                i += op - 0x5f;
                continue;
            }
            if (reachable) {
                assertTrue(op != 0xf4 && op != 0xf2 && op != 0xff);
                assertTrue(op != 0x54 && op != 0x55 && op != 0x5c && op != 0x5d, "storage instruction");
                assertTrue(op != 0xf0 && op != 0xf1 && op != 0xf5 && op != 0xfa, "external call or creation");
            }
            if (op == 0x00 || op == 0x56 || op == 0xf3 || op == 0xfd || op == 0xfe || op == 0xff) reachable = false;
        }
    }
}
