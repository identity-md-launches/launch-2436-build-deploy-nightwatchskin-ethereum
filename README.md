# NightWatchSkin

An immutable SVG identity overlay for the separately deployed NIGHT WATCHERS NFT collection on Ethereum (chain ID **1**). The sole application contract is [`src/NightWatchSkin.sol`](src/NightWatchSkin.sol).

```solidity
function layer(uint256 n, uint8 t, uint16[10] calldata inputs)
    external pure returns (string memory);
```

Anyone can call it. `pure` is a stronger restriction than the requested `view`: the output depends only on its arguments. The ABI selector is `0x0ec07bba`. There are no other public functions, constructor arguments, storage variables, owners, fees, tokens, upgrades, pause controls, external calls, or services. All helpers are private and included in the runtime; there are no linked libraries.

## Rendering and assumptions

- Valid inputs: `0 <= n <= 9999`, `1 <= t <= 6`, and ten full-range `uint16` identifiers. Invalid numbers revert with `InvalidNumber()`; invalid tiers revert with `InvalidTier()`. The ABI decoder also rejects malformed integers or truncated arguments.
- `n` is displayed in exactly four decimal digits. Tier 6 displays `THE CAPTAIN`; all other tiers display `ON WATCH`. In particular, `(n = 0, t = 6)` is valid and matches the supplied Captain hash. Zero is also valid at other tiers. The brief's final sentence saying that tier 6 and number 0 revert conflicts with the explicit bounds and supplied vector; the explicit bounds and vectors take precedence here.
- Code identifiers are lowercase hexadecimal without `0x`, padded to **at least three digits**. The brief does not specify how to represent the valid `uint16` values above `0xfff` in three hex digits. This implementation preserves all their bits: `0 -> 000`, `255 -> 0ff`, `4095 -> fff`, `4096 -> 1000`, `65535 -> ffff`. There is no extra input restriction or truncation. Bar arithmetic always uses the full identifier.
- Output order is DEFS, SCAN, optional BEAM, 16 BARs, ID, tier-dependent ORBITs, optional six CODE rows, eight STARs, optional EDGE. The third Captain orbit lasts six seconds; its first two last four seconds. All four supplied Keccak-256 vectors match exactly.
- This returns an SVG **fragment**, without a root element, data URI, card art, background or added whitespace. The consumer supplies the 1000-by-1000 card SVG, the inherited `currentColor`, and the card's other layers. Animation playback belongs to the SVG client; the contract needs no clock, transactions, keeper or randomness. The fixed `nwS`, `nwB`, and `nwE` IDs assume one layer per SVG document (or isolated SVGs).
- There is no payable constructor, receive function or fallback; normal ETH transfers and value-bearing `layer` calls revert. Ethereum can force ETH onto any address regardless of its code. Any forced balance would be inaccessible: there is intentionally no withdrawal or recovery function. Do not send ETH or tokens to this renderer.

## Build and test offline

The root Foundry project pins Solidity **0.8.26** (`0.8.26+commit.8a97fa7a`), Cancun EVM, optimizer enabled with 200 runs, `via_ir = true`, and `bytecode_hash = "none"`. The IR pipeline handles the long SVG concatenations. Foundry's test dependency is vendored as ordinary files in [`lib/forge-std`](lib/forge-std/UPSTREAM.md); production has no dependencies. With the pinned compiler installed, no package installation or network is needed.

```sh
forge build
FOUNDRY_FUZZ_SEED=0x63f99e0ad03e8ee3e977fc933aa89a0415f825cd95f776a7c4ad36680803ee00 forge test
forge fmt --check
```

The suite includes all four supplied hashes, 54 independently generated reference cases, invalid boundaries, malformed ABI data, full-width identifiers, caller/block independence, cyclic-input sensitivity, absence of storage access, ETH rejection, forced-balance independence, STATICCALL, factory CREATE2 deployment, and runtime/opcode limits. Four fuzz tests each run 256 cases with the supplied seed. Tests read no environment values, require no fork, FFI or filesystem permissions, and run independently.

The Python oracle uses its own string rendering, standard Python formatting, and `cast keccak`. It checks the supplied hashes before producing the committed Solidity corpus. Python and `cast` are needed only to regenerate/check that corpus; `forge test` uses the committed data directly:

```sh
python3 test/reference/generate.py --check
```

## `layer()` gas

Measured with Foundry 1.8.3 and the pinned configuration, with `n = 9999` and all ten identifiers equal to `65535`. Each tier is a separate test with a cold target address. These measurements include the external STATICCALL and returndata copying/decoding, exclude input encoding and transaction intrinsic gas, and are representative measurements rather than maximum bounds. An ordinary `eth_call` has no transaction fee; another contract calling this renderer pays execution gas.

| Tier | Measured call gas | SVG bytes |
| --- | ---: | ---: |
| 1 | 183,695 | 5,217 |
| 2 | 187,567 | 5,730 |
| 3 | 243,748 | 7,053 |
| 4 | 244,742 | 7,280 |
| 5 | 247,721 | 7,643 |
| 6 | 250,873 | 8,009 |

Reproduce with `forge test --match-contract NightWatchSkinGasTest -vv`. The test enforces a one-million-gas ceiling for each measured case. Runtime is **6,232 bytes** (EIP-170 limit: 24,576); creation bytecode is **6,258 bytes**. `forge build --sizes` reproduces the sizes.

## Deployment handoff

This deliverable is ready for the IdentityMD launch process; it has **not** broadcast a deployment or obtained explorer verification. IdentityMD's later manifest/deployment step supplies the confirmed address and transaction. There is no `launch.json` here because that belongs to the separate manifest step.

| Parameter | Value |
| --- | --- |
| Network | Ethereum mainnet, chain ID 1 |
| Application / Solidity identifier | `NightWatchSkin` |
| Artifact | `out/NightWatchSkin.sol/NightWatchSkin.json` |
| Source identifier | `src/NightWatchSkin.sol:NightWatchSkin` |
| Constructor arguments | None (empty encoding) |
| Deployment value | 0 ETH |
| Owner / admin / recipient settings | None |
| External addresses / linked libraries | None |
| Post-deployment initialization | None |

The launch deploys this artifact's creation bytecode through its factory. It must retain the exact compiler settings above. The constructor has no dependency on the factory, transaction origin, caller, chain state, or another deployed contract. Only `NightWatchSkin` is an application; `SkinDeploymentProbe` is a test harness.

After launch, the launch operator records the receipt/address, compares the deployed runtime with the artifact, and verifies on both Etherscan and Sourcify. Set `NIGHTWATCH_ADDRESS` to the **confirmed** launch address and configure the operator's Etherscan API key outside this repository, then run:

```sh
forge verify-contract "${NIGHTWATCH_ADDRESS:?set confirmed launch address}" \
  src/NightWatchSkin.sol:NightWatchSkin --chain 1 \
  --compiler-version v0.8.26+commit.8a97fa7a \
  --verifier etherscan --watch

forge verify-contract "${NIGHTWATCH_ADDRESS:?set confirmed launch address}" \
  src/NightWatchSkin.sol:NightWatchSkin --chain 1 \
  --compiler-version v0.8.26+commit.8a97fa7a \
  --verifier sourcify --watch
```

The Etherscan command uses `ETHERSCAN_API_KEY` configured by that operator. Neither command requires a signing key or constructor arguments. For manual submission, add `--show-standard-json-input` to the verification command to export the compiler input; retain `bytecodeHash: none` and the other pinned settings. Foundry build-info is also enabled in `out/build-info/`. See the [Foundry CLI overview](https://www.getfoundry.sh/forge/index.html), [Sourcify Foundry verification](https://docs.sourcify.dev/docs/verify-via-foundry/), and [Sourcify build-info/UI verification](https://docs.sourcify.dev/docs/how-to-verify/index.html).

The NFT/card integrator must use the confirmed renderer address, choose `n`, `t`, and the ten inputs, and compose the fragment into its card. This contract neither enforces collection membership nor derives tiers/identifiers from token ownership. After verification there are no operator transactions, funds, settings, renewals, or maintenance roles. Changing the design requires deploying a new contract and separately updating any consumer that supports it.

Local tests and a scoped manual security review are recorded in [`docs/REVIEW.md`](docs/REVIEW.md); no independent audit or live explorer verification is claimed.
