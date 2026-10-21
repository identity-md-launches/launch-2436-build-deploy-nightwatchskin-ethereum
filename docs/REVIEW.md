# NightWatchSkin review

Scope: the single production contract `src/NightWatchSkin.sol`, built with the root Foundry configuration. The task's supplied security reference and protected deployment/owner checks were read as background and acceptance data. This is a local implementation review, not an independent audit.

| Property | Evidence |
| --- | --- |
| Exact output and ordering | Four requester-supplied Keccak-256 hashes, plus 54 cases from a separate Python implementation; includes every tier, decimal padding boundaries, zero/max inputs and hex-width boundaries. |
| Access and state | Only `layer` is externally callable; it is `pure`. No inheritance or state declarations. Compiler storage layout is empty; `vm.record` records no storage access. Caller/block-change fuzzing gives identical output. |
| Deployment | Implicit, nonpayable, zero-argument constructor; CREATE2 rehearsal deploys identical runtime without another application or configuration. No factory/origin privileges. Runtime is 6,232 bytes; no unresolved library links. |
| No custody | No payable entry point, external value transfer, token interaction or withdrawal. ETH-bearing calls fail. A simulated forced balance changes no output and enables no withdrawal. |
| External dependencies | No contract calls or service lookups. Runtime instruction check excludes CALL, STATICCALL, CREATE, CREATE2, DELEGATECALL, CALLCODE and SELFDESTRUCT, along with persistent/transient storage instructions. It uses the protected floor's reachability treatment of trailing literal data. |
| Arithmetic | Bounds checked before rendering. Bar input multiplication promotes to uint256, bounded by `65535 * 22`; height is 8..48. Number arithmetic is bounded by 9999. Output decimal casts only convert ASCII 48..57. Loops have fixed limits of 16, 6, 8, 4, or the small number of decimal/hex digits. |
| Failure paths | Specific errors for tiers 0 and 7..255 and numbers above 9999; tests cover maximum uint256 numbers, noncanonical uint8/uint16 ABI words, truncated and unknown calls, and nonzero call value. |
| Input reuse | Period-41 bar invariance and code-row sensitivity fuzzing exercise all ten cyclic inputs; reference cases check all generated positions and durations. |

The hex formatting assumption and the contradictory revert sentence are explained in the README. No oracle, valuable randomness, signatures, token custody, economic accounting, reentrancy surface, upgradeability, or administrative recovery is present. Arbitrary `uint16` values cannot inject markup because all inputs are converted to numeric ASCII.

Validation performed: `forge build`, `forge test` with the requested fuzz seed (256 runs for each of four fuzz tests), `forge fmt --check`, independent Python corpus verification, compiler ABI/storage-layout inspection, gas measurements, and manual source review. Slither and Mythril were not run. The supplied protected tests depend on launch-time environment and owner-check files supplied by the later verifier; this local suite rehearses their relevant deployment/opcode properties without environment dependencies.

Outstanding launch operations: IdentityMD deployment, receipt/address recording, on-chain runtime comparison, Etherscan verification and Sourcify verification. No transaction was signed or broadcast by this assignment. The NFT integrator remains responsible for card composition and the meaning/provenance of supplied values; the renderer intentionally authenticates none of them.
