// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title NightWatchSkin
/// @notice Stateless SVG identity overlay for NIGHT WATCHERS. No surrounding SVG/card is included.
/// @dev No storage, privileged callers, external dependencies, receive function or fallback.
contract NightWatchSkin {
    error InvalidTier();
    error InvalidNumber();

    /// @notice Render an identity layer using only the supplied values.
    /// @param n Card number, 0 through 9999 inclusive, displayed with four decimal digits.
    /// @param t Tier, 1 through 6 inclusive; tier 6 is THE CAPTAIN.
    /// @param inputs Ten identifiers, reused cyclically for bars and code rows.
    /// @return The exact SVG fragment, without a wrapper, extra whitespace or a newline.
    function layer(uint256 n, uint8 t, uint16[10] calldata inputs) external pure returns (string memory) {
        if (t < 1 || t > 6) revert InvalidTier();
        if (n > 9999) revert InvalidNumber();

        // Build each bounded group separately to avoid repeatedly copying the entire layer.
        string memory bars;
        for (uint256 k; k < 16; ++k) {
            bars = string.concat(bars, _bar(k, inputs[k % 10]));
        }

        string memory orbits;
        if (t >= 2) orbits = _orbit("-12", "0;1", 16 - 2 * uint256(t));
        if (t >= 5) orbits = string.concat(orbits, _orbit("14", "1;0", 16 - 2 * uint256(t)));
        if (t == 6) orbits = string.concat(orbits, _orbit("38", "0;1", 6));

        string memory codes;
        if (t >= 3) {
            for (uint256 k; k < 6; ++k) {
                codes = string.concat(codes, _code(k, inputs));
            }
        }

        string memory stars;
        for (uint256 k; k < 8; ++k) {
            stars = string.concat(stars, _star(n, k));
        }

        return string.concat(
            _defs(_colour(t)),
            '<rect width="1000" height="1000" fill="url(#nwS)"><animateTransform attributeName="transform" type="translate" values="0 0;0 6" dur="1s" repeatCount="indefinite"/></rect>',
            t >= 2 ? _beam(9 - uint256(t)) : "",
            bars,
            _identity(n, t),
            orbits,
            codes,
            stars,
            t >= 4 ? _edge(12 - uint256(t)) : ""
        );
    }

    function _colour(uint8 t) private pure returns (string memory) {
        if (t == 1) return "#3FE6FF";
        if (t == 2) return "#B8FF4A";
        if (t == 3) return "#A98BFF";
        if (t == 4) return "#FF4FD8";
        if (t == 5) return "#FFC46B";
        return "#E9E4FF";
    }

    function _defs(string memory c) private pure returns (string memory) {
        return string.concat(
            '<defs><pattern id="nwS" width="8" height="6" patternUnits="userSpaceOnUse"><path d="M0 .5H8" stroke="#E2E8F0" stroke-opacity=".08"/></pattern><linearGradient id="nwB" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="',
            c,
            '" stop-opacity="0"/><stop offset="1" stop-color="',
            c,
            '" stop-opacity=".28"/></linearGradient><linearGradient id="nwE" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="',
            c,
            '"/><stop offset=".55" stop-color="#A3E635"/><stop offset="1" stop-color="#8B5CF6"/></linearGradient></defs>'
        );
    }

    function _beam(uint256 duration) private pure returns (string memory) {
        return string.concat(
            '<rect x="24" y="-80" width="952" height="80" fill="url(#nwB)"><animate attributeName="y" values="-80;976" dur="',
            _decimal(duration),
            's" repeatCount="indefinite"/></rect>'
        );
    }

    function _bar(uint256 k, uint256 identifier) private pure returns (string memory) {
        // Promote inputs to uint256 before multiplication; all uint16 values are valid.
        uint256 h = 8 + (identifier * (k + 7)) % 41;
        return string.concat(
            '<rect x="',
            _decimal(588 + 14 * k),
            '" y="',
            _decimal(142 - h),
            '" width="6" height="',
            _decimal(h),
            '" fill="currentColor" opacity=".55"><animate attributeName="opacity" values=".55;1;.25;.55" dur="',
            _decimal(2 + k % 4),
            's" begin="',
            _decimal(125 * k),
            'ms" repeatCount="indefinite"/></rect>'
        );
    }

    function _identity(uint256 n, uint8 t) private pure returns (string memory) {
        bytes memory number = new bytes(4);
        for (uint256 i; i < 4; ++i) {
            // The remainder is 0..9, so the ASCII value is 48..57 and fits uint8.
            // forge-lint: disable-next-line(unsafe-typecast)
            number[3 - i] = bytes1(uint8(48 + n % 10));
            n /= 10;
        }
        return string.concat(
            '<rect x="66" y="188" width="8" height="12" fill="currentColor"><animate attributeName="opacity" values="1;0;1" dur="1s" repeatCount="indefinite"/></rect><text x="82" y="199" font-size="12" font-family="monospace" fill="#C4B4FF" letter-spacing="3">ID / #',
            string(number),
            " / ",
            t == 6 ? "THE CAPTAIN" : "ON WATCH",
            "</text>"
        );
    }

    function _orbit(string memory rotation, string memory keyPoints, uint256 duration)
        private
        pure
        returns (string memory)
    {
        return string.concat(
            '<g transform="rotate(',
            rotation,
            ' 500 520)" opacity=".8"><ellipse cx="500" cy="520" rx="430" ry="96" fill="none" stroke="currentColor" stroke-width="2.5" stroke-dasharray="4 8"/><circle r="6" fill="#F2EFFF"><animateMotion dur="',
            _decimal(duration),
            's" repeatCount="indefinite" keyPoints="',
            keyPoints,
            '" keyTimes="0;1" calcMode="linear" path="M70 520a430 96 0 1 0 860 0a430 96 0 1 0 -860 0"/></circle></g>'
        );
    }

    function _code(uint256 k, uint16[10] calldata inputs) private pure returns (string memory) {
        return string.concat(
            '<text x="',
            k < 3 ? "40" : "930",
            '" y="',
            _decimal(300 + 18 * (k % 3)),
            '" font-size="11" font-family="monospace" fill="currentColor" text-anchor="',
            k < 3 ? "start" : "end",
            '" opacity=".5">',
            _hex(inputs[(3 * k) % 10]),
            ":",
            _hex(inputs[(3 * k + 1) % 10]),
            ":",
            _hex(inputs[(3 * k + 2) % 10]),
            '<animate attributeName="opacity" values=".2;.75;.2" dur="',
            _decimal(3 + k),
            's" repeatCount="indefinite"/></text>'
        );
    }

    function _star(uint256 n, uint256 k) private pure returns (string memory) {
        return string.concat(
            '<rect x="',
            _decimal((k % 2 == 0 ? 40 : 836) + (37 * n + 53 * k) % 120),
            '" y="',
            _decimal(230 + (61 * n + 97 * k) % 560),
            '" width="3" height="3" fill="#E2E8F0"><animate attributeName="opacity" values=".1;.8;.1" dur="',
            _decimal(2 + (n + k) % 3),
            's" repeatCount="indefinite"/></rect>'
        );
    }

    function _edge(uint256 duration) private pure returns (string memory) {
        return string.concat(
            '<path d="M60 24H940L976 60V940L940 976H60L24 940V60Z" fill="none" stroke="url(#nwE)" stroke-width="5" stroke-dasharray="60 30"><animate attributeName="stroke-dashoffset" values="0;-900" dur="',
            _decimal(duration),
            's" repeatCount="indefinite"/></path>'
        );
    }

    function _decimal(uint256 value) private pure returns (string memory) {
        uint256 digits = 1;
        for (uint256 remaining = value; remaining >= 10; remaining /= 10) {
            ++digits;
        }
        bytes memory result = new bytes(digits);
        do {
            // The remainder is 0..9, so the ASCII value is 48..57 and fits uint8.
            // forge-lint: disable-next-line(unsafe-typecast)
            result[--digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        } while (digits != 0);
        return string(result);
    }

    /// @dev Lowercase, no prefix, padded to at least three digits; preserves all uint16 bits.
    function _hex(uint16 value) private pure returns (string memory) {
        bytes16 alphabet = "0123456789abcdef";
        uint256 digits = value > 0xfff ? 4 : 3;
        bytes memory result = new bytes(digits);
        do {
            result[--digits] = alphabet[value & 0xf];
            value >>= 4;
        } while (digits != 0);
        return string(result);
    }
}
