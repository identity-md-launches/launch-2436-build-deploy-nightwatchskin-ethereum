// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {NightWatchSkin} from "../src/NightWatchSkin.sol";

/// @dev A second rendering of the brief, written part by part from its text (not from the contract),
/// with decimals from forge's own `vm.toString`. Used as a differential oracle over fuzzed inputs.
/// CODE rows are rendered with exactly three hex digits, so it is only an oracle for identifiers
/// <= 0xfff; the brief does not say how wider uint16 identifiers are written (see .imd-findings.json).
contract BriefOracle is Test {
    function render(uint256 n, uint8 t, uint16[10] memory inputs) external pure returns (string memory out) {
        string memory c = ["#3FE6FF", "#B8FF4A", "#A98BFF", "#FF4FD8", "#FFC46B", "#E9E4FF"][t - 1];
        out = string.concat(
            '<defs><pattern id="nwS" width="8" height="6" patternUnits="userSpaceOnUse"><path d="M0 .5H8" stroke="#E2E8F0" stroke-opacity=".08"/></pattern><linearGradient id="nwB" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="',
            c,
            '" stop-opacity="0"/><stop offset="1" stop-color="',
            c,
            '" stop-opacity=".28"/></linearGradient><linearGradient id="nwE" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="',
            c,
            '"/><stop offset=".55" stop-color="#A3E635"/><stop offset="1" stop-color="#8B5CF6"/></linearGradient></defs>',
            '<rect width="1000" height="1000" fill="url(#nwS)"><animateTransform attributeName="transform" type="translate" values="0 0;0 6" dur="1s" repeatCount="indefinite"/></rect>'
        );
        if (t >= 2) {
            out = string.concat(
                out,
                '<rect x="24" y="-80" width="952" height="80" fill="url(#nwB)"><animate attributeName="y" values="-80;976" dur="',
                vm.toString(uint256(9 - t)),
                's" repeatCount="indefinite"/></rect>'
            );
        }
        for (uint256 k; k < 16; ++k) {
            uint256 h = 8 + (uint256(inputs[k % 10]) * (k + 7)) % 41;
            out = string.concat(
                out,
                string.concat('<rect x="', vm.toString(588 + 14 * k), '" y="', vm.toString(142 - h)),
                string.concat('" width="6" height="', vm.toString(h), '" fill="currentColor" opacity=".55">'),
                string.concat(
                    '<animate attributeName="opacity" values=".55;1;.25;.55" dur="',
                    vm.toString(2 + (k % 4)),
                    's" begin="',
                    vm.toString(125 * k),
                    'ms" repeatCount="indefinite"/></rect>'
                )
            );
        }
        string memory padded = vm.toString(n);
        while (bytes(padded).length < 4) {
            padded = string.concat("0", padded);
        }
        out = string.concat(
            out,
            '<rect x="66" y="188" width="8" height="12" fill="currentColor"><animate attributeName="opacity" values="1;0;1" dur="1s" repeatCount="indefinite"/></rect><text x="82" y="199" font-size="12" font-family="monospace" fill="#C4B4FF" letter-spacing="3">ID / #',
            padded,
            " / ",
            t == 6 ? "THE CAPTAIN" : "ON WATCH",
            "</text>"
        );
        if (t >= 2) out = string.concat(out, _orbit("-12", "0;1", 16 - 2 * uint256(t)));
        if (t >= 5) out = string.concat(out, _orbit("14", "1;0", 16 - 2 * uint256(t)));
        if (t == 6) out = string.concat(out, _orbit("38", "0;1", 6));
        if (t >= 3) {
            for (uint256 k; k < 6; ++k) {
                string memory row = string.concat(
                    _hex3(inputs[(3 * k) % 10]),
                    ":",
                    _hex3(inputs[(3 * k + 1) % 10]),
                    ":",
                    _hex3(inputs[(3 * k + 2) % 10])
                );
                out = string.concat(
                    out,
                    string.concat('<text x="', k < 3 ? "40" : "930", '" y="', vm.toString(300 + 18 * (k % 3))),
                    string.concat(
                        '" font-size="11" font-family="monospace" fill="currentColor" text-anchor="',
                        k < 3 ? "start" : "end",
                        '" opacity=".5">',
                        row
                    ),
                    string.concat(
                        '<animate attributeName="opacity" values=".2;.75;.2" dur="',
                        vm.toString(3 + k),
                        's" repeatCount="indefinite"/></text>'
                    )
                );
            }
        }
        for (uint256 k; k < 8; ++k) {
            uint256 x = (k % 2 == 0 ? 40 : 836) + (37 * n + 53 * k) % 120;
            out = string.concat(
                out,
                string.concat('<rect x="', vm.toString(x), '" y="', vm.toString(230 + (61 * n + 97 * k) % 560)),
                '" width="3" height="3" fill="#E2E8F0"><animate attributeName="opacity" values=".1;.8;.1" dur="',
                vm.toString(2 + (n + k) % 3),
                's" repeatCount="indefinite"/></rect>'
            );
        }
        if (t >= 4) {
            out = string.concat(
                out,
                '<path d="M60 24H940L976 60V940L940 976H60L24 940V60Z" fill="none" stroke="url(#nwE)" stroke-width="5" stroke-dasharray="60 30"><animate attributeName="stroke-dashoffset" values="0;-900" dur="',
                vm.toString(uint256(12 - t)),
                's" repeatCount="indefinite"/></path>'
            );
        }
    }

    function _orbit(string memory r, string memory keys, uint256 d) private pure returns (string memory) {
        return string.concat(
            '<g transform="rotate(',
            r,
            ' 500 520)" opacity=".8"><ellipse cx="500" cy="520" rx="430" ry="96" fill="none" stroke="currentColor" stroke-width="2.5" stroke-dasharray="4 8"/><circle r="6" fill="#F2EFFF"><animateMotion dur="',
            vm.toString(d),
            's" repeatCount="indefinite" keyPoints="',
            keys,
            '" keyTimes="0;1" calcMode="linear" path="M70 520a430 96 0 1 0 860 0a430 96 0 1 0 -860 0"/></circle></g>'
        );
    }

    function _hex3(uint16 v) private pure returns (string memory) {
        require(v <= 0xfff, "oracle: identifier wider than three hex digits");
        bytes memory digits = "0123456789abcdef";
        bytes memory out = new bytes(3);
        out[0] = digits[(v >> 8) & 0xf];
        out[1] = digits[(v >> 4) & 0xf];
        out[2] = digits[v & 0xf];
        return string(out);
    }
}

contract NightWatchSkinSpecTest is Test {
    NightWatchSkin private skin;
    BriefOracle private oracle;
    string private constant _orbitBody =
        '" opacity=".8"><ellipse cx="500" cy="520" rx="430" ry="96" fill="none" stroke="currentColor" stroke-width="2.5" stroke-dasharray="4 8"/><circle r="6" fill="#F2EFFF">';

    function setUp() public {
        skin = new NightWatchSkin();
        oracle = new BriefOracle();
    }

    // ---------------------------------------------------------------- oracle self-check

    /// The oracle is only trusted because it reproduces all four requester-supplied hashes.
    function test_oracleReproducesSuppliedVectors() public view {
        assertEq(
            keccak256(bytes(oracle.render(1, 1, [uint16(184), 185, 186, 189, 190, 78, 80, 81, 82, 86]))),
            0x2a93428c834d0f406f41844fbd93691276402298a395e0462c27cf41a6634e4c
        );
        assertEq(
            keccak256(bytes(oracle.render(7, 3, [uint16(26), 30, 50, 2, 5, 96, 97, 93, 94, 87]))),
            0xaaf9e3a1dd4ce02bdfe8a864f16037c4c574974d1fe5e852b78ac8c6ba0477e0
        );
        assertEq(
            keccak256(bytes(oracle.render(50, 5, [uint16(10), 45, 103, 12, 19, 22, 69, 188, 204, 267]))),
            0xb2e57d5de55080f34fe0d6818af8d64f27b6850b3c2bd9fe18ad19682b55fb8f
        );
        assertEq(
            keccak256(bytes(oracle.render(0, 6, [uint16(1), 45, 103, 12, 19, 22, 69, 188, 204, 267]))),
            0xeecaf052aaad318dfead6dc6ca66725156009b16cd331563b85b5cc64b060b53
        );
    }

    // ---------------------------------------------------------------- differential fuzzing

    /// forge-config: default.fuzz.runs = 512
    function testFuzz_matchesBriefForThreeDigitIdentifiers(uint256 n, uint8 t, uint16[10] memory inputs) public view {
        n = bound(n, 0, 9999);
        t = uint8(bound(t, 1, 6));
        for (uint256 i; i < 10; ++i) {
            inputs[i] = uint16(bound(inputs[i], 0, 0xfff));
        }
        assertEq(skin.layer(n, t, inputs), oracle.render(n, t, inputs));
    }

    /// Tiers 1 and 2 draw no CODE rows, so the brief fixes their output for every uint16 identifier.
    /// forge-config: default.fuzz.runs = 512
    function testFuzz_matchesBriefForFullWidthIdentifiersWithoutCodeRows(
        uint256 n,
        bool tierTwo,
        uint16[10] memory inputs
    ) public view {
        n = bound(n, 0, 9999);
        uint8 t = tierTwo ? 2 : 1;
        assertEq(skin.layer(n, t, inputs), oracle.render(n, t, inputs));
    }

    // ---------------------------------------------------------------- pinned edges

    function test_matchesBriefAtEdges() public view {
        uint16[10] memory zero;
        uint16[10] memory top;
        uint16[10] memory mixed = [uint16(0), 1, 15, 16, 255, 256, 4094, 4095, 40, 41];
        for (uint256 i; i < 10; ++i) {
            top[i] = 0xfff;
        }
        uint256[8] memory ns = [uint256(0), 1, 9, 10, 99, 100, 999, 9999];
        for (uint8 t = 1; t <= 6; ++t) {
            for (uint256 j; j < ns.length; ++j) {
                assertEq(skin.layer(ns[j], t, zero), oracle.render(ns[j], t, zero));
                assertEq(skin.layer(ns[j], t, top), oracle.render(ns[j], t, top));
                assertEq(skin.layer(ns[j], t, mixed), oracle.render(ns[j], t, mixed));
            }
        }
    }

    /// Spec D values: BEAM 9 - t, ORBIT 16 - 2t (Captain's third orbit 6), EDGE 12 - t.
    function test_tierDurationsAndColours() public view {
        uint16[10] memory inputs;
        string[6] memory colours = ["#3FE6FF", "#B8FF4A", "#A98BFF", "#FF4FD8", "#FFC46B", "#E9E4FF"];
        for (uint8 t = 1; t <= 6; ++t) {
            string memory svg = skin.layer(42, t, inputs);
            assertEq(_count(svg, colours[t - 1]), 3, "colour used by the three gradient stops");
            for (uint256 other; other < 6; ++other) {
                if (other != t - 1) assertEq(_count(svg, colours[other]), 0, "foreign tier colour");
            }
            string memory beam = string.concat('values="-80;976" dur="', vm.toString(uint256(9 - t)), 's"');
            assertEq(_count(svg, beam), t >= 2 ? 1 : 0, "beam");
            string memory orbit = string.concat('<animateMotion dur="', vm.toString(16 - 2 * uint256(t)), 's"');
            assertEq(_count(svg, orbit), t >= 5 ? 2 : (t >= 2 ? 1 : 0), "orbit duration");
            assertEq(
                _count(svg, string.concat("<g transform=\"rotate(38 500 520)", _orbitBody, '<animateMotion dur="6s"')),
                t == 6 ? 1 : 0,
                "captain orbit"
            );
            string memory edge = string.concat('values="0;-900" dur="', vm.toString(uint256(12 - t)), 's"');
            assertEq(_count(svg, edge), t >= 4 ? 1 : 0, "edge");
        }
    }

    /// Element counts and the order of optional parts, tier by tier.
    /// forge-config: default.fuzz.runs = 128
    function testFuzz_structureByTier(uint256 n, uint8 t, uint16[10] memory inputs) public view {
        n = bound(n, 0, 9999);
        t = uint8(bound(t, 1, 6));
        string memory svg = skin.layer(n, t, inputs);
        bytes memory b = bytes(svg);

        assertTrue(_startsWith(svg, "<defs><pattern"), "DEFS first");
        assertTrue(_endsWith(svg, t >= 4 ? "</path>" : 's" repeatCount="indefinite"/></rect>'), "STAR or EDGE last");
        for (uint256 i; i < b.length; ++i) {
            assertTrue(b[i] != 0x0a && b[i] != 0x0d && b[i] != 0x09, "no newlines or tabs");
            if (i > 0) assertFalse(b[i] == 0x20 && b[i - 1] == 0x20, "no doubled spaces");
        }
        assertEq(_count(svg, "<defs>"), 1);
        assertEq(_count(svg, 'fill="currentColor" opacity=".55"'), 16, "bars");
        assertEq(_count(svg, 'width="3" height="3"'), 8, "stars");
        assertEq(_count(svg, "<g transform="), t == 6 ? 3 : (t == 5 ? 2 : (t >= 2 ? 1 : 0)), "orbits");
        assertEq(_count(svg, 'text-anchor="start"'), t >= 3 ? 3 : 0, "left code rows");
        assertEq(_count(svg, 'text-anchor="end"'), t >= 3 ? 3 : 0, "right code rows");
        assertEq(_count(svg, "THE CAPTAIN"), t == 6 ? 1 : 0);
        assertEq(_count(svg, "ON WATCH"), t == 6 ? 0 : 1);
        assertEq(_count(svg, "url(#nwB)"), t >= 2 ? 1 : 0, "beam");
        assertEq(_count(svg, "url(#nwE)"), t >= 4 ? 1 : 0, "edge");

        // Brief order: ... BAR(15) ID [ORBIT...] [CODE...] STAR(0)
        uint256 lastBar = _lastIndexOf(svg, 'fill="currentColor" opacity=".55"');
        uint256 id = _indexOf(svg, "ID / #");
        uint256 firstStar = _indexOf(svg, 'width="3" height="3"');
        assertLt(lastBar, id);
        assertLt(id, firstStar);
        if (t >= 2) assertLt(_indexOf(svg, "url(#nwB)"), _indexOf(svg, 'opacity=".55"'));
        if (t >= 3) {
            assertLt(_lastIndexOf(svg, "<g transform="), _indexOf(svg, "text-anchor"));
            assertLt(_lastIndexOf(svg, "text-anchor"), firstStar);
        }
        if (t >= 4) assertLt(_lastIndexOf(svg, 'width="3" height="3"'), _indexOf(svg, "url(#nwE)"));
    }

    /// The four-digit ID for every n in a decade block, and every boundary digit width.
    function testFuzz_idIsFourDigitDecimal(uint256 n, uint8 t) public view {
        n = bound(n, 0, 9999);
        t = uint8(bound(t, 1, 6));
        uint16[10] memory inputs;
        string memory digits = vm.toString(n);
        while (bytes(digits).length < 4) {
            digits = string.concat("0", digits);
        }
        string memory expected = string.concat("ID / #", digits, " / ", t == 6 ? "THE CAPTAIN" : "ON WATCH", "<");
        assertEq(_count(skin.layer(n, t, inputs), expected), 1);
    }

    /// Bar heights stay within 8..48 and y = 142 - H, for full-width identifiers.
    /// forge-config: default.fuzz.runs = 128
    function testFuzz_barHeightBounds(uint16[10] memory inputs, uint256 n) public view {
        n = bound(n, 0, 9999);
        string memory svg = skin.layer(n, 1, inputs);
        for (uint256 k; k < 16; ++k) {
            uint256 h = 8 + (uint256(inputs[k % 10]) * (k + 7)) % 41;
            assertGe(h, 8);
            assertLe(h, 48);
            string memory bar = string.concat(
                '<rect x="',
                vm.toString(588 + 14 * k),
                '" y="',
                vm.toString(142 - h),
                '" width="6" height="',
                vm.toString(h)
            );
            assertEq(_count(svg, bar), 1);
        }
    }

    // ---------------------------------------------------------------- failure paths

    function test_boundaryAcceptance() public view {
        uint16[10] memory inputs;
        assertGt(bytes(skin.layer(0, 1, inputs)).length, 0);
        assertGt(bytes(skin.layer(9999, 1, inputs)).length, 0);
        assertGt(bytes(skin.layer(0, 6, inputs)).length, 0);
        assertGt(bytes(skin.layer(9999, 6, inputs)).length, 0);
    }

    /// n = 0 is valid on every tier (it is the Captain's number and the supplied vector uses it).
    function test_numberZeroIsValidOnEveryTier() public view {
        uint16[10] memory inputs;
        for (uint8 t = 1; t <= 6; ++t) {
            assertEq(skin.layer(0, t, inputs), oracle.render(0, t, inputs));
        }
    }

    function test_revertTierZeroAtEveryValidNumberEdge() public {
        uint16[10] memory inputs;
        vm.expectRevert(NightWatchSkin.InvalidTier.selector);
        skin.layer(0, 0, inputs);
        vm.expectRevert(NightWatchSkin.InvalidTier.selector);
        skin.layer(9999, 0, inputs);
    }

    function test_revertTierAboveCaptain() public {
        uint16[10] memory inputs;
        vm.expectRevert(NightWatchSkin.InvalidTier.selector);
        skin.layer(0, 7, inputs);
        vm.expectRevert(NightWatchSkin.InvalidTier.selector);
        skin.layer(0, type(uint8).max, inputs);
    }

    function test_revertNumberJustAboveRangeOnEveryTier() public {
        uint16[10] memory inputs;
        for (uint8 t = 1; t <= 6; ++t) {
            vm.expectRevert(NightWatchSkin.InvalidNumber.selector);
            skin.layer(10_000, t, inputs);
            vm.expectRevert(NightWatchSkin.InvalidNumber.selector);
            skin.layer(type(uint256).max, t, inputs);
        }
    }

    /// Both arguments invalid: the call must still revert (no partial output).
    function testFuzz_bothInvalidReverts(uint256 n, uint8 t) public {
        n = bound(n, 10_000, type(uint256).max);
        t = t % 2 == 0 ? 0 : uint8(bound(t, 7, 255));
        uint16[10] memory inputs;
        (bool ok,) = address(skin).staticcall(abi.encodeCall(NightWatchSkin.layer, (n, t, inputs)));
        assertFalse(ok);
    }

    /// Exactly the valid domain renders; everything else reverts.
    /// forge-config: default.fuzz.runs = 1000
    function testFuzz_revertsIffOutOfDomain(uint256 n, uint8 t) public view {
        // Bias half the runs to the boundaries so both sides are exercised.
        if (n % 2 == 0) n = bound(n, 9990, 10_010);
        uint16[10] memory inputs;
        (bool ok,) = address(skin).staticcall(abi.encodeCall(NightWatchSkin.layer, (n, t, inputs)));
        assertEq(ok, n <= 9999 && t >= 1 && t <= 6);
    }

    // ---------------------------------------------------------------- helpers

    function _count(string memory hay, string memory needle) private pure returns (uint256 count) {
        bytes memory h = bytes(hay);
        bytes memory nd = bytes(needle);
        if (nd.length == 0 || nd.length > h.length) return 0;
        for (uint256 i; i + nd.length <= h.length; ++i) {
            if (_matchAt(h, nd, i)) ++count;
        }
    }

    function _indexOf(string memory hay, string memory needle) private pure returns (uint256) {
        bytes memory h = bytes(hay);
        bytes memory nd = bytes(needle);
        for (uint256 i; i + nd.length <= h.length; ++i) {
            if (_matchAt(h, nd, i)) return i;
        }
        revert("needle not found");
    }

    function _lastIndexOf(string memory hay, string memory needle) private pure returns (uint256) {
        bytes memory h = bytes(hay);
        bytes memory nd = bytes(needle);
        for (uint256 i = h.length - nd.length + 1; i > 0; --i) {
            if (_matchAt(h, nd, i - 1)) return i - 1;
        }
        revert("needle not found");
    }

    function _matchAt(bytes memory h, bytes memory nd, uint256 at) private pure returns (bool) {
        for (uint256 j; j < nd.length; ++j) {
            if (h[at + j] != nd[j]) return false;
        }
        return true;
    }

    function _startsWith(string memory s, string memory prefix) private pure returns (bool) {
        return bytes(s).length >= bytes(prefix).length && _matchAt(bytes(s), bytes(prefix), 0);
    }

    function _endsWith(string memory s, string memory suffix) private pure returns (bool) {
        return bytes(s).length >= bytes(suffix).length
            && _matchAt(bytes(s), bytes(suffix), bytes(s).length - bytes(suffix).length);
    }
}
